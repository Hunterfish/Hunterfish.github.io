---
title: Spring Boot微信点餐项目本地运行
date: 2018-05-11 15:10:48
categories: Spring Boot微信点餐项目
tags:
  - 微信
  - 
---

# 准备工作  

本项目我使用的是阿里云服务器，没有使用本地虚拟机，不过基本是一样的  

## 阿里云服务器基本信息  

* CPU： 1核  
* 内存： 2 GB  
* 实例类型： I/O优化  
* 操作系统： CentOS 7.4 64位  

## 环境准备  

* [后端项目地址](https://gitee.com/ddebug/sell.git)  
* [买家端前端地址](https://gitee.com/ddebug/sell_buyer_ui)  
* [微信公众测试账号](https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login)  
* [阿里云安装redis](https://www.ddebug.cn/aliyun-install-redis-summary.html)  
* [阿里云安装mysql](https://www.ddebug.cn/aliyun-install-mysql-summary.html)
* [阿里云搭建私服](https://www.ddebug.cn/aliyun-install-nexus-summary.html)

## 工具  

* IDEA [激活地址](http://idea.lanyus.com/)  
* Xshell  
* [微信Web开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/devtools.html)    
* [小米球ngrok](http://ngrok.ciqiuwl.cn/)  
> 主要是免费，可以固定域名  

# 本地运行  

## 修改配置  

### application.dev.yml  

* mysql  
* redis  
* wechat公众平台测试账号ID和秘钥  
* 支付商户号和开放平台需要企业资质，暂时不测试  
* templatedId: 微信推送消息模板ID  
* projectUrl: 设置自己内网穿透的域名  

### nginx.cnf配置  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/12733950.jpg)
* Server.name  sell.ddebug.cn  
> 我这里由于是阿里云服务器，使用了已经备案过的域名添加解析;  
> 如果本地虚拟机，可以自定义，同时修改主机hosts文件添加解析 

![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/8826006.jpg)
* proxy_pass  http://hunterfish.ngrok.xiaomiqiu.cn  
> 本地后端项目启动后，用nginx代理床头内网生成的域名，是阿里云或虚拟机中的前端项目通过nginx代理调用后端本地启动的接口  

* root  /opt/data/wwwroot/sell  
> 买家端前端项目打包后存放目录  

### 微信测试账号配置  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/21701607.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/3970488.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/80793861.jpg)

## 买家端前端测试  

### 运行测试(有微信测试账号)    

* 启动后端项目  

* 微信web开发者工具中输入：http://sell.ddebug.cn  

* 跳转到微信授权  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/60890277.jpg)

* 同时后台打印了微信授权信息openid  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/74526378.jpg)

* 授权成功，跳转页面    
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/23484113.jpg)

* 同时生成Cookie  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/27750359.jpg)

* 因为支付商户号需要企业资质，所以没有测试  

### 运行测试(没有微信测试账号)  

* 启动后端项目  
* 浏览器中输入并访问： http://sell.ddebug.cn/#/order  
* 浏览器console中手动设置cookie(可以自定义): **document.cookie="openid=abc123"**  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/75375552.jpg)
* 再访问： http://sell.ddebug.cn  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/75947108.jpg)

## 卖家端前端测试  

> 卖家端前端就是卖家管理商品订单分类的后台中心，使用微信开放平台账号的微信扫一扫登陆功能  

> 由于微信开放平台需要企业资质才能申请，所以这里只是自定义设置openid来模拟登陆，实际上代码已经完善，如果你有开放账号，直接修改application.xml  

* 浏览器访问： http://hunterfish.ngrok.xiaomiqiu.cn/sell/  
* console设置cookie(可以自定义): **document.cookie="token=abc123"**  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/19972825.jpg)

* 浏览器访问： http://hunterfish.ngrok.xiaomiqiu.cn/sell/seller/order/list  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-11/53997991.jpg)















