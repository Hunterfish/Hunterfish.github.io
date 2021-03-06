---
title: 秒杀活动与分布式锁
date: 2018-05-09 11:18:58
categories: Spring Boot微信点餐项目
tags:
  - 压测
  - Spring Boot
---

# 分布式锁应用  

## 压测工具模拟并发    

> 分布式锁应用在高并发、大流量场景中，之前微信点餐项目中使用的单元测试、postman都无法模拟这种情形，    

> 所以这里使用压测工具来模拟高并发请求。  

* 压测工具[Apache ab](https://www.apachehaus.com/cgi-bin/download.plx)  

> 安装和使用参考：[Apache ab并发负载压力测试](https://www.cnblogs.com/lishuyi/p/5808661.html)  

> [ab压测工具Windows配置使用说明](https://www.cnblogs.com/billyang/p/apache-ab.html)  

* ab 常用命令  

> 模拟100个并发发送500个请求：相当于100个人同时访问500次该网站  

```jshelllanguage
ab -n 500 -c 100 http://www.baidu.com/
```
> 连续60s内发送100个请求  

```jshelllanguage
ab -t 60 -c 100 http://www.baidu.com/
```

## 常规流程  

### 业务代码  

* service层:  

```java
public interface SecKillService {

    /**
     * 查询商品信息
     * @param productId
     * @return
     */
    String querySecKillProductInfo(String productId);

    /**
     * 秒杀活动：下单，减库存，结束活动
     * @param productId
     */
    void orderProductMockDiffUser(String productId);
}
```

```java
@Service
public class SecKillServiceImpl implements SecKillService {

    /** 国庆活动，皮蛋粥特价，限量100000份 */
    static Map<String, Integer> products;
    static Map<String, Integer> stock;
    static Map<String, String> orders;
    static {
        /** 模拟多个表：商品信息表，库存表，秒杀成功订单表 */
        products = new HashMap<>();
        stock = new HashMap<>();
        orders = new HashMap<>();
        products.put("123456", 100000); // 商品Id, 商品库存
        stock.put("123456", 10000000);
    }

    private String queryMap(String productId) {
        return "国庆活动，皮蛋粥特价，限量份"
                + products.get(productId)
                + " 还剩：" + stock.get(productId) + "份"
                + " 该商品成功下单用户数目："
                + orders.size() + " 人";
    }

    @Override
    public String querySecKillProductInfo(String productId) {
        return this.queryMap(productId);
    }

    @Override
    public void orderProductMockDiffUser(String productId) {
        // 1. 查询该商品库存，为0则结束活动
        int stockNum = stock.get(productId);
        if (stockNum == 0) {
            throw new SellException(100, "活动结束");
        } else {
            // 2. 下单(模拟不同用户openid不同)
            orders.put(KeyUtil.genUniqueKey(), productId);
            // 3. 减库存
            stockNum = stockNum - 1;
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            stock.put(productId, stockNum);
        }
    }
}
```

* controller层：  

```java
/**
 * 功能描述: 测试秒杀：压测，分布式锁
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/9 0009 10:17
 */
@RestController
@RequestMapping("/skill")
@Slf4j
public class SecKillController {

    @Autowired
    private SecKillService secKillService;

    /**
     * 查询秒杀活动特价商品的信息
     * @param productId
     * @return
     * @throws Exception
     */
    @GetMapping("/query/{productId}")
    public String query(@PathVariable String productId) throws Exception {
        return secKillService.querySecKillProductInfo(productId);
    }

    /**
     * 秒杀，没有抢到提示
     * @param productId
     * @return
     * @throws Exception
     */
    @GetMapping("/order/{productId}")
    public String skill(@PathVariable String productId) throws Exception {
        log.info("@skill request, productId:" + productId);
        secKillService.orderProductMockDiffUser(productId);
        return secKillService.querySecKillProductInfo(productId);
    }
}
```

### 测试  

* 启动项目  
* 访问链接：查询订单信息  

```html
http://127.0.0.1:8080/sell/skill/query/123456
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/38816287.jpg)

> 用户下单（刷新一下，就是请求一次）    

```html
http://127.0.0.1:8080/sell/skill/order/123456
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/42446295.jpg)

* ab压测测试：模拟100并发发送500次请求  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/30715844.jpg)

* 压测结果  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/72923430.jpg)  

> 可以看到，出现了超卖问题  

### 问题原因  

> 从代码上来看，因为我们的数据是放在map中，类似于数据存在内存中（redis），而不是从数据库中，这样查询速度快。  

> 我们可以在核心代码【SecKillServiceImpl.java】上加上关键字**synchronized**  

* 修改代码：  

