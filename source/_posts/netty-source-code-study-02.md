---
title: Netty源码学习-Netty服务端启动分析
date: 2018-11-08 20:37:12
categories: Netty学习总结
tags: 
  - Netty
---

# 提出问题  

1. 服务端的socket在哪里初始化？  
> netty是在哪里调用了底层jdk的socket api去创建服务端的socket。  

2. 在哪里accept连接？  

# 分析源码  

## 总结过程  

1. 创建服务端Channel  
> 调用jdk底层的api创建jdk的channel，netty将其包装成自己的channel，同时创建一些基本组件绑定到其Channel上。  

2. 初始化服务端Channel  
> 创建完Channel后，会初始化一些基本属性，添加一些逻辑处理器（ChannelHandler）  

3. 注册Selector  
> netty将jdk底层的channel注册到事件轮询器``selector``上，
> 并把netty服务端的channel作为一个。。。，绑定在对应的jdk底层的服务端的channel，后续事件轮询器``selector``轮训出来后，拿到这个taitement，就是netty封装的Channel。  

4. 端口绑定  
> 前面三个步骤完成后，端口绑定其实也是调用底层jdk 的api实现对端口的监听。  

# 反射创建服务端Channel  
![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/80447954.jpg)

## bind()   

服务端创建的入口。  

```java
// 绑定端口，启动server端
ChannelFuture f = b.bind(8888).sync();
```

## initAndRegister()  

* AbstractBootStrap.java  
```java
 final ChannelFuture initAndRegister() {
    Channel channel = null;
    try {
        channel = channelFactory.newChannel();
        init(channel);
    } catch (Throwable t) {
        ...
    }
    ...
 }
```

> 我们点击进入``channelFactory.newChannel()``  

* ReflectiveChannelFactory.java  

```java
 @Override
public T newChannel() {
    try {
        // 通过反射获取Channel，那么这个clazz到底是什么呢
        return clazz.newInstance();
    } catch (Throwable t) {
        throw new ChannelException("Unable to create Channel from class " + clazz, t);
    }
}
```

> 为了知道clazz是什么，我们要弄清楚``channelFactory``是在哪里初始化的。  

## newChannel()  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/33425637.jpg)

* nettyServer端代码  

```java
EventLoopGroup bossGroup = new NioEventLoopGroup(1);
EventLoopGroup workerGroup = new NioEventLoopGroup();

try {
    ServerBootstrap b = new ServerBootstrap();
    b.group(bossGroup, workerGroup)
            // 此处我们设置了NIO的模型，重点就是这个.channel方法
            .channel(NioServerSocketChannel.class)
            .handler(new SimpleServerHandler())
            .childHandler(new ChannelInitializer<SocketChannel>() {
                @Override
                public void initChannel(SocketChannel ch) throws Exception {
                }
            });
    // 绑定端口，启动server端
    ChannelFuture f = b.bind(8888).sync();

    f.channel().closeFuture().sync();
} finally {
    bossGroup.shutdownGracefully();
    workerGroup.shutdownGracefully();
}
```

> 进入.channel方法  

* AbstractBootstrap.java  

```java
public B channel(Class<? extends C> channelClass) {
    if (channelClass == null) {
        throw new NullPointerException("channelClass");
    }
    // 通过反射的方法返回ChannelFactory
    return channelFactory(new ReflectiveChannelFactory<C>(channelClass));
}
```

> 上面我们知道反射了``NioServerSocketChannel.java``该类初始化``ChannelFactory``，我们看看该类的构造函数。  

* NioServerSocketChannel.java  

```java
// 构造函数调用newSocket创建地城jdk channel
public NioServerSocketChannel() {
    // 1
    this(newSocket(DEFAULT_SELECTOR_PROVIDER));
}

private static ServerSocketChannel newSocket(SelectorProvider provider) {
    ...
    // 底层jdk api方法返回底层jdk的服务端channel ServerSocketChanenl
    return provider.openServerSocketChannel();
    ...
}

// 执行1中的this，继续构造函数
public NioServerSocketChannel(ServerSocketChannel channel) {
    // 调用父类的构造函数，做了什么？
    super(null, channel, SelectionKey.OP_ACCEPT);
    // tcp配置参数
    config = new NioServerSocketChannelConfig(this, javaChannel().socket());
}
```

