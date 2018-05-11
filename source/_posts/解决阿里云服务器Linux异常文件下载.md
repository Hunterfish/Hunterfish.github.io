---
title: 解决阿里云服务器Linux异常文件下载
date: 2018-05-11 13:16:05
categories: 阿里云服务器
tags: 
  - Linux
  - 阿里云服务器
---

# 阿里云服务器参数  

* CPU： 1核 
* 内存： 2 GB 
* 实例类型： I/O优化 
* 操作系统： CentOS 7.4 64位  

# 异常情况  

* 进程异常行为-Linux异常文件下载  
* 谷歌后，应该是通过redis获取了root权限，上传了病毒  
* 会大量占用cpu资源，造成服务器卡顿  

![](1)  

# 解决方法  

> 参考[博客1](https://blog.csdn.net/yucdsn/article/details/79847869), [博客2](https://www.cnblogs.com/killall007/p/8877294.html)  