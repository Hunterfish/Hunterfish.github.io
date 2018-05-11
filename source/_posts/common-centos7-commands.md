---
title: 常用CentOS7命令
date: 2018-04-29 13:41:11
categories: Linux
tags:
   - CentOS7
---

# 常用但不好记命令  

## 开放防火墙端口  

* 开放相应端口  

```java
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --permanent --zone=public --add-port=3306/udp 
```  
* 重启使修改的防火墙规则生效  

```java
firewall-cmd --reload  
```  

## 查看进程和端口监听  

* 检查后台进程是否正在运行  

```java
ps -ef | grep redis  
```  

* 检测端口是否在监听  

```java
netstat -lntp | grep 6379
```

## 远程连接服务器发送文件  

### 通过工具  

> 这种比较简单，可以通过putty,xshell等连接，通过xfpt发送文件  

### 通过命令行  
* **ssh username@ip.address**：连接
> 通过命令行远程连接linux服务器  
```jshelllanguage
ssh root@47.98.xxx.xx
```
* **scp**：copy文件  
> 参考[scp命令在linux和windows之间互传文件](https://blog.csdn.net/jyf0412/article/details/36866041)  
```jshelllanguage
scp target\sell.jar root@47.98.113.88:/opt/javaapps
```




