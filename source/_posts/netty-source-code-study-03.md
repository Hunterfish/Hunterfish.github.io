---
title: Netty源码学习-NioEventLoop(一)创建
date: 2018-11-09 09:43:28
categories: Netty学习总结
tags: 
  - Netty
---

# 问题   

1. 默认情况下，Netty服务端起多少线程？何时启动？  

2. Netty是如何解决jdk空轮训bug的？  
> 极端情况下，jdk空轮训会导致cpu高速飙升到100%；  

3. Netty如何保证异步串行无锁化的？  
> 服务端拿到客户端的channel，不需要对这个channel进行同步，直接可以高性能并发读写。  
> channelHandler中所有操作都是线程安全的，不需要进行同步。  

# 创建流程  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-9/53015749.jpg)

## new NioEventLoopGroup()  

> 在之前代码中，我们知道，服务端启动时，创建了两个线程组``bossGroup``、``workerGroup``，他们对应的都是一个``NioEventLoopGroup()``  

```java
public static void main(String[] args) {
    // 1. 参数1
    NioEventLoopGroup boosGroup = new NioEventLoopGroup(1);
    // 2. 无参数，构造函数默认传入0
    NioEventLoopGroup workerGroup = new NioEventLoopGroup();
    ...
}
```

> 我们进入上面1中的``new NioEventLoopGroup(1)``中，即构造函数  

* NioEventLoopGroup.java  

```java
public NioEventLoopGroup(int nThreads) {
    // Executor：创建我们的NioEventLoop对应的底层的线程
    this(nThreads, (Executor) null);
}

public NioEventLoopGroup(int nThreads, Executor executor) {
    // provider()：创建我们的NioEventLoop维护的selector
    this(nThreads, executor, SelectorProvider.provider());
}
```

> 我们继续跟进源码，进入父类构造函数  

* MultithreadEventLoopGroup.java  

```java
protected MultithreadEventLoopGroup(int nThreads, Executor executor, Object... args) {
    // 如果我们传进来的参数为0，使用默认的线程数：cpu核数*2
    super(nThreads == 0 ? DEFAULT_EVENT_LOOP_THREADS : nThreads, executor, args);
}
```

* MultithreadEventExecutorGroup.java  

```java
protected MultithreadEventExecutorGroup(int nThreads, Executor executor, Object... args) {
    // DefaultEventExecutorChooserFactory.INSTANCE：负责创建线程选择器，后面会讲到  
    this(nThreads, executor, DefaultEventExecutorChooserFactory.INSTANCE, args);
}
```
> 进入this后，最终就是创建NioEventLoopGroup的源码了  

```java
// 省略无关代码
protected MultithreadEventExecutorGroup(int nThreads, Executor executor,
                                            EventExecutorChooserFactory chooserFactory, Object... args) {

        // 1. 创建线程执行器                
        executor = new ThreadPerTaskExecutor(newDefaultThreadFactory());

        // 2. for循环构建NioEventLoop
        children = new EventExecutor[nThreads];
        for (int i = 0; i < nThreads; i ++) {
            boolean success = false;
            children[i] = newChild(executor, args);
            success = true;
            ...
        }

        // 3. 创建线程选择器
        chooser = chooserFactory.newChooser(children);

        final FutureListener<Object> terminationListener = new FutureListener<Object>() {
            @Override
            public void operationComplete(Future<Object> future) throws Exception {
                if (terminatedChildren.incrementAndGet() == children.length) {
                    terminationFuture.setSuccess(null);
                }
            }
        };

        for (EventExecutor e: children) {
            e.terminationFuture().addListener(terminationListener);
        }

        Set<EventExecutor> childrenSet = new LinkedHashSet<EventExecutor>(children.length);
        Collections.addAll(childrenSet, children);
        readonlyChildren = Collections.unmodifiableSet(childrenSet);
    }
```

> 下面我们详细分析上面的三个步骤。  

### ThreadPerTaskExecutor  

1. 每次执行任务时，都会创建一个线程实体``FastThreadLocalThread``  
> 我们接着上面的源码，进入构造函数  

