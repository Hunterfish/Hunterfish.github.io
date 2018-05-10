---
title: 项目中异常捕获--统一异常处理
date: 2018-05-09 08:56:58
categories: Spring Boot微信点餐项目
tags:
  - Exception
  - Spring Boot
---

# 统一异常处理  

## 准备  

* Spring Boot微信点餐项目  
* PostMan工具  

## 之前  

1. 使用postman发送生成订单请求，成功时返回信息如下：  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/48933708.jpg)

2. 失败时，返回信息如下：  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/7610957.jpg)

> 我们想无论成功还是失败返回统一格式的信息。  

## 代码实现  

* ResultVO.java  

> 返回到前台的信息  

```java
/**
 * 功能描述: http请求返回的最外层对象
 * <p>
 * 作者: luohq
 * 日期: 2018/3/13 20:14
 */
@Data
public class ResultVO<T> {

    /** 错误码 */
    private Integer code;
    /** 提示信息 */
    private String msg;
    /** 具体内容 */
    private T data;
}
```

* ResultVO工具类  

```java
/**
 * 功能描述: ResultVO工具类
 * <p>
 * 作者: luohq
 * 日期: 2018/3/13 21:14
 */
public class ResultVOUtil {

    public static ResultVO success(Object object) {
        ResultVO resultVO = new ResultVO();
        resultVO.setData(object);
        resultVO.setCode(0);
        resultVO.setMsg("成功");
        return resultVO;
    }

    public static ResultVO success() {
        return success(null);
    }

    public static ResultVO error(Integer code, String msg){
        ResultVO resultVO = new ResultVO();
        resultVO.setCode(code);
        resultVO.setMsg(msg);
        return resultVO;
    }
}
```

* SellException.java  

> 自定义全局异常类，处理业务时，抛出该异常；  

```java
@Getter
public class SellException extends RuntimeException {

    private Integer code;

    public SellException(ResultEnum resultEnum) {
        super(resultEnum.getMessage());
        this.code = resultEnum.getCode();
    }
    public SellException(Integer code, String message) {
        super(message);
        this.code = code;
    }
}
```

* ResultEnum.java  

> 返回前端信息的枚举类  

```java
@Getter
public enum ResultEnum {

    SUCCESS(0, "成功"),
    PARAM_ERROR(1, "参数不正确"),
    PRODUCT_NOT_EXIST(10, "商品不存在"),
    PRODUCT_SOTCK_ERROR(11, "商品库存异常"),
    ORDER_NOT_EXIST(12, "订单不存在"),
    ORDERDETAIL_NOT_EXIST(12, "订单不存在"),
    ORDER_STATUS_ERROR(14, "订单状态不正确"),
    ORDER_UPDATE_FAIL(15, "订单更新失败"),
    ORDER_DETAIL_EMPTY(16, "订单详情为空"),
    ORDER_PAY_STATUS_ERROR(17, "订单支付状态不正确"),
    CART_EMPTY(18, "购物车为空"),
    ORDER_OWNER_ERROR(19, "该订单不属于当前用户"),
    WECHAT_MP_ERROR(20, "微信公众账号方面错误"),
    WXPAY_NOTIFY_MONEY_VERIFY_ERROR(21, "微信支付异步通知金额校验不通过"),
    ORDER_CANCEL_SUCCESS(22, "订单取消成功"),
    ORDER_FINISH_SUCCESS(23, "订单完结成功"),
    PRODUCT_STATUS_ERROR(24, "商品状态不正确"),
    LOGIN_FAIL(25, "登录失败, 登录信息不正确"),
    LOGOUT_SUCCESS(26, "登出成功"),
    ;

    private Integer code;
    private String message;

    ResultEnum(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
}
```


* SellExceptionHandler.java   

> 统一异常处理类：拦截登录异常；拦截各种业务异常  

