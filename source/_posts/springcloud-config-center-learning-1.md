---
title: SpringCloud统一配置中心组件——config(1)
date: 2018-05-31 10:23:34
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - config
---

# 前言  

参考博客[Spring Cloud - Config统一配置管理](https://www.jianshu.com/p/55e92b06a7fd)  

## 为什么需要统一配置中心  

1. 不方便维护  
> 解决多个开发人员对配置文件修改，冲突不利于维护  

2. 配置内容安全与权限  
> 主要是针对线上配置来说。  
> 一个公司线上项目的配置文件不会对开发人员公开，特别是敏感内容比如数据库密码等等，只有管理者或运维才能知道；  

3. 更新配置项目需要重启  
> 线上更新文案或限制，比如短信验证码一天错误限制，可能需要修改；  
> SpringCloud config组件能做到  

## 统一配置中心架构  

1. 统一配置中心可以作为项目的单独的一个微服务，也包含了server端和client端；  
2. server端：配置文件为了方便管理，放到远端git上用于版本控制。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/43489584.jpg)

# 实战config-server服务  

[个人码云私有项目地址](https://gitee.com/ddebug/config-repo)   

## config-server端  

### 注意事项  

1. **创建注意事项**  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/2191390.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/71443228.jpg)

2. **版本号**  

> 确保版本号一致，否则报错信息不好处理！！  

依赖|版本号  
-|-|  
Spring Boot|2.0.0.M3  
Spring Cloud|Finchley.M2  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/74263447.jpg)

### 初始化项目

1. ConfigApplication.java  
> 因为config项目本身也是一个服务，所以添加注解``@EnableDiscoveryClient``  

```java
@SpringBootApplication
@EnableDiscoveryClient
public class ConfigApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConfigApplication.class, args);
	}
}
```
2. application.yml  

```yaml
spring:
  application:
    name: config
eureka:
  client:
    service-url: 
      defaultZone: http://localhost:8761/eureka/ 
```

3. 启动eureka，启动config，访问<http://localhost:8761/>  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/41307372.jpg)

### 初始化成config-server    

1. ConfigApplication.java  
> 添加注解``@@EnableConfigServer``  

2. 新建远程git仓库  
> 可以在码云上创建  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/18705545.jpg)

3. application.yml  
> 配置远程仓库地址  