> 上面``NioServerSocketChannel.java``构造函数调用父类的构造函数。  

* AbstractNioChannel.java  

```java
protected AbstractNioChannel(Channel parent, SelectableChannel ch, int readInterestOp) {
    // 这里调用AbstractChannel的构造函数
    super(parent);
    this.ch = ch;
    this.readInterestOp = readInterestOp;
    try {
        // netty核心：设置服务端的channel为非阻塞模式
        // ch: 刚刚通过newSocket()创建的底层jdk 的channel
        ch.configureBlocking(false);
    } catch (IOException e) {
        try {
            ch.close();
        } catch (IOException e2) {
            if (logger.isWarnEnabled()) {
                logger.warn(
                        "Failed to close a partially initialized socket.", e2);
            }
        }

        throw new ChannelException("Failed to enter non-blocking mode.", e);
    }
}
```

> 上面的super(parent)，调用``AbstractChannel``的构造函数，为什么调用它呢？  
> 因为我们除了服务端的channel，还有客户端的channel，都是继承与它，都会有id，unsafe，pipeline这三个属性，id对应channel的唯一标识，unsafe就是tcp相关的读写，底层的东西；pipeline是服务端和客户端相关的逻辑链；  

* AbstractChannel.java  

```java
protected AbstractChannel(Channel parent) {
    this.parent = parent;
    id = newId();
    unsafe = newUnsafe();
    pipeline = newChannelPipeline();
}
```

# 初始化服务端channel   

## init()  
  
![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/4968981.jpg)

> 我们在上面小结``initAndRegister()``中，进入``init(channel)``方法。  

* ServerBootstrap.java

```java
void init(Channel channel) throws Exception {
    // 1. set ChannelOptions，绑定用户自定义的属性到channel中
    final Map<ChannelOption<?>, Object> options = options0();
    synchronized (options) {
        // config()：上面创建channel的时候，创建的config
        channel.config().setOptions(options);
    }

    // 1. set ChannelAttrs，绑定用户自定义的属性到channel中
    final Map<AttributeKey<?>, Object> attrs = attrs0();
    synchronized (attrs) {
        for (Entry<AttributeKey<?>, Object> e: attrs.entrySet()) {
            @SuppressWarnings("unchecked")
            AttributeKey<Object> key = (AttributeKey<Object>) e.getKey();
            channel.attr(key).set(e.getValue());
        }
    }

    ChannelPipeline p = channel.pipeline();

    final EventLoopGroup currentChildGroup = childGroup;
    final ChannelHandler currentChildHandler = childHandler;
    final Entry<ChannelOption<?>, Object>[] currentChildOptions;
    final Entry<AttributeKey<?>, Object>[] currentChildAttrs;
    // 2. set ChildOptions，保存到方法的局部变量中
    synchronized (childOptions) {
        currentChildOptions = childOptions.entrySet().toArray(newOptionArray(childOptions.size()));
    }
    // 2. set ChildAttrs，保存到方法的局部变量中
    synchronized (childAttrs) {
        currentChildAttrs = childAttrs.entrySet().toArray(newAttrArray(childAttrs.size()));
    }

    p.addLast(new ChannelInitializer<Channel>() {
        @Override
        public void initChannel(Channel ch) throws Exception {
            // 3. 配置服务端pipeline，添加自定义的handler
            final ChannelPipeline pipeline = ch.pipeline();
            // 拿到用户自定义的handler
            ChannelHandler handler = config.handler();
            if (handler != null) {
                pipeline.addLast(handler);
            }

            ch.eventLoop().execute(new Runnable() {
                @Override
                public void run() {
                    // 4. add ServerBootstrapAcceptor 
                    // 通过上面1.2.3保存的用户的自定义属性、handler创建一个连接接入器；
                    // 连接接入器每accept一个新的连接后，都会使用这些属性配置新的连接
                    pipeline.addLast(new ServerBootstrapAcceptor(
                            currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
                }
            });
        }
    });
}
```

# 注册selector  

channel创建和初始化完成后，注册到事件轮询器selector中。  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/25343566.jpg)

> 还是回到上面小结的``initAndRegister()``方法中。  

