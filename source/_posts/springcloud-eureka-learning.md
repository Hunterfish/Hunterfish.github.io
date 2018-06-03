---
title: Spring Cloud Eureka--服务注册发现
date: 2018-05-13 10:59:09
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Eureka
---
# 了解服务注册发现  

参考博客[SpringCloud学习1-服务注册与发现(Eureka)](https://www.cnblogs.com/woshimrf/p/springclout-eureka.html)  

## 分布式系统中为什么需要服务发现？  

1. 只有两个服务，他们都有自己的地址   
> 此时如果A服务调用B服务，只需在A服务中配置B服务地址  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/86609379.jpg)

2. 分布式服务，单节点A如何寻找多节点的服务B   
> 当B节点不多的时候，我们可以把所有的节点B的地址全都配置在A中  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/17463888.jpg)

3. 在2的基础上，B服务节点有100个甚至更多  
> 此时就不能使用上面的方法，把所有的B服务的地址全部配置在A服务中了。  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/28706408.jpg)

4. 而且现在云服务时代，B服务数量有可能不停动态变化：  
> 当流量小时，B服务数量减少； 当流量大时，就需要更多的B服务；  
> 而且B服务也有可能随时挂掉。  

## 引入注册中心  

### 分析  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/28338490.jpg)
1. B启动时，就把自己地址上报到注册中心；  
2. A如果调用B服务，就去注册中心获取B服务的地址信息即可  
3. 因此，分布式系统中，服务注册中心是最重要的基础部分  
> 随时都应该处于提供服务的状态，无论是Eureka还是其他相同功能的组件，承担分布式系统中的注册中心都应该是高可用的，也都是基本采用集群的解决方案；  

### 服务发现的两种方式  

1. **客户端发现**：A直接去注册中心查询B服务信息  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/28338490.jpg)
> A从注册中心拿到一堆B服务的地址，通过轮询、随机、哈希等等（就是负载均衡机制）从众多可用的B服务挑选一个，通过ip地址找到一个B服务；  
> 这种就是**客户端发现**，是由A发起的。  

2. **服务端发现**  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-14/7650221.jpg)
> 增加**代理**，帮A从众多可用的B中挑选一个出来  

#### 客户端发现  

* **Eureka**  

#### 服务端发现  

* **Nginx**  
> Nginx不仅可以作为Http反向代理服务器和负载均衡器；  
> 也可以作为服务发现的负载均衡器  

* **zookeeper**  
> 作为Dubbo的注册中心  

* **Kubernetes**  

## 微服务**异构**  

### 异构特点  

* 不同语言  
> 各个服务间可以用不同的开发语言实现  

*不同类型的数据库  
> 每个服务根据需要选择适合自己的数据库  

### SpringCloud的服务调用方式  

> Spring Cloud是一个强大的微服务框架，但它是纯java的；  
> 但微服务落地时，特别是越大的微服务系统，遇到的非java部分也是99%以上了，因为每种语言都有自己的优势；  
> 针对不同的语言，如何实现轻量级的通信呢？  

* **RESTapi接口**  
> 比较流行的还有RPC  
> Eureka支持将非java语言实现的服务纳入到自己的服务治理体系中来，只需要其他语言自己实现Eureka client的客户端程序；  
> 比如Node.js的eureka-js-client  

# Spring Cloud Eureka简介  

基于Netflix Eureka做了二次封装  

## Eureka 两个组件  

1. Eureka Server 注册中心  
> Eureka服务端供服务注册的服务器;  
> 系统其它微服务使用Eureka客户端连接到注册中心，并维持心跳连接，监控系统各个微服务是否正常运行  

2. Eureka Client 服务注册  
> Eureka客户端用来简化客户端与服务的交互；  
> 作为轮询负载均衡器，并提供服务的故障切换功能。  

# Eureka Server高可用  

> 生产环境一定要高可用（大于等于2个Server节点）；  
> 开发环境使用一个就可以了  

## 单点  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/22118683.jpg)

## 双节点  

> 实现Server节点的相互注册  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/61755903.jpg)

### idea启动两个实例  

* 修改Run/debug configurations  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/78385075.jpg)

* application.yml  
> 注释掉端口配置  
```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    register-with-eureka: false
  server:
    enable-self-preservation: false # 开发环境配置，生产环境不要配置（不显示警告)
spring:
  application:
    name: eureka
#server:
#  port: 8761
```

* 启动8761时，修改注册地址为8762  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/77448070.jpg)

* 启动8762时，修改注册地址为8761  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/84789552.jpg)

* client端，注册地址为8761，启动    
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/413485.jpg)

* 浏览器访问Eureka server 8761和8762  
> 会发现此时两个注册中心都注册了client服务  

### 测试高可用  

1. 停止注册中心8761，发现8762上依然以后client服务；  
2. 在1的基础上停止client服务，发现8762上依然有client服务，这是由于心跳机制缓存；  
3. 重启client服务，发现8762上client服务消失，因为client的application.yml中只配置了8761；  
4. 我们可以在client的application.yml中配置两个注册中心地址：  
```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8762/eureka/,http://localhost:8762/eureka/
spring:
  application:
    name: client
```

## 三节点：两两注册  

> 本质上和双节点是一样的，Eureka Server之间互相注册，client客户端注册所有服务注册中心地址  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-13/29622199.jpg)

### Eureka Server配置   
> application.yml注册地址端口号  

* 8761 ==> 8762,8763  
* 8762 ==> 8761,8763
* 8763 ==> 8761,8762  

### Eureka Client配置  
```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8762/eureka/, http://localhost:8762/eureka/, http://localhost:8762/eureka/
spring:
  application:
    name: client
```

# Eureka总结  

* **@EnableEurekaServer @EnableEurekaClient**  
> 这两个注解分别启动Server和client；  
> Eureka Server会提供服务注册功能，各个服务节点启动后会在Eureka Server中注册，这样就有了所有服务节点的注册信息。  

* **心跳检测**  
> 如果在系统运行期间，某个服务节点挂掉，也就是在规定的时间内没有发送心跳信号；  
> 这个时候就会被Eureka Server自动剔除掉  

* **健康检查**  

* **负载均衡**  
> 如果某个服务的流量增加，你只需要增加相应的服务节点即可  

* **Eureka的高可用**  
> 生产上建议至少两台以上，不要单台  

* **分布式系统中，服务注册中心是最重要的基础部分**  










