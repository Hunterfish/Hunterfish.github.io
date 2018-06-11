---
title: Spring Cloud 实战 (十三)：Hystrix--服务容错
date: 2018-06-10 10:42:59
categories: Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Hystrix
---
# 前言  

## 雪崩效应  

1. 雪崩效应：在微服务架构中，通常有多个微服层调用，如果某个服务不可用，导致调用故障，造成整个系统不可用的情况。  

2. 比如A、B、C 三个微服务，A 服务调用 B 服务，B 服务调用 C 服务；  
3. 如果 B 服务调用 C 服务由于某种原因失败，B 就会一直重试，**同步等待**会造成资源耗尽，结果 B 服务也不可用；  
4. 而 A 调用已经不可用的 B，同时也会**同步等待**，最会 A、B、C 都不可用了，导致整个系统都不可用了！  

![](1)

## Spring Cloud Hystrix  

参考博客[服务容错保护 Hystrix【Finchley 版】](https://windmt.com/2018/04/15/spring-cloud-4-hystrix/)。  

1. **防雪崩利器**  

2. **基于 Netflix 对应的 Hystrix** 实现的

3. 微服务提供一切服务容错机制，雪崩防御机制

# Hystrix功能

## 服务降级  

生活中常见比如双十一高峰时，显示"服务器开小差了"，秒杀时，显示"请稍后再试"。   

1. 优先核心服务，非核心服务**不可用**或**弱可用**  
> 比如我们点餐项目，流量突然大量涌入，要保证核心业务商品、订单、支付服务可用；  
> 其他比如广告、积分、红包等服务暂时不可用或部分可用。  

2. **通过``HystrixCommand``注解指定**  

3. **``fallbackMethod``(回退函数)中具体实现降级逻辑**  

### 异常回退  

下面主要为``order``项目中。  

1. **pom.xml**   
> ``order-server``子模块需要引入``spring-cloud-starter-netflix-hystrix``   

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>
```

2. **OrderApplication**启动类  
> 加入注解``@EnableHystrix``   

```java
@SpringBootApplication
// @EnableDiscoveryClient
@EnableHystrix
@EnableFeignClients(basePackages = ("cn.hunter.product.client"))
public class OrderApplication {

    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }
}
```

3. **HystrixController.java**  

```java
@RestController
public class HystrixController {

    @GetMapping("/getProductInfoList")
    @HystrixCommand(fallbackMethod = "fallback")
    public String getProductInfoList() {
        RestTemplate restTemplate = new RestTemplate();
        return restTemplate.postForObject("http://127.0.0.1:8081/product/listForOrder",
                Arrays.asList("157875196366160022"),
                String.class);
    }

    private String fallback() {
        return "太拥挤了，请稍后再试";
    }
}
```

4. 启动 eureka、config、api-gateway、product、order 服务。  

5. **访问：<http://localhost:8082/getProductInfoList>**  
> 访问成功，返回数据！  

![](2)

6. 如果停掉``product``服务，再次访问 5 中 URL：

![](3)

### 默认回退方法  

1. 在方法上添加注解``@DefaultProperties(defaultFallback = "defaultFallback")``  

```java
@RestController
@DefaultProperties(defaultFallback = "defaultFallback")
public class HystrixController {

    @GetMapping("/getProductInfoList")
//    @HystrixCommand(fallbackMethod = "fallback")
    @HystrixCommand
    public String getProductInfoList() {
        RestTemplate restTemplate = new RestTemplate();
        return restTemplate.postForObject("http://127.0.0.1:8081/product/listForOrder",
                Arrays.asList("157875196366160022"),
                String.class);
    }

    private String fallback() {
        return "太拥挤了，请稍后再试";
    }

    private String defaultFallback() {
        return "默认提示：太拥挤了，请稍后再试~~";
    }
}
```

2. 在``product``服务停止情况下，访问：<http://localhost:8082/getProductInfoList>  

![](4)

### 服务超时时间  

根据具体业务考虑是否配置，当服务要访问外网，比如开户、提现、第三方支付等业务访问时间可能会比较长，需要合理设置。  

1. **ProductController.java**  
> ``product``项目，添加休眠时间，2 秒。  

```java
/**
 * 获取商品列表（远程订单服务调用）
 * @param productIdList
 * @return
 */
