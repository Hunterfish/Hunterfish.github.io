---
title: Netty源码学习-Netty基本组件
date: 2018-11-08 20:24:50
categories: Netty学习总结
tags: 
  - Netty
---

# Netty基本组件  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/98467937.jpg)

* NioEventLoop  

可以看做Netty的发动机，启动了两种线程：
1. 监听客户端的连接；   
2. 处理客户端的读写。  

* Channel  

其实就是对连接（socket）的封装，在channel封装的api里面你可以对数据进行读写。  

* Pipeline  

对数据的读写可以看做一个个逻辑的链，逻辑处理链的一个个链就是下面的ChannelHandler  

* ChannelHandler  

* ByteBuf  
在ChannelHandler中对数据的读写、操作都是基于ByteBuf来操作的。  





