---
layout: post
title: "手工休眠问题"
description: ""
category: linux
tags: []
---

写网络虚拟驱动的时候，发现内核的read函数会在上层应用调用了一次之后永远进入休眠状态，无法被唤醒。出现这个问题的原因可能有两个：

1.驱动的read函数休眠设置不正确

2.负责唤醒read进程的函数没有正确执行

-----------------------------------------------------------

##手工休眠##

    ssize_t device_read(struct file *file,char *buffer,
    size_t length, loff_t *offset)
    {
    int i;
    struct ed_device *edp;
    DECLARE_WAITQUEUE(wait,current);
    edp = (struct ed_device *)file->private_data;
    add_wait_queue(&edp->rwait,&wait);
    for(;;){
        set_current_state(TASK_INTERRUPTIBLE);
        if ( file->f_flags & O_NONBLOCK)
            break;
        if ( edp->tx_len > 0)
            break;//直接处理数据
        if ( signal_pending(current))
            break;//处理伪唤醒
		printk("Start going to sleep\n");
           schedule();//进行进程调度
		printk("return from scheduler\n");
    }
    printk("Have been waked\n");
    set_current_state(TASK_RUNNING);
    remove_wait_queue(&edp->rwait,&wait);
    spin_lock(&edp->lock);
    if(edp->tx_len == 0) {
         spin_unlock(&edp->lock);
         return 0;     
    }
    else{...}
    spin_unlock(&edp->lock);
    return length;
    }

由此可见手工休眠需要这些设置

1.在前面已经用`DECLARE_WAIT_QUEUE_HEAD(rwait)`定义了等待队列头rwait，这里需要再用`DECLARE_WAITQUEUE(wait,current)`定义等待队列项。current指当前进程。

2.将等待队列项wait加入等待队列头rwait，`add_wait_queue(&edp->rwait,&wait)`。该队列会在进程等待的条件满足时唤醒它。在其他地方写相关代码，在事件发生时，对等待队列执行唤醒操作。这个程序是由kernel_write中的wake_up_interruptible唤醒,即当有数据写到buffer中可供应用层读写时。

    ssize_t kernel_write(const char *buffer,size_t length,int buffer_size)
    {
    if(length > buffer_size )
    length = buffer_size;
    memset(ed[ED_TX_DEVICE].buffer,0,buffer_size);
    memcpy(ed[ED_TX_DEVICE].buffer,buffer,buffer_size);
    ed[ED_TX_DEVICE].tx_len = length;
    wake_up_interruptible(&ed[ED_TX_DEVICE].rwait);	
    printk("function [kernel_write] is called \n");
    return length;}

3.在每次的for循环中将当前的进程状态置为TASK_INTERRUPTIBLE，意思是可由信号唤醒，但不是事件唤醒，所以要对这个伪唤醒做处理
    
    if ( signal_pending(current))
    break;

4.`file->f_flags & O_NONBLOCK`中O_NONBLOCK表示不等待。如果在用户层采用
  
    fd = open("/dev/device", O_RDWR | O_NONBLOCK)

读，则O_NONBLOCK会被置为1，为非阻塞读，会立刻返回是否读到数据。如果不设置这个标志，则是阻塞读。应用层的read的阻塞&&非阻塞设置是在这里实现的。

5.如果buffer中有数据`edp->tx_len > 0`，则直接处理数据，不进行休眠。没数据就会使用调度函数schedule()使当前进程休眠，而去执行其他的进程。

6.一旦kernel_write函数执行，会从schedule()函数返回，执行whie的下一次循环。这时buffer里有数据，因而break脱离while循环。这时把当前进程的状态设为TASK_RUNNING，移出等待队列。

进行测试，发现当为阻塞读时，device_read停在Start going to sleep。当为非阻塞读时，会一直打印信息Have been waked。两种情况下都无法显示buffer中的数据，或许是因为应用层的read调用导致buffer里再也无法接受数据。



--------------------------------------------------------------------

##Reference##
[1].http://www.linuxidc.com/Linux/2011-10/44429p2.htm

[2].http://blog.sina.com.cn/s/blog_5f84dc840100v3j1.html

[3].http://blog.csdn.net/yikai2009/article/details/8653697