@PostMapping("listForOrder")
public List<ProductInfo> listForOrder(@RequestBody List<String> productIdList) {
    try {
        Thread.sleep(2000l);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    return productService.findList(productIdList);
}
```

2. 启动``product``服务，访问：<http://localhost:8082/getProductInfoList>  
> 从下面步骤3可知道，默认超时时间为1秒，所以``order``服务会执行**回退方法``。   

![](5)

3. 配置超时时间  
> 休眠2秒，我们设置超时时间3秒；  
> 配置``execution.isolation.thread.timeoutInMilliseconds``  

![](6)

```java
@RestController
@DefaultProperties(defaultFallback = "defaultFallback")
public class HystrixController {

    @GetMapping("/getProductInfoList")
//    @HystrixCommand(fallbackMethod = "fallback")
    // 超时配置
    @HystrixCommand(commandProperties = {
            @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "3000")
    })
    public String getProductInfoList() {
        RestTemplate restTemplate = new RestTemplate();
        return restTemplate.postForObject("http://127.0.0.1:8081/product/listForOrder",
                Arrays.asList("157875196366160022"),
                String.class);
    }

    private String fallback() {
        return "太拥挤了，请稍后再试";
    }

    private String defaultFallback() {
        return "默认提示：太拥挤了，请稍后再试~~";
    }
}
```

4. 重新执行步骤2  
> 成功返回数据！  

![](7)

## 依赖隔离  

参考博客[Spring Cloud构建微服务架构：服务容错保护（Hystrix依赖隔离）【Dalston版】](http://blog.didispace.com/spring-cloud-starter-dalston-4-2/)  

### 特点  

1. 线程池隔离  
> 为每一个``hystrixCommand``创建一个独立的线程池，这样就算某一个在``HystrixCommand``包装下的依赖服务出现延迟过高的情况，也只是对该依赖的服务调用产生影响，并不会拖慢其他服务。 

2. **Hystrix 自动实现了依赖隔离**  
> 使用``HystrixCommand``将某个函数包装成 **Hystrix 命令**时，**Hystrix 框架** 就会自动为这个函数实现**依赖隔离**，所以依赖隔离、服务降级在使用时都是一体化实现的。  
> 这样利用 Hystrix 实现服务容错保护在编程模型上非常方便。


## 服务熔断  

微服务和分布式中，必须考虑容错，一般有**重试机制**和**断路器模式**。   

**重试机制**：对于预期的短暂故障，可以使用重试解决，第一次不成功，再试一次就成功了。  

接下来重点介绍**断路器模式**。   

### 实战演练  

1. 去除超时设置，增加**熔断参数配置**   
> 添加请求参数``number``，为偶数时，直接返回成功；为奇数是，请求``product``服务；  
> 因为删除超时配置，而``product``服务仍然休眠 2 秒，所以，``number=奇数``时，总是跳转到**回退函数**，**触发降级**。  

```java
@RestController
@DefaultProperties(defaultFallback = "defaultFallback")
public class HystrixController {

    @GetMapping("/getProductInfoList")
//    @HystrixCommand(fallbackMethod = "fallback")
    // 超时配置
//    @HystrixCommand(commandProperties = {
//            @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "3000")
//    })
    // 熔断机制
    @HystrixCommand(commandProperties = {
            @HystrixProperty(name = "circuitBreaker.enabled", value = "true"),  // 启动熔断
            @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold", value = "10"),
            @HystrixProperty(name = "circuitBreaker.sleepWindowInMilliseconds", value = "10000"),
            @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage", value = "60"),
    })
    public String getProductInfoList(@RequestParam("number") Integer number) {
        // 如果偶数，请求直接返回成功
        if (number % 2 == 0) {
            return "success";
        }
        // 否则，请求 Product 服务
        RestTemplate restTemplate = new RestTemplate();
        return restTemplate.postForObject("http://127.0.0.1:8081/product/listForOrder",
                Arrays.asList("157875196366160022"),
                String.class);
    }

    private String fallback() {
        return "太拥挤了，请稍后再试";
    }

