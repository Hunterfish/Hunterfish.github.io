---
title: 分布式系统和分布式session
date: 2018-05-02 15:38:42
categories: 分布式
tags:
  - 分布式
  - session
---
# 分布式系统  

## 介绍  

> 旨在支持应用程序和服务的开发，可以利用物理架构由多个自治的处理元素；
> 不共享主内存，但通过网络发送消息合作。

###  三个特点  

* 多节点  
* 消息通信  
* 不共享内存  

### 三个概念  

* 分布式系统（distributed system） 
* 集群（cluster）  
* 分布式计算（distributed computing）  

> 关于分布式和集群可以这样理解：一个厨房有炒菜的和洗菜的，这就是分布式；如果炒菜的有多个，这就是集群。    

# 分布式session  

## session  

> 这里我们所说的session是广义的session，就是平常所说的**会话控制**  

* http协议是无状态的，对于一个URL请求并没有上下文关系，当用户完成登陆后，需要有一个机制能够保存用户的信息
和状态，在后续的请求中能够验证用户的身份和检查用户的信息，这个依赖就是会话控制即SESSION。  

* 可以把session理解为一种保存key-value的机制；session机制的关键点：
> 第一：设置和获取key;  
> 第二：如何保存并正确获取对应的value。  

* 从key方面来看，常用的会话方式有**sessionId**和**token**；  

* 不管是sessionId还是token都是全局唯一性的，无论是key还是value，如果没有唯一性，就会分辨不出用户身份和信息；  

* 当我们依赖sessionId时，如果用户禁用了Cookie，那么系统就会让用户不断的去登陆；  

* key对应的value什么情况下有可能不唯一呢，这就是引出了分布式系统下的session问题了？  

### sessionId  

* 客户端请求服务端时，服务端通过setCookie在http请求头中设置key：JSESSIONID和对应的value值；  

![图片](/images/sessionId.png)  

* 客户端Cookie会保存在本地，后续的请求都会自动带上  

### token  

* 使用token时，我们需要手动在http head头或者url请求中设置token字段，服务器收到请求后，
再从head头里或url请求中获取token验证用户身份。  

* 当安全比较严格时，会结合签名一起使用。  

##  分布式系统下的session   

### 应用最开始的架构  

* 用户请求通过nginx到达tomcat，tomcat部署了一个应用，此时，session保存在tomcat应用的内存中，  

![图片](/images/session1.png)  

* 后来用户使用人数激增，一个tomcat扛不住了，然后增加机器，部署多个Tomcat；  

> 水平扩展：A2、A3都是通过A1复制的，也就是平常说的集群； 
 
> 垂直扩展：比如tomcat的应用中有订单、商家、商品三个服务，拆分出来，然后在三个tomcat上单独部署这三个
服务；  

> 接着配置nginx，通过访问不同的url访问不同的负载均衡到不同的服务器上去，减轻单台服务器压力。

![图片](/images/session2.png)  

* 无论是水平扩展还是垂直拆分扩展，都会引出session的问题：  
> 1，比如用户第一次进来访问的是A1服务器，此时A1持有用户的session；  
> 2，当用户第二次请求时，由用户负载均衡，有可能访问A2或A3，A2或A3并没有用户的session信息，就会认为该用户没有登陆；    
> 3，对于水平扩展，ip_hash可以让同一ip过来的请求发送到后台同一台服务器中，问题：如果很多用户的ip都映射到A1服务器，
如果某一时刻，A1宕机挂掉，之前都访问A1服务器的用户都访问不到我们的服务了；  
> 4，垂直扩展更没戏了，所以不推荐使用ip_hash。  

### 通用方案  

* 创建单独的服务保存session信息，其他的服务都从该服务获取session信息；  、
* 通常用Redis集群或主从复制实现；  
![图片](/images/session3.png)
* 这样无论是集群还是分布式服务都能从该服务中根据用户id获取唯一的session信息了；  
> 登陆：设置key，保存value（sesion信息）；  
> 登出：使该session信息失效。  

# 分布式session实战  

> 新建spring boot项目，[点击访问项目地址](https://gitee.com/ddebug/session)  
> 功能：实现卖家端微信扫码登陆功能。  

## 微信公众平台测试账号  

> 参考链接：<https://blog.csdn.net/antma/article/details/79629584>  

> 有关代码基本上和上面参考链接一样，部分需要修改！  

* 微信服务验证接口  



## sql语句<MySql>    

```sql
-- 用户(登录后台使用, 用户登录可直接采用微信扫码登录，不使用账号密码)
create table `seller_info` (
    `id` varchar(32) not null,
    `username` varchar(32) not null,
    `password` varchar(32) not null,
    `openid` varchar(64) not null comment '微信openid',
    `create_time` timestamp not null default current_timestamp comment '创建时间',
    `update_time` timestamp not null default current_timestamp on update current_timestamp comment '修改时间',
    primary key (`id`)
) comment '用户信息表';
```

## 后台代码  

* pom.xml  

> 新增mysql、jpa、lombok、weixin-java-mp、thymeleaf依赖  
```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
</dependency>

<dependency>
    <groupId>com.github.binarywang</groupId>
    <artifactId>weixin-java-mp</artifactId>
    <version>2.7.0</version>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

* 实体类  

```java
@Data
@Entity
public class UserInfo {

    @Id
    private String sellerId;
    private String username;
    private String password;
    private String openid;
}
```

* Dao层  

```java
public interface UserInfoRepository extends JpaRepository<UserInfo, String> {

    /**
     * 根据openId查询用户信息
     */
    UserInfo findByOpenid(String openid);
}
```

* Service层  

```java
public interface UserInfoService {

    /**
     * 根据openid查询用户信息
     * @param openid
     * @return
     */
    UserInfo findUserInfoByOpenid(String openid);
}
```

```java
public class UserInfoServiceImpl implements UserInfoService {

    @Autowired
    private UserInfoRepository userInfoRepository;

    @Override
    public UserInfo findUserInfoByOpenid(String openid) {
        return null;
    }
}

```

* 

* controller层  

```java

```

## 微信授权登陆  