```java
final ChannelFuture initAndRegister() {
    ...
    channel = channelFactory.newChannel();
    init(channel);
    ...
    // 1. 实际最终调用了AbstractChannel.register(channel)
    ChannelFuture regFuture = config().group().register(channel);
    ...
    return regFuture;
}
```

> ``AbstractChannel.register()``，注册到selector的入口。  

* AbstractChannel.java  

```java
@Override
public final void register(EventLoop eventLoop, final ChannelPromise promise) {
    ...
    // 2. this.eventLoop = eventLoop : nio线程和当前channel绑定
    // 简单的复制操作声明channel，后续的io事件相关的操作都是交给我这个eventloop去处理。  
    AbstractChannel.this.eventLoop = eventLoop;

    if (eventLoop.inEventLoop()) {
        // 3. 实际注册
        register0(promise);
    } else {
        ...
    }
}
```

> 我们进入``register0()``中。  

* 
```java
 private void register0(ChannelPromise promise) {
    try {
        // 3.1 调用jdk底层注册，把当前channel绑定到selector中
        doRegister();
        neverRegistered = false;
        registered = true;
        // 3.2 用户自定义handler的HandlerAdd()事件 回调，传播到我们的用户方法
        pipeline.invokeHandlerAddedIfNeeded();

        safeSetSuccess(promise);
        // 3.3 用户自定义的handler的ChannelRegister() 回调，传播到我们的用户方法
        pipeline.fireChannelRegistered();
        if (isActive()) {
            if (firstRegistration) {
                pipeline.fireChannelActive();
            } else if (config().isAutoRead()) {
                beginRead();
            }
        }
    } catch (Throwable t) {
        closeForcibly();
        closeFuture.setClosed();
        safeSetFailure(promise, t);
    }
}
```

> 我们进入最核心部分，doRegister()  

* AbstractNioChannel.java  
```java
protected void doRegister() throws Exception {
    boolean selected = false;
    for (;;) {
        try {
            // javaChannel(): 之前保存的创建channel调用底层jdk生成的底层channel；
            // 
            selectionKey = javaChannel().register(eventLoop().selector, 0, this);
            return;
        } catch (CancelledKeyException e) {
            if (!selected) {
                eventLoop().selectNow();
                selected = true;
            } else {
                throw e;
            }
        }
    }
}
```

# 端口绑定  

上面的步骤执行完后，最后一个过程是执行端口的绑定。  

![](http://p8hqd7oln.bkt.clouddn.com/18-11-8/21055020.jpg)

> 我们回到一开始的``doBind()``方法。   

* AbstractBootstrap.java  

```java
private ChannelFuture doBind(final SocketAddress localAddress) {
    final ChannelFuture regFuture = initAndRegister();
    final Channel channel = regFuture.channel();
    
    // 进入，最终会调用AbstractChannel的bind()方法
    doBind0(regFuture, channel, localAddress, promise);
    ...
}
```

* AbstractChannel.java  

```java
@Override
public final void bind(final SocketAddress localAddress, final ChannelPromise promise) {
    assertEventLoop();
    ...
    // 端口绑定之前，isActive()返回false
    boolean wasActive = isActive();
    try {
        // 1. 调用jdk底层的端口绑定方法
        doBind(localAddress);
    } catch (Throwable t) {
        safeSetFailure(promise, t);
        closeIfClosed();
        return;
    }
    // 端口绑定之后，isActive()返回true
    if (!wasActive && isActive()) {
        invokeLater(new Runnable() {
            @Override
            public void run() {
                // 传播事件：触发ChannelActive() 事件
                pipeline.fireChannelActive();
            }
        });
    }

    safeSetSuccess(promise);
}
```

> 我们进入上面的doBind()，最终调用``NioServerSocketChannel``的doBind()方法。  

* NioServerSocketChannel.java  

```java
protected void doBind(SocketAddress localAddress) throws Exception {
    if (PlatformDependent.javaVersion() >= 7) {
        // 上面创建NioServerSocketChannel时，调用jdk底层创建的channel
        javaChannel().bind(localAddress, config.getBacklog());
    } else {
        javaChannel().socket().bind(localAddress, config.getBacklog());
    }
}
```



















