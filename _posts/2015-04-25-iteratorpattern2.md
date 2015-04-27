---
layout: post
title: "test"
description: ""
category: C&&C++
tags: []
---

C++ Primer 12章动态内存中定义了一个StrBlob类，它实现了一个新的集合类型，和vector类似。这么定义可以允许多个对象共享相同的元素，其实实质就是浅拷贝，而vector是深拷贝。下面借助这个类实现一下迭代器。用StrBlob存入一个文件的每行，用StrblobPtr迭代器打印每个元素。