---
title: 微信小程序学习总结
date: 2018-06-13 13:28:28
categories:
  - 微信小程序学习实战
tags:
  - 微信小程序
---

# 前言

参考资料：[https://www.cnblogs.com/xuanbiyijue/p/7980010.html](https://www.cnblogs.com/xuanbiyijue/p/7980010.html)  

知乎精选：[如何入门微信小程序开发](https://www.zhihu.com/question/50907897)  

[微信小程序开发资源汇总](https://github.com/justjavac/awesome-wechat-weapp)  

[微信小程序使用有坑记录](https://github.com/senola/wechat-app-issues)

## github项目  

1. [litemall【Spring Boot后端 + Vue管理员前端 + 微信小程序用户前端】](https://github.com/linlinjava/litemall)   
> 该项目有非常完善的开发部署文档：<https://linlinjava.gitbook.io/litemall>    

2. [计生计](https://github.com/ximolang/mp-jishengji)  

3. [Muse-UI](https://muse-ui.org/#/zh-CN/button)  

## wepy：微信小程序组件开发框架  

1. github地址：[wepy](https://github.com/Tencent/wepy)  
2. 组件汇总：[awesome-wepy](https://github.com/aben1188/awesome-wepy)  
3. [省份/城市/区县定位选择器](https://gitee.com/qfr_bz/citySelector)  
4. [微信小程序-极点日历](https://github.com/czcaiwj/calendar)  
5. [微信原始小程序组件-minui](https://github.com/meili/minui)  

## mpvue：美团小程序开发框架  

1. github地址：[mpvue](https://github.com/Meituan-Dianping/mpvue)

## 视频教程  

1. [SpringBoot+MyBatis搭建迷你小程序](https://www.imooc.com/learn/945)  

## 实现功能  

日历上能够显示不同颜色，不同颜色代表你坚持的不同的事情。 
### 项目名称  
1. you can you up
2. you will,you mast


### 首页

显示本月日历，每天日期上会有颜色区块！  

1. 红色：一段时间内，你每天是否跑步；  
2. 蓝色：剪头；  
3. 黄色：看电影；  
4. 绿色：发工资；

### 类别统计页  

1. 统计你自定义的事情的列表/柱形图等；  
2. .....待续  

## 使用组件  

1. [微信小程序-极点日历](https://github.com/czcaiwj/calendar)  
2. [轮播图：we-swiper](https://github.com/we-plugin/we-swiper)  
3. [第三方UI组件库](https://github.com/TalkingData/iview-weapp)  
4. [首页特效](http://www.wxapp-union.com/forum.php?mod=viewthread&tid=4628) 
5. [首页特效](https://github.com/qindiandadudu/TianguoguoXiaopu)
6. [悬浮按钮-wux](https://github.com/skyvow/wux)  
7. [promise](https://github.com/bigmeow/minapp-api-promise)
# 初步了解小程序  

通过上面视频教程，初步学习小程序前后台搭建。  

## 实现功能    

1. **后端：Spring Boot + Mybatis 框架**  

2. **实现后端业务功能**  

3. **前端：本地微信小程序**  

4. **前端和后端联调**  

## 域名证书  

* [SpringBoot微服务的https配置方法（即微信小程序后台服务搭建解决方案）](https://blog.csdn.net/Colton_Null/article/details/78266810)  

## spring后台部署  

* [Docker(四)：Docker 三剑客之 Docker Compose](http://www.ityouknow.com/docker/2018/03/22/docker-compose.html)  
* [Spring Boot 2.0(六)：使用 Docker 部署 Spring Boot 开源软件云收藏](http://www.ityouknow.com/springboot/2018/04/02/docker-favorites.html)  
* [利用docker nginx,redis,mysql部署springboot应用集群环境](https://blog.csdn.net/jzd1997/article/details/79315919)

* [spring cloud 与 docker-compose构建微服务](https://blog.csdn.net/u012734441/article/details/77832797)

## 总结  

1. [spring boot 应用发布到 docker 完整版](http://blog.anxpp.com/index.php/archives/1075/)  
2. [阿里云服务器centos7安装nginx](https://www.cnblogs.com/kaid/p/7640723.html)
> 注意：[编译nginx指定ssl模块](https://www.cnblogs.com/saneri/p/5391821.html)  
> 注意：[nginx: [emerg] getpwnam(“www”) failed错误](http://blog.itblood.com/nginx-emerg-getpwnam-www-failed.html)  

3. [阿里云官方文档：nginx安装ssl证书](https://yundun.console.aliyun.com/?spm=5176.2020520001.aliyun_sidebar.20.11f44bd3aPrsJa&p=cas#/cas/download/214817049210895?regionId=)  
4.

## mysql数据库备份

参考：[CentOS 7 MySQL自动备份shell脚本](https://www.jianshu.com/p/746db5ceec02)

# 部署流程  

## 部署环境  

* 阿里云服务器【centos 7】  

## 部署配置

### 配置Docker Remote API

参考：[spring boot 应用发布到 docker 完整版](http://blog.anxpp.com/index.php/archives/1075/)

1. pom.xml文件
> 添加``docker-maven-plugin``，使用Docker Remote API 进行远程提交镜像的。  

#### 部署遇到问题  

1. 配置Docker Remote API  
> 不用增加 ``Docker Hub`` 镜像地址，否则会报错；  

2. 修改上述配置文件后，使用下面命令重启；  
> ``systemctl daemon-reload``  

3. 由于项目架构为SpringBoot的多模块，在子模块中运行下面命令即可：  
> ``mvn clean package docker:build``  



## 操作流程  

1. 项目根目录：

```java
mvn clean install -Dmaven.test.skip=true
```

2. calendar-wx-api目录下：
> 执行下面命令后，生成docker镜像，会推送到阿里云服务器

```java
mvn clean package -Dmaven.test.skip=true docker:build
```
![](http://p8hqd7oln.bkt.clouddn.com/18-7-8/91690899.jpg)


3. 阿里云服务器启动docker服务【如果未启动】

```java
systemctl start docker
```

4. 下载Docker Java8 运行环境镜像
> ```frolvlad/alpine-oraclejdk8```，最受欢迎

```java
docker pull frolvlad/alpine-oraclejdk8
```

5. 阿里云服务器运行docker容器  
> -d：让容器后台运行  
> -p：将容器内的端口映射到docker所在系统的端口  
> -t：打开一个伪终端，以便后续可以进入查看控制台 log

```java
docker run -p 443:443 -t calendar/calendar-wx-api
```

6. 查看docker运行情况  

![](http://p8hqd7oln.bkt.clouddn.com/18-7-8/91319982.jpg)

7. 查看docker镜像日志：  
> –since : 此参数指定了输出日志开始日期，即只输出指定日期之后的日志。  
> -f : 表示查看实时日志   
> -t : 查看日志产生的日期   
> -tail=200 : 查看最后的200条日志。   
> sleepy_snyder 容器的名称，并不是镜像的名字

```java
docker logs -f -t --since="2018-07-08" --tail=20 sleepy_tesla
```
![](http://p8hqd7oln.bkt.clouddn.com/18-7-8/21393208.jpg)
 
8. 删除容器和镜像  
> docker rmi [name]：删除镜像  
> docker rm [name]：删除容器  

![](http://p8hqd7oln.bkt.clouddn.com/18-7-8/18055543.jpg)


