---
title: Netty源码学习-NioEventLoop(二)启动过程
date: 2018-11-09 11:43:28
categories: Netty学习总结
tags: 
  - Netty
---

# 启动触发器  

NioEventLoop的启动有两大触发器。  

1. 服务端启动绑定端口  
> 之前我们已经深入源码了解过。  

2. 新连接接入通过``chooser``绑定一个``NioEventLoop``  

## 端口绑定启动流程  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-9/4759255.jpg)

1. bind() --> execute(task) 入口  
> 之前我们在服务端启动流程中，分析过``doBind0``源码  

* AbstractBootstrap.java  
```java
private static void doBind0(
            final ChannelFuture regFuture, final Channel channel,
            final SocketAddress localAddress, final ChannelPromise promise) {
    
    // eventLoop(): 前面服务端启动过程中，通过register方法绑定的
    // Runnable: task，具体就是做绑定端口的事情
    channel.eventLoop().execute(new Runnable() {
        @Override
        public void run() {
            if (regFuture.isSuccess()) {
                channel.bind(localAddress, promise).addListener(ChannelFutureListener.CLOSE_ON_FAILURE);
            } else {
                promise.setFailure(regFuture.cause());
            }
        }
    });
}
```

> 我们进入execute方法中  

* SingleThreadEventExecutor.java  
```java
@Override
public void execute(Runnable task) {

    // inEventLoop()方法：判断当前执行的线程是否是NioEventLoop的线程
    // 此时返回false
    boolean inEventLoop = inEventLoop();
    if (inEventLoop) {
        addTask(task);
    } else {
        // 1. 启动线程
        startThread();
        addTask(task);
        if (isShutdown() && removeTask(task)) {
            reject();
        }
    }

    if (!addTaskWakesUp && wakesUpForTask(task)) {
        wakeup(inEventLoop);
    }
}
```
> 进入inEventLoop()  

```java
// AbstractEventExecutor.java  
@Override
public boolean inEventLoop() {
    // Thread.currentThread(): 因为我们服务端启动时是在main执行的，此处就是主线程
    return inEventLoop(Thread.currentThread());
}

// SingleThreadEventExecutor.java
@Override
public boolean inEventLoop(Thread thread) {
    // 因为当前线程还没有创建，所以此处返回false
    return thread == this.thread;
}
```

> 进入startThread(), 创建线程  

* SingleThreadEventExecutor.java  
```java
private void startThread() {
    // 判断当前线程是否未启动
    if (STATE_UPDATER.get(this) == ST_NOT_STARTED) {
        if (STATE_UPDATER.compareAndSet(this, ST_NOT_STARTED, ST_STARTED)) {
            doStartThread();
        }
    }
}

private void doStartThread() {
    // 断言 启动的线程必须是以前没有创建过的
    assert thread == null;
    // 2. executor: NioEventLoop创建过程中，初始化保存了线程执行器ThreadPerTaskExecutor
    // 生成一个线程FastThreadLocalThread
    executor.execute(new Runnable() {
        @Override
        public void run() {
            // 2.1 thread就是创建NioEventLoop底层的FastThreadLocalThread
            // 保存thread，就是把netty的NioEventLoop这个对象跟唯一的线程进行绑定
            thread = Thread.currentThread();
            
            boolean success = false;
            updateLastExecutionTime();
            // 2.2 NioEventLoop的run方法进行启动
            SingleThreadEventExecutor.this.run();
            success = true;
        }
    });
}
```



