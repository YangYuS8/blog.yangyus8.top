---
title: VirtualBox安装CentOS-7时容易遇到的Bug及解决方案
categories: [Linux]
tags: [Bug,VirtualBox,CentOS]
banner_img: https://cdn.yangyus8.top/blog/2025/09/f3c90e47eaed427fd7e54a7f5989dea2.webp
index_img: https://cdn.yangyus8.top/blog/2025/09/f3c90e47eaed427fd7e54a7f5989dea2.webp
toc: true
comments: true
date: 2025-09-29 09:55:35
updated: 2025-09-29 09:55:35
---
## Q1.报错“Unknown guest OS major version '7'”

### 报错图例：

![2c64712033980b6bd8d4640abf9807ef](https://cdn.yangyus8.top/blog/2025/09/e4f414d2b70c095a2eb0f8e09f4b945b.webp)

### 解决方案：

- 按照下图依次点击 `设置`->`存储`->`没有盘片`；
  ![image-20250223145922532](https://cdn.yangyus8.top/blog/2025/09/9ad931b282b26b0a4bde6f825aecfc4a.webp)
- 在右侧属性界面的分配光驱选项的右边有一个光盘图标，点击它，在下拉菜单栏中可以看到安装系统时选择的镜像文件（正常情况下）；如果没有，则选择 `Choose a Disk File...`，然后手动选择你下载的镜像（如CentOS-7），然后点击确定即可。
  ![image-20250223150412154](https://cdn.yangyus8.top/blog/2025/09/fc2ac34db19bc7323dec4da1f5ebbeb4.webp)

配置完成后如下图所示：

![image-20250223150940595](https://cdn.yangyus8.top/blog/2025/09/2eaf1d798c98ae8e2588ff77668b6482.webp)

### 原理解释：

报错的原因是镜像没有成功挂载上，触发原因暂且不明，解决方案的原理很简单，重新挂载一次镜像即可。

---

## Q2.报错”Error In supR3HardenedWinReSpawn“

### 报错图例：

![c10989984a1018ff5ade6ed8bb4b3a63432b12c9](https://cdn.yangyus8.top/blog/2025/09/3b989e8eae3efa5c889cbedba1b17855.webp)

### 解决方案：

- 打开VirtualBox的安装目录（默认为 `C:\Program Files\Oracle\VirtualBox`）；
  ![image-20250223152839300](https://cdn.yangyus8.top/blog/2025/09/ed3d845a9f27b796cbffb4c6a2a62906.webp)
- 在安装目录下依次进入 `drivers`->`vboxsup`，可以看到下面三个文件：
  ![image-20250223152914256](https://cdn.yangyus8.top/blog/2025/09/13f44c1b515d0e9fd586c5cd92d3b556.webp)
- 右键 `VBoxSup.inf`，选择 `安装`，在弹出来的窗口中选择 `是`，安装完成后，需要重启电脑；
  ![image-20250223153223808](https://cdn.yangyus8.top/blog/2025/09/b479ef80196463554223f4a3205668e6.webp)

重启电脑后再次启动虚拟机，就可以正常启动了。
![image-20250223153349532](https://cdn.yangyus8.top/blog/2025/09/fb5bf7cd0087504c89e7ffe1f5133e4c.webp)

### 原理解释：

报错的原因是vboxsup服务没有安装或没有成功启动，此问题常出现于64位的系统中。
