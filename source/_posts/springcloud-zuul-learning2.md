---
title: Spring Cloud 实战 (十二)：Zuul--服务网关 (2)
date: 2018-06-08 09:27:26
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Zuul
---

上一篇初步了解并使用了 **Zuul** 的特点和基本功能，本章继续深入学习 **Zuul**的功能。 
参考博客[服务网关 Zuul（过滤器）【Finchley 版】](https://windmt.com/2018/04/23/spring-cloud-11-zuul-filter/)

# Pre Post 过滤器   

## 实现功能 

1. 分析服务网关 **Zuul** 模块，可以看到所有请求都会经过 zuul，然后才到达服务 A、B、C；
2. 现在对所有请求做**权限校验**，通过 **Zuul**，不必对 A、B、C 都进行校验；  
3. 所以在 **Zuul**上对所有服务请求做**统一权限校验**。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/74674982.jpg)

## Pre过滤器  

实现权限认证。  

1. **TokenFilter.java**  
> extends``ZuulFilter``；
> 这里只是简单判断``token``是否为空，你也可以与数据库对比，更详细的操作。    

```java
/**
 * 功能描述: Zuul 前置过滤器：参数校验
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/8 0008 9:32
 */
@Component
public class TokenFilter extends ZuulFilter {


    @Override
    public String filterType() {
        return PRE_TYPE;
    }

    /**
     * 过滤器顺序，数值越小，优先级越高
     * @return
     */
    @Override
    public int filterOrder() {
        // 减一，自定义的过滤器就会在PRE_DECORATION_FILTER_ORDER过滤器之前执行
        return PRE_DECORATION_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();

        // 从url参数里获取，也可以从cookie，header里获取
        String token = request.getParameter("token");
        if (StringUtils.isEmpty(token)) {
            // token为空，权限验证不通过
            requestContext.setSendZuulResponse(false);
            // 没有权限标识：401
            requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
        }
        return null;
    }
}
```

2. **ApiGatewayApplication.java**  
> 启动类上加入以下代码；  

```java
@Bean
public TokenFilter tokenFilter() {
    return new TokenFilter();
}
```

3. 启动``eureka``、``config``、``api-gateway``、``product``；  
4. 访问：http://localhost:8082/myProduct/product/list  
> URL 后不加 **token"，报``401``权限认证失败错误。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/2765235.jpg)

5. 访问：http://localhost:8082/myProduct/product/list?token=123456  
> URL 后加上 **token"，成功获取数据！  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/6583713.jpg)

## Post 过滤器  

实现返回 **Response**时，添加自定义信息，比如头部 **Header**。  

1. **AddResponseHeaderFilter.java**  
> 和上面``TokenFilter.java``一样步骤。  

```java
/**
 * 功能描述: Zuul Post过滤器：返回自定义内容
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/8 0008 10:46
 */
public class AddResponseHeaderFilter extends ZuulFilter {

    @Override
    public String filterType() {
        return POST_TYPE;
    }

    @Override
    public int filterOrder() {
        return SEND_RESPONSE_FILTER_ORDER;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    /**
     * 返回response头部添加自定义信息
     * @return
     * @throws ZuulException
     */
    @Override
    public Object run() throws ZuulException {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletResponse response = requestContext.getResponse();
        response.setHeader("X-Foo", UUID.randomUUID().toString());
        return null;
    }
}
```

2. **ApiGatewayApplication.java**  
> 启动类上加入以下代码；  

```java
@Bean
public AddResponseHeaderFilter addResponseHeaderFilter() {
    return new AddResponseHeaderFilter();
}
```

3. 访问：http://localhost:8082/myProduct/product/list?token=123456  
> Response Header 显示自定义头部信息！  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/8010409.jpg)

# Zuul：限流   

## 限流分析  

因为所有网络请求都会经过服务网关 **Zuul**，在 **Zuul**上对 **API** 做 ``限流保护``，防止网络攻击。  
比如某个 API 是发短信的，需要限制客户端请求速率，从而在一定程度上抵御**短信轰炸攻击**，降低损失。   

1. **时机**：请求被转发之前调用   
> **限流保护**功能实在**前置过滤器**中做的；  
> 如果前置过滤器有多个操作，**限流**应该放到最前面的地方；  
> 比如限流和鉴权，限流应该放在鉴权前面；  

## 限流方案    

