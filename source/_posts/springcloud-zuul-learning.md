---
title: Spring Cloud 实战 (十二)：Zuul--服务网关 (1)
date: 2018-06-07 13:45:40
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Zuul
---

上一篇学习了 Spring Cloud 组件 ``Stream``和 RabbitMQ 结合异步通知发送消息；本篇介绍另一个组件``Zuul``：服务网关。  

# 服务网关  

## 为什么需要服务网关   

1. 假如没有网关服务，启动十几个服务后，客户端需要和这十几个服务分别打交道，显然不现实，需要一个统一的 request 请求入口；  
2. 充当上面入口的就是**服务网关**，所有请求都会通过它。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/61016426.jpg)

## 服务网关要素   

1. **稳定性、高可用**  
> 因为所有请求都要经过服务网关，所以保证 7*24小时都可用，网关瘫痪，系统全挂，致命伤害。  

2. **性能、并发性**  
> 所有请求都经过网关，压力巨大。  

3. **安全性**  
> 确保服务安全，防止外部恶意访问。  

4. **扩展性**    
> 所有请求都经过网关，理论上，网关是处理各种非业务功能的绝佳场所，如**协议转发、防刷、流量管控、日志监控**等等。  

## 常见网关方案  

第一代 **Zuul** 性能上还不能和 **Nginx** 相比，据说第二代能相比，但还没有具体验证。  

1. **Nginx + Lua**  
> 性能和高可用是 Nginx 傲视群雄的资本，先天的事件驱动型设计、全异步网络 IO 处理机制、极少的进程间切换以及许多优化设计都使得 Nginx 天生善于处理高并发请求；  
> 扩展性上，本身被设计成由多个不同功能、不同层次、不同类型且耦合度极低的模块组成，当对某一个模块修复 bug 或升级时，其他模块不受影响。  

2. **Kong**  
> [Kong](https://getkong.org/) 一款商业的 API 管理软件；  
> 本身是基于上面 Nginx + Lua 实现的，但配置简单。  

3. **Tyk**  
> [Tyk](https://tyk.io/) 是开源的、轻量级的、快速可伸缩的 API 网关；  
> 支持配额和速度限制，支持认证和数据分析，支持多用户多组织,还提供全 Restful API;  
> Go 语言开发，Go 是 Google 的亲儿子，在并发编程上具有天然优势，在性能和扩展性上也非常不错。  

4. **Spring Cloud Zuul**  
> Zuul 是 Netflix 出品的一个基于 JVM 路由和服务端的负载均衡器，天生服务于微服务；  
> 参考链接<https://blog.csdn.net/xf1195718067/article/details/78637807>；  

### Zuul

### Zuul 的特点  

Zuul 相比 Nginx 优势不足，但是 Spring Cloud 完整生态构建服务体系的前置网关服务还是不错的选择。  

1. **路由+过滤器 = Zuul**    

2. **核心就是一系列的过滤器**  
> Servlet 的过滤器 filter 都不陌生，Zuul实现服务网关的核心就是一系列的过滤器； 
> 每一个进入 Zuul 的 Http 的请求都会经过这一列过滤器，处理之后，得到响应并返回给客户端； 

### Zuul 的四种过滤器 API  

1. **前置(Pre)**  
> 典型应用场景：可以**限流**，流量过大时，依据某些规则，可以把请求挡回去，后续逻辑就不再处理了；  
> 可以**鉴权**，如果我们有三个服务，如果每个服务都要鉴权一次，非常麻烦，我们可以把鉴权的逻辑写到前置过滤器中；  
> 可以**参数校验调整**；等等  

2. **后置(Post)**  
> 统计：对象、时间等；  
> 日志：记录；  

3. **路由(Route)**  
4. **错误(Error)**  

### Zuul 架构图  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/78393182.jpg)

### 请求生命周期   

1. 一次 HTTP Request 请求的生命周期;  
2. 下图中间灰色部分都是 zuul 的各种过滤器，Origin Server 就是我们的服务，比如 **product**、**order**；  
3. "custom" filters ：我们可以自定义的过滤器。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/24258310.jpg)

### Zuul的高可用  

所有的请求都要经过 Zuul，所以生产环境中我们都会部署多台 Zuul，以避免**单点故障**。  

1. **多个 Zuul 节点注册到 Eureka Server**  
> 可以把 Zuul 当成普通服务注册到 Eureka 上；
> 此时 Zuul 的高可用和其他的服务比如之前已经介绍过的 config-server、order 的高可用没有什么区别；  
> 微服务系统内部调用时，A 服务可以调用到某个 Zuul 服务，再通过它转发到 B 服务；  
> 对于外部调用，我们可以使用下面混搭方式。  

2. **Nginx 和 Zuul “混搭”方式**  
> 使用 Nginx 对外暴露一个 URL，Nginx 把请求转发到多个 Zuul服务上；  
> Nginx 继续做负载均衡，从而做到 Nginx 和 Zuul 的取长补短；

## 点餐项目分析   

既然上面提到 **Zuul** 性能还不能和 **Nginx** 相比，为什么使用？如何使用呢？

### 项目改造  

1. 灵活使用技术，学会混搭；  
2. 原来我们的点餐项目是 Nginx 在前，Tomcat 在后，Nginx 做了负载均衡和反向代理；  
3. 现在我们依然让 Nginx 发挥负载均衡和反向代理优势，后面的 Tomcat 换成 Zuul;  
4. 而Zuul 发挥自己的优势。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/99358170.jpg)

