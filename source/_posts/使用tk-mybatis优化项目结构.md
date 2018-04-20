title: 使用tk.mybatis优化Spring Boot项目
categories: 工作日志
tags:
  - mybatis
  - spring boot
date: 2018-04-19 16:19:01
---
#  Spring Boot项目中整合tk.mybatis通用插件  

##  tk.mybatis介绍  
* tk.mybatis是一款强大的MyBatis插件，合理使用会帮你除去大量的mybatis中的mapper.mxl文件里重复的sql语句；
* Spring Boot中已经整合了tk.mybatis插件，使用起来非常方便  
* [Mybatis官方文档地址](http://www.mybatis.tk/)  
* [框架介绍链接](https://blog.csdn.net/shikaiwencn/article/details/52485883)

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

* <font color=#0099ff size=3 face="黑体">mapper.xml示例</font>  

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

* <font color=#0099ff size=3 face="黑体">Dao层代码</font>  

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

* <font color=#0099ff size=3 face="黑体">service接口</font>  

```java
public interface BankService {
    // 新增自定义查询接口
    R updateBank(Bank bank);
    // 修改了原来dao默认的查询接口
    Bank queryObject(Long id);
}
```  

* <font color=#0099ff size=3 face="黑体">service实现层</font>  

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

* <font color=#0099ff size=3 face="黑体">mapper.xml文件</font>  

> 对，crud什么都不需要了，除非你有其他新增的业务需求要重写sql语句  

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.dl98.modules.api.dao.financial.BankMapper">
</mapper>
```  

* <font color=#0099ff size=3 face="黑体">实体类</font>   

> 使用tk.mybatis后，实体类必须使用注解  

```java
@EqualsAndHashCode(callSuper = true)
@Data
@Table(name = "dl_bank")
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(value = {"hibernateLazyInitializer", "handler", "fieldHandler"}, ignoreUnknown = true)
public class Bank extends BaseFullEntity {

    private static final long serialVersionUID = -8252054024694303083L;

    /** 用户 **/
    @Column(name = "user_id")
    private Long userId;

    /** 银行卡所属银行 */
    @Column(name = "bank")
    private String bank;

    /** 银行卡号 */
    @Column(name = "card_no")
    private String cardNo;

    /** 支行 */
    @Column(name = "subbranch")
    private String subbranch;

    /** 姓名 (实名认证的名字) **/
    @Column(name = "name")
    private String name;

    /** 银行卡类型  0=银行卡 1=支付宝？ 2=微信？ **/
    @Column(name = "card_type")
    private Integer cardType;
}
```  

> **@JsonInclude(Include.NON_NULL)**：将该标记放在属性上，如果该属性为NULL则不参与序列化；  
如果放在类上，对整个类的全部属性起作用。[点击详情！](https://www.cnblogs.com/yangy608/p/3936848.html)

> **@JsonIgnoreProperties(value = {"hibernateLazyInitializer", "handler", "fieldHandler"}, ignoreUnknown = true)**：  
* value属性：目的为了阻止Jackson在转化时触发hibernateLazyFetch机制
* ignoreUnknown = true：忽略掉从JSON（由于在应用中没有完全匹配的POJO）中获得的所有“多余的”属性
* 参考资料：<http://wong-john.iteye.com/blog/1753402> <http://hypgr.iteye.com/blog/907549>   

* <font color=#0099ff size=3 face="黑体">Dao层</font>  

> 重点是BaseMapper<Bank>, 
BaseMapper新增了两个通用的自定义的查询接口：queryList和queryTotal  

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

> * 不要把BaseMapper放到同其他Mapper一起，该类不能被当做普通Mapper一样被扫描，否则会出错
* extends的接口参考资料：<https://www.cnblogs.com/deolin/p/8182100.html>  

* <font color=#0099ff size=3 face="黑体">service接口</font>  

```java
public interface BankService extends IService<Bank>{

    /**
     * 功能描述: 更新银行卡信息
     */
    R updateBank(Bank bank);

    Bank queryObject(Long id);
}
```  

> 定义Service层基础接口Iservice<T>，其他Service接口都继承该接口  

```java
@SuppressWarnings("UnusedReturnValue")
public interface IService<T> {

    int save(T entity);

    int save(List<T> list);

    int saveBatch(List<T> list);

    int saveNotNull(T entity);

    int deleteByKey(Object key);

    int deleteByIds(String ids);

    int deleteByIds(Object[] ids);

    int updateAll(T entity);

    int updateNotNull(T entity);

    T selectByKey(Object key);

    List<T> selectByIds(String ids);

    List<T> selectByIds(Object[] ids);

    List<T> selectByExample(Object example);

    /**
     * 功能描述: 列表查询条件 需要实现这个接口
     *
     * 作者: July
     * 日期: 2018-03-22 13:31:29
     */
    List<T> queryList(Map<String, Object> map);

    /**
     * 功能描述: 列表查询条件总数 需要实现这个接口
     *
     * 作者: July
     * 日期: 2018-03-22 13:31:51
     */
    int queryTotal(Map<String, Object> map);
}
```  

* <font color=#0099ff size=3 face="黑体">service实现</font>  

```java
@Service
@Transactional
public class BankServiceImpl extends AbstractService<BankMapper, Bank> implements BankService{

    @Override
    public R updateBank(Bank bank) {
        int Result = updateNotNull(bank);
        return Result == 0 ? R.error("银行卡信息保存失败") : R.ok();
    }

    @Override
    @Transactional(readOnly = true)
    public Bank queryObject(Long id) {
        return selectByKey(id);
    }
}
```  
> 抽象类**AbstractService**基于MyBatis Mapper插件的接口实现，实现了Iservice接口  

```java
@Service("abstractService")
@Transactional
public abstract class AbstractService<M extends BaseMapper<T>, T> implements IService<T> {

    @Autowired
    @SuppressWarnings("all")
    protected M mapper;

    /**
     * 保存一个实体，null的属性也会保存，不会使用数据库默认值
     */
    @Override
    public int save(T entity) {
        return mapper.insert(entity);
    }

    /**
     * 批量插入，支持批量插入的数据库可以使用，例如MySQL,H2等，另外该接口限制实体包含`id`属性并且必须为自增列
     */
    @Override
    public int save(List<T> list) {
        return mapper.insertList(list);
    }

    /**
     * 批量插入，支持批量插入的数据库可以使用，例如MySQL,H2等，另外该接口限制实体包含`id`属性并且必须为自增列
     */
    @Override
    public int saveBatch(List<T> list) {
        return mapper.insertList(list);
    }

    /**
     * 保存一个实体，null的属性不会保存，会使用数据库默认值
     */
    @Override
    public int saveNotNull(T entity) {
        return mapper.insertSelective(entity);
    }

    /**
     * 根据主键字段进行删除，方法参数必须包含完整的主键属性
     */
    @Override
    public int deleteByKey(Object key) {
        return mapper.deleteByPrimaryKey(key);
    }

    /**
     * 根据主键字符串进行删除，类中只有存在一个带有@Id注解的字段
     *
     * @param ids 如 "1,2,3,4"
     */
    @Override
    public int deleteByIds(String ids) {
        return mapper.deleteByIds(ids);
    }

    @Override
    public int deleteByIds(Object[] ids) {
        return mapper.deleteByIds(StringUtils.join(ids, ","));
    }

    /**
     * 根据主键更新实体全部字段，null值会被更新
     */
    @Override
    public int updateAll(T entity) {
        return mapper.updateByPrimaryKey(entity);
    }

    /**
     * 根据主键更新属性不为null的值
     */
    @Override
    public int updateNotNull(T entity) {
        return mapper.updateByPrimaryKeySelective(entity);
    }

    /**
     * 根据主键字段进行查询，方法参数必须包含完整的主键属性，查询条件使用等号
     */
    @Override
    @Transactional(readOnly = true)
    public T selectByKey(Object key) {
        return mapper.selectByPrimaryKey(key);
    }

    /**
     * 根据主键字符串进行查询，类中只有存在一个带有@Id注解的字段
     *
     * @param ids 如 "1,2,3,4"
     */
    @Override
    @Transactional(readOnly = true)
    public List<T> selectByIds(String ids) {
        return mapper.selectByIds(ids);
    }

    @Override
    @Transactional(readOnly = true)
    public List<T> selectByIds(Object[] ids) {
        return mapper.selectByIds(StringUtils.join(ids, ","));
    }

    /**
     * 根据Example条件进行查询
     */
    @Override
    @Transactional(readOnly = true)
    public List<T> selectByExample(Object example) {
        return mapper.selectByExample(example);
    }

    /**
     * 功能描述: 列表查询条件 需要实现这个接口
     */
    @Override
    @Transactional(readOnly = true)
    public List<T> queryList(Map<String, Object> map) {
        return mapper.queryList(map);
    }

    /**
     * 功能描述: 列表查询条件总数 需要实现这个接口
     */
    @Override
    @Transactional(readOnly = true)
    public int queryTotal(Map<String, Object> map) {
        return mapper.queryTotal(map);
    }
}
```  

## 总结  
整体引入tk.mybatis通用插件，新增基础接口**BaseMapper.java**、**Iservice**、**AbstractService**优化了项目结构，  
当新增业务时，减少代码量。  
