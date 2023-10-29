# Lab3

#### 磁盘文件

`ide`在这里不是integrated development environment的意思，而是Integrated Drive Electronics的意思，表示的是一种标准的硬盘接口。我们这里写的东西和Integrated Drive Electronics并不相关，这个命名是ucore的历史遗留。

`fs`全称为file system,我们这里其实并没有“文件”的概念，这个模块称作 `fs`只是说明它是“硬盘”和内核之间的接口。

```
// kern/driver/ide.c
/*
#include"s
*/

void ide_init(void) {}

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];
```

实际上定义了一个char数组，之后利用一系列函数进行访问。

#### KADDR和PADDR

```
/* *
 * PADDR - takes a kernel virtual address (an address that points above
 * KERNBASE),
 * where the machine's maximum 256MB of physical memory is mapped and returns
 * the
 * corresponding physical address.  It panics if you pass it a non-kernel
 * virtual address.
 * */
#define PADDR(kva)                                                 \
    ({                                                             \
        uintptr_t __m_kva = (uintptr_t)(kva);                      \
        if (__m_kva < KERNBASE) {                                  \
            panic("PADDR called with invalid kva %08lx", __m_kva); \
        }                                                          \
        __m_kva - va_pa_offset;                                    \
    })

/* *
 * KADDR - takes a physical address and returns the corresponding kernel virtual
 * address. It panics if you pass an invalid physical address.
 * */
#define KADDR(pa)                                                \
    ({                                                           \
        uintptr_t __m_pa = (pa);                                 \
        size_t __m_ppn = PPN(__m_pa);                            \
        if (__m_ppn >= npage) {                                  \
            panic("KADDR called with invalid pa %08lx", __m_pa); \
        }                                                        \
        (void *)(__m_pa + va_pa_offset);                         \
    })
```

PADDR实际上就是将内核虚拟地址装化为物理地址，同理KADDR将物理地址转化为内核虚拟地址。（物理地址实际上是内核中分配的一篇连续空间）。

#### 地址空间

```
// Sv39 virtual address:
// +----9----+----9---+----9---+---12--+
// |  VPN[2] | VPN[1] | VPN[0] | PGOFF |
// +---------+----+---+--------+-------+
//
// Sv39 physical address:
// +----26---+----9---+----9---+---12--+
// |  PPN[2] | PPN[1] | PPN[0] | PGOFF |
// +---------+----+---+--------+-------+
//
// Sv39 page table entry:
// +----26---+----9---+----9---+---2----+-------8-------+
// |  PPN[2] | PPN[1] | PPN[0] |Reserved|D|A|G|U|X|W|R|V|
// +---------+----+---+--------+--------+---------------+
```

#### 增加页表项

```
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    //pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
    pte_t *ptep = get_pte(pgdir, la, 1);
    //先找到对应页表项的位置，如果原先不存在，get_pte()会分配页表项的内存
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page);//指向这个物理页面的虚拟地址增加了一个
    if (*ptep & PTE_V) { //原先存在映射
        struct Page *p = pte2page(*ptep);
        if (p == page) {//如果这个映射原先就有
            page_ref_dec(page);
        } else {//如果原先这个虚拟地址映射到其他物理页面，那么需要删除映射
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);//构造页表项
    tlb_invalidate(pgdir, la);//页表改变之后要刷新TLB
    return 0;
}
```

第一步，获得页表项

第二步，page引用+1

第三步，映射原来存在，page引用-1（相当于不变）；映射到了其他页面，删除映射。

第四步，构造一个balid的页表项

第五步，刷新tlb（失效）

#### 删除页表项

```
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0);//找到页表项所在位置
    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep);//删除这个页表项的映射
    }
}
//删除一个页表项以及它的映射
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) {  //(1) check if this page table entry is valid
        struct Page *page = pte2page(*ptep);  //(2) find corresponding page to pte
        page_ref_dec(page);   //(3) decrease page reference
        if (page_ref(page) == 0) {  
            //(4) and free this page when page reference reachs 0
            free_page(page);
        }
        *ptep = 0;                  //(5) clear page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}
```

第一步，检查地址和有效位，保证映射存在。

第二步，找到对应页目录项对应的页表。

第三步，引用值-1，若为0，则回收页面

第四步，tlb对应位置刷新为无效

#### 分配页表项

