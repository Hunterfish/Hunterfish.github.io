---
title: 2018工作项目总结-后台管理中心
date: 2018-10-25 08:42:18
categories: 工作日志
tags:
  - 总结
  - 面试
---

# 简介  

liang多多商城后台管理中心。  

## 项目描述  

* 后端基于 ``SpringBoot + tk.mybatis``、前端基于``Vue + Vuex + elementUI``的前后端分离项目；  
* 基于 ``Shiro`` 安全框架的登陆身份认证和权限校验（授权）；  
* 实现前后端分离，通过 ``token`` 进行数据交互。  

## 项目主要模块  

1. 系统管理  
> 管理员列表、角色管理、菜单管理、文件上传、系统日志  

2. 会员管理  
> 认证审核、充值管理、用户管理  

3. 财务管理  
> 提现审核、银行机构  

4. 直供管理  
> 订单管理、商家管理、商品管理、商品分类  

5. 本地生活  
> 商家管理、生活服务、订单管理、生活分类、开通城市  

6. 统计管理  

7. 代理管理  

8. 其他  
> 推送、弹窗消息、广告位管理、App文章管理  


## 重点技术  

自定义全局异常处理类、shiro、redis、系统日志等

### shiro  

参考：[跟我学Shiro](http://jinnianshilongnian.iteye.com/blog/2018398?page=3#comments)  

实体关系：**用户--角色--权限**  

1. 主要创建Shiro配置文件``ShiroConfig.java``  

* 初始化``SessionMannger``  
> **会话管理**，即用户登录后就是一次会话，在没有退出之前，它的所有信息都在会话中。  
* 初始化 ``SerucityManager``  
> **安全管理器**，安全管理器；即所有与安全有关的操作都会与SecurityManager交 互；且它管理着所有Subject；可以看出它是Shiro的核心，它负责与后边介绍的其他组件进行交互，如果学习过SpringMVC，你可以把它看成DispatcherServlet前端控制器。


* 初始化``权限过滤器``  
> 拦截所有请求，配置为 ``anon`` 的，表示不经过shiro处理，配置为 ``oauth2`` 的，表示经过 ``OAuth2Filter.java`` 处理。  
> 前后端分离的接口，都会交给``OAuth2Filter``处理，这样就保证，没有权限的
请求，拒绝访问。  

* ``Oauth2Filter.java``  
> 继承``AuthenticatingFilter.java``;  
> 主要重写了：``createToken``(获取当前认证令牌信息token)、``isAccessAllowed``(是否允许访问)、``onAccessDenied``(访问被拒绝处理，token不存在，直接返回401)、``onLoginFailure``(登陆失败处理,返回授权错误状态码401)  


2. 创建``OAuth2Realm.java``  

* ``Realm``
> 可以有1个或多个Realm，可以认为是安全实体数据源，即用于获取安全实体的；可以是JDBC实现，也可以是LDAP实现，或者内存实现等等；由用户提供；注意：Shiro不知道你的用户/权限存储在哪及以何种格式存储；所以我们一般在应用中都需要实现自己的Realm；  

* 继承``AuthorizingRealm.java``抽象类
> 实现``supports()``： 判断是否支持此token（本项目我们自定义token）
```java
public boolean supports(AuthenticationToken token) {
    return token instanceof OAuth2Token;
}
```
```java
public class OAuth2Token implements AuthenticationToken {
    private String token;

    public OAuth2Token(String token){
        this.token = token;
    }
    // 获取身份
    @Override
    public String getPrincipal() {
        return token;
    }
    // 获取凭证
    @Override
    public Object getCredentials() {
        return token;
    }
}
```
> 实现``doGetAuthenticationInfo()``: 获取身份验证（登陆）相关信息  
> 实现``doGetAuthorizationInfo()``: 获取授权信息  

3. 本项目中登陆时，都会重新生成token保存到数据库中，获取权限等其他接口请求的header中携带token参数，通过shiro的过滤器判断token是否和数据库中查询的一样。  

### Redis缓存  

> 灵活和高效实用缓存，需要考虑以下几个问题：  

1.  查询数据的时候，尽量减少DB查询，DB主要负责写数据
2.  尽量不使用 ``LEFT JOIN`` 等关联查询，缓存命中率不高，还浪费内存
3.  多使用单表查询，缓存命中率最高
4.  数据库insert、update、delete时，同步更新缓存数据  
5.  合理运用Redis数据结构，也许有质的飞跃
6.  对于访问量不大的项目，使用缓存只会增加项目的复杂度

#### 切面配置    

> 本系统采用Redis作为缓存，并可配置是否开启redis缓存，主要还是通过Spring AOP实现的，配置如下所
示：  

```yml
redis:
    open: true  # 是否开启redis缓存  true开启   false关闭
    database: 5
    host: 192.168.**.***
    port: 6379
    password:      # 密码（默认为空）
    timeout: 6000  # 连接超时时长（毫秒）
    pool:
      max-active: 1000  # 连接池最大连接数（使用负值表示没有限制）
      max-wait: -1      # 连接池最大阻塞等待时间（使用负值表示没有限制）
      max-idle: 10      # 连接池中的最大空闲连接
      min-idle: 5       # 连接池中的最小空闲连接
```

```java
/**
 * Redis切面处理类
 */
@Aspect
@Configuration
public class RedisAspect {
    private Logger logger = LoggerFactory.getLogger(getClass());
    
    /**
     * 是否开启redis缓存  true开启   false关闭
     */
    @Value("${spring.redis.open: false}")
    private boolean open;

    @Around("execution(* com.dl98.admin.common.utils.RedisUtils.*(..))")
    public Object around(ProceedingJoinPoint point) throws Throwable {
        Object result = null;
        if(open){
            try{
                result = point.proceed();
            }catch (Exception e){
                logger.error("redis error", e);
                throw new RRException("Redis服务异常");
            }
        }
        return result;
    }
}
```

### 全局异常处理机制  

> 本项目通过 ``RRException`` 异常类，抛出自定义异常，RRException继承 ``RuntimeException``，不能继承Exception，如果继承Exception，则Spring事务不会回滚。  

```java
public class RRException extends RuntimeException {
	private static final long serialVersionUID = 1L;
	
    private String msg;
    private int code = 500;
    
    public RRException(String msg) {
		super(msg);
		this.msg = msg;
	}
	
	public RRException(String msg, Throwable e) {
		super(msg, e);
		this.msg = msg;
	}
	
	public RRException(String msg, int code) {
		super(msg);
		this.msg = msg;
		this.code = code;
	}
	
	public RRException(String msg, int code, Throwable e) {
		super(msg, e);
		this.msg = msg;
		this.code = code;
	}
    public String getMsg() {
		return msg;
	}

	public void setMsg(String msg) {
		this.msg = msg;
	}

	public int getCode() {
		return code;
	}

	public void setCode(int code) {
		this.code = code;
	}
    
```

> 定义了 ``RRExceptionHandler`` 类，并加上注解 ``@RestControllerAdvice``，就可以处理所有抛出的异常，并返回JSON数据。  

> @RestControllerAdvice是由@ControllerAdvice、@ResponseBody注解组合而来。  

```java
/**
 * 功能描述: 全局异常处理器
 */
@RestControllerAdvice
public class RRExceptionHandler {

    private Logger logger = LoggerFactory.getLogger(getClass());

    /**
     * 处理自定义异常
     */
    @ResponseStatus(HttpStatus.OK)
    @ExceptionHandler(RRException.class)
    public R handleRRException(RRException ex) {
        logger.error("handleRRException => {}", ex.getMessage());
        R r = new R();
        r.put("code", ex.getCode());
        r.put("msg", ex.getMessage());
        return r;
    }

    @ResponseStatus(HttpStatus.OK)
    @ExceptionHandler(DuplicateKeyException.class)
    public R handleDuplicateKeyException(DuplicateKeyException ex) {
        logger.error("handleDuplicateKeyException => {}", ex.getMessage());
        return R.error("数据库中已存在该记录");
    }

    @ExceptionHandler(AuthorizationException.class)
    public R handleAuthorizationException(AuthorizationException ex) {
        logger.error("handleAuthorizationException => {}", ex.getMessage());
        return R.error("没有权限，请联系管理员授权");
    }

    @ResponseStatus(HttpStatus.OK)
    @ExceptionHandler(Exception.class)
    public R handleException(Exception ex) {
        logger.error("handleException => {}", ex);
        return R.error();
    }
}
```

### 系统日志  

> 系统日志是通过 ``Spring AOP`` 实现的，我们自定义了注解 ``@SysLog``，且只能在方法上使用，如下所示  
```java
/**
 * 放置在RequestMapping注解的Url请求处理方法上，用于统计请求操作日志
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface SysLog {

    /** 功能名称 ***/
    String value() default "";
}
```
> 使用方式：  

```java
/**
 * 保存用户
 */
@SysLog("保存用户")
@RequestMapping("/save")
@RequiresPermissions("sys:user:save")
public R save(@RequestBody SysUserEntity user) {
    ValidatorUtils.validateEntity(user, AddGroup.class);

    user.setCreateUserId(getUserId());
    sysUserService.add(user);

    return R.ok();
}
```

> 我们可以发现，只需要在保存日志的请求方法上，加上 ``@SysLog`` 注解，就可以把日志保存到数据库里了。具体是在哪里把数据保存到数据库里的呢，我们定义  ``SysLogAspect`` 处理类，如下所示  

```java
/**
 * 功能描述: 操作日志切面处理类
 */
@Aspect
@Component
public class SysLogAspect {

    private static final Logger logger = LoggerFactory.getLogger(SysLogAspect.class);

    @Autowired
    private SysLogService sysLogService;

    private ThreadLocal<Long> startTime = new ThreadLocal<>();

    /**
     * 功能描述: 其他请求拦截
     */
    @Before("within(com.dl98.admin..*) && @annotation(sysLog)")
    public void addBeforeSysLog(JoinPoint joinPoint, SysLog sysLog) {
        startTime.set(System.currentTimeMillis());
        logger.debug("执行 [ {} ] 开始", sysLog.value());
        logger.debug("方法名称 : {}", joinPoint.getSignature().toString());
        logger.debug("传入参数 : {}", JsonUtils.toJsonString(joinPoint.getArgs()));
    }

    @AfterReturning("within(com.dl98.admin..*) && @annotation(sysLog)")
    public void addAfterReturningSysLog(JoinPoint joinPoint, SysLog sysLog) {
        long time = System.currentTimeMillis() - startTime.get();
        logger.debug("执行 [ {} ] 结束 耗时: {} 毫秒", sysLog.value(), time);
        saveSysLog(joinPoint, sysLog, time);
    }

    @AfterThrowing(pointcut = "within(com.dl98.admin..*) && @annotation(sysLog)", throwing = "ex")
    public void addAfterThrowingSysLog(JoinPoint joinPoint, SysLog sysLog, Exception ex) {
        logger.error("执行 [ {} ] 异常", sysLog.value(), ex);
    }

    private void saveSysLog(JoinPoint joinPoint, SysLog sysLog, long time) {
        SysLogEntity operation = new SysLogEntity();
        // 注解上的描述
        operation.setOperation(sysLog.value());
        // 请求的方法名
        operation.setMethod(joinPoint.getSignature().toShortString());
        // 请求的参数
        try {
            operation.setParams(JsonUtils.toJsonString(joinPoint.getArgs()));
        } catch (Exception ignored) {
            operation.setParams("");
        }
        // 设置IP地址
        operation.setIp(IPUtils.getIpAddress(HttpContextUtils.getHttpServletRequest()));

        String username = ((SysUserEntity) SecurityUtils.getSubject().getPrincipal()).getUsername();
        operation.setUsername(username);

        operation.setTime(time);
        operation.setCreateDate(new Date());
        // 保存系统日志
        sysLogService.saveNotNull(operation);
    }
}
```

> ``SysLogAspect`` 类定义了一个切入点，请求 ``@SysLog`` 注解的方法时，会进入 ``around`` 方法，把系统日志保存到数据库中。  
