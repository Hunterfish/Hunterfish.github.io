---
title: Spring Cloud 实战 (十五)：Docker容器部署
date: 2018-06-18 14:05:25
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Docker
---
# 简单上手  

## 运行 Eureka  

1. 下载并启动 **8761** 端口的``Eureka``   
> ```hub.c.163.com```：网易镜像中心。  

```java
docker run -p 8761:8761 -d hub.c.163.com/springcloud/eureka
```

2. 下载并启动 **18761** 端口的``Eureka``   

```java
docker run -p 18761:8761 -d hub.c.163.com/springcloud/eureka
```

# 点餐项目 Docker 容器部署  

## 构建镜像  

### eureka 项目

1. **Dockerfile**  

