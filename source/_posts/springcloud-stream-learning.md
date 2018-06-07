---
title: Spring Cloud 实战 (十一)：Stream--消息驱动组件
date: 2018-06-06 14:01:10
categories:
  - Spring Cloud微服务实战
tags:
  - Spring Cloud
  - Stream
---

上一篇文章主要介绍了消息总线，本篇文章介绍 Spring Cloud 组件``Stream``，结合点餐项目中``订单服务``和``商品服务``的下订单减库存业务，使用``RabbitMQ``异步通知。  

# Stream 组件简介  

操作消息队列的一种方法，是 Spring Cloud 的一种组件之一，**为微服务应用构建消息驱动能力的框架**。  

## 分析  

1. 应用程序通过``inputs``或者``outputs``来与``Stream``中的``Binder``交互；  
2. 而``Binder``来与``Middleware``中间件交互；  
3. ``Binder``是``Stream``的一种抽象概念，是应用与消息中间件的粘合剂（binder中文就是这个意思）；  
4. 使用``Stream``最大的方便之处就是：对消息中间件的进一步封装，可以做到代码层面对中间件的无感知，甚至于动态的切换中间件，切换 Topic;  
5. ``Stream``局限：目前的``Binder``只支持``RabbitMQ``和``Kafka``这两种。  

![](1)

# 实战使用  

参考博客[Spring Cloud整合RabbitMQ或Kafka消息驱动(二十二)](https://blog.csdn.net/mrspirit/article/details/80574164)  

## 点餐业务中使用  RabbitMQ   

* 在**商品服务**和**订单服务**中使用MQ；  
* **商品服务**一旦有库存变化，就会发布消息，**订单服务**接收到消息后，会把库存的数据记录到自己的服务里，这里我们把数据存到``redis``里；  
* 导致库存变化的情形有第一次商品上架、商品卖完补货、下订单时等等；  
* 下面演练当**商品服务**扣库存时使用MQ消息。  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/23312725.jpg)

## 安装运行 Redis

参考[Spring Cloud 基础篇 (二)：Docker 环境下安装 Redis]()

## product  

### product 初始化  

> 之前学习``config``、``bus``组件都是在**订单服务** order 中实现的，现在在**商品服务** product 中添加 ``config``、``bus``组件。  

1. **pom.xml**  
> product 的 server 子模块  

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-config-client</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-stream-rabbit</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
    <dependency>
        <groupId>cn.hunter</groupId>
        <artifactId>product-common</artifactId>
    </dependency>
    <dependency>
        <groupId>com.google.code.gson</groupId>
        <artifactId>gson</artifactId>
    </dependency>
</dependencies>
```

2. **bootstrap.yml**  
> server 子模块  

```yaml
spring:
  application:
    name: product
  cloud:
    config:
      discovery:
        enabled: true
        service-id: CONFIG
      profile: dev
eureka:
  instance:
    prefer-ip-address: true
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

### 添加 MQ 消息队列  

1. **pom.xml**  
> 上一小节已将添加，``spring-cloud-starter-stream-rabbit``stream rabbitmq 依赖。  

2. **ProductServiceImpl.java**  
> 注入 **AmqpTemplate**;  
> 添加消息队列名``productInfo``;  
> Lambda表达式学习使用！！  

