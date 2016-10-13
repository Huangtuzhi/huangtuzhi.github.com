---
layout: post
title: "写一个 Chrome 插件解决生活问题"
description: ""
category: 
tags:
---

鹅厂开发网和办公网是分离的，办公网可以上外网，开发网需要在一个 OA 管理网站上请求授权后有 2 小时连接外网的时间。所以需要每隔 2 小时去这个 OA 网站上点击一下按钮，真不知道这样开发网限制连外网有个毛用。幸好这个 OA 网站不能抢月饼，于是想写一个 JS 脚本来有事没事续一秒。

刚好在知乎看到一个妹子分享了自己如何用代码解决生活问题的，[should-i-reply](Github  https://github.com/hanax/should-i-reply)。前段时间也曾预研过 Chrome 插件写法。于是学着写一个简单的插件。功能不复杂，也遇到了一些问题，主要是找找自己做项目的感觉。

-----

## Chrome 插件结构

```
|-- Out
|   |-- content.js    //插件后台执行代码
|   |-- icon.png      //插件图标
|   |-- main.css
|   |-- manifest.json //插件配置
|   |-- Out.crx       //可以直接安装的插件
|   |-- popup.html    //点击插件的弹窗页面
|   |-- popup.js
|   `-- README.md
```

`mainfest.json` 定义了插件的配置

```
{
    "manifest_version": 2,
    "name":    "Out Devnet",
    "version": "0.1",
    "background": {
        "persistent": false,
        "scripts": ["background.js"]
    },
    "content_scripts": [{        
        "matches": ["http://oa.com/*"],
        "js":      ["content.js"]
    }],
    "browser_action": {
        "default_icon": "icon.png",
        "default_popup": "popup.html"
    },

    "permissions": ["activeTab"],

    "icons": { "48": "icon.png" }
}
```
`backgroud` 字段指明 `background.js` 为在后台永远默默执行的代码。`content_scripts` 字段指明当我们在地址栏打开 `http://oa.com/*` 匹配的网站时，它会去执行 `content.js`，相当于监听正则表达式匹配的网站。`default_popup` 字段指明点击插件按钮时弹出来的框的页面内容 `popup.html`，其实就是一个普通网页，如下所示，它需要单独的 `popup.js` 来进行交互。弹窗页面的 js 是打开后执行一次，生命周期和普通网页一样。

![image](/assets/images/chrome-plunge-1.jpg)

完成这个需求只需要在 `background.js` 里监听页面中的剩余时间，当剩余时间小于 5 分钟时，提交按钮事件就可以达到目的了。但这个按钮一天只能点 6 次，超过之后必须输入验证码。这时就无能为力了。

-----------------

## 排期迭代

功能虽然简单，也要一步步来，分为三期迭代。

一期：跑通 Chrome 插件的例子，理解原理机制

二期：在插件弹窗页面实时显示访问开发网剩余时间；不需要验证码授权时，剩余时间小于阈值则自动授权

三期：需要验证码授权时，把验证码显示在弹窗里，提醒输入验证码后进行授权。后来发现这个功能不好做，验证码模块的 HTML 代码是写在 iframe 中的，这是一个跨域问题啊（敲黑板）！

------------

## 主要逻辑

``` javascript
function success(text) {
    var textpos = $("#time_left");
    var startPos = text.indexOf("访问外网时间剩余");
    var endPos = text.indexOf("分钟");
    var timeStr = text.substring(startPos + 31, endPos + 2);

    var hourStartPos = timeStr.indexOf("小时");
    var miniteStartPos = timeStr.indexOf("分钟");
    if (hourStartPos == -1 && parseInt(timeStr.substring(miniteStartPos - 2, miniteStartPos)) < 5) {
        //请求下授权
        accessInternet(text);
    }
}

function accessInternet(text) {
     text.querySelector("#btnDevTempVisit").click();
     var myDate = new Date();
     console.log(myDate.toLocaleString() + ": A click been excuted");
}

function executeAjax() {
    var request = new XMLHttpRequest();
    request.withCredentials = true; 

    request.onreadystatechange = function() {
        if (request.readyState === 4) {
            if (request.status === 200) {
                return success(request.responseText)
            } else {
                return fail(request.status)
            }
        } else {
        }
    }

    request.open('GET', 'http://xxxx/NetVisit');
    request.send();
}

function getLeftTime() {
  //定期获取 OA 网站内容
  setInterval(executeAjax, 3600000);
}
```

主要逻辑在后台代码 `background.js` 中，使用 `setInterval` 定时功能固定时间去检测访问情况。

比较奇怪的是单独直接打开 `popup.html`，它会调用 `popup.js`，里面也会执行 Ajax 请求 OA 网站，但会出现跨域错误。显然站点服务端是不支持跨域的。

```
XMLHttpRequest cannot load http://xxxx/NetVisit. 
No 'Access-Control-Allow-Origin' header is present on the requested resource. 
Origin 'null' is therefore not allowed access.
```

那么写在插件里 JS 又是怎么达到目的的呢。那是因为 Chrome 插件是浏览器自产自销的，不受限于同源策略。

> 普通网页能够使用 XMLHttpRequest 对象发送或者接受服务器数据, 但是它们受限于同源策略. 扩展可以不受该限制. 任何扩展只要它先获取了跨域请求许可，就可以进行跨域请求。

这里的 Ajax 请求也会带上本地的 Cookie。

---------

### iframe 跨域问题

页面引用了单独的验证码模块，一旦使用 `getElementById` 类似的方法，就会出现

> Blocked a frame with origin from accessing a cross-origin frame

的错误，[stackoverflow](http://stackoverflow.com/questions/25098021/securityerror-blocked-a-frame-with-origin-from-accessing-a-cross-origin-frame) 上也有讨论。显然在不侵入验证码模块时，无法让两个窗口进行通信，<del>不不，多贵的电脑也不行</del>，HTML5 的 `postMessage` 方案也不行。

道哥「白帽子讲 Web 安全」中有一节讲利用 `postMessage` 去进行 XSS 攻击。这个 API 不受同源策略限制，允许一个 window（当前窗口、弹窗、iframe 等）对象往其他 window 发送文本消息，从而实现窗口信息传递。

不过毕竟是 Chrome 的插件，还是有方法获取 iframe 的内容的：使用 `content_scripts` 的 `all_frames = true` 选项。`content_scripts` 是打开匹配的网站时，`content.js` 进行加载，获取到验证码后和 popup 弹窗进行通信，把提醒消息和验证码发到弹窗。弹窗手动输入验证码后发送消息到 `content.js` 发起授权。

-----------

## 参考

[让张总泪流满面的 CTRL+V 出现了](http://www.alibuybuy.com/posts/15130.html)

[白帽子讲 Web 安全 6.2.2](https://book.douban.com/subject/10546925/)

[http://stackoverflow.com/questions/25098021/securityerror-blocked-a-frame-with-origin-from-accessing-a-cross-origin-frame](http://stackoverflow.com/questions/25098021/securityerror-blocked-a-frame-with-origin-from-accessing-a-cross-origin-frame)

[http://open.chrome.360.cn/html/dev_xhr.html](http://open.chrome.360.cn/html/dev_xhr.html)

[http://blog.allenm.me/2010/11/chrome-extension-cannot-read-iframe/](http://blog.allenm.me/2010/11/chrome-extension-cannot-read-iframe/)

[http://stackoverflow.com/questions/8917593/do-chrome-extensions-access-iframes](http://stackoverflow.com/questions/8917593/do-chrome-extensions-access-iframes)