```
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    /* LAB2 EXERCISE 2: YOUR CODE
     *
     * If you need to visit a physical address, please use KADDR()
     * please read pmm.h for useful macros
     *
     * Maybe you want help comment, BELOW comments can help you finish the code
     *
     * Some Useful MACROs and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   PDX(la) = the index of page directory entry of VIRTUAL ADDRESS la.
     *   KADDR(pa) : takes a physical address and returns the corresponding
     * kernel virtual address.
     *   set_page_ref(page,1) : means the page be referenced by one time
     *   page2pa(page): get the physical address of memory which this (struct
     * Page *) page  manages
     *   struct Page * alloc_page() : allocation a page
     *   memset(void *s, char c, size_t n) : sets the first n bytes of the
     * memory area pointed by s
     *                                       to the specified value c.
     * DEFINEs:
     *   PTE_P           0x001                   // page table/directory entry
     * flags bit : Present
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];//找到对应的Giga Page
    if (!(*pdep1 & PTE_V)) {//如果下一级页表不存在，那就给它分配一页，创造新页表
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        //我们现在在虚拟地址空间中，所以要转化为KADDR再memset.
        //不管页表怎么构造，我们确保物理地址和虚拟地址的偏移量始终相同，那么就可以用这种方式完成对物理内存的访问。
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);//注意这里R,W,X全零
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];//再下一级页表
    //这里的逻辑和前面完全一致，页表不存在就现在分配一个
    if (!(*pdep0 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
                return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    //找到输入的虚拟地址la对应的页表项的地址(可能是刚刚分配的)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

第一步，在一级页表中找到虚拟地址页目录号对应的页目录项，观察二级页表是否存在

第二步，PTE_V在第一位，所以与1的操作可以相当于&&，即页面不存在。通过alloc_page找到一个物理页，设置引用位为1

第三步，找到page的物理地址(pa)，利用KADDR转化为内核中的地址，内核中实际上给他一个页的大小，将这个页刷新。并创建二级页表中的二级页表项

第四步，按同样的方式分配三级页表项

最后返回三级页表项对应的页，即最终的划分的页

这里有两行函数

```
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}
```

page2pnn获得了相对全局的页的次数，当前页地址-页数组地址+基地址页数，相当于物理地址中的除页偏移的TAG号。

page2pa实现了将这个号左移pageshift获得其物理地址（不是内核地址）

#### 缺页

```
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
```

首先来看看alloc_page函数，他将系统中分配n个页。在这里出现的local_intr_save和local_intr_restore，其功能就是避免执行中间语句的时候被打断，即某种意义上的原语操作。使用swap_out换出。

之前我们进行物理页帧管理时有个功能没有实现，那就是动态的内存分配。管理虚拟内存的数据结构（页表）需要有空间进行存储，而我们又没有给它预先分配内存（也无法预先分配，因为事先不确定我们的页表需要分配多少内存），于是我们就需要设置接口来负责分配释放内存，这里我们选择的是 `malloc/free`的接口。同样，我们也要在 `pmm.h`里编写对物理页面和虚拟地址，物理地址进行转换的一些函数。

```
// kern/mm/pmm.c
void *kmalloc(size_t n) { //分配至少n个连续的字节，这里实现得不精细，占用的只能是整数个页。
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
    int num_pages = (n + PGSIZE - 1) / PGSIZE; //向上取整到整数个页
    base = alloc_pages(num_pages); 
    assert(base != NULL); //如果分配失败就直接panic
    ptr = page2kva(base); //分配的内存的起始位置（虚拟地址），
    //page2kva, 就是page_to_kernel_virtual_address
    return ptr;
}

