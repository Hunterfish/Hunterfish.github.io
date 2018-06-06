---
title: Spring Cloud 实战 (十一)：Stream--消息驱动组件
date: 2018-06-06 14:01:10
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Stream
---
# Stream 组件简介  

操作消息队列的一种方法，是 Spring Cloud 的一种组件之一，**为微服务应用构建消息驱动能力的框架**。  

## 分析  

1. 应用程序通过``inputs``或者``outputs``来与``Stream``中的``Binder``交互；  
2. 而``Binder``来与``Middleware``中间件交互；  
3. ``Binder``是``Stream``的一种抽象概念，是应用与消息中间件的粘合剂（binder中文就是这个意思）；  
4. 使用``Stream``最大的方便之处就是：对消息中间件的进一步封装，可以做到代码层面对中间件的无感知，甚至于动态的切换中间件，切换 Topic;  
5. ``Stream``局限：目前的``Binder``只支持``RabbitMQ``和``Kafka``这两种。  

![](1)

# 实战使用  

参考博客[Spring Cloud整合RabbitMQ或Kafka消息驱动(二十二)](https://blog.csdn.net/mrspirit/article/details/80574164)


