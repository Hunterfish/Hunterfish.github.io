---
title: 使用websocket推送消息
date: 2018-05-08 17:07:59
categories: Spring Boot微信点餐项目
tags:
  - WebSocket
  - Spring Boot
---

# websocket推送消息  

## 准备  

* spring boot点餐项目  
* websocket(Html5原生)  

> 功能：当客户端下订单后，服务端推送消息提醒卖家由用户下单  

## 流程  

* pom.xml：引入依赖  

```xml
<!-- websocket -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```
* /order/list.ftl：前端js  
```html
<#--弹窗-->
<div class="modal fade" id="myModal" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h4 class="modal-title" id="myModalLabel">
                    提醒
                </h4>
            </div>
            <div class="modal-body">
                你有新的订单
            </div>
            <div class="modal-footer">
                <button onclick="javascript:document.getElementById('notice').pause()" type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
                <button onclick="location.reload()" type="button" class="btn btn-primary">查看新的订单</button>
            </div>
        </div>
    </div>
</div>

<#--播放音乐--><!--使用html5原生播放音乐-->
<audio id="notice" loop="loop">
    <source src="/sell/mp3/websocket_message.mp3" type="audio/mpeg" />
</audio>

<script src="https://cdn.bootcss.com/jquery/1.12.4/jquery.min.js"></script>
<script src="https://cdn.bootcss.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script>
    var websocket = null;
    if('WebSocket' in window) {
        websocket = new WebSocket('ws://hunterfish.ngrok.xiaomiqiu.cn//sell/webSocket');
    }else {
        alert('该浏览器不支持websocket!');
    }
    // websocket事件
    websocket.onopen = function (event) {
        console.log('建立连接');
    }

    websocket.onclose = function (event) {
        console.log('连接关闭');
    }

    websocket.onmessage = function (event) {
        console.log('收到消息:' + event.data)
        //弹窗提醒, 播放音乐
        $('#myModal').modal('show');

        document.getElementById('notice').play();
    }

    websocket.onerror = function () {
        alert('websocket通信发生错误！');
    }

    // 页面刷新，触发
    window.onbeforeunload = function () {
        websocket.close();
    }

</script>
```
* 通知音乐文件：可以[点击](http://developer.baidu.com/vcast)自定义自己想要的提示音！    

![图片](/images/websocket1.png)

* WebSocketConfig.java：websocket配置类，生成Bean  

```java
/**
 * 功能描述: websocket配置类
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/8 0008 16:09
 */
@Component
public class WebSocketConfig {

    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
```
* WebSocket.java  

> 类似于Controller接口  

```java
/**
 * 功能描述: webSocket事件方法：实现前端js中定义的事件方法
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/8 0008 16:10
 */
@Component
@ServerEndpoint("/webSocket")
@Slf4j
public class WebSocket {

    private Session session;

    // 储存session
    private static CopyOnWriteArraySet<WebSocket> webSocketSet = new CopyOnWriteArraySet<>();

    /**
     * 打开连接
     * @param session
     */
    @OnOpen
    public void onOpen(Session session) {
        this.session = session;
        webSocketSet.add(this);
        log.info("【websocket消息】有新的连接，总数:{}", webSocketSet.size());
    }

    /**
     * 关闭连接
     */
    @OnClose
    public void OnClose() {
        webSocketSet.remove(this);
        log.info("【websocket消息】连接断开，总数:{}", webSocketSet.size());
    }

    /**
     * 收到消息
     * @param message
     */
    @OnMessage
    public void onMessage(String message) {
        webSocketSet.remove(this);
        log.info("【websocket消息】收到客户端发来的消息:{}", message);
    }

    /**
     * 发送消息
     */
    public void sendMessage(String message) {
        for (WebSocket webSocket : webSocketSet) {
            log.info("【websocket消息】广播消息, message={}", message);
            try {
                webSocket.session.getBasicRemote().sendText(message);
            } catch (Exception e) {
                e.printStackTrace();    // 异常只打印不抛出（抛出会回滚）
            }
        }
    }
}
```

## 测试  

* 启动项目  

如何启动，请参考本博客另一篇文章[启动spring boot微信点餐项目]()

> 当进入或刷新订单页面后，websocket产生连接  

![图片](/images/websocket3.png)  
![图片](/images/websocket4.png)  

* postman发送生成订单请求：  

![图片](/images/websocket2.png)  

* 发送请求后：  

![图片](/images/websocket5.png)  
![图片](/images/websocket6.png)  


