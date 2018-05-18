---
title: 移动端app分享html5页面跳转到app中
date: 2018-05-18 08:49:24
categories: 前端
tags:
  - Vue
  - Vant
---
# 前言  

## 任务需求  
> 因为我是java后端，app没有涉入，我的工作就是开发一个页面，并进行跳转  

* 点击分享链接跳转到商品详情页面（手机浏览器）  
* 点击商品详情页部分按钮跳转到手机端该应用（安装）或注册页面（未安装）  
* 跳转到app时，把商品ID复制到手机端剪切板，由app端获取跳转到具体商品  

## 知识点  

* Vue  
* vant [轻量、可靠的移动端 Vue 组件库](https://www.youzanyun.com/zanui/vant#/zh-CN/intro)  

## 参考资料  

* [Vue.js+Koa2移动电商实战视频教程](http://jspang.com/2018/04/15/vuekoa/#01)  
> 免费1-5节足够了  
* [h5页面唤起app(iOS和Android),没有安装则跳转下载页面](https://www.cnblogs.com/lyre/p/6169028.html)  

## 运行项目  

### 项目地址  

> 码云项目地址：[my_vue](https://gitee.com/ddebug/my_vue)  

### 效果展示  

* app分享商品链接  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/99281777.jpg)

* 在手机端浏览器内点击，跳转到商品详情页    
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/38867480.jpg)

* 跳转到手机端app应用或注册页面  
> 点击下方店铺、加入购物车、立即购买，如果手机端有该app，跳转进入；如果没有，跳转到注册页面  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/92716597.jpg)

# 开发流程  

## 创建Vue项目并初始化    

参考我的博客：[快速创建Vue简单项目](http://www.ddebug.cn/vue-project-fast-create.html)


## 使用Vant  

### 安装Vant  

```sql
npm i vant -S # 简写形式
npm install vant --save # 完整写法
```

### 引入Vant  

* 安装babel-plugin-import  
> 按需引入组建模块，Vue项目组件库的主流引入方法  

```sql
npm i babel-plugin-import -D  # 简写
npm install babel-plugin-import --save-dev    # 完整写法
```
* .baberlrc中配置plugins(插件)  

```json
"plugins": [
    "transform-vue-jsx", 
    "transform-runtime",
    ["import",{"libraryName":"vant","style":true}]
  ]
```

* 按需使用Vant组件  
> 设置好.babelrc后，就可以按需引入Vant框架。  
> 比如现在我们引入一个Button组件，在src/main.js里加入下面的代码：  

```js
import {Button, Row, Col, Swipe, SwipeItem , Lazyload, Popup, NavBar,Sku,Icon,Panel, Cell, CellGroup,
  GoodsAction, GoodsActionBigBtn, GoodsActionMiniBtn, RadioGroup, Radio ,Stepper } from 'vant'

Vue.use(Button).use(Row).use(Col).use(Swipe).use(SwipeItem).use(Lazyload).use(Popup).use(NavBar).use(Sku).use(Icon)
  .use(GoodsAction).use(GoodsActionBigBtn).use(GoodsActionMiniBtn).use(Panel).use(Cell).use(CellGroup).use(RadioGroup)
  .use(Radio).use(Stepper)
```

* 在需要的组件页面中加入Button  

```vue
<van-button type="primary">主要按钮</van-button>
```

## 剪切板clipboard   

> 点击按钮实现复制功能，主要时转到app应用中传递商品ID  

### 引入clipboard.js  

* 安装  

```sql
npm install clipboard --save
```

## vue-awesome-swiper滑动插件  

参考博客：[使用vue-awesome-swiper滑块插件](https://www.jianshu.com/p/fece694a6959)  

* 安装swiper  

```sql
npm install vue-awesome-swiper --save
```

## 测试接口  

可以在[Easy Mock](https://www.easy-mock.com)自定义获取商品详情信息的接口。  

![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/52977910.jpg)

* json数据参考：  

```json
{    
  "code": 0,
      "data": {        
    "barCode": "0",
            "contentList": [            {                
      "content": "https://static.wdh158.com/61d464d0-1548-45e8-8df2-667e36ee66ec.png",
                      "goodsId": 130,
                      "id": 2978,
                      "orders": 0,
                      "type": 2            
    },              {                
      "content": "https://static.wdh158.com/9b3213b0-d85c-4d12-9983-72149b4fa96c.png",
                      "goodsId": 130,
                      "id": 2979,
                      "orders": 1,
                      "type": 2            
    },              {                
      "content": "https://static.wdh158.com/upload/20180225/fc8e2e19ab1941deaa3de1e5bd68c5de.jpg",
                      "goodsId": 130,
                      "id": 2988,
                      "orders": 2,
                      "type": 2            
    }        ],
            "cover": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
            "deduction": 0,
            "goodId": 130,
            "imageList": [            {                
      "goods_id": 0,
                      "id": 2125,
                      "orders": 1,
                      "source": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
                      "thumb_nail": "",
                      "title": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
                      "type": 1            
    },              {                
      "goods_id": 0,
                      "id": 2126,
                      "orders": 2,
                      "source": "https://static.wdh158.com/fb489355-c1fb-4858-b393-578b3ce28ed3mmexport1519527876761.jpg",
                      "thumb_nail": "",
                      "title": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
                      "type": 1            
    },              {                
      "goods_id": 0,
                      "id": 2127,
                      "orders": 3,
                      "source": "https://static.wdh158.com/d154011c-b61b-48ad-89c7-0f0d028e528bmmexport1519527878772.jpg",
                      "thumb_nail": "",
                      "title": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
                      "type": 1            
    },              {                
      "goods_id": 0,
                      "id": 2134,
                      "orders": 4,
                      "source": "https://static.wdh158.com/upload/20180225/1185961bafbc48e19fdde8db639e4a9b.jpg",
                      "thumb_nail": "",
                      "title": "https://static.wdh158.com/a196ca7f-269e-42f8-b650-874aad573560mmexport1519527875279.jpg",
                      "type": 1            
    }        ],
            "millId": 3,
            "name": "神州亮剑去油王500g×3瓶",
            "parameterList": [            {                
      "cost": 25,
                      "deduction": 0,
                      "fen": 0,
                      "goodsId": 130,
                      "id": 410,
                      "name": "500g/桶 3桶/组",
                      "orders": 1,
                      "price": 36,
                      "stock": 904,
                      "type": 0            
    }        ],
            "price": 36,
            "saleCount": 103,
            "supplierName": "廊坊市芮芙利化工有限责任公司",
            "type": 1,
            "volume": 81    
  },
      "message": "成功",
      "success": true
}
```