**漏桶**和**令牌桶**算法，详情参考博客(https://www.cnblogs.com/LBSer/p/4083131.html)。  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/22408360.jpg)

### Guava RateLimiter  

1. github源码[guava](https://github.com/google/guava)  
2. 采用**令牌桶方案**；  
2. 参考博客：<http://www.itmuch.com/spring-cloud-sum/spring-cloud-ratelimit/>  
3. 参考博客：[Guava RateLimiter源码解析](https://segmentfault.com/a/1190000012875897)  

### spring-cloud-zuul-ratelimit  

1. 该组件并非 **Spring Cloud**官方的，而是个人写的；  
2. github 源码[spring-cloud-zuul-ratelimit](https://github.com/marcosbarbero/spring-cloud-zuul-ratelimit)  
3. 参考博客[Zuul：构建高可用网关之多维度限流](https://segmentfault.com/a/1190000012252677)  

## 实战   

使用 **Guava RateLimiter** 简单演示限流功能。  

1. **RateLimitFilter.java**  
```java

/**
 * 功能描述: 令牌桶方案：限流
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/8 0008 11:35
 */
@Component
public class RateLimitFilter extends ZuulFilter {

    // RateLimiter：谷歌开源令牌桶算法
    // 指定每秒100个令牌
    private static final RateLimiter RATE_LIMITER = RateLimiter.create(100);

    @Override
    public String filterType() {
        return PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        // SERVLET_DETECTION_FILTER_ORDER 优先级-3，限流优先级应该最小，所以 -1
        return SERVLET_DETECTION_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {
        // 如果没有拿到令牌，抛出异常
        if (!RATE_LIMITER.tryAcquire()) {
            throw new RateLimitException();
        }
        return null;
    }
}
```

2. 使用 ab 压测工具进行测试  
> 可以参考之前博客[秒杀活动与分布式锁](https://www.ddebug.cn/seconds-kill-distributed-lock.html)简单上手使用;  
> 下面命令为 1 秒钟发送 100 次请求。 
> 这里只是简单模拟，测试，是否报异常 

```java
ab -t 1 -c 100 http://localhost:8082/myProduct/product/list?token=123456
```

3. ``api-gateway``console 上已经打印报错信息：  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/55147445.jpg)

# Zuul：权限校验   

1. 微服务架构下，多个微服务都需要对访问进行鉴权，每个微服务都需要明确当前访问的用户及其权限；  
2. 在 **Zuul** 的前置过滤器里实现相关逻辑，是不错的方案   
3. **分布式 Session** 和 **Oauth2**  
> 在微服务框架中，多个微服务的无状态化，一般考虑的都是上面两种方案；  
> 本点餐项目采用的是**分布式 session**，即将用户认证信息储存在共享存储中，且通常由**用户会话**作为 key 来实现简单的分布式 Hash 映射；  
> 当用户访问微服务时，用户数据可以从共享储存中获取，用户登录状态是不透明的，同时也是高可用且扩展的方案。  

4. **Oauth2**  
> 公司项目就是 **Spring Security** 和 **Oauth2**结合作为鉴权的。  

## 项目实战  

下面结合之前学习的点餐项目学习！  

### 用户登录功能   

#### API 文档  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/75180955.jpg)

#### 用户表  

```sql
-- 用户
CREATE TABLE `user_info` (
  `id` varchar(32) NOT NULL,
  `username` varchar(32) DEFAULT '',
  `password` varchar(32) DEFAULT '',
  `openid` varchar(64) DEFAULT '' COMMENT '微信openid',
  `role` tinyint(1) NOT NULL COMMENT '1买家2卖家',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`)
);
```

#### 新建 user 项目   

1. 注意添加依赖  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-8/57631951.jpg)

2. 项目多模块化，参考之前博客[Spring Cloud 实战 (六)：Spring Boot多模块化](https://www.ddebug.cn/springboot-multi-module-startup.html)  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-11/95691334.jpg)

3. **bootstrap.yml**  

```yaml
spring:
  application:
    name: user
  cloud:
    config:
      discovery:
        enabled: true
        service-id: CONFIG
      profile: dev
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

4. 远端git仓库：**user-dev.yml**  

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    username: root
    password: root
    url: jdbc:mysql://localhost:3306/SpringCloud_Sell?characterEncoding=utf-8&useSSL=false
  redis:
    host: 127.0.0.1
    port: 6379
```

#### 买家/卖家登录  

1. **LoginController**  

```java
@RestController
public class LoginController {

    @Autowired
    private UserService userService;

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    /**
     * 卖家端登录
     * @param openid
     * @param response
     * @return
     */
    @GetMapping("/buyer")
    public ResultVO buyer(@RequestParam("openid") String openid,
                          HttpServletResponse response) {

        // 1. openid 和数据库里的数据进行匹配
        UserInfo userInfo = userService.findByOpenid(openid);
        if (userInfo == null) {
            return ResultVOUtil.error(ResultEnum.LOGIN_FAIL);
        }
        // 2. 判断登录用户是否买家角色
        if (RoleEnum.BUYER.getCode() != userInfo.getRole()) {
            return ResultVOUtil.error(ResultEnum.ROLE_ERROR);
        }

        // 3. cookie里设置openid=abc
        CookieUtil.set(response, CookieConstant.OPENID, openid, CookieConstant.expire);
        return ResultVOUtil.success();
    }

    /**
     * 买家端登录
     * @param openid
     * @param response
     * @return
     */
    @GetMapping("/seller")
    public ResultVO seller(@RequestParam("openid") String openid,
                           HttpServletResponse response,
                           HttpServletRequest request) {

        // 1. 判断是否已登录
        Cookie cookie = CookieUtil.get(request, CookieConstant.TOKEN);
        // cookie不为空且redis存储token也不为空
        if (cookie != null &&
                !StringUtils.isEmpty(stringRedisTemplate.opsForValue().get(String.format(RedisConstant.TOKEN_TEMPLATE, cookie.getValue())))) {
            return ResultVOUtil.success();
        }

        // 1. openid 和数据库里的数据进行匹配
        UserInfo userInfo = userService.findByOpenid(openid);
        if (userInfo == null) {
            return ResultVOUtil.error(ResultEnum.LOGIN_FAIL);
        }
        // 2. 判断登录用户是否卖家角色
        if (RoleEnum.SELLER.getCode() != userInfo.getRole()) {
            return ResultVOUtil.error(ResultEnum.ROLE_ERROR);
        }

        // 3. redis 设置key=UUID, value=456
        String token = UUID.randomUUID().toString();
        Integer expire = CookieConstant.expire;
        stringRedisTemplate.opsForValue()
                .set(String.format(RedisConstant.TOKEN_TEMPLATE, token),
                    openid,
                    expire,
                    TimeUnit.SECONDS);

        // 3. cookie里设置openid=abc
        CookieUtil.set(response, CookieConstant.TOKEN, token, CookieConstant.expire);
        return ResultVOUtil.success();
    }
}
```

## 实现效果   

用户登陆后，根据Cookie信息判断是卖家还是买家。  

1. 买家、买家特征，买家和卖家登录时分别访问哪个服务；   

```java
/**
 *  /order/create 只能买家访问(cookie里有openid)
 *  /order/finish 只能卖家访问(cookie里有token，并且对应的redis中值)
 *  /product/list 都可访问
 */
```

2. 首先访问``api-gateway``，再转发到``user``服务中去。  

## Zuul 敏感头  

> 添加配置``sensitive-headers``  

```yaml
# 自定义路由
zuul:
  # 全部服务忽略敏感头（全部服务都可以传递cookie）
  sensitive-headers:
  routes:
    myProduct:
      path: /myProduct/**
      serviceId: product
#     sensitiveHeaders:
    # 简介写法
#    product: /myProduct/**
  # 排除某些路由
#  ignored-patterns:
#    - /product/product/list
#    - /myProduct/product/list
#    - /**/product/listForOrder
```
### api-gateway 代码  

1. AuthFilter.java  

```java
/**
 * 功能描述: 权限拦截filter：区分买家和卖家
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/8 0008 13:58
 */
@Component
public class AuthFilter extends ZuulFilter {

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public String filterType() {
        return PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return PRE_DECORATION_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();

        /**
         *  /order/create 只能买家访问(cookie里有openid)
         *  /order/finish 只能卖家访问(cookie里有token，并且对应的redis中值)
         *  /product/list 都可访问
         */
        if ("/order/order/create".equals(request.getRequestURI())) {
            Cookie cookie = CookieUtil.get(request, "openid");
            if (cookie == null || StringUtils.isEmpty(cookie.getValue())) {
                requestContext.setSendZuulResponse(false);
                requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
            }
        }
        if ("/order/order/finish".equals(request.getRequestURI())) {
            Cookie cookie = CookieUtil.get(request, "token");
            if (cookie == null
                    || StringUtils.isEmpty(cookie.getValue())
                    || StringUtils.isEmpty(stringRedisTemplate.opsForValue().get(String.format(RedisConstant.TOKEN_TEMPLATE, cookie.getValue())))) {
                requestContext.setSendZuulResponse(false);
                requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
            }
        }

        return null;
    }
}
```
### 测试访问  

区分买家、卖家靠登录时的 Cookie 信息。
买家登录时，Cookie 存储 ``openid=abc``openid 信息；
卖家登录时，Cookie 存储 ``token=xxx`` token 信息，同时 Redis 存储了先关信息

1. 访问**买家下单**：<http://localhost:9000/order/order/create>  
> 注意在 **Headers** 添加 **Cookie**信息!    

![](http://p8hqd7oln.bkt.clouddn.com/18-6-10/87100972.jpg)

2. 访问**卖家结单**，先访问卖家登陆：<http://localhost:9000/user/login/seller?openid=xyz>  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-10/31819995.jpg)

2. 访问**卖家结单**：<http://localhost:8082/order/finish>  
> 注意在 **Headers** 添加 Cookie 信息！  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-10/79859744.jpg)

### 优化买家/卖家过滤  

为了以后扩展性，我们可以分成买家过滤器 **AuthBuyerFilter.java**，卖家过滤器 **AuthSellerFilter.java**。  

1. **AuthBuyerFilter.java**  

```java
@Component
public class AuthBuyerFilter extends ZuulFilter {

    @Override
    public String filterType() {
        return PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return PRE_DECORATION_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();
        
        // 判断是否买家下订单链接，如果是，执行下面 run()方法，如果不是，直接返回false
        if ("/order/order/create".equals(request.getRequestURI())) {
            return true;
        }
        return false;
    }

    @Override
    public Object run() throws ZuulException {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();

        /**
         *  /order/create 只能买家访问(cookie里有openid)
         */
        Cookie cookie = CookieUtil.get(request, "openid");
        if (cookie == null || StringUtils.isEmpty(cookie.getValue())) {
            requestContext.setSendZuulResponse(false);
            requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
        }

        return null;
    }
}
```
2. **AuthSellerFilter.java**  

```java
@Component
public class AuthSellerFilter extends ZuulFilter {

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Override
    public String filterType() {
        return PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return PRE_DECORATION_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();

        if ("/order/order/finish".equals(request.getRequestURI())) {
            return true;
        }
        return false;
    }

    @Override
    public Object run() throws ZuulException {
        RequestContext requestContext = RequestContext.getCurrentContext();
        HttpServletRequest request = requestContext.getRequest();

        /**
         *  /order/finish 只能卖家访问(cookie里有token，并且对应的redis中值)
         */
        Cookie cookie = CookieUtil.get(request, "token");
        if (cookie == null
                || StringUtils.isEmpty(cookie.getValue())
                || StringUtils.isEmpty(stringRedisTemplate.opsForValue().get(String.format(RedisConstant.TOKEN_TEMPLATE, cookie.getValue())))) {
            requestContext.setSendZuulResponse(false);
            requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
        }

        return null;
    }
}
```

# Zuul：跨域

## 跨域问题  

1. 浏览器的 Ajax 是有**同源策略**的，如果违反同源策略，就会产生**跨域**问题；  

2. **Zuul** 作为 API 服务网关，可以处理跨域问题，Zuul 的跨域也可以看成 **Spring** 的跨域；  

3. 第一种：**在被调用的类或方法上增加``@CrossOrigin``注解**；  
> 增加注解，来声明支持跨域； 
> 局限性：只支持类或方法，如果应用太多，非常麻烦。  

4. 第二种：**在 Zuul 里增加``CorsFilter``过滤器**；  
> 此方案只增加在 API 网关上，对内部代码没有任何改造，解耦性。  

## CorsFilter 过滤器  

### Cors 含义  

跨域资源共享！

1. C: Cross  
2. O: Orign  
3. R: Resource
4. S: Sharing

### CorsConfig

CorsFilter配置类！  

1. **CorsConfig.java**  

```java
/**
 * 功能描述: 跨域配置
 * <p>
 * 作者: luohongquan
 * 日期: 2018/6/10 10:13
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        final UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        final CorsConfiguration config = new CorsConfiguration();

        // 设置是否支持Cookie跨域
        config.setAllowCredentials(true);
        // list存放所有原始域，比如http:www.a.com，http:www.b.com
        config.setAllowedOrigins(Arrays.asList("*"));
        // 允许所有头
        config.setAllowedHeaders(Arrays.asList("*"));
        // 允许所有请求方法，比如get/post
        config.setAllowedMethods(Arrays.asList("*"));
        // 缓存时间，在该时间段内，多次访问不会检查跨域问题
        config.setMaxAge(300l); // 300秒

        // "/**": 对所有路径设置跨域处理
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
```
2. 跨域问题基本上都是有前端 js 发起，这里就不测试了；  
3. 处理跨域很多时候可以在 ``nginx``中完成；  
4. 想深入学习可以参考慕课网免费课程[ajax跨域完全讲解](https://www.imooc.com/learn/947)。  







