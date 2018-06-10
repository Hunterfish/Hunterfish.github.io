---
title: Spring Cloud 实战 (一)：初识微服务架构与Spring Cloud
date: 2018-05-12 17:07:06
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
---
学习期间参考了大神博客：
1. [springCloud Finchley 从入门到精通实战系列](https://segmentfault.com/blog/spring-cloud)  
2. [Spring Cloud 学习 【Finchley版】](https://windmt.com/tags/Spring-Cloud/page/2/)  
3. [Spring Cloud 2 Finchley.M9 概览](https://www.jianshu.com/p/c52b1089ea92)  

# 微服务架构简介  

> 微服务是一种架构风格，她不是某种组件或某种框架；比如我们熟悉的RESTful，也是一种架构风格；  
> 架构风格即没有强制性，没有绝对标准的答案，是一种建议，可以有不同细节的实现。  

## [官方定义](https://martinfowler.com/articles/microservices.html#footnote-etymology)

> In short, the microservice architectural style is an approach to developing a single application as **a suite of small services**, 
each **running in its own process** and communicating with lightweight mechanisms, often an HTTP resource API. These services are **built 
around business capabilities** and **independently deployable** by fully automated deployment machinery. There is **a bare minimum of centralized 
management of these servicesJ**, which may be written in different programming languages and use different data storage technologies.  

### 官方定义重点  

* 一系列微小的服务共同组成  
> 对应传统的单体应用：一个服务  

* 跑在自己的进程里  
> 任何一个微服务，都有自己的独立进程，互不干扰  

* 每个服务为独立的业务开发  
> 微服务要围绕业务围绕领域模型建造：服务拆分  

* 独立部署  

* 分布式的管理  
> 对应传统的集中式管理  

## 传统架构  

### 点餐系统涉及的架构形态   

点击回顾之前的[SpringBoot微信点餐系统](https://www.ddebug.cn/springboot-wechat-ordering-project-summary.html#more)  

* 单体架构  
> 一个工程构建之后是一个war包  

* 基于Ajax的前后端分离  

* 分布式（水平扩展 & 服务拆分）  

### 单体架构  

#### 以点餐系统为例  

下图显示点餐系统卖家端业务:  
1. 传统的CMS后台管理系统  
> 包含了商品、订单、类目三种服务，这三种服务对应了三种业务逻辑代码，可以把它看成整体就是单体架构的应用；  

2. 所有应用打包成一个war/jar包，整体上没有外部依赖  
> 这里外部依赖不是指pom.xml文件里的各种dependency，意思是订单依赖商品服务，但此时是一个整体，整合到一个war包里了  

3. 部署在一个Web容器里  
> 比如Tomcat, 包含了Dao层，Service层，UI等所有逻辑；  
> 当然不一定是Tomcat，我们使用的Spring Boot实现的内部默认实现的Tomcat容器也可以改成Jetty等其他web容器, 这里暂且不表  

4. 共用一个DB数据库
 
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/53165413.jpg)

#### 单体架构优点  

* 容易测试  
> 在本地就可以启动完整的项目，不需要外部依赖  

* 容易部署  
> 直接打成一个完整的War包，放到Tomcat等web容器中就可以运行  

#### 单体架构缺点  

* 开发效率低  
> 所有开发人员在一个项目里改代码，提交代码时可能等待或造成代码冲突  

* 代码维护难  

* 部署不灵活  
> 跟容易部署是两个概念，是指部署时间比较长，有任何代码的小修改必须重新部署整个项目  

* 稳定性不高  
> 所有业务代码写到一个项目，一个微不足道的小问题可能让整个系统挂掉，牵一发而动全身！  

* 扩展性不够  
> 无法满足高并发情况下的业务需求；  
> 比如买家们都只看不买的情况比较多，商品服务应对的流量大一些，订单服务应对的流量相反就小一些，
此时单体架构很难做到，因为商品订单服务都在一个整体中，运行也在一个war包里运行；  
> 而微服务很容易做到，因为商品和订单服务独立开来，可以将商品服务部署10台服务器，订单服务部署5台服务器。  

### [基于Ajax的前后端分离](https://blog.csdn.net/finish_dream/article/details/52231469)  
这种开发模式可以称为SPA(Single Page Application 单页面应用)  
参考[Web研发模式演变](https://github.com/lifesinger/blog/issues/184)  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/68979207.jpg)

#### 点餐服务的前后端分离  
下图显示的是买家端： 

1. SpringBoot后端服务可以多个  
> 因为项目里我们使用Redis实现了Session共享，从而使springBoot服务支持水平扩展（集群部署）
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/53634998.jpg)

### 分布式架构  

> 旨在支持应用程序和服务的开发，可以利用物理架构由**多个自治的处理元素**，**不共享主内存**，但**通过网络发送消息合作**。  

需要理解：微服务必然是分布式的！  

* 多个自治的处理元素  
> 即多节点，分布式系统是多节点的，集群也是多节点的  
> 分布式：一个厨房有炒菜和洗菜，互不干扰。  
> 集群：一个厨房炒菜有5个人  

* 通过网络发送消息合作  
> 比如通过http、RESTful接口、RPC等，放到微服务中同样适用； 

## 微服务架构  

### 一个简单的微服务架构图  

> 后端、前端、服务注册发现都是可以集群化的  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/45578133.jpg)

1. 服务注册发现  
> 微服务内部相互通信；  
> 服务提供方注册服务，把自己的地址信息暴露出来；  
> 服务调用方才能发现需要的服务。  

2. 服务网关(Service Gateway)  
> 外界访问微服务，比如手机、浏览器，通过前端路由（服务网关组件）使自己的服务暴露出去；  
> 服务网关是连接内外的大门，有一下作用：  
> 1. 对外屏蔽后台服务的细节，后台升级或修改，对外用户是无感知的  
> 2. 路由功能：将外部的请求反向路由的内部的某个具体的微服务  
> 3. 限流和容错：所有的请求都会经过网关，可以控制流量，监控和打印日志  
> 4. 微服务安全性：网关可以对请求进行控制，比如用户的认证、授权、反爬虫等等。  

3. 后端通用服务(也称中间层服务Middle Tier Service)  
> 后端服务启动时，会将地址信息注册到服务注册表中；  
> 前端服务通过查询注册表就可以发现并调用后端服务。  

4. 前端服务(也称边缘服务Edge Service)  
> 主要作用：对后端服务作必要的**聚合和裁剪**后暴露给外部不同的设备。  
> **聚合**：对多个api调用逻辑进行聚合，从而减少客户端的请求数。比如客户端调用用户基本信息和收获地址两个接口api，前端服务可以合二为一，作为一
个接口提供出去，客户端只需调用前端服务的一个接口就可以了；  
> **裁剪**：根据不同的需求返回不同的数据。比如PC端和手机端访问同一个api商品详情接口，返回的内容详细程度可能不一样，大家熟知的淘宝就是这样；
又或者PC端我们需要返回Html，手机端需要返回JSON报文，这时需要前端服务裁剪工作了。  

### 微服务化点餐项目  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/12903115.jpg)

1. Vue Web App ---> 前端服务  
2. SpringBoot后端服务 ---> 后端通用服务  

### 微服务"配方"  

#### 阿里系  

1. Dubbo：核心，服务治理  
2. Zookeeper：服务注册中心  
3. SpringMVC or SpringBoot  
4. ....  

#### Spring Cloud  
1. Spring Cloud Netflix Eureka  
2. SpringBoot  
3. ....  

# Spring Cloud简介    

1. Spring Cloud是一个开发工具集  
> 利用Spring Boot的开发便利  
> Spring Cloud是一个基于Spring Boot实现的云应用开发工具，它为基于JVM的云应用开发中涉及的配置管理、服务发现、断路器、智能路由、微代理、控制总线、全局锁、决策竞选、分布式会话和集群状态管理等操作提供了一种简单的开发方式。

2. Spring Cloud包含了多个子项目  
> 主要是基于对Netflix开源组件的进一步封装  
> Spring Cloud包含了多个子项目（针对分布式系统中涉及的多个不同开源产品），比如：Spring Cloud Config、Spring Cloud Netflix、Spring Cloud0 CloudFoundry、Spring Cloud AWS、Spring Cloud Security、Spring Cloud Commons、Spring Cloud Zookeeper、Spring Cloud CLI等项目  
