---
title: Linux配置SSH密钥连接GitHub仓库(以Manjaro为例)
categories:
  - Linux
tags:
  - Manjaro
  - SSH
  - GitHub
banner_img: https://cdn.yangyus8.top/blog/2025/09/f460fe18ab4d7b9f96666e1079a768ad.webp
index_img: https://cdn.yangyus8.top/blog/2025/09/f460fe18ab4d7b9f96666e1079a768ad.webp
toc: true
comments: true
abbrlink: '16268779'
date: 2025-09-28 07:11:31
updated: 2025-09-28 07:11:31
---
最近给笔记本刷了Manjaro/Windows双系统，所以需要在Manjaro上重新配置一下开发环境，但是在配置git的时候发现官方教程不知道什么时候更新了，既然如此，干脆记录一下官方推荐的新的配置方案应该怎么用。毕竟通过ssh的方式推送代码速度更快，还不用每次都输入密码。

---

## 生成新SSH密钥对

由于是新系统，自然不用检查以前的密钥，那么就直接开始。

首先推荐进入 `～/.ssh`目录，这是ssh密钥的默认保存位置，可以方便一下待会儿在重命名步骤的操作。

```bash
cd ~/.ssh
```

执行下面的命令生成新的密钥，记得将 `youremail@email.com`替换为登录GitHub账号时的邮箱：

```bash
ssh-keygen -t ed25519 -C "youremail@email.com"
```

