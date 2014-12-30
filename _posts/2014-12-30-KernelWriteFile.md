---
layout: post
title: "内核中读写文件"
description: ""
category: linux
tags: []
---

在linux内核驱动开发中，大多是把要实现的逻辑功能写成设备驱动的形式，设备驱动在文件系统中以设备文件的形式表示。应用层调用驱动只需要读写或者ioctl设备文件即可。

但有时也需要在内核中读写文件，显然open/read/write这些应用层的标准库方法用不了。这就需要利用利用kernel的一些函数，这些函数主要有`file_open()`,`file_read()`,`vfs_read()`,`vfs_write()`等。

----------------------------------------

##打开文件##
filp_open()在kernel中可以打开文件，其原形如下：

```strcut file* filp_open(const char* filename, int open_mode, int mode);```

该函数返回strcut file*结构指针，供后继函数操作使用，该返回值用IS_ERR()来检验其有效性。它和标准库open的参数形式相似。open和fopen的区别参见[1]。

--------------------------------------------------

##读写文件##
kernel中文件的读写操作可以使用vfs_read()和vfs_write，在使用这两个函数前需要说明一下get_fs()和 set_fs()这两个函数。

vfs_read() 和vfs_write()两函数的原形如下：
```
ssize_t vfs_read(struct file* filp, char __user* buffer, size_t len, loff_t* pos);

ssize_t vfs_write(struct file* filp, const char __user* buffer, size_t len, loff_t* pos);
```
这两个函数的第二个参数buffer，前面都有__user修饰符，这就要求这两个buffer指针都应该指向用空的内存，如果对该参数传递kernel空间的指针，这两个函数都会返回失败-EFAULT。但在Kernel中，我们一般不容易生成用户空间的指针，或者不方便独立使用用户空间内存。要使这两个读写函数使用kernel空间的buffer指针也能正确工作，需要使用set_fs()函数，其原形如下：

`void set_fs(mm_segment_t fs)`

该函数的作用是改变kernel对内存地址检查的处理方式，其实该函数的参数fs只有两个取值：USER_DS，KERNEL_DS，分别代表用户空间和内核空间，默认情况下，kernel取值为USER_DS，即对用户空间地址检查并做变换。那么要在这种对内存地址做检查变换的函数中使用内核空间地址，就需要使用set_fs(KERNEL_DS)进行设置。get_fs()一般也可能是宏定义，它的作用是取得当前的设置，这两个函数的一般用法为：

```
mm_segment_t old_fs;
old_fs = get_fs();
set_fs(KERNEL_DS);
...... //与内存有关的操作
set_fs(old_fs);
```
还有一些其它的内核函数也有用__user修饰的参数，在kernel中需要用kernel空间的内存代替时，都可以使用类似办法。

---------------------------------------------------
##示例##

```
void WriteSerial(char* buf)
{
    mm_segment_t old_fs;
    printk("write messages to file/n");
    if(file == NULL)
        file = filp_open("/dev/ttyS0",O_RDWR|O_APPEND|O_CREAT,0644 );
    if (IS_ERR(file)) {
        printk("error occured while opening file %s./n","/dev/ttyS0");
        return;
    }
    old_fs = get_fs();
    set_fs(KERNEL_DS);
    file->f_op->write(file, buf, sizeof(buf), &file->f_pos);
    //把buf数据写到串口中
    set_fs(old_fs);
}
```

----------------------------------------------------

##Reference##
[1].http://blog.sina.com.cn/s/blog_6f3ff2c90100mph8.html

[2].http://soft.chinabyte.com/os/421/11398421.shtml

