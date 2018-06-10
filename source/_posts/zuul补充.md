---
title: zuul补充
date: 2018-06-09 17:51:31
tags:
---

# Zuul：权限校验  

1. 微服务架构下，多个微服务都需要对访问进行鉴权，每个微服务都需要明确当前访问的用户及其权限；  

2. 在 **Zuul** 的前置过滤器里实现相关逻辑，是不错的方案

3. **分布式 Session** 和 **Oauth2**  
> 在微服务框架中，多个微服务的无状态化，一般考虑的都是上面两种方案；  
> 本点餐项目采用的是**分布式 session**，即将用户认证信息储存在共享存储中，且通常由**用户会话**作为 key 来实现简单的分布式 Hash 映射；  
> 当用户访问微服务时，用户数据可以从共享储存中获取，用户登录状态是不透明的，同时也是高可用且扩展的方案。  

4. **Oauth2**  
> 公司项目就是 **Spring Security** 和 **Oauth2**结合作为鉴权的。  


## 项目流程

1. 买家、买家特征，买家和卖家登录时分别访问哪个服务，  

```java
/**
     *  /order/create 只能买家访问(cookie里有openid)
     *  /order/finish 只能卖家访问(cookie里有token，并且对应的redis中值)
     *  /product/list 都可访问
     */
```

2. 首先访问``api-gateway``，再转发到``user``服务中去

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


