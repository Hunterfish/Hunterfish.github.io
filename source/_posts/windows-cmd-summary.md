---
title: Windows cmd常用命令总结
date: 2018-05-30 09:42:07
categories: 总结大全
tags:
  - Windows
  - cmd
---

# 端口占用  

参考：[Windows查看所有的端口及端口对应的程序](https://blog.csdn.net/hu_wen/article/details/53783726)  

1. Windows下查看所有端口  

```jshelllanguage
netstat -ano
```

2. 查询指定的端口占用的PID号   

```jshelllanguage
netstat -ano|findstr "8080"
```

3. 查询PID对应的进程  
> 如果上面查询的PID号为"233"  

```jshelllanguage
tasklist|findstr "233"
```

4. 杀死进程  

> 我们也可以在任务管理器中  

```jshelllanguage
taskkill /f /t /im 程序名
```
