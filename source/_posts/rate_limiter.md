---
title: 常见的限流算法
date: 2021-01-18 11:16:00
tags:
- 分布式
- service governance
categories:
- 服务治理
---
该文章将介绍几种常见的限流算法，以及如何在分布式下实现限流
<!-- more -->
## 常用限流算法

### 单机限流器

#### 计数器

计数器算法是定义一个计数器在周期内累加访问次数，当达到设定的限流值时，触发限流策略。下一个周期开始时，将计数器清零，重新计数。该算法无论在单机还是在分布式环境下实现都非常简单，分布式环境下使用redis的incr原子自增性和线程安全即可实现。

对于时间周期较大的情况下，计数器算法会存在临界问题。如图，限流设定为100访问量/分钟，在前一个周期最后5s以及后一个周期前5s分别涌入了100访问量，在各自周期都符合预期，但在这10s内已经达到了200的访问量，远超预期负载能力。

![计数器](/image/rate_limiter/single_counter.png)

#### 滑动窗口

滑动窗口算法很好地解决了计数器算法带来的临界问题。该算法将一个时间周期划分成N个更小的周期，分别记录小周期内的访问量，根据时间窗口的滑动，淘汰过期的小周期，生成新的小周期。访问量的计算方法为滑动窗口内所有小周期的访问量总和。若窗口内访问量总和超过了阈值，则触发限流策略。

![滑动窗口](/image/rate_limiter/sliding_window.png)

在Go中实现一个滑动窗口的结构：

```go
// window maintains a ring of buckets and increments the failure and success
// counts of the current bucket.

type window struct {
   rw      rwlock.RWLock
   oldest  int32    // oldest perPBucket index
   latest  int32    // latest perPBucket index
   buckets []bucket // buckets this perPWindow holds

   bucketTime time.Duration // time each perPBucket holds
   bucketNums int32         // the numbe of buckets
   inWindow   int32         // the number of buckets in the perPWindow
   ...
}
```

#### 令牌桶

令牌桶算法是以恒定的速度(限流值 / 周期)往桶内添加令牌，桶的容量即限流值，桶满了令牌直接丢弃。而每个请求都需要从桶内获取令牌，只有获取到令牌才能执行请求，否则就触发限流策略，拒绝该请求。

![令牌桶](/image/rate_limiter/token_bucket.png)

在Go中实现一个简单的令牌桶：

```go
// qps_limiter.go
// qpsLimiter implements the RateLimiter interface.
type qpsLimiter struct {
   limit    int32
   tokens   int32
   interval time.Duration
   once     int32
   ticker   *time.Ticker
}

// Acquire .
func (l *qpsLimiter) Acquire() bool {
   if atomic.LoadInt32(&l.tokens) <= 0 {
      return false
   }
   return atomic.AddInt32(&l.tokens, -1) >= 0
}

// 这里允许一些误差，直接Store，可以换来更好的性能，也解决了大并发情况之下CAS不上的问题
func (l *qpsLimiter) updateToken() {
   var v int32
   v = atomic.LoadInt32(&l.tokens)
   if v < 0 {
      v = atomic.LoadInt32(&l.once)
   } else if v+atomic.LoadInt32(&l.once) > atomic.LoadInt32(&l.limit) {
      v = atomic.LoadInt32(&l.limit)
   } else {
      v = v + atomic.LoadInt32(&l.once)
   }
   atomic.StoreInt32(&l.tokens, v)
}
```

#### 漏桶

漏桶算法则与令牌桶算法相似，所有请求都会加入到一个漏桶，当桶满溢出，请求就会被拒绝。漏桶会以恒定的速率释放请求，请求将被正常执行，直至漏桶为空。

![漏桶](/image/rate_limiter/leaky_bucket.png)

#### 对比

| 算法   | 参数                  | 限制突发流量 | 平滑限流                  | 分布式下实现难度 |
| ---- | ------------------- | ------ | --------------------- | -------- |
| 计数器  | 计数周期T周期最大访问值N       | 否      | 否                     | 低        |
| 滑动窗口 | 窗口长度T窗口划分K窗口内最大访问值N | 是      | 窗口内周期划分得越精细，窗口的滑动就越平滑 | 中        |
| 令牌桶  | 令牌增长速度r令牌桶容量N       | 是      | 是                     | 高        |
| 漏桶   | 漏桶流出速度r漏桶容量N        | 是      | 是                     | 高        |

### 分布式限流器

#### 分布式精准限流器

使用Redis Incr接口实现计数器算法，利用该算法实现了简单的分布式精准限流。每个请求进来都需要通过Redis计数器判断是否触发限流。

#### 分布式大QPS限流器

该限流器与精准限流器最大的区别是加入了step(步长)的概念，限流接口的令牌数量仍然是在reids中存放着，但是取令牌数量时候不像精准限流器那样一次取一个而是以步长为单位去获取，每次获取单位步长的令牌到本地缓存，新的请求进入需要先去本地的令牌桶中去获取令牌，如果本地令牌桶中消耗完之后需要到redis桶中再次去获取直至redis桶中的令牌被消耗完毕。它比精准限流器在相同的限制数量上减少了去redis请求的次数，相当于依靠远端redis+本地结合的方式可以支持更高的并发大流量的限制。

![大QPS](/image/rate_limiter/big_qps.png)

#### 分布式大QPS+单机限流

该方案是结合了分布式限流器以及单机限流器，区别于分布式限流器对redis强依赖，若redis不可用，则整个限流器失效。该方案一般情况下都通过分布式限流器获取token，当出现redis不可用时，降级到单机限流，同时持续探测redis的健康情况，如果恢复健康，则自动切回分布式限流。

#### 对比

![对比](/image/rate_limiter/compare.png)

## 容量预估

有一个简单的QPS容量预估方法, 其基本思路为: 当物理资源在安全阈值内时, 其消耗和QPS大致成线性正比关系;

对于一般的服务, 这里的物理资源主要考虑CPU和内存;

比如昨天服务低峰QPS为100, CPU使用10%, 高峰QPS为300, CPU使用20%;

则大致判断每增加200的QPS, CPU使用会增加10%;

假设以70%的CPU使用为安全阈值;

从低峰100/10%出发, 到达70%的使用大概能撑1300;

用同样的方式预估一下内存的情况, 取两者较小值, 作为服务的安全容量上限;

当然比较准确的是通过压测进行QPS估量

