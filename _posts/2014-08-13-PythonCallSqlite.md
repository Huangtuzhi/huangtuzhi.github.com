---
layout: post
title: "Python访问Sqlite数据库"
description: "sqlite"
category: network
tags: [python]
---

##安装sqlite3##
sqlite是一个轻型的关系型数据库。它的设计目标是针对嵌入式设备，目前已经在很多嵌入式产品中使用了它。

笔者在ubuntu14.04环境下进行安装。

+ 执行命令 `sudo apt-get install sqlite sqlite3`,安装即可完成。
+ 执行命令 `sqlite -version`，可以查看 sqlite 的版本
+ cd ~下创建一个目录sqlite (`mkdir sqlite`)，执行命令`sqlite3 test.db`，创建一个名为test.db 的数据库
+ 输入 `create table mytable(ld,name,age);` 创建了一个名字叫mytabel的数据表，该数据表内定义了三个字段，分别为 ld、name、age。
+ 输入 `insert into mytable(ld,name,age) values(1, "huangyi",24);`向数据表中插入第1个数据;
输入 `insert into mytable(ld,name,age) values(2, "wangrubi",24);`向数据表中插入第2个数据;

执行命令 `select * from mytable;`可以显示数据表中的所有数据:

       sqlite> select * from mytable;
       ld|name|age
       1|huangyi|24
       2|wangrubi|24

--------------------------------------------
##sqlite python库##
sqlite库已经成为了python的标准库，接口和使用说明参见[1]。

> SQLite is a C library that provides a lightweight disk-based database that doesn’t require a separate server process and allows accessing the database using a nonstandard variant of the SQL query language. sqlite3 was written by Gerhard Häring and provides a SQL interface compliant with the DB-API 2.0 specification。

----------------------------------------------
##实现##
把python库提供的操作函数封装成类和成员函数的方式来调用。

{% highlight objc %}
#! /usr/bin/python
# -*- coding: utf8 -
import sqlite3
class SqliteFunction:
    def __init__(self,db_name):
        self.dbname = db_name
        try:
            self.conn = sqlite3.connect(db_name) 
            self.cur = self.conn.cursor()
            print("Database "+db_name+" is opened successfully!")
        except Exception as err:
            print(str(err))

    def close(self):
        try:
            self.conn.close()
            print("Database is closed successfully!")
        except Exception as err:
            print(str(err))

    def run(self,sql):
        try:        
            self.cur = self.conn.cursor()
            self.cur.execute(sql)
            self.conn.commit()
            print('['+sql+']'+"runs successfully")
            return 0
        except Exception as err:
            self.conn.rollback()
            print(str(err))
            return -1

SqliteDB=SqliteFunction("test.db")
SqliteDB.run("insert into mytable(ld,name,age)values(3,'vitual',0);")
SqliteDB.run("select * from mytable;")
SqliteDB.close()   
{% endhighlight %} 

##总结##
以上就是使用python操作sqlite数据库的简单例子，其实开始笔者想做的是用C++调用Python接口来操作sqlite数据库，借此复习一下python和C++。其实sqlite [3]中已经直接提供了C/C++接口。如果在嵌入式系统中需要数据库存储用户数据或者大量的命令参数，sqlite是一个不错的选择。
--------------------------------------------

##Reference#
[1].http://docspy3zh.readthedocs.org/en/latest/library/sqlite3.html

[2].http://my.oschina.net/mlgb/blog/288261

[3].http://www.sqlite.org/cintro.html

[4].http://www.blogjava.net/xylz/archive/2012/09/25/388519.html
