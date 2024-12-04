pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            yaml """
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: gradle
    image: docker.io/library/gradle:8.11.1-jdk17
    command: 
      - cat
    tty: true
  - name: kubectl
    image: docker.io/bitnami/kubectl:latest
    command: 
      - cat
    tty: true
  - name: docker
    image: docker.io/moby/buildkit:master-rootless
    command: 
      - cat
    env:
      - name: BUILDKITD_FLAGS
        value: --oci-worker-no-process-sandbox
    tty: true
    volumeMounts:
      - mountPath: /home/user/.config/buildkit
        # subPath: buildkitd.toml
        name: buildkit-config
        readOnly: true
  volumes:
  - name: buildkit-config
    configMap:
      name: buildkitd
"""
        }
    }

    environment {
        SONAR_HOST_URL = "http://sonarqube.lo-k8s/"  // SonarQube 服务器地址
        SONAR_AUTH_TOKEN = credentials('sonar_token') // 使用 Jenkins 凭据管理获取 SonarQube token
        GIT_TOKEN = credentials('bb_token') // 使用 Jenkins 凭据管理获取 Bitbucket token
        GRADLE_OPTS = '-Dorg.gradle.daemon=false'
        APP_VERSION = "0.0.4"
        DOCKER_IMAGE="huang/spring-test"
    }

    stages {
        stage('Checkout') {
            steps {
                container('gradle') {
                    git branch: 'main', credentialsId: 'bk_app', url: 'https://bitbucket.org/tortoi-bk/spring-test.git'
                    /*script {
                        sh '''
                            git config --global credential.helper store
                            echo "https://x-token-auth:${bb_token}@bitbucket.org/tortoi-bk/spring-test.git" > ~/.git-credentials
                            git clone https://bitbucket.org/tortoi-bk/spring-test.git
                            cd spring-test
                        '''
                    }*/
                }
            }
        }

        /*stage('SonarQube Analysis') {
            steps {
                container('gradle') { // 指定使用 Gradle 容器
                    script {
                        // 执行 SonarQube 检查
                        sh '''
                            cd spring-test
                            ./gradlew sonarqube -Dsonar.projectKey=your-project-key \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_AUTH_TOKEN}
                        '''
                    }
                }
            }
        }*/

        stage('Build with Gradle') {
            steps {
                container('gradle') { // 指定使用 Gradle 容器
                    script {
                        // 执行 Gradle 构建
                        sh '''
                            # chmod +x ./gradlew
                            # ./gradlew clean test bootJar -PprojectVersion="${APP_VERSION}" ${GRADLE_OPTS}
                            gradle clean test bootJar -PprojectVersion="${APP_VERSION}" ${GRADLE_OPTS}
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') { // 指定使用 Docker 容器
                    script {
                        // 构建 Docker 镜像
                        sh "buildctl-daemonless.sh build --frontend dockerfile.v0 --opt build-arg:BUILD_PROJECT_NAME= --opt build-arg:JAR_FILE_NAME=stest-${APP_VERSION} --local context=. --local dockerfile=. --output type=image,name=registry.container-registry:5000/${DOCKER_IMAGE}:${APP_VERSION},push=true"
                    }
                }
            }
        }

        /*stage('Push Docker Image') {
            steps {
                container('docker') { // 指定使用 Docker 容器
                    script {
                        // 推送 Docker 镜像到远程仓库
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }*/

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') { // 指定使用 kubectl 容器
                    script {
                        // 解码 kubectl 使用的 kubeconfig
                        //writeFile file: 'kubeconfig', text: sh(script: "echo ${KUBECONFIG_BASE64} | base64 --decode", returnStdout: true).trim()
                        
                        // 设置 KUBECONFIG 环境变量
                        //env.KUBECONFIG = "${WORKSPACE}/kubeconfig"

                        // 使用 kubectl 部署
                        sh '''
                            kubectl run spring-test --image=localhost:32000/${DOCKER_IMAGE}:${APP_VERSION}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
