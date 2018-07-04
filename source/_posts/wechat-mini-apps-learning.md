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

### 总结  

1. [spring boot 应用发布到 docker 完整版](http://blog.anxpp.com/index.php/archives/1075/)  
2. [阿里云服务器centos7安装nginx](https://www.cnblogs.com/kaid/p/7640723.html)
> 注意：[编译nginx指定ssl模块](https://www.cnblogs.com/saneri/p/5391821.html)  
> 注意：[nginx: [emerg] getpwnam(“www”) failed错误](http://blog.itblood.com/nginx-emerg-getpwnam-www-failed.html)  

3. [阿里云官方文档：nginx安装ssl证书](https://yundun.console.aliyun.com/?spm=5176.2020520001.aliyun_sidebar.20.11f44bd3aPrsJa&p=cas#/cas/download/214817049210895?regionId=)  
4. 
