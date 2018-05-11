title: 使用微信推送模板消息功能
categories: Spring Boot微信点餐项目
tags:
  - 微信
  - Spring Boot
date: 2018-05-08 15:26:40
---
# 微信推送模板消息  

## 准备  

* 微信公众平台测试账号  
* 微信开发SDK：[weixin-java-mp](https://github.com/Wechat-Group/weixin-java-tools)  

## 微信测试平台新建模板消息  

> 微信测试账号和正式账号还是不一样的，暂时不提  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/47258658.jpg)
![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/55601474.jpg)

## 代码  

* application.yml  

> 可以添加多个模板ID  

```yaml
  templateId:
    # 订单状态变化模板
    orderStatus: 6JxFTK2OKTIF0hZ6aFrsHcUaNad5VDZ8a8wNk_OztFY
```

* PushMessageService   

```java
/**
 * 功能描述: 微信推送消息
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/8 0008 14:06
 */
public interface PushMessageService {

    /**
     * 订单状态变更消息
     * @param orderDTO
     */
    void orderStatus(OrderDTO orderDTO);
}
```
* PushMessageServiceImpl.java  

```java
/**
 * 功能描述: 微信推送消息实现
 * <p>
 * 作者: luohongquan
 * 日期: 2018/5/8 0008 14:07
 */
@Slf4j
@Service
public class PushMessageServiceImpl implements PushMessageService {

    @Autowired
    private WxMpService wxMpService;
    @Autowired
    private WechatAccountConfig wechatAccountConfig;

    @Override
    public void orderStatus(OrderDTO orderDTO) {
        WxMpTemplateMessage templateMessage = new WxMpTemplateMessage();
        templateMessage.setTemplateId(wechatAccountConfig.getTemplateId().get("orderStatus"));
        templateMessage.setToUser(orderDTO.getBuyerOpenid());

        List<WxMpTemplateData> data = Arrays.asList(
                new WxMpTemplateData("first", "亲，请记得收货！"),
                new WxMpTemplateData("keyword1", "微信点餐"),
                new WxMpTemplateData("keyword2", "13636486238"),
                new WxMpTemplateData("keyword3", orderDTO.getOrderId()),
                new WxMpTemplateData("keyword4", orderDTO.getOrderStatusEnum().getMessage()),
                new WxMpTemplateData("keyword5", "￥" + orderDTO.getOrderAmount()),
                new WxMpTemplateData("remark", "欢迎再次光临！")

        );
        templateMessage.setData(data);
        try {
            wxMpService.getTemplateMsgService().sendTemplateMsg(templateMessage);
        } catch (WxErrorException e) {
            log.error("【微信模板消息】发送失败, {}", e);
        }
    }
}
```
> 发送模板消息只是捕捉，打印错误日志，并没有抛出异常，因为下面业务代码【完结订单】执行后，如果抛出异常，就会
回滚，而【发送模板消息】并不是必须的，如果因为【发送模板消息】出现异常就回滚【完结订单】业务，就得不偿失了！      

* OrderServiceImpl.java  

> 结束订单时，发送模板消息  

```java
    @Override
    @Transactional
    public OrderDTO finish(OrderDTO orderDTO) {
        // 1. 判断订单状态
        if (!orderDTO.getOrderStatus().equals(OrderStatusEnum.NEW.getCode())) {
            log.error("【完结订单】订单状态不正确，orderId={}, orderStatus={}", orderDTO.getOrderId(), orderDTO.getOrderStatus());
            throw new SellException(ResultEnum.ORDER_STATUS_ERROR);
        }

        // 2. 修改订单状态
        orderDTO.setOrderStatus(OrderStatusEnum.FINISHED.getCode());
        OrderMaster orderMaster = new OrderMaster();
        BeanUtils.copyProperties(orderDTO, orderMaster);
        OrderMaster updateResult = orderMasterRepository.save(orderMaster);
        if (updateResult == null) {
            log.error("【完结订单】更新失败，orderMaster={}", orderMaster);
            throw new SellException(ResultEnum.ORDER_UPDATE_FAIL);
        }

        // 3. 推送微信模板消息（没有抛出异常，只是捕捉并打印日志，因为如果抛出异常，完结订单就会回滚了，推送消息并不是非常必需的）
        pushMessageService.orderStatus(orderDTO);

        return orderDTO;
    }
```  

* 测试类：  

```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class PushMessageServiceImplTest {

    @Autowired
    private PushMessageServiceImpl pushMessageService;
    @Autowired
    private OrderService orderService;
    @Test
    public void orderStatus() {

        OrderDTO orderDTO = orderService.findOne("1525757413764873869");
        pushMessageService.orderStatus(orderDTO);
    }
}
```

* 结果  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/22669771.jpg)
