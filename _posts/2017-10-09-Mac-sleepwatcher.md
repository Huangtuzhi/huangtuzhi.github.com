---
layout: post
title: "使用 sleepwatcher 自启程序"
description: ""
category: 
tags:
comments: yes
---

在 Mac 中可以设置开机自启应用程序，但无法在 Mac 屏幕锁定后唤醒时自启应用程序。Mac 睡眠后，Samba 远程服务器连接、SyncKM Link 多屏幕控制器等应用程序的连接会断掉。而唤醒后并不会重新自动连接，使用 sleepwater 可以完美解决这个问题。

------------------------

## sleepwatcher

sleepwatcher 是一个能监听系统状态的工具，在进行授权后它会运行在系统后台，相当于系统级的应用。

安装使用 Mac 自带的软件管理

`brew install sleepwatcher`

设置软件服务自启动

`brew services start sleepwatcher`

查看进程是否启动

```
ps aux | grep sleepwatcher
titus 29048 0.0 0.0 2469824 0:10.21 
/usr/local/sbin/sleepwatcher -V -s ~/.sleep -w ~/.wakeup
```

sleepwatcher 执行的是 ~/.sleep 和 ~/.wakeup 文件，前者是睡眠时执行，后者是唤醒时执行。

------------------------

## 编写配置脚本

在 home 目录下创建文件 .wakeup 并赋予权限 777

```shell
touch ~/.wakeup
chmod 777 ~/.wakeup
```

脚本如下

```shell
#!/bin/bash
#.wakeup

open /Users/titus/Library/PowerSyncKMLinkFull/PowerSyncKMLink.app
echo "`date` -- Open SyncKMLink" >> /tmp/wakeup.log

net=`system_profiler SPAirPortDataType | awk -F':' '/Current 
Network Information:/{
 getline
 sub(/^ */,"")
 sub(/:$/,"")
 print
}'`

# If located in designated Wifi
if [ "$net"x = "DevWiFi"x ];then
    # Do Something
fi

if [ "$net"x = "HomeWiFi"x ];then
    # Do Something
fi

```

使用 open 命令可以在机器唤醒时打开特定应用程序

另外判断当前连接的 Wifi 可以实现工作环境配置和生活环境配置的自动切换。



