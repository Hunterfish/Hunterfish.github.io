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

2. [netty源码深度分析](https://www.jianshu.com/nb/7981390)  

3. [微信聊天表结构设计](https://wenku.baidu.com/view/b7c83e54ba0d4a7302763acf.html)  



** 总结知识点  

* Netty使用的NIO模式--高性能IO之Reactor模式

> Netty、Redis等大多数IO相关组件使用的IO模式，参考<https://www.cnblogs.com/doit8791/p/7461479.html>  

* 自定义客户端服务端通信协议设计**魔数**的原因。  
> 尽早屏蔽非本协议的客户端

* 理解**服务端**绑定监听端口方法返回的一个``Future``、**客户端**连接服务端返回的``Future``，说明这两个方法是异步的。  参考``Java Futrue``资料：<https://blog.csdn.net/u014209205/article/details/80598209>。  

* 无论是``netty``，还是原始的``Socket``编程，基于``TCP``通信的数据包格式均为**二进制**。  
> 协议指的是客户端与服务端事先商量好的

* 序列化和编码都是把``java``对象封装成二进制数据的过程，它们的区别和联系  
> 编码在将java对象序列化后按照约定的协议规则处理。简单来说，序列化是将java对象持久化成二进制流，编码是将信息从一定格式转换成另一种格式，序列化可以看做是一种编码方式。  
> 除了``json``序列化方式外，还有``xml``、``protobuf``方式。  

*** Reactor 线程模型  
> netty 提供了三种Reactor线程模型

1. 单线程模型：所有的IO操作都由同一个NIO线程处理的。  

  * 三个``client``连接了``server``,连接过程单线程处理的，该单线程要完成client连接、读取请求，响应请求。 
  * 理论上，简单业务单线程处理上述所有逻辑没有问题，但高负载、大并发性能上支持不了，此时，client连接服务端，如果连接不上，就会执行重试，加重服务器负载，造成单节点故障或宕机。  

2. 多线程模型：由一组NIO线程处理IO操作  

  * 可以看到，由原先的``Reactor单线程``拆分两块，一块为``Reactor单线程``，一块为``Reactor线程池``；
  * 左边负责client连接，丢给线程池处理数据读写请求

3. 主从线程组模型：一组线程池接收客户端请求，另一组线程池处理io操作  

  * 原来``Reactor单线程``变为``主线程池``，后面更名为``从线程池``。  
  * 官方推荐的线程模型，高效  

** websocket  

实时通信的方式：  

1. Ajax轮询  
> 循环访问，不停建立http访问链接，耗费性能

2. Long pull  
> 阻塞模型，循环访问服务端，性能差

3. websocket  
> 一旦建立连接，服务端会主动的推送消息到客户端，客户端不需要请求服务端。  
> 只需要一次http请求连接，服务端主动推送消息，节省资源。  

*** websocket api  

1. var socket = new WebSocket("ws://[ip]:[port]")  
> 服务端和客户端通过url地址连接  

2. 生命周期：onopen()、onmessage()、onerror()、onclose()  
  
  * onopen(): client和server连接时触发
  * onmessage(): client收到消息时触发  
  * onerror(): server等异常触发
  * onclose: client断开连接触发  
3. 主动方法  

  * new WebSocket().send(): 客户端发送消息到服务端  
  * new WebSocket().close(): 关闭客户端和服务端连接  
  







