---
title: Spring Cloud 实战 (七)：使用RabbitMQ实现服务间异步消息调用
date: 2018-05-30 13:20:34
categories: Spring Cloud微服务实战
tags:
  - Spring Boot
  - RabbitMQ
---
# 同步/异步   

多模块化后的**order**订单服务和**product**商品服务之间的通信是同步的，订单会调用商品的扣库存远程服务。  
而异步：**客户端请求不会阻塞进程，服务端的响应可以是非即时的**。  
> http最常见的方式是同步，http也是支持异步调用的  

## 异步常见形态  

### 一对一交互  

1. **通知**  
> 单向请求，你对她放电，她对你绝缘。。  

2. **请求/异步响应**  
> 客户端发送请求到服务端，服务端异步响应请求，客户端不会阻塞，而且被设计成响应不会立刻送达  

### 一对多交互  

1. **消息**  
> 利用消息可以实现一对多形态的交互，比如``发布/订阅``模式下，客户端发送消息通知，被0个或多个感兴趣的服务消费；  
> 再比如客户端发送消息请求，等待服务发回的响应。  

## MQ 应用场景  

1. **异步处理**  
> 比如用户注册后，调用短信服务和积分服务分别执行发短信和加积分操作，注册信息写入数据库后，通过异步消息让短信服务和积分服务去做他们的事，提升用户体验。  

2. **流量削峰**  
> 常见的比如**秒杀**场景，秒杀活动由于流量过大，导致流量暴增，甚至导致应用挂掉，为了解决这种问题，一般会在应用前端加上消息队列，从而控制活动人数；  
> 假如消息队列长度超过最大数量，可以直接拒绝用户请求，提示超出人数信息，或跳转相应的提示页面；  

3. **日志处理**  
> 最典型的就是**Kafka**，**Kafka**消息队列一开始设计就是用于日志处理，大数据应用频繁，通过日志采集定时写入**Kafka**队列，然后消息队列对日志进行接收、储存和转发  

4. 应用解耦  
> 比如用户下单后，订单服务需要通知商品系统，我们之前做的是订单服务需要调用商品服务的接口，订单服务和商品服务是**耦合**的；  
> 下面我们会使用 **MQ** 消息队列，用户下单后，订单服务完成持久化处理，将消息写入消息队列，返回用户订单下单成功，商品服务订阅下单消息，采用推/拉方式获取下单信息，商品系统根据下单信息进行商品库存的操作；  
> 如果下单时，商品服务不能正常工作了，并不会影响正常下单，因为下单后，订单服务写入消息队列后，就不在关心后续操作，这样就实现订单服务和商品服务的应用解耦了。  

## RabbitMQ初步使用  

### 消息中间件的选择  

* **RabbitMQ**  
* **Kafka**  
* **ActiveMQ**   

### RabbitMQ安装运行  

参考博客[]()  

### 项目实战  

#### 场景分析  

1. 订单服务可以同时处理**数码商品**、**水果商品**两种订单；  
2. 订单服务根据不同的商品类型发送不同的``mq``消息，相对应的，**数码供应商**只关心数码产品订单，**水果供应商**也是一样；  
3. 就是``rabbitmq``的消息分组！  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-6/46186534.jpg)

#### 代码  

1. **pom.xml【server子模块】**  
> 上一章中已经添加过了，rabbitmq依赖``spring-cloud-stream-binder-rabbit``  
> 其实是 spring cloud 的 ``stream``组件，将在下章中介绍  

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-bus</artifactId>
</dependency>
```

2. **bootstrap.yml**  
> 添加 rabbitmq 配置   
> 如果你的 rabbitmq 默认启动，没有修改配置，下面的配置信息不用添加，Spring Cloud 默认使用 RabbitMQ  

```yaml
spring:
  cloud:
    config:
      name: order
      profile: test
      lable: master
      discovery:
        enabled: true   # 开启config服务发现支持
        service-id: config
  rabbitmq:
    host: localhost
    port: 5672
    username: guest
    password: guest
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