void kfree(void *ptr, size_t n) { //从某个位置开始释放n个字节
    assert(n > 0 && n < 1024 * 0124);
    assert(ptr != NULL);
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE; 
    /*计算num_pages和kmalloc里一样，
    但是如果程序员写错了呢？调用kfree的时候传入的n和调用kmalloc传入的n不一样？
    就像你平时在windows/linux写C语言一样，会出各种奇奇怪怪的bug。
    */
    base = kva2page(ptr);//kernel_virtual_address_to_page
    free_pages(base, num_pages);
}
```

kmalloc返回一个kva内核地址

kfree使用init_manager，即lab2的功能实现回收空闲页。

#### 页面置换的结构体

在vmm.h定义两个结构体 (vmm：virtural memory management)。

* `vma_struct`结构体描述一段连续的虚拟地址，从 `vm_start`到 `vm_end`。 通过包含一个 `list_entry_t`成员，我们可以把同一个页表对应的多个 `vma_struct`结构体串成一个链表，在链表里把它们按照区间的起始点进行排序。
* `vm_flags`表示的是一段虚拟地址对应的权限（可读，可写，可执行等），这个权限在页表项里也要进行对应的设置。

我们注意到，每个页表（每个虚拟地址空间）可能包含多个 `vma_struct`, 也就是多个访问权限可能不同的，不相交的连续地址区间。我们用 `mm_struct`结构体把一个页表对应的信息组合起来，包括 `vma_struct`链表的首指针，对应的页表在内存里的指针，`vma_struct`链表的元素个数。

除了以上内容，我们还需要为 `vma_struct`和 `mm_struct`定义和实现一些接口：包括它们的构造函数，以及如何把新的 `vma_struct`插入到 `mm_struct`对应的链表里。注意这两个结构体占用的内存空间需要用 `kmalloc()`函数动态分配。

```
// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
//如果返回NULL，说明查询的虚拟地址不存在/不合法，既不对应内存里的某个页，也不对应硬盘里某个可以换进来的页
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL;
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}
```

这段代码实现的是根据虚拟地址在链表中找到对应的vma，找到了vma，就相当于知道了磁盘中的位置，或内存中调入的物理地址。

主要关注缺页处理部分

```
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    //addr: 访问出错的虚拟地址
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
    //我们首先要做的就是在mm_struct里判断这个虚拟地址是否可用
    pgfault_num++;
    //If the addr is not in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE); //按照页面大小把地址对齐

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;

    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /*
        * Now we think this pte is a  swap entry, we should load data from disk
        * to a page with phy addr,
        * and map the phy addr with logical addr, trigger swap manager to record
        * the access situation of this page.
        *
        *    swap_in(mm, addr, &page) : alloc a memory page, then according to
        * the swap entry in PTE for addr, find the addr of disk page, read the
        * content of disk page into this memroy page
        *     page_insert ： build the map of phy addr of an Page with the virtual addr la
        *   swap_map_swappable ： set the page swappable
        */
        if (swap_init_ok) {
            struct Page *page = NULL;
            //在swap_in()函数执行完之后，page保存换入的物理页面。
            //swap_in()函数里面可能把内存里原有的页面换出去
            swap_in(mm, addr, &page);  //(1）According to the mm AND addr, try
                                       //to load the content of right disk page
                                       //into the memory which page managed.
            page_insert(mm->pgdir, page, addr, perm); //更新页表，插入新的页表项
            //(2) According to the mm, addr AND page, 
            // setup the map of phy addr <---> virtual addr
            swap_map_swappable(mm, addr, page, 1);  //(3) make the page swappable.
            //标记这个页面将来是可以再换出的
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
failed:
    return ret;
}
```

第一步，找到对应的vma，判断是否可用

第二步，设置标志位，找到ptep，即分配到页表中最后的页空间。

第三步，执行换入：swap_in写入内存,page_insert写入页表，标记页面可换出页面。


#### 练习1：理解基于FIFO的页面替换算法（思考题）

描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了 `kern/mm/swap_fifo.c`文件中，这点请同学们注意）

* 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

（前文分块叙述）

当需要换入页面时，需要调用 `swap.c`文件中的 `swap_in`。

* `swap_in`：用于换入页面。首先调用 `pmm.c`中的 `alloc_page`，申请一块连续的内存空间，然后调用 `get_pte`找到或者构建对应的页表项，最后调用 `swapfs_read`将数据从磁盘写入内存。
* `alloc_page`：用于申请页面。通过调用 `pmm_manager->alloc_pages`申请一块连继续的内存空间，在这个过程中，如果申请页面失败，那么说明需要换出页面，则调用 `swap_out`换出页面，之后再次进行申请。
* `assert(result!=NULL)`：判断获得的页面是否为 `NULL`，只有页面不为 `NULL`才能继续。
* `swap_out`：用于换出页面。首先需要循环调用 `sm->swap_out_victim`，对应于 `swap_fifo`中的 `_fifo_swap_out_victim`。然后调用 `get_pte`获取对应的页表项，将该页面写入磁盘，如果写入成功，释放该页面；如果写入失败，调用 `_fifo_map_swappable`更新FIFO队列。最后刷新TLB。
* `free_page`：用于释放页面。通过调用 `pmm_manager->free_pages`释放页面。
* `assert((*ptep & PTE_V) != 0)`：用于判断获得的页表项是否合法。由于这里需要交换出去页面，所以获得的页表项必须是合法的。
* `swapfs_write`：用于将页面写入磁盘。在这里由于需要换出页面，而页面内容如果被修改过那么就与磁盘中的不一致，所以需要将其重新写回磁盘。
* `tlb_invalidate`：用于刷新TLB。通过调用 `flush_tlb`刷新TLB。
* `get_pte`：用于获得页表项。
* `swapfs_read`：用于从磁盘读入数据。
* `_fifo_swap_out_victim`：用于获得需要换出的页面。查找队尾的页面，作为需要释放的页面。
* `_fifo_map_swappable`：将最近使用的页面添加到队头。在 `swap_out`中调用是用于将队尾的页面移动到队头，防止下一次换出失败。

该页面移动到了链表的末尾时，在下一次有页面换入的时候需要被换出。

#### 练习2：深入理解不同分页模式的工作原理（思考题）

get_pte()函数（位于 `kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

