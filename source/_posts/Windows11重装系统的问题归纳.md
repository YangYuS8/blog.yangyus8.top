---
title: Windows11重装系统的问题归纳
categories: [系统重装]
tags: [Windows,Bug]
banner_img: https://cdn.yangyus8.top/blog/banner.jpg
index_img: https://cdn.yangyus8.top/blog/cover.jpg
toc: true
comments: true
date: 2025-10-17 20:34:03
updated: 2025-10-17 20:34:03
---
在帮助他人重装Windows系统时，我遇到了各种问题，所以专门写了这篇博客用来记录这些问题的解决方案，既是为了分享，也是为了给未来记性不好的我一个救急方案。

------

## 1.U盘的PE工具进不去，出现莫名其妙的蓝屏

这种情况是因为主板BIOS开启了`安全启动`，需要先进入BIOS中，在安全或启动部分的相关设置中关闭（一般是叫`Secure Boot`），然后再重启系统就可以进入PE了。

## 2.使用官方镜像重装系统找不到磁盘

这种情况一般出现在英特尔的11-13代CPU中，原因是从11代开始，品牌机的BIOS中默认开启了VMD，而重装时使用的镜像没有提前注入VMD驱动，所以无法正确识别出磁盘。

解决方案有两个：

1. 提前将VMD驱动的压缩包解压到U盘中，然后在选择磁盘的地方手动加载VMD驱动，这样的好处是不用修改镜像，缺点是需要提前准备适配的驱动，我曾经给戴尔游匣笔记本装VMD驱动时还出现过驱动不兼容的问题，所以这个方案其实我个人不怎么推荐；
2. 进入主板BIOS关闭VMD模式，改用ACHI模式，这样可以直接绕过VMD驱动缺失的问题，一般是在硬盘相关的设置中修改；

当然，除了以上两种方案，其实还可以通过在PE中使用Dism++给系统盘注入VMD驱动的方式解决问题，只不过这个方法相对而言要更加复杂，这里仅作记录。

## 3.安装完系统重启后出现报错（0xc0000225）

这个问题的原因一般是因为重装系统之后引导分区出错，可以直接在PE中使用Dism++修复引导，再次重启就没问题了。

## 4.Win11跳过联网激活（2025.10.17有效）

由于微软在最新版本镜像中封死了oobe命令行跳过联网的漏洞，所以需要采用新方法来解决这个问题：

- 方法一：在登录界面按`Shift+F10`调出命令行提示符，输入下面的命令：

  ```powershell
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
  ```

  执行完毕后再输入重启命令：

  ```powershell
  shutdown /r/t 0
  ```

  重启后就可以直接创建本地账户了；

- 方法二：在断网状态下，使用`Shift+F10`打开命令行提示符，输入`regedit`进入注册表编辑器。然后找到下面的路径：

  ```powershell
  HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE
  ```

  右键新建一个`DWORD(32位)值`，把数值改成`1`，保存并重启即可。

