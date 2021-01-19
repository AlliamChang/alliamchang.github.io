---
title: Go开源缓存库分析
date: 2021-01-18 14:55:52
tags:
- go
categories:
- 学习笔记
- Go
---
该文章对Github上Star比较多的几个Go开源缓存库进行分析。
<!-- more -->
## [Go-cache](https://github.com/patrickmn/go-cache)

类似于memcached，go-cache是一个内存中的键值对存储/缓存。

主要特点：

* 底层使用map\[string] interface{}做缓存
* 有过期时间，会启动协程定期清理过期缓存
* 实现简单，不需要序列化或在网络中传输。
* 可以在给定的持续时间内或永久存储任何对象，并且线程安全。
* 可以将整块缓存保存到文件，也可从文件中加载以快速从停机中恢复。
* 可以分片分段缓存，减轻了锁的竞争(尚未公开)

### 组件分析

如下是go-cache的主要结构。可以清晰地看到，go-cache的底层使用了map作缓存结构，对value进行了一层包装，增加了expiration的字段，该字段可以设置该kv的过期时间。由于map不是线程安全的，cache引入了sync.RWMutex来控制并发读写。用户可以自定义onEvicted函数，当kv被delete时触发回调，处理一些业务逻辑。

```go
type Cache struct {
   /* 再嵌套一层结构是为了保证运行janitor的协程是对cache操作而不是Cache。*/
   /* 当Cache被gc时，finalizer可以终止janitor的协程(runtime.SetFinalizer(Cache, stopJanitor))，这样cache就可以被正确地回收 */
   *cache
}

type cache struct {
   defaultExpiration time.Duration
   items             map[string]Item
   mu                sync.RWMutex
   onEvicted         func(string, interface{})
   janitor           *janitor
}

// 存储结构
type Item struct {
    Object     interface{} // real value
    Expiration int64
}

// 定期清理
type janitor struct {
    Interval time.Duration
    stop     chan bool
}
```

### 核心流程

