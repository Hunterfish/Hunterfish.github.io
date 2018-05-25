---
title: WDCP面板+织梦模板构建网站
date: 2018-05-25 16:21:48
categories: 前端
tags:
  - Linux
---

# 前言  

## 需求  

最近公司官网首页要重新编辑，要求可以后台编辑发布公司新闻，在老大帮助下，使用织梦模板来改造一下公司官网。  

## 准备  

### 阿里云linux虚拟机  

> 由于工作上下班电脑来回配置比较麻烦，所以使用云虚拟机来练习，这里注意需要**域名**，如果是本地的话，修改hosts文件就行了  

### WDCP云虚拟机管理面板  

* [官网资料](https://www.wdlinux.cn/wdcp/install.html)   

### 织梦模板  

* [织梦模板网站-源码集合](http://www.ymjihe.com/dedecms)  

# wdcp安装与织梦模板安装  

## 安装  

参考**[WDCP织梦模板安装教程](https://jingyan.baidu.com/article/b87fe19e6cea8d521935684e.html)**链接，进行安装配置。  
> wdcp安装时间有点长，大概20分钟左右。请注意！    

## 访问页面    

### wdcp  

* 登陆地址：``http://your-ip-address:8080/login``

* 登陆界面  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/25606871.jpg)
* 站点列表  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/68981775.jpg)

### 织梦后台  

* 登录地址：``http://xxx.xxx.cn/dede``

* 登陆界面  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/36011085.jpg)

* 首页  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/72384695.jpg)

### 官网首页  

* 登陆地址：wdcp站点域名  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/93943860.jpg)

* 首页效果  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/54238446.jpg)

# 修改模板  

## 修改样式图片  

> 【附件管理】中修改：  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/43868336.jpg)

## 修改网站模板  

> 【模板管理】默认模板管理修改首页头部、尾部、关于、联系等模板  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/49825835.jpg)

## 修改系统参数  

> 织梦模板中统一配置的参数比如网站地址、版权信息、备案号、邮箱、qq、电话、地址等信息  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/56603264.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-25/80849037.jpg)



