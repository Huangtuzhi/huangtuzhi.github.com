---
layout: post
title: "RAII实现的mutex资源类"
description: ""
category: C&&C++
tags: []
---



**RAII**，指的是Resource Acquisition is Initialization。即使用资源时对资源初始化，使用完毕进行自动释放。它利用stack上的临时对象生命期是程序自动管理的这一特点，将我们的资源释放操作封装在一个临时对象中。

当我们使用多线程时，需要保证线程安全，这就需要对资源进行加锁。Linux下使用`pthread_mutex_t`实现不可重入。我们可以用RAII的手法对mutex进行封装。

------------------------------------------------------

## 封装

```
class MutexLock
{
public:
	MutexLock() {
		pthread_mutex_init(&mutex_, NULL);
        cout << "construct of MutexLock" << endl;
	}
	~MutexLock() {
		cout << "deconstruct of MutexLock" << endl;
		pthread_mutex_destroy(&mutex_);
	}

	void lock() {
		pthread_mutex_lock(&mutex_);//lock不上的线程会被阻塞
	}

	void unlock() {
		pthread_mutex_unlock(&mutex_);
	}

private:
	MutexLock(const MutexLock &);
	MutexLock& operator=(const MutexLock &); 

	pthread_mutex_t mutex_;
};

class MutexLockGuard
{
public:
	explicit MutexLockGuard(MutexLock &mutex): mutex_(mutex) {
        cout << "construct of MutexLockGuard" << endl;
		mutex_.lock();
	}
	~MutexLockGuard() {
		cout << "deconstruct of MutexLockGuard" << endl;
		mutex_.unlock();
	}

private:
	MutexLockGuard(const MutexLock &);
	MutexLockGuard& operator=(const MutexLock &);
	MutexLock &mutex_;
};
```

`MutexLock`类的构造函数初始化互斥锁，析构函数销毁互斥锁。它封装了临界区，位于`lock()`和`unlock()`调用之间。

`MutexLockGuard`类的构造函数对临界区进行加锁操作，进入临界区，保证了不可重入。析构函数解锁，退出临界区。

`MutexLockGuard`类一般是一个栈对象，它的作用域刚好等于临界区域。

-------------------------------------------------

## 应用

```

MutexLock mutex;
int cnt = 5;

void *f(void *arg){
    long t_num = (long) arg;
    while(true){
        MutexLockGuard lock(mutex);
        if(cnt>0){
            usleep(1);
            cout << "args: " << t_num << " "<< "cnt: "<< cnt--<< endl; 
        } 
        else{break;}       
    }
    return NULL;
}

int main()
{
    pthread_t tid, tid1, tid2, tid3;
    int ret = pthread_create(&tid, NULL, f,(void*)11);
    if(ret == -1){
        perror("create error\n");
    }
     
    ret = pthread_create(&tid1, NULL, f, (void*)22);
    if(ret == -1){
        perror("create error\n");
    }
     
    ret = pthread_create(&tid2, NULL, f, (void*)33);
    if(ret == -1){
        perror("create error\n");
    }
     
    ret = pthread_create(&tid3, NULL, f, (void*)44);
    if(ret == -1){
        perror("create error\n");
    }
     
    pthread_join(tid, NULL);
    pthread_join(tid1, NULL);
    pthread_join(tid2, NULL);
    pthread_join(tid3, NULL);
    return 0;
}
```

程序打开四个线程进行测试，打印结果如下：

```
construct of MutexLock
construct of MutexLockGuard

construct of MutexLockGuard
args: 11 cnt: 5
deconstruct of MutexLockGuard

construct of MutexLockGuard
construct of MutexLockGuard

construct of MutexLockGuard
args: 11 cnt: 4
deconstruct of MutexLockGuard

construct of MutexLockGuard
args: 11 cnt: 3
deconstruct of MutexLockGuard

construct of MutexLockGuard
args: 33 cnt: 2
deconstruct of MutexLockGuard

construct of MutexLockGuard
args: 33 cnt: 1
deconstruct of MutexLockGuard

construct of MutexLockGuard
deconstruct of MutexLockGuard

deconstruct of MutexLockGuard
deconstruct of MutexLockGuard
deconstruct of MutexLockGuard
deconstruct of MutexLock
```

这个结果有点诡异。当四个线程初始化时，生成了两个`MutexLockGuard`实例。其中一个获取到了mutex锁，另一个进程阻塞。对`cnt`进行操作后，释放了mutex锁。

然后主线程继续生成另外两个`MutexLockGuard`实例。主线程未直接生成四个实例是因为

> The main() thread is possibly not creating all threads before it gets preempted by one of its child threads.

接下来发生的事是:

`args: 11`获取锁，释放锁，`cnt--`

`args: 11`获取锁，释放锁，`cnt--`

`args: 33`获取锁，释放锁，`cnt--`

`args: 33`获取锁，释放锁，`cnt--`

某个进程执行break结束循环。

具体可以参见[OS](http://stackoverflow.com/questions/30678529/constructor-and-destructor-in-multi-threading)讨论。

> All the threads construct a MutexLockGuard but only one is permitted to acquire the mutex and proceed (as intended).

> However, when that one destroys its MutexLockGuard and releases the mutex, it turns out that it loops around and creates a new MutexLockGuard and acquires the mutex before the system unblocks another thread and allows them to acquire the mutex.

> Mutex acquisition is not guaranteed to be fair. The system may act like this in an attempt to prevent spending work switching threads.

其实争抢到mutex的线程中局部变量`MutexLockGuard`实例的生存期位于`while`中，其它未争抢到mutex的线程阻塞没有执行到下一个`while`，所以不调用析构函数。

当所有局部的`MutexLockGuard`析构后，全局的`MutexLock`在最后自动析构。

-------------------------------------------------

## 参考

Linux多线程服务端编程