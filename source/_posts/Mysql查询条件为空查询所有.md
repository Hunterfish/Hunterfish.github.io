title: Mysql查询条件为空查询所有
author: 咸鱼翻面
date: 2018-04-17 10:53:56
tags:
  - mysql
categories: 工作日志
---
#  mysql if语法

公司后台框架为Spring Boot + mybatis + vue,在一段复杂的统计查询语句中没有使用mybatis，而是一段完整的sql语句

```xml
<select id="queryAreaOrderStatistics" resultType="com.dl98.modules.api.vo.OrderStatisticsVo">
        SELECT
            c1.area_id,
            count(c1.area_id) orderNum,
            SUM(c1.total) total
        FROM (
                 SELECT
                     sgoc.order_id,
                     sgo.area_id,
                     sgo.create_time,
                     sum(
                             (sp.price - sp.cost) * sgoc.goods_count * 0.08
                     ) AS total
                 FROM
                     dl_supplier_goods_order_correlation sgoc
                     LEFT JOIN dl_supplier_parameter sp ON sgoc.parameter_id = sp.id
                     LEFT JOIN dl_supplier_goods_order sgo ON sgoc.order_id = sgo.id
                 WHERE
                     sgo.create_time BETWEEN #{sTime} AND #{eTime} AND if(#{id} is null, 1, sgo.mill_id=#{id}) AND sgo.pay_status = 1
                 GROUP BY
                     sgoc.order_id) c1
        GROUP BY c1.area_id
</select>
```
```java
public class Demo {
    public static void main(String[] args){
      System.out.println("Hello! World!");
    }
}
```
主要是：if (#{id} is null, 1, sgo.mill_id = #{id})

参考资料:<https://blog.csdn.net/touatou/article/details/77045740>
