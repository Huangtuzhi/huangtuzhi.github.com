---
layout: post
title: "实现vector内存管理类"
description: ""
category: C&&C++
tags: []
---

标准库中的vector是一个模板，可以实例化为存储任何对象的vector。我们实现一个简单的用于存储string的vector，命名为StrVec。

-----------------------------

## 申请内存
vector类将元素保存在连续的内存中，它会预先分配足够的内存来保存元素。添加元素的成员函数都会检查是否有空间容纳更多的元素。如果有，成员函数会在下一个可用位置构造一个对象;如果没有可用空间，vector会重新分配空间。

StrVec使用类似的策略，使用一个allocator来获取raw memory。allocator分配的内存是原始未构造的，所以需要在添加元素时用construct成员在原始内存中创建对象。使用如下：

```
    allocator<string> alloc;
    string s;
    auto const p = alloc.allocate(n);
    alloc.construct(p++, s);
```

-----------------------------

## StrVec定义

```
class StrVec
{
public:
    StrVec():
        elements(nullptr), first_free(nullptr), cap(nullptr) { }
    StrVec(const StrVec&);
    StrVec& operator=(const StrVec&);
    ~StrVec();
    void push_back(const string&);
    size_t size() const { return first_free - elements; }
    size_t capacity() const { return cap - elements; }
    string* begin() const { return elements; }
    string* end() const { return first_free; }
private:
    static allocator<string> alloc;
    void chk_n_alloc()
    { if(size() == capacity()) reallocate(); }
    pair<string*, string*> alloc_n_copy(const string*, const string*);
    void free();
    void reallocate();
    string* elements;
    string* first_free;
    string* cap;
};
allocator<string> StrVec::alloc; 

```

其中定义了三个指针elements，first_free和cap，分别指向内存开始，空余内存开始和内存结束位置。

size()是已存储元素的大小，capacity()是可容纳元素的大小。

注意静态成员在类外定义才能使用，不然出现undefined reference to StrVec::alloc错误，参见[stackoverflow](http://stackoverflow.com/questions/272900/vectorpush-back-odr-uses-the-value-causing-undefined-reference-to-static-clas)。

-----------------------------

##alloc_n_copy成员

```
pair<string*,string*> StrVec::alloc_n_copy(const string* b,const string* e)
{
    auto data = alloc.allocate(e - b); //分配内存
    return {data, uninitialized_copy(b, e, data)}; //进行拷贝
}
```

alloc_n_copy成员用来拷贝和赋值，开辟一块新的内存空间，将b～e间元素拷贝到新空间。

-----------------------------

## operator=
拷贝控制成员是比较有意思的部分，operator=承担了拷贝构造函数和析构函数两个功能：对等式左边部分析构，对右边部分进行拷贝构造。

```
StrVec& StrVec::operator=(const StrVec& rhs)
{
    auto data = alloc_n_copy(rhs.begin(), rhs.end());
    free();
    elements = data.first;
    first_free = cap = data.second;
    return *this;
}
```
它先给等式右边的元素分配新的内存，再析构左边的对象并释放分配的内存，最后进行赋值。

完整的实现存放在[Github](https://github.com/Huangtuzhi/CppPrimer/blob/master/ch13/ex13_39_40.cpp)。

-----------------------------

##Reference
[1].C++ Primer. Page464~470