```java
@ControllerAdvice
public class SellExceptionHandler {

    @Autowired
    private ProjectUrlConfig projectUrlConfig;

    // 拦截登录异常
    // 拦截后，跳转到：http://sell.natapp4.cc/sell/wechat/qrAuthorize?returnUrl=http://sell.natapp4.cc/sell/seller/login
    @ExceptionHandler(value = SellerAuthorizeException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public ModelAndView handlerAuthorizeException() {
        return new ModelAndView("redirect:"
        .concat(projectUrlConfig.getWechatOpenAuthorize())
        .concat("/sell/wechat/qrAuthorize")
        .concat("?returnUrl=")
        .concat(projectUrlConfig.getSell())
        .concat("/sell/seller/login"));
    }

    // 拦截业务异常
    @ExceptionHandler(value = SellException.class)
    @ResponseBody
    public ResultVO handlerSellerException(SellException e) {
        return ResultVOUtil.error(e.getCode(), e.getMessage());
    }
}
```

## 实现效果  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/19068018.jpg)

> 从上图可以看到：返回正确格式的错误信息，但此时状态码为**200**，之前是**500**，当然这个也可以自定义。  

## 抛出异常时自定义返回状态码  

* SellExceptionHandler.java 部分代码：  

> 直接使用注解**@ResponseStatus**,比如抛出异常时，返回403：**HttpStatus.FORBIDDEN**   

```java
// 拦截业务异常
    @ExceptionHandler(value = SellException.class)
    @ResponseBody
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public ResultVO handlerSellerException(SellException e) {
        return ResultVOUtil.error(e.getCode(), e.getMessage());
    }
```

* HttpStatus.java  

> 各种状态码  

```java
public interface HttpStatus {
    int SC_CONTINUE = 100;
    int SC_SWITCHING_PROTOCOLS = 101;
    int SC_PROCESSING = 102;
    int SC_OK = 200;
    int SC_CREATED = 201;
    int SC_ACCEPTED = 202;
    int SC_NON_AUTHORITATIVE_INFORMATION = 203;
    int SC_NO_CONTENT = 204;
    int SC_RESET_CONTENT = 205;
    int SC_PARTIAL_CONTENT = 206;
    int SC_MULTI_STATUS = 207;
    int SC_MULTIPLE_CHOICES = 300;
    int SC_MOVED_PERMANENTLY = 301;
    int SC_MOVED_TEMPORARILY = 302;
    int SC_SEE_OTHER = 303;
    int SC_NOT_MODIFIED = 304;
    int SC_USE_PROXY = 305;
    int SC_TEMPORARY_REDIRECT = 307;
    int SC_BAD_REQUEST = 400;
    int SC_UNAUTHORIZED = 401;
    int SC_PAYMENT_REQUIRED = 402;
    int SC_FORBIDDEN = 403;
    int SC_NOT_FOUND = 404;
    int SC_METHOD_NOT_ALLOWED = 405;
    int SC_NOT_ACCEPTABLE = 406;
    int SC_PROXY_AUTHENTICATION_REQUIRED = 407;
    int SC_REQUEST_TIMEOUT = 408;
    int SC_CONFLICT = 409;
    int SC_GONE = 410;
    int SC_LENGTH_REQUIRED = 411;
    int SC_PRECONDITION_FAILED = 412;
    int SC_REQUEST_TOO_LONG = 413;
    int SC_REQUEST_URI_TOO_LONG = 414;
    int SC_UNSUPPORTED_MEDIA_TYPE = 415;
    int SC_REQUESTED_RANGE_NOT_SATISFIABLE = 416;
    int SC_EXPECTATION_FAILED = 417;
    int SC_INSUFFICIENT_SPACE_ON_RESOURCE = 419;
    int SC_METHOD_FAILURE = 420;
    int SC_UNPROCESSABLE_ENTITY = 422;
    int SC_LOCKED = 423;
    int SC_FAILED_DEPENDENCY = 424;
    int SC_INTERNAL_SERVER_ERROR = 500;
    int SC_NOT_IMPLEMENTED = 501;
    int SC_BAD_GATEWAY = 502;
    int SC_SERVICE_UNAVAILABLE = 503;
    int SC_GATEWAY_TIMEOUT = 504;
    int SC_HTTP_VERSION_NOT_SUPPORTED = 505;
    int SC_INSUFFICIENT_STORAGE = 507;
}
```

* 效果  

> 可以看到，状态码已经显示403了  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/20639259.jpg)



