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

4. [微信小程序中如何使用WebSocket实现长连接](https://www.cnblogs.com/imstudy/p/9224604.html)   



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

** 心跳  

1. netty与三个手机（客户端）连接，此时Channel数量3个； 
![]()
2. 如果用户手动关闭手机websocket进程，服务端自定义的handler会把每个channel关闭并移除，此时Channel数量为0；  
3. 如果用户开始飞行模式，websocket进程没有关闭，服务端Channel数量还是3个；
![]()
4. 如果有几千上万的手机端开启了飞行模式，服务端的channel没有关闭，造成资源的浪费；  
5. 所以我们要在客户端做心跳机制，检测失败的关闭Channel。  

** 责任链模式  

*** 责任链  

> 通俗讲，将对象处理连成一条链，使得请求可以在链中进行传递，直到有一个对象处理他为止。  

*** 角色  

1. 抽象处理者角色（Handler）  
> 定义一个处理请求接口，接口中定义出一个方法用来设定和返回对下个处理者的引用，通常用Java抽象类或者Java接口实现。  

2. 具体处理角色（ConcreteHandler）  
> 具体处理者接到请求后，可以选择将请求处理掉，或者将请求传给下家，由于具体处理者持有对下家的引用，因此，如果需要，具体处理者可以访问下家。  

*** 实例  

* ``Handler.java``: 抽象处理者角色
```java
public abstract class Handler {
  /** 持有后继的责任对象 */
  protected Handler successor;

  /** 处理请求的方法，自定义参数 */
  public abstract void handleRequest();

  /**
   * 取值方法
   */
   public Handler getSuccessor() {
     return successor;
   }

   /** 赋值方法，设置后继的责任对象 */
   public void setSuccessor(Handler successor) {
     this.successor = successor;
   }
}

```

* ``ConcreateHandler.java``: 具体处理者角色  
```java
public class ConcreateHandler extends Handler {
  /**
   * 处理请求方法
   */
   @Override
   public void handleRequest() {
     // 判断是否有后继的责任对象
     // 1. 如果有，转发给后继的责任对象
     // 2. 如果没有，处理请求
     if (getSuccessor() != null) {
       getSuccessor().handleRequest();
     } else {
       System.out.println("处理请求");
     }
   }
}
```

* ``Client.java``: 客户端类  
```java
public class Client {
  public static void main(String[] args) {
    // 组装责任链
    Handler handler1 = new ConcreateHandler();
    Handler handler2 = new ConcreateHandler();
    handler1.setSuccessor(handler2);
    // 提交请求
    handler1.handleRequest()
  }
}
```
  