```yaml
spring:
  application:
    name: config
  cloud:
    config:
      server:
        git:
          uri: https://gitee.com/ddebug/config-repo
          username: ddebug
          password: ********
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

4. 重新启动项目，访问<http://localhost:8080/order-a.yml>   
> 访问格式下面会将为何如此写！  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/15155589.jpg)

### 理解配置中心访问url路径规则    

1. **当config项目启动后，控制台中心，你可以看到** 
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/11667827.jpg)  

```yaml
/{name}-{profiles}.properties
/{name}-{profiles}.yml || /{name}-{profiles}.yaml
/{name}/{profiles:.*[^-].*}
/{label}/{name}-{profiles}.yml || /{label}/{name}-{profiles}.yaml
/{name}/{profiles}/{label:.*}
/{name}-{profiles}.json
/{label}/{name}-{profiles}.properties
/{label}/{name}-{profiles}.json
/{name}/{profile}/{label}/**
/{name}/{profile}/{label}/**

{name}通常使用微服务名称，对应Git仓库中文件名的前缀；
{profile}对应{name}-后面的dev、pro、test等；
{label}对应Git仓库的分支名，默认为master。
```

2. **尝试访问**<http://localhost:8080/order-a.properties>、<http://localhost:8080/order-a.json>  
> 发现返回相应格式的配置文件  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/68979852.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/6924783.jpg)

3. **远程git仓库[config-repos](https://gitee.com/ddebug/config-repos)新建order-dev.yml、order-test.yml**  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/71702856.jpg)

4. **访问**<http://localhost:8080/order-dev.yml>、<http://localhost:8080/order-test.yml>   

5. **创建release分支进行访问配置文件**<http://localhost:8080/release/order-dev.yml>     

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/89288736.jpg)

> 访问<http://localhost:8080/release/order-dev.yml>  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/12228473.jpg)

6. **常用方式**   
> 看需求，都可以  

```yaml
/{name}-{profiles}.properties
/{label}/{name}-{profiles}.yml
```

### 远程配置文件存储位置  

统一配置中心会把远端git配置文件拉取到本地git中，拉倒哪了呢？  

1. **console控制台**  
> 可以看到，拉到某一个目录中

```java
2018-05-31 11:44:28.629  INFO 4268 --- [nio-8080-exec-7] o.s.c.c.s.e.NativeEnvironmentRepository  : Adding property source: file:/C:/Users/ADMINI~1/AppData/Local/Temp/config-repo-7525068817470639949/order-dev.yml
2018-05-31 11:44:28.629  INFO 4268 --- [nio-8080-exec-7] o.s.c.c.s.e.NativeEnvironmentRepository  : Adding property source: file:/C:/Users/ADMINI~1/AppData/Local/Temp/config-repo-7525068817470639949/order.yml
```

2. **application.yml**添加位置配置   
> 出于项目安全，特别是线上，配置文件放到指定目录;  
> 添加路径**basedir**  

```yaml
spring:
  application:
    name: config
  cloud:
    config:
      server:
        git:
          uri: https://gitee.com/ddebug/config-repo
          username: ddebug
          password: lhq19931201
          # 配置到项目下，也可以配置到其他路径
          basedir: E:\springcloudservice\config\basedir
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

3. **重新访问**<http://localhost:8080/release/order-dev.yml>   

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/88213574.jpg)

## config-client端：order服务  

### order修改为config客户端    

1. **server子模块pom.xml引入依赖**   

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-client</artifactId>
</dependency>
```

2. **注意：修改feign版本为``2.0.0.M1``，否则报错**  

参考地址：<https://coding.imooc.com/learn/questiondetail/49125.html>  
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-feign</artifactId>
    <version>2.0.0.M1</version>
</dependency>
```

3. **application.yml修改为bootstrap.yml**  
> springboot特性，如果不修改，不能从远端git中读物配置文件了  

4. **OrderApplication.java**不需要修改  

5. **新建EnvController.java**，测试是否拿到配置文件：  
```java
@RestController
@RequestMapping("/env")
public class EnvController {

    @Value("${env}")
    private String env;

    @GetMapping("/print")
    public String print() {
        return env;
    }
}
```
6. **访问<http://localhost:8080/env/print>**  
> 你也可以测试``test``  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/50923784.jpg)

### 配置中心高可用  

1. **config**配置中心微服务启动多个实例``-Dserver.port=9002``  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/73732896.jpg)

2. **多次启动order**微服务  
> 可以发现每一次启动可能会从不同地址的config-server读取配置文件  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/8165937.jpg)

###  总结配置文件  

#### config-server  

* application.yml  

```yaml
spring:
  application:
    name: config
  cloud:
    config:
      server:
        git:
          uri: https://gitee.com/ddebug/config-repos
          username: ddebug
          password: lhq19931201
          # 拉取远程git端配置文件到本地位置
          basedir: E:\springcloudservice\config\basedir
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
server:
  port: 8888
```

#### order  

* bootstrap.yml  
> 注册中心配置在这里因为默认端口8761，如果修改为其他端口，无法从配置中心服务**config**读取远端git配置文件；  

```yaml
spring:
  application:
    name: config
  cloud:
    config:
      server:
        git:
          uri: https://gitee.com/ddebug/config-repos
          username: ddebug
          password: lhq19931201
          basedir: E:\springcloudservice\config\basedir
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
server:
  port: 8888
```

#### 远端git``config-repos``配置文件  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/68597127.jpg)

* order.yml  
> 可以不配置，也可以添加dev、test等相同配置  

* order-dev.yml  

```yaml
spring:
  application:
    name: order
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    username: root
    password: root
    url: jdbc:mysql://127.0.0.1:3306/SpringCloud_Sell?characterEncoding=utf-8&useSSL=false
env:
  dev
```













