---
title: 2018工作项目总结-liang多多商城后台
date: 2018-10-25 08:42:18
categories: 工作日志
tags:
  - 总结
  - 面试
---

# 简介  

liang多多商城后台微服务项目介绍。  

## 架构摘要    

### SpringCloud  

* ``Spirng Cloud`` 版本``Edgware.SR3``，``Spring Boot``版本``1.5.13``。  
> `Spring Cloud` 是一个基于`Spring Boot`实现的云应用开发工具，它为基于JVM的云应用开发中的配置管理、服务发现、断路器、智能路由、微代理、控制总线、全局锁、决策竞选、分布式会话和集群状态管理等操作提供了一种简单的开发方式。  

### 认证与鉴权  

> 基于 `OAuht2` 方案实现对于请求或登陆的用户身份的认证和合法性鉴权。  

### 负载均衡  

> 将服务保留的rest进行代理和网关控制，除了平常经常使用的`node.js`、`nginx`外，`Spring Cloud`系列的`zuul`和`ribbon`，可以帮我们进行正常的网关管控和负载均衡。  

### 服务注册与调用  

> 基于`Eureka`来实现的服务注册与调用，在`Spring Cloud`中使用`Feign`, 我们可以做到使用HTTP请求远程服务时能与调用本地方法一样的编码体验，开发者完全感知不到这是远程方法，更感知不到这是个HTTP请求。  

### 熔断机制  

> 因为采取了服务的分布，为了避免服务之间的调用“雪崩”，采用了`Hystrix`的作为熔断器，避免了服务之间的“雪崩”。  

## 项目模块说明  

名称 | 说明 |
:---------------|:---------------
gateway   		| 网关路由
eureka-server		| 服务注册发现中心
config-server		| 配置服务中心
auth-service 		| 登录认证授权
user-service 		| 用户微服务
supplier-service	| 直供商城微服务
life-service 		| 本地生活微服务
pay-service  		| 充值(聚合支付)微服务
red-service  		| 红包微服务
msg-service  		| 消息推送短信微服务
game-service 		| 游戏微服务
live-service		| 直播微服务
admin-service 	| 后台管理服务


## 重点技术    

### auth-service 登录认证授权  

#### 介绍  

> 随着 Restful API、微服务的兴起，基于Token的认证现在已经越来越普遍。  
> Token和Session ID 不同，并非只是一个 key。Token 一般会包含用户的相关信息，通过验证 Token 就可以完成身份校验。用户输入登录信息，发送到身份认证服务进行认证。AuthorizationServer验证登录信息是否正确，返回用户基础信息、权限范围、有效时间等信息，客户端存储接口。用户将 Token 放在 HTTP 请求头中，发起相关 API 调用。被调用的微服务，验证Token。ResourceServer返回相关资源和数据。  

#### 模块主要功能

> - 用户登录认证授权  
> - 微服务资源权限  
> - 第三方登录认证封装  

#### Oauth2.0 登录模式   

1. `authorization_code` — 授权码模式(即先登录获取code,再获取token)  
2. `password` — 密码模式(将用户名,密码传过去,直接获取token)  
3. `client_credentials` — 客户端模式(无用户,用户向客户端注册,然后客户端以自己的名义向’服务端’获取资源)  
4. `implicit` — 简化模式(在redirect_uri 的Hash传递token; Auth客户端运行在浏览器中,如JS,Flash)  
5. `refresh_token` — 刷新access_token  

#### 测试流程  

1. 登陆请求  

```java
http://127.0.0.1:8084/oauth/token?username=账号&password=密码&grant_type=password
```
* 参数说明

|   参数名称   |   说明  | 例子 |
|:-------:|:-------:|:------:|
|username |用户账号|18600000000|
|password |用户密码|123456|
|grant_type |登录模式|password|

|   Header   |   Value  |
|:-------:|:-------:|
|Authorization |Basic 加密后的secret|

* 返回结果  

```json
{
    "access_token": "afa127f9-aed6-4430-9f53-bb3cfe1e4abd",
    "token_type": "bearer",
    "refresh_token": "3a7af11a-bdad-48d6-8b52-3ca5ed6cc955",
    "expires_in": 7199,
    "scope": "api"
}
```

> `access_token` 就是用户认证的令牌   

携带令牌请求其他接口时写在Header中格式

|   Header   |   Value  |
|:-------|:-------|
|Authorization |Bearer afa127f9-aed6-4430-9f53-bb3cfe1e4abd|

#### 第三方登录认证封装  

> 第三方登陆不管是那种方式，原理基本上都是基于OAuth的  
> 主要两点：向第三方登陆的认证服务器获取token，向资源服务器获取第三方的用户信息。  

1. 需求描述  

> 用户可使用**支付宝**或**微信**来登录 App  

