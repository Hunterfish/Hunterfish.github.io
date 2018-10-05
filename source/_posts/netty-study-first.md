---
title: Netty笔记--后期整理
date: 2018-10-05 10:14:04
categories: Netty
tags: 
  - Netty
---

* 前言  

** 学习资料  

1. [Netty入门与实战：仿写微信 IM 即时通讯系统
](https://juejin.im/book/5b4bc28bf265da0f60130116/section/5b6a1a9cf265da0f87595521)  

** 总结知识点  

1. Netty使用的IO模式--高性能IO之Reactor模式

> Netty、Redis等大多数IO相关组件使用的IO模式，参考<https://www.cnblogs.com/doit8791/p/7461479.html>  

2. 理解**服务端**绑定监听端口方法返回的一个``Future``、**客户端**连接服务端返回的``Future``，说明这两个方法是异步的。  参考``Java Futrue``资料：<https://blog.csdn.net/u014209205/article/details/80598209>。  

3. 无论是``netty``，还是原始的``Socket``编程，基于``TCP``通信的数据包格式均为**二进制**。  
> 协议指的是客户端与服务端事先商量好的

4. 序列化和编码都是把``java``对象封装成二进制数据的过程，它们的区别和联系  
> 编码在将java对象序列化后按照约定的协议规则处理。简单来说，序列化是将java对象持久化成二进制流，编码是将信息从一定格式转换成另一种格式，序列化可以看做是一种编码方式。  

> 除了``json``序列化方式外，还有``xml``、``protobuf``方式。


