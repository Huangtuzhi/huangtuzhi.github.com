---
layout: post
title: "andriod访问网NetworkOnMainThreadException解决方法"
description: "Andriod"
category: Network
tags: [andriod]
---

##访问网络##
andriod应用在进行网络访问时，需要在Manifest文件中加入权限访问允许：

<uses-permission android:name="android.permission.INTERNET"/> 

否则会抛出异常。

在C8815手机上进行测试，写一个Client端与Mini2440开发板上C写的的Server进行Socket通信。应用出现闪退。而用这种调试模式无法显示调试信息，只是提示无法捕捉异常。

于是安装Genmotion模拟器进行调试。具体介绍和安装方法见http://www.genymotion.com/。

安装模拟器后，eclipse出现错误信息:android.os.NetworkOnMainThreadException。

在[1]找到解决方法。

在MainActivity文件的setContentView(R.layout.activity_main)下面加上如下代码

{% highlight objc %}
    if (android.os.Build.VERSION.SDK_INT > 9) {
    StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
    StrictMode.setThreadPolicy(policy);
    }
{% endhighlight %}

Client和Server能正常进行通信。

这个异常出现的原因是：

> The exception that is thrown when an application attempts to perform a networking operation on its main thread.This is only thrown for applications targeting the Honeycomb SDK or higher. Applications targeting earlier SDK versions are allowed to do networking on their main event loop threads, but it's heavily discouraged. See the document Designing for Responsiveness.
Also see StrictMode.

简单地说，就是一个APP如果在**主线程**中请求网络操作，将会抛出此异常。Android这个设计是为了防止网络请求时间过长而导致界面假死的情况发生。关于 StrictMode类控制，请见[2]。

-----------------------------------------------------
##References##
[1].http://www.2cto.com/kf/201402/281526.html

[2].http://hb.qq.com/a/20110914/000054.htm

