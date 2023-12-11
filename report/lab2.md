# Lab2

#### 页表项

一个页表项是用来描述一个虚拟页号如何映射到物理页号的。

在sv39的一个页表项（PTE, Page Table Entry）占据8字节（64位），那么页表项结构是这样的：

| 63-54        | 53-28  | 27-19  | 18-10  | 9-8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| ------------ | ------ | ------ | ------ | --- | - | - | - | - | - | - | - | - |
| *Reserved* | PPN[2] | PPN[1] | PPN[0] | RSW | D | A | G | U | X | W | R | V |
| 10           | 26     | 9      | 9      | 2   | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

我们可以看到 sv39 里面的一个页表项大小为 64 位 8 字节。其中第 53-10 位共44位为一个物理页号，表示这个虚拟页号映射到的物理页号。后面的第 9-0 位共10位则描述映射的状态信息。

介绍一下映射状态信息各位的含义：

* RSW：两位留给 S Mode 的应用程序，我们可以用来进行拓展。
* D：即 Dirty ，如果 D=1 表示自从上次 D 被清零后，有虚拟地址通过这个页表项进行写入。
* A，即 Accessed，如果 A=1 表示自从上次 A 被清零后，有虚拟地址通过这个页表项进行读、或者写、或者取指。
* G，即 Global，如果 G=1 表示这个页表项是”全局"的，也就是所有的地址空间（所有的页表）都包含这一项
* U，即 user，U为 1 表示用户态 (U Mode)的程序 可以通过该页表项进映射。在用户态运行时也只能够通过 U=1 的页表项进行虚实地址映射。 注意，S Mode 不一定可以通过 U=1 的页表项进行映射。我们需要将 S Mode 的状态寄存器 sstatus 上的 SUM 位手动设置为 1 才可以做到这一点（通常情况不会把它置1）。否则通过 U=1 的页表项进行映射也会报出异常。另外，不论sstatus的SUM位如何取值，S Mode都不允许执行 U=1 的页面里包含的指令，这是出于安全的考虑。
* R,W,X 为许可位，分别表示是否可读 (Readable)，可写 (Writable)，可执行 (Executable)。

| X | W | R | Meaning                           |
| - | - | - | --------------------------------- |
| 0 | 0 | 0 | 指向下一级页表的指针              |
| 0 | 0 | 1 | 这一页只读                        |
| 0 | 1 | 0 | *保留(reserved for future use)* |
| 0 | 1 | 1 | 这一页可读可写（不可执行）        |
| 1 | 0 | 0 | 这一页可读可执行（不可写）        |
| 1 | 0 | 1 | 这一页可读可执行                  |
| 1 | 1 | 0 | *保留(reserved for future use)* |
| 1 | 1 | 1 | 这一页可读可写可执行              |

#### 多级页表

我们使用的sv39权衡各方面效率，使用三级页表。有4KiB=4096字节的页，大小为2MiB= 2^21 字节的大页，和大小为1 GiB 的大大页。

整个Sv39的虚拟内存空间里，有512（2的9次方）个大大页，每个大大页里有512个大页，每个大页里有512个页，每个页里有4096个字节，整个虚拟内存空间里就有512∗512∗512∗4096个字节，是512GiB的地址空间。

那么为啥是512呢？注意，4096/8 = 512，我们恰好可以在一页里放下512个页表项。

#### 页表基址

在翻译的过程中，我们首先需要知道树状页表的根节点的物理地址。这一般保存在一个特殊寄存器里。对于RISCV架构，是一个叫做 `satp`（Supervisor Address Translation and Protection Register）的CSR。实际上，`satp`里面存的不是最高级页表的起始物理地址，而是它所在的物理页号。除了物理页号，`satp`还包含其他信息。

| 63-60      | 59-44      | 43-0      |
| ---------- | ---------- | --------- |
| MODE(WARL) | ASID(WARL) | PPN(WARL) |
| 4          | 16         | 44        |

MODE表示当前页表的模式：

* 0000表示不使用页表，直接使用物理地址，在简单的嵌入式系统里用着很方便。
* 0100表示sv39页表，也就是我们使用的，虚拟内存空间高达 `512GiB`。
* 0101表示Sv48页表，它和Sv39兼容。
* 其他编码保留备用 ASID（address space identifier）我们目前用不到 。OS 可以在内存中为不同的应用分别建立不同虚实映射的页表，并通过修改寄存器 satp 的值指向不同的页表，从而可以修改 CPU 虚实地址映射关系及内存保护的行为。

#### 建立快表以加快访问效率

实践表明虚拟地址的访问具有时间局部性和空间局部性。

因此，在 CPU 内部，我们使用快表 (TLB, Translation Lookaside Buffer) 来记录近期已完成的虚拟页号到物理页号的映射。由于局部性，当我们要做一个映射时，会有很大可能这个映射在近期被完成过，所以我们可以先到 TLB 里面去查一下，如果有的话我们就可以直接完成映射，而不用访问那么多次内存了。 但是，我们如果修改了 satp 寄存器，比如将上面的 PPN 字段进行了修改，说明我们切换到了一个与先前映射方式完全不同的页表。此时快表里面存储的映射结果就跟不上时代了，很可能是错误的。这种情况下我们要使用 `sfence.vma` 指令刷新整个 TLB 。 同样，我们手动修改一个页表项之后，也修改了映射，但 TLB 并不会自动刷新，我们也需要使用 `sfence.vma` 指令刷新 TLB 。如果不加参数的， `sfence.vma` 会刷新整个 TLB 。你可以在后面加上一个虚拟地址，这样 `sfence.vma` 只会刷新这个虚拟地址的映射。

#### 内核空间