* ThreadPerTaskExecutor.java  
```java
public final class ThreadPerTaskExecutor implements Executor {
    private final ThreadFactory threadFactory;

    // 初始化传进来的threadFactory
    public ThreadPerTaskExecutor(ThreadFactory threadFactory) {
        this.threadFactory = threadFactory;
    }

    // 每次执行task任务时，都会创建一个线程，把任务扔进去，然后执行
    @Override
    public void execute(Runnable command) {
        threadFactory.newThread(command).start();
    }
}
```
2. NioEventLoop线程命名规则``nioEventLoop-1-xx``  
> 命名规则就是上面传进来的``threadFactory``，返回上一步，进入``newDefaultThreadFactory``。  

* DefaultThreadFactory.java  
```java
public DefaultThreadFactory(Class<?> poolType, boolean daemon, int priority) {
    // toPoolName(poolType): 根据poolType即 NioEventLoop.class获取类名称，并进行大小写转换
    this(toPoolName(poolType), daemon, priority);
}

public DefaultThreadFactory(String poolName, boolean daemon, int priority, ThreadGroup threadGroup) {
        ...
        // poolId.incrementAndGet(): 每创建一个 NioEventLoopGroup，就会自增
        prefix = poolName + '-' + poolId.incrementAndGet() + '-';
        this.daemon = daemon;
        this.priority = priority;
        this.threadGroup = threadGroup;
    }
```

> 上面创建完``threadFactory``后，我们回到第1步中，**threadFactory.newThread()**创建线程的源码  

* DefaultThreadFactory.java  
```java
public Thread newThread(Runnable r) {
    // preifx: 上面的prefix
    // nextId.incrementAndGet(): 每次创建NioEventLoop时都会自增1
    Thread t = newThread(new DefaultRunnableDecorator(r), prefix + nextId.incrementAndGet());
    ...
    return t;
}

protected Thread newThread(Runnable r, String name) {
    // FastThreadLocalThread: netty继承jdk底层Thread，主要是对ThreadLocal相关的操作进行优化  
    return new FastThreadLocalThread(threadGroup, r, name);
}
```

### newChild()  

1. 保存线程执行器``ThreadPerTaskExecutor``  
2. 创建一个``MpscQueue``  
3. 创建一个``selector``  

> 我们回到上面``MultithreadEventExecutorGroup``构造函数的源码  

```java
// 省略无关代码
protected MultithreadEventExecutorGroup(int nThreads, Executor executor,
                                            EventExecutorChooserFactory chooserFactory, Object... args) {

    // 1. 创建线程执行器                
    executor = new ThreadPerTaskExecutor(newDefaultThreadFactory());

    // 2. for循环构建NioEventLoop
    children = new EventExecutor[nThreads];
    for (int i = 0; i < nThreads; i ++) {
        boolean success = false;
        // executor上面创建的线程执行器  
        children[i] = newChild(executor, args);
        success = true;
        ...
    }

    // 3. 创建线程选择器
    ...
}
```  
> 我们进入``newChile``最底层  

* NioEventLoop.java  

```java
NioEventLoop(NioEventLoopGroup parent, Executor executor, SelectorProvider selectorProvider,
                 SelectStrategy strategy, RejectedExecutionHandler rejectedExecutionHandler) {
    super(parent, executor, false, DEFAULT_MAX_PENDING_TASKS, rejectedExecutionHandler);
    ...
    provider = selectorProvider;
    // 3. selector: 成员属性，说明一个NioEventLoop绑定了一个selector
    selector = openSelector();
    selectStrategy = strategy;
}
```
> 我们跟进super父类构造函数  

* SingleThreadEventExecutor.java  

