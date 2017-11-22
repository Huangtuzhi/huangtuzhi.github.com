---
layout: post
title: "用继承和反射机制实现业务扩展"
description: ""
category: 
tags:
comments: yes
---

以前学 C++ 的时候，总是听说可以用继承和基类指针去扩展业务逻辑，而对整体项目架构的侵入很小。其实对这里理解并不深。最近在看其他同学写的搜索引擎新框架时，发现这种设计可以将系统框架和业务逻辑完全解耦开。于是决定实现一下。

----------

## 基本操作

```C
class BaseModule
{
public:
	virtual ~BaseModule(); 

	virtual string GetData();
};

class BusinessModuleA: public BaseModule
{
public:
	virtual string GetData(); // 卖出 00700.HK
};

class BusinessModuleB: public BaseModule
{
public:
	virtual string GetData(); // 签下 Playerunknown's Battlegrounds
};

int main 
{
	// PartA，使用 ModuleA 处理 
	BaseModule * module_a = new BusinessModuleA();
	cout << module_a->GetData() << endl;

	// PartB，使用 ModuleB 处理 
	BaseModule * module_b = new BusinessModuleB();
	cout << module_b->GetData() << endl;
}
```

先定义一个 BaseModule 类，里面有一个虚成员函数 GetData()，它负责处理所有的业务逻辑，在 BaseModule 中不实现。再定义一个 BusinessModuleA 类，它继承自 BaseModule 类，这个类实现了自己的 GetData() 方法，比如在这个方法中卖出所有的 00700.HK，并返回当天的收益。同理，再定义一个 BusinessModuleB 类，它也实现了自己的 GetData() 方法，比如在这个方法中签下「Playerunknown's Battlegrounds」，并返回在国服上线的日期。

在使用时，用两个基类指针分别指向新建的 BusinessModuleA、BusinessModuleB 实例。为什么用基类指针呢？因为基类指针的命名（尽管子类名不同，但基类指针都是一个名）和行为（调用虚成员函数）是统一的，在 module_a->GetData() 进行调用时，编译器会自动去分辨到底使用哪个子类的方法。

这样做的好处是什么呢，我们可以将只含 PartA 的代码编译成二进制放在 mmstock1 线上机器上作为股票业务的服务，将只含有 PartB 的代码生成的二进制放在 mmgame1 机器上作为游戏业务的服务。如果仅仅是这样似乎没有必要搞这么复杂，单独分开去写代码也可以。
但如果 BaseModule 类中还有其他大量的逻辑，比如处理网络连接、监控服务状态、收集错误日志呢。这些公用的方法被放在了基类中，而独特的业务逻辑被抽出来放在了各自的子类里。

现在新开展一个业务，只需要新建一个子类继承 BaseModule，在 GetData() 类中实现业务，最后在 main 函数中修改为 new 这个子类即可。

但这种方式有一些问题，

1、需要在入口文件中添加新增业务的头文件

2、main 方法中的代码是属于系统框架的，不能每次新增业务都去改动框架代码

------------

## 还是基本操作

因而需要引入反射机制来改善上面的缺点，整个 repo 位于 [how-to-extend-business](https://github.com/Huangtuzhi/code-gist/tree/master/Cpp/how-to-extend-business)。还是基本操作，都坐下。

C++ 本身不支持反射，只能去模拟这种机制，即用类名去获取类的实例。需要做到下面两方面：

1、有一个单例类，其成员变量 map<string, Creator> m_creator_registry 存放（类名，创建对应类实例的函数指针）

2、每一个独立业务的子类中，实现自己的 Creator，即返回子类实例的函数

3、每一个独立业务的子类中，向 m_creator_registry 注册 

如使用 `gcc -E -C business_a.cpp > out.txt` 查看

`REGISTER_MODULE(BusinessModuleA, "BusinessModuleA");` 这一行

宏展开后的结果，就是实现了 2 和 3 两部分。

```C
BaseModule* ObjectCreator_register_name_BusinessModuleA()
{ 
	return new BusinessModuleA; 
} 

ObjectCreatorRegister_ModuleRegister 
g_object_creator_register_name_BusinessModuleA("BusinessModuleA",
ObjectCreator_register_name_BusinessModuleA);
```

这样改造以后，新增业务时只需要新建一个子类继承 BaseModule，在 GetData() 类中实现业务，在最后加上 REGISTER_MODULE 宏。

-------------

## 动态配置

在代码的 main 函数中可以看到依然要指定 GET_MODULE 中的类名

```C
// 使用反射获取 ModuleA 实例
BaseModule* business_a = GET_MODULE("BusinessModuleA");
cout << business_a->GetData() << endl;

// 使用反射获取 ModuleB 实例
BaseModule* business_b = GET_MODULE("BusinessModuleB");
cout << business_b->GetData() << endl;
```

怎样才能完全不修改系统框架呢？

可以再加入一个配置类，配置类去读取服务器指定路径下的配置文件。这样可以在配置文件中动态修改类名了，新增一个业务，修改一下配置项即可。

-------------

## 参考

[PUBG](https://mp.weixin.qq.com/s/FREXun1jWP5zH4prVEVO6Q)

[00700.HK](https://www.futunn.com/quote/stock?m=hk&code=00700)

[C++ 实现通过类名来进行实例化](http://www.cnblogs.com/cycxtz/p/4871927.html)

[C++ 反射机制的简单实现](http://www.cnblogs.com/xudong-bupt/p/6643721.html)

