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

《大规模分布式系统架构与设计实现》，了解ZooKeeper;《UNP》，熟悉通信过程;《HTTP权威指南》，熟悉HTTP。

* 业务逻辑

了解Nodejs，了解搜索技术，可以跟一下公开课 [Text Retrieval and Search Engines](https://zh.coursera.org/course/textretrieval)

微信里的H5页面基本都是[SPA(Single-Page application)](http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/)，集中体现在商户侧和用户侧页面。这些页面基本是前后端分离。数据由后台服务CGI吐出，前端调AJAX/JSONP展现数据。

前后端分离定义如下：

前端：写模板或者前端模板，完成AJAX请求，用户交互。

后端：与前端开发协商接口及数据格式并吐出数据。

可以对比一下MVC的Django

> Getting data from the database according to a parameter passed in the URL, loading a template and returning the rendered template.

M负责定义DB字段，V定义function并返回URL对应的模板页面，而C由URLconf来实现，即urls.py，其机制是使用正则表达式匹配URL，然后调用views.py中合适的函数。

* 数据

《高性能MySQL》纸质版重读，Redis，Memcached实践应用。了解常用数据分析方法，机器学习的算法，库。

* 运维

《Linux Shell脚本攻略》，Python手册

sed，awk，grep

Nginx，Django框架

[Linux Performance Tools](http://www.brendangregg.com/linuxperf.html)

《七周七并发模型》

------------------------------

## 技能树

![图片](/assets/images/serverTree.png)

------------------------------

## 参考

[http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/](http://ued.taobao.org/blog/2014/04/full-stack-development-with-nodejs/)