```java
public synchronized void orderProductMockDiffUser(String productId) {
        // 1. 查询该商品库存，为0则结束活动
        int stockNum = stock.get(productId);
        if (stockNum == 0) {
            throw new SellException(100, "活动结束");
        } else {
            // 2. 下单(模拟不同用户openid不同)
            orders.put(KeyUtil.genUniqueKey(), productId);
            // 3. 减库存
            stockNum = stockNum - 1;
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            stock.put(productId, stockNum);
        }
    }
```
* 重新测试  

> 重启项目，进行压测，结果显示正常，没有出现**超卖**问题  

> 但是发现，压测时，明显感觉到请求速度变慢，sychronized在保证线程安全同时，牺牲了性能

### 分析synchronized  

* 是一种解决方法  
* 无法做到细粒度控制  
> 比如很多商品参加秒杀活动，每个商品ID都不一样，这些商品的每一次请求都会访问上面的方法，秒杀A商品的人比较多，
秒杀B商品的人较少，这样这两种秒杀都会一样的慢  
* 只适合单点的情况  
> 上述只能跑在单机上面，如果我们项目进行水平扩展，比如集群，显然负载均衡后，不同的用户访问下结果肯定是五花八门。
这就引出下一篇的**Redis分布式锁**了。  

## Redis分布式锁  

### Redis介绍  

* [Redis中文网站](http://redis.cn/)  
* [SETNX命令](http://redis.cn/commands/setnx.html)  
* [GETSET命令](http://redis.cn/commands/getset.html)

### 使用Redis作为分布式锁  

* RedisLock.java  
```java
/**
 * 功能描述: Redis分布式锁
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/9 0009 13:28
 */
@Component
@Slf4j
public class RedisLock {

    @Autowired
    private StringRedisTemplate redisTemplate;

    /**
     * 加锁
     * @param key productId
     * @param value 当前时间+超时时间
     * @return
     */
    public boolean lock(String key, String value) {
        // setIfAbset() 等同于 Redis 命令：SETNX
        if (redisTemplate.opsForValue().setIfAbsent(key, value)) {
            return true;
        }

        String currentValue = redisTemplate.opsForValue().get(key);
        // 如果锁过期
        if (!StringUtils.isEmpty(currentValue) && Long.parseLong(currentValue) < System.currentTimeMillis()) {
            // 获取上一个锁的时间
            // getAndSet 等同于 Redis 命令：GETSET
            String oldValue = redisTemplate.opsForValue().getAndSet(key, value);
            if (!StringUtils.isEmpty(oldValue) && oldValue.equals(currentValue)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 解锁：删掉key
     * @param key
     * @param value
     */
    public void unlock(String key, String value) {
        try {
            String currentValue = redisTemplate.opsForValue().get(key);
            if (!StringUtils.isEmpty(currentValue) && currentValue.equals(value)) {
                redisTemplate.opsForValue().getOperations().delete(key);
            }
        } catch (Exception e) {
            log.error("【redis分布式锁】解锁异常, {}", e);
        }
    }
}
```

* SecKillServiceImpl.java 核心代码   

> 去掉synchronized关键字；
在用户下单减库存业务执行前后添加【加锁】和【解锁】功能。  

```java
@Override
    public void orderProductMockDiffUser(String productId) {

        // 加锁
        long time = System.currentTimeMillis() + TIMEOUT;

        // 如果加锁不成功, lock()返回false
        if (!redisLock.lock(productId, String.valueOf(time))) {
            throw new SellException(101, "哎呦喂，人也太多了，换个姿势再试试~~~");
        }

        // 1. 查询该商品库存，为0则结束活动
        int stockNum = stock.get(productId);
        if (stockNum == 0) {
            throw new SellException(100, "活动结束");
        } else {
            // 2. 下单(模拟不同用户openid不同)
            orders.put(KeyUtil.genUniqueKey(), productId);
            // 3. 减库存
            stockNum = stockNum - 1;
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            stock.put(productId, stockNum);
        }

        // 解锁
        redisLock.unlock(productId, String.valueOf(time));
    }
```

### 测试结果  

* 重启项目，ab压测  

```jshelllanguage
ab -n 500 -c 100 http://127.0.0.1:8080/sell/skill/order/123456
```
* 和sychorized对比，明显Redis分布式锁速度快多了  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/34453815.jpg)

## 总结  

* Redis作为**单线程服务**，又是**NoSql数据库**，即高效的**key-value**数据结构，能达到每秒10万次的并发，能作为
【高可用】【分布式集群】的一种解决方案；  

* 相对于关键字【synchronized】支持分布式、高可用；  

* 可以更细粒度的控制  
> 上面介绍的以商品ID productId 作为锁的key, 采用分布式锁  

* 多台机器上多个进程对一个数据进行操作的互斥  
> 用户可以秒杀多个商品，采用多个productId作为分布式的锁。

