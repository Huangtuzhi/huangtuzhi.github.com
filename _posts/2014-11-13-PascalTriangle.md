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

Given numRows, generate the first numRows of Pascal's triangle.

For example, given numRows = 5,

Return
 
1

1 1

1 2 1

1 3 3 1

1 4 6 4 1

思路：顺序加入每一个vector。显然每个vector的大小不一样。

-------------------------------------------------

##Solution##

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
    

--------------------------------------------------------------------

##Reference##

[1].https://oj.leetcode.com/

