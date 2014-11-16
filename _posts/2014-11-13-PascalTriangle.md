---
layout: post
title: "Pascal's Triangle"
description: ""
category: c&&C++
tags: [LeetCode]
---
 
开始练习LeetCode上的基础算法题。LeeCode支持3种语言：python，C++，Java，C++建议使用STL。

-----------------------------------------------------------

##Pascal's Triangle##

Given numRows, generate the first numRows of Pascal's triangle.For example, given numRows = 5,Return
 
1

1 1

1 2 1

1 3 3 1

1 4 6 4 1

思路：顺序加入每一个vector。显然每个vector的大小不一样。



    class Solution {
    public:
    vector<vector<int> > generate(int numRows)
    {
        vector<vector<int> > answer;
        for(int i=0;i< numRows;i++)
        {
            vector<int> col;
            if(i==0)
            col.push_back(1);
            else
            {
                for(int j=0;j<=i;j++)
                {
                    if(j==0 || j==i)
                    col.push_back(1);
                    else
                    col.push_back(answer[i-1][j]+answer[i-1][j-1]);
                 }
                }
            answer.push_back(col);
            }
        return answer;
        }
    };
    

----------------------------------------

##Same Tree##

Given two binary trees, write a function to check if they are equal or not.
Two binary trees are considered equal if they are structurally identical and the nodes have the same value. 

思路：采用递归，分别判别左节点和右节点，两边节点都满足时才返回true。

    /**
    * Definition for binary tree
    * struct TreeNode {
    *     int val;
    *     TreeNode *left;
    *     TreeNode *right;
    *     TreeNode(int x) : val(x), left(NULL), right(NULL) {}
    * };
    */
    class Solution {
    public:
        bool isSameTree(TreeNode *p, TreeNode *q) {
        if( (!p)&&(!q) )
        return true;
        if( (!p&&q) || (p&&!q) || (p->val != q->val) )
        return false;
        return( isSameTree(p->left, q->left) && isSameTree(p->right, q->right) );
        }
    };

----------------------------------------

## Min Stack##

Design a stack that supports push, pop, top, and retrieving the minimum element in constant time.

push(x) -- Push element x onto stack.

pop() -- Removes the element on top of the stack.

top() -- Get the top element.

getMin() -- Retrieve the minimum element in the stack.

思路：因为题目要求retrieving the minimum element in constant time，所以不能对堆栈整个进行搜索。必须另用一个堆栈来记录最小的元素。

    class MinStack {
    public:
    void push(int x) {
        elements.push(x);
        if ( mins.empty() || x<=mins.top() )
        mins.push(x);
    }

    void pop() {
        if ( elements.empty() )
        return;
        if(elements.top()==mins.top())
        mins.pop();
        elements.pop();
        
    }

    int top() {
        return elements.top();
    }

    int getMin() {
        return mins.top();
    }
    
    
    private:
    stack <int> elements;
    stack <int> mins;
    };

##Sqrt(x)##

Implement int sqrt(int x).Compute and return the square root of x.

思路：二分法

    class Solution {
    public:
        int sqrt(int x) {
        int low=1,high=x,mid;
        if(x<=1) return x;
        while(low<=high)
            {
            mid=low+((high-low)>>1);
            if(mid==x/mid) return mid;
            if(mid>x/mid)
            {
                high=mid-1;
            }
            else low=mid+1;
            }
         return high;
        }
    };

 
--------------------------------------------------------------------

##Reference##

[1].https://oj.leetcode.com/

