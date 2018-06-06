---
title: Spring Cloud 实战 (十)：bus--消息总线组件
date: 2018-06-01 17:11:26
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - config
---
# Spring Cloud Bus动态刷新配置  

## 原理分析  

参考博客[配置中心(消息总线)【Finchley 版】](https://windmt.com/2018/04/19/spring-cloud-9-config-eureka-bus/)  

1. **config-server** 从远端git拉取配置文件存到本地，同时提供对外的服务；  
2. **order** 服务启动时，访问 **config-server**，读取配置；  
3. **order** 启动后，在修改 **config-server** 配置，order 读取过的配置不会变了；  
4. **config-server** 会通知 **order** 服务更新配置文件，通过``rabbitmq``消息队列传递信息；    
5. Spring Cloud 微服务中使用 ``SpringCloud Bus`` 消息总线组件操作消息队列；    
6. **config-server** 使用 ``Bus`` 组件后，对外提供一个Http接口 ``/bus-refresh``；  
7. **远端git** 访问该接口，**config-server** 就会把更新配置信息发送到mq中；  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-1/30523127.jpg)

## 实战操作  

### 服务端 config-server   

1. **pom.xml**  
> 引入bus依赖``spring-cloud-bus``  
> 下面4个依赖是必须的  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-bus</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-stream-binder-rabbit</artifactId>
</dependency>
```

2. **application.yml**   
> 暴露**bus-refresh**接口  

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
          basedir: E:\basedir
    bus:
      enabled: true
      trace:
        enabled: true
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
management:
  endpoints:
    web:
      exposure:
        include: bus-refresh
```

### 客户端-Order服务  

1. **install 【product】 服务**  
> 因为 **order** 依赖了 **product** 子模块 **product-client**  
> 不要忘了修改 **product** ``springboot``、``springcloud``版本  

```jshelllanguage
mvn -Dmaven.test.skip=true clean install
```

2. pom.xml【server子模块】  
> 引入bus依赖 ``spring-cloud-bus``     
> 前五个是必须的  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-bus</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-stream-binder-rabbit</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```
3. **application.yml**  
> 在服务端 **config** 和客户端 **order** 都暴露了``bus-refresh``端口  

```yaml
spring:
  application:
    name: order
  cloud:
    bus:
      trace:
        enabled: true
      enabled: true
server:
  port: 8081
management:
  endpoints:
    web:
      exposure:
        include: bus-refresh
```

4. **bootstrap.yml**  

```yaml
spring:
  cloud:
    config:
      name: order
      profile: dev
      lable: master
      discovery:
        enabled: true   # 开启config服务发现支持
        service-id: config-server
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

5. **EnvController.java**  
> 添加注解 ``@RefreshScope``  
> 测试获取从服务端 **config** 获取远端仓库 **config-repos** 配置文件  

```java
@RestController
@RequestMapping("/env")
@RefreshScope
public class EnvController {

    @Value("${env}")
    private String env;

    @GetMapping("/print")
    public String print() {
        return env;
    }
}
```

### 测试  

首先启动docker中的rabbitmq，参考之前博客[Spring Cloud 实战 (七)：使用RabbitMQ实现服务间异步消息调用](https://www.ddebug.cn/springcloud-rabbitmq-async-message.html#more)    

```jshelllanguage
docker run -d --hostname my-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:3.7.5-management
```

1. **启动服务**  
> 分别启动 **eureka**、**config**、和两个 **order**  

```jshelllanguage
// 打包 order
mvn clean package -Dmaven.test.skip=true
java -jar order-server-0.0.1-SNAPSHOT.jar --server.port=8081
java -jar order-server-0.0.1-SNAPSHOT.jar --server.port=8082
```

2. **Rabbit中心 <http://localhost:15672>**  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/92111033.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/79806051.jpg)

3. **访问**<htp://localhost:8081/env/print>、<http://localhost:9081/env/print>    
> 返回内容都是dev  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/72735464.jpg)

4. git 仓库 ``config-repos`` order-dev.yml 修改 ``env: dev2``  

5. 执行``curl -X POST http://localhost:8888/actuator/bus-refresh``  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/1104392.jpg)
 
6. 再次访问 3 中的链接，返回 dev2  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/29048362.jpg)

7. 同时config、order的控制台console产生了刷新接口相应的日志  

### @RefreshScope 进阶  

上面我们获取远端 git 仓库配置文件都是在 **controller** 中添加注解 ``@RefreshScope`` ，我们也可以专门写一个配置类，独立起来  

1. **order-dev.yml** 添加配置  
> 远端 git 仓库 ``config-repos``  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/98084809.jpg)

2. **order** 新建 **GirlConfig.java**  

```java
@Data
@Component
@ConfigurationProperties("girl")
@RefreshScope
public class GirlConfig {

    private String name;
    private Integer age;
}
```

3. **order** 新建 **GirlController.java**  

```java
@RestController
public class GirlController {

    @Autowired
    private GirlConfig girlConfig;

    @GetMapping("/girl/print")
    public String print() {
        return "name:" + girlConfig.getName() + " age:" + girlConfig.getAge();
    }
}
```

4. **重启 order**  
> 访问<http://localhost:8081/girl/print>  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/94067207.jpg)

## WebHooks  

上面我们改完配置，都是在命令行执行``curl -X POST http://localhost:8888/actuator/bus-refresh``，然后重新自动获取配置。  
我们可以使用**码云**或**github**的WebHooks，当执行push操作后，会自动执行刷新命令。  
 
1. 远端 git 仓库**码云**替换成 **github**  
> 使用码云失败，可能有 bug，github 成功的  

2. 更改``config``中远端 git 地址  
> 换成github的  

3. 内网穿透地址：<http://springcloud.ngrok.xiaomiqiu.cn/>  
> WebHooks 设置链接不能使用 localhost 了，必须使用外网能访问的域名；  
> 可以使用[小米球ngrok](http://ngrok.ciqiuwl.cn/)，能固定域名，而且免费！  
> 映射端口为服务端**config**的8888端口  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/98832397.jpg)

4. 测试访问内网映射地址<http://springcloud.ngrok.xiaomiqiu.cn/order-dev.yml>  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/38848557.jpg)

4. **github** WebHooks 设置  
> 访问地址最后添加``monitor``

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/87396767.jpg)  

5. 重启各服务后，我们修改 github 仓库 ``config-repo``
> 修改 order-dev.yml 中 girl 的 age  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/2934818.jpg)

6. 重新访问客户端 **order**：<http://localhost:8081/girl/print>  
> 此时，不需要执行``curl -X POST http://localhost:8888/actuator/bus-refresh``

![](http://p8hqd7oln.bkt.clouddn.com/18-6-5/65870750.jpg)











  





  
  
  
