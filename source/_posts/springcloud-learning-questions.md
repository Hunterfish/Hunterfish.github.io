---
title: Spring Cloud学习过程中遇到问题总结
date: 2018-05-13 14:44:53
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - 总结
---
# 遇到解决问题  

## Process finished with exit code 0  

> 启动新建Eureka-client客户端项目时，自动结束了项目  

```java
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Single vip registry refresh property : null
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Force full registry fetch : false
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Application is null : false
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Registered Applications size is zero : true
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Application version is -1: true
2018-05-13 14:48:47.656  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Getting all instance registry info from the eureka server
2018-05-13 14:48:47.978  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : The response status is 200
2018-05-13 14:48:47.983  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Starting heartbeat executor: renew interval is: 30
2018-05-13 14:48:47.987  INFO 13796 --- [           main] c.n.discovery.InstanceInfoReplicator     : InstanceInfoReplicator onDemand update allowed rate per min is 4
2018-05-13 14:48:47.992  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Discovery Client initialized at timestamp 1526194127990 with initial instances count: 1
2018-05-13 14:48:47.996  INFO 13796 --- [           main] o.s.c.n.e.s.EurekaServiceRegistry        : Registering application client with eureka with status UP
2018-05-13 14:48:47.996  INFO 13796 --- [           main] com.netflix.discovery.DiscoveryClient    : Saw local status change event StatusChangeEvent [timestamp=1526194127996, current=UP, previous=STARTING]
2018-05-13 14:48:47.999  INFO 13796 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CLIENT/localhost:client:8090: registering service...
2018-05-13 14:48:48.014  INFO 13796 --- [           main] com.hunter.client.ClientApplication      : Started ClientApplication in 8.655 seconds (JVM running for 12.228)
2018-05-13 14:48:48.017  INFO 13796 --- [      Thread-37] s.c.a.AnnotationConfigApplicationContext : Closing org.springframework.context.annotation.AnnotationConfigApplicationContext@5b478eab: startup date [Sun May 13 14:48:43 CST 2018]; parent: org.springframework.context.annotation.AnnotationConfigApplicationContext@2140de63
2018-05-13 14:48:48.019  INFO 13796 --- [      Thread-37] o.s.c.n.e.s.EurekaServiceRegistry        : Unregistering application client with eureka with status DOWN
2018-05-13 14:48:48.019  WARN 13796 --- [      Thread-37] com.netflix.discovery.DiscoveryClient    : Saw local status change event StatusChangeEvent [timestamp=1526194128019, current=DOWN, previous=UP]
2018-05-13 14:48:48.021  INFO 13796 --- [      Thread-37] o.s.c.support.DefaultLifecycleProcessor  : Stopping beans in phase 0
2018-05-13 14:48:48.025  INFO 13796 --- [      Thread-37] com.netflix.discovery.DiscoveryClient    : Shutting down DiscoveryClient ...
2018-05-13 14:48:48.069  INFO 13796 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CLIENT/localhost:client:8090 - registration status: 204
2018-05-13 14:48:48.070  INFO 13796 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CLIENT/localhost:client:8090: registering service...
2018-05-13 14:48:48.074  INFO 13796 --- [nfoReplicator-0] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CLIENT/localhost:client:8090 - registration status: 204
2018-05-13 14:48:48.075  INFO 13796 --- [      Thread-37] com.netflix.discovery.DiscoveryClient    : Unregistering ...
2018-05-13 14:48:48.081  INFO 13796 --- [      Thread-37] com.netflix.discovery.DiscoveryClient    : DiscoveryClient_CLIENT/localhost:client:8090 - deregister  status: 200
2018-05-13 14:48:48.091  INFO 13796 --- [      Thread-37] com.netflix.discovery.DiscoveryClient    : Completed shut down of DiscoveryClient
2018-05-13 14:48:48.092  INFO 13796 --- [      Thread-37] o.s.j.e.a.AnnotationMBeanExporter        : Unregistering JMX-exposed beans on shutdown
2018-05-13 14:48:48.092  INFO 13796 --- [      Thread-37] o.s.j.e.a.AnnotationMBeanExporter        : Unregistering JMX-exposed beans
Disconnected from the target VM, address: '127.0.0.1:60152', transport: 'socket'

Process finished with exit code 0
```

* 解决方案：[原参考链接](https://blog.csdn.net/qq920447939/article/details/80189347)
* pom.xml文件添加依赖: **spring-boot-starter-web**
```xml
    <!-- web应用 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
```
