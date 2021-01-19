---
title: 面经
categories:
  - 面试
date: 2020-08-30 01:01:50
---
春招实习以及秋招的面经
<!-- more -->
# 春招
oc: 华为、字节、美团

## 腾讯一面(未知部门)
1. mysql varchar和char
    char是固定长，初始长度是多少，赋值之后就是多长
    varchar是可变长，赋值长度与初始长度无关
2. mysql建表规则
3. hashmap和treemap
    hashmap不会排序，treemap会根据comparator进行排序
4. ArrayList和linkedlist
    linkedlist是双向链表非循环
5. java基本类型
    byte 1
    short 2
    int 4
    long 8
    float 4
    double 8
    char 2
    boolean 1
6. jvm
    jvm是java虚拟机，用来运行java编译后的字节码文件(.class)，做到一次编译多次运行(跨平台)
7. collection的方法
    add remove contains iterator size isEmpty
8. static方法访问非static变量
    类的静态成员（变量和方法）都属于类本身，在类加载的时候就会分配内存，可以通过类名直接访问
9. java多继承
    1、若子类继承的父类中拥有相同的成员变量，子类在引用该变量时将无法判别使用哪个父类的成员变量
    2、若一个子类继承的多个父类拥有相同方法，同时子类并未覆盖该方法（若覆盖，则直接使用子类中该方法），那么调用该方法时将无法确定调用哪个父类的方法。
10. 乐观锁 悲观锁
    悲观：总是假设最坏的情况，每次去拿数据的时候都认为别人会修改，所以每次在拿数据的时候都会上锁，这样别人想拿这个数据就会阻塞直到它拿到锁（共享资源每次只给一个线程使用，其它线程阻塞，用完后再把资源转让给其它线程）。
    乐观：总是假设最好的情况，每次去拿数据的时候都认为别人不会修改，所以不会上锁，但是在更新的时候会判断一下在此期间别人有没有去更新这个数据，可以使用版本号机制和CAS算法实现
11. StringBuilder StringBuffer
12. 单例
    懒汉和饿汉
13. 异常
14. sql: 班级前三
    select * from class c where 3 > (select count(distinct score) from class where clazz = c.clazz and score > c.score);


## 腾讯一面(IEG)
1. 算法：删除倒数第k节点
2. tcp/udp的区别 视频/语音为什么使用udp
3. 4次挥手时的timewait
4. tcp中的流量控制和拥塞控制
5. 进程和线程
6. 进程的调度
7. 进程的通信方式
8. 大端和小端系统
9. 队列能否不使用锁进行并发
10. 队列要用多少个堆实现
11. 静态链接和动态链接
12. C++的多态(Java)
13. 僵尸进程
    https://www.cnblogs.com/Anker/p/3271773.html


## 字节一面
1. 算法：链表反转(m到n)
2. mysql索引 最左索引
3. visitor模式
4. 进程和线程
5. 进程通信
6. 线程同步
7. java锁
8. synchronize方法和代码块
9. synchronize怎么做到可重入
10. CAS 以及哪些领域同样用到cas
11. tcp4次挥手 为什么
12. 


## 阿里二面(几乎都是开放性问题)
1. 进程切换
    进程切换分两步：

    1.切换页目录以使用新的地址空间

    2.切换内核栈和硬件上下文

    对于linux来说，线程和进程的最大区别就在于地址空间，对于线程切换，第1步是不需要做的，第2是进程和线程切换都要做的。

    1、（中断／异常等触发）正向模式切换并压入PSW／PC 。 （Program Status Word 程序状态字。program counter 程序计数器。指向下一条要执行的指令）

    2、保存被中断进程的现场信息。

    3、处理具体中断、异常。

    4、把被中断进程的系统堆栈指针SP值保存到PCB。（Stack Pointer 栈指针。Process Control Block 进程控制块。）

    5、调整被中断进程的PCB信息，如进程状态）。

    6、把被中断进程的PCB加入相关队列。

    7、选择下一个占用CPU运行的进程。

    8、修改被选中进程的PCB信息，如进程状态。

    9、设置被选中进程的地址空间，恢复存储管理信息。

    10、恢复被选中进程的SP值到处理器寄存器SP。

    11、恢复被选中进程的现场信息进入处理器。

    12、（中断返回指令触发）逆向模式转换并弹出PSW／PC。

