---
layout: post
title: "如何优雅地用ARM开发板搭建服务器"
description: "ARM Server"
category: ARM
tags: [ARM]
---

本文参见[Building a tiny ARM-based server][1]，是翻译，也是学习。

我拆了一个旧的ARM开发板，并用它制作了一个基于Debian的mini服务器。我现在有一个随时可以访问的网关，它：

 - 非常节能，只有大约3-3.5W
 - 总是可以访问的，即使我用的动态IP (via DynDNS)
 - 有一个Nginx网络服务器，所以我能和世界分享我的生活。(Nginx是一款面向性能设计的HTTP服务器，相较于Apache、lighttpd具有占有内存少，稳定性高等优势。）
 - 有一个Exim邮件服务器，所以我能通过SMTP接受Email并把它存在我的房子里。我通过SSH/mytt阅读邮件。
 - 能够通过SSH远程连接，允许远程唤醒我的主桌面。
 - 在后台进行下载（wget/rtorrent) ，用Samba服务器共享至绑定设备，如Andriod平板
 - SSH端口复用为HTTPS端口来滤除一些防火墙限制。

这个是我最好的作品。我喜欢建造它的过程。

-------------------------------------
##Building a tiny ARM-based server##

大约一年前，我拿到了一个NAS设备——这是一个相当古老低耗能基于ARM的文件服务器。按照现代的标准，它被认为过时。然而我知道从我获得它的那一天我会非常享受改造它。

我的职业是一个程序员。我诚恳认为编程和生活是分开的，可以有这样一种可能它们都能被提高。

-------------------------------------------------
##Disassembling and soldering ##

首先我必须把整个东西拆开，这样我才能按照我的想法去搭建这个世界。按照其他工程师的指导，我足足拆了半个小时才拆开它。我把机器里面的两个光驱拆出来，连接到我的外部USB/SATA附件。迅速地检测了一下它的功能。

    smartctl -a /dev/sdX 

这个命令显示两个光驱都有坏的扇区。
我找到一个160GB的USB移动硬盘挂在上面。由于这是一个嵌入式设备，没有VGA输出，也没有串口输入。我需要找到一种监视它启动过程的方法。我google了很久，这个机器上面实际有RS232的悍盘。万能的互联网提供的方法说明非常简单：

Pin 1 = +3.3V

Pin 2 = GND

Pin 3 = Rx

Pin 4 = Tx
我已經过了用面包版搭建RS232接口的年纪，我在网上从一家电子商城订购了一根TTL转RS232电缆。

![在此输入图片描述][2]

上图红箭头所指的就是我焊接上去的串口线。两天后，我又连接了一根串口转USB的电缆。我的电脑是ArchLinux，Atom 330 。我把USB插入电脑，打开串口调试程序，这样就能控制这个板子了。

    <!-- lang: shell -->
    minicom -D /dev/ttyUSB0 -b 115200

---------------------------------
##U-booting from no BIOS whatsoever##

下面讲的就是怎么对160G的硬盘分区，然后启动内核。

> I mounted the old drives up to my main PC's USB/SATA enclosure, and sure enough, I saw clear signs of a Linux-based machine: the software RAID driver in my ArchLinux detected raid devices (cat /proc/mdstat showed information about the RAID structure 磁盘冗余阵列). Apparently, MyBook had the two drives in a RAID formation - which I proceeded to successfully mount. There were 4 partitions in each of the two drives, clearly in a RAID1 mirror formation - with the 4th and final partition being the one with the "File Server" storage area.
I proceeded to copy the first three partitions (including the partition table) to my 160GB drive (via dd). I then used fdisk to fix the size of the 4th partition to be the remaining space of my drive.

-----------------------------
##Installing Debian (and some thoughts about Windows)##

这一段主要是讲如何安装Debian操作系统，和怎么看待linux和windows的差别。

> Sadly, this is a skill that Microsoft all but destroyed, making people hopelessly dependent on "wizards". That, in itself would have been fine, if it were not for the inevitable side-effect: people clicking on buttons unaware of what is going on behind them, end up with systems that can only be rescued with "OS reinstalls". My own settings - since I work with UNIX systems - are simple files under /etc and my $HOME... and have always been living under revision control (e.g my main dot files and vim configuration), happily migrating over the last 15 years across many machines. Backing them up and restoring them

接下来作者讲述如何解决服务提供商IP变动的问题，主要是使用cron定时工具让一个 DynDNS 程序自启动，这个DynDNS可以映射一个固定IP地址。这样就可以在外面稳定地访问了。贴代码。

下载
  
     <!-- lang: shell -->
    # apt-get install gcc
    ...
    # wget http://inatech.eu/inadyn/inadyn.v1.96.2.zip
    # unzip inadyn.v1.96.2.zip
    # cd inadyn
    # make
    ...
    # cp bin/linux/inadyn /usr/local/bin
    
自启动
   
    <!-- lang: shell -->
    # cat /var/spool/cron/crontabs/root 
    ...
    @reboot /usr/local/bin/inadyn

然后作者讲述怎么安装邮件服务器Exim，网络服务器Nginx

------------------------
##Conclusion - UNIX glory##

> In plain words, UNIX power put to use - in the tiny server, in my phone, in my tablet. All 3 of them, running on ARM processors. To be honest, I didn't expect that ; 15 years ago I was sure that Intel and MS had cornered the galaxy... but somehow, Linux managed to change all that.

我仍然得对他们进行越狱或者破解来实现我的想法——因为这个世界还不完美。

但是这就是为什么这个世界有意思的原因 :‑)


  [1]: http://users.softlab.ece.ntua.gr/~ttsiod/arm.html
  [2]: http://static.oschina.net/uploads/space/2014/0313/210042_mwwi_1420197.jpg

