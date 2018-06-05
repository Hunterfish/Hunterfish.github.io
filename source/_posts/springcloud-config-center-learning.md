---
title: Spring Cloud 实战 (九)：config--统一配置中心组件
date: 2018-05-31 10:23:34
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - config
---

# 前言  

参考博客[Spring Cloud - Config统一配置管理](https://www.jianshu.com/p/55e92b06a7fd)  

## 为什么需要统一配置中心  

1. **不方便维护**  
> 解决多个开发人员对配置文件修改，冲突不利于维护  

2. **配置内容安全与权限**  
> 主要是针对线上配置来说。  
> 一个公司线上项目的配置文件不会对开发人员公开，特别是敏感内容比如数据库密码等等，只有管理者或运维才能知道；  

3. **更新配置项目需要重启**  
> 线上更新文案或限制，比如短信验证码一天错误限制，可能需要修改；  
> SpringCloud config组件能做到  

## 统一配置中心架构  

1. 统一配置中心可以作为项目的单独的一个微服务，也包含了server端和client端；  
2. server端：配置文件为了方便管理，放到远端git上用于版本控制。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/43489584.jpg)

# 实战config-server服务  

[个人码云私有项目地址](https://gitee.com/ddebug/config-repo)  

## 统一版本  

一开始使用SpringBoot【2.0.0.M3】、SpringCloud【Finchley.M2】经常出现错误，无法查询远传git配置文件信息；  

```xml

```
所以统一SpringBoot和SpringCloud版本，以免以后太多坑！！  
> eureka、config、order、product、都修改下面新版本  

依赖|旧版本|新版本  
-|-|-|    
Spring Boot|2.0.0.M3|2.0.1.RELEASE    
Spring Cloud|Finchley.M2|Finchley.RC1  

## config-server端  

### 注意事项  

1. **创建注意事项**  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/2191390.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/71443228.jpg)

2. **版本号**  
> 修改为上面版本号  

### 初始化为Eureka-Client   

1. **pom.xml**  
> 引入``spring-cloud-starter-netflix-eureka-client``依赖  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

2. **ConfigApplication.java**   
> SpringCloud【Finchley.RC1】版本已经不需要注解``@EnableDiscoveryClient``  

```java
@SpringBootApplication
// @EnableDiscoveryClient
public class ConfigApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConfigApplication.class, args);
	}
}
```
3. **application.yml**  

```yaml
spring:
  application:
    name: config
eureka:
  client:
    service-url: 
      defaultZone: http://localhost:8761/eureka/ 
```

4. **启动eureka，启动config，访问<http://localhost:8761/>**  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/41307372.jpg)

### 初始化成Config-Server  

1. **pom.xml**  
> 引入依赖``spring-cloud-config-server``  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
</dependency>
```

2. **ConfigApplication.java**   
> 在**上一节基础上**添加注解``@@EnableConfigServer``  

2. **新建远程git仓库**   
> 可以在码云上创建  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/18705545.jpg)

3. **application.yml**   
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

4. **重新启动项目，访问<http://localhost:8080/order-a.yml>**   
> 下小节讲解上述访问URL如何定义的！！   

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/15155589.jpg)

### 配置中心访问url路径规则  

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
```
> ``{name}``：通常使用微服务名称，对应Git仓库中文件名的前缀；     
> ``{profile}``：对应{name}-后面的dev、pro、test等；  
> ``{label}``：对应Git仓库的分支名，默认为master。  

2. **访问**<http://localhost:8080/order-a.properties>、<http://localhost:8080/order-a.json>  
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
> 看需求，都可以，经常使用下面两种格式了    

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
> 添加配置``basedir``  

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
          password: ***********
          # 配置到项目下，也可以配置到其他路径
          basedir: E:\springcloudservice\config\basedir
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

3. **重新访问<http://localhost:8080/release/order-dev.yml>**   

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/88213574.jpg)

## config-client端：order  

### order初始化为config-client      

1. **pom.xml**   
> server子模块pom.xml引入依赖``spring-cloud-starter-config``  
> 因为**order**即是Eureka-client，也是Config-Client，下面依赖都不可少  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

2. **application.yml**  

```yaml
spring:
  application:
    name: order
server:
  port: 8081
```

3. **bootstrap.yml**  
> **特别注意**：与 Spring Cloud Config 相关的属性必须配置在 bootstrap.yml 中，config 部分内容才能被正确加载。因为 config 的相关配置会先于 application.yml，而 bootstrap.yml 的加载也是先于 application.yml。  

```yaml
spring:
  cloud:
    config:
      name: order
      profile: dev
      lable: master
      discovery:
        enabled: true   # 开启config服务发现支持
        service-id: config   # config：Config-Server端服务名  
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

4. **OrderApplication.java**   
> 删除注解``@EnableDiscoveryClient``  

```java
@SpringBootApplication
// @EnableDiscoveryClient
@EnableFeignClients(basePackages = ("cn.hunter.product.client"))
public class OrderApplication {

	public static void main(String[] args) {
		SpringApplication.run(OrderApplication.class, args);
	}
}
```

5. **EnvController.java**  
> 测试是否从config中获取配置文件的配置信息  
  
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
> 启动eureka、config、order服务  
> 测试修改order的bootstrap.yml``profile``为``test``，测试能够获取    

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/50923784.jpg)

### 配置中心config高可用   

1. **config** 配置中心微服务启动多个实例``-Dserver.port=9002``  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/73732896.jpg)

2. **多次启动 order** 微服务  
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