2. 页表
3. tcp如何保证可靠
4. tcp如何保证正确性 校验和原理？
    1.把伪首部添加到UDP上；
    2.计算初始时是需要将检验和字段添零的；
    3.把所有位划分为16位（2字节）的字
    4.把所有16位的字相加，如果遇到进位，则将高于16字节的进位部分的值加到最低位上，举例，0xBB5E+0xFCED=0x1 B84B，则将1放到最低位，得到结果是0xB84C
    5.将所有字相加得到的结果应该为一个16位的数，将该数取反则可以得到检验和checksum。

5. 10亿订单，每个区间取topk
6. 10亿订单存在哪里可以取出来
7. java能否多进程(多进程编程)
    使用Process和Runtime进行多进程编程
8. java内存管理
9. 回收机制
10. 堆的内存泄漏
11. 如何管理内存泄漏问题(工具)
    jps (JVM Process Status）: 类似 UNIX 的 ps 命令。用户查看所有 Java 进程的启动类、传入参数和 Java 虚拟机参数等信息；
    jstat（ JVM Statistics Monitoring Tool）: 用于收集 HotSpot 虚拟机各方面的运行数据;
    jinfo (Configuration Info for Java) : Configuration Info forJava,显示虚拟机配置信息;
    jmap (Memory Map for Java) :生成堆转储快照;
    jhat (JVM Heap Dump Browser ) : 用于分析 heapdump 文件，它会建立一个 HTTP/HTML 服务器，让用户可以在浏览器上查看分析结果;
    jstack (Stack Trace for Java):生成虚拟机当前时刻的线程快照，线程快照就是当前虚拟机内每一条线程正在执行的方法堆栈的集合。

    JConsole:Java 监视与管理控制台
        连接 Jconsole
        查看 Java 程序概况
        内存监控
        线程监控
    Visual VM:多合一故障处理工具

12. 输入http之后的流程
13. java多线程(自己的看法)
14. 线程池设置多少合理
15. 如何让udp可靠


## 字节二面(几乎都是为什么)
1. http输入之后的过程
2. dns的解析过程
3. ip传输的过程
    https://blog.csdn.net/thisispan/article/details/7587998
4. 整个请求传输的过程
5. 什么时候用tcp udp，什么场景下，为什么
6. html响应解析渲染的过程
7. html head里有什么元素
8. 什么时候要多线程，什么时候要多进程
    https://blog.csdn.net/yu876876/article/details/82810178
    https://www.cnblogs.com/yuanchenqi/articles/6755717.html
9. 如登陆，如何保证安全性
10. 后端如何保证
11. 加密算法
12. 算法：k个一组地翻转链表


## 美团一面
1. HashMap的实现原理，插入如果冲突，是插入头部还是尾部
2. 是否线程安全，哪些是线程安全的
3. ConcurrentHashMap如何做到线程安全
4. ConcurrentHashMap的size()如何实现
5. LinkedHashMap的区别
6. 多线程都用什么来开发
7. ThreadPoolExcutor的参数，队列使用的是哪种，是否设置初始值，无界队列是否可以
8. ThreadPoolExcutor如何操作，原理
9. Excutors.newFixed()的缺点
10. 其他的线程池方法
11. 线程如何做到交替运行
12. 多线程如何做到顺序执行
13. 线程如何做到等待其他线程完成后执行
14. synchronized和lock的区别
15. mysql的隔离级别
16. mysql的默认隔离级别
17. 幻读是什么
18. mysql的可重复读是否可以防止幻读
19. b树和b+树的区别
    https://blog.csdn.net/z702143700/article/details/49079107   
20. b+树用作索引的数据结构优势在哪
21. 平衡二叉树与红黑树的区别
    https://blog.csdn.net/theshowlen/article/details/92184314
22. 算法：用stack实现queue


## 美团二面
1. 网络协议有哪些
2. ThreadLocal的作用，是否线程安全
3. 进程间的通信，java进程间的通信
    1、如果Java中要涉及到多进程之间交互，子进程只是简单的做一些功能处理的话建议使用
    Process p = Runtime.getRuntime().exec("java ****类名");
    p.getOutputStream()
    p.getInputStream() 的方式进行输入、输出流的方式进行通信
    如果涉及到大量的数据需要在父子进程之间交互不建议使用该方式，该方式子类中所有的System都会返回到父类中，另该方式不太适合大并发多线程
    2、内存共享(MappedByteBuffer)
    该方法可以使用父子进程之间通信，但在高并发往内存内写数据、读数据时需要对文件内存进行锁机制，不然会出现读写内容混乱和不一致性，Java里面提供了文件锁FileLock，但这个在父/子进程中锁定后另一进程会一直等待，效率确实不够高。
    RandomAccessFile raf = new RandomAccessFile("D:/a.txt", "rw");
    FileChannel fc = raf.getChannel(); 
    MappedByteBuffer mbb = fc.map(MapMode.READ_WRITE, 0, 1024);
    FileLock fl = fc.lock();//文件锁
    3、Socket 这个方式可以实现，需要在父子进程间进行socket通信
    4、队列机制 这种方式也可以实现，需要父/子进程往队列里面写数据，子/父进程进行读取。不太好的地方是需要在父子进程之间加一层队列实现，队列实现有ActiveMQ,FQueue等
    5、通过JNI方式，父/子进程通过JNI对共享进程读写
    6、基于信号方式，但该方式只能在执行kill -12或者在cmd下执行ctrl+c 才会触发信息发生。

4. TreeMap讲解，里面有什么属性，entry里有什么属性
5. java里有哪些是不需要加锁的同步方法
6. 行锁和表锁的区别、场景
7. 组合索引的使用，eg. (a, b, c)索引，where a=x; where b=x; where a=x and b=x;哪个能使用索引
8. ArrayList和linkedlist的区别
9. 有哪些集合类是线程安全的
10. blockingqueue什么场景下使用
11. java有哪些锁
12. 算法：排好序的数组，找2个数的和为M的所有组合
13. 算法：大数据下，找出出现频率topK的ip
14. 在Hadoop/Spark下如何实现
15. 看过哪些书
16. 动态代理
    https://www.jianshu.com/p/95970b089360
17. java还有哪些像cas的线程同步


## 字节三面
1. 最近的项目(我应该说最熟悉的那个。。)
2. 写懒加载单例 为什么里外层null判断 为什么加volatile 如何做到复用(泛型)
3. 算法：(login, logout)，算出在线人数峰值
4. 算法：一组边，做成树结构(左点为父，右点为子)
5. mysql：每个班级中某科目前10，如何建立索引优化


## 阿里评估
1. 问项目，所有涉及的项目
2. mysql中索引的区别
3. springboot所带来的便利，内嵌容器与直接运行的区别
4. 对Collection的了解
5. 接口和抽象的区别
6. 

## 腾讯一面()
1. mysql： 现有一个工资管理系统，包含三张表： department、 employee、salary。
    表结构分别为：
    department:  [id: 部门ID, name: 部门名称]
    employee: [id:员工ID, department_id: 部门ID, name:员工名称]
    salary:[id:薪水记录ID, employee:员工ID, year:薪水所在年份,month:薪水所在月份,money:每月薪水]
2. 算法题： 人民币有1角，5角，1元，5元，10元，20元，50元，100元几种币值，请写一个程序，任意给一个货币金额，请用最少的货币个数表示这个货币金额。
3. 大数据： 2个1T的QQ号文件，32G的内存，如何找出重复的QQ
    可以直接使用bitmap解决：32G内存可以表示32G * 8 = 2^38个QQ号，而QQ号长度假设为8，则1T文件中大概会有1T / 8 = 2^37个QQ号，大致是够用的
4. 线程池原理，threadlocal
5. tcp udp区别，tcp的4次挥手
6. 吃鸡用tcp还是udp？
7. 客户端发起10次服务调用，udp和tcp场景下，服务端调用的次数？
8. 多态的描述
9. 抽象和接口
10. 浅克隆和深克隆
11. 线程和进程的区别
12. 进程的同步
13. 死锁的条件，如何解决死锁
14. 进程句柄在内存中的结构
15. http中keep-alive的作用
16. 301 302 404 502的意义
17. CAS的原理，缺点，如何解决ABA问题
18. 静态内部类和非静态内部类

## 华为一面()
1. 算法题：全排列 + 字典序

# 秋招
oc：网易互娱、字节、shopee、华为

## 腾讯一面(音乐源)
1. jvm内存 java堆与元空间的区别
2. springboot的优点
3. springboot的类加载
4. jvm的类加载
5. jvm的启动过程
6. 内存溢出和内存泄漏
7. 如何解决内存溢出/泄漏问题
8. 最熟悉的数据库
9. 悲观锁和乐观锁，分别使用的场景
10. 你的优势or你做的最满意的
11. rpc调用机制
12. 如何实现方法调用
13. 服务发现、服务注册
14. consul如何做到
15. 服务熔断
16. hive、hbase的存储
17. 列式存储和行式存储，列式存储的实现
18. mysql acid
19. mysql如何做到事务回滚
20. mysql什么时候行级锁、什么时候表级锁
21. arraylist和hashmap的底层实现 扩容机制
22. 数据库主从同步 如何做 基于redolog/undolog
23. mysql 使用for update什么时候行级锁什么时候表级锁

## shopee一面
1. 算法：数组和target，找出每对乘积为target的数
2. 虚拟内存 32位的大小
3. tcp和udp 什么场景 流量控制
4. mysql 什么是事物 acid 隔离级别
5. innodb的默认隔离级别 能阻止什么情况
6. acid每个机制分别通过什么来实现(redolog undolog mvcc)
7. 索引是什么，优缺点，为什么用b+树，不用hash表、b树、平衡搜索树、红黑树
8. hash表是什么，怎么解决冲突，查询和插入的复杂度
9. tcp 3次握手
10. tcp timewait 大量timewait会如何
11. 进程 线程 协程
12. 协程的实现机制
13. 

## 网易一面(互娱)
1. 算法：已排序数组a,b, a大小为a+b, 将a,b合并到a，仍为排序
2. 算法：链表、链表排序（可以二分）
3. cache页的调度算法
4. java多继承问题，如何实现多继承效果
5. java interface是否可以有属性
6. gc机制
7. java里final的用法（包括类、属性、方法参数、方法内变量
8. 进程间通信 有名管道和匿名管道的解释
9. linux中的’|‘
10. 编译原理（可以回忆回忆，方便讲
11. 对Python的了解
12. sychronize 死锁的条件
13. thread和runnable的区别
14. 异常是什么，解释名词。。（是程序本身可以处理的异常。Exception 类有一个重要的子类 RuntimeException。RuntimeException 类及其子类表示“JVM 常用操作”引发的错误。例如，若试图使用空值对象引用、除数为零或数组越界，则分别引发运行时异常（NullPointerException、ArithmeticException）和 ArrayIndexOutOfBoundException。
15. c++的函数参数与java的有什么不同

## 网易二面(互娱)
1. 算法：圆内随机点
2. 算法：矩阵中最大正方形(LeetCode原题)
3. 算法：爬楼

## 腾讯一面(业务运维)
1. 算法: 先序遍历、链表有环
2. 结构体: 限流器
3. linux的指令(重点看看！)
4. 服务熔断、限流

## 字节转正(一面)
1. 算法: 爬楼(递归与非递归，递归如何减少复杂度)
2. 业务设计: 文件系统，设计数据库表，如何建索引
3. oauth
4. 服务端如何设置cookies(Nginx)(header里Set-cookie, 参数name,expire...)
5. 运营后台请求的全过程(http dns ip ...)
6. 如何存储登录信息
7. b+树的复杂度(logMlogmN = logN)
8. b+树的优势
9. https的加密方式
10. treemap的查询复杂度

## 字节转正(二面)
1. 算法: 堆排序
2. 算法: 先序和中序，构造后序
3. 算法: 连通图，最小生成树
    https://blog.csdn.net/a2392008643/article/details/81781766
4. go channel buffer的作用
5. go多态的实现
6. 微服务的概念 优劣势(与单体应用比)
7. 熔断和降级的原理(熔断的原理和作用要好好看)
    熔断 - 服务雪崩
8. innodb的默认隔离级别
9. innodb不串行怎么防止幻读
10. innodb的存储结构
11. b+树与b树的区别、优势
    b+树非叶子节点不存储数据，可以一次性从磁盘读出更多的索引数据
    b+树在范围搜索中占有很大的优势(b+树链表搜索、b树需要根据中序遍历查找)
12. redis分布式锁
13. redis zset 读写的复杂度
    底层skiplist跳表(key:score, value: member), hashmap(key:member, value: score)
14. go slice什么时候会扩容，是否会导致与原数组不同
15. innodb联合索引的存储结构
16. mysql如何查看是否使用了索引(explain)
17. mysql explain extra里的using where/using filesort等
    https://segmentfault.com/a/1190000021458117?utm_source=tag-newest
    
## 字节转正(三面)
1. 算法: 中文字转int
2. 算法: 随机数函数f3(0,1,2), 转化成f5(0,1,2,3,4)
3. java类加载
4. java equals与==的区别，为什么重载equals同时重载hash
5. java string为什么是final

## 华为一面
1. 算法: 乘积为正数的最长子数组
2. go与java的区别 感受
3. springmvc 请求过来如何识别到哪个方法 最先到达哪个类(具体的调用过程)
4. java gc
5. gc root的选择
6. 并发的问题(没太听懂问题。。)

## 华为二面
1. 算法: 探索地图 固定步长 起点走到终点(dfs)
2. 其余都是项目问题