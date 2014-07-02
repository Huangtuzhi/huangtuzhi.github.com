---
layout: post
title: "github上搭建个人博客"
description: "blog"
category: tool
tags: [tool]
---

在软件开发中，常常需要用到版本控制工具。常见的工具有git，SVN。

git是Linus Torvalds编写的版本控制工具，github是基于git托管代码的大型仓库，同时github提供了一个github pages功能。可以被认为是用户编写的、托管在github上的静态网页。

由于是静态网页，所以不能连接数据库。但是当网站需要更新时，就需要修改源代码。这时Jekyll就能发挥作用了。它是一个静态站点生成器，会根据网页源码生成静态文件。我们只需要用顺手的工具(如Sublime，ZenPen)写Markdown文件就可以了。

---------------
##构建网站文件##
我们可以从Jekyll的官网上下载源代码上传到github上，或者直接fork别人修改好的Repository。下面是我采用的步骤：

在linux下安装git：

    sudo apt-get install git
   
把自己github上博客相关的repository下载到自己的pc上，作为一个本地的仓库用来同步代码。

     git clone git@github.com:Huangtuzhi/huangtuzhi.github.com.git ~/huangtuzhi.github.com

Huangtuzhi为笔者在github上的用户名，huangtuzhi.github.com是github上为blog建的repository。

设置ssh公钥。(见)

     cd ~/.ssh
    
创建ssh key

     ssh-keygen -t rsa -C "your_email@youremail.com"

打开~\.ssh\id_rsa.pub文件，复制里面的key码到github的公钥设置里。

----------------------
##开始写博客##

连接到远程机
  
      git remote set-url origin git@github.com:Huangtuzhi/huangtuzhi.github.com.git

查看连接状态

       git status -s

添加博客文章

       git add blog.md 

删除博客文章
  
      git rm blog.md

提交更改到Head区
 
       git commit -m "comment"

上面的add只是把更改从working dir提交到缓存区index，并没有提交到.git下面的本地仓库里。而commit命令式提交到本地仓库里。

推送更改到github

       git push origin master

------------------------
##Reference##
[1].http://www.open-open.com/lib/view/open1340532978952.html

[2].http://www.ruanyifeng.com/blog/2012/08/blogging_with_jekyll.html


