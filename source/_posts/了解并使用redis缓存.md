---
title: 了解并使用Redis缓存
date: 2018-05-09 14:39:47
categories: Spring Boot微信点餐项目
tags:
  - Redis
  - 缓存
  - Spring Boot
---

# Redis缓存    

## 介绍  

> 大流量场景环境下，有效提高数据读取速度；  

### 三个特点  

* 命中  
> 用户从cache中获取数据，取到后返回  
* 失效  
> 缓存时间到时  
* 更新  
> 应用程序把数据存到数据库中，再放到缓存中  

##