---
layout: post
title: "简单shell脚本检测mysql运行情况"
description: "shell"
category: Network
tags: [shell]
---

阿里云服务器上的mysql服务经常挂掉，每次需要自己去重启nginx，php，mysql服务器。其实只需要写一个简单的shell脚本监测mysql的运行进程，一旦这个进程消失就重启服务器。同时把脚本加入到系统服务中。为了不占用过多的资源，让脚本1分钟检查一次。

##Monitor Shell##
    <!-- lang: shell -->
    #!/bin/bash
    #Supported by Letian
    while [ "1"="1" ]
    do
    still_running=$(ps -ef |grep 'mysql' |grep -v 'grep')
    if [ "still_runnig" ];then
    :
    else
    service nginx restart
    service php5-fpm restart
    service mysql restart
    fi
    sleep 60
    done

##加入系统服务##
还需要把脚本添加为系统服务，让脚本开机自启动。本方法采用适用于linux-ubuntu与Debian系统中的update-rc.d(创建/注册系统服务) 。

 1. 编写服务脚本放在/etc/init.d下。
 
 2. 在/etc/rc*.d中制作相关的link。K开头是kill, S开头是start, 数字顺序代表启动的顺序。可以采用update-rc.d 简化过程。

![在此输入图片描述][01]

这样建立了/etc/rc*.d中各种系统级别到脚本的软链接。然后执行命令

update-rc.d mysql-daemon start 90 1 2 3 4 5 . stop 52 0 6 .

start 90 1 2 3 4 5 . : 表示在1、2、3、4、5这五个运行级别中，按先后顺序，由小到大，第90个开始运行这个脚本。

stop 52 0 6 . ：表示在0、6这两个运行级别中，按照先后顺序，由小到大，第52个停止这个脚本的运行。

##关于update-rc.d##

> update-rc.d  updates   the   System   V   style   init   script   links  /etc/rcrunlevel.d/NNname  whose  target is the script /etc/init.d/name.  These links are run  by  init  when  it  changes  runlevels;  they  are generally  used  to  start  and  stop  system services such as daemons. runlevel  is  one  of  the  runlevels  supported   by   init,   namely, 0123456789S,  and  NN  is the two-digit sequence number that determines  where in the sequence init will run the scripts.

update-rc.d命令，用来自动升级System V类型初始化脚本。简单的讲就是，哪些东西是你想要系统在引导初始化的时候运行的，哪些是希望在关机或重启时停止的，可以用它来帮你设置。这些脚本的连接位于/etc/rc*.d/LnName,对应脚本位于/etc/init.d/Script-name。

ubuntu与Debian 的update-rc.d与RH的chkconfig工具相类似。然而chkconfig是一个二进制程序，而update-rc.d是一个Perl脚本。这些工具有不同的命令行选项，但是却执行类似的功能。[1]

设置完这些，用service --status-all命令可以查看mysql-daemon是否存在系统服务中。
![在此输入图片描述][02]



##Reference##

[1].http://blog.csdn.net/aa2650/article/details/6304049

[2].http://manpages.ubuntu.com/manpages/hardy/man8/update-rc.d.8.html

[3].http://xiaoxia.org/2011/11/15/create-a-simple-linux-daemon/


  [01]: http://static.oschina.net/uploads/space/2014/0504/104909_VAA8_1420197.png
  [02]: http://static.oschina.net/uploads/space/2014/0504/110241_I4bj_1420197.png
