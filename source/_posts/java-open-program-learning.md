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

### 高性能异步分布式事务TCC框架  

[高性能异步分布式事务TCC框架（try/confirm/cancel）](https://github.com/yu199195/hmily)  

# 开源项目讲解  

## Hmily项目demo流程  

1. aop  
> 根据添加的注解进行aop处理  

2. rpc框架特性  
> 在调用远程服务的接口前，获取所调用的方法签名  

3. rpc框架参数传递  
> 通过ThreadLocal保存事务上下文信息，进行参数传递  

4. 事务日志，到底存储了什么东西？怎么存储的，怎么序列化的？  
> 采用``disruptor``进行事务日志异步读写，与rpc框架性能毫无差别

5. 定时事务补偿  
> 使用jdk的``ScheduledExecutorService.scheduleWithFixedDelay()``，主要作用将定时任务和线程池功能结合使用。  
> 参考：[Thread之ScheduledExecutorService的使用](https://www.cnblogs.com/huhx/p/baseusejavaScheduledExecutorService.html)  
> 解决集群下重复执行问题，可以使用[redis分布式锁](https://blog.csdn.net/quwenzhe/article/details/78865875)解决，redis的命令``setnx``实现：当网redis中存入一个值时，会先判断该值对应的key是否存在，如果存在则返回0，如果不存在，则将该值存入redis并返回1。  
> 根据上面的特性，我们在执行任务的程序中，每次都调用``setIfAbsent(该方法时setnx命令的实现)``方法，来模拟是否获取到锁，如果返回true，则说明key值不存在，表示获取到锁；如果返回false，则说明key值已存在，已经有程序使用这个key了，从而实现类似加锁的功能。  

6. 高效并发  
> 单机 **2000** 并发，可以通过[jmeter压测](http://www.cnblogs.com/yangxia-test/p/3964881.html)  
> 因为目前是异步的存储日志到mysql，会有限制，使用``mongo``集群，很快  

7. TCC缺点  
> 代码量多，try、confirm、cancel三个方法，使用者需要知道confirm、cancel方法的正确书写，使用场景有限。  
> 事务日志需要记录：推荐使用高效的存储，推荐使用mongo集群，kroy序列化  

8. TCC优点  
> 天然支持集群，不依赖于事务；  
> 依赖事务日志，最终一致性

### 使用技术  

#### mysql乐观锁  

目的：解决高并发。  

参考：[APP大规模高并发请求和抢购的架构与解决方案](https://www.cnblogs.com/jurendage/p/9232173.html)  

在**定时事务补偿**补偿中，对于事务异常记录到数据库中的事务进行补偿重试操作，为避免高并发，采用``mysql乐观锁``机制，采用版本号的形式实现，事务的重试次数即为版本号。  

> 乐观锁，是相对于**悲观锁**采用更为宽松的加锁机制，大都是采用带版本号（Version）更新。实现就是，这个数据所有请求都有资格去修改，但会获得一个该数据的版本号，只有版本号符合的才能重试。  

> 悲观锁，也就是在修改数据的时候，采用锁定状态，排斥外部请求的修改。遇到加锁的状态，就必须等待。
虽然上述的方案的确解决了线程安全的问题，但是，别忘记，我们的场景是“高并发”。也就是说，会很多这样的修改请求，每个请求都需要等待“锁”，某些线程可能永远都没有机会抢到这个“锁”，这种请求就会死在那里。同时，这种请求会很多，瞬间增大系统的平均响应时间，结果是可用连接数被耗尽，系统陷入异常。 

```java
@Override
public int update(final TccTransaction tccTransaction) {
    final Integer currentVersion = tccTransaction.getVersion();
    tccTransaction.setLastTime(new Date());
    tccTransaction.setVersion(tccTransaction.getVersion() + 1);
    String sql = "update " + tableName
            + " set last_time = ?,version =?,retried_count =?,invocation=?,status=? ,pattern=? where trans_id = ? and version=? ";
    try {
        final byte[] serialize = serializer.serialize(tccTransaction.getParticipants());
        return executeUpdate(sql, tccTransaction.getLastTime(),
                tccTransaction.getVersion(), tccTransaction.getRetriedCount(), serialize,
                tccTransaction.getStatus(), tccTransaction.getPattern(),
                tccTransaction.getTransId(), currentVersion);
    } catch (TccException e) {
        e.printStackTrace();
        return FAIL_ROWS;
    }
}
```

#### ScheduledExecutorService  

参考博客：[a定时任务之ScheduledThreadPoolExecutor](http://moon-walker.iteye.com/blog/2407533)  

1. extends [ThreadPoolExecutor](http://moon-walker.iteye.com/blog/2406788)，说明本质也是一个线程池。  
```java
public class ScheduledThreadPoolExecutor  extends ThreadPoolExecutor  
                implements ScheduledExecutorService {  
//省略实现代码  
}
```
2. 实现``ScheduledExecutorService``接口，自定义个性方法，实现**延迟任务和周期性任务**的核心方法。 

> 下面四个方法都是提交任务方法，相当于``ThreadPoolExecutor``的execute、submit方法，并且都由返回值，类型都是``ScheduledFuture``，相当于普通线程池的``Future``，可以用于控制任务生命周期。  

> 第1、2个是**延迟任务**，即延迟固定period时间后，执行任务。  
> 第3、4个是**周期性任务**，
```java
// 1. 延迟任务 执行方法，参数为Runnable类型对象  
public ScheduledFuture<?> schedule(Runnable command,  
                                    long delay, TimeUnit unit);  

// 2. 延迟任务 执行方法，参数为Callable类型对象  
public <V> ScheduledFuture<V> schedule(Callable<V> callable,  
                                        long delay, TimeUnit unit);  
// 3. 固定频率 执行方法，任务时间到后就立即执行
// 等待周期分两种情况：如果程序的执行时间大于间隔时间，等待周期为执行时间；
// 如果程序的执行时间小于间隔时间，等待周期为间隔时间
public ScheduledFuture<?> scheduleAtFixedRate(Runnable command,  
                                                long initialDelay,  
                                                long period,  
                                                TimeUnit unit);  

// 4. 固定延迟周期 执行方法，上次执行完成后（不管执行任务需要花多长时间）固定等待延迟时间后 再执行  
public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command,  
                                                    long initialDelay,  
                                                    long delay,  
                                                    TimeUnit unit);  
```

3. 新建线程池的任务队列是``ScheduledThreadPoolExecutor``的静态内部类``DelayedWorkQueue``。  
> 该队列主要是维护了一个由[二叉堆算法(最小堆)](https://www.cnblogs.com/skywang12345/p/3610390.html)实现的数组，简单理解就是在调用add方法插入队列时，采用二叉堆算法保证第一个元素是最小值，这里其实就是**Delay时间**最小的值。  

```java
public ScheduledService(final TccConfig tccConfig, final CoordinatorRepository coordinatorRepository) {
        this.tccConfig = tccConfig;
        this.coordinatorRepository = coordinatorRepository;
        // 内部默认实现了队列
        this.scheduledExecutorService = new ScheduledThreadPoolExecutor(1, HmilyThreadFactory.create("tccRollBackService", true));
    }
```



#### 切面-AOP  

1. 理解了aop，就理解了tcc，就理解了分布式事务的实现。  

```java
 @Override
    @Tcc(confirmMethod = "confirmOrderStatus", cancelMethod = "cancelOrderStatus")
    public void makePayment(Order order) {
        order.setStatus(OrderStatusEnum.PAYING.getCode());
        // 本地事务
        orderMapper.update(order);
        // 扣除用户余额
        AccountDTO accountDTO = new AccountDTO();
        accountDTO.setAmount(order.getTotalAmount());
        accountDTO.setUserId(order.getUserId());
        LOGGER.debug("===========执行springcloud扣减资金接口==========");
        // 远端服务
        accountClient.payment(accountDTO);
        //进入扣减库存操作
        InventoryDTO inventoryDTO = new InventoryDTO();
        inventoryDTO.setCount(order.getCount());
        inventoryDTO.setProductId(order.getProductId());
        // 远端服务
        inventoryClient.decrease(inventoryDTO);
    }
```

2. 实现springcloud的切面类实现了Spirng的``Ordered``接口，并重写了getOrder方法，返回``Ordered.HIGHEST_PRECEDENCE``，所以他是优先级最高的切面。  
```java
@Aspect
@Component
public class SpringCloudHmilyTransactionAspect extends AbstractTccTransactionAspect implements Ordered {

    @Autowired
    public SpringCloudHmilyTransactionAspect(final SpringCloudHmilyTransactionInterceptor springCloudHmilyTransactionInterceptor) {
        this.setTccTransactionInterceptor(springCloudHmilyTransactionInterceptor);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
```

3. 我们在``下订单``时会调用远端rpc服务，springcloud使用``@FeignClient``，并在接口上加了注解``@Tcc``。  
> Spring AOP的特性，接口上加注解，无法进入切面，所以在这里，要采用rpc框架的某些特性来帮助我们获取到``@Tcc``注解信息。  

```java
@FeignClient(value = "account-service", configuration = MyConfiguration.class)
@SuppressWarnings("all")
public interface AccountClient {

    /**
     * 用户账户付款
     * @param accountDO 实体类
     * @return true 成功
     */
    @PostMapping("/account-service/account/payment")
    @Tcc
    Boolean payment(@RequestBody AccountDTO accountDO);
}
```

4. 承接上一步，当调用``SpringCloud``的RPC服务``accountClient.payment()``，会进入``HmilyFeignHandler``。  
> 通过@FeignClient的自定义配置``MyConfiguration.java``;  
> 在这里我们获取了之前设置到本地ThreadLocal里的事务上下文，然后进行SpringCloud的rpc传参数。  
> 保存方法的所有的信息，方法签名、接口等。


### tcc库作用  

存储做分布式事务时的日志信息。  
1. 如果是正常执行，日志信息会删除；  
2. ``订单``、``库存``、``账户``三个不同的库，下订单时，属于分布式事务，如果有一处异常，比如库存异常（服务断掉），已经持久化的订单、账户就会回滚，保持事务高度一致性。  

3. 服务超时时，通过**本地补偿**，

* applicationContext.xml  
```xml
<context:component-scan base-package="com.hmily.tcc.*"/>
    <aop:aspectj-autoproxy expose-proxy="true"/>
    <bean id="hmilyTransactionBootstrap" class="com.hmily.tcc.core.bootstrap.HmilyTransactionBootstrap">
        <property name="serializer" value="kryo"/>
        <property name="recoverDelayTime" value="120"/>
        <property name="retryMax" value="30"/>
        <property name="scheduledDelay" value="120"/>
        <property name="scheduledThreadMax" value="4"/>
        <property name="repositorySupport" value="db"/>
        <property name="tccDbConfig">
            <bean class="com.hmily.tcc.common.config.TccDbConfig">
                <property name="url"
                          value="jdbc:mysql://localhost:3306/tcc?useUnicode=true&amp;characterEncoding=utf8"/>
                <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
                <property name="username" value="root"/>
                <property name="password" value="root"/>
            </bean>
        </property>
    </bean>
```

### 执行confirm、cancel方法失败时  

框架初始化时，会初始化一个线程池，任务调度，根据你的配置多少时间轮询一次。  
1. 如果你的日志没有删除，服务分布式事务执行失败，进行各种情况的判断；  
2. 如果try未执行完成，那么就不进行补偿，直接删除事务日志 （防止在try阶段的各种异常情况）  
3. 如果超过了最大执行次数，不再进行重试  
4. 




### Myth项目demo流程  

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





