---
layout: post
title: "SwordOffer有意思的算法题"
description: ""
category: algorithm
tags: []
---

假期看完了_剑指offer_，这本书对基本的数据结构和算法进行了很好的实践应用。印象里记得一些比较有意思的算法题，总结记录下来。

-------------------------------------------------------

##八皇后问题与全排列##

首先看一个字符串全排列的问题，题目：输入一个字符串，打印出字符串中字符的所有排列。例如输入字符串abc，则打印出由字符a、b、c所能排列出来的所有字符串abc、acb、bac、bca、cab和cba。

```
void swap(char* a, char* b)
{
   char tmp = *a;
   *a = *b;
   *b = tmp; 
}

void Permutation(char* pStr, char* pBegin)
{
    char* pCh;
    if(*pBegin == '\0')
    {
        printf("%s\n", pStr);
    }
    else
    {
        for(pCh = pBegin; *pCh != '\0'; pCh++)
        {
            swap(pCh, pBegin);
            Permutation(pStr, pBegin + 1);
            swap(pBegin, pCh);
        }
    }
}

void PermutationAll(char* pStr)
{
    if(pStr == NULL)
        return;
    Permutation(pStr, pStr);
}

int main(void)
{
    char str[] = "abcd"; //变量
    char* test = "ab";   //常量，存储在全局静态区。用这个会出现段错误。
    PermutationAll(str); //str正常，test异常
    return 0;
}
```
上面这段程序用Str测试正常，而用test异常。这是因为str是变量，可以进行swap运算，而test是存储在全局静态区的常量，无法进行swap。会出现段错误。段错误由以下几种情况引起：

1. 访问不存在的内存地址
2. 访问系统保护的内存地址
3. 访问只读的内存地址
4. 栈溢出

<br/>

全排列主要用了递归算法。下面展示算法步骤:

1.abcd进行全排列，pCh和pBegin都指向a，第1次相当于没交换。下一步是递归处理bcd，先不看。然后交换pCh和pBegin，相当于没交换。

2.第二次循环，pCh+1,交换得到bacd。然后递归处理acd，也先不看。然后交换ab还原为abcd，这样是为了让a和后面的每个数字交换。

3.第三次循环，得到cbad。第四次得到dbca。

4.四次循环之后a就和所有的四个数字（包括自己）交换完了，然后是递归处理第一个字符后面的剩余字符。处理方法同上。

再看看八皇后问题：在8*8国际象棋棋盘上，要求在每一行放置一个皇后，且能做到在竖方向，斜方向都没有冲突。

![图片](/assets/images/EightQueen-2.png)

我们将八皇后表示为Queen[8] = {0,1,2,3,4,5,6,7}。每个皇后的坐标可以表示为：(idx, Queen[idx])。

这样完全可以保证它们在不同行和列，下面只需要保证斜方向不冲突。即满足关系：

    abs(i-j) != abs(Queen[i]-Queen[j])。

我们只需要将Queen[8]数字全排列之后剔除不满足关系的组合即可。

先写一个判断摆法是否正确的判断函数。

```
int isSafe(char *str)
{
    int i, j;
    for(i=0;i<8;i++)
    {
        for(j=i+1;j<8;j++)
        {
            if abs(i-j) == abs(str[i]-str[j]) 
                return 0;      
        }
    }
    return 1;
}

```
将上面的排列函数改为：

```
void Permutation(char* pStr, char* pBegin)
{
    int static method = 1;
    char* pCh;
    if(*pBegin == '\0')
    {
       if(isSafe(pStr))
            printf("method %d : %s\n", method++, pStr);
    }
    else
    {
        for(pCh = pBegin; *pCh != '\0'; pCh++)
        {
            swap(pCh, pBegin);
            Permutation(pStr, pBegin + 1);
            swap(pBegin, pCh);
        }
    }
}
```

测试程序为：

```
int main(void)
{
    char str[] = "01234567"; 
    PermutationAll(str);
    return 0;
}
```

可以得到八皇后的解为92种。四皇后的解为2种。

![图片](/assets/images/EightQueen.png)

