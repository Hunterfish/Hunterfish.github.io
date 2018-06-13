---
title: 开发拼团功能
date: 2018-06-11 17:27:37
tags:
---

参考：[Java开源生鲜电商平台-团购模块设计与架构](http://www.cnblogs.com/jurendage/p/9098368.html)；  
参考：[Java定时方式Timer和TimerTask、Spring、QuartZ、Linux Cron](https://www.kancloud.cn/digest/java-travel/159427)；  
参考：[开源项目：FightGroups](https://gitee.com/guinong/FightGroups)  
参考：[开源N拼开发框架：tanjor](https://gitee.com/l2iu/tanjor/tree/master/tanjor)

# 设计思路  

参考：[深入解析拼团模式及用法](http://www.woshipm.com/evaluating/650989.html)  

## 拼团模式  

参考：[商城原型设计（包含前后端），拼团微商城+pc后台管理系统](http://www.pmdaniu.com/rp/detail/35847?page=15)  
 
1. 活动期间,用户可以通过拼团商品详情,下单发起拼团;   
2. 用户只有付款成功才算成功发起拼团或者成功参与拼团,创建订单未付款不算有效参与拼团玩法;   
3. 用户在规定时间内拉满拼团人数,商家就会开始正常发货,   
4. 如果未能在规定时间内拼团成功,则系统自动触发退款。  

### 关键点    

1. 超时未成团自动退款（支付宝、微信接口）  
2. 未成团前不能发起退款，只有成团后才能发起退款  
3. 未支付成功不算参团；  
4. 需要注意**超卖**情况，设置好商品数量与人数平衡；   
> **用缓存**控制并发，不要超卖  

5. 是否添加拼团支持的城市列表；  
6. 是否设置拼团为新用户； 
7. 检测是否成团或失败：进程监控软件 + curl   
8. 多线程处理退款、发送消息通知；  
> 拼团失败，马上退款，用户不会觉得是假的  


## 实际应用  

1. 商家出商品团，当 1 个人购买时 30，5 个人拼团后价格变为 20；   
2. 消费者参加 5 人商品团，先支付 30，开团成功，然后分享好友，拉好友参团；  
3. 24 小时内，满 5 人则拼团成功；  
4. 24 小时内或超出 24 小时，未满 5 人则拼团失败，系统自动退款。  
  

# 数据表设计  

## 拼团主表  

> 开团总人数、开团金额、团开始时间、团结束时间   
> 总人数、当前参团人数、开团人、参与人等  

```sql
CREATE TABLE `groups` (
  `group_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_no` varchar(32) DEFAULT NULL COMMENT '团号',
  `group_title` varchar(128) DEFAULT NULL COMMENT '团购标题',
  `group_area` varchar(128) DEFAULT NULL COMMENT '团购区域(区域ID集合)',
  `begin_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `max_num` int(11) DEFAULT NULL COMMENT '最大买家数',
  `buyer_amt` decimal(12,2) DEFAULT NULL COMMENT '买家起团金额',
  `min_amt` decimal(12,2) DEFAULT NULL COMMENT '最低开团金额',
  `group_status` tinyint(4) DEFAULT NULL COMMENT '状态(1发布 -1未发布 2团成 3未团成)',
  `remarks` varchar(256) DEFAULT NULL,
  `create_user_id` bigint(20) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='团购主表';
```

## 拼团买家表  

> 记录哪个买家、哪个团购、团购最终数量、团购价格等等  

```sql
CREATE TABLE `groups_buyer` (
  `gb_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `buyer_id` bigint(20) DEFAULT NULL COMMENT '买家ID',
  `group_id` bigint(20) DEFAULT NULL COMMENT '团购ID',
  `item_id` bigint(20) DEFAULT NULL COMMENT '团购明细ID',
  `order_id` bigint(20) DEFAULT NULL COMMENT '订单ID',
  `gb_num` int(11) DEFAULT NULL COMMENT '团购数量',
  `gb_price` decimal(12,2) DEFAULT NULL COMMENT '团购价格',
  `gb_amt` decimal(12,2) DEFAULT NULL COMMENT '团购金额',
  `gb_status` tinyint(4) DEFAULT NULL COMMENT '状态(1完成 -1取消)',
  `gb_time` datetime DEFAULT NULL COMMENT '团购时间',
  PRIMARY KEY (`gb_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='团购买家表';
```

## 拼团商品表  

> 记录拼团商品具体规格  

```sql
CREATE TABLE `groups_item` (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint(20) DEFAULT NULL COMMENT '团购ID',
  `goods_id` bigint(20) DEFAULT NULL COMMENT '商品ID',
  `format_id` bigint(20) DEFAULT NULL COMMENT '商品规格ID',
  `group_price` decimal(12,2) DEFAULT NULL COMMENT '团购价格',
  `group_num` int(11) DEFAULT NULL COMMENT '团购数量',
  `item_status` tinyint(4) DEFAULT NULL COMMENT '状态(1在用 -1停用)',
  `create_user_id` bigint(20) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='团购明细表';
```

# 业务功能   

## 商家   

1. 查询拼团活动列表   
2. 查看拼团详情  
3. 新增或修改拼团信息   
4. 更新拼团状态（开团/不开团）  

## 买家   

1. 拼团活动列表   
2. 支付下单，开启拼团   
3. 团购定时器  
> 拼团成功，更新团购状态，推送消息；   
> 拼团失败，更新团购状态，退回支付金额（微信，支付宝），推送消息。  

4. 查看团购详情   

# 表设计

```sql
DROP TABLE IF EXISTS `activity_publish`;
CREATE TABLE `activity_publish` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `activity_number` VARCHAR(100) NOT NULL COMMENT '活动编号',
  `activity_name` VARCHAR(100) NOT NULL COMMENT '活动名称',
  `register_start_time` DATETIME DEFAULT NULL COMMENT '报名开始时间',
  `register_end_time` DATETIME DEFAULT NULL COMMENT '报名结束时间',
  `activity_start_time` DATETIME DEFAULT NULL COMMENT '活动开始时间',
  `activity_end_time` DATETIME DEFAULT NULL COMMENT '活动结束时间',
  `limited` DATETIME DEFAULT NULL COMMENT '限制付款时间<分钟>',
  `activity_mode` tinyint NOT NULL DEFAULT 1 COMMENT '拼团方式 1-普通团 2-阶梯团 3-新增团',
  `activity_explain` VARCHAR(255) COMMENT '活动说明',
  `min_stock` 

) ENGINE=INNODB DEFAULT CHARSET=utf8 COMMENT='活动招商发布表';
```