```java
@Service
public class ProductServiceImpl implements ProductService {

    @Autowired
    private ProductInfoRepository productInfoRepository;

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Override
    public List<ProductInfo> findUpAll() {
        return productInfoRepository.findByProductStatus(ProductStatusEnum.UP.getCode());
    }

    @Override
    public List<ProductInfo> findList(List<String> productIdList) {
        return productInfoRepository.findByProductIdIn(productIdList);
    }

    @Override

    public void decreaseStock(List<DecreaseStockInput> decreaseStockInputList) {

        List<ProductInfo> productInfoList = decreaseStockProcess(decreaseStockInputList);

        // 发送mq消息：扣库存
        List<ProductInfoOutput> productInfoOutputList = productInfoList.stream().map(e -> {
            ProductInfoOutput output = new ProductInfoOutput();
            BeanUtils.copyProperties(e, output);
            return output;
        }).collect(Collectors.toList());
        amqpTemplate.convertAndSend("productInfo", JsonUtil.toJson(productInfoOutputList));
    }

    @Transactional
    public List<ProductInfo> decreaseStockProcess(List<DecreaseStockInput> DecreaseStockInputList) {
        List<ProductInfo> productInfoList = new ArrayList<>();
        for (DecreaseStockInput cartDTO : DecreaseStockInputList) {
            Optional<ProductInfo> productInfoOptional = productInfoRepository.findById(cartDTO.getProductId());
            // 判断商品是否存在
            if (!productInfoOptional.isPresent()) {
                throw new ProductException(ResultEnum.PRODUCT_NOT_EXIST);
            }
            // 判断商品库存是否足够
            ProductInfo productInfo = productInfoOptional.get();
            Integer result = productInfo.getProductStock() - cartDTO.getProductQuantity();
            if (result < 0) {
                throw new ProductException(ResultEnum.PRODUCT_STOCK_ERROR);
            }
            productInfo.setProductStock(result);
            productInfoRepository.save(productInfo);
            productInfoList.add(productInfo);
        }
        return productInfoList;
    }
}
```

## order  

1. **pom.xml**  
> server子模块引入 redis 依赖``spring-boot-starter-data-redis``  

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

2. **order-dev.yml**  
> github 远端``config-server``git 仓库添加redis配置信息    

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    username: root
    password: root
    url: jdbc:mysql://localhost:3306/SpringCloud_Sell?characterEncoding=utf-8&useSSL=false
rabbitmq:
    host: localhost
    port: 5672
    username: guest
    password: guest
redis:
    host: localhost
    port: 6379
jpa:
    show-sql: true
```

1. **ProductInfoReceiver.java**  
> 接收商品服务 mq 消息；  

```java
@Slf4j
@Component
public class ProductInfoReceiver {

    private static final String PRODUCT_STOCK_TEMPLATE = "product_stock_%s";

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @RabbitListener(queuesToDeclare = @Queue("productInfo"))
    public void process(String message) {
        // message => ProductInfoOutput
        List<ProductInfoOutput> productInfoOutputList = (List<ProductInfoOutput>)JsonUtil.fromJson(message,
                new TypeReference<List<ProductInfoOutput>>() {});
        log.info("从队列【{}】接收到的消息：{}", "productInfo", productInfoOutputList);

        // 消息存储到redis中
        for (ProductInfoOutput productInfoOutput : productInfoOutputList) {
            stringRedisTemplate.opsForValue().set(String.format(PRODUCT_STOCK_TEMPLATE, productInfoOutput.getProductId()),
                    String.valueOf(productInfoOutput.getProductStock()));
        }
    }
}
```

## 测试  

1. docker 运行``rabbitmq``、``redis``

2. 运行``eureka``、``config``、``product``、``order``服务；  

3. ``postman``发送**减库存** post 请求  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/51640506.jpg)

4. 登陆 RabbitMQ 控制面板 <http://localhost:15672>  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/22385442.jpg)

5. ``order``控制台打印输出信息    

```java
2018-06-07 11:34:07.500  INFO 12052 --- [cTaskExecutor-1] c.h.order.message.ProductInfoReceiver    : 从队列【productInfo】接收到的消息：[ProductInfoOutput(productId=157875196366160022, productName=皮蛋粥, productPrice=0.01, productStock=26, productDescription=好吃的皮蛋粥, productIcon=//fuss10.elemecdn.com/0/49/65d10ef215d3c770ebb2b5ea962a7jpeg.jpeg, productStatus=0, categoryType=1)]
```

6. Redis 存储库存数据  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-7/18484580.jpg)





