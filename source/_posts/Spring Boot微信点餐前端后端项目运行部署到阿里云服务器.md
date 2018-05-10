---
title: Spring Boot微信点餐前端后端项目运行部署到阿里云服务器
date: 2018-05-10 09:35:49
categories: Spring Boot微信点餐项目
tags:
  - Vue
  - 阿里云服务器
---

# 后端运行部署  

## 项目介绍  

> Spring Boot项目  

1. 点击[项目地址](https://gitee.com/ddebug/sell.git)下载项目到本地  

## 项目运行  

## 项目部署  


# 前端运行部署  

## 项目介绍  

> Spring Boot微信点餐项目的前端是参考慕课网视频[vue.js高仿饿了么外卖App](https://coding.imooc.com/class/74.html),
我抽取了服务器中前端项目上传到自己的码云上，并修改了部分自己后端项目的配置。  

1. 搭建环境参考博客[]  

2. 点击[项目地址](https://gitee.com/ddebug/sell_buyer_ui)下载项目到本地  

## 项目运行  

> 本地运行  

```jshelllanguage
# 安装依赖
npm install

## 若上述不行则采取下面命令
npm install --registry=https://registry.npm.taobao.org
cnpm install

# 本地开发 开启服务
npm run dev
```

## 项目部署  

### 构建静态文件  

```jshelllanguage
# 构建生成环境
npm run build
```
> 生成dist目录  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/65663777.jpg)

### 上传到阿里云服务器  

1. 参考[如何部署vue前端项目到阿里云服务器上](https://blog.csdn.net/sherry_chan/article/details/79055211)  

2. 参考[nginx+vue.js实现前后端分离](https://blog.csdn.net/qq_26026975/article/details/75331779)

2. copy上节生成的dist目录下的内容上传到云服务指定位置  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/83119425.jpg)

3. 修改nginx配置     

> 修改nginx配置 

```jshelllanguage
vim /etc/nginx/conf.d/default.conf
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/35267061.jpg)

> 由于我用的是阿里云服务器，配置已备案二级域名，并在阿里云控制台配置解析  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/14153152.jpg)

> 如果是本地虚拟机，可以修改本地hosts文件完成映射即可  

> 修改后重启nginx: **nginx -s reload**  





