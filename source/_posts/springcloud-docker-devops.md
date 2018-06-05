---
title: Spring Cloud 实战 (八)：微服务、容器Docker和DevOps
date: 2018-05-30 13:53:03
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Docker
  - DevOps
---
# 前言  

## 微服务和容器：天生一对  

1. 使用容器从系统环境开始，自底至上打包应用  
> 解决了程序应用在我的环境中正常，在你的环境里就异常了  

2. docker轻量级，对资源的有效隔离和管理，符合微服务理念  
> 做到进程隔离，资源管理  

3. 可复用，版本化  
> 通过Docker镜像交付环境，利用强大的tag机制指定镜像版本，这样就可以版本化整个微服务环境  

## Microservice/Docker/Devops  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-31/14118347.jpg)

> 微服务之前产生的交互相当复杂，服务拆分过后，每个服务都要独立部署，简而言之，就是可以随时随地升级服务版本；  

> 因此**自动化运维**提升交互速度才是真正玩转微服务重要环节；  

> 微服务、Docker、Devops相辅相成，微服务架构是核心，Docker、Devops是工具、手段！！  

# Docker  

## Docker安装

[安装地址](https://www.docker.com/community-edition)  

### Linux阿里云  

#### 阿里云服务器参数  

* CPU： 1核  
* 内存： 2 GB  
* 实例类型： I/O优化  
* 操作系统： CentOS 7.4 64位  

#### 安装  

参考[从零开始学习 Docker](https://segmentfault.com/a/1190000012924580)  
  
> 使用阿里云官方文档[安装Docker](https://help.aliyun.com/document_detail/60742.html?spm=5176.11065259.1996646101.searchclickresult.3335232c6fvZbt)  
  
> 注意一定要安装**阿里云加速器**。  


### Windows  

> 尽量不要再Windows环境下学习使用！！  

> 参考上面安装连接，下载windows版本，目前docker只支持win10；  

> 注意配置Docker镜像加速器。  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-31/51997639.jpg)

## Docker学习  

参考[阮一峰 Docker入门教程](http://www.ruanyifeng.com/blog/2018/02/docker-tutorial.html)  




