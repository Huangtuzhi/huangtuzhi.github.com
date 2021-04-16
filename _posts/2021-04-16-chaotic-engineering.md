---
layout: post
title: "演习与混沌工程"
description: ""
category: 
tags:
comments: yes
---

> [Chaos Is A Ladder](https://www.youtube.com/watch?v=XSWMepI7yDg)

现代战争中为了评估战力、保证军备强度会进行实战的军事演习，日常生活中也常常有消防演习、地震演习。消防演习真正发射了防空导弹，消防演习也真的点了一把火，另外我也真的[有一头牛](https://www.zhihu.com/question/370764915)。这些是真实的行动，不是推演、假设，要的效果就是和现实世界一样。也只有这样当灾难发生，我们的应对措施才有效。


---

## 名词解释

- BCP：Business Continuity Planning，业务持续计划。BCP 是为了防止正常业务行为被中断而建立的计划。
当面对自然或人为造成的故障引起正常业务不能使用时，BCP 可以用来保护关键业务步骤，类似于应急预案。比如消防演习时制定的撤离计划，再比如 MySQL 故障时的备机切换方案。下图是购买车险业务中，当专线出现故障时的 BCP。

![](/assets/images/20210416-3.jpg)

- 演习：在真实的环境中进行演练，为了保证有效性，严格来说演习必须在生产环境。演习建立在系统完成 BCP 的条件下进行。
- 反脆弱：Antifragile，塔勒布写的一本书，讲述如何在不确定性中获益。“对随机性、不确定性和混沌也是一样：你要利用它们，而不是躲避它们。你要成为火，渴望得到风的吹拂。这总结了我对随机性和不确定性的明确态度”。我们需要让系统从每一次故障、失败中受益，不断进化。
- 混沌工程：大学时的电路学过非线性电路混沌电路，实现了最简单的[混沌系统](https://www.bilibili.com/video/av56735270/)。混沌系统的特点就是随机、不确定性。而混沌工程理论是建构于塔勒布的反脆弱思想之上。混沌工程提倡用一系列实验来真实地验证系统在各类故障场景下的表现，通过频繁地主动引发故障进行大量实验，使得系统本身的反脆弱性持续增强，也让开发者对系统越来越有信心。

---

## 混沌系统

业界对混沌系统的研究已经很多年了，一些大厂在业务中已经大量实践。混沌系统是混沌工程的系统集成，用于快速进行实验，主要包括故障注入、稳态监控等，适配的平台有物理机和 Kubernetes。

- Netfix：[Chaos Monkey](https://github.com/Netflix/chaosmonkey)
- AWS：[AWSSSMChaosRunner](https://github.com/amzn/awsssmchaosrunner)
- 阿里：[Chaosblade](https://github.com/chaosblade-io/chaosblade)
- PingCAP：[Chaos Mesh](https://github.com/chaos-mesh/chaos-mesh)
- Tencent：Chaos Excutor

---

## 原子故障

很多业务系统故障和最基本的系统资源异常有关，比如 OOM、CPU 满载、进程退出，把这种系统资源异常叫做原子故障。主要分为下面几类

![](/assets/images/20210416-2.jpg)

看几个原子故障的实现原理

---

### 网络延时

网络延时可以通过混沌系统 agent 下发执行 iptables DROP 命令来实现

封禁指定 IP 访问本机

```iptables -I INPUT -s 192.30.252.154 -j DROP```

封禁本机访问指定 IP

```iptables -I OUTPUT -d 192.30.252.154 -j DROP```

封禁后的 iptables 规则

```
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
DROP       tcp  --  anywhere             lb-192-30-252-154-iad.github.com
``` 

---

### CPU 负载

CPU 负载是通过混沌系统 agent 新开一个进程去空跑 for 循环来消耗 CPU 时间片。

```
for i in `seq 1 $(cat /proc/cpuinfo |grep 'physical id' |wc -l)`; 
do dd if=/dev/zero of=/dev/null & done && sleep MINUTEm
```

---

## 异常事件库

在实际应用中，我们在应用层遇到的故障可能是 RPC 接口失败、kafka 队列满等。这些原子故障不能满足需求，需要在 Iaas 层、Paas 层、Saas 层基于原子故障去建立不同层次的异常事件库。

![](/assets/images/20210416-4.jpg)

---

## 实战演习

业务中使用一个唯一 ID 生成器 IDGen，它是一个独立的进程。IDGen 的 BCP 方案是在共享内存中缓存了 2 个小时的 ID，这次演习 IDGen 故障，看业务是否受到影响。思路是使用混沌工程平台将进程异常事件注入到机器上。

![](/assets/images/20210416-5.jpg)

进程退出后，业务正常，说明 BCP 方案生效，演习成功。


> [如果你渴望和平，就必须做好战争的准备](https://www.bilibili.com/video/av22192156/)