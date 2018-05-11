title: mysql统计一段时间内每天数据情况
categories: 工作日志
tags:
  - MySQL
date: 2018-05-02 12:14:01
---
##  项目需求  

后台项目要统计游戏模块每天新增人数，新增体力值数量以及占总体力值百分比，显示效果如下图所示：

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/37035734.jpg)
##  sql语句
sql语句如下：
```sql
SELECT
    t2.date,
    ifnull(t4.newUserNum,0) newUserNum,
    ifnull(t3.addVitality,0) addVitality,
    ifnull(t4.allVitality,0) allVitality,
    ifnull(ROUND(t3.addVitality/t4.allVitality*100,1),0) percent
FROM
    (SELECT @cdate := DATE_ADD(@cdate, INTERVAL -1 DAY) date
     FROM
             (SELECT @cdate := DATE_ADD('2018-03-21', INTERVAL +1 DAY)
                FROM
                        dl_area t0 LIMIT 10
             ) t1
    ) t2
LEFT JOIN (SELECT sum(if((pay_status = 1),pay_amount,0)) addVitality, DATE(create_time) date
         FROM
                 ldd_game_pay_order
         WHERE create_time BETWEEN '2018-02-02T00:00' AND '2018-03-21T00:00' GROUP BY date
        ) t3
ON t2.date = t3.date
LEFT JOIN (SELECT count(id) newUserNum, sum(vitality) allVitality, Date(create_time) date
         FROM
                 ldd_game_user_info
         WHERE create_time BETWEEN '2018-02-02T00:00' AND '2018-03-21T00:00' GROUP BY date
        ) t4
ON t2.date = t4.date
ORDER BY t2.date
```

mybatis,xml语句如下：
```xml
<select id="queryNewUserStatistics" resultType="com.dl98.modules.api.vo.GameStatisticsVo">
    SELECT
        t2.date,
        ifnull(t4.newUserNum,0) newUserNum,
        ifnull(t3.addVitality,0) addVitality,
        ifnull(t4.allVitality,0) allVitality,
        ifnull(ROUND(t3.addVitality/t4.allVitality*100,1),0) percent
    FROM
        (SELECT @cdate := DATE_ADD(@cdate, INTERVAL -1 DAY) date
         FROM
             (SELECT @cdate := DATE_ADD(#{eDate}, INTERVAL +1 DAY)
              FROM
                  dl_area t0 LIMIT #{days}
             ) t1
        ) t2
    LEFT JOIN (SELECT sum(if((pay_status = 1),pay_amount,0)) addVitality, DATE(create_time) date
               FROM
                   ldd_game_pay_order
               WHERE create_time BETWEEN #{sTime} AND #{eTime} GROUP BY date
              ) t3
    ON t2.date = t3.date
    LEFT JOIN (SELECT count(id) newUserNum, sum(vitality) allVitality, Date(create_time) date
               FROM
                   ldd_game_user_info
               WHERE create_time BETWEEN #{sTime} AND #{eTime} GROUP BY date
              ) t4
    ON t2.date = t4.date
    ORDER BY t2.date
</select>
```
###  sql分析
####  生成一段时间列  
```sql
SELECT @cdate := DATE_ADD(@cdate, INTERVAL -1 DAY) date
FROM
(SELECT @cdate := DATE_ADD(#{eDate}, INTERVAL +1 DAY)
FROM
  dl_area t0 LIMIT #{days}
) t1
```
1. **@cdate**   
    > 是定义名为cdate的变量并赋值（select后面必须用:=）  
2. **[ATE_ADD(date, INTERVAL expr type)](http://www.w3school.com.cn/sql/func_date_add.asp)** 
    > 该mysql函数向日期添加指定的时间间隔  
3. **[INTERVAL](https://blog.csdn.net/arenzhj/article/details/16902141)**  
    > 取间隔关键字
4. **@cdate := DATE_ADD('20180319', INTERVAL + 1 DAY)**  
    > 按照传入的日期'20180319',加一天  
5. **SELECT @cdate := DATE_ADD('20180319',INTERVAL + 1 DAY) FROM 'dl_area'**  
    > 找一张表记录条数足够多的即可，能生成你想要的时间段内的连续日期  
6. **limit**  
    > 你需要的连续日期长度
##  参考链接

* ifnull(,)在使用GROUP By后不起作用，参考资料：<https://blog.csdn.net/galenowow/article/details/79258748>  
* mysql生成一段时间内的连续天数日期，参考资料：
<https://www.jianshu.com/p/a63526962139>  
<https://www.cnblogs.com/dennyzhangdd/p/8073181.html>  
    > 注意：limit作用是连续天数的个数，不能超过查询表的记录条数！
* <https://blog.csdn.net/touatou/article/details/77045740>