---
title: 2018工作项目总结-个人项目仿微信聊天项目
date: 2018-10-25 08:42:18
categories: 工作日志
tags:
  - 总结
  - 面试
---

## 简介  

基于后端netty、前端websocket实现的前后端分离项目，模仿微信，实现微信单聊、群聊功能功能，本意是自己学习netty的项目。  

## 后端架构  

基于SpirngBoot、shiro的后端开发基础框架。

## 前端架构  

* 项目地址：[my_wechat_ui](https://gitee.com/ddebug/my_wechat_ui.git)  

* 基于跨平台APP开发方案[wetouch](http://www.wetouch.net/)，开发完成后，直接打包  
> wetouch对免费用户只有100M免费流量，请注意！  

## 启动流程  

### 后端  

1. 克隆项目到本地  
> git clone https://gitee.com/ddebug/my_wechat_admin.git  

2. 启动后台管理中心  
> 运行模块 ``admin-service`` 的主程序文件 ``AdminApplication``  

### 前端  

1. 克隆项目到本地  
> git clone git@192.168.50.186:java/ldd-admin-ui.git  

2. 启动前端  

* 安装依赖 
> npm install  

* 开发环境运行  
> npm run dev

* 进入项目  
> 浏览器访问：<http://0.0.0.0:8181>  

## 过程    

1. 服务端发送消息到客户端，客户端向服务端发送签收响应；  
2. 主要处理**网络的不稳定性**、**网络的无响应**、**安全认证**、**客户端心跳重连机制**、**消息编解码**等问题；  
3. 客户端和服务器建立长连接，服务端会保存着这个长连接，然后对长连接进行轮询看看是否有新的消息；
4. 当客户端socket在非正常情况掉线，比如断网、断电，服务端没有收到连接关闭命令，连接对象不会自从关闭，继续保持着连接活跃。  

## 常见技术  

### netty  

#### 推送消息状况  

1. 信息阅读的方式比较多，例如：pc、手机、ipad、穿戴设备等等。  

2. 现在使用网络质量并不是稳定的，网络主要是运营商的无线移动网，例如在地铁上、山区、沙漠信号就很差，容易发生网络闪断；

3. 海量的终端链接，而且通常使用长连接，服务器维持大量长连接，资源消耗都非常大；  

4. 谷歌开发的推送框架无法再国内使用，android的应用必须自己由于谷歌的推送框架无法在国内使用，Android的长连接是由每个应用各自维护的，这就意味着每台安卓设备上会存在多个长连接。即便没有消息需要推送，长连接本身的心跳消息量也是非常巨大的，这就会导致流量和耗电量的增加；

不稳定：消息丢失、重复推送、延迟送达、过期推送时有发生；垃圾消息到处是。  

#### netty优点  

``Netty``提供异步的、事件驱动的网络应用程序框架和工具，用以快速开发高性能、高可靠性的网络服务器和客户端程序。  

1. 统一的API，适用于不同的协议（阻塞和非阻塞）,比如http/tcp/udp。  
2. 基于灵活、可扩展的事件驱动模型,采用了链式的事件模型。  
3. 高度可定制的线程模型。  
4. 可靠的无连接数据Socket支持（UDP）。  
5. 更好的吞吐量，低延迟。  

#### 

### TCP协议模型  

参考博客：[TCP/IP 协议和 OSI 模型](http://www.cookqq.com/blog/8a10a5f35382ba2e0153e9e2ffe0304d)  

TCP/IP协议由应用层、传输层（tcp）、网络层（IP）和数据链路层（物理层）四层组成。 


## 问题  

1. Netty中boss线程池大小为1，worker线程池大小为8, new NioEventLoopGroup(8)，其余线程分配给业务使用。  

2. 由于超时时间过长，100W个长链接链路会创建100w长连接对象（比如channel/IdlChannelHandlerAdapter/ScheduledFutureTask ...），每个对象还保存有业务的成员变量，非常消耗内存。一些定时任务被老化到持久代中，没有被JVM垃圾回收掉，内存一直在增长，用户误认为存在内存泄露。 所以说一些长时间没有通信的链接需要关闭掉。 定时心跳显得很重要，如果300s没有收到任何信息，则把链接关闭掉。  

3. 不要在Netty的I/O线程上处理业务（心跳发送和检测除外）。为什么呢？？  
> 因为Java进程，线程不能无限增长。这就意味着Netty的Reactor线程数必须收敛。但是在实际业务处理中，经常会有一些额外的复杂逻辑处理，例如性能统计、记录接口日志等，这些业务操作性能开销也比较大，如果在I/O线程上直接做业务逻辑处理，可能会阻塞I/O线程，影响对其它链路的读写操作，或者导致一些链路的关闭或者打开比较慢。

4. 写日志的时候小心

在生产环境中，需要实时打印接口日志，其它日志处于ERROR级别，当推送服务发生I/O异常之后，会记录异常日志。如果当前磁盘的WIO比较高，可能会发生写日志文件操作被同步阻塞，阻塞时间无法预测。这就会导致Netty的NioEventLoop线程被阻塞，Socket链路无法被及时关闭、其它的链路也无法进行读写操作等。  

5、-Xmx:JVM最大内存需要根据内存模型进行计算并得出相对合理的值；  

## 服务器消息重发  

参考：[基于netty的企业即时通讯系统的设计与实现-服务器消息重发](http://www.cookqq.com/blog/8a10a5f35382ba2e0153c2f707e11e9e)  


## 服务器端跨域  

参考：[服务器端解决跨域问题的三种方法](https://blog.csdn.net/james_wade63/article/details/50772041)

## 表结构设计  

### 群消息设计    
  
1. 群消息，只存一份。  
> 如果为每一个成员设置一个群消息队列，会有大量数据冗余，不合适。  

2. 确定未读消息  
> 利用群消息的偏序关系，记录每个成员已读的最后一条消息，那么该消息之前的消息都是已读，之后的消息
都是未读。  
> 即对于群内的每一个用户，只需要记录一个值即可。  

3. 群消息表
```sql
CREATE TABLE `message` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '消息id',
  `type` int(4) DEFAULT NULL COMMENT '消息类型：1：私聊；2：群聊',
  `receiver_id` int(11) DEFAULT NULL COMMENT '联系人id（接收方）；type为1：联系人id, type为2：群id',
  `sender_id` int(11) DEFAULT NULL COMMENT '用户id（发送方）',
  `message_type` int (11) DEFAULT NULL COMMENT '类型  1：文字；3：图片；43：音频；47：emoji；48：位置；49：文件',
  `content` text COMMENT '消息格式 【发信人id:内容】',
  `sign_status` int(11) DEFAULT NULL COMMENT '消息状态  0: 未签收；1: 签收',
  `create_time` datetime(0) DEFAULT NULL COMMENT '消息发送时间',
  `updated_time` datetime(0) NULL DEFAULT NULL COMMENT '消息状态更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='消息记录表';
```
4. 群成员表  
```sql
CREATE TABLE `chat_group_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '群成员id',
  `chat_group_id` int(11) NOT NULL COMMENT '群组id',
  `user_remark_name` VARCHAR(50) DEFAULT NULL COMMENT '用户所在群昵称',
  `last_ack_msg_id` int(11) DEFAULT NULL COMMENT '群成员最后收到的一条群消息ID',
  `create_time` datetime(0) NOT NULL,
  `updated_time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='群组表';
```