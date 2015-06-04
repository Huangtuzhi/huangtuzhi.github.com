---
layout: post
title: "使用Nginx反向代理Flask站点"
description: ""
category: 服务器
tags: []
---

Nginx实际上只能处理静态资源请求，那么对于动态请求怎么做呢。这就需要用到Nginx的`upstream`模块对这些请求进行转发，即**反向代理**。这些接收转发的服务器可以是Apache、Tomcat、IIS等。示意图如下：

![](/assets/images/proxy-1.png)

现在对一个Python Flask的站点进行反向代理设置，站点的源码存放在[Github](https://github.com/Huangtuzhi/GoLink)。在本机Min17中目录如下：

```
/
+- srv/
  +- www/
    +- GoLink/       <-- Web App根目录
      +- www/        
      |  +- static/  <-- 存放静态资源文件
      |  +- index.py <-- Python源码
```

--------------------------------------------

## 部署方式

由于flask是单进程处理请求的，不像Tornado的异步，同时访问的人数稍微过多，就会出现阻塞的情况，导致Nginx出现502的问题。而Gunicorn可以指定多个工作进程，这样就可以实现并发功能。

![](/assets/images/proxy-2.png)

Nginx可以作为服务进程直接启动，但Gunicorn还不行。可以使用Supervisor管理Gunicorn进行自启动。

总结一下我们需要用到的服务有：

Nginx：高性能Web服务器+负责反向代理；

gunicorn：高性能WSGI服务器；

gevent：把Python同步代码变成异步协程的库；

Supervisor：监控服务进程的工具；

在Linux服务器上可以直接安装上述服务：

```
$ sudo apt-get install nginx gunicorn python-gevent supervisor
```

--------------------------------------------

## 配置Nginx
Nginx配置文件位于`/usr/local/nginx/conf/nginx.conf`，为了便于管理，新建一个`site`文件夹存放我们对配置的添加更改。在`site`中新建`app.conf`配置文件。

在`nginx.conf`中添加

```
http {
    include       sites/*.conf;
    # ...
}
```

在`app.conf`中添加

```
server {
    listen      80; # 监听80端口

    root        /srv/www/GoLink/www; 
    server_name localhost; # 配置域名

    # 处理静态资源:
    location ~ ^\/static\/.*$ {
        root /srv/www/GoLink/www;
    }

    # 动态请求转发到8000端口(gunicorn):
    location / {
        proxy_pass       http://127.0.0.1:8000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

重新加载Nginx配置文件：

```
$ sudo .nginx -s reload
```

--------------------------------------------

##配置Supervisor

编写一个Supervisor的配置文件`golink.conf`，存放到`/etc/supervisor/conf.d/目录下`：

```
[program:golink]
command     = /usr/bin/gunicorn --bind 127.0.0.1:8000 
--workers 3 --worker-class gevent index:app
directory   = /srv/www/GoLink/www
user        = www-data
startsecs   = 3

redirect_stderr         = true
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
```
参数解释

> --workers: The number of worker processes for handling requests. A positive integer generally in the 2-4 x $(NUM_CORES) range. 

> --worker-class: The type of workers to use.

启动后台服务

```
$ sudo supervisorctl reload
$ sudo supervisorctl start golink
$ sudo supervisorctl status
golink    RUNNING    pid 13636, uptime 0:00:27
```

这时在浏览器中输入 `http://127.0.0.1：80`即可访问网站。

还有，又一年过去了。纪念。

> 毕竟西湖六月中，风光不与四时同。

--------------------------------------------

## 参考

[http://rfyiamcool.blog.51cto.com/1030776/1276364](http://rfyiamcool.blog.51cto.com/1030776/1276364)

[http://spacewander.github.io/explore-flask-zh/14-deployment.html](http://spacewander.github.io/explore-flask-zh/14-deployment.html)

[http://docs.gunicorn.org/en/latest/settings.html#settings](http://docs.gunicorn.org/en/latest/settings.html#settings)