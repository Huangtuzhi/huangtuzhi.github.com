---
layout: post
title: "仿singleten模式的客户-服务方法"
description: ""
category: c&&c++
tags: []
---

在看一个豆瓣FM项目的QT程序。里面用到了类似单例模式（singleten）的客户-服务器方法，用来控制该程序只能运行一个实例进程。

------------------------------------------------
##singleten##
所谓的单例模式是指一个类只有一个实例，并提供一个访问它的全局访问点，参见_大话设计模式_ P213。

```
class Singleton
{
    private:
    Singleton(){}
    static Singleton *instance;
    public:
    static Singleton* GetInstance()
    {
        if(instance == NULL)
        instance = new Singleton();
        return instance;
    }
}
```

可以看出此类的构造函数为私有，因此不能用new来实例化对象。只能通过静态方法(方法调用独立于对象)：

` Singleton *p1 =  Singleton :: GetInstance() `

------------------------------------------------
##使用QLocalSocket##
我们再看一下QT里是采用什么方法。

```
QLocalSocket socket;//Connect to the local server
socket.connectToServer(LOCAL_SOCKET_NAME);
if (socket.waitForConnected(500)) {
        qWarning() << "There is already a instance running, /
        raising it up";
        return 0;
}

QLocalServer server(&w);
 w.connect(&server, &QLocalServer::newConnection, [&] () {
     if (w.isHidden())
         w.show();
     else
         w.activateWindow();
     qDebug() << "Raise window";
    }
);
server.listen(LOCAL_SOCKET_NAME);

```

这里，先用QLocalSocket新建连接来连接本地服务器，如果能连上，说明已经存在服务器，即有一个实例进程了。这时退出。

QLocalServer则新建一个服务器，同时监听客户端消息。

------------------------------------------------------------------------
##Reference##
[1].http://www.raychase.net/2556

[2].http://blog.csdn.net/hackbuteer1/article/details/7460019

[3].http://blog.csdn.net/yangxiao_0203/article/details/11492137
