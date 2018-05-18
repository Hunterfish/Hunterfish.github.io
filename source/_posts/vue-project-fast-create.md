---
title: 快速创建Vue简单项目
date: 2018-05-18 10:10:12
categories: 前端
tags:
  - Vue
  - Node.js
---
# 前言  

## 需求

工作中经常遇到html5单页面项目的需求，所以学习了一下Vue，因为经常忘记，造成反复查询资料，再次总结一下Vue项目快速创建！  

## 运行  

我已经上传到码云上了：[my-vue](https://gitee.com/ddebug/my_vue)   

参考[移动端app分享html5页面跳转到app中](http://www.ddebug.cn/app-share-page-vue-vant.html)  

### 直接运行  

```sql
git clone "xxxx"
npm i
npm run dev
```

### 变成自己的  

> 删除上面博客引用的以下内容即可  

* package.json  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/2047295.jpg)

* Vue组件页面  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/7360608.jpg)

* 开发/生产环境接口地址  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/91189189.jpg)

## Vue特点  

* [Vue官方地址](https://cn.vuejs.org/)  
* 前后端分离的开发思想，调用后端提供的JSON接口，没有任何耦合；  
* 开发环境完全分离，开发完成后可以分别部署到两个不同的服务器运行。

## 参考资料  

> 参考的博客非常丰富，基础环境Node.js等搭建、Vue项目初始化流程都有    

* [Vue2+VueRouter2+webpack 构建项目实战](https://blog.csdn.net/fungleo/article/details/53171052)
* [Vue2项目构建心得](https://www.jianshu.com/p/87a4fe7bf0b1)
* [手摸手，带你用vue撸后台系列](https://segmentfault.com/a/1190000009275424)  

# Vue项目快速创建  

## 初始化项目  

### 建立前端文件夹  

```jshelllanguage
mkdir my_vue
```
### 初始化Vue项目

* cnpm安装  

> 淘宝源，国内比较快  

```sql
npm install vant --save --registry=https://registry.npm.taobao.org
```

* 全局安装vue-cli Vue脚手架   

```sql
npm install vue-cli -g
```
* 初始化vue项目  

```sql
cd my_vue
vue init webpack
npm install
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/53561962.jpg)

* 测试是否初始化成功  
> 在浏览器中输入**http://localhost:8080**进行测试  

```sql
npm run dev
```
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/10422759.jpg)

### 配置生产环境和发布环境的接口地址
> config/目录下  

参考链接：<https://blog.csdn.net/sxy1847589546/article/details/79290288>

* 项目结构图  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/99117323.jpg)

* dev.env.js  

```js
'use strict'
const merge = require('webpack-merge')
const prodEnv = require('./prod.env')

module.exports = merge(prodEnv, {
  NODE_ENV: '"development"',
  BASE_API: '"http://test.ldd158.com/api/v1"'   // 开发环境路径
})
```

* prod.env.js  

```js
'use strict'
module.exports = {
  NODE_ENV: '"production"',
  BASE_API: '"http://api.ldd158.com/api/v1"',
}
```

### 封装公用axios工具  

* 安装axios  

```sql
npm install axios -D
```

* 项目结构图：  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/56402245.jpg)

* source/api/request.js添加如下内容：  
> 根据自己项目定义的接口格式来修改内容  

```js
import axios from 'axios'

// 创建axios实例
const service = axios.create({
  baseURL: process.env.BASE_API,  // 开发/生产环境url
  timeout: 5 * 1000 // 请求超时时间
});

// 添加响应拦截器
service.interceptors.response.use(
  // 对响应数据做点什么
  response => {
    /**
     * 下面的注释为通过response自定义code来标示请求状态，当code返回如下情况为权限有问题，登出并返回到登录页
     * 如通过xmlhttprequest 状态码标识 逻辑可写在下面error中
     */
    const res = response.data;
    //console.log(res);
    /*if (res.code !== 0) {
      Message({
        message: res.message,
        type: 'info',
        duration: 2 * 1000
      });
    }*/
    return response
  },
  // 对响应错误做点什么
  error => {
    const res = error.response;
    return Promise.reject(error)
  }
);
export default service
```

* api.js  
> 此处写vue页面中需要使用的接口  

```js
import request from './request'

// 测试参考
/*export const getRedDetail = (id) => request.get('/user/findByMobile', {params: {id: id}})
export const doPayConfirm = (params) => request.post('/pay/qrPay/qrPay', params)
export const register = (mobile, spreadMobile) => request('/user/register', {method: 'post', params: {mobile: mobile, spreadMobile: spreadMobile}})
export const findByMobile = (mobile) => request.get('/user/findByMobile', {params: {mobile: mobile}})
export const sendCode = (mobile) => request('/sms/sendCode', {method: 'post', params: {mobile: mobile, type: 1}})
export const verifyCode = (mobile, code) => request('/sms/verify', {method: 'post', params: {mobile: mobile, code: code, type: 1}})*/
export const goodsDetail = (goodsId) => request.get('/life/goods/detail', {params: {goodsId: goodsId}})

```

### 路由设置  

* 项目结构图  
![](http://p8hqd7oln.bkt.clouddn.com/18-5-18/49789087.jpg)

* _import_development.js  

```js
module.exports = file => require('@/views/' + file + '.vue').default; // vue-loader at least v13.0.0+
```
* _import_production.js  

```js
module.exports = file => () => import('@/views/' + file + '.vue');
```
* index.js  
```js
import Vue from 'vue'
import Router from 'vue-router'

const _import = require('./_import_' + process.env.NODE_ENV);

Vue.use(Router)

export const constantRouterMap = [
  // 样式
  {path: '/goods', name: '商品详情', component: _import('goods/GoodsDetail'), meta: {title: '商品详情'}}
];

const router = new Router({
  routes: constantRouterMap
});

router.beforeEach((to, from, next) => {
  /* 路由发生变化修改页面title */
  if (to.meta.title) {
    document.title = to.meta.title
  }
  next()
});

export default router

```
  