3. **MqReceiver.java**  
> **order**服务中新建接受 MQ 消息的类;  
> 注解``@RabbitListener``  
> 关键字``exchange``  
> 关键字``key``  
> 关键字``value``  

```java
@Slf4j
@Component
public class MqReceiver {

    // 1. 需要手动在rabbitmq控制台上新建队列 @RabbitListener(queues = "myQueue")
    // 2. 自动创建队列 @RabbitListener(queuesToDeclare = @Queue("myQueue"))
    // 3. 自动创建，Exchange和queue绑定
    @RabbitListener(bindings = @QueueBinding(
            value = @Queue("myQueue"),
            exchange = @Exchange("myExchange")
    ))
    public void process(String message) {
        log.info("MqReceiver: {}", message);
    }

    /**
     * 数码供应商服务  接受消息
     * @param message
     */
    @RabbitListener(bindings = @QueueBinding(
            exchange = @Exchange("myOrder"),
            key = "computer",
            value = @Queue("computerOrder")
    ))
    public void processComputer(String message) {
        log.info("MqReceiver: {}", message);
    }

    /**
     * 水果供应商服务  接受消息
     * @param message
     */
    @RabbitListener(bindings = @QueueBinding(
            exchange = @Exchange("myOrder"),
            key = "fruit",
            value = @Queue("fruitOrder")
    ))
    public void processFruit(String message) {
        log.info("MqReceiver: {}", message);
    }
}
```

4. **MqServerTest.java**  
> 测试类，MQ服务端发送消息  
> 注入``AmqpTemplate``  

```java
@Component
public class MqServerTest extends OrderApplicationTests {

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Test
    public void send() {
        amqpTemplate.convertAndSend("myQueue", "now: " + new Date());
    }

    @Test
    public void sendOrder() {
        amqpTemplate.convertAndSend("myOrder", "fruit", "now: " + new Date());
    }
}
```

5. **启动 eureka、config、order**  
> 运行测试类``MqServerTest.java``的 **sendOrder()** 方法  
> console控制台打印``fruit``发送的队列消息    

```java
2018-06-06 13:28:00.618  INFO 4192 --- [cTaskExecutor-1] cn.hunter.order.message.MqReceiver       : fruit receive: now: Wed Jun 06 13:28:00 CST 2018
```
6. **RabbitMQ 控制面板**  

![](http://p8hqd7oln.bkt.clouddn.com/18-6-6/28043517.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-6-6/7823441.jpg)

## 点餐项目分析  

1. **用户服务**  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/10741821.jpg)

> **用户服务**在用户登录时，会调用**短信服务**给用户发短信；登录操作可能会调用**积分服务**给用户加积分；等等调用其他服务。  

> 如果上面都采用同步通信机制，服务之间耦合过大，用户登录过程需要多个服务同时响应成功才能成功，造成不好的用户体验；  

> 我们可以通过消息队列解决上面问题。  

2. **本项目订单/商品服务**   

![](http://p8hqd7oln.bkt.clouddn.com/18-5-30/23312725.jpg)

> **订单服务**在扣库存前先调用**商品服务**查询商品信息接口，之后再调用减库存接口进行减库存操作；  

> 如果我们改造成：**商品服务**在更改库存后发布消息【库存变化】，**订单服务**订阅此消息，获取商品的具体信息，比如可购买商品的个数、商品ID等； 
**订单服务**在下单时，不会去**商品服务**调用查询商品信息接口，而是在本服务中查询了；  

> 然后**订单服务**在扣库存时，发布消息【扣库存】，**商品服务**订阅此消息，读取消息后，减少对应商品的库存量；  

> 支付成功/失败也会对库存有影响：具体看业务设计，比如设置30分钟后如果未支付，由**支付服务**发布消息，**商品服务**和**订单服务**同时订阅此消息， 
就能够保证数据的最终一致性。  

> 再通俗讲，比如**用户服务**购买商品后，业务上还要给用户加积分，发短信，此时，**订单服务**不需要修改，**短信服务**和**积分服务**只要也订阅了消息， 
相应的积分、短信就可以实现。 


# 订单/商品同步改为异步消息调用  

