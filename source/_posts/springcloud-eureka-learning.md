---
title: Spring Cloud Eureka--服务注册发现
date: 2018-05-13 10:59:09
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Eureka
---
# 了解服务注册发现  

## 分布式系统中为什么需要服务发现？  
![]()





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