内核空间不超过1GB，在上述我们只需分配一个三级页表项，将他放在三级页表最后一个，作为全局可访问的页表项。

页=2^12=4KB=1个一级页表项

一级页表=2^21=2MB=1个二级页表项

二级页表=2^30=1GB=1个三级页表项

三级页表=2^39=512GB

#### 思考

在linux内核中常常会看到do{} while(0)这样的语句，do{} while(0)内的语句只能执行一次，那么加不加do{} while(0)有什么区别呢？或者说加了do{} while(0)语句有什么作用呢？

宏被展开后，上面的调用语句才会保留初始的语义。do能确保大括号里的逻辑能被执行，而while(0)能确保该逻辑只被执行一次，就像没有循环语句一样。

#### qemu物理地址

```
struct Page {
    int ref;                 // page frame's reference counter
    uint64_t flags;          // array of flags that describe the status of the page frame
    unsigned int property;   // the num of free block, used in first fit pm manager
    list_entry_t page_link;  // free list link
};
```

Qemu 规定的 DRAM 物理内存的起始物理地址为 `0x80000000` 。而在 Qemu 中，可以使用 `-m` 指定 RAM 的大小，默认是 `128MiB` 。因此，默认的 DRAM 物理内存地址范围就是 `[0x80000000,0x88000000)`。

为了管理物理内存，我们需要在内核里定义一些数据结构，来存储”当前使用了哪些物理页面，哪些物理页面没被使用“这样的信息，使用的是Page结构体。我们将一些Page结构体在内存里排列在内核后面，这要占用一些内存。而摆放这些Page结构体的物理页面，以及内核占用的物理页面，之后都无法再使用了。我们用 `page_init()`函数给这些管理物理内存的结构体做初始化。

#### 地址初始化步骤

```
PG_reserved      // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0
PG_property     // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.
```

1.pages指针指向内核初始化完毕终点的后一页

2.将pages中0~npage-nbase-1页面全部设为保留内核

3.自由使用的free页为设置完保存所有页的页表项的后一页

4.使用定义的init_memmap完成自由页面的初始化

```
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // number of free pages in this free list
} free_area_t;
```

全局的free_area_t保存空闲链表的首节点

```
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {              //将所有的页的property标签设置为0，引用置零。
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;                   //设置空页面数量为n
    SetPageProperty(base);               //设置第一个页面property位为1，表示第一个空闲页
    nr_free += n;                       //空闲页数量增加
    if (list_empty(&free_list)) {      //若freelist为空，则把他连接到freelist，
        list_add(&free_list, &(base->page_link));
    } else {                              // 若freelist不为空，找到最后一个节点，base在page之前，连入链尾，否则连入链头
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {       //使用le遍历freelist，base<page,空闲地址小于当前le,放到le前
            struct Page* page = le2page(le, page_link);   //base>page，继续向后遍历le，直到找到base<page
            if (base < page) {                            //如果下一个到了freelist头，说明到最后也没找到base<page，直接连入链尾
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）

first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合 `kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：

* 你的first fit算法是否有进一步的改进空间？
* alloc函数只支持分配一块连续的空间，不能分配分散的加起来的空间。

```
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {     //要分配的页大于拥有的空闲页，返回null
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {   //遍历freelist
        struct Page *p = le2page(le, page_link);   
        if (p->property >= n) {                     //这一块空闲页大于n,可以用来分配
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));     //该块上一个空闲块
        list_del(&(page->page_link));                           //删除page对应链
        if (page->property > n) {                              //如果刚好分配，完成了；否则需要添加剩下的部分进入空闲链
            struct Page *p = page + n;                        //找到page+n页
            p->property = page->property - n;               //设为第一个空闲页数量为原来的-n
            SetPageProperty(p);                           //设为第一个空闲页标志
            list_add(prev, &(p->page_link));               //将原来的上一个块和新的块合起来成一个新的双向链
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

```
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));      //不能释放内核空间和空闲页
        p->flags = 0;                                      //标志位置零
        set_page_ref(p, 0);                                //引用位置零
    }
    base->property = n;                                   //空闲页为n
    SetPageProperty(base);                               //设置空闲首页property=1
    nr_free += n;                                        //空闲页总数+n

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));      //空闲链表为空，直接赋值
    } else {
        list_entry_t* le = &free_list;                 //与初始化一样
        while ((le = list_next(le)) != &free_list) {   //使用le遍历freelist，base<page,空闲地址小于当前le,放到le前
            struct Page* page = le2page(le, page_link);
            if (base < page) {                                //base>page，继续向后遍历le，直到找到base<page
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {     //如果下一个到了freelist头，说明到最后也没找到base<page，直接连入链尾
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));       //查插入空闲节点的上一个节点
    if (le != &free_list) {                                 //le不是freelist，即le不是链中唯一的节点
        p = le2page(le, page_link);
        if (p + p->property == base) {                     //检查与前一个块是否连续。如果连续，需要删除后一个块的property标记，并将长度加到前一个块
            p->property += base->property;   
            ClearPageProperty(base);
            list_del(&(base->page_link));                 //完成后在空闲链表中删除list_del后一个节点
            base = p;
        }
    }

    le = list_next(&(base->page_link));                  //查插入空闲节点的下一个节点
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {               //与上述过程一致
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

* 你的 Best-Fit 算法是否有进一步的改进空间？
* 可以通过将空闲链表通过大小而不是地址顺序排序，形成一个排序树或平衡树或红黑树，能logn更快找到目标块。

仅以下部分需要修改，其他部分均可与default中一致

```
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            if(p->property<min_size){
                page = p;
                min_size=p->property;
            }
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

* 参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

```

```

#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

* 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）

* 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？
