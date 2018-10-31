---
title: 2018工作项目总结-模仿蒲公英App上传平台
date: 2018-10-25 08:42:18
categories: 工作日志
tags:
  - 总结
  - 面试
---

# 简介  

模仿蒲公英App上传平台。  

## 项目描述  

* 后端基于 ``SpringBoot + tk.mybatis``、前端基于``Vue + Vuex + elementUI``的前后端分离项目；  
* 基于 ``Shiro`` 安全框架的登陆身份认证和权限校验（授权）；  
* 实现前后端分离，通过 ``token`` 进行数据交互。  
* 特点  
```
- 友好的代码结构及注释，便于阅读及二次开发
- 实现前后端分离，通过token进行数据交互，前端再也不用关注后端技术
- 灵活的权限控制，可控制到页面或按钮，满足绝大部分的权限需求
- 页面交互使用Vue2.x，极大的提高了开发效率
- 完善的代码生成机制，可在线生成entity、xml、dao、service、vue、sql代码，减少70%以上的开发任务
- 引入quartz定时任务，可动态完成任务的添加、修改、删除、暂停、恢复及日志查看等功能
- 引入API模板，根据token作为登录令牌，极大的方便了APP接口开发
- 引入Hibernate Validator校验框架，轻松实现后端校验
- 引入云存储服务，已支持：七牛云、阿里云、腾讯云等
```

## 技术选型  

```
- 核心框架：Spring Boot 2.0
- 安全框架：Apache Shiro 1.4
- 视图框架：Spring MVC 5.0
- 持久层框架：MyBatis 3.3
- 定时器：Quartz 2.3
- 数据库连接池：Druid 1.0
- 日志管理：SLF4J 1.7、Log4j
- 页面交互：Vue2.x  
```

## 项目主要模块  

1. 结合七牛云的文件上传  

2. QQ、Github第三方登录  

3. 支付宝PC端网页支付、微信扫码支付  

4. 邮箱发送注册  


### 七牛云文件上传    



### QQ第三方登陆  

1. 申请地址: [QQ互联](https://connect.qq.com/index.html)  
2. 需要审核成为**开发者**才能创建应用  
3. 本地测试中，网站应用或移动该应用可以不用审核成功，但只能本人qq登陆自己网站。  

![](http://p8hqd7oln.bkt.clouddn.com/18-9-30/71077275.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-9-30/23390421.jpg)

### Github第三方登陆  

![](http://p8hqd7oln.bkt.clouddn.com/18-9-30/17124559.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-9-30/95558268.jpg)

### 支付宝PC端支付  

1. 微信/支付宝异步回调域名设置  

> 如果没有域名，可以内网穿透，推荐免费工具：[小米球](http://ngrok.ciqiuwl.cn/)

```yaml
pay:
  web-url: http://app.ngrok.xiaomiqiu.cn
```

2. 支付宝设置同步回调地址  

> 支付成功后，跳转页面，正式环境切换域名  
```yaml
alipay:
    return_url: http://localhost:8080/#/index # 支付宝支付成功后前端跳转地址（非必填）
```


### 微信扫码支付  

### 发送邮件  

* 使用SpringBoot自带的 ``JavaMailSender``  
* 参考博客[Spring Boot中使用JavaMailSender发送邮件](http://blog.didispace.com/springbootmailsender/)  

* ``application.yml`` 配置文件:  

```yaml
spring:
    mail:
        default-encoding: UTF-8
        host: smtp.163.com
        username: ***@163.com
        password: *********
# 设置常用参数
custom:
  email:
      # 邮箱配置
      from-email: *****@163.com
      # 验证码信息模板
      codeTemplate: "您的验证码是: #code"
      # 每日最大发送条数
      sendMaxCount: 30
      # 验证错误次数限制
      errorMaxCount: 3
      # 验证码过期时间 单位秒
      expireTime: 300
```