# Zuul 实战  

## 初始化 api-gateway 项目 

1. **新建``api-gateway``项目**  
> 选择下面三种配置  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/67071377.jpg)

2. **pom.xml**  
> 更改 boot、Cloud 版本  

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.0.1.RELEASE</version>
    <relativePath/> <!-- lookup parent from repository -->
</parent>

<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <java.version>1.8</java.version>
    <spring-cloud.version>Finchley.RC1</spring-cloud.version>
</properties>
```

3. **ApiGatewayApplication.java**  
> 添加注解``@EnableZuulProxy``  

```java
@SpringBootApplication
@EnableZuulProxy
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
```

## Zuul 基本功能  

### Zuul 转发功能   

现在实现转发非常简单，添加依赖和在启动类上添加注解，但是弊端也很明显，第四条必须遵守特定的访问路径规则。  

1. docker启动``rabbitmq``、``redis``;  
2. 运行``eureka``、``product``、``config``、``order``、``api-gateway``服务； 
3. 测试``product``get 请求：http://localhost:8080/product/list  
> 成功请求数据！  
4. 测试``api-gateway``，请求：http://localhost:8082/product/product/list  
> 第一个 **product**为注册到 **eureka**上的服务名称！  
> 成功请求数据！  

### 自定义路由  

1. **bootstrap.yml**  
> serviceId：注册的服务名称  

```yaml
# 自定义路由
zuul:
  routes:
    myProduct:
      path: /myProduct/**
      serviceId: product
```

2. 再次访问：http://localhost:8082/myProduct/product/list  
> 成功请求数据！  
> 发现其实访问默认：http://localhost:8082/product/product/list 也是成功的！  

3. 查看路由规则路径  
> ``api-gateway``启动时，并执行一次路由转发访问后，打印到 console 上  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/34331428.jpg)

4. 1 中的配置也可以简写成下面形式：  

```yaml
# 自定义路由
zuul:
  routes:
    product: /myProduct/**
```

### 排除路由  

当我们不想让用户访问``product``服务的某些接口时，我们可以排除路由。  

1. **pom.xml**  

```yaml
  # 排除某些路由
  ignored-patterns:
#    - /product/product/list
#    - /myProduct/product/list
  - /**/product/listForOrder
```

2. 访问：http://localhost:8082/product/product/list、http://localhost:8082/myProduct/product/list  
> 报``404``错误，无法访问！  

## Zuul 传递 Cookie

我们在开发 **Web** 项目是，经常会使用到 **Cookie**，Cookie 需传递到后端，但是使用 **Zuul**组件后，Cookie是无法传递过去的！  

### 测试是否拿到  Cookie  

1. 手动设置 Cookie  
> 访问 http://localhost:8082/myProduct/product/list；  
> F12下，``document.cookie='openid=abc123456'``  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/91069339.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/2591488.jpg)

2. /product/list 接口上断点  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/5465613.jpg)

3. 重新访问第 1 步中路径，查看后台是否拿到 Cookie 信息  
> 发现为空！经过 **Zuul**路由转发后 Cookie 无法传递！  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/84204254.jpg)

### 传递Cookie   

1. **bootstrap.yml**  
> 添加``sensitiveHeaders``  

```yaml
# 自定义路由
zuul:
  routes:
    myProduct:
      path: /myProduct/**
      serviceId: product
      sensitiveHeaders:
```

2. 重新执行上一小节内容  
> 成功获取 **Cookie**  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/26717776.jpg)

### Zuul 动态路由  

动态路由即动态配置，之前在 [Spring Cloud实战 (九)：config--统一配置中心组件](https://www.ddebug.cn/springcloud-config-center-learning.html)一章中已经讲过。  

1. **api-gateway-dev.yml**  
> github 远端仓库 [config-repo](https://github.com/Hunterfish/config-repo)新建文件；  
> ``api-gateway``项目中``bootstrap.yml``部分配置文件移到上述新建文件中。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/76666259.jpg)

2. **ZuulConfig.java**  
> 当我们在 git 远端仓库``config-repo``修改配置文件后，后端也要同时动态修改  

```java
/**
 * 功能描述: 配置动态注入
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/7 0007 16:54
 */
@Component
public class ZuulConfig {

    @ConfigurationProperties("zuul")
    @RefreshScope
    public ZuulProperties zuulProperties() {
        return new ZuulProperties();
    }
}
```

3. 当然，如果你不执行第2步，也可以直接在 **ApiGatewayApplication.java** 中配置   
```java
@SpringBootApplication
@EnableZuulProxy
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }

    @ConfigurationProperties("zuul")
    @RefreshScope
    public ZuulProperties zuulProperties() {
        return new ZuulProperties();
    }
}
```















