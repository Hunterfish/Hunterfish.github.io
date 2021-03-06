---
title: 我的idea使用总结
date: 2018-05-09 15:39:02
categories: 开发工具
tags:
  - idea
---

参考[IntelliJ IDEA 使用教程](http://wiki.jikexueyuan.com/project/intellij-idea-tutorial/)  

# 序列化插件  

## 效果  

* Ctrl+Shift+s：生成序列化ID **serialVersionUID**  

![图片](http://p8hqd7oln.bkt.clouddn.com/18-5-10/30770183.jpg)

## idea插件安装  

![图片](http://p8hqd7oln.bkt.clouddn.com/18-5-10/97346624.jpg)

## 插件设置快捷键  

![图片](http://p8hqd7oln.bkt.clouddn.com/18-5-10/66397016.jpg)

# IDEA终端Terminal  

参考[修改 Idea 终端 Terminal 为 GitBash 或 Cmder](https://segmentfault.com/a/1190000012717033); 修改为gitbash比较好，Cmder存在中文乱码问题  

# 常用快捷键  

1. [Intellij IDEA神器居然还有这些小技巧](https://blog.csdn.net/linsongbin1/article/details/80211919)  

# git 忽略已提交文件  

一次项目``target``文件竟然提交到git仓库里，idea自动生成的.gitignore文件可能没有忽略掉target文件。

1. 新增下面文件  

```xml
target/
*.war
*.ear
*.zip
*.tar
*.tar.gz
```

2. ``git rm -rf --cached .``  
> 把本地缓存删除（改变成未track状态）  

3. ``git add .``  
4. ``git commit -m "update .gitignore"``  

# 翻译插件  

github: [TranslationPlugin](https://github.com/YiiGuxing/TranslationPlugin)  

# mybatis插件  

``mybatis-plus2.92``: 链接: https://pan.baidu.com/s/1uydTqyurhDSe7g72Te9HdQ 提取码: w355 




