---
title: Spring Cloud 实战 (六)：Spring Boot多模块化
date: 2018-05-28 13:09:23
categories: Spring Cloud微服务实战
tags:
  - Spring Boot
  - Spring Cloud
---

# spring Boot 多模块  

## 前言  

去总公司参加推介会，无聊没事做，又因为总公司电脑配置垃圾，环境都没有配置，所以谢谢博客！ 
最近学习sprincloud微服务实战，过程需要spring boot项目多模块化，趁机总结一波！  

参考慕课网免费视频： [Spring Boot多模块构建项目](https://www.imooc.com/video/16354)  

## 为什么  

在传统的项目主结构中，我们的java代码由于不同的模块执行不同的职责，在这种情形下我们讲  
这些模块拆分成更小的单元，并赋予单独的使命。  

## 如何做  

本质上还是利用maven的特性：模块化！  

### 重构   

1. 调整主（父）工程类型（<packaging>）  
> 一开始项目是单独的**jar**工程，包含了代码和依赖，打包形式是jar形式，我们要更改为聚合工程**pom**形式。  

2. 创建子模块工程（<module>）  
* 模型层： model(实体类)  
* 持久层： persistence (dao层)  
* 表示层： web  (controller)  

3. 子模块依赖管理（<dependencyManagement>）  
> 调整模块之间的依赖关系：模型层model是工程最底层的子模块，被持久层和web层双依赖。  

## 实战拆分  

### 修改成pom聚合工程  

* pom.xml  
```xml
    <groupId>cn.hunter</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>

    <!-- 修改成 pom 聚合工程 -->
    <packaging>pom</packaging>
```
### 构建表示层web  

1. 新建module   
> 新建时，可以不用选择具体类型   

![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/72119483.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/23020680.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/84235608.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/56915207.jpg)
2. 项目结构图   
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/14455286.jpg)  

3. 主工程pom.xml文件变化   
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/67854836.jpg)

4. 主工程代码移动到相应子模块中   
> 移动成功后，可以删除掉主工程的src目录了   
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/9615337.jpg)

### 构建 persistence 和 model 子模块  

参考构建web子模块！！  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/71295242.jpg)

### 解决子模块之间的依赖  

> web依赖于persistentce，persistence依赖于model   

1. 修改 persistence pom.xml文件  
```xml
<dependencies>
    <!-- persistence 增加 model 子模块依赖 -->
    <dependency>
        <groupId>cn.hunter</groupId>
        <artifactId>model</artifactId>
        <version>0.0.1-SNAPSHOT</version>
    </dependency>
</dependencies>
```

2. 修改 web pom.xml文件   
```xml
<dependencies>
    <!-- web 依赖于 persistence -->
    <!-- persistence 依赖于 model -->
    <!-- web 增加 persistence 子模块依赖 -->
    <dependency>
        <groupId>cn.hunter</groupId>
        <artifactId>persistence</artifactId>
        <version>0.0.1-SNAPSHOT</version>
    </dependency>
</dependencies>
```

### 测试   
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/38972138.jpg)

# 项目打包  

## 打包方式   

* **jar包**   
* **war包**   

### jar包  

1. 主工程pom.xml文件添加启动类配置：  
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <!-- 添加启动类配置，否则打包时提示找不到-->
            <configuration>
                <mainClass>cn.hunter.DemoApplication</mainClass>
            </configuration>
        </plugin>
    </plugins>
</build>
```

2. 上面的**build配置信息**放到web子模块的pom.xml中   
> 因为web子模块已经成为了主模块，拥有启动类**DemoApplication.java**  

3. 安装依赖子模块的jar包到本地maven仓库   

```java
mvn -Dmaven.test.skip=true -U clean install
```

4. 构建打包命令：  
> -u: 更新第三方包   

```java
mvn -Dmaven.test.skip -u clean package
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/41532244.jpg)

4. jar包启动命令：  

```xml
java -jar xxx.jar
```


### war包   

1. packaging值调整成war  
> web子模块pom.xml文件中，packaging值默认为**jar**   

![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/67423211.jpg)

2. web模块新增webapp/WEB-INF/web.xml   
> war包maven标准目录  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/18227634.jpg)


3. 打包命令：  
> 和jar一样  

```java
mvn -Dmaven.test.skip -u clean package
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-26/21019712.jpg)

4. war包启动命令   
> 在spring boot中，war包可以和jar包一样，通过下面命令行作为可执行jar包使用；  
> 放在tomcat、jetty容器中运行  

```xml
java -jar xxx.war
```

# Spring Boot运行方式   

* **IDEA方式**    
* **JAR/WAR 方式**   
* **Maven插件方式**   

> 如果你是开发环境，会使用Idea方式；   
> 如果你是在线上生产环境，会使用Jar/war方式（脚本命令运行）；   
> 如果你是开发环境，同时没有图形化操作界面，可以使用Maven插件方式。  

## 启动过程   

1. 安装persistence、model子模块依赖   
> 在工程主目录下  

```java
mvn -Dmaven.test.skip -u clean install
```

* 启动工程   
> 在web子模块目录下   

```java
mvn spring-boot:run
```

# Spring Cloud点餐项目多模块化  

> 重点是暴露远程服务的接口定义在客户端Product，比如Order服务调用Product服务的查询商品、减库存服务。  
> 这么做的好处是，自己定义的接口，暴露出去给别人用，便于使用和修改，如果后面还有支付系统需要使用Product的服务，不需要重新再支付系统中再写一遍了！！  

## Product服务  

### 多模块化分析  

* **product-server**： 所有业务逻辑  
* **product-clent**： 对外暴露的接口  
* **product-common**： 公用的对象（被外部服务调用，也会被内部其他模块使用）  

### 多模块依赖关系  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/51260546.jpg)

### 效果  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/84154162.jpg)

## Order服务  

和Product服务一样，不在分析  

## 注意事项  

### server子模块   

**ProductApplication.java**、**OrderApplication.java**要放在**server**子模块中！！  

1. 启动类  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/6652656.jpg)

2. server.pom  
> **build**配置文件从主项目中移到server.pom中  

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

### 引入依赖子模块common  

> product-common子模块被内部其他模块**product-client**使用;  
> 也可能被外部服务**order**的内部子模块**order-server**使用； 

1. 首先在**product**、**order**主pom.xml文件中引入：  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/82243249.jpg)

2. 内部模块**product-client**使用：  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/75110005.jpg)

3. 外部项目服务**order**使用：  

> 和内部使用一样，但首先把**product**子模块**client**、**common**安装到本地仓库  
```jshelllanguage
mvn -Dmaven.skip.test=true -U clean install
```








