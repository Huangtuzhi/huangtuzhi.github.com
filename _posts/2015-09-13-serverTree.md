---
layout: post
title: "后台开发之路"
description: ""
category: server
tags: []
---

服务端后台开发主要涉及到四个层面:网络，业务逻辑，数据，运维。不同类型的业务对以上四点的要求不同。

-----------------------------

## 服务器特点


Server|网络       | 业务逻辑       | 数据 | 运维        
:----- |:-------|:--------|:-----
WeChat  |大部分长连接+短连接|消息存储+转发| 用户关系链的长久保存 中间消息缓存 | 基础服务 7×24
QZone |高性能HTTP服务器|用户日志照片存储|SNS业务，cache很重要|非基础服务

----------------------------

## 加强的地方

* 网络

《大规模分布式系统架构与设计实现》，《UNP》，《HTTP权威指南》

* 业务逻辑

Nodejs了解，搜索技术了解，可以跟一下公开课 [Text Retrieval and Search Engines](https://zh.coursera.org/course/textretrieval)

* 数据

《高性能MySQL》纸质版重读，Redis，Memcached多实践应用

* 运维

《Linux Shell脚本攻略》

------------------------------

## 技能树

![图片](/assets/images/serverTree.png)

------------------------------

## 参考

KM




