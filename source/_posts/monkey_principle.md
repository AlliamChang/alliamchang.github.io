---
title: Go Monkey的原理
date: 2021-01-18 14:17:10
tags:
- go
categories:
- 学习笔记
- Go
---
该文章是对Go的函数动态替换库[Monkey](https://github.com/bouk/monkey)的原理分析。
<!-- more -->
# Principle

## *Disassembled code*

首先，我们写一段简单的代码。使用go build -o编译代码（要设置`-gcflags=-l`来禁用内联，后续编译均默认带上）

```Go
package main

func a() int {
   return 1
}

func main() {
   print(a())
}
```

将这段代码编译后，以上代码会生成下面的汇编代码。(可使用[Hopper](https://hopperapp.com/) 查看)

![](/image/monkey_principle/hopper1.png)

![](/image/monkey_principle/hopper2.png)

可以看到，地址`0x105c8e0`调用在地址`0x105c8a0`的main.a函数，main.a函数只是简单地将`0x1`放到栈上然后返回。地址`0x105c8f3`到地址`0x105c900`再将该值传递给runtime.printint。

## *How function values work in Go*

我们再写一段代码来看看函数对象的值

```Go
package main

import (
   "fmt"
   "unsafe"
)

func a() int { return 1 }

func main() {
   f := a
   fmt.Printf("0x%x\n", *(*uintptr)(unsafe.Pointer(&f)))
}
```

![](/image/monkey_principle/hopper3.png)

在第11行，我们将函数a赋值给f，这意味着执行f()将调用a。直接使用unsafe.Pointer读取f的值，运行代码会看到输出为`0x10d4ca0`，这个与地址`0x10a8760`并不相同（如上图所示，main.a的地址）

我们再次反汇编该段代码，可以看到上面的第11行所对应的汇编代码：

![](/image/monkey_principle/hopper4.png)

其引用了一个地址为`0x10d4ca0`的值，查看该位置，可以看到以下内容：

![](/image/monkey_principle/hopper5.png)

事实上，该地址就是main.a.f所处的位置。拼接图中的地址，我们可以得到`0x10a8760`，发现这就是main.a的位置。 看来f不是指向函数的指针，而是指向函数指针的指针。 我们对代码再进行一点修改。

```Go
package main

import (
   "fmt"
   "unsafe"
)

func a() int {
   return 1
}

func main() {
   f := a
   fmt.Printf("0x%x\n", **(**uintptr)(unsafe.Pointer(&f)))
}
```

这时候，运行代码，我们就能得到期望的`0x10d4ca0`。在[这里](https://github.com/golang/go/blob/e9d9d0befc634f6e9f906b5ef7476fbd7ebd25e3/src/runtime/runtime2.go#L75-L78) 我们可以看到Go代码中的实现情况。 Go函数值可以包含额外的信息，以实现闭包以及函数对象。

现在，来看看调用函数值的工作方式：

```Go
package main

func a() int { return 1 }

func main() {
        f := a
        f()
}
```

我们再次反汇编，可以得到下图：

![](/image/monkey_principle/hopper6.png)

main.a.f指向的内容(即main.a的地址)会被加载到rax，然后被调用。 同时，main.a.f的地址也会被加载到rdx中，这里对应的是上文提到的Go代码中的实现，为函数对象和闭包提供可能的额外信息。

## *Replacing a function at runtime*

下面的代码中，我们希望程序输出的结果是2

```Go
package main

func a() int { return 1 }
func b() int { return 2 }

func main() {
        replace(a, b)
        print(a())
}
```

现在我们如何实现替换？我们需要修改函数a跳转到函数b执行，而不是执行自己本身。根据汇编语言，我们需要用以下代码来进行替换，这会把b的函数值加载到rdx中，然后跳转到rdx指向的位置。(旁边的注释即相应生成的机器码)

```
mov rdx, main.b.f ; 48 C7 C2 ?? ?? ?? ?? 后4个byte即main.b.f地址
jmp [rdx] ; FF 22
```

下面这段就是将该汇编语言写到代码中：

```Go
func assembleJump(f func() int) []byte {
  funcVal := *(*uintptr)(unsafe.Pointer(&f))
  return []byte{
    0x48, 0xC7, 0xC2,
    byte(funcval >> 0),
    byte(funcval >> 8),
    byte(funcval >> 16),
    byte(funcval >> 24), // MOV rdx, funcVal

    0xFF, 0x22,          // JMP [rdx]
  }
}
```

我们已经拥有将函数a替换为函数b所需的代码。 下面的代码尝试将机器码直接复制到函数所处的位置。

```Go
package main

import (
        "syscall"
        "unsafe"
)

func a() int { return 1 }
func b() int { return 2 }

// 直接读取函数的内存块
func rawMemoryAccess(b uintptr) []byte {
        return (*(*[0xFF]byte)(unsafe.Pointer(b)))[:]
}

func assembleJump(f func() int) []byte {
        funcVal := *(*uintptr)(unsafe.Pointer(&f))
        return []byte{
                0x48, 0xC7, 0xC2,
                byte(funcVal >> 0),
                byte(funcVal >> 8),
                byte(funcVal >> 16),
                byte(funcVal >> 24), // MOV rdx, funcVal
                0xFF, 0x22,          // JMP [rdx]
        }
}



func replace(orig, replacement func() int) {
        bytes := assembleJump(replacement)
        functionLocation := **(**uintptr)(unsafe.Pointer(&orig))
        window := rawMemoryAccess(functionLocation)
   
        copy(window, bytes)

}

func main() {
        replace(a, b)
        print(a())
}
```

不过，直接运行代码并没有得到预期结果，反而还导致[segmentation fault](https://en.wikipedia.org/wiki/Segmentation_fault#Writing_to_read-only_memory) 。 这是由于默认情况下加载的二进制文件不可写（如下图所示，\__TEXT的默认只有r和x，没有w）（查看segment权限可查阅[这里](https://www.objc.io/issues/6-build-tools/mach-o-executables/#mach-o) ）。

![](/image/monkey_principle/segment.png)

我们可以使用[mprotect syscall](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/mprotect.2.html) 来禁用此保护。最终我们得到以下的代码。运行这段代码，我们就能将函数a替换为函数b，并成功输出预期的“2”。

```Go
package main

import (
        "syscall"
        "unsafe"
)

func a() int { return 1 }
func b() int { return 2 }

// 获取函数所在的内存页
func getPage(p uintptr) []byte {
        return (*(*[0xFFFFFF]byte)(unsafe.Pointer(p & ^uintptr(syscall.Getpagesize()-1))))[:syscall.Getpagesize()]
}

// 获取函数的内存块
func rawMemoryAccess(b uintptr) []byte {
        return (*(*[0xFF]byte)(unsafe.Pointer(b)))[:]
}

func assembleJump(f func() int) []byte {
        funcVal := *(*uintptr)(unsafe.Pointer(&f))
        return []byte{
                0x48, 0xC7, 0xC2,
                byte(funcVal >> 0),
                byte(funcVal >> 8),
                byte(funcVal >> 16),
                byte(funcVal >> 24), // MOV rdx, funcVal
                0xFF, 0x22,          // JMP rdx
        }
}

func replace(orig, replacement func() int) {
        bytes := assembleJump(replacement)
        functionLocation := **(**uintptr)(unsafe.Pointer(&orig))
        window := rawMemoryAccess(functionLocation)
       
        page := getPage(functionLocation)

        // 修改内存页的权限
        syscall.Mprotect(page, syscall.PROT_READ|syscall.PROT_WRITE|syscall.PROT_EXEC)
      
        copy(window, bytes)
}

func main() {
        replace(a, b)
        print(a())
}
```

## *Wrapping it up in a library*

以上就是如何在运行时替换函数的原理。根据该原理，就可以封装成一个库函数，提供开发者使用。

[Monkey](https://github.com/bouk/monkey) 就是其中的一个。

# Permission Denied

理论上，可以通过`-segprot \__TEXT rwx rx`设置max_prot来解决此问题。但从Catalina版本开始，max_prot会被忽略，而max_prot的值会被重置成init_prot，这导致了我们无法直接修改内存。(上下文查看[here](https://github.com/apple-opensource/ld64/blob/fd3feabb0a1eb18ab5d7910f3c3a5eed99cef6ab/src/ld/Options.cpp#L374-L379))

```cpp
uint32_t Options::initialSegProtection(const char* segName) const
{
        ......
        if ( strcmp(segName, "__TEXT") == 0 ) {
                return ( fUseTextExecSegment ? VM_PROT_READ : (VM_PROT_READ | VM_PROT_EXECUTE) );
        }
        ......
}

uint32_t Options::maxSegProtection(const char* segName) const
{
        // i386 uses text-relocations so, need max prot to be rwx.  All others have max==init
        if ( fArchitecture != CPU_TYPE_I386 )
                return initialSegProtection(segName);
       
        ......
}
```

# Possible Solving

在尝试mprotect失败后，再尝试[vm_protect](https://www.gnu.org/software/hurd/gnumach-doc/Memory-Attributes.html)

> The function vm_protect sets the virtual memory access privileges for a range of allocated addresses in target_task's virtual address space. The protection argument describes a combination of read, write, and execute accesses that should be *permitted*.

# Reference

**\[1]** [Monkey Patching in Go](https://bou.ke/blog/monkey-patching-in-go/)
