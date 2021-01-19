---
title: linux常用命令
date: 2020-09-06 11:50:57
tags:
- linux
categories:
- 学习笔记
---
本文涉及到vim\grep\cat\more\less\echo\sed\awk的入门用法。
<!-- more -->
## vim：
vim test -----建立一个test文件。test文件可以是hello.py、hello.txt等。
touch test -----效果同vim test。
mkdir test -----建立一个test文件夹
open test -----打开test文件夹
rm test ----- 删除test文件
rm -r test -----删除test文件夹
注意：vim test 命令后会进入vim编辑器，按键i,进入编辑模式，按键esc,退出编辑模式，键入:x,（注意是':x'）保存编辑并退出。
## grep:
文本搜索工具，可搭配正则表达式使用，全称Global Regular Expression Print，译为全局正则表达式版本。
grep的一般使用方法：grep+[options]+pattern+filename  ,其中pattern是要搜索的字符串或正则表达式。
options可选参数：
    -i ：忽略大小写
    -c ：打印匹配的行数
    -l ：从多个文件中查找包含匹配项
    -v ：查找不包含匹配项的行
    -n：打印包含匹配项的行和行标
正则表达式参数：
    \ 忽略正则表达式中特殊字符的原有含义
    ^ 匹配正则表达式的开始行
    $ 匹配正则表达式的结束行
    \< 从匹配正则表达式的行开始
    \>; 到匹配正则表达式的行结束
    [ ] 单个字符；如[A] 即A符合要求
    [ - ] 范围 ；如[A-Z]即A，B，C一直到Z都符合要求
    . 所有的单个字符
    * 所有字符，长度可以为0
其他：
明确要求搜索子目录(-r的意思是递归)：grep -r
    或忽略子目录：grep -d skip
