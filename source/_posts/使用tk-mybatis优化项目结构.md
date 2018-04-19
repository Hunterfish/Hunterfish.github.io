---
title: 使用tk.mybatis优化Spring Boot项目
date: 2018-04-19 16:19:01
categories: 工作日志
tags: 
    - mybatis
    - spring boot
---

#  Spring Boot项目中整合tk.mybatis通用插件  

##  tk.mybatis介绍  
* tk.mybatis是一款强大的MyBatis插件，合理使用会帮你除去大量的mybatis中的mapper.mxl文件里重复的sql语句；
* Spring Boot中已经整合了tk.mybatis插件，使用起来非常方便  

```xml
<!-- 通用插件 mapper  -->
<dependency>
    <groupId>tk.mybatis</groupId>
    <artifactId>mapper-spring-boot-starter</artifactId>
    <version>${mapper-spring-boot-starter.version}</version>
</dependency>
```  

##  项目改造  

###  引入之前  

没有使用tk.mybatis之前，使用Mybatis Generator逆向生成mapper.xml, pojo, dao, service, controller等文件

* mapper.xml示例:  

>  每一个mapper.xml文件中都会包含queryObject，queryList，save，update，delete，deleteBatch查询语句，在此基础上你可以修改或新增查询方法；
造成大量的重复性代码  

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.dl98.modules.api.dao.financial.BankDao">

	<!-- 可根据自己的需求，是否要使用 -->
    <resultMap type="com.dl98.modules.api.entity.user.Bank" id="dlBankMap">
        <result property="id" column="id"/>
        <result property="createTime" column="create_time"/>
        <result property="updatedTime" column="updated_time"/>
        <result property="createBy" column="create_by"/>
        <result property="deleted" column="deleted"/>
        <result property="enable" column="enable"/>
        <result property="modifyBy" column="modify_by"/>
        <result property="bank" column="bank"/>
        <result property="cardNo" column="card_no"/>
        <result property="cardType" column="card_type"/>
        <result property="name" column="name"/>
        <result property="subbranch" column="subbranch"/>
        <result property="userId" column="user_id"/>
    </resultMap>

	<select id="queryObject" resultType="com.dl98.modules.api.entity.user.Bank">
		select * from dl_bank where id = #{value}
	</select>

	<select id="queryList" resultType="com.dl98.modules.api.entity.user.Bank">
		select * from dl_bank
        <choose>
            <when test="sidx != null and sidx.trim() != ''">
                order by ${sidx} ${order}
            </when>
			<otherwise>
                order by id desc
			</otherwise>
        </choose>
		<if test="offset != null and limit != null">
			limit #{offset}, #{limit}
		</if>
	</select>
	
 	<select id="queryTotal" resultType="int">
		select count(*) from dl_bank 
	</select>
	 
	<insert id="save" parameterType="com.dl98.modules.api.entity.user.Bank" useGeneratedKeys="true" keyProperty="id">
		insert into dl_bank
		(
			`create_time`, 
			`updated_time`, 
			`create_by`, 
			`deleted`, 
			`enable`, 
			`modify_by`, 
			`bank`, 
			`card_no`, 
			`card_type`, 
			`name`, 
			`subbranch`, 
			`user_id`
		)
		values
		(
			#{createTime}, 
			#{updatedTime}, 
			#{createBy}, 
			#{deleted}, 
			#{enable}, 
			#{modifyBy}, 
			#{bank}, 
			#{cardNo}, 
			#{cardType}, 
			#{name}, 
			#{subbranch}, 
			#{userId}
		)
	</insert>
	 
	<update id="update" parameterType="com.dl98.modules.api.entity.user.Bank">
		update dl_bank 
		<set>
			<if test="createTime != null">`create_time` = #{createTime}, </if>
			<if test="updatedTime != null">`updated_time` = #{updatedTime}, </if>
			<if test="createBy != null">`create_by` = #{createBy}, </if>
			<if test="deleted != null">`deleted` = #{deleted}, </if>
			<if test="enable != null">`enable` = #{enable}, </if>
			<if test="modifyBy != null">`modify_by` = #{modifyBy}, </if>
			<if test="bank != null">`bank` = #{bank}, </if>
			<if test="cardNo != null">`card_no` = #{cardNo}, </if>
			<if test="cardType != null">`card_type` = #{cardType}, </if>
			<if test="name != null">`name` = #{name}, </if>
			<if test="subbranch != null">`subbranch` = #{subbranch}, </if>
			<if test="userId != null">`user_id` = #{userId}</if>
		</set>
		where id = #{id}
	</update>
	
	<delete id="delete">
		delete from dl_bank where id = #{value}
	</delete>
	
	<delete id="deleteBatch">
		delete from dl_bank where id in 
		<foreach item="id" collection="array" open="(" separator="," close=")">
			#{id}
		</foreach>
	</delete>
</mapper>
```  

* Dao层代码：  

>  继承BaseDao接口；BaseDao定义的方法xml文件中必须有相应的SQL语句  

```java
/**
 * 功能描述: 银行卡数据访问层
 */
@Mapper
@Repository
public interface BankDao extends BaseDao<Bank> {
}
```  

```java
/**
 * 基础Dao(还需在XML文件里，有对应的SQL语句)
 */
public interface BaseDao<T> {
	void save(T t);
	void save(Map<String, Object> map);
	void saveBatch(List<T> list);
	int update(T t);
	int update(Map<String, Object> map);
	int delete(Object id);
	int delete(Map<String, Object> map);
	int deleteBatch(Object[] id);
	T queryObject(Object id);
	List<T> queryList(Map<String, Object> map);
	List<T> queryList(Object id);
	int queryTotal(Map<String, Object> map);
	int queryTotal();
}
```
* service接口  

```java
public interface BankService {
    // 新增自定义查询接口
    R updateBank(Bank bank);
    // 修改了原来dao默认的查询接口
    Bank queryObject(Long id);
}
```  

* service实现层  

>  注入BankDao  

```java
@Service
@Transactional
public class BankServiceImpl implements BankService{
    @Autowired
    private BankDao bankDao;
    
    @Override
    public R updateBank(Bank bank) {
        int Result = bankDao.update(bank);
        return Result == 0 ? R.error("银行卡信息保存失败") : R.ok();
    }

    @Override
    @Transactional(readOnly = true)
    public Bank queryObject(Long id) {
        return bankDao.queryObject(id);
    }
}
```  

>  总结：在mapper.xml中会有大量重复代码产生，使用tk.mybatis解决这个问题。  

### 引入之后  

* mapper.xml文件：  

> 对，crud什么都不需要了，除非你有其他新增的业务需求要重写sql语句  

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.dl98.modules.api.dao.financial.BankMapper">
</mapper>
```  
* Dao层  

> 重点是BaseMapper<Bank>  

```java
public interface BankMapper extends BaseMapper<Bank>{
}
```  
```java
/**
 * 功能描述: 公共 Mapper
 */
public interface BaseMapper<T> extends
        Mapper<T>,
        MySqlMapper<T>,
        IdsMapper<T> {
    //TODO
    //FIXME 特别注意，该接口不能被扫描到，否则会出错

    List<T> queryList(Map<String, Object> map);

    int queryTotal(Map<String, Object> map);
}
```