* get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
* 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？


* 详见（分配页表项一标题）。因第一段代码用于从 `GiGa Page`中查找 `PDX1`的地址，如果查得的地址不合法则为该页表项分配内存空间；第二段代码用于从 `MeGa Page`中查找 `PDX0`的地址，如果查得的地址不合法则为该页表项分配内存空间。两次查找的逻辑相同，不同的只有查找的基地址与页表偏移量所在位数。而三种页表管理机制只是虚拟页表的地址长度或页表的级数不同，规定好偏移量即可按照同一规则找出对应的页表项。
* 这种写法更好。因为在大部分情况下，只有在获取页表非法的情况下才会进行创建页表，同时只关心最后一级页表所给出的页，合在一起可以减少代码的冗余，并提高代码的可维护性。

#### 练习3：给未被映射的地址映射上物理页（需要编程）

补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

```
if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            swap_in(mm, addr, &page);
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir, page, addr, perm);
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
            page->pra_vaddr = addr;
        } else {
```

* 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。

  页目录项和页表项中的合法位可以用来判断该页面是否存在，还有一些其他的权限位，比如可读可写，可以用于CLOCK算法或LRU算法。修改位可以决定在换出页面时是否需要写回磁盘。
* 
* 
* 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
* trap--> trap_dispatch-->pgfault_handler-->do_pgfault* 首先保存当前异常原因，根据 `stvec`的地址跳转到中断处理程序，即 `trap.c`文件中的 `trap`函数。

  * 接着跳转到 `exception_handler`中的 `CAUSE_LOAD_ACCESS`处理缺页异常。
  * 然后跳转到 `pgfault_handler`，再到 `do_pgfault`具体处理缺页异常。
  * 如果处理成功，则返回到发生异常处继续执行。
  * 否则输出 `unhandled page fault`。
* 
* 
* 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？


有对应关系。如果页表项映射到了物理地址，那么这个地址对应的就是 `Page`中的一项。页表项对应的页表也需要利用请求分页机制换入换出。

#### 练习4：补充完成Clock页替换算法（需要编程）

通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。(提示:要输出curr_ptr的值才能通过make grade。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

每次添加新页面时会将页面添加到链表尾部。每次换出页面时都会遍历查找最前使用的页面。如果该页访问了，将访问为置零，相当于给了下一次机会，暂时不换出，有良好的局部性。

```
static int
_clock_init_mm(struct mm_struct *mm)
{   
     /*LAB3 EXERCISE 4: YOUR CODE*/ 
     list_init(&pra_list_head);
     curr_ptr = &pra_list_head;
     mm->sm_priv = &pra_list_head;
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: YOUR CODE*/ 
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_add_before(head, entry);
    page->visited = 1;
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问
    return 0;
}
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    while (1) {
        /*LAB3 EXERCISE 4: YOUR CODE*/ 
        // 编写代码
        if(curr_ptr == head) {
            curr_ptr = list_next(curr_ptr);
            if(curr_ptr == head) {
                *ptr_page = NULL;
                break;
            }
        }
        struct Page* page = le2page(curr_ptr, pra_page_link);
        if(!page->visited) {
            list_entry_t *del_ptr = curr_ptr;
            curr_ptr = list_next(curr_ptr);
            cprintf("curr_ptr %p\n",del_ptr);
            list_del(del_ptr);
            *ptr_page = page;
            break;
        } else {
            page->visited = 0;
            curr_ptr = list_next(curr_ptr);
        }
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
    }
    return 0;
}
```

* 比较Clock页替换算法和FIFO算法的不同。
* 
* Clock算法：每次添加新页面时会将页面添加到链表尾部。每次换出页面时都会遍历查找最前使用的页面。如果该页访问了，将访问为置零，相当于给了下一次机会，暂时不换出，有良好的局部性。
* FIFO算法：将链表看成队列，每次添加新页面会将页面添加到链表头部（队列尾部）。每次换出页面时不管队头的页面最近是否访问，均将其换出。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

优点：映射快，因为只需进行一次映射，故只需访问一次就能得到对应的物理地址。

缺点：需要连续的地址空间，占用内存过大。一些永远不会被访问到的页面持续留在内存，效率低。

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。
