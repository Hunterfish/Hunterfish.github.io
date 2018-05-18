---
title: 了解并使用Redis缓存
date: 2018-05-09 14:39:47
categories: Spring Boot微信点餐项目
tags:
  - Redis
  - 缓存
  - Spring Boot
---

# Redis缓存  

## 特点  

> 大流量场景环境下，有效提高数据读取速度；  

* 命中  
> 用户从cache中获取数据，取到后返回  
* 失效  
> 缓存时间到时  
* 更新  
> 应用程序把数据存到数据库中，再放到缓存中  

## 准备  

* Spring Boot微信点餐项目  
* 项目启动参考<xxxxxxxxxxxxxx>  

## 学习点  

1. @EnableCaching、@Cacheable、@CachePut、@CacheEvict  
2. 相关对象实现序列化  
3. 使用缓存要结合业务场景，避免滥用  

# 如何优雅的使用缓存  

## 常规使用  

### 代码内容  

> 实体类和页面展示类需要实现序列化，可参考[我的idea使用总结](https://www.ddebug.cn/my-idea-summary.html)  

* SellApplication.java   

> 项目启动类添加注解 **@EnableCaching**  

```java
@SpringBootApplication
@EnableCaching
public class SellApplication {

	public static void main(String[] args) {
		SpringApplication.run(SellApplication.class, args);
	}
}
```

* BuyerProductController.java  

> 在商品列表接口上添加注解 **@Cacheable**  

```java
@GetMapping("/list")
    @Cacheable(cacheNames = "product", key = "123")
    public ResultVO list() {
        // 1. 查询所有上架的商品
        List<ProductInfo> productInfoList = productService.findUpAll();

        // 2. 查询类目（一次性查询）
        // 传统方法
//        List<Integer> categoryTypeList = new ArrayList<>();
//        for (ProductInfo productInfo : productInfoList) {
//            categoryTypeList.add(productInfo.getCategoryType());
//        }

        // 精简方法（Java8，lambda）
        List<Integer> categoryTypeList = productInfoList.stream()
                .map(e -> e.getCategoryType())
                .collect(Collectors.toList());
        List<ProductCategory> productCategoryList = categoryService.findByCategoryTypeIn(categoryTypeList);

        // 3. 数据拼装
        List<ProductVO> productVOList = new ArrayList<>();
        for (ProductCategory productCategory : productCategoryList) {
            ProductVO productVO = new ProductVO();
            productVO.setCategoryType(productCategory.getCategoryType());
            productVO.setCategoryName(productCategory.getCategoryName());

            List<ProductInfoVO> productInfoVOList = new ArrayList<>();

            for (ProductInfo productInfo : productInfoList) {
                if (productInfo.getCategoryType().equals(productCategory.getCategoryType())) {
                    ProductInfoVO productInfoVO = new ProductInfoVO();
                    BeanUtils.copyProperties(productInfo, productInfoVO);
                    productInfoVOList.add(productInfoVO);

                }
            }
            productVO.setProductInfoVOList(productInfoVOList);
            productVOList.add(productVO);
        }
        return ResultVOUtil.success(productVOList);
    }
```

### 效果演示  

* 启动项目  

> 在controller接口中打断点，访问：
http://hunterfish.ngrok.xiaomiqiu.cn/sell/buyer/product/list    

> 访问后，会在断点处停止；    

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/11466847.jpg)

* 再次访问上面链接  

> 发现不会经过断点，测试已经从redis缓存中获取数据了  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/66300248.jpg)

### 问题  

> 当我们修改商品数据保存到数据库后，再次访问，发现redis缓存数据没有变化  

## 缓存内容更新时  

> 当我们查询数据已经更新（数据库），同时也要**更新缓存数据**  

* SellerProductController.java  

> 保存/更新接口：save()添加注解 **@CachePut** 或者 **@CacheEvict**  

> 因为此处更新数据的接口缓存的是**ModelAndView**，并不是查询接口的ResultVO，所以此处使用**@CacheEvict**删除缓存，在查询接口时重新生成缓存，而不是更新。  

```java
@PostMapping("/save")
    // @CachePut(cacheNames = "product", key = "123")  // 更新缓存
    @CacheEvict(cacheNames = "product", key= "123") // 删除缓存
    public ModelAndView save(@Valid ProductForm form,
                             BindingResult bindingResult,
                             Map<String, Object> map) {
        if (bindingResult.hasErrors()) {
            map.put("msg", bindingResult.getFieldError().getDefaultMessage());
            map.put("url", "/sell/seller/product/index");
            return new ModelAndView("common/error", map);
        }

        ProductInfo productInfo = new ProductInfo();
        try {
            //如果productId为空, 说明是新增
            if (!StringUtils.isEmpty(form.getProductId())) {
                productInfo = productService.findOne(form.getProductId());
            } else {
                form.setProductId(KeyUtil.genUniqueKey());
            }
            BeanUtils.copyProperties(form, productInfo);
            productService.save(productInfo);
        } catch (SellException e) {
            map.put("msg", e.getMessage());
            map.put("url", "/sell/seller/product/index");
            return new ModelAndView("common/error", map);
        }

        map.put("url", "/sell/seller/product/list");
        return new ModelAndView("common/success", map);
    }
```

## 使用@CacheConfig  

> 如果我们就是想更新，而不是删除缓存，我们可以在Service层使用注解  

> @CacheConfig、@Cacheable、@CachePut  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-10/99533631.jpg)

## 使用condition、unless   

1. **key="#sellerId"**  
> [spel表达式](https://blog.csdn.net/ya_1249463314/article/details/68484422)，获取接口参数的值  

2. **condition="#sellerId.length() > 3"**  
> 判断条件，当请求参数sellerId的长度大于3时，才缓存返回结果ResultVO  

3. **unless="#result.getCode() != 0"**  
> unless是"如果不"的意思,即当返回结果ResultVO的code为0时，执行缓存  

4. 测试URL  
> http://127.0.0.1:8080/sell/buyer/product/list?sellerId=123457  

