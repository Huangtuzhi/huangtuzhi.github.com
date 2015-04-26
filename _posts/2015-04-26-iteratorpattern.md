---
layout: post
title: "C++迭代器模式"
description: ""
category: C&&C++
tags: []
---

C++ Primer 12章动态内存中定义了一个StrBlob类，它实现了一个新的集合类型，和vector类似。这么定义可以允许多个对象共享相同的元素，其实实质就是浅拷贝，而vector是深拷贝。下面借助这个类实现一下迭代器。用StrBlob存入一个文件的每行，用StrblobPtr迭代器打印每个元素。

----------------------------------------

##StrBlob类

```
class StrBlob
{
    friend class StrBlobPtr;
public:
    StrBlob(): data(make_shared<vector<string>>()) { }
    StrBlob(initializer_list<string> il): 
        data(make_shared<vector<string>>(il)) { }
    int size() const { return data->size(); }
    bool empty() const { return data->empty(); }
    void push_back(const string& t) { data->push_back(t); }
    void pop_back();

    string& front();
    string& back();

    StrBlobPtr begin();
    StrBlobPtr end();
private:
    shared_ptr<vector<string>> data;
    void check(int i, const string& msg) const;
};

StrBlobPtr StrBlob::begin() 
{
    return StrBlobPtr(*this); 
}

StrBlobPtr StrBlob::end()
{
    return StrBlobPtr(*this, data->size()); 
}

```
StrBlobPtr作为迭代器，为了使StrBlobPtr能访问StrBlob的私有成员data，将它定义为friend。

data是指向vector<string>的指针，用来保存元素。

--------------------------------------------

##StrBlobPtr类

```
class StrBlobPtr
{
public:
    StrBlobPtr(): curr(0){ }
    StrBlobPtr(StrBlob &a, size_t sz = 0):
            wptr(a.data), curr(sz) { }
    string& deref() const;
    StrBlobPtr& incr();
private:
    shared_ptr<vector<string>> check(size_t i, const string& msg) const;
    weak_ptr<vector<string>> wptr;
    size_t curr;
};

string& StrBlobPtr::deref() const
{
    auto p = check(curr, "dereference past end");
    return (*p)[curr];
}

StrBlobPtr& StrBlobPtr::incr()
{
    check(curr, "increment past end of StrBlobPtr");
    ++curr;
    return *this;
}

```
StrBlobPtr有两个构造函数，第一个默认构造函数生成空的StrBlobPtr，初始化列表将curr显示初始化为0，将wptr隐式初始化为空的weak_ptr。

第二个构造函数接受一个StrBlob引用和一个可选的索引值(有默认参数，所以可以不写)，wptr被绑定到StrBlob的shared_ptr指针上，对元素具有访问权了。

我们观察StrBlob的成员函数StrBlob::begin()，发现它返回StrBlobPtr类。StrBlobPtr(\*this)调用构造函数，因为有默认参数，所以调用的是第二个构造函数，相当于StrBlobPtr(\*this， 0)[1]。同理StrBlob::end()也调用这个构造函数，只不过它的curr指向vector的末尾。

现在打印出StrBlob的所有元素

```
StrBlob Blob;
StrBlobPtr ptr;
for(int i=0; i<Blob.size(); i++){
	ptr = ptr.incr();
	cout << ptr.deref()<< endl;
}
```

其中incr()用来增加索引，deref()用来解引用取值。这和标准的vector是不是很像?

```
vector<int>::iterator iter;
for(iter=vi.begin();iter!=vi.end();++iter)
    cout<<*iter;   
```
但是还差一些，我们需要重载++，!=，*这三个运算符。

```
StrBlobPtr& operator ++(int) { this->curr++; }
bool operator !=(const StrBlobPtr& rhs){
    return (this->curr != rhs.curr);
}
string& operator *(){
    auto p = check(curr, "dereference past end");
    return (*p)[curr];
}
```

这样上述遍历代码可以写为

```
StrBlobPtr iter;
for(iter=Blob.begin(); iter!=Blob.end(); iter++){
cout << *iter << '\n';
```

++实现incr()的功能，*实现deref()的功能。

需要注意++的重载，StrBlobPtr& operator ++(int)加入int表示是后++的重载，而StrBlobPtr& operator ++()表示前++的重载。[2]

这样就实现了StrBlob类的迭代器，完整的实现代码放在[Github](https://github.com/Huangtuzhi/CppPrimer/blob/master/ch12/ex12_20.cpp)。

输出结果如下:

![图片](/assets/images/iteratorpattern1.png)

> 不要温和地走进那个良夜
老年应当在日暮时燃烧咆哮
怒斥，怒斥光明的消逝
虽然智慧的人临终时懂得黑暗有理
因为他们的话没有迸发出闪电，他们
也并不温和地走进那个良夜


--------------------------------------

##Reference
[1].http://stackoverflow.com/questions/29867449/how-smart-pointer-weak-ptr-is-bound-to-shared-ptr-in-this-case

[2].http://blog.csdn.net/ozwarld/article/details/8263868