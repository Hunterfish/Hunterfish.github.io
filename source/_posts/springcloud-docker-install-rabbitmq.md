---
title: Spring Cloud 基础篇 (一)：Docker 环境下安装 RabbitMQ
date: 2018-06-06 11:53:32
categories: Spring Cloud微服务实战
tags:
  - Docker
  - RabbitMQ
---
# RabbitMQ   

在Docker中安装RabbitMQ，Docker可以参考[微服务、容器Docker和DevOps](https://www.ddebug.cn/springcloud-docker-devops.html#more)。  

## 下载  

1. [官网下载地址](https://hub.docker.com/_/rabbitmq/)  
2. **注意事项**    
![](http://p8hqd7oln.bkt.clouddn.com/18-5-31/84358853.jpg)

## 安装运行    

1. **docker命令：** 
```bash
docker run -d --hostname my-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:3.7.5-management
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-31/38308950.jpg)

2. **docker ps查看**  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-6/95321892.jpg)

3. 访问管理界面<http://localhost:15672>  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-31/13026009.jpg)

