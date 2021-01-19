---
title: Go的学习笔记
date: 2020-08-31 11:47:50
tags:
- go
categories:
- GO
---
学习Go过程中记录下来的点点滴滴
<!-- more -->
1. 值接收者和指针接收者
值接收者：func (x TypeName) TethodName(params…) params...
指针接收者：func (x *TypeName) TethodName(params…) params…
区别：指针会直接改动原结构体的值，值接收者不会

2. ![类型选择](/image/Lark20200831-142222.png)
3. ![Stringer](/image/Lark20200831-142523.png)
4. GO的一个隐性bug：https://studygolang.com/articles/23930
   	看源码应该是sprint中会判断error类型，error类型又会再次调用print，导致递归内存溢出
5. 可以使用struct{}来表示如Java中的Object类，可以用来充当标志位属性
6. 可以使用nil chan来控制select模块
7. 要注意slice的使用：
   不要对临时slice进行值修改，这可能会导致原数组的更改，应该先使用copy
8. 继承：如果你确实需要原有类型的方法，你可以定义一个新的struct类型，用匿名方式把原有类型嵌入其中。
9. 被defer的函数的参数会在defer声明时求值（而不是在函数实际执行时）
10. interface变量仅在类型和值为“nil”时才为“nil”。interface的类型和值会根据用于创建对应interface变量的类型和值的变化而变化。
11. 调度器会在GC、“go”声明、阻塞channel操作、阻塞系统调用和lock操作后运行。它也会在非内联函数调用后执行。如果存在不允许调度器运行的for循环出现时，其他goroutine就无法被执行
12. go的格式化输出/log：https://www.cnblogs.com/liubiaos/p/9367504.html
13. Go的单例，可通过type的命名大小写，控制外部文件的访问

## Benchmark

可以使用benchmark进行性能比较
```shell
go test -bench=. -benchmem -benchtime=1s
```
* bench regexp：性能测试，支持表达式对测试函数进行筛选。-bench .则是对所有的benchmark函数测试
* -benchmem：性能测试的时候显示测试函数的内存分配的统计信息
* -benchtime：指定运行时间
* -cpuprofile/memprofile <filename>：输出pprof
* -count n：运行测试和性能多少此，默认一次
* -run regexp：只运行特定的测试函数， 比如-run ABC只测试函数名中包含ABC的测试函数
* -timeout t：测试时间如果超过t, panic,默认10分钟
* -v：显示测试的详细信息，也会把Log、Logf方法的日志显示出来
* -cpu

```shell
goos: darwin
goarch: amd64
pkg: aven/myUtil
BenchmarkMap-8           2129355      1131 ns/op     167 B/op     2 allocs/op
BenchmarkSyncMap-8       4758883       603 ns/op     196 B/op     5 allocs/op
```
* BenchmarkMap-8：-cpu参数指定，-8表示8个CPU线程执行
* 2129355：表示总共执行了2129355次
* 1131 ns/op：表示每次执行耗时1131纳秒
* 167 B/op:表示每次执行分配的内存（字节）
* 2 allocs/op：表示每次执行分配了2次对象

## PProf
```shell
$ go tool pprof <filename>
...
...
(pprof) top         #查看所有
(pprof) list <func> #具体某个函数
(pprof) web         #生成图像, 需安装graphviz(brew install)
```
* 使用go原生工具查看火焰图：`go tool pprof -http=":8081" [binary] [profile]`
