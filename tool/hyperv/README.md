
# ubuntu autoinstall
在 Hyper-V 上进行无人值守安装 Ubuntu 可通过使用 Cloud-Init 和自定义映像进行。以下是详细的步骤：
参考: [autoinstall](https://canonical-subiquity.readthedocs-hosted.com/en/latest/intro-to-autoinstall.html)

## 1. 准备 Ubuntu ISO 文件和 Cloud-Init 配置

### 下载 Ubuntu ISO：

+ 访问 Ubuntu官方网站 并下载所需的 Ubuntu ISO 文件。
## 配置 Cloud-Init：

+ 创建一个 user-data 文件（这将是配置文件）。以下是一个 Cloud-Init 配置文件的示例：

```yaml
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    ssh-authorized-keys:
      - ssh-rsa your-ssh-public-key

package_update: true
package_upgrade: true
packages:
  - git
  - curl

runcmd:
  - [ sh, -c, 'echo Ubuntu Cloud-Init Setup Complete' ]
```
替换 your-ssh-public-key 为你的实际 SSH 公钥。


## 2. 创建 ISO 文件以包含 Cloud-Init 配置

### 创建 Cloud-Init ISO 文件：
+ 将 user-data 文件放入一个目录。例如，创建 /tmp/cloud-init/ 目录：

```bash
mkdir -p /tmp/cloud-init/nocloud
```
+ 将 user-data 文件放入 /tmp/cloud-init/nocloud 目录中。

+ 使用以下命令创建 ISO 文件：

```bash
genisoimage -output /tmp/cloud-init.iso -volid cidata -joliet -r /tmp/cloud-init/nocloud
```
这样就会生成一个名为 cloud-init.iso 的 ISO 文件。


## 3. 在 Hyper-V 上创建虚拟机

### 打开 Hyper-V 管理器；

+ 创建新虚拟机：

右键单击 Hyper-V 主机，选择“新建” -> “虚拟机”。
按照向导设置虚拟机的名称、生成（推荐选择“第 2 代”）和内存等选项。
设置网络：

确保虚拟机能够访问网络（选择合适的虚拟交换机）。
添加虚拟硬盘：

创建或选择现有虚拟硬盘。
添加 Ubuntu ISO 文件作为启动项：

在虚拟机设置中，添加刚刚下载的 Ubuntu ISO 文件到“DVD 驱动器”中。
添加 Cloud-Init ISO：

在“DVD 驱动器”下，添加你创建的 
cloud-init.iso
 文件（确保它在第一位）。

## 4. 启动虚拟机并执行无人值守安装

### 启动虚拟机；
安装 Ubuntu：
一旦虚拟机启动，Ubuntu 将自动获取 Cloud-Init 配置，并开始安装，无需用户输入。

## 5. 验证安装

安装完成后，使用 SSH 访问你的 Ubuntu 虚拟机（使用你之前设置的 SSH 密钥）。
检查所有预定义的配置是否成功应用。

## 注意事项

确保网络连接正常，以便于下载更新和所需的包。
Cloud-Init 需要在 Ubuntu 操作系统中默认安装。如果你使用的 ISO 镜像是 Ubuntu Server 版本，默认应该包括 Cloud-Init。
如果你需要进一步个性化或定制安装，请参考 Cloud-Init 的文档。

通过以上步骤，你应该可以成功在 Hyper-V 上进行无人值守的 Ubuntu 安装。如果你在某个步骤上遇到问题，请随时联系我！