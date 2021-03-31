---
layout: post
title: "智能指针进行资源管理"
description: ""
category: C&&C++
tags: []
---

我们知道shared_ptr是C++11的新标准，可以自动回收动态内存。同时它也可以管理其它资源。

比如网络编程里的连接。

-------------------------------------------------------

##语法##
shared_ptr语法如下：

    shared_ptr<T> p(q, d)

p接管了内置指针q所指对象的所有权。q必须保证能强制转换为T*类型。

p将调用回调函数d来代替delete回收资源。

-------------------------------------------------------

##应用##

```
struct destination
{
    string ip;
    int port;
    destination(string _ip, int _port): ip(_ip), port(_port){};
};

struct connection
{
    string ip;
    int port;
    connection(string _ip, int _port): ip(_ip), port(_port){};
};

connection connect(destination *d)
{
    shared_ptr<connection> pConn(new connection(d->ip, d->port));
    cout << "creating connection(" << pConn.use_count() << ")" << endl;
    return *pConn;
}

connection disconnect(connection& p)
{
    cout << "connection close(" << p.ip << ":" << p.port << ")" << endl;
}

void deleter(connection* p)
{
    disconnect(*p);
}

void f(destination &d)
{
    connection c = connect(&d);
    //shared_ptr<connection> p(&c, deleter);
    shared_ptr<connection> p(&c, [](connection* p)
                             {disconnect(*p);});
    cout << "Resource has been reaped\n";
}

int main()
{
    destination des("202.201.13.12", 8888);
    f(des);
}

```
如上所示，当f退出时，p被销毁，connection会被正确关闭。

程序打印结果：

```
creating connection(1)

Resource has been reaped

connection close(202.201.13.12:8888)

```

-------------------------------------------------------

##Reference##
[1].C++ Primer. P416.

