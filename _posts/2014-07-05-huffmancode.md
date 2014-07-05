---
layout: post
title: "Huffman树的C实现"
description: "huffman"
category: algorithm
tags: [C]
---

Huffman编码是一种无损的数据压缩熵编码。编码过程可以通过构造Huffman二叉树来进行。
--------------------------------
##举个栗子##
假设书 Steven Jobs 中所有的人名都用一个char型来存储，比如Jobs编码为1111 1111，Jonathan  Ive（曾设计锤子手机外观）编码为0000 0000。Jobs在书中出现概率为20%，而Ive只有5%。那么某一段话可以表示为11111111xxxxxxxx00000000(X为其他字，比如love，employ的编码）。实际上我们没有必要把名字都编码为定长。在一章文字中出现概率越多的名字，我们将它编码为较小的长度，这样可以节省空间。至于能小到多少，这就和概率有关，必须做到不能损失信息量。这就可以用Huffman树来实现。

实现过程中遇到有这些问题：
+ 如何建立链表和二叉树
+ 单链表选择排序
+ 如何遍历输出叶子节点及路径（因为路径代表的就是编码）

-----------------------------------------
##程序结构##
采用模块化编程的思路
InputNodes() 函数用来输入节点权重和建立链表
MakeQueue() 函数用来对链表进行选择排序
HuffmanForest()函数用来构建哈弗曼二叉树
PreOrder() 函数用来输出叶子节点
MakeCode() 函数用来输出编码，具体程序还没写出

{% highlight objc %}
#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include <malloc.h>

typedef struct node{	
     float weight;
     struct node *Lnode;
     struct node *Rnode; 
     struct node *next;
}HuffmanNode;
typedef HuffmanNode Node;
int NodeNum=0; //节点个数
HuffmanNode * InputNodes()
{
float w;
int i=0;
printf("Input the size of nodes\n");
scanf("%d",&NodeNum);
    HuffmanNode *Leaves;//定义指向结构体缓存区的指针,被返回了。所以是局部变量也没关系。
Leaves=(HuffmanNode*)malloc(sizeof(HuffmanNode)*NodeNum);//申请存放节点的全局空间，什么时候被释放？
printf("Please input the weight of nodes to perform Lossless Compression \n");
for(i=0;i<NodeNum;i++)
{
        scanf("%f",&w);
Leaves[i].weight=w;
Leaves[i].Lnode=NULL;
Leaves[i].Rnode=NULL;
}
for(i=0;i<NodeNum-1;i++)
{
Leaves[i].next=&Leaves[i+1];//这里的表达真奇葩
}
return Leaves;
}
HuffmanNode* MakeQueue(HuffmanNode *l)
{
Node *p,*q,*m,*n;
Node *temp1,*temp2;
if(l->next==NULL)
printf("NO LINKLIST!!!");
else
{
p=l;q=l->next;
while(q->next!=NULL)
{
m=p->next;
n=q->next;
temp1=m;
while(temp1->next!=NULL)
{
if(temp1->next->weight<q->weight && temp1->next->weight < n->weight)
{
m=temp1;n=temp1->next;
}
temp1=temp1->next;
}/*_*====此循环用于找到基准(q)以后的序列的最小的节点=====*_*/
if(m!=p->next || (m==p->next && m->weight>n->weight))
{
p->next=n;
p=n;
m->next=q;
m=q;
q=q->next;
n=n->next;
p->next=q;
m->next=n;
}/*_*======此条件用于交换两个节点*_*/
else
{
p=p->next;
q=q->next;
}/*_*======此条件用于没有找到最小值时的p，q后移操作*_*/
}/*_*=====外循环用于从前往后扫描，通过移动p,q指针实现=======*_*/
temp2=l->next;
// printf("List after sorting is:\n");
while(temp2!=NULL)
{
printf("%f",temp2->weight);
temp2=temp2->next;
}
}
printf("\n");
}
HuffmanNode* HuffmanForest(HuffmanNode *forest)
{
int i;
HuffmanNode *current=NULL;
HuffmanNode *NewNode=NULL;
for(i=0;i<NodeNum-1;i++)
{
MakeQueue(forest);// 节点组成链表，看成一个队列 进行排序
printf("every loop : sort output\n");
for(current=forest;current->next!=NULL;current=current->next)
{
printf("data %f\n",current->weight);
}
printf("data %f\n",current->weight);
NewNode=(HuffmanNode*)malloc(sizeof(HuffmanNode));
NewNode->weight=(forest->weight)+((forest->next)->weight);
NewNode->Lnode =forest;
NewNode->Rnode =forest->next;
for(current=forest;current->next!=NULL;current=current->next){}
current->next=NewNode; //加入新节点
NewNode->next=NULL;
forest=(forest->next)->next;//删除前两个节点
}
return forest;
}
void PreOrder(HuffmanNode *root)
{
if(root!=NULL)
{
if(root->Lnode==NULL && root->Rnode==NULL)
{
printf("Node weight:%f\n",root->weight);
}
PreOrder(root->Lnode);
PreOrder(root->Rnode);
}
}
void MakeCode(HuffmanNode *root)
{
//构建好了排序二叉树，还需要完善打印code的程序
}
int main()
{
int i;
    HuffmanNode *p=NULL;
    HuffmanNode *Head=NULL;
    p=InputNodes();
for(i=0;i<NodeNum;i++)
{
printf("Sorted Nodes %f\n",p[i].weight);
}
Head=HuffmanForest(p);
PreOrder(Head);
MakeCode(Head);
}
{% endhighlight %}

----------------------------------------------------------

##References##
[1].http://coolshell.cn/articles/7459.html

[2].http://blog.csdn.net/abcjennifer/article/details/8020695

[3].http://www.nowamagic.net/librarys/veda/detail/1852

[4].http://zh.wikipedia.org/wiki/%E9%9C%8D%E5%A4%AB%E6%9B%BC%E7%BC%96%E7%A0%81
