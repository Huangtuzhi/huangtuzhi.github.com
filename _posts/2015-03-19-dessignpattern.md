---
layout: post
title: "遇到的设计模式"
description: ""
category: algorithm
tags: []
---

Gang of Four在_Design Pattern_中写到设计模式分为三类：创建型模式(Creational Patterns,通常和对象的创建有关，涉及到对象实例化的方式，有Singleton，Factory Method, Builder, Prototype等)，行为型模式(Behavioral Patterns，通常和对象间通信有关)，结构型模式(Structural Patterns,描述如何组合类和对象以获得更大的结构)。其中比较常见的模式有Singleton，Factory，代理，装饰器模式等。

-----------------------------------------------

##单例模式##
单例模式是最简单的设计模式，但如果考虑线程安全就会十分复杂。一个简单的Singleton如下所示，它把类的构造函数私有化从而不能用在类外实例化对象，同时也禁用了拷贝构造函数()和拷贝复制运算符=(C++ Primer13章)。但它提供了一个供访问的全局节点GetInstance()，注意这里类只能在堆上实例化(new)，同时不能被继承。那么问题来了，如何设计一个只能在堆上或栈上实例化的类[2]。


```
class Singleton
{
public:
	static Singleton* GetInstance()
	{
		if(NULL == instance)
		{
			instance = new Singleton;
		}
	return instance;
	}

	static void ReleaseInstance(Singleton* instance)
	{
		//Lock();//借用其它类来实现，如boost
		if(NULL != instance)
		{
			delete instance;
			instance = NULL;
		}
		//UnLock()
	}

private:
	Singleton()
	{
		instance = NULL;
		printf("Singleton begin constructing\n");
		printf("Singleton end constructing\n");		
	}

	virtual ~Singleton()
	{
		printf("Singleton Destruct\n");		
	}

private:
	Singleton(const Singleton&){};
	Singleton& operator = (const Singleton &){};

private:
	static Singleton* instance;	
};

int main(void)
{
	Singleton* A = Singleton::GetInstance();
	Singleton::ReleaseInstance(A)//注意这里要手动释放申请的资源，防止内存泄漏
	return 0;
}

```

这是一个所谓的“懒汉”模式，在调用GetInstance时才进行内存分配。
上面的单例模式线程不安全是因为在多线程模式下，可能会同时判断`NULL == instance`，从而生成多个实例。

```
class Singleton2
{
public:
	static Singleton2 & GetInstance()
	{
		//Lock(); 
		static Singleton2 sg;
		return sg;
		//
	}

	void Print()
	{
		printf("Singleton2 count = %d \n", m_count);
	}

private:
	int m_count;
	Singleton2()
	{
		printf("Begin construct Singleton2, m_count = %d \n", m_count);
		m_count = 100;
		printf("End construct Singleton2, m_count = %d \n", m_count);
	}

	~Singleton2()
	{
		printf("Deconstruct Singleton2 \n");
	}

private:
	Singleton2(Singleton2&){};
	Singleton2& operator=(Singleton2&){};
};

int main()
{
	Singleton2& instance = Singleton2::GetInstance();
	instance.Print();
	return 0;
}

```
这是另外一个“懒汉”单例模式，单例对象使用局部变量方式使之延迟到调用时实例化。因为静态局部变量独立于对象存在，只有一个版本，因而不需要判断`NULL == instance`，提高了效率。它使用对象而不是指针分配内存，因此自动调用析构函数，不会造成内存泄漏。但是它也不是线程安全的。

要使以上变为线程安全，可以采取如上加锁的方式。Singleton2在C++11后不需要加锁了，因为标准要求编译器保证内部静态变量的线程安全性。


```
class SingletonStatic
{
private:
    static const SingletonStatic* m_instance;
    SingletonStatic(){}
public:
    static const SingletonStatic* getInstance()
    {
        return m_instance;
    }
};

//外部初始化before invoke main
const SingletonStatic* SingletonStatic::m_instance = new SingletonStatic;

```
相对应的，还有一种“恶汉”单例模式，即无论是否调用该类的实例，在程序开始时就会产生一个该类的实例，并在以后仅返回此实例。因为静态实例初始化在程序开始时进入主函数之前就由主线程以单线程方式完成了初始化，不必担心多线程问题。

---------------------------------------

##装饰器模式##
Python的特性中就有装饰器模式。现在定义一个函数，打印日期。

