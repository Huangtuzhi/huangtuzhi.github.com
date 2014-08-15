---
layout: post
title: "Huffman树的C实现"
description: "huffman"
category: algorithm
tags: [C]
---


Huffman编码是一种无损的数据压缩熵编码。编码过程可以通过构造Huffman二叉树来进行。

-----------------------------------
##举个栗子
假设书 《Steven Jobs》 中所有的人名都用一个char型来存储，比如Jobs编码为1111 1111，Jonathan  Ive（曾设计锤子手机外观）编码为0000 0000。Jobs在书中出现概率为20%，而Ive只有5%。那么某一段话可以表示为11111111xxxxxxxx00000000(X为其他字，比如love，employ的编码）。实际上我们没有必要把名字都编码为定长。在一章文字中出现概率越多的名字，我们将它编码为较小的长度，这样可以节省空间。至于能小到多少，这就和概率有关，必须做到不能损失信息量。这就可以用Huffman树来实现。

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

PreOrder() 函数用来遍历输出Huffman编码，用了一个递归调用


{% highlight objc %}

#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include <malloc.h>
typedef struct node
{
	float weight;
    struct node *Lnode;
	struct node *Rnode;
	struct node *Parent;
	struct node *next;
}HuffmanNode;

int NodeNum=0;      //节点个数
HuffmanNode * InputNodes(void)
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
	Leaves[NodeNum-1].next=NULL;
	return Leaves;
}

HuffmanNode* MakeQueue(HuffmanNode *innode)//形成队列 排序算法有问题,不应该是简单换weight，而是链表的插入操作
{
	HuffmanNode *p, *p_follow, *q_follow, *q, *temp;
	p_follow=p;//p跟随指针初始化
	for(p=innode;p->next!=NULL;p=p->next)
	{
		if(p==innode && p->next->next!=NULL)//当p是头节点,且有>=3个节点。
		{
			q_follow=p;
			for(q=p->next;q!=NULL;)//小心q溢出
			{
				if(q_follow==p)
				{
					if(p->weight > q->weight)
					{
						p->next=q->next;
						q->next=p;
						temp=q;
						q=p;
						p=temp;
					//	printf("case:p是头节点，p和q相邻\n");
				   	}
					innode=p;
					q_follow=q;
					q=q->next;
				}
				else
				{
					if(p->weight > q->weight)
				   	{
						temp=p->next;//防止p的指针发生改变
						p->next=q->next;
						q_follow->next=p;
						q->next=temp;

						temp=q;
						q=p;
						p=temp;
						innode=p;
					//	printf("case:p是头节点，p和q至少相邻1个,交换完毕\n");
					}
				
					if(q->next==NULL)
					{
					//	printf("q的下一个为空，程序中止\n");
						break;
					}
					else
					{
						q_follow=q;
						q=q->next;
					//	printf("case:p是头节点，p和q至少相邻一个，q移向下一个\n");
					}
				}
			 }
			 innode=p;
		}
		
		else if((p==innode) && (p->next!=NULL) && (p->next->next==NULL))//当p是头节点，且有2个节点。
		{
			//printf("case:Sorting 2 points\n");
			q=p->next;
			if(p->weight > q->weight)
			{
				q->next=p;
				p->next=NULL;
			
				innode=q; 
			//	printf("Num=2，2个节点交换成功\n");
				return innode;
			}
			else
			{
			//	printf("Num=2，2个节点排序正确，不用交换\n");
			}

		}

		else if((p!=innode) && (p->next->next==NULL))//当p是尾节点的前一个节点
		{
	  	   // printf("p不是头节点，且p是倒数第二个节点\n");
			q=p->next;
			if(p->weight > q->weight)
				{
					p->next=NULL;
					q->next=p;
					p_follow->next=q;
		
		     		temp=q;
		    		q=p;
					p=temp;
				}
		}

		else //当p是其它节点
		{
		//	printf("This situation is popular points\n");
			q_follow=p;
			for(q=p->next;q!=NULL;q=q->next)
			{
				if(q_follow==p)
				{
					if(p->weight > q->weight)
				   {
					p->next=q->next;
					q->next=p;
					p_follow->next=q;
					
					temp=q;
					q=p;
					p=temp;
				   }
				}
				else
				{
					if(p->weight > q->weight)
				   {
					temp=p->next;//在链路改版前保存下来
					p->next=q->next;
					q_follow->next=p;
					q->next=temp;
					p_follow->next=q;
					
					temp=q;
					q=p;
					p=temp;
				   }
				} 
		   q_follow=q;
		   }
		}
		p_follow=p;
		}
	return innode;
}

HuffmanNode* HuffmanForest(HuffmanNode *forest)
{
	int i;
	HuffmanNode *current=NULL;
	HuffmanNode *NewNode=NULL;
	HuffmanNode *Head=NULL;
	for(i=0;i<NodeNum-1;i++)
	{
		printf("-----------------------------------------------\n");
		printf("第%d次调用MakeQueue函数对输入的树进行排序\n",i+1);
		Head=MakeQueue(forest);//节点组成链表，看成一个队列 进行排序。这里必须用Head去接受返回值，不然出错。
		for(current=Head;current!=NULL;current=current->next)
		{
			printf("%f  ",current->weight);
		}
		printf("\n");
		
	
		NewNode=(HuffmanNode*)malloc(sizeof(HuffmanNode));
		NewNode->weight=(Head->weight)+((Head->next)->weight);//这里的节点不能写作forest，必须写作Head。
		NewNode->Lnode =Head;
		NewNode->Rnode =Head->next;
		Head->Parent=Head->next->Parent=NewNode;
		
	    
		for(current=Head;current->next != NULL;current=current->next){}
		current->next=NewNode;   //加入新节点
		NewNode->next=NULL;
		Head=(Head->next)->next;//删除前两个节点
		forest=Head;
	}
	return forest;
}

void PreOrder(HuffmanNode *root)
{
	HuffmanNode *Increase=NULL;
	if(root!=NULL)
	{
		if(root->Lnode==NULL && root->Rnode==NULL)
		{
			printf("Node weight:%f\n",root->weight);
			for(Increase=root;Increase->Parent!=NULL;Increase=Increase->Parent)
			{
				if(Increase->Parent->Lnode==root)
				{
					printf("code 1\n");
				}
				else
				{
					printf("code 0\n");
				}

			}

		}
		PreOrder(root->Lnode);
		PreOrder(root->Rnode);
	}
}

int main()
{
	int i;
    HuffmanNode *p=NULL;
	HuffmanNode *current=NULL;
    HuffmanNode *Head=NULL;
    p=InputNodes();

	// Test the function of MakeQueue
	/*	Head=MakeQueue(p);
	printf("Data after sorting:\n");
	for(current=Head;current!=NULL;current=current->next)
	{
		printf("%f  ",current->weight);
	}
	*/

	Head=HuffmanForest(p);
	PreOrder(Head);
	
}

{% endhighlight %}

----------------------------------------------------------

##References##
[1].http://coolshell.cn/articles/7459.html

[2].http://blog.csdn.net/abcjennifer/article/details/8020695

[3].http://www.nowamagic.net/librarys/veda/detail/1852

[4].http://zh.wikipedia.org/wiki/%E9%9C%8D%E5%A4%AB%E6%9B%BC%E7%BC%96%E7%A0%81
