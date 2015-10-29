---
layout: post
title: "ZooKeeper使用场景"
description: ""
category: 分布式
tags: []
---

这里使用开源软件 curator 的 API 来构造 Zookeeper 的客户端，先需要下载 curator 的依赖包

* [curator-framework](http://mvnrepository.com/artifact/org.apache.curator/curator-framework/2.3.0)

* [curator-recipes](http://maven.outofmemory.cn/org.apache.curator/curator-recipes/2.4.2/)

* [Guava-14.0.1](http://maven.outofmemory.cn/com.google.guava/guava/14.0.1/)


----------------------

## 分布式锁

在分布式环境中，为了保证数据的一致性，经常在程序的某个运行点需要进行同步控制。

```
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.CountDownLatch;
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.recipes.locks.InterProcessMutex;
import org.apache.curator.retry.ExponentialBackoffRetry;
import com.google.common.cache.CacheBuilder;


class DistributedLock {
    
    static String lock_path = "/curator_recipes_lock_path";
    static CuratorFramework client = CuratorFrameworkFactory.builder()
            .connectString("202.201.13.*:2100")
            .retryPolicy(new ExponentialBackoffRetry(1000, 3)).build();
    
    public static void main(String[] args) throws Exception {
        client.start();
        final InterProcessMutex lock = new 
        InterProcessMutex(client, lock_path);
        final CountDownLatch down = new CountDownLatch(1);
        
        for(int i = 0; i < 10; i++){
            new Thread(new Runnable() {
                public void run() {
                    try {
                        down.await();
                        lock.acquire();
                    } catch ( Exception e ) {}
                    
                    SimpleDateFormat sdf  = new SimpleDateFormat("HH:
                    mm:ss|SSS");
                    String orderNo = sdf.format(new Date());
                    
                    System.out.println("生成的订单号是： " + orderNo);
                    try {
                        lock.release();
                    } catch ( Exception e ) {}
                }
            }).start();
        }
        down.countDown();
    }
}
```

`CountDownLatch` 类是一个同步计数器，每调用一次countDown()方法，计数器减1，计数器大于0 时，await()方法会阻塞程序继续执行。它是一个倒计数的锁存器，当计数减至0时触发特定的事件。利用这种特性，可以让主线程等待子线程的结束。

在这里的作用是让 10 个子进程先阻塞在一个 `down.await()`，以便后面模拟高并发。父进程一旦执行 `down.countDown()`，10 个子进程开始抢锁。

而为了让 10 个子进程不造成资源竞争，需要使用 `InterProcessLock` 进行同步。

```
public interface InterProcessLock
  -public void acquire() throws Exception;
  -public void release() throws Exception;
```

打印结果

```
生成的订单号是： 21:06:29|951
生成的订单号是： 21:06:29|981
生成的订单号是： 21:06:30|007
生成的订单号是： 21:06:30|023
生成的订单号是： 21:06:30|039
生成的订单号是： 21:06:30|062
生成的订单号是： 21:06:30|076
生成的订单号是： 21:06:30|096
生成的订单号是： 21:06:30|107
生成的订单号是： 21:06:30|148
```

------------------------

## 分布式计数器

分布式计数器可以用来统计系统的在线人数。思路是指定一个 ZooKeeper 节点作为计数器，多个应用实例在分布式锁的控制下，递增数据节点的计数值。

```
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.recipes.atomic.AtomicValue;
import org.apache.curator.framework.recipes.atomic.DistributedAtomicInteger;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.apache.curator.retry.RetryNTimes;

class Recipes_DisAtomicInt {
    
    static String distatomicint_path="/curator_recipes_distatomicint_path";
    static CuratorFramework client = CuratorFrameworkFactory.builder()
            .connectString("202.201.13.*:2100")
            .retryPolicy(new ExponentialBackoffRetry(1000, 3)).build();
    
    public static void main(String[] args) throws Exception {
        client.start();
        DistributedAtomicInteger atomicInterger = 
        new DistributedAtomicInteger( client, distatomicint_path,
         new RetryNTimes(3, 1000));
        
        AtomicValue<Integer> rc = atomicInterger.add(1);
        System.out.println("Result: " + rc.succeeded());
    }
}
```

使用客户端脚本来连接服务器查看计数值

`bash zkCli.sh -server 127.0.0.1:2100`

![图片](/assets/images/zookeeper-scene.png)

可以看到节点的数据从 1A 增到 1B。
