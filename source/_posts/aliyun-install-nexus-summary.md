---
title: 阿里云服务器搭建Maven nexus私服
date: 2018-04-29 13:12:36
categories: 阿里云服务器
tags: 
  - Maven
  - JDK
  - Nexus3
  - Linux
  - 阿里云服务器
---

# 在阿里云服务器上搭建Maven私服  

## 服务器具体信息   

* CPU： 1核 
* 内存： 2 GB 
* 实例类型： I/O优化 
* 操作系统： CentOS 7.4 64位  

## 安装流程  

### git安装  

参考链接：<https://www.cnblogs.com/boxuan/articles/6434109.html>  

> 执行``make configure``等命令时，会报错，缺少包，百度搜一下安装即可。  

### JDK安装  

参考链接：<https://blog.csdn.net/fuyuwei2015/article/details/73195936>  

### Maven安装  

参考链接：<https://www.cnblogs.com/HendSame-JMZ/p/6122188.html>  

* /etc/profile修改为：  

```properties
#set for nodejs  
export NODE_HOME=/usr/local/node  
#export PATH=$NODE_HOME/bin:$PATH
export JAVA_HOME=/usr/local/java/jdk1.8.0_171
#export JRE_HOME=${JAVA_HOME}/jre
#export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export MAVEN_HOME=/usr/local/maven
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$MAVEN_HOME/bin:$NODE_HOME/bin:$PATH
```  

### 搭建私服  

参考链接：<https://juejin.im/entry/59e1cea8f265da43163c1990>  

