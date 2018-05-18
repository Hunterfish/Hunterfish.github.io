title: Spring Cloud Feign--应用通信
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Feign
date: 2018-05-15 09:01:00
---
# 应用间通信方式  

> 主要有两种: HTTP, RPC  

## HTTP  
代表：**Spring Cloud**。  
SpringCloud目标是微服务架构下的一站式解决方案。
SpringCloud微服务架构下，微服务之间使用**HTTP RESTful**方式进行通信，RESTful本身轻量、易用、适用性强，可以很容易的跨语言、跨平台。  

## RPC 

代表：**Dubbo**  
Dubbo本身就是一个基于RPC的框架，基于Dubbo开发的应用还是要依赖周边的平台与生态。相比其他的RPC框架，Dubbo在服务治理集成上非常完善，不仅提供了**服务注册发现**，**负载均衡**，**路由**等面向**分布式系统**的基础能力，还涉及了面向开发测试阶段**MOCK**等机制，同时也提供了服务治理的可监控可视化平台。  

# Spring Cloud RESTful调用方式  

## RestTemplate  

RestTemplate是一个Http客户端，功能和Java框架中的HttpClient差不多，用法更简单。  

下面使用订单服务调用商品服务演示RestTemplate的三种使用方式。  

### 第一种：直接使用restTemplate, url写死  

> 不知道对方ip，这种方式写死Url，非常不好。  

* product服务：ServerController.java  
```java
@RestController
public class ServerController {

    // 测试服务
    @GetMapping("/msg")
    public String msg() {
        return "this is product' msg";
    }
}
```

* order服务：ClientController.java  
```java
@Slf4j
@RestController
public class ClientController {

    @Autowired
    private RestTemplate restTemplate;


    @GetMapping("/getProductMsg")
    public String getProductMsg() {
        // 调用远程服务
        // 1. 第一种方式（直接使用restTemplate, url写死）
        RestTemplate restTemplate = new RestTemplate();
        String response = restTemplate.getForObject("http://localhost:8080/msg", String.class);
        
        log.info("response={}", response);
        return response;
    }
}
```
### 第二种方式：loadBalancerClient  

> 利用loadBalancerClient通过应用名称获取url（ip地址和端口），然后在使用restTemplate  

* order服务：ClientController.java  
```java
@Slf4j
@RestController
public class ClientController {

    @Autowired
    private LoadBalancerClient loadBalancerClient;

    @GetMapping("/getProductMsg")
    public String getProductMsg() {
        // 调用远程服务
        // 2. 第二种方式（利用loadBalancerClient通过应用名称获取url，然后在使用restTemplate）
        RestTemplate restTemplate = new RestTemplate();
        ServiceInstance serviceInstance = loadBalancerClient.choose("PRODUCT");
        String url = String.format("http://%s:%s", serviceInstance.getHost(), serviceInstance.getPort()) + "/msg";
        String response = restTemplate.getForObject(url, String.class);

        log.info("response={}", response);
        return response;
    }
}
```

### 第三种方式  

> 利用@LoadBalanced，可在restTemplate里使用应用名称"PRODUCT"  

* 创建RestTemplate配置类：  
> 重点注解**@LoadBalanced**  
```java
@Component
public class RestTemplateConfig {

    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```
* order服务：ClientController.java  
```java
@Slf4j
@RestController
public class ClientController {

    @Autowired
    private RestTemplate restTemplate;


    @GetMapping("/getProductMsg")
    public String getProductMsg() {
        // 调用远程服务       
        // 3. 第三种方式（利用@LoadBalanced，可在restTemplate里使用应用名称"PRODUCT"）
        String response = restTemplate.getForObject("http://PRODUCT/msg", String.class);
        log.info("response={}", response);
        return response;
    }
}

```

### 测试  

启动order、product服务，访问地址：http://localhost:8081/getProductMsg，成功调用远程服务Product。  
![](1)  



## Feign  

在学习Feign之前，首先学习一下[Spring Cloud负载均衡器Ribbion]()