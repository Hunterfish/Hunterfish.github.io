---
title: java优秀的开源项目和博客
date: 2018-07-25 14:28:21
categories: 总结大全
tags:
  - 总结
  - 面试
---

# github  

## 文档知识  

1. [后端架构师技术图谱(architect-awesome)](https://github.com/xingshaocheng/architect-awesome)  

2. [Java核心知识库(JCSprout)](https://github.com/crossoverJie/JCSprout)  

3. [java面试指南(JavaGuide)](https://github.com/Snailclimb/JavaGuide)  

## 开源项目  

### Java垂直爬虫框架(Web Magic)  
[Java垂直爬虫框架(Web Magic)](https://github.com/code4craft/webmagic/blob/master/README-zh.md)  

### Spring Cloud + Vue + oAuth2.0商城(paascloud-master)
[Spring Cloud + Vue + oAuth2.0商城(paascloud-master)](https://github.com/paascloud/paascloud-master)  

### 基于可靠消息最终一致性分布式事务框架(myth)  
[基于可靠消息最终一致性分布式事务框架(myth)](https://github.com/yu199195/myth)  

#### 项目demo流程  

> ``MythMqReceiveServiceImpl.java``: ReentrantLock  

* 订单支付分布式事务流程  

1. service层 ``PaymentServiceImpl.java``
```java
    @Override
    @Myth(destination = "")
    public void makePayment(Order order) {
      // 扣除余额
      // 扣减库存
    }
```

2. 因为上面service有 ``@Myth`` 注解，该注解使用了 ``Aop`` 切面拦截该注解  ``AbstractMythTransactionAspect.java``  
spirng aop AspectJ参考：[Spring 之AOP AspectJ切入点语法详解](https://blog.csdn.net/zhengchao1991/article/details/53391244)  
```java
    @Pointcut("@annotation(com.github.myth.annotation.Myth)")
    public void mythTransactionInterceptor() {

    }

    /**
     * this is around in {@linkplain com.github.myth.annotation.Myth }.
     * @param proceedingJoinPoint proceedingJoinPoint
     * @return Object
     * @throws Throwable  Throwable
     */
    @Around("mythTransactionInterceptor()")
    public Object interceptMythAnnotationMethod(final ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
        return mythTransactionInterceptor.interceptor(proceedingJoinPoint);
    }
```

3. ``Aop``拦截器对事务进行处理，判断事务角色是否是发起者、本地执行或者提供者``
> 此处事务已经发起，返回``StartMythTransactionHandler.java``  
![](1)  
```java
@Component
public class MythTransactionFactoryServiceImpl implements MythTransactionFactoryService {

    private final MythTransactionEngine mythTransactionEngine;

    @Autowired
    public MythTransactionFactoryServiceImpl(final MythTransactionEngine mythTransactionEngine) {
        this.mythTransactionEngine = mythTransactionEngine;
    }

    // 判断事务类型并返回相应事务处理类
    @Override
    public Class factoryOf(final MythTransactionContext context) throws Throwable {
        //如果事务还没开启或者 myth事务上下文是空， 那么应该进入发起调用
        if (!mythTransactionEngine.isBegin() && Objects.isNull(context)) {
            return StartMythTransactionHandler.class;
        } else {
            if (context.getRole() == MythRoleEnum.LOCAL.getCode()) {
                return LocalMythTransactionHandler.class;
            }
            return ActorMythTransactionHandler.class;
        }
    }
}
```
```java
@Component
public class MythTransactionAspectServiceImpl implements MythTransactionAspectService {

    private final MythTransactionFactoryService mythTransactionFactoryService;

    @Autowired
    public MythTransactionAspectServiceImpl(final MythTransactionFactoryService mythTransactionFactoryService) {
        this.mythTransactionFactoryService = mythTransactionFactoryService;
    }

    @Override
    @SuppressWarnings("unchecked")
    public Object invoke(final MythTransactionContext mythTransactionContext, final ProceedingJoinPoint point) throws Throwable {
        // 返回相应事务
        final Class clazz = mythTransactionFactoryService.factoryOf(mythTransactionContext);
        final MythTransactionHandler mythTransactionHandler = (MythTransactionHandler) SpringBeanUtils.getInstance().getBean(clazz);
        // 处理相应事务（该流程下事务已经开始，进入StartMythTransactionHandler.java）
        return mythTransactionHandler.handler(point, mythTransactionContext);
    }
}
```

4. 处理事务：``StartMythTransactionHandler.handler()``  

```java
    public Object handler(final ProceedingJoinPoint point, final MythTransactionContext mythTransactionContext) throws Throwable {
        try {
            // 异步保存事务
            mythTransactionEngine.begin(point);
            final Object proceed = point.proceed();
            mythTransactionEngine.updateStatus(MythStatusEnum.COMMIT.getCode());
            return proceed;
        } catch (Throwable throwable) {
            //更新失败的日志信息
            mythTransactionEngine.failTransaction(throwable.getMessage());
            throw throwable;
        } finally {
            //发送消息
            mythTransactionEngine.sendMessage();
            mythTransactionEngine.cleanThreadLocal();
            TransactionContextLocal.getInstance().remove();
        }
    }
```

#### 订单支付流程异常处理  

* 下订单业务逻辑  
```java
@Override
    @Myth(destination = "")
    public void makePayment(Order order) {
        //检查数据 这里只是demo 只是demo 只是demo
        // 省略...
        // 1. 本地事务：更新订单
        order.setStatus(OrderStatusEnum.PAY_SUCCESS.getCode());
        orderMapper.update(order);
        // 2. 远程事务：扣除用户余额
        AccountDTO accountDTO = new AccountDTO();
        accountDTO.setAmount(order.getTotalAmount());
        accountDTO.setUserId(order.getUserId());
        accountClient.payment(accountDTO);

        // 3. 远程事务：进入扣减库存操作
        InventoryDTO inventoryDTO = new InventoryDTO();
        inventoryDTO.setCount(order.getCount());
        inventoryDTO.setProductId(order.getProductId());
        inventoryClient.decrease(inventoryDTO);
    }
```

##### 停掉Invertory库存服务  

承接上一节内容，此时如果在``第3步``扣库存时停掉``invertory``微服务，会发现之前执行的**订单更新**、远程服务的**扣除余额**操作都已经正常完成；
而库存并没有减掉，再次重新启动``invertory``服务，发现会自动执行未完成事务，完成扣库存操作。  

1. 重启``invertory``服务时，会经过``SpringCloudMythTransactionInterceptor.interceptor()``执行事务补偿。  

##### 停掉Order服务  

如果上面再``第2步``停掉``order``服务，``order``服务会执行完该业务方法，即完成``2、3步``。不会造成分布式事务问题。  

##### 停掉消息服务RabbitMQ  

* ```MythInitServiceImpl.java```: 通过线程池调动一直重试恢复
```java
    @Override
    public void initialization(final MythConfig mythConfig) {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> LOGGER.error("myth have error!")));
        try {
            loadSpiSupport(mythConfig);
            // 启动disruptor
            publisher.start(mythConfig.getBufferSize());
            coordinatorService.start(mythConfig);
            // (事务发起者)如果需要自动恢复 开启线程 调度线程池，进行恢复
            if (mythConfig.getNeedRecover()) {
                scheduledService.scheduledAutoRecover(mythConfig);
            }
        } catch (Exception ex) {
            LogUtil.error(LOGGER, "Myth init fail:{}", ex::getMessage);
            //非正常关闭
            System.exit(1);
        }
        LogUtil.info(LOGGER, () -> "Myth init success");
    }
```



#### Disruptor(无锁并行计算框架)  

在无锁的情况下实现网络的Queue并发操作，高性能的异步事件驱动型的处理框架，或者可以认为是最快的消息框架（轻量的JMS），也可以认为是一个观察者模式的实现，或者事件监听模式的实现。  

典型的**生产者-消费者**模式，disruptor使用RingBuffer存放数据，sequence管理生产和消费的位置（long类型，递增），生产者要生产数据的时候首先向生产者请求一个sequence，然后在sequence的位置放置数据。  


参考博客：[架构师养成记--15.Disruptor并发框架](https://www.cnblogs.com/sigm/p/6251910.html)  

* 项目使用流程总结  
> ``MythTransactionBootStrap.java``启动类中初始化启动了``Disruptor``，当然还启动了其他配置。  
```java
private void start(final MythConfig mythConfig) {
    mythInitService.initialization(mythConfig);
}
```
```java
// MythInitServiceImpl.java
@Override
public void initialization(final MythConfig mythConfig) {
    Runtime.getRuntime().addShutdownHook(new Thread(() -> LOGGER.error("myth have error!")));
    try {
        loadSpiSupport(mythConfig);
        // 启动disruptor
        // bufferSize，RingBuffer大小，必须是2的N次方
        publisher.start(mythConfig.getBufferSize());
        coordinatorService.start(mythConfig);
        //(事务发起者)如果需要自动恢复 开启线程 调度线程池，进行恢复
        if (mythConfig.getNeedRecover()) {
            scheduledService.scheduledAutoRecover(mythConfig);
        }
    } catch (Exception ex) {
        LogUtil.error(LOGGER, "Myth init fail:{}", ex::getMessage);
        //非正常关闭
        System.exit(1);
    }
    LogUtil.info(LOGGER, () -> "Myth init success");
}
```

1. 建立``Event``类（数据对象）  
> 事务对象  
```java
@Data
public class MythTransactionEvent implements Serializable {

    private MythTransaction mythTransaction;

    private int type;

    /**
     * help gc.
     */
    public void clear() {
        mythTransaction = null;
    }
}
```

2. 建立一个生产数据的工厂类，``EventFactory``，用于生产数据  
```java
public class MythTransactionEventFactory implements EventFactory<MythTransactionEvent> {

    @Override
    public MythTransactionEvent newInstance() {
        return new MythTransactionEvent();
    }
}
```

3. 监听事件类（处理Event数据）   
> 监听策略  
```java
  // BlockingWaitStrategy 是最低效的策略，但其对CPU的消耗最小并且在各种不同部署环境中能提供更加一致的性能表现
  WaitStrategy BLOCKING_WAIT = new BlockingWaitStrategy();

  // SleepingWaitStrategy 的性能表现跟BlockingWaitStrategy差不多，对CPU的消耗也类似，但其对生产者线程的影响最小，适合用于异步日志类似的场景
  WaitStrategy SLEEPING_WAIT = new SleepingWaitStrategy();

  // YieldingWaitStrategy 的性能是最好的，适合用于低延迟的系统。在要求极高性能且事件处理线数小于CPU逻辑核心数的场景中，推荐使用此策略；例如，CPU开启超线程的特性
  WaitStrategy YIELDING_WAIT = new YieldingWaitStrategy();
```

4. 实例化Disruptor，配置参数，绑定事件  
> ``MythTransactionEventPublisher.java``  
```java
public void start(final int bufferSize) {
    // 创建 disruptor
    // 使用 BlockingWatiStrategy 策略
    // ProducerType: MULTI(多个生产者), SINGLE(单个生产者)
    disruptor = new Disruptor<>(new MythTransactionEventFactory(), bufferSize, r -> {
        AtomicInteger index = new AtomicInteger(1);
        return new Thread(null, r, "disruptor-thread-" + index.getAndIncrement());
    }, ProducerType.MULTI, new BlockingWaitStrategy());

    // 消费者缓存池构建
    final Executor executor = new ThreadPoolExecutor(MAX_THREAD, MAX_THREAD, 0, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<>(),
            MythTransactionThreadFactory.create("myth-log-disruptor", false),
            new ThreadPoolExecutor.AbortPolicy());

    MythTransactionEventHandler[] consumers = new MythTransactionEventHandler[MAX_THREAD];
    for (int i = 0; i < MAX_THREAD; i++) {
        consumers[i] = new MythTransactionEventHandler(coordinatorService, executor);
    }
    // 连接消费者的方法
    disruptor.handleEventsWithWorkerPool(consumers);
    disruptor.setDefaultExceptionHandler(new IgnoreExceptionHandler());
    // 启动
    disruptor.start();
}

```

5. 事件发布  
> 建存放数据的核心 RingBuffer，生产的数据放入 RungBuffer，本项目中就是各种类型的事务。参考上面的**订单支付分布式事务流程**的第
4步，处理``Start``类型事务。  
```java
// StartMythTransactionHandler.java  
@Override
public Object handler(final ProceedingJoinPoint point, final MythTransactionContext mythTransactionContext) throws Throwable {
    try {
        // 此处发布了（生产者数据）事务
        mythTransactionEngine.begin(point);
        final Object proceed = point.proceed();
        mythTransactionEngine.updateStatus(MythStatusEnum.COMMIT.getCode());
        return proceed;
    } catch (Throwable throwable) {
        //更新失败的日志信息
        mythTransactionEngine.failTransaction(throwable.getMessage());
        throw throwable;
    } finally {
        //发送消息
        mythTransactionEngine.sendMessage();
        mythTransactionEngine.cleanThreadLocal();
        TransactionContextLocal.getInstance().remove();
    }
}
```
```java
// MythTransactionEngine.java
public void begin(final ProceedingJoinPoint point) {
    LogUtil.debug(LOGGER, () -> "开始执行Myth分布式事务！start");
    MythTransaction mythTransaction = buildMythTransaction(point, MythRoleEnum.START.getCode(), MythStatusEnum.BEGIN.getCode(), "");
    // 发布事务保存事件，异步保存
    publishEvent.publishEvent(mythTransaction, EventTypeEnum.SAVE.getCode());
    // 当前事务保存到ThreadLocal
    CURRENT.set(mythTransaction);
    // 设置tcc事务上下文，这个类会传递给远端
    MythTransactionContext context = new MythTransactionContext();
    // 设置事务id
    context.setTransId(mythTransaction.getTransId());
    // 设置为发起者角色
    context.setRole(MythRoleEnum.START.getCode());
    TransactionContextLocal.getInstance().set(context);
}

// MythTransactionEventPublisher.java
public void publishEvent(final MythTransaction mythTransaction, final int type) {
    final RingBuffer<MythTransactionEvent> ringBuffer = disruptor.getRingBuffer();
    ringBuffer.publishEvent(new MythTransactionEventTranslator(type), mythTransaction);
}
```


6. 消费者：消费缓存中主动发送给消费端的数据  
> [executor的execute()和submit方法区别](http://san-yun.iteye.com/blog/2072726)  

```java
/**
 * MythTransactionEventHandler.
 *  // 事件消费者，也就是一个事件处理器
 * @author xiaoyu(Myth)
 */
public class MythTransactionEventHandler implements WorkHandler<MythTransactionEvent> {

    private final CoordinatorService coordinatorService;

    private Executor executor;

    public MythTransactionEventHandler(final CoordinatorService coordinatorService,
                                       final Executor executor) {
        this.coordinatorService = coordinatorService;
        this.executor = executor;
    }

    // 根据EventTypeEnum事务类型不同处理
    @Override
    public void onEvent(final MythTransactionEvent mythTransactionEvent) {
        executor.execute(() -> {
            if (mythTransactionEvent.getType() == EventTypeEnum.SAVE.getCode()) {
                coordinatorService.save(mythTransactionEvent.getMythTransaction());
            } else if (mythTransactionEvent.getType() == EventTypeEnum.UPDATE_PARTICIPANT.getCode()) {
                coordinatorService.updateParticipant(mythTransactionEvent.getMythTransaction());
            } else if (mythTransactionEvent.getType() == EventTypeEnum.UPDATE_STATUS.getCode()) {
                final MythTransaction mythTransaction = mythTransactionEvent.getMythTransaction();
                coordinatorService.updateStatus(mythTransaction.getTransId(), mythTransaction.getStatus());
            } else if (mythTransactionEvent.getType() == EventTypeEnum.UPDATE_FAIR.getCode()) {
                coordinatorService.updateFailTransaction(mythTransactionEvent.getMythTransaction());
            }
            mythTransactionEvent.clear();
        });
    }
}
```

#### Feign源码  

[feign源码解析](http://techblog.ppdai.com/2018/05/14/20180514/)  

* 设计模式：建造者模式   



### netty系列  

1. [Netty 4.x 用户指南(netty-4-user-guide)](https://github.com/waylau/netty-4-user-guide)  

2. [基于netty的IM服务器(face2face)](https://github.com/a2888409/face2face)  

3. [MPush推送系统(mpush)](https://github.com/mpusher/mpush)  

4. [基于netty构建RPC系统(NettyRPC)](https://github.com/tang-jie/NettyRPC)  

5. [芋艿源码解读(netty)](https://github.com/YunaiV/netty)  


# 博客大佬  

1. [crossoverJie's Blog](https://crossoverjie.top/)  





