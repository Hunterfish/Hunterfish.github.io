title: 我的博客创建之旅
categories: 杂谈
tags:
  - 杂谈
date: 2018-04-17 09:48:40
---
# 我的博客搭建  

## 前言  
通过一年的学习，最近想搭建一个博客网站，一是可以记录自己的学习历程，二是可以总结学习知识。  
最后最不重要的一点就是可以装B了！

## 技术选择  
> hexo, github, git, hexo-admin, node.js, npm

## 搭建流程  
  因为网上资源很多，所以只是整理资料，然后挑出重点总结。  
  
### 常规
* 1、 **[Hexo从零开始到搭建完整](https://www.cnblogs.com/visugar/p/6821777.html)**  
* 2、 **[将Hexo博客同时托管到github和coding](https://www.cnblogs.com/tengj/p/5352572.html)**  
* 3、 **[Hexo Next主题使用](http://theme-next.iissnan.com/getting-started.html)**
* 4、 **[Hexo常用命令](https://segmentfault.com/a/1190000002632530)**
* 5、 **[markdown常用语法](https://www.cnblogs.com/liugang-vip/p/6337580.html)**  

### 进阶  
* 1、 **[基于Hexo的全自动博客构建部署系统](http://kchen.cc/2016/11/12/hexo-instructions/)**
* 2、 **[Hexo站点域名配置](https://www.cnblogs.com/penglei-it/p/hexo_domain_name.html)**  
* 3、 **[Hexo博客多终端同步问题](https://blog.csdn.net/Monkey_LZL/article/details/60870891)**
* 4、 **[畅言评论系统](https://www.jianshu.com/p/5888bd91d070)**  
* 5、 **[Hexo-admin本地编辑上传博客](https://www.jianshu.com/p/68e727dda16d)**  
* 6、 **[Hexo-admin 哈希值密码创建](http://lxj-life.com/2017/08/08/Hexo%E6%8F%92%E4%BB%B6-admin/)**  
* 7、 **[将Hexo部署到阿里云主机VPS](https://blog.csdn.net/fjinhao/article/details/77096951)**  
* 8、 **[博客极简图床+七牛云](https://www.jianshu.com/p/7cbd50058ea3)**  
* 9、 **[解决谷歌百度收录问题](https://www.cnblogs.com/tengj/p/5357879.html)**   

### 优化  
* 1、 **[Hexo高阶教程各种优化](https://blog.csdn.net/sunshine940326/article/details/70936988)**  
* 2、 **[Hexo定制&优化](https://www.jianshu.com/p/3884e5cb63e5)**
* 3、 **[为Hexo博客标题自动添加序号：hexo-heading-index](http://r12f.com/posts/adding-index-to-your-headings-with-hexo-heading-index/)**  
* 4、 **[hexo的next主题个性化配置教程](https://segmentfault.com/a/1190000009544924)**  

## 操作流程  
* 1 [我的博客项目](https://github.com/Hunterfish/Hunterfish.github.io)分支情况：  
    > master分支：部署博客（存放部署后静态页面文件）的分支
    > hexo分支：我们可以clone到其他电脑或其他系统的hexo源文件的分支，而且我们已经将它设置成默认仓库
* 2 在新的电脑端clone远程仓库hexo分支到本地
    > git clone -b hexo git@github.com:yourname/yourname.github.io.git  

* 3 初始化并新建博客部署   

```java
npm install hexo-cli -g     // 全局安装hexo
cd yourname.github.io
npm install
hexo new post "new blog name" // 新建一个.md文件，你可以编辑博客内容
git add source
git commit -m "XX"
git push origin hexo
hexo clean
hexo g
gulp build  // gulp插件，优化静态文件
hexo d      // //push更新完分支之后将自己写的博客对接到自己搭的博客网站上，同时同步了Github中的master
```
## 遇到问题  

* 1、 **hexo s -d 启动后，但是访问<http://localhost:4000>一直无法访问**  

> 可能是4000端口号被占用，hexo s -d -p 5000 更换端口