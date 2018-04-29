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
