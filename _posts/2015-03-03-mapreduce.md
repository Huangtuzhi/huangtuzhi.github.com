---
layout: post
title: "python中map和reduce的应用"
description: ""
category: python
tags: []
---

map和reduce在那篇经典的论文 _MapReduce: Simplified Data Processing on Large Clusters_中这么定义

> MapReduce is a programming model and an associated implementation for processing and generating large data sets. Users specify a map function that processes a key/value pair to generate a set of intermediate key/value pairs, and a reduce function that merges all intermediate values associated with the same intermediate key.

------------------------------------------------------------------

##map##
map(function, iterable, ...)的第一个参数是一个函数，第二个参数接受一个iterable对象（字符串，列表，元组等）。该函数返回一个列表。如：

```
def func(x):
    return x * x

result = map(func, [1, 2, 3, 4, 5, 6])
print result
```

其中func分别作用在1, 2, 3, 4, 5, 6上，因此返回结果是列表[1, 4, 9, 16, 25, 36]。

现在可以利用map()函数，把用户输入的不规范的英文名字，变为首字母大写，其他小写的规范名字。输入：['adam', 'LISA', 'barT']，输出：['Adam', 'Lisa', 'Bart']。

```
def lower2upper(s):
    loop = 0
    l = ''
    for n in s:
        if n.islower() and loop == 0:
            l = l + n.upper()
            loop += 1
        elif n.isupper() and loop == 0:
            l = l + n
            loop += 1
        elif n.islower() and loop != 0:
            loop += 1
            l = l + n
        else:
            l = l + n.lower()
    return l
 
result = map(lower2upper, ['adam', 'LISA', 'barT'])
print result
```

-------------------------------------------------------

##reduce##
reduce(function, iterable[, initializer])把函数从左到右累积作用在元素上，产生一个数值。如reduce(lambda x, y: x+y, [1, 2, 3, 4, 5])就是计算((((1+2)+3)+4)+5)。

Python提供的sum()函数可以接受一个list并求和，现实现一个prod()函数，可以接受一个list并利用reduce()求积。

```
def prod(list):
    def multiply(x, y):
        return x * y
    return reduce(multiply, list)
 
print prod([1, 3, 5, 7])
```

-----------------------------------------------------------------

##map和reduce##
我们可以综合利用map和reduce来完成一个简单的字符串到数字的程序。

```
def str2int(s):
    def fn(x, y):
        return x * 10 + y
    def char2num(s):
        return {'0':0, '1':1, '2':2, '3':3, '4':4, '5':5, '6':6, '7':7, '8':8, '9':9}[s]
    return reduce(fn, map(char2num, s))
 
print str2int('12345')
```

其中map用于将字符串拆分为对应的数字，并以list的方式返回。reduce用来累加各个位上的和。

----------------------------------------------------

##filter##
filter(function, iterable)使用function的规则滤除iterable对象中不满足规则的元素。

```
def is_odd(n):
    return n % 2 == 1
    
result = filter(is_odd, [1, 2, 3, 4, 5, 6])
print result
```
结果是[1, 3, 5]。

现在尝试用filter()删除1~100中的素数。

```
def is_prime(n):
    div = 2
    if (n ==1):
        return 0
    elif (n == 2):
        return 1
    else:
        while(div < n):
            if(n % div == 0):
                return 0
            else:
                div += 1
        return 1

def del_prime(n):
    if not(is_prime(n)):
        return n
result2 = filter(del_prime, range(1,100))
print result2
```

判断素数的算法有很多优化，参见_编程珠玑(续)_中的第一章性能监视工具。


---------------------------------------------------

##Reference##
[1].https://docs.python.org/2/library/functions.html#reduce

[2].http://www.liaoxuefeng.com/

[3].http://blog.csdn.net/tianshuai1111/article/details/7636856
