---
title: Spring Cloud 基础篇 (二)：Docker 环境下安装 Redis
date: 2018-06-07 10:19:57
categories: Spring Cloud微服务实战
tags:
  - Docker
  - Redis
---
# Redis  
在Docker中安装Redis，Docker可以参考[微服务、容器Docker和DevOps](https://www.ddebug.cn/springcloud-docker-devops.html#more)。  

## 下载   
1. [Docker版本官网下载地址](https://hub.docker.com/_/redis/)   

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/22499339.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/86926513.jpg)

## 安装运行    

1. **docker命令：**   

```bash
docker run -d -p 6379:6379 redis:4.0.8
```
![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/10579186.jpg)