八皇后还有其他的优化算法，如回溯法，还有这个 [如何用C++在10行内写出八皇后？](http://www.zhihu.com/question/28543312)。

优化算法如下：

```
//函数功能 ： 检查皇后cur的摆法
//函数参数 ： n为皇后数，cur为当前检查的皇后，col为皇后的列位置
void Queen(int n, int cur, int *col, int *sum)
{
    if(cur == n)  //找到一种摆法
    {
        for(int i = 0; i < n; i++)
            cout<<col[i]<<' ';
        cout<<endl;
        (*sum)++; //摆法加1
        return;
    }
    int i, j;
    for(i = 0; i < n; i++) //考虑每一个可能的列号
    {
        //检查当前考虑的皇后是不是可以放在位置i
        for(j = 0; j < cur; j++)
        {
            if(abs(j-cur) == abs(col[j]-i) || col[j] == i)
            //与之前的皇后有冲突，不用考虑下一个皇后了
                break;
        }   
        if(j == cur) 
        {
            col[cur] = i;  //可以放在这个位置
            Queen(n, cur+1, col, sum); //考虑下一个皇后
        }
    }
}

int NQueenProblem(int n)
{
    int *col = new int[n];
    int sum = 0;
    Queen(n, 0, col, &sum); //调用核心函数
    delete [] col;
    col = NULL;
    return sum;
}

int main(void)
{
    NQueenProblem(8);
    return 0;
}
```

陈硕在知乎上针对服务器C++并行编程提出了一个练习题，[N-皇后问题的多机并行求解](http://www.zhihu.com/question/22608820/answer/21968467?utm_source=weibo&utm_medium=weibo_share&utm_content=share_answer&utm_campaign=share_button)。可以思考一下八皇后问题的多机实现。

<br/>

--------------------------------------------

##并行排序##
上面提到了并行编程，APUE中有一个并行排序的例子，对800万个随机数字进行多线程并行排序。

```
#define NTHR   8                /* number of threads */
#define NUMNUM 8000000L         /* number of numbers to sort */
#define TNUM   (NUMNUM/NTHR)    /* number to sort per thread */
long nums[NUMNUM];
long snums[NUMNUM];

pthread_barrier_t b;
extern int heapsort(void *, size_t, size_t,int (*)(const void *, const void *));

//传入heapsort函数的比较long型大小的辅助函数
int complong(const void *arg1, const void *arg2)
{
    long l1 = *(long *)arg1;
    long l2 = *(long *)arg2;

    if (l1 == l2)
        return 0;
    else if (l1 < l2)
        return -1;
    else
        return 1;
}

void *thr_fn(void *arg)//分组排序的工作线程
{
    long idx = (long)arg;
    heapsort(&nums[idx], TNUM, sizeof(long), complong);
    pthread_barrier_wait(&b);
    return((void *)0);
}

void merge()//合并排序结果
{
    long    idx[NTHR];
    long    i, minidx, sidx, num;

    for (i = 0; i < NTHR; i++)
        idx[i] = i * TNUM;
    for (sidx = 0; sidx < NUMNUM; sidx++) {
        num = LONG_MAX;
        for (i = 0; i < NTHR; i++) {
            if ((idx[i] < (i+1)*TNUM) && (nums[idx[i]] < num)) {
                num = nums[idx[i]];
                minidx = i;
            }
        }
        snums[sidx] = nums[idx[minidx]];
        idx[minidx]++;
    }
}

int main()
{
    unsigned long   i;
    struct timeval  start, end;
    long long       startusec, endusec;
    double          elapsed;
    int             err;
    pthread_t       tid;    
    srandom(1);
    for (i = 0; i < NUMNUM; i++)
        nums[i] = random();
    gettimeofday(&start, NULL);//Create 8 threads to sort the numbers.
    pthread_barrier_init(&b, NULL, NTHR+1);
    for (i = 0; i < NTHR; i++) {
        err = pthread_create(&tid, NULL, thr_fn, (void *)(i * TNUM));
        if (err != 0)
            err_exit(err, "can't create thread");
    }
    pthread_barrier_wait(&b);
    merge();
    gettimeofday(&end, NULL);

    //打印排序结果
    startusec = start.tv_sec * 1000000 + start.tv_usec;
    endusec = end.tv_sec * 1000000 + end.tv_usec;
    elapsed = (double)(endusec - startusec) / 1000000.0;
    printf("sort took %.4f seconds\n", elapsed);
    for (i = 0; i < NUMNUM; i++)
        printf("%ld\n", snums[i]);
    exit(0);
}
```
<br/>

-----------------------------------
##函数指针##

题目：求1+2+...+n，要求不能用乘除法，for,while,if,else,switch,case等关键字及条件判断语句(A?B:C)。

```
typedef unsigned int (*fun)(unsigned int);
unsigned int Solution(unsigned int n)
{
    return 0;
}

unsigned int Sum(unsigned int n)
{
    static fun f[2] = {Solution, Sum};
    return n + f[!!n](n-1);
}
```

首先定义了新的函数指针类型fun，它接受参数unsigned int，返回unsigned int。
在Sum中定义函数指针数组f[0],f[1]。

Sum(50)的调用过程为：

    Sum(50) = 50 + f[!!50](即Sum函数)(49)

这里是一个递归。巧妙之处是用！！解决了递归结束的条件。当n = 0,f[!!n]变为Solution函数，因此返回0。

<br/>

----------------------------------

##不能被继承的类与堆/栈上实例化##

要想类不能被继承，最简单的方法就是把构造函数和析构函数设为private。

```
class SealedClass1
{
public:
    static SealedClass1* GetInstance()
    {
        return new SealedClass1();
    }

    static void DeleteInstance(SealedClass1* pInstance)
    {
        delete pInstance;
    }

private:
    SealedClass1(){}
    ~SealedClass1(){}
};
```
这里不能采用SealedClass1 instance的方法实例化(得到栈上的实例)，只能得到位于堆上的实例。这个类不能被继承是因为当继承类实例化时无法调用基类的构造函数。

因为GetInstance()被定义为静态函数，可以在类外独立于对象而调用。

另外一个方法是采用友元类和虚继承。

```
template <typename T>
class MakeSealed
{
    friend T;
private:
    MakeSealed(){}
    ~MakeSealed(){}
};

class SealedClass2: virtual public MakeSealed<SealedClass2>
{
public:
    SealedClass2(){}
    ~SealedClass2(){}
};

class Try: SealedClass2
{
public:
    Try(){}
    ~Try(){}
}
```
SealedClass2被申明为MakeSealed类的友元类，可以调用它的私有构造函数，因此可以和一般类一样在堆/栈上建立实例。

而当Try试图继承SealedClass2时，会跳过SealedClass2的构造函数而直接调用MakeSealed的构造函数(因为SealedClass2是虚继承而来的)。这样就满足了题目的要求。

----------------------------------

##Reference##
[1].http://www.cnblogs.com/panfeng412/archive/2011/11/06/2237857.html

[2].http://blog.csdn.net/wuzhekai1985/article/details/6644318

[3].http://my.oschina.net/lvyi/blog/346050

[4].http://blog.csdn.net/dqjyong/article/details/8029527