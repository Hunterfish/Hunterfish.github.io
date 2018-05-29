---
title: 阿里云服务器安装mysql总结
date: 2018-04-27 14:37:52
categories: 阿里云服务器
tags: 
  - MySQL
  - Linux
  - 阿里云服务器
---
# 阿里云服务器安装mysql总结  

## 服务器具体信息  

* CPU： 1核 
* 内存： 2 GB 
* 实例类型： I/O优化 
* 操作系统： CentOS 7.4 64位  

## mysql版本  

> mysql  Ver 14.14 Distrib 5.6.40, for Linux (x86_64) using  EditLine wrapper  

## 安装流程  

参考资料：<https://yq.aliyun.com/articles/47237>  

* 卸载原来mysql  
* 安装流程  
* 开机启动  
* 防火墙设置  
* MySql安全设置  
* 远程访问设置  
* utf8字符集设置  
* 备份还原  

## mysql 用户设置  

* root用户禁止远程访问   密码：L***1!
* 普通用户：hunterfish 密码：1****0
* 管理员用户：admin 密码：1****9

## 遇到的问题  

### mysql5.7初始化密码问题  

按照上面参考链接教程安装，如果是mysql5.7的话，使用mysql访问会出现下面错误：  

```xml
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
```
这是因为mysql从5.6开始后，安装初始化密码就不为空了，下面更改密码：  

1. 查看初始化密码  

```xml
grep 'temporary password' /var/log/mysqld.log
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-29/90859158.jpg)

2. 更改初始化密码  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-29/85681101.jpg)

### 3306端口  

顺利执行上面参考链接的安装流程后，在本地远程连接阿里云mysql数据库时（防火墙已经开放了3306d端口），遇到：

> can't connect to mysql server on 10060  
  
原因是阿里云服务器设置了安全组规则，只允许22和3389端口开放，所以新增3306安全组规则：  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/4855161.jpg)

参考资料：<https://blog.csdn.net/u010955892/article/details/72774920>
