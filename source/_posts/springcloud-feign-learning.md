title: Spring Cloud 实战 (四)：Feign--应用通信
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
> SpringCloud目标是微服务架构下的一站式解决方案。  
> SpringCloud微服务架构下，微服务之间使用**HTTP RESTful**方式进行通信，RESTful本身轻量、易用、适用性强，可以很容易的跨语言、跨平台。    

## RPC 

代表：**Dubbo**  
> Dubbo本身就是一个基于RPC的框架，基于Dubbo开发的应用还是要依赖周边的平台与生态。相比其他的RPC框架，Dubbo在服务治理集成上非常完善，不仅提供了**服务注册发现**，**负载均衡**，**路由**等面向**分布式系统**的基础能力，还涉及了面向开发测试阶段**MOCK**等机制，同时也提供了服务治理的可监控可视化平台。    

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

> 启动order、product服务，访问地址``http://localhost:8081/getProductMsg``，成功调用远程服务Product。    
![](http://p8hqd7oln.bkt.clouddn.com/18-5-21/11377641.jpg)

## Feign  

在学习Feign之前，首先学习一下[Spring Cloud负载均衡器Ribbion]()。  

### 引入Feign  

> order项目中引入feign  

* pom.xml：添加依赖  
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-feign</artifactId>
</dependency>
```

* OrderApplication.java：启动类添加注解**EnableFeignClients**开启Feign    
```java
@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
public class OrderApplication {

	public static void main(String[] args) {
		SpringApplication.run(OrderApplication.class, args);
	}
}
```

### 定义调用的接口  

> 看似和服务端Product的接口类似，只是在**客户端**声明了你需要调用的**服务端**的方法的接口  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-21/47328269.jpg)

* ProductClient.java  
```java
/**
 * 功能描述: 调用远程服务的接口列表
 */
@FeignClient(name = "product")
public interface ProductClient {

    @GetMapping("/msg")
    String productMsg();
}
```

### 调用接口  

* ClientFeignController.java  
```java
/**
 * 功能描述: Feign调用远程服务Product
 */
@Slf4j
@RestController
public class ClientFeignController {

    @Autowired
    private ProductClient productClient;

    @GetMapping("/getProductMsgByFeign")
    public String getProductMsg() {
        String response = productClient.productMsg();
        log.info("response={}", response);
        return response;
    }
}
```

## Feign特点  

**Feign内部使用了Ribbion负载均衡**，从上面实战测试可以总结一下几点：  

* **声名式REST客户端（伪RPC）**   
> 感觉是在用RPC，完全感觉不到这是远程方法，更感知不到这是一个Http请求，但Feign本质还是Http客户端，通过Feign把Http远程调用对开发者完全透明，得到**与调用本地方法**一致的编码体验。  

* **采用基于接口的注解**  
> 定义接口(ProductClient)，在接口里添加注解  

