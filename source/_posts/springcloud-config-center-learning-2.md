---
title: SpringCloud统一配置中心组件——config(2)
date: 2018-06-01 17:11:26
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - config
---
# Spring Cloud Bus动态刷新配置  

## 原理分析  

1. **config-server**从远端git拉取配置文件存到本地，同时提供对外的服务；  
2. **order**服务启动时，访问**config-server**，读取配置；  
3. **order**启动后，在修改**config-server**配置，order读取过的配置不会变了；  
4. **config-server**会通知**order**服务更新配置文件，通过``rabbitmq``消息队列传递信息；    
5. Spring Cloud微服务中使用**SpringCloud Bus**组件操作消息队列；    
6. **config-server**使用**Bus**组件后，对外提供一个Http接口``/bus-refresh``；  
7. **远端git**访问该接口，**config-server**就会把更新配置信息发送到mq中；  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/30523127.jpg)

## 添加Bus组件    

### 版本更改  

> 测试，M3版本下报错，config微服务修改版本号  

依赖|旧版本|新版本  
-|-|-|    
Spring Boot|2.0.0.M3|2.0.0.BUILD-SNAPSHOT  
Spring Cloud|Finchley.M2|Finchley.BUILD-SNAPSHOT  

### config-server   

1. pom.xml  
> 引入bus依赖  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bus-amqp</artifactId>
</dependency>
```

### config客户端-Order服务  

1. 修改版本，见上；  
> 版本升级后，feign组件名称需要修改  


2. pom.xml【server子模块】  
> 引入bus依赖  
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bus-amqp</artifactId>
</dependency>
```

  
  
  
