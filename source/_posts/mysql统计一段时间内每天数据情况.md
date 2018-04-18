title: mysql统计一段时间内每天数据情况
categories: 工作日志
tags:
  - mysql
date: 2018-04-18 17:14:01
---
#  mysql if语法

##  项目需求

后台项目要统计游戏模块每天新增人数，新增体力值数量以及占总体力值百分比，显示效果如下图所示：

![图片](/images/game_highcharts.png)
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
##  遇到问题

1,ifnull(,)在使用GROUP By后不起作用，参考资料：<https://blog.csdn.net/galenowow/article/details/79258748>
2,mysql生成一段时间内的连续天数日期，参考资料：
<https://www.jianshu.com/p/a63526962139>  
<https://www.cnblogs.com/dennyzhangdd/p/8073181.html>  
注意：limit作用是连续天数的个数，不能超过查询表的记录条数！

参考资料:<https://blog.csdn.net/touatou/article/details/77045740>