2. 详细说明  

> 生成第三方登录认证请求的令牌返回给前端 前端唤起第三方应用  

> 第三方应用授权后和账号进行关联绑定  

### user-service 用户微服务

#### 功能介绍

1. 用户登录注册
2. 第三方登录注册
3. 用户资料修改
4. 收货地址增删改查
5. 银行卡增删改查
6. 实名认证
7. 用户粉丝查询
8. 商户提现申请

#### 注册功能

1. 需求描述  

> 注册功能主要可以实现, 用户手机号,验证码的形式进行注册. 用户手机号码必须唯一. 必须实现第三方登录(微信/支付宝)  

2. 详细说明   

```
  1. 1个手机号码只能注册一个账号.
  2. 手机号存在或者账号被冻结需要提示.
  3. 提供推荐者手机号(选填)
  4. 验证码为6位数字随机
  5. 用户注册成功之后将默认密码为手机后六位, 并提示用户及时修改
  6. 支持支付宝/微信账号授权登陆, 第三方授权绑定用户手机号, 不允许多次绑定手机号
```

3. 流程描述  

> [支付宝第三方登录](https://docs.open.alipay.com/218/105326/) 官方文档中已经详细描述了第三方授权登陆的流程以及细节。  

>  这里再次强调流程中的条件。

>  1. 用户发起第三方登陆, 获取授权码,userid. 如果数据库中已经存在匹配的userid 则说明,用户已经绑定过了. 拉取用户相关信息即可完成登陆
>  2. 如果userid不存在则需要注册新用户, 通过授权码发起oauth.token返回用户access_token. 通过access_token 获取用户用户信息 (ifo.share). [获取用户信息](https://docs.open.alipay.com/api_2/alipay.user.info.share)
>  
>  [微信第三方登录](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419317851&token=&lang=zh_CN)和支付都采用了标准的oauth2. 大体类似. 获取第三方注册信息之后 需要补充我们自己的业务. 我们拿到access_token 获取用户信息, 需要注册新用户, 跳转到用户注册页面进行信息的关联. 用户填写内容之后. 注册成功新用户, 并且关联第三方唯一信息.


### pay-service 充值(聚合支付)微服务  

#### 功能介绍  

1. 充值订单的生成  
2. 第3方支付通知接口业务  
3. 聚合扫码支付  

#### 充值订单的生成  

- 需求描述
```
对前端发起的充值业务区分 和 支付方式生成充值订单 和 第三方支付订单
```
- 详细说明

```
1. 生成支付宝或微信充值订单信息 返回给前端用于唤起支付宝或微信支付功能
2. 对充值的进行检测是否异常 是否可完成支付该充值业务的支付
```

- 流程描述

> 参考支付宝官方文档：[官方文档](https://docs.open.alipay.com/204/105051/)  

1. 创建应用并获取APPID  

2. 配置应用  
> 添加App支付功能，在开放平台里进行签约。  

3. 时序图  
![](https://gw.alipayobjects.com/zos/skylark-tools/public/files/2885bb7c5ebbc7ec07a46141fc3c0480.png)  

4. 接口流程示意图  
![](https://gw.alipayobjects.com/os/skylark-tools/public/files/81fdbf664f654970835e5426b55959f6)


> 参考微信官方文档：[官方文档](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_1) 

1. 时序图  
![](http://p8hqd7oln.bkt.clouddn.com/18-9-22/16266607.jpg)  

2. 用户在商户APP中选择商品，提交订单，选择微信支付。  

3. 商户后台收到用户支付单，调用微信支付统一下单接口。  

4. 统一下单接口返回正常的prepay_id，再按签名规范重新生成签名后，将数据传输给APP。参与签名的字段名为appid，partnerid，prepayid，noncestr，timestamp，package。注意：package的值格式为Sign=WXPay  

5. 商户APP调起微信支付。  

6. 商户后台接收支付通知。  

7. 商户后台查询支付结果。

#### 第3方支付通知接口业务  

- 需求描述
```
用户支付成功后(失败,取消) 后端会收到 支付宝或微信支付的通知
后端对该支付订单进行校检 修改用户资金
```
- 详细说明

```
1. 收到第3方通知回调后 对订单进行校检
2. 当通知为 用户支付完成 必须和本地支付订单进行对比 校检最终给用户增加 资金 和 账单
```

#### 聚合扫码支付
- 需求描述
```
用户能在 支付宝 微信 App 中扫描商家二维码 来进行对商家付款
```
- 详细说明

```
1. 订单生成逻辑和上面支付逻辑大致相同
2. 唯一不同的是在支付宝和微信支付中必须先生成 认证请求
3. 支付完成后进行其他业务处理 如: 分润 生成红包 等业务
```