```
def PrintDate():
	print '2015-4-19'	
```
假设我们要增强PrintDate函数的功能，比如，在函数调用前后自动打印日志，但又不希望修改函数的定义，这种在代码运行期间动态增加功能的方式，称之为“装饰器”（Decorator）。

```
def log(func):
	def wrapper(*args, **kw):
		print 'call function %s()' % func.__name__
		return func(*args, **kw)
	return wrapper	
```

我们可以这样用：

```
@log
def PrintDate():
	print '2015-3-19'	
```

这样调用PrintDate函数的结果就是打印

call function PrintDate()
2015-3-19

Flask框架中返回所有用户的信息
@app.route('/user', methods=['GET'])
def web_user():
	db = LinkDB()
	users = db.get_all_user_info()
	return render_template('homepage.html', users=users)

再看看C++中代理模式实现

```
//公共抽象类
class Phone
{
public:
    Phone() {}
    virtual ~Phone() {}
    virtual void ShowDecorate() {} 
};

//具体手机类
class iPhone:public Phone
{
private:
    string m_name;
public:
    iPhone(string name):m_name(name){}
    ~iPhone() {}
    void ShowDecorate()
    {
        cout << m_name << "的装饰" <<endl;
    }
};

class AndroidPhone : public Phone
{
private:
    string m_name;
public:
    AndroidPhone(string name):m_name(name){}
    ~AndroidPhone() {}
    void ShowDecorate()
    {
        cout << m_name << "的装饰" <<endl;
    }
};

//装饰类
class DecoratorPhone : public Phone
{
private:
    Phone *m_phone;//要装饰的手机
public:
    DecoratorPhone(Phone *phone):m_phone(phone) {}
    virtual void ShowDecorate()
    {
        m_phone->ShowDecorate();
    }
};

//具体的装饰类
class DecoratorPhoneA:public DecoratorPhone
{
public:
    DecoratorPhoneA(Phone *phone) : DecoratorPhone(phone) {}
    void ShowDecorate() 
    {
        DecoratorPhone::ShowDecorate(); 
        AddDecorate();
    }
private:
    void AddDecorate()
    {
        cout << "增加挂件" << endl;
    }
};

int main()
{
	 Phone *iphone = new iPhone("5s");//基类指针指向派生类
     Phone *dpa = new DecoratorPhoneA(iphone);
     dpa->ShowDecorate();
     delete dpa;
    
     Phone *anphone = new AndroidPhone("Mi2");
     Phone *dpb = new DecoratorPhoneA(anphone);
     dpb->ShowDecorate();
     return 0;
}
```
打印结果为：

```
5s的装饰
增加挂件
Mi2s的装饰
增加挂件
```
UML图表示成如下
![图片](/assets/images/UML.png)

---------------------------------------

##代理模式##
_Ruminations On C++_第五章讲了代理类，下面看一下简单的代理模式。

```
class Image
{
public:
	Image(string name): m_imageName(name) {}
	virtual ~Image() {}
	virtual void Show() {}
protected:
	string m_imageName;
};
class BigImage: public Image
{
public:
	BigImage(string name):Image(name) {}
	~BigImage() {}
	void Show() { cout<<"Show big image : "<<m_imageName<<endl; }
};
class BigImageProxy: public Image
{
private:
	BigImage *m_bigImage;
public:
	BigImageProxy(string name):Image(name),m_bigImage(0) {}
	~BigImageProxy() { delete m_bigImage; }
	void Show() 
	{
		if(m_bigImage == NULL)
			m_bigImage = new BigImage(m_imageName);
		m_bigImage->Show();
	}
};

int main()
{
	Image *image = new BigImageProxy("proxy.jpg"); //代理
	image->Show(); //需要时由代理负责打开
	delete image;
	return 0;
}
```
这里的运用场景是，当打开一个含有图片的文档时，可以用代理类处理图片，在需要进行图片显示时才显示图片。这样可以提高打开文档的速度。

---------------------------------------


##Reference##
[1].http://blog.csdn.net/rabbit729/article/details/3419495

[2].http://www.51testing.com/html/14/n-847714.html

[3].http://www.cnblogs.com/ccdev/archive/2012/12/19/2825355.html

[4].http://blog.csdn.net/wuzhekai1985/article/details/6672614

[5].http://blog.csdn.net/wuzhekai1985/article/details/6669219