缓存的Set/Get写的非常简洁，就是读写前后用锁保护起来。比较有趣的是作者不用`defer unlock()`，原因是defer会增加200ns耗时。不过经过几次迭代，现在defer已经优化到[几乎不增加耗时](https://go.googlesource.com/proposal/+/refs/heads/master/design/34481-opencoded-defers.md) 了，所以还是建议使用`defer unlock()`。

```go
func (c *cache) Set(k string, x interface{}, d time.Duration) {
   var e int64
   
   if d == DefaultExpiration {
      d = c.defaultExpiration
   }

   if d > 0 {
      e = time.Now().Add(d).UnixNano()
   }

   c.mu.Lock()
   c.items[k] = Item{
      Object:     x,
      Expiration: e,
   }

   c.mu.Unlock()
}

func (c *cache) Get(k string) (interface{}, bool) {
	
   c.mu.RLock()
   item, found := c.items[k]
   
   if !found {
      c.mu.RUnlock()
      return nil, false
   }
   
   if item.Expiration > 0 {
      if time.Now().UnixNano() > item.Expiration {
         c.mu.RUnlock()
         return nil, false
      }
   }
   
   c.mu.RUnlock()
   return item.Object, true
}
```

同时go-cache还实现了一系列Increment/Decrement函数，可直接对缓存进行计算。还有Save/SaveFile可以将缓存进行持久化，Flush清空缓存。

总的来说，go-cache是一个很简单的缓存实现(代码都在一个go文件中)，初学者可以作为入门开源库进行阅读学习，也可以参考着自己实现一个缓存。

## [Groupcache](https://github.com/golang/groupcache)

groupcache是一个分布式缓存库，在许多情况下可用来替代内存缓存节点池，是google自己开发出来的一个缓存库。

其主要特点：

* 分布式缓存，去中心化
* 简单的HTTP协议进行Peer Server之间的通信
* 支持pb的消息协议的格式
* singleflight防止缓存击穿
* 一致性hash算法对key进行shard
* 使用LRU缓存淘汰算法

缺点：

* 不支持对缓存过期策略
* 本地cache用的是单个map，且value用的是指针，如果本地存有千万级keys，会导致gc延迟
* hotcache计算方法是随机10%，导致本地缓存命中率不是很高
* 使用groupcache时，应用层需要自己实现一套peer节点管理的机制，本身不提供

### 组件分析

与Go-cache不同，由于引入了分布式缓存以及LRU算法，组件会更多，更复杂，但设计上都是基于面向接口编程，只要理解了其中的核心组件，就能大致了解整体的运作。

* ByteView

    * 内部包装了一个byte slice和一个string，是Groupcache实现缓存的数据结构。
    * 读数据会先取byte slice，slice为nil，则取string
    * Sink负责从一个Get调用中接收缓存数据，对接ByteView，从ByteView中获取数据，起到一个中间人的作用，和ByteView的关系有点类似DO和DTO/VO的关系
    * groupcache提供了不同的Sink实现类来满足不同数据格式的要求，内置的有string、byte和proto

* Sink

  * Sink负责从一个Get调用中接收缓存数据，对接ByteView，从ByteView中获取数据，起到一个中间人的作用，和ByteView的关系有点类似DO和DTO/VO的关系
  * groupcache提供了不同的Sink实现类来满足不同数据格式的要求，内置的有string、byte和proto

![](/image/go_cache/groupcache.png)

* Group

    * 标识一个唯一的缓存的命名空间
    * 对外提供获取缓存的Get接口，整个groupcache最核心的接口
    * 维护对缓存各种操作和结果的统计信息
    * 缓存的写入和缓存的维护，包括本地缓存的维护

* PeerPicker

    * 提供根据key获取关联Peer的能力

* HTTPPool

    * 是一个简单的Http server，同时也是groupcache中默认的peer选择器

* lru.Cache

    * 基于Map和队列List构建的一个缓存结构，采用LRU算法进行缓存淘汰

* cache

    * groupcache.go文件中定义的cache结构体，内聚一个lru.Cache实例，相当于是lru.Cache的代理结构，在原始lru.Cache的基础上增加额外的统计信息，比如：缓存命中次数、Get请求次数以及缓存逐出次数等
    * 加入读写锁RWMutex，对lru.Cache的操作进行加锁，保证线程安全

* flightGroup

提供了一个Do()方法用来处理本地缓存不存在时大量请求涌入数据库时可能造成的缓存击穿。flightGroup的实现还有call和Group两个数据结构来组成。

```go
// call表示一个正在执行的或者已经完成的函数调用
type call struct {
   wg  sync.WaitGroup
   val interface{}
   err error
}

// Group可以看做是对调用任务的分类，map中维护的了对key当前调用的记录
type Group struct {
   mu sync.Mutex       // protects m
   m  map[string]*call // lazily initialized
}
```

Do函数是flightGroup的核心实现，保证了同一时间同一个key只会有一个请求被处理，其他请求将会在第一个请求完成后，直接从call结构中取值，防止了缓存失败都涌入数据库的情况。

```go
func (g *Group) Do(key string, fn func() (interface{}, error)) (interface{}, error) {
        g.mu.Lock()
  // lazyinit
        if g.m == nil {
                g.m = make(map[string]*call)
        }
  // 如果key存在表示有其他请求先一步进来，直接等待其他请求返回即可
        if c, ok := g.m[key]; ok {
                g.mu.Unlock()
                c.wg.Wait()
                return c.val, c.err
        }
        c := new(call)
        c.wg.Add(1)
        g.m[key] = c
        g.mu.Unlock()
        
        c.val, c.err = fn()
        c.wg.Done()
        
        g.mu.Lock()
        delete(g.m, key)
        g.mu.Unlock()
        
        return c.val, c.err
}
```

### 核心流程

**Get获取缓存的流程**如图：groupcache会先从本地的`maincache`和`hotcache`取，未命中时，根据一致性hash算法获取Peer对象，如果Peer是自身，则调用用户自定义的GetFunc获取数据，并缓存在`maincache`；否则，发起http请求远端的Peer获取缓存，并有10%的概率写到`hotcache`中。

整个流程都是在flightGroup.Do()中完成的。

![](/image/go_cache/groupcache_step.png)

### 扩展点

1. **\*type GetterFunc func(ctx context.Context, key string, dest Sink) error**

    1. 初始化一个cache group实例的时候作为入参传入，在整个缓存群组都没有对应缓存的时候被调用执行，这部分是用户自定义的

2. func RegisterServerStart(fn func())

    1. 初始化initPeerServer函数
    2. 初始化一个新的cache group实例的时候调用initPeerServer，sync.Once保证只被执行一次

3. func RegisterPeerPicker(fn func() PeerPicker)

    1. 初始化portPicker函数，用于返回一个PeerPicker的实现类

4. func RegisterPerGroupPeerPicker(fn func(groupName string) PeerPicker)

    1. 作用和func RegisterPeerPicker(fn func() PeerPicker)一样，官方文档中对两者的描述为should be called exactly once, but not both.

5. func RegisterNewGroupHook(fn func(\*Group))

    1. 初始化newGroupHook函数
    2. 在实例化一个新的cache group之后执行

***

## [Bigcache](https://github.com/allegro/bigcache)

Bigcache属于本地缓存库，只存储字节数组，它可以独立部署为一个缓存服务，支持http协议访问。

其主要特点是：

* 支持10K RPS(5k 写，5k 读)
* 平均响应时间5ms，p99.9 10ms，p99.999 400ms
* 支持大并发访问，本地使用多分片优化缓存
* 忽略内存开销，Map只存储value的索引值，减少GC耗时
* 支持生命时间窗口，每个缓存都有过期时间，定期处理过期缓存
* 一定程度上支持LRU

缺点：

* 缓存底层结构是byte slice，删除缓存只会将数据置0，不会调整位置，这样会导致slice中存在大量“虫洞”
* 不解决冲突，如果hash发生冲突，将直接overwrite原缓存，所以需要一个优秀的hasher，避免冲突

### 组件分析

![](/image/go_cache/bigcache.png)

核心组件关系图

* BigCache

    * shards的数量必须是2的幂，这样就能满足公式x mod N = (x & (N - 1))，只需要使用一次按位AND运算就可以求得余数
    * 可配置OnRemove/OnRemoveWithReason函数，当有缓存被淘汰的时候，bigcache就会回调用户自定义的处理函数
    * 当cleanWindow > 0时，初始化的同时会启动一个协程，每个cleanWindow间隔清除过期缓存

* cacheShard

    * 每一个shard相当于一块缓存，有独立的锁保证线程安全
    * Map的value并不存数据，存的是数据的索引，这是由于Go的开发者优化了垃圾回收时对于map的处理([#9477](https://github.com/golang/go/issues/9477))，如果map对象中的key和value不包含指针，那么垃圾回收器就会对它们进行优化

* queue.BytesQueue

    * 缓存的实际存储结构，是一个环形队列，本质上是byte slice
    * 每个缓存都会被包装成一个entry，附上4字节的header表示长度，
    * 缓存的大小受maxShardSize影响，若用户未配置该属性(=0)，则表示无大小限制
    * 由于所有缓存都存于一个byte slice，即使缓存达到上G大小，也不会影响性能，GC只会将其看做是一个指针
    * BytesQueue里的数据结构如下图所示：


![](/image/go_cache/bytequeue.svg)

* iterator

    * 支持对缓存进行遍历
    * 按分片顺序遍历每块缓存

* encoding

    * 对数据包装，加入时间戳、hashkey、key、数据长度等，以及读取头部字段

* server

    * 该文件夹下封装了一整套的http服务，其中server.go就是服务的入口，可以独立部署bigcache，通过http访问读写缓存

### 核心流程

**GET**

```go
func (c *BigCache) Get(key string) ([]byte, error) {
   // 计算分片
   hashedKey := c.hash.Sum64(key)
   shard := c.getShard(hashedKey)
   return shard.get(key, hashedKey)
}
func (s *cacheShard) get(key string, hashedKey uint64) ([]byte, error) {
   s.lock.RLock()
   // 先查找索引
   itemIndex := s.hashmap[hashedKey]
   
   if itemIndex == 0 {
      s.lock.RUnlock()
      return nil, ErrEntryNotFound
   }
   // 根据索引找出entry
   wrappedEntry, err := s.entries.Get(int(itemIndex))
   if err != nil {
      s.lock.RUnlock()
      s.miss()
      return nil, err
   }
   // 从entry中取出key，再次比对(hash可能存在冲突而被覆盖)
   if entryKey := readKeyFromEntry(wrappedEntry); key != entryKey {
      s.lock.RUnlock()
      return nil, ErrEntryNotFound
   }
   // 从entry中取出real entry
   entry := readEntry(wrappedEntry)
   s.lock.RUnlock()
   return entry, nil
}
```

**SET**

```go
func (c *BigCache) Set(key string, entry []byte) error {
   // 计算分片
   hashedKey := c.hash.Sum64(key)
   shard := c.getShard(hashedKey)
   return shard.set(key, hashedKey, entry)
}
func (s *cacheShard) set(key string, hashedKey uint64, entry []byte) error {
   currentTimestamp := uint64(s.clock.epoch())
   
   s.lock.Lock()
   
   // 先查找旧值
   if previousIndex := s.hashmap[hashedKey]; previousIndex != 0 {
      if previousEntry, err := s.entries.Get(int(previousIndex)); err == nil {
         // 将旧值置0
         resetKeyFromEntry(previousEntry)
      }
   }
   // 查看队首entry是否过期
   if oldestEntry, err := s.entries.Peek(); err == nil {
      s.onEvict(oldestEntry, currentTimestamp, s.removeOldestEntry)
   }
   
   w := wrapEntry(currentTimestamp, hashedKey, key, entry, &s.entryBuffer)
   // 尝试将值加入到队列
   for {
      if index, err := s.entries.Push(w); err == nil {
         s.hashmap[hashedKey] = uint32(index)
         s.lock.Unlock()
         return nil
      }
      // 如果空间不足，会移除队首entry
      if s.removeOldestEntry(NoSpace) != nil {
         s.lock.Unlock()
         return fmt.Errorf("entry is bigger than max shard size")
      }
   }
}
```

***

## [Freecache](https://github.com/coocood/freecache)

内存对象的长期存在会带来巨额的GC开销，而FreeCache可以在内存中缓存无限数量的对象，且不会增加延迟并降低吞吐量。

主要特点：

* 零GC开销
* 高并发线程安全访问
* 支持过期时间(非主动清理)
* 近乎LRU算法
* 严格限制内存使用
* 支持迭代器

缺点：

* 缓存失效是不可靠的，已失效数据可能长时间都不会被清理，而热点数据有几率被误删

### 组件分析

![](/image/go_cache/freecache.svg)

* Cache

    * cache的总入口，封装了固定的256个segment，和与其对应的256个锁
    * 所有对缓存的操作都是从Cache调用

* segment

    * 每个segment下还会再分割出n个slot，且会随着内存对象的增加而扩容
    * segment会维护这个"slot(hashmap)"数据结构，通过对 key 进行 hash func，先拿到对应的 slot，然后 slot 中维护着一个索引，可以定位到具体的数据在数组中的位置。

* RingBuf

    * 缓存的实际数据结构，它的数组空间在逻辑上是一个环状的
    * 其内存大小是初始化的时候就分配好的，每个RingBuf的值为 size / 256
  
下图为主要结构之间的关系

![](/image/go_cache/ringbuf.svg)

* entryPtr

    * 缓存对象的封装，不存实际的value，而是通过里面的信息从RingBuf读取

* Iterator

    * 提供迭代器遍历整个缓存

* server

    * 一个附带的服务器，该服务器通过管道支持一些基本的Redis命令

### 核心流程

**Get**

```go
func (seg *segment) get(key, buf []byte, hashVal uint64, peek bool) (value []byte, expireAt uint32, err error) {
   slotId := uint8(hashVal >> 8)
   hash16 := uint16(hashVal >> 16)
   // 根据key找到相应的slot以及offset
   slot := seg.getSlot(slotId)
   idx, match := seg.lookup(slot, hash16, key)
   if !match {
      err = ErrNotFound
      if !peek {
         atomic.AddInt64(&seg.missCount, 1)
      }
      return
   }
   ptr := &slot[idx]
   
   // 根据offset读取header
   var hdrBuf [ENTRY_HDR_SIZE]byte
   seg.rb.ReadAt(hdrBuf[:], ptr.offset)
   hdr := (*entryHdr)(unsafe.Pointer(&hdrBuf[0]))
   
   // peek表示是否变动access time以及是否进行淘汰，(access time是freecache实现lru的关键)
   if !peek {
      now := seg.timer.Now()
      expireAt = hdr.expireAt
      
      // 淘汰过期对象
      if hdr.expireAt != 0 && hdr.expireAt <= now {
         seg.delEntryPtr(slotId, slot, idx)
         atomic.AddInt64(&seg.totalExpired, 1)
         err = ErrNotFound
         atomic.AddInt64(&seg.missCount, 1)
         return
      }
      // 更新access time和total time
      atomic.AddInt64(&seg.totalTime, int64(now-hdr.accessTime))
      hdr.accessTime = now
      seg.rb.WriteAt(hdrBuf[:], ptr.offset)
   }
   
   if cap(buf) >= int(hdr.valLen) {
      value = buf[:hdr.valLen]
   } else {
      value = make([]byte, hdr.valLen)
   }
   
   // 读取real value
   seg.rb.ReadAt(value, ptr.offset+ENTRY_HDR_SIZE+int64(hdr.keyLen))
   return
}
```

**Set**

```go
func (seg *segment) set(key, value []byte, hashVal uint64, expireSeconds int) (err error) {
   // 不能大于ringbuf最大长度
   maxKeyValLen := len(seg.rb.data)/4 - ENTRY_HDR_SIZE
 if len(key)+len(value) > maxKeyValLen {
      // Do not accept large entry.
      return ErrLargeEntry
   }
   now := seg.timer.Now()
   expireAt := uint32(0)
   if expireSeconds > 0 {
      expireAt = now + uint32(expireSeconds)
   }
   
   slotId := uint8(hashVal >> 8)
   hash16 := uint16(hashVal >> 16)
   
   var hdrBuf [ENTRY_HDR_SIZE]byte
   hdr := (*entryHdr)(unsafe.Pointer(&hdrBuf[0]))
   
   // 先查找旧缓存
   slot := seg.getSlot(slotId)
   idx, match := seg.lookup(slot, hash16, key)
   if match {
      matchedPtr := &slot[idx]
      // 更新旧值
      seg.rb.ReadAt(hdrBuf[:], matchedPtr.offset)
      hdr.slotId = slotId
      hdr.hash16 = hash16
      hdr.keyLen = uint16(len(key))
      originAccessTime := hdr.accessTime
      hdr.accessTime = now
      hdr.expireAt = expireAt
      hdr.valLen = uint32(len(value))
      if hdr.valCap >= hdr.valLen {
         //in place overwrite
         atomic.AddInt64(&seg.totalTime, int64(hdr.accessTime)-int64(originAccessTime))
         seg.rb.WriteAt(hdrBuf[:], matchedPtr.offset)
         seg.rb.WriteAt(value, matchedPtr.offset+ENTRY_HDR_SIZE+int64(hdr.keyLen))
         atomic.AddInt64(&seg.overwrites, 1)
         return
      }
      // 软删除旧值 只设置标记
      // avoid unnecessary memory copy.
      seg.delEntryPtr(slotId, slot, idx)
      match = false
      // increase capacity and limit entry len.
      for hdr.valCap < hdr.valLen {
         hdr.valCap *= 2
      }
      if hdr.valCap > uint32(maxKeyValLen-len(key)) {
         hdr.valCap = uint32(maxKeyValLen - len(key))
      }
   } else {
      // 设置头信息
   }
   
   entryLen := ENTRY_HDR_SIZE + int64(len(key)) + int64(hdr.valCap)
   // 遍历头部触发淘汰策略，直至有足够空间存放新对象
   // 删除过期对象 & 最近最少访问对象(只移动begin，不删数据)
   // 极端情况下(头部n个都不能被删除)，就会无条件删除
   slotModified := seg.evacuate(entryLen, slotId, now)
   if slotModified {
      // the slot has been modified during evacuation, we need to looked up for the 'idx' again.
      // otherwise there would be index out of bound error.
      slot = seg.getSlot(slotId)
      idx, match = seg.lookup(slot, hash16, key)
   }
   // 将offset插入到slot中
   newOff := seg.rb.End()
   seg.insertEntryPtr(slotId, hash16, newOff, idx, hdr.keyLen)
   // entry写入到ringbuf中
   seg.rb.Write(hdrBuf[:])
   seg.rb.Write(key)
   seg.rb.Write(value)
   seg.rb.Skip(int64(hdr.valCap - hdr.valLen))
   atomic.AddInt64(&seg.totalTime, int64(now))
   atomic.AddInt64(&seg.totalCount, 1)
   seg.vacuumLen -= entryLen
   return
}
```

### LRU的实现

freecache实现LRU的方法并非是平常所见的map + list，而是采用一种近乎LRU的方式实现的。每个entry的header会保存entry的**access time**，每个segment里都会存有**totalTime**和**totalCount**两个字段，totalTime就是该segment里所有entry的access time之和，totalCount就是entry的数量。

而freecache的淘汰条件就是access time \* total count <= total time

每次非peek访问，都会去更新entry header里的access time和segment的total time，来保证能淘汰掉最近最少访问的缓存

***

## 参考文献

**\[1]** [groupcache](https://talks.golang.org/2013/oscon-dl.slide#43)

**\[2]** [妙到颠毫: bigcache优化技巧](https://colobu.com/2019/11/18/how-is-the-bigcache-is-fast/)

**\[3]** [从入门到掉坑：Go 内存池/对象池技术介绍](https://cloud.tencent.com/developer/article/1638446)

**\[4]** [Go 语言进阶：freecache 源码学习](https://zhuanlan.zhihu.com/p/67298011)
