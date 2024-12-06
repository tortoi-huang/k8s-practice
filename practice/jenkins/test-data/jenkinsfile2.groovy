//def POD_LABEL = "agent-pod-${UUID.randomUUID().toString()}"
podTemplate(
  agentContainer: 'gradle',
  // 配置为true 就不用 jnlp 容器了
  agentInjection: true,
  //label: POD_LABEL, 
  cloud: 'kubernetes',
  yaml: '''
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
''') {
  node(POD_LABEL) {
    //environment 方法无效
    /* environment {
        DOCKER_IMAGE = "your-docker-repo/your-image-name:latest"
        SONAR_HOST_URL = "http://your-sonarqube-url"  // SonarQube 服务器地址
        SONAR_AUTH_TOKEN = credentials('sonar-token-id') // 使用 Jenkins 凭据管理获取 SonarQube token
        GIT_TOKEN = credentials('your-bitbucket-token-id') // 使用 Jenkins 凭据管理获取 Bitbucket token
        GRADLE_OPTS = '-Dorg.gradle.daemon=false'
        APP_VERSION = "0.0.3"
    }*/
    withEnv(["APP_VERSION=0.0.10", "DOCKER_IMAGE=huang/spring-test"]) {
      stage('checkout') {
        // 如果需要在shell中引用密码则需要 withCredentials 方法
        //withCredentials([string(credentialsId: 'bb_token', variable: 'bb_token')]) {
          container('gradle') {
              stage('git_clone') {
                // pipeline 中的 git 函数会将文件拉到当前目录，而不会创建一个目录， 与 shell中的git命令不同
                git branch: 'main', credentialsId: 'bk_app', url: 'https://bitbucket.org/tortoi-bk/spring-test.git'
                /*sh '''
                    echo 'checkout git start'
                    git config --global credential.helper store
                    echo "token url: https://x-token-auth:${bb_token}@bitbucket.org/tortoi-bk/spring-test.git"
                    echo "https://x-token-auth:${bb_token}@bitbucket.org/tortoi-bk/spring-test.git" > ~/.git-credentials
                    git clone https://bitbucket.org/tortoi-bk/spring-test.git
                    echo '------------------------------------------------------------------------ checkout git end'
                '''*/
              }
          }
        //}
      }
      stage('build') {
        container('gradle') {
            stage('Build_project') {
            sh '''
              echo 'gradle Build start'
              echo -e '~ is:' ~ 
              echo -e "\$HOME is: $HOME"
              whoami
              echo -e "\$USER is: $USER"
              id
              cat /etc/passwd|grep 1000
              ls -la /home/jenkins/agent/workspace/hello-k8s/
              ls -la /home/jenkins/agent/
              ls -la /home/jenkins/
              gradle clean test bootJar -PprojectVersion="${APP_VERSION}" --no-daemon
              echo '------------------------------------------------------------------------ gradle Build end'
            '''
            }
        }
      }

      stage('package') {
        container('docker') {
          stage('package_image') {
            sh '''
              echo 'docker build start'
              echo -e '~ is:' ~ 
              echo -e "\$HOME is: $HOME"
              whoami
              echo -e "\$USER is: $USER"
              id
              cat /etc/passwd|grep 1000
              touch ~/test1 /home/jenkins/test2
              ls -la ~/
              ls -la /home/jenkins/agent/workspace/hello-k8s/
              ls -la /home/jenkins/agent/
              ls -la /home/jenkins/
              cat ~/.config/buildkit/buildkitd.toml
              # docker build --build-arg BUILD_PROJECT_NAME= --build-arg JAR_FILE_NAME=stest-${APP_VERSION} -t ${DOCKER_IMAGE}:${APP_VERSION} -f ./Dockerfile . 
              # /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=registry.container-registry:5000/${DOCKER_IMAGE}:${APP_VERSION}
              buildctl-daemonless.sh build --frontend dockerfile.v0 --opt build-arg:BUILD_PROJECT_NAME= --opt build-arg:JAR_FILE_NAME=stest-${APP_VERSION} --local context=. --local dockerfile=. --output type=image,name=registry.container-registry:5000/${DOCKER_IMAGE}:${APP_VERSION},push=true
              # docker images
              echo '------------------------------------------------------------------------ kubectl deploy end'
            '''
          }
        }
      }

      stage('deploy') {
        container('kubectl') {
            stage('deploy2k8s') {
            sh '''
              echo 'kubectl deploy start'
              echo -e '~ is:' ~ 
              echo -e "\$HOME is: $HOME"
              echo $(whoami)
              echo -e "\$USER is: $USER"
              echo $(id)
              echo $(cat /etc/passwd|grep 1001)
              touch ~/test1 /home/jenkins/test2
              ls -la ~/
              ls -la /home/jenkins/agent/workspace/hello-k8s/
              ls -la /home/jenkins/agent/
              ls -la /home/jenkins/
              kubectl run spring-test --image=localhost:32000/${DOCKER_IMAGE}:${APP_VERSION}
              echo '------------------------------------------------------------------------ kubectl deploy end'
            '''
            }
        }
      }
    }
  }
}