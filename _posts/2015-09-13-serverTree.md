---
layout: post
title: "后台开发之路"
description: ""
category: server
tags: []
---

服务端后台开发主要涉及到四个层面：网络，业务逻辑，数据，运维。不同类型的业务对以上四点的要求不同。

-----------------------------

## 服务器特点

对比一下微信和QQ空间两种架构的场景。

Server|网络       | 业务逻辑       | 数据 | 运维        
:----- |:-------|:--------|:-----
微信|大部分长连接+短连接|消息存储+转发|关系链长久保存，中间消息缓存 | 基础服务 7×24
空间|高性能HTTP服务器 |用户日志照片存储|SNS业务，cache很重要|非基础服务

----------------------------


## apt-get upgrade

细分下来需要了解和提高的地方。

* 网络

《UNP》，熟悉通信过程

《HTTP权威指南》，熟悉HTTP

《大规模分布式系统架构与设计实现》,了解常用分布式系统架构

《从Paxos到ZooKeeper》，了解 ZooKeeper

* 业务逻辑

《七周七并发模型》，了解常用并发模型

《深入浅出 Nodejs》，了解 Nodejs

公开课 [Text Retrieval and Search Engines](https://zh.coursera.org/course/textretrieval)，了解搜索技术。《自制搜索引擎》，对比 [wukong 搜索引擎](https://github.com/huichen/wukong)源码。

微信里的 H5 页面基本都是 [SPA(Single-Page application)](http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/)，集中体现在商户侧和用户侧页面。这些页面基本是前后端分离。数据由后台服务 CGI 吐出，前端调 AJAX/JSONP 展现数据。

前后端分离定义如下：

前端：写模板或者前端模板，完成AJAX请求，用户交互。

后端：与前端开发协商接口及数据格式并吐出数据。

可以对比一下 MVC 的 Django

> Getting data from the database according to a parameter passed in the URL, loading a template and returning the rendered template.

M 负责定义 DB 字段，V 定义 function 并返回 URL 对应的模板页面，而 C 由 URLconf 来实现，即 urls.py，其机制是使用正则表达式匹配 URL，然后调用 views.py 中合适的函数。

* 数据

《高性能MySQL》纸质版重读，Redis，Memcached 实践应用

公开课《Machine Learning》，机器学习的算法，库

* 运维

《Linux Shell脚本攻略》

sed，awk，grep 使用

Nginx 常用配置

[Linux Performance Tools](http://www.brendangregg.com/linuxperf.html)

[Docker](https://github.com/Huangtuzhi/DockerTutorial)



------------------------------

## 技能树

![图片](/assets/images/serverTree.png)

------------------------------

## 参考

[http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/](http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/)





