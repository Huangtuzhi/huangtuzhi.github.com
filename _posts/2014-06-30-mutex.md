---
layout: post
title: "内核同步机制之Mutex Exclusion"
description: "linux"
category: linux
tags: [kernel]
---

S3C2440在内核版本2.6.34下开发ADC驱动时，会发现驱动程序里用了互斥通信来实现同步：

    <!-- lang: cpp -->
    DECLARE_MUTEX(ADC_LOCK);
    static int OwnADC = 0;
在wikipedia中式这么定义Mutex Exclusion的：

> In computer science, mutual exclusion refers to the requirement of ensuring that no two processes or threads (henceforth referred to only as processes) are in their critical section at the same time. Here, a critical section refers to a period of time when the process accesses a shared resource, such as shared memory. 
 
专业的表达也可以是这样:
> A data structure for mutual exclusion, also known as a binary semaphore. A mutex is basically just a multitasking-aware binary flag that can be used to synchronize the activities of multiple tasks. As such, it can be used to protect critical sections of the code from interruption and shared resources from simultaneous use.

互斥体是表现互斥现象的数据结构，也被当作二元信号灯。一个互斥基本上是一个多任务敏感的二元信号，它能用作同步多任务的行为，它常用作保护从中断来的临界段代码并且在共享同步使用的资源。

-------------------------
##使用##
Linux内核的同步机制里面：
辅助宏:

    <!-- lang: cpp -->
    DECLARE_MUTEX(name); /*声明一个互斥锁，把名为name的信号量变量初始化为1 */
    DECLARE_MUTEX_LOCKED(name); /* 声明一个互斥锁，把名为name的信号量变量初始化为0 */

在Linux世界中, P函数被称为down, 指的是该函数减小了信号量的值, 它也许会将调用者置于休眠状态, 然后等待信号量变得可用, 之后再授予调用者对被保护资源的访问权限.

void down(struct semaphore *sem);
    
当一个线程成功调用down函数后, 就称为该线程拥有了该信号量, 可以访问被该信号量保护的临界区. 当互斥操作完成后, 必须释放该信号量.
Linux的V函数是up:
 
void up(struct semaphore *sem)

调用up之后, 调用者不再拥有该信号量 

##Reference##
[1].Linux Device Drivers.Thirth Edition.P112-P114

