---
title: 阿里云服务器安装redis总结
date: 2018-05-01 15:18:20
categories: 阿里云服务器
tags:
  - linux
  - redis
---

# 在阿里云服务器上安装Redis数据库  

## 服务器具体信息  

* CPU： 1核 
* 内存： 2 GB 
* 实例类型： I/O优化 
* 操作系统： CentOS 7.4 64位  

## mysql版本  

> redis-4.0.9  

## 安装流程  

参考链接：<https://blog.csdn.net/mlks_2008/article/details/19001595>  

## 注意事项  

* 参考链接里的init脚本头部添加下面内容：  

```properties
#!/bin/sh
# chkconfig: 2345 90 10
# description: Redis is a persistent key-value database
```  
* redis配置认证密码  

redis配置文件/etc/redis.conf，去掉下面的注释，修改你自己的密码，重启完成

```java
requirepass footbared  
```   

* 配置外网访问  

redis3.0 以上的版本默认启用了安全机制较高的防护模式（protected-mode）。  

redis2.x 只需要 bind 0.0.0.0，并开放防火墙端口即可外网访问；而redis3.x版本需要在此基础上禁用防护模式。  

```java
# redis-cli // 进入redis命令行模式  
xxxx:6379> CONFIG SET protected-mode no // 禁用防护模式 
```  