```java
protected SingleThreadEventExecutor(EventExecutorGroup parent, Executor executor,
                                        boolean addTaskWakesUp, int maxPendingTasks,
                                        RejectedExecutionHandler rejectedHandler) {
    super(parent);
    this.addTaskWakesUp = addTaskWakesUp;
    this.maxPendingTasks = Math.max(16, maxPendingTasks);
    // 1. 保存线程执行器，因为之前分析过创建NioEventLoop对应的底层线程，需要用到
    this.executor = ObjectUtil.checkNotNull(executor, "executor");
    // 2. 外部线程在执行netty任务时，如果判断不是在NioEvnetLoop对应的线程里执行；
    // 而是直接塞在任务的队列里，再由NioEventLoop对应的线程执行
    taskQueue = newTaskQueue(this.maxPendingTasks);
    rejectedExecutionHandler = ObjectUtil.checkNotNull(rejectedHandler, "rejectedHandler");
}
```
> 进入``newTaskQueue``  

* NioEventLoop.java  

```java
protected Queue<Runnable> newTaskQueue(int maxPendingTasks) {
    // 外部线程把任务扔进到一个队列里交给NioEventLoop的一个线程去消费
    return PlatformDependent.newMpscQueue(maxPendingTasks);
}
```

### chooserFactory.newChooser()  

创建``NioEventLoop``的最后一个过程。  
chooser的主要作用是：给新连接绑定对应的``NioEventLoop``，对应的是``next()``方法。  

> 我们回到上面``MultithreadEventExecutorGroup``构造函数的源码  

```java
// 省略无关代码
protected MultithreadEventExecutorGroup(int nThreads, Executor executor,
                                            EventExecutorChooserFactory chooserFactory, Object... args) {

    // 1. 创建线程执行器                
    executor = new ThreadPerTaskExecutor(newDefaultThreadFactory());

    // 2. for循环构建NioEventLoop
    children = new EventExecutor[nThreads];
    for (int i = 0; i < nThreads; i ++) {
        boolean success = false;
        children[i] = newChild(executor, args);
        success = true;
        ...
    }

    // 3. 创建线程选择器
    chooser = chooserFactory.newChooser(children);
}
```

> ``chooser``的作用我们看看该类中的``next()``方法。  

```java
@Override
public EventExecutor next() {
    return chooser.next();
}
```

#### 绑定原理  

NioEventLoop绑定新连接的原理。  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-9/56333154.jpg)

当新连接进来时，绑定到第一个NioEventLoop，然后依次往后绑定，当n+1个进来时，循环到第一个NioEventLoop。netty也对此过程进行了优化。  
![](http://p8hqd7oln.bkt.clouddn.com/18-11-9/50073657.jpg)

> 我们继续上面第3步``chooserFactory.newChooser(children);``方法中  

* DefaultEventExecutorChooserFactory.java  
```java
public EventExecutorChooser newChooser(EventExecutor[] executors) {
    // 判断NioEventLoop数组是否是2的幂
    if (isPowerOfTwo(executors.length)) {
        // true
        return new PowerOfTowEventExecutorChooser(executors);
    } else {
        // false
        return new GenericEventExecutorChooser(executors);
    }
}
```

> 当不是2的幂  

* GenericEventExecutorChooser.java  

```java
private static final class GenericEventExecutorChooser implements EventExecutorChooser {
    private final AtomicInteger idx = new AtomicInteger();
    private final EventExecutor[] executors;

    GenericEventExecutorChooser(EventExecutor[] executors) {
        this.executors = executors;
    }

    @Override
    public EventExecutor next() {
        // index自增取模并求绝对值，这样就能从0到最后一个，然后循环从0开始
        return executors[Math.abs(idx.getAndIncrement() % executors.length)];
    }
}
```

> 当是2的幂  

* PowerOfTowEventExecutorChooser.java  
```java
private static final class PowerOfTowEventExecutorChooser implements EventExecutorChooser {
    private final AtomicInteger idx = new AtomicInteger();
    private final EventExecutor[] executors;

    PowerOfTowEventExecutorChooser(EventExecutor[] executors) {
        this.executors = executors;
    }

    @Override
    public EventExecutor next() {
        // index自增直接&，利用二进制位运算，比前面取模%高效的多
        return executors[idx.getAndIncrement() & executors.length - 1];
    }
}
```