    private String defaultFallback() {
        return "默认提示：太拥挤了，请稍后再试~~";
    }
}
```
2. 访问：<http://localhost:8082/getProductInfoList?number=1>  
> number=1 时，总是触发降级

![](8)

3. 访问：<http://localhost:8082/getProductInfoList?number=2>  
> number=2 时，总是返回"success"  

![](9)

4. 不断刷新访问：<http://localhost:8082/getProductInfoList?number=1>  
> 根据上面代码设置的``@HystrixProperty(name = "circuitBreaker.errorThresholdPercentage", value = "60")``，降级访问**60%**后  

5. 再访问：<http://localhost:8082/getProductInfoList?number=2>
> 我们发现，number=2 时，也触发了降级  

![](10)

### 断路器模式  

#### 定义  

对于长时间无法解决的故障问题，不断重试是无法解决的。  
**断路器模式**是将受保护的服务封装到可以监控的**断路器对象**里面，当故障达到一定的值，断路器就会“跳闸”，断路对象返回错误。  

1. 断路器模式设计状态机   
> 参考博客[断路器（CircuitBreaker）设计模式](http://blog.sina.com.cn/s/blog_72ef7bea0102vvsn.html)  

> 断路器三种状态：**Closed(关闭)**、**Open(打开)**、**Half Open(半熔断)**;  
> 调用失败累计到达一定域值(或者一定比例)，就会启动熔断机制[open]，此时对服务都直接返回错误；  
> 但设计了一个默认的**时钟选项**，到了这个时间后，就会进入**半熔断**状态，允许定量的服务请求，如果调用都成功或一定比例成功，则认为恢复了，就会关闭【close】熔断器；否则又回到【open】状态。

![](11)

#### 重要参数  

从上面实战演示看到，熔断配置的三个重要参数  

```java
(name = "circuitBreaker.requestVolumeThreshold", value = "10");
(name = "circuitBreaker.sleepWindowInMilliseconds", value = "10000");
(name = "circuitBreaker.errorThresholdPercentage", value = "60")
```
1. **CircuitBreaker：断路器**  
> Martin Fowler 解释断路器：<https://martinfowler.com/bliki/?CircuitBreaker.html>  
> 原意是电路上的一种开关，比如保险丝，对电路本身来说，是一种保护机制，当电流过大时，如果不跳闸，就会烧毁电器。  
> 回到微服务``Hystrix``中同理，当某个服务单元发生故障（电器短路），通过断路器故障监控（熔断保险丝），直接切断原来主逻辑电路。 就像上面实战内容里，``number=2``时，不断刷新，一直处于**服务降级**（电器短路）模式，当访问``number=1``时，也会发生**服务降级**。  

2. **circuitBreaker.sleepWindowInMilliseconds**  
> 上一小结提到的**时钟选项**，达到默认的时间后，进入【半熔断】状态；  
> 其中的``window``可以翻译成**时间窗口**，断路器确定是否需要打开统计一些请求和错误数据时，是有一个时间范围的，即**时间窗口**；  
> 当断路器打开，对**主逻辑**进行熔断后，``Hystrix``会启动一个休眠时间窗，在这个时间窗内，**降级逻辑**会成为主逻辑；  
> 休眠时间到期，断路器将会进入【半熔断】状态，释放一次请求到原来的**主逻辑**上，如果这次请求正常返回，断路器将进入【关闭】状态，主逻辑恢复，如果请求异常，断路器将继续进入【打开】状态，休眠时间窗重新计时；  
> 在实战演练中，我们设定了``10000``ms，当休眠时间窗结束之后，断路器进入【half open半熔断】状态，尝试熔断请求命令，如果依然失败，断路器继续进入【open打开】状态，如果成功，就进入【closed关闭】状态。  

3. **circuitBreaker.requestVolumeThreshold**  
> 设置在滚动时间窗口中，断路器的最小请求数。  

4. **circuitBreaker.errorThresholdPercentage**  
> 设置断路器打开，启动服务熔断降级的错误百分比条件，表示在滚动时间窗口中，如果发生10次调用，其中有7次发生异常(70% > 60%)，断路器就会进入【open打开】状态，否则【closed关闭】状态。  
> 




## 监控 (Hystrix Dashboard)




# 参考  

1. [springCloud Finchley 微服务架构从入门到精通【七】断路器 Hystrix(ribbon)](https://segmentfault.com/a/1190000014763791)  
2. 
