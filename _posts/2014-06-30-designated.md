---
layout: post
title: "结构体Desinated initializer在linux内核中的使用"
description: "c"
category: C&&C++
tags: [linux]
---

##缘起##
   在2.6内核版本中对ARM平台的支持引入了platform的概念（相当于板级支持包BSP），开发底层驱动设备时，首先要确认设备的资源信息，比如设备的地址【1】。
设备的资源用结构体paltform_device来描述，定义在kernel\include\linux\platform_device.h【2】中

{% highlight objc %}
    struct platform_device 
    {
    const char * name;
    u32  id;
    struct device dev;
    u32  num_resources;
    struct resource * resource;
    };
{% endhighlight %}

该结构体中还有一个嵌套的结构体resource，定义在 kernel\include\linux\ioport.h中

  ![resource][5]

（举个例子，在\linux-3.11.1\linux-3.11.1\arch\arm\plat-samsung\devs.c中也可以看见类似的定义）
下面是写一个用PWM调制发送红外的驱动里定义资源的结构体：
  
{% highlight objc %}

    static struct resource controler_resource[]={
    s[0] = {
        .start = PWM_REG_BASE,
        .end   = PWM_REG_END,
        .flags = IORESOURCE_MEM,
    },
    [1] = {
        .start = TIMER0_IRQ,
        .end   = TIMER4_IRQ,
        .flags = IORESOURCE_IRQ,
    },
    [2] = {
        .start = GPH0_REG_START,
        .end   = GPH0_REG_END,
        .flags = IORESOURCE_MEM,
    },
    }
{% endhighlight %}

-----------------------------
##解释##
看到.start = PWM_REG_BASE这样的写法可能会比较陌生，这其实是C99中支持的结构体的指定初始化项目 【3】，就是不需要对结构体所有成员进行赋值，只对需要的成员赋值。
现定义一个结构体：

  
{% highlight objc %}
    struct book
    {
    char title[MAXTITL];
    char author[MAXAUTL];
    float value;
    }; 
{% endhighlight %}

如果只需初始化value的话可以这样做：
struct book Redmansion={.value=1,};
注意：

 - 结构体指定初始化时，用到的就是点运算符加变量名，不许要指明类型，程序会自动匹配。
 - 右边的值类型尽量要匹配左边的类型。
 - 初始化时，变量之间可以用逗号分开，也可以用分号分开。最后的}前可以加逗号也可以不加。
 - 整个结构体外边不要忘记分号。

---------------------
##测试: Red Mansion##
在windows VC++下写入如下测试代码，看能否支持这种赋值。

    <!-- lang: cpp -->
    #include <stdio.h>
    void main()
     {
    struct book{
    char title[7];
    char author[10];
    float value;};
    struct book Redmansion={.author="Caoxueqin",};
    printf("%s",Redmansion.author);
     }
结果显示RedMansion的作者是Caoxueqin，这是对的，必须是对的,
当然译作Dream of the Red Mansion会比Chamber好些。

----------------------------
##Reference##
[1].http://blog.chinaunix.net/uid-24807808-id-3219820.html
[2].http://lxr.free-electrons.com/source/include/linux/platform_device.h?a=sh
[3].《C Primier Plus》。Page383
[4].http://en.wikipedia.org/wiki/Dream_of_the_Red_Chamber

[5]: http://static.oschina.net/uploads/space/2013/1211/225055_Jfyb_1420197.jpg

