---
title: Netty笔记--后期整理
date: 2018-10-05 10:14:04
categories: Netty
tags: 
  - Netty
---

# 前言  

## 学习资料  

1. [Netty入门与实战：仿写微信 IM 即时通讯系统
](https://juejin.im/book/5b4bc28bf265da0f60130116/section/5b6a1a9cf265da0f87595521)  

2. [netty源码深度分析](https://www.jianshu.com/nb/7981390)  

3. [Netty面试相关](https://blog.csdn.net/baiye_xing/article/details/76735113)  

4. [微信聊天表结构设计](https://wenku.baidu.com/view/b7c83e54ba0d4a7302763acf.html)  

5. [微信小程序中如何使用WebSocket实现长连接](https://www.cnblogs.com/imstudy/p/9224604.html)  

6. [新手入门一篇就够：从零开发移动端IM](http://www.52im.net/thread-464-1-1.html)  

7. [大佬的netty企业即时通讯系统博客](http://www.cookqq.com/listBlog.action?type=8a10a5f34e38beab014e4cd6b9e801cf)  




## 总结知识点  

1. ``Netty``是基于Java NIO的``client-server``框架。  
> 作为一个异步NIO框架，Netty的所有IO操作都是异步非阻塞的，通过``Future-Listener``机制，用户可以很方便的主动获取或者通过通过机制获得IO操作结果。  

2. ``Netty``是一个高性能、异步事件驱动的NIO框架，它提供了对**TCP**、**UDP**、和**文件传输**的支持。  
> Netty、Redis等大多数IO相关组件使用的IO模式--高性能IO之Reactor模式，参考<https://www.cnblogs.com/doit8791/p/7461479.html>  

3. 自定义客户端服务端通信协议设计**魔数**的原因。  
> 尽早屏蔽非本协议的客户端

4. 理解**服务端**绑定监听端口方法返回的一个``Future``、**客户端**连接服务端返回的``Future``，说明这两个方法是异步的。  参考``Java Futrue``资料：<https://blog.csdn.net/u014209205/article/details/80598209>。  

5. 无论是``netty``，还是原始的``Socket``编程，基于``TCP``通信的数据包格式均为**二进制**。  
> 协议指的是客户端与服务端事先商量好的

6. 序列化和编码都是把``java``对象封装成二进制数据的过程，它们的区别和联系  
> 编码在将java对象序列化后按照约定的协议规则处理。简单来说，序列化是将java对象持久化成二进制流，编码是将信息从一定格式转换成另一种格式，序列化可以看做是一种编码方式。  
> 除了``json``序列化方式外，还有``xml``、``protobuf``方式。  

### netty高性能特点  

1. 接口同步转异步处理；  
2. 回调通知结果；  
3. 多线程提高并发效率；  

### 遇到的问题  

1. 异步之后事务如何保证？  
2. 回调失败的情况？  

### netty的核心组件  

* channel;  
* 回调；  
* Future;  
* 事件和ChannelHandler;  

这些构建块代表了不同类型的构造：资源、逻辑以及通知。你的应用程序将使用它们来访问网络以及流经网络的数据。  

1. Future、回调和ChannelHandler  

Netty的异步编程模型是建立在Future和回调的概念之上的， 而将事件派发到ChannelHandler的方法则发生在更深的层次上。结合在一起，这些元素就提供了一个处理环境，使你的应用程序逻辑可以独立于任何网络操作相关的顾虑而独立地演变。这也是Netty的设计方式的一个关键目标。

拦截操作以及高速地转换入站数据和出站数据，都只需要你提供回调或者利用操作所返回的Future。这使得链接操作变得既简单又高效，并且促进了可重用的通用代码的编写。

2. 选择器、事件和EventLoop  

Netty通过触发事件将Selector从应用程序中抽象出来，消除了所有本来将需要手动编写的派发代码。在内部，将会为每个Channel分配一个EventLoop，用以处理所有事件，包括：

* 注册感兴趣的事件；  
* 将事件派发给ChannelHandler；  
* 安排进一步的动作。  

EventLoop本身只由一个线程驱动，其处理了一个Channel的所有I/O事件，并且在该EventLoop的整个生命周期内都不会改变。这个简单而强大的设计消除了你可能有的在你的ChannelHandler中需要进行同步的任何顾虑，因此，你可以专注于提供正确的逻辑，用来在有感兴趣的数据要处理的时候执行。如同我们在详细探讨Netty的线程模型时将会看到的，该API是简单而紧凑的。



### Reactor 线程模型  

详细请参考：[高性能IO之Reactor模式](https://www.cnblogs.com/doit8791/p/7461479.html)。  

netty 提供了三种Reactor线程模型：

1. 单线程模型：所有的IO操作都由同一个NIO线程处理的。  

  * 三个``client``连接了``server``,连接过程单线程处理的，该单线程要完成client连接、读取请求，响应请求。 
  * 理论上，简单业务单线程处理上述所有逻辑没有问题，但高负载、大并发性能上支持不了，此时，client连接服务端，如果连接不上，就会执行重试，加重服务器负载，造成单节点故障或宕机。  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-1/14354713.jpg)

2. 多线程模型：由一组NIO线程处理IO操作  

  * 可以看到，由原先的``Reactor单线程``拆分两块，一块为``Reactor单线程``，一块为``Reactor线程池``；
  * 左边负责client连接，丢给线程池处理数据读写请求。  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-1/59444344.jpg)

3. 主从线程组模型：一组线程池接收客户端请求，另一组线程池处理io操作  

  * 原来``Reactor单线程``变为``主线程池``，后面更名为``从线程池``。  
  * 官方推荐的线程模型，高效  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-11-1/33303710.jpg)

### websocket  

实时通信的方式：  

1. Ajax轮询  
> 循环访问，不停建立http访问链接，耗费性能

2. Long pull  
> 阻塞模型，循环访问服务端，性能差

3. websocket  
> 一旦建立连接，服务端会主动的推送消息到客户端，客户端不需要请求服务端。  
> 只需要一次http请求连接，服务端主动推送消息，节省资源。  

#### websocket api  

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

### 心跳机制    

1. netty与三个手机（客户端）连接，此时Channel数量3个； 
![]()
2. 如果用户手动关闭手机websocket进程，服务端自定义的handler会把每个channel关闭并移除，此时Channel数量为0；  
3. 如果用户开始飞行模式，websocket进程没有关闭，服务端Channel数量还是3个；
![]()
4. 如果有几千上万的手机端开启了飞行模式，服务端的channel没有关闭，造成资源的浪费；  
5. 所以我们要在客户端做心跳机制，检测失败的关闭Channel。  

### 责任链模式  

> 通俗讲，将对象处理连成一条链，使得请求可以在链中进行传递，直到有一个对象处理他为止。  

#### 角色  

1. 抽象处理者角色（Handler）  
> 定义一个处理请求接口，接口中定义出一个方法用来设定和返回对下个处理者的引用，通常用Java抽象类或者Java接口实现。  

2. 具体处理角色（ConcreteHandler）  
> 具体处理者接到请求后，可以选择将请求处理掉，或者将请求传给下家，由于具体处理者持有对下家的引用，因此，如果需要，具体处理者可以访问下家。  

#### 实例  

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
  