这里注意一下，官方教程更新后推荐使用Ed25519算法来生成密钥，关于Ed25519这个算法，可以参考[官网](https://ed25519.cr.yp.to/)的介绍，我这里简单贴出来一下：

![image-20250713072719195](https://cdn.yangyus8.top/blog/2025/09/02d75852ac784f1fb963b99d6df7f987.webp)

<p class="note note-info">
	如果你使用的是不支持 Ed25519 算法的旧系统，请执行以下命令使用RSA算法加密：
</p>

```bash
ssh-keygen -t rsa -b 4096 -C "youremail@email.com"
```

运行ssh-keygen后，系统会提示你选择密钥保存的位置，这里由于我们之前已经进入了密钥的默认保存位置，所以就不用写前面的绝对路径了(当然，如果你要更改保存位置的话另说)。为了能更好的区分密钥，我个人推荐给默认密钥重命名为 `id_ed25519_github`，这样既能避免以后生成别的密钥时重复写入到同一个文件(比如生成AUR的密钥)，又能清晰明了的标明每个密钥对应的平台，以后删起来也方便。

<p class="note note-info">
	注意：如果刚才是使用RSA加密的密钥，最好重命名为id_rsa_github，避免弄混
</p>

接下来系统还会询问是否要输入密码来保护密钥，虽然确实可以增加安全性，但是会变成每次使用SSH密钥都需要输入密码，很明显这违背了我使用密钥的初心(懒得输密码)，因此我一般直接回车就行。

密钥生成完成后，使用 `ls -l`命令可以看到刚才生成的一对密钥：私钥 `id_ed25519_github`和公钥 `id_ed25519_github.pub`

---

## 将SSH私钥添加到ssh-agent

我们需要将密钥添加到ssh代理，先执行下面的命令启动ssh代理：

```bash
eval "$(ssh-agent -s)"
```

<p class="note note-primary">
  正常情况下会输出`Agent pid xxxxx`，说明启动成功了，如果没有成功，可以试试下面的其他命令：
</p>

```bash
exec ssh-agent bash
```

```bash
exec ssh-agent zsh
```

启动ssh代理后，执行下面的命令将SSH私钥添加到ssh-agent：

```bash
ssh-add ~/.ssh/id_ed25519_github
```

添加成功的输出类似于 `Identity added: ~/.ssh/id_ed25519_github (youremail@email.com)`

接下来我们需要编辑一下 `～/.ssh/config`，如果没有这个文件自己创建一个即可，将下面的内容复制到文件中，只需要注意一下密钥的路径和名称是否对应：

```bash
Host github
HostName github.com
User git
IdentityFile ~/.ssh/id_ed25519_github
IdentitiesOnly yes
```

修改完成后，我们本地的配置基本就完成了。

---

## 将SSH公钥添加到GitHub账户

官网推荐的是使用[GitHub CLI](https://docs.github.com/zh/github-cli/github-cli/about-github-cli)添加，但是我并不是很喜欢，因此这里还是用网页的方式添加吧。

登录GitHub官网后，通过[这个链接](https://github.com/settings/keys)进入SSH密钥的设置页面，我们点击右上角的 `New SSH key`添加公钥

![image-20250713090659258](https://cdn.yangyus8.top/blog/2025/09/6a2cd7715427b83698114641f67ca5d2.webp)

来到 `Add new SSH Key`页面后，这里有三个可以配置的选项：

- Title：这个公钥的别名，我个人一般习惯写设备名，方便后续更换设备后删除；
- Key type：保持默认即可；
- Key：这里需要填入公钥 `id_ed25519_github.pub`中的内容。

我们可以执行下面的命令获取公钥内容：

```bash
cat ~/.ssh/id_ed25519_github.pub
```

输出的内容类似于 `ssh-ed25519 xxx...xxx youremail@email.com`，将这一长串全部复制粘贴到Key的位置：

![image-20250713091932956](https://cdn.yangyus8.top/blog/2025/09/0e8ae1390a6202861d8a2335bea6c9f4.webp)

最后点击 `Add SSH Key`就完成添加了。

---

## 本地验证

完成添加后，我们可以执行下面的命令验证是否配置成功：

```bash
ssh -T git@github.com 
```

不出意外的话，输出应该是下面这样：

![image-20250713092410074](https://cdn.yangyus8.top/blog/2025/09/a3d15169731af434dddd599eafee992f.webp)

至此，我们就完成了整个配置SSH密钥的过程......吗？

---

## 配置自动添加密钥

说实话，本来这篇博客已经写完了，就在我已经美滋滋的配置完Hexo的格式准备推送文章时，突然又发现了一个问题：如果我开了一个新终端，ssh-agent的代理是不会保留的，也就是说， 当我每次想用ssh密钥连接时，都需要手动完成一遍启动代理、加载私钥的过程，非常麻烦。为了解决这个问题，我稍微琢磨了一下，找到了一种解决方案。

首先，我们需要编辑shell 配置文件（根据你的 shell 选择）：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
if [ -z "$SSH_AUTH_SOCK" ]; then
   # 启动 SSH agent
   eval "$(ssh-agent -s)" > /dev/null
   # 自动添加密钥
   ssh-add ~/.ssh/id_ed25519_github 2>/dev/null
fi
```

这里注意一下，如果你有多个私钥，可以复制第6行代码，修改中间的文件名，然后接在第6行下面，就像下面这样：

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)" > /dev/null
   ssh-add ~/.ssh/id_ed25519_github 2>/dev/null		# 添加GitHub私钥
   ssh-add ~/.ssh/id_ed25519_gitee 2>/dev/null		# 添加Gitee私钥
   ssh-add ~/.ssh/id_ed25519_gitlab 2>/dev/null		# 添加GitLab私钥
fi
```

然后应用配置：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

最后再新开一个终端，执行下面的命令验证是否配置成功：

```bash
ssh-add -l            # 应显示已加载密钥
ssh -T git@github.com # 应显示成功消息
```

至此，才是真正完成了所有配置SSH密钥的过程，虽然本篇是以Manjaro和GitHub为例，但对于其他Linux系统和其他需要ssh密钥连接的平台其实基本也是通用的。

------

## 2025.10.12更新

好吧，本来以为这篇博客可以完结了，没想到还能有后续：

博主最近更换了Manjaro的桌面环境，从KDE换成了Hyprland，体验确实更舒服了，但配置的过程确是灾难级的。这其中的辛酸暂且不提，今天的重点还是在密钥配置上。

出于一些原因，博主的`~/.zshrc`文件被覆写了，导致原来的配置失效了（当然，仅仅是自动添加密钥部分），由于我把以前KDE的密钥管理服务Kwallet换成了现在的gnome-keyring，可能中间出了什么问题，所以现在自动添加的部分应该是用不了了。现在给出我使用的最新方案，可以保证跨桌面环境使用：

首先我们需要安装一个叫keychain的软件，安装方式如下：

```bash
# Arch/Manjaro:
sudo pacman -S keychain
# Debian/Ubuntu:
sudo apt install keychain
```

安装完成后，修改`~/.zshrc`（或者是`~/.bashrc`）:

```bash
# 使用 keychain 复用/启动 ssh-agent，并加载密钥（存在才加载）
if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --eval --quiet ~/.ssh/id_ed25519_github)"
fi
```

当然，如果要加载多个密钥也是可以的，只需要在第一个密钥后面接着写就行：

```bash
# 使用 keychain 复用/启动 ssh-agent，并加载三把密钥（存在才加载）
if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --eval --quiet ~/.ssh/id_ed25519_github ~/.ssh/id_ed25519_gitee ~/.ssh/id_ed25519_gitlab)"
fi
```

修改完成后刷新一下终端配置文件：

```bash
source ~/.zshrc
# source ~/.bashrc
```

然后新开一个终端验证一下：

```bash
ssh-add -l
ssh -T git@github.com
```

![image-20251012183505260](https://cdn.yangyus8.top/blog/2025/10/80d7b821921be1f9338ac77e6d63f9bb.webp)

~~好了，这下终于不用担心了，博主终于可以睡个好觉了QAQ.~~

睡个蛋，我都准备关电脑了，结果在VSCode里面推送的时候出权限问题了，原因是我用gnome-keyring的时候设置了硬编码SSH_AUTH_SOCK，现在直接给出解决方案：

首先创建户服务和环境文件：

```bash
mkdir -p ~/.config/systemd/user ~/.config/environment.d
```

创建`~/.config/systemd/user/ssh-agent.service`，填入下面的内容：

```shell
[Unit]
Description=User SSH Agent
[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a ${SSH_AUTH_SOCK}
[Install]
WantedBy=default.target
```

然后创建`~/.config/environment.d/10-ssh-agent.conf`，填入下面的内容：

```shell
SSH_AUTH_SOCK=%t/ssh-agent.socket
```

接下来启动刚刚创建的服务，并将其设置为开机自启：

```bash
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service
```

继续修改`~/.zshrc`（或者是`~/.bashrc`）：

```bash
# 注释掉下面这两行：
#export GPG_AGENT_INFO=~/.gnupg/S.gpg-agent:0:1
#export SSH_AUTH_SOCK=~/.gnupg/S.gpg-agent.ssh

# 添加这一行：
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"

# 下面的保持不变：
if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --eval --quiet ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_github ~/.ssh/id_ed25519_>
fi
```

然后注销并重新登录图形会话一次，让 VS Code、GUI 进程都拿到该变量，应该就没问题了

> 参考文献：
>
> - [GitHub文档 - 生成新的 SSH 密钥并将其添加到 ssh-agent](https://docs.github.com/zh/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
> - [GitHub文档 - 新增 SSH 密钥到 GitHub 帐户](https://docs.github.com/zh/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
> - [Ed25519：高速高安全签名](https://ed25519.cr.yp.to/)
> - [博客园 - github添加ssh密钥，通过ssh方式推送代码](https://www.cnblogs.com/kiwiblog/p/18341759)
>
> 文章背景及封面作者：
>
> - [匣子](https://www.pixiv.net/users/64408268)
>
> 转载请注明作者及原页面链接

![封面](https://cdn.yangyus8.top/blog/2025/09/f460fe18ab4d7b9f96666e1079a768ad.webp)