注意：grep 是搜索文件内容的，不搜索文件名。
如果有很多 输出时，您可以通过管道将其转到'less'上阅读：
    $ grep magic /usr/src/Linux/Documentation/* | less
    
常见的示例有：
grep Aug /var/log/messages 在文件 '/var/log/messages'中查找关键词"Aug"
    grep ^Aug /var/log/messages 在文件 '/var/log/messages'中查找以"Aug"开始的词汇
    grep [0-9] /var/log/messages 选择 '/var/log/messages' 文件中所有包含数字的行
    grep Aug -R /var/log/* 在目录 '/var/log' 及随后的目录中搜索字符串"Aug"

    

    
在Linux系统中有三种命令可以用来查阅全部的文件，分别是cat、more和less命令。它们查阅文件的使用方法也比较简单都是 命令 文件名 ，但是三者又有着区别。
1.cat命令可以一次显示整个文件，如果文件比较大，使用不是很方便；
2.more命令可以让屏幕在显示满一屏幕时暂停，此时可按空格健继续显示下一个画面，或按Q键停止显示。
3.less命令也可以分页显示文件，和more命令的区别就在于它支持上下键卷动屏幕，当结束浏览时，只要在less命令的提示符": "下按Q键即可。
另外，多数情况下more和less命令会配合管道符来分页输出需要在屏幕上显示的内容。
## cat:
cat命令是linux下的一个文本输出命令，通常是用于观看某个文件的内容的；
    cat主要有三大功能：
    1.一次显示整个文件。
    cat   filename
    2.从键盘创建一个文件。
    cat  >  filename
    只能创建新文件,不能编辑已有文件。编辑好后Ctrl+C退出编辑模式。
    3.将几个文件合并为一个文件。
    cat   file1   file2  > file

    cat具体命令格式为 : cat [-AbeEnstTuv] [--help] [--version] fileName
    

    参数：
    -n 或 -number 由 1 开始对所有输出的行数编号
    -b 或 -number-nonblank 和 -n 相似，只不过对于空白行不编号
    -s 或 -squeeze-blank 当遇到有连续两行以上的空白行，就代换为一行的空白行
    ...
范例：
    cat -n linuxfile1 > linuxfile2 把 linuxfile1 的档案内容加上行号后输入 linuxfile2 这个档案里
    cat -b linuxfile1 linuxfile2 >> linuxfile3 把 linuxfile1 和 linuxfile2 的档案内容加上行号(空白行不加)之后将内容附加到linuxfile3 里。
    范例：
    把 linuxfile1 的档案内容加上行号后输入 linuxfile2 这个档案里
    cat -n linuxfile1 > linuxfile2
    把 linuxfile1 和 linuxfile2 的档案内容加上行号(空白行不加)之后将内容附加到 linuxfile3 里。
    cat -b linuxfile1 linuxfile2 >> linuxfile3
补充说明：
    
cat   file1   file2  > file表示将file1和file2的内容串接后输入到file文件中，如果已经存在，file文件被重写。
    cat   file1   file2  >>file表示将file1和file2的内容串接后输入到file文件中，如果已经存在，新内容追加在file文件原内容的后面。

    
## more:
more test.log -----将test.log文件内容显示满一屏幕时暂停，此时可按空格健继续显示下一个画面，或按Q键停止显示。
cat test.log | grep aug | more  -----将test.log文件筛选出含字符串aug的行以more的方式显示输出
    
## less:
less test.log -----将test.log文件分页显示，支持上下键卷动屏幕，当结束浏览时，只要在less命令的提示符": "下按Q键即可。
cat test.log | grep aug | less  -----将test.log文件筛选出含字符串aug的行以less的方式显示输出
## echo:
echo命令的功能是在显示器上显示一段文字，一般起到一个提示的作用。
    该命令的一般格式为： echo [-n ][-e] 字符串
其中选项n表示输出文字后不换行；字符串能加引号，也能不加引号。
    -e 若字符串中出现以下字符，则特别加以处理，而不会将它当成一般文字输出：
       \a 发出警告声；
       \b 删除前一个字符；
       \c 最后不加上换行符号；
       \f 换行但光标仍旧停留在原来的位置；
       \n 换行且光标移至行首；
       \r 光标移至行首，但不换行；
       \t 插入tab；
       \v 与\f相同；
       \\ 插入\字符；
       \nnn 插入nnn（八进制）所代表的ASCII字符；
    
    
echo示例：
    示例一 打印当前的PATH设置
    [root@jfht ~]# echo $PATH 
    /usr/kerberos/sbin:/usr/kerberos/bin:/usr/apache/apache-ant-1.7.1/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
    
    示例二 打印当前的LANG设置
    [root@jfht ~]# echo $LANG 
    zh_CN.GB18030
    
    示例三 对输出信息进行转义，比如输出换行
    echo "hello\nworld" 
    hello\nworld

    echo -e "hello\nworld" 
    hello
    world
    
    echo hello; echo world 
    hello
    world
    
    
## sed：
1. sed替换的基本语法为:         sed 's/原字符串/替换字符串/'    ------------单引号里面,s表示替换,三根斜线中间是替换的样式,特殊字符需要使用反斜线"\"进行转义。
2. 单引号是没有办法用反斜线"\"转义的,这时候只要把命令中的单引号改为双引号就行了,格式如下：
### 要处理的字符包含单引号
sed "s/原字符串包含'/替换字符串包含'/" 
3. 命令中的三根斜线分隔符可以换成别的符号,有时候替换目录字符串的时候有较多斜线，这个时候换成其它的分割符是较为方便,只需要紧跟s定义即可。
### 将分隔符换成问号"?":
sed 's?原字符串?替换字符串?'
4. 可以在末尾加g替换每一个匹配的关键字,否则只替换每行的第一个,例如:
### 替换所有匹配关键字
sed 's/原字符串/替换字符串/g'
5. 一些特殊字符的使用
　　"^"表示行首
　　"$"符号如果在引号中表示行尾，但是在引号外却表示末行(最后一行)
### 注意这里的 " & " 符号，如果没有 "&"，就会直接将匹配到的字符串替换掉
       sed 's/^/添加的头部&/g' 　　　　 #在所有行首添加
       sed 's/$/&添加的尾部/g' 　　　　 #在所有行末添加
       sed '2s/原字符串/替换字符串/g'　 #替换第2行
       sed '$s/原字符串/替换字符串/g'   #替换最后一行
       sed '2,5s/原字符串/替换字符串/g' #替换2到5行
       sed '2,$s/原字符串/替换字符串/g' #替换2到最后一行
6.批量替换字符串(mac如下)
sed -i '' "s/查找字段/替换字段/g" `grep 查找字段 -rl 路径`
sed -i '' "s/oldstring/newstring/g" `grep oldstring -rl yourdir`
7. sed处理过的输出是直接输出到屏幕上的,使用参数"i"直接在文件中替换。
### 替换文件中的所有匹配项
sed -i 's/原字符串/替换字符串/g' filename
8. 多个替换可以在同一条命令中执行,用分号";"分隔，其格式为:
### 同时执行两个替换规则
sed 's/^/添加的头部&/g；s/$/&添加的尾部/g'

    
## awk:
awk语言的最基本功能是在文件或者字符串中基于指定规则浏览和抽取信息。
通常，awk是以文件的一行为处理单位的。awk每接收文件的一行，然后执行相应的命令，来处理文本。
相对于grep的查找，awk强在对文本的分析处理。
使用方法

awk '{pattern + action}' {filenames}
pattern 表示 AWK 在数据中查找的内容，而 action 是在找到匹配内容时所执行的一系列命令。花括号（{}）不需要在程序中始终出现，但它们用于根据特定的模式对一系列指令进行分组。 
调用awk

命令行方式调用awk
awk [-F  field-separator]  'commands'  input-file(s)
其中，commands 是真正awk命令，[-F域分隔符]是可选的。 input-file(s) 是待处理的文件。
在awk中，文件的每一行中，由域分隔符分开的每一项称为一个域。通常，在不指名-F域分隔符的情况下，默认的域分隔符是空格。
 入门实例
假设last -n 5的输出如下
```shell script
[root@www ~]# last -n 5
root     pts/1   192.168.1.100  Tue Feb 10 11:21   still logged in
root     pts/1   192.168.1.100  Tue Feb 10 00:46 - 02:28  (01:41)
root     pts/1   192.168.1.100  Mon Feb  9 11:41 - 18:30  (06:48)
dmtsai   pts/1   192.168.1.100  Mon Feb  9 11:41 - 11:41  (00:00)
root     tty1                   Fri Sep  5 14:09 - 14:10  (00:01)
```
如果只是显示最近登录的5个帐号
```shell script
#last -n 5 | awk  '{print $1}'

root

root

root

dmtsai

root
```
awk工作流程是这样的：读入有'\n'换行符分割的一条记录，然后将记录按指定的域分隔符划分域，填充域，$0则表示所有域,$1表示第一个域,$n表示第n个域。默认域分隔符是"空白键" 或 "[tab]键",所以$1表示登录用户，$3表示登录用户ip,以此类推。

如果只是显示/etc/passwd的账户
```shell script
#cat /etc/passwd |awk  -F ':'  '{print $1}'  
root
daemon
bin
sys
```
这种是awk+action的示例，每行都会执行action{print $1}。
-F指定域分隔符为':'。

如果只是显示/etc/passwd的账户和账户对应的shell,而账户与shell之间以tab键分割
```shell script
#cat /etc/passwd |awk  -F ':'  '{print $1"\t"$7}'
root    /bin/bash
daemon  /bin/sh
bin     /bin/sh
sys     /bin/sh
```

如果只是显示/etc/passwd的账户和账户对应的shell,而账户与shell之间以逗号分割,而且在所有行添加列名name,shell,在最后一行添加"blue,/bin/nosh"。
```shell script
cat /etc/passwd |awk  -F ':'  'BEGIN {print "name,shell"}  {print $1","$7} END {print "blue,/bin/nosh"}'
name,shell
root,/bin/bash
daemon,/bin/sh
bin,/bin/sh
sys,/bin/sh
....
blue,/bin/nosh
```
awk工作流程是这样的：先执行BEGIN，然后读取文件，读入有/n换行符分割的一条记录，然后将记录按指定的域分隔符划分域，填充域，$0则表示所有域,$1表示第一个域,$n表示第n个域,随后开始执行模式所对应的动作action。接着开始读入第二条记录······直到所有的记录都读完，最后执行END操作。

搜索/etc/passwd有root关键字的所有行
```shell script
#awk -F: '/root/' /etc/passwd
root:x:0:0:root:/root:/bin/bash
```
这种是pattern的使用示例，匹配了pattern(这里是root)的行才会执行action(没有指定action，默认输出每行的内容)。
搜索支持正则，例如找root开头的: awk -F: '/^root/' /etc/passwd

搜索/etc/passwd有root关键字的所有行，并显示对应的shell
```shell script
# awk -F: '/root/{print $7}' /etc/passwd             
/bin/bash
```
这里指定了action{print $7}

    
模式可以是以下任意一个：
- /正则表达式/：使用通配符的扩展集。
- 关系表达式：可以用下面运算符表中的关系运算符进行操作，可以是字符串或数字的比较，如$2>%1选择第二个字段比第一个字段长的行。
- 模式匹配表达式：用运算符~(匹配)和~!(不匹配)。
- 模式，模式：指定一个行的范围。该语法不能包括BEGIN和END模式。
- BEGIN：让用户指定在第一条输入记录被处理之前所发生的动作，通常可在这里设置全局变量。
- END：让用户在最后一条输入记录被读取之后发生的动作。
几个实例:
- $ awk '/^(no|so)/' test-----打印所有以模式no或so开头的行。
- $ awk '/^[ns]/{print $1}' test-----如果记录以n或s开头，就打印这个记录。
- $ awk '$1 ~/[0-9][0-9]$/(print $1}' test-----如果第一个域以两个数字结束就打印这个记录。
- $ awk '$1 == 100 || $2 < 50' test-----如果第一个或等于100或者第二个域小于50，则打印该行。
- $ awk '$1 != 10' test-----如果第一个域不等于10就打印该行。
- $ awk '/test/{print $1 + 10}' test-----如果记录包含正则表达式test，则第一个域加10并打印出来。
- $ awk '{print ($1 > 5 ? "ok "$1: "error"$1)}' test-----如果第一个域大于5则打印问号后面的表达式值，否则打印冒号后面的表达式值。
- $ awk '/^root/,/^mysql/' test----打印以正则表达式root开头的记录到以正则表达式mysql开头的记录范围内的所有记录。如果找到一个新的正则表达式root开头的记录，则继续打印直到下一个以正则表达式mysql开头的记录为止，或到文件末尾。

    
awk内置变量
awk有许多内置变量用来设置环境信息，这些变量可以被改变，下面给出了最常用的一些变量。

ARGC               命令行参数个数
ARGV               命令行参数排列
ENVIRON            支持队列中系统环境变量的使用
FILENAME           awk浏览的文件名
FNR                浏览文件的记录数
FS                 设置输入域分隔符，等价于命令行 -F选项
NF                 浏览记录的域的个数
NR                 已读的记录数
OFS                输出域分隔符
ORS                输出记录分隔符
RS                 控制记录分隔符
此外,$0变量是指整条记录。$1表示当前行的第一个域,$2表示当前行的第二个域,......以此类推。

统计/etc/passwd:文件名，每行的行号，每行的列数，对应的完整行内容:
```shell script
#awk  -F ':'  '{print "filename:" FILENAME ",linenumber:" NR ",columns:" NF ",linecontent:"$0}' /etc/passwd
filename:/etc/passwd,linenumber:1,columns:7,linecontent:root:x:0:0:root:/root:/bin/bash
filename:/etc/passwd,linenumber:2,columns:7,linecontent:daemon:x:1:1:daemon:/usr/sbin:/bin/sh
filename:/etc/passwd,linenumber:3,columns:7,linecontent:bin:x:2:2:bin:/bin:/bin/sh
filename:/etc/passwd,linenumber:4,columns:7,linecontent:sys:x:3:3:sys:/dev:/bin/sh
```
    
记录、域、域分隔符
记录
awk把每一个以换行符结束的行称为一个记录。
记录分隔符：默认的输入和输出的分隔符都是回车，保存在内建变量ORS和RS中。
$0变量：它指的是整条记录。如$ awk '{print $0}' test将输出test文件中的所有记录。
变量NR：一个计数器，每处理完一条记录，NR的值就增加1。如$ awk '{print NR,$0}' test将输出test文件中所有记录，并在记录前显示记录号。
域
记录中每个单词称做"域"，默认情况下以空格或tab分隔。awk可跟踪域的个数，并在内建变量NF中保存该值。如$ awk '{print $1,$3}' test将打印test文件中第一和第三个以空格分开的列(域)。
域分隔符
内建变量FS保存输入域分隔符的值，默认是空格或tab。我们可以通过-F命令行选项修改FS的值。如$ awk -F: '{print $1,$5}' test将打印以冒号为分隔符的第一，第五列的内容。
可以同时使用多个域分隔符，这时应该把分隔符写成放到方括号中，如$awk -F'[:\t]' '{print $1,$3}' test，表示以空格、冒号和tab作为分隔符。
输出域的分隔符默认是一个空格，保存在OFS中。如$ awk -F: '{print $1,$5}' test，$1和$5间的逗号就是OFS的值。