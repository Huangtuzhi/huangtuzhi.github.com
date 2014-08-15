---
layout: post
title: "wait_event_interruptible的唤醒问题"
description: ""
category: linux
tags: []
---
这段时间准备重写一个红外代码学习的控制驱动，发现还有很多linux内核的基础没有真正理解，对进程跳转的运行逻辑不清楚。比如读一个字符设备阻塞是怎么实现的？来自哪儿的信号通知进程可以开始读数据？

LDD在第十章**中断处理** 中说：

> 中断处理例程的一个典型任务就是：如果中断通知进程所等待的事件已经发生，比如新的数据到达，就会唤醒在该设备上休眠的进程。

所以可以得到上面一个问题的答案，是在中断服务子函数中通知read进程可以读数据了。

--------------------------------------------------------------------
##wait_event_interruptible函数##
先看函数的源代码

{% highlight objc %}
(Part1)
#define wait_event_interruptible(wq, condition)   \
({ \
    int __ret = 0;                  \
    if (!(condition))          \
        __wait_event_interruptible(wq, condition, __ret);  \
    __ret;   \
})
{% endhighlight %}

{% highlight objc %}
(Part2)
#define __wait_event_interruptible(wq, condition, ret)
    do { \
    DEFINE_WAIT(__wait);   \
                            \
    for (;;) {              \
        prepare_to_wait(&wq, &__wait, TASK_INTERRUPTIBLE); \
        if (condition)        \
            break;            \
        if (!signal_pending(current)) {    \
            schedule();       \
            continue;            \
        }                   \
        ret = -ERESTARTSYS;   \
        break;        \
    }                  \
    finish_wait(&wq, &__wait);   \
} while (0)
{% endhighlight %}


在C语言中`{a,b,......,x}`的值等于最后一项x，因此Part1代码的返回值是__ret。

当进程等待的事件还没来临，也就是condition=0时，会调用Part2代码`__wait_event_interruptible(wq, condition, __ret)`。它做了如下事情：

+ 声明__wait进程节点
+ `prepare_to_wait`把__wait进程结点放到wq进程头节点中

如果这时等待事件来临，跳出Part2部分。如果没有来自处理器的信号且等待事件没有来临，进行schedule调度。schedule调度可以参见[
进程函数schedule()解读](http://huangtuzhi.github.io/2014/06/29/schedule)。调度会将当前置为TASK_INTERRUPTIBLE状态的进程从runqueue中删除，此进程不再参与调度，除非通过其他函数将这个进程重新放入到runqueue队列中，这个就是wake_up_interruptible()函数的作用。

------------------------------------------------------------------
##如何唤醒被wait_event_interruptuble睡眠的进程##

由上面的分析可以看出唤醒被wait_event_interruptuble睡眠的进程需要两个条件：

+ condition为真。满足此条件才能从Part2程序中的for循环跳出来。不然从schedule()返回的此进程一直会被`prepare_to_wait(&wq, &__wait, TASK_INTERRUPTIBLE)`置为TASK_INTERRUPTIBLE状态，接下来执行schedule()的结果是再次被从runqueue队列中删除。

+ 调用wake_up_interruptible()。这个函数会把队列中睡眠的进程放入到runqueue队列中，这样就可以被schedule()调度进入运行状态。

--------------------------------------------------------------------
##Reference##

[1].http://blog.csdn.net/tommy_wxie/article/details/12448913

[2].http://huangtuzhi.github.io/2014/06/29/schedule/

[3].Linux Device Driver.P269

[4].Understanding the Linux Kernel.P277~P279

