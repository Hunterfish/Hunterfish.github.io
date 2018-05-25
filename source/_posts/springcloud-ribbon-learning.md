title: Spring Cloud Ribbon--负载均衡器
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Ribbon
date: 2018-05-15 10:06:00
---
# Ribbon简介  

之前在[Spring Cloud Eureka--服务注册发现](https://www.ddebug.cn/springcloud-eureka-learning.html)一文中学习过服务端发现和客户端发现的两种服务注册发现方式。  
Eureka属于客户端发现。Eureka的负载均衡是软负载，也就是客户端会向服务器（Eureka Server）拉取已注册的可用的服务信息，然后根据负载均衡策略命中哪台机器发送服务请求。整个过程都是在客户端完成，并不需要服务器（Eureka Server）参与。  
SpringCloud的**客户端负载均衡**就是**Ribbon**组件，它是基于**Netflix Ribbon**组件实现的，通过SpringCloud的封装，可以轻松的面向服务的Rest模板请求，自动转化为客户端负载均衡服务调用。  

## Ribbon应用  

> Spring Cloud在结合了Ribbon的负载均衡实现中，封装增加了HttpClient和OkHttp两种请求端实现，默认使用了Ribbon对Eureka服务发现的负载均衡client。  

* **RestTemplate** 
在[Spring Cloud Feign--应用通信](https://www.ddebug.cn/springcloud-feign-learning.html) 一文中我们介绍了服务间通信RestTemplate的三种使用方式；  
通过添加@LoadBalanced注解或者直接@AutoWired注入LoadBalancerClient，其实就是试用了Ribbon的组件；  
> 添加@LoadBalanced注解后，Ribbon会通过LoadBalancerClient自动的帮助你基于某种规则，比如简单的轮询、随机连接等去连接目标服务，从而很容易使用Ribbon实现服务的负载均衡算法。

* **Feign**  
* **Zuul**  

## Ribbon核心  

Ribbon实现负载均衡，核心有三点：  

* **服务发现**  
> 发现依赖服务的列表，通俗讲，依据服务的名字，把该服务所有的实例都找出来  

* **服务选择规则**  
> 依据规则策略（轮询、随机），如何从多个服务找到有效的服务  

* **服务监听**  
> 检测失效的服务，做到高效剔除  

## Ribbon主要组件  

> 整体流程：首先通过ServerList来获取所有的可用服务列表，然后通过ServerListFilter过滤掉一部分地址，最后剩下的地址中通过IRule选择一个实例作为最终目标结果。

* **ServerList**  
* **Rule**  
* **ServerListFilter**  

# 源码分析  

[深入理解Ribbon之源码解析](https://blog.csdn.net/forezp/article/details/74820899)  







