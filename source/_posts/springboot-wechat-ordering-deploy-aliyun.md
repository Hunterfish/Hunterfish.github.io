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

* 点击[项目地址](https://gitee.com/ddebug/sell.git)下载项目到本地     

* 本地手动下载pom.xml依赖  
```jshelllanguage
call mvn -f pom.xml dependency:copy-dependencies
```

## 项目部署  

> 下面的几种方式其实现在都已经过时了，以后总结docer部署项目的相关知识  

### Tomcat  

> 打好包后，放到tomcat某个目录中，启动tomcat 

### java -jar  

> 推荐使用此java框架方法  

1. 进入项目主目录  

```jshelllanguage
mvn clean package -Dmaven.test.skip=true
```
2. target下jar包  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/70520653.jpg)
> 可以更改jar包名字, 修改pom.xml文件，然后重新执行上面打包命令：  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/74412635.jpg)

3. copy到服务器  
> 可以参考博客[常用CentOS7命令](https://www.ddebug.cn/common-centos7-commands.html)  

4. 运行  
```jshelllanguage
java -jar sell.jar
```

5. 指定端口和运行环境  
```jshelllanguage
java -jar -Dserver.port=8080 -Dspring.profiles.active=prod sell.jar
```

6. 后台运行  

> 启动后，会在sell.jar同目录下生成日志文件  

```jshelllanguage
nohup java -jar sell.jar > /dev/null 2>&1 &
# 停止进程
kill -9 进程数
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/50729385.jpg)

7. 脚本运行  

> 新建文件start.sh  

```jshelllanguage
#!/bin/sh
nohup java -jar sell.jar > /dev/null 2>&1 &
```

> 启动：bash start.sh  

### centos7下可以新建服务service启动  

1. 新建sell.service  

```jshelllanguage
cd /etc/systemd/system
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/83976316.jpg)
2. vim sell.service  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/56882885.jpg)
4. systemctl daemon-reload: 修改文件后，重启配置
3. systemctl start sell：启动服务  
4. systemctl stop sell: 停止服务  
5. systemctl enable sell: 开机启动  
6. systemctl disable sell: 停止开机启动  

## 运行测试  

1. 访问项目接口，成功显示数据   

> URL：http://47.98.***.**:8080/sell/buyer/product/list  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/87579972.jpg)

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
3. copy上节生成的dist目录下的内容上传到云服务指定位置  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/83119425.jpg)

4. 修改nginx配置   

> 修改nginx配置 

```jshelllanguage
vim /etc/nginx/conf.d/default.conf
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/35267061.jpg)

> 由于我用的是阿里云服务器，配置已备案二级域名，并在阿里云控制台配置解析  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/14153152.jpg)

> 如果是本地虚拟机，可以修改本地hosts文件完成映射即可  
> 修改后重启nginx: **nginx -s reload**  





