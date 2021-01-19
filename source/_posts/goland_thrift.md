---
title: 如何在GoLand安装Thrift插件
date: 2021-01-18 17:30:24
tags:
- GoLand
categories:
- 插件
---
由于现在thrift support插件已经不支持GoLand，无法在市场搜索安装，经上网搜索后找到了另一种安装的方法。
<!-- more -->
- Clone插件源码[fkorotkov/intellij-thrift](https://github.com/fkorotkov/intellij-thrift)
- 删掉[thrift/src/main/resources/META-INF/plugin.xml](https://github.com/fkorotkov/intellij-thrift/blob/master/thrift/src/main/resources/META-INF/plugin.xml#L123) 文件中的`<depends>com.intellij.modules.java</depends>`
- 根据README，build项目: `./gradlew :thrift:buildPlugin`(注: jdk不能高于11)
- 找到`$intellij-thrift/thrift/build/libs/plugin.jar`，使用GoLand的硬盘安装安装该插件
![install](/image/goland_thrift/install.png)