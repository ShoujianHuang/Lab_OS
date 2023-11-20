# Lab4

#### 进程控制块

在实验四中，进程管理信息用struct proc_struct表示，在*kern/process/proc.h*中定义如下：

```
struct proc_struct {
    enum proc_state state;                  // Process state
    int pid;                                // Process ID
    int runs;                               // the running times of Proces
    uintptr_t kstack;                       // Process kernel stack
    volatile bool need_resched;             // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;             // the parent process
    struct mm_struct *mm;                   // Process's memory management field
    struct context context;                 // Switch here to run process
    struct trapframe *tf;                   // Trap frame for current interrupt
    uintptr_t cr3;                          // CR3 register: the base addr of Page Directroy Table(PDT)
    uint32_t flags;                         // Process flag
    char name[PROC_NAME_LEN + 1];           // Process name
    list_entry_t list_link;                 // Process link list 
    list_entry_t hash_link;                 // Process hash list
};
```

下面重点解释一下几个比较重要的成员变量：

* `mm`：这里面保存了内存管理的信息，包括内存映射，虚存管理等内容。具体内在实现可以参考之前的章节。
* `state`：进程所处的状态。uCore中进程状态有四种：分别是 `PROC_UNINIT`、`PROC_SLEEPING`、`PROC_RUNNABLE`、`PROC_ZOMBIE`。
* `parent`：里面保存了进程的父进程的指针。在内核中，只有内核创建的idle进程没有父进程，其他进程都有父进程。进程的父子关系组成了一棵进程树，这种父子关系有利于维护父进程对于子进程的一些特殊操作。
* `context`：`context`中保存了进程执行的上下文，也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态（进程切换的详细过程在后面会介绍）。切换过程的实现在 `kern/process/switch.S`。
* `tf`：`tf`里保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中（注意这里需要保存的执行状态数量不同于上下文切换）。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。
* `cr3`：`cr3`寄存器是x86架构的特殊寄存器，用来保存页表所在的基址。出于legacy的原因，我们这里仍然保留了这个名字，但其值仍然是页表基址所在的位置。
* `kstack`: 每个线程都有一个内核栈，并且位于内核地址空间的不同位置。对于内核线程，该栈就是运行时的程序使用的栈；而对于普通进程，该栈是发生特权级改变的时候使保存被打断的硬件信息用的栈。uCore在创建进程时分配了 2 个连续的物理页（参见memlayout.h中KSTACKSIZE的定义）作为内核栈的空间。这个栈很小，所以内核中的代码应该尽可能的紧凑，并且避免在栈上分配大的数据结构，以免栈溢出，导致系统崩溃。kstack记录了分配给该进程/线程的内核栈的位置。主要作用有以下几点。首先，当内核准备从一个进程切换到另一个的时候，需要根据kstack 的值正确的设置好 tss （可以回顾一下在实验一中讲述的 tss 在中断处理过程中的作用），以便在进程切换以后再发生中断时能够使用正确的栈。其次，内核栈位于内核地址空间，并且是不共享的（每个线程都拥有自己的内核栈），因此不受到 mm 的管理，当进程退出的时候，内核能够根据 kstack 的值快速定位栈的位置并进行回收。uCore 的这种内核栈的设计借鉴的是 linux 的方法（但由于内存管理实现的差异，它实现的远不如 linux 的灵活），它使得每个线程的内核栈在不同的位置，这样从某种程度上方便调试，但同时也使得内核对栈溢出变得十分不敏感，因为一旦发生溢出，它极可能污染内核中其它的数据使得内核崩溃。如果能够通过页表，将所有进程的内核栈映射到固定的地址上去，能够避免这种问题，但又会使得进程切换过程中对栈的修改变得相当繁琐。感兴趣的同学可以参考 linux kernel 的代码对此进行尝试。

#### 全局变量

为了管理系统中所有的进程控制块，uCore维护了如下全局变量（位于 *kern/process/proc.c* ）：

● static struct proc *current：当前占用CPU且处于“运行”状态进程控制块指针。通常这个变量是只读的，只有在进程切换的时候才进行修改，并且整个切换和修改过程需要保证操作的原子性，目前至少需要屏蔽中断。可以参考 switch_to 的实现。

● static struct proc *initproc：本实验中，指向一个内核线程。本实验以后，此指针将指向第一个用户态进程。

● static list_entry_t hahash_listsh_list[HASH_LIST_SIZE]：所有进程控制块的哈希表，proc_struct中的成员变量hash_link将基于pid链接入这个哈希表中。

● list_entry_t proc_list：所有进程控制块的双向线性列表，proc_struct中的成员变量list_link将链接入这个链表中。

关于hash的使用：

```
// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}
```

可以看到，hashproc是将新进程添加到hash_list

findproc将根据pid从hash_list中找出对应的proc_struct

#### 进程执行过程

```
// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) {
            schedule();
        }
    }
}
```

第一个进程idle执行进程的调度。

工作就是在current目前运行的进程need_resched时进行进程的调度

```
// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");

    }
  
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process ++;

    current = idleproc;

    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}
```

这段代码是在初始化第一个内核线程idleproc并创建第二个内核线程init_main。
该函数初始化了proc_list和hash_list数据结构。然后使用alloc_proc函数为idleproc进程分配内存。然后通过将其属性与预期值进行比较来检查idleproc进程的正确性。如果检查通过，则将idleproc的pid设置为0，其状态设置为PROC_RUNNABLE，其内核堆栈设置为bootstack。
idleproc的名称设置为"idle"，进程数增加1。
然后将current指针设置为idleproc。调用kernel_thread函数创建init_main进程。如果创建init_main失败，则内核会崩溃。然后将initproc进程设置为pid为1的进程，并将其名称设置为"init"。最后，使用断言确保idleproc和initproc不为NULL，并且它们的pid分别为0和1。


下面我们来分析一下创建内核线程的函数kernel_thread：

```
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    // 对trameframe，也就是我们程序的一些上下文进行一些初始化
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));

    // 设置内核线程的参数和函数指针
    tf.gpr.s0 = (uintptr_t)fn; // s0 寄存器保存函数指针
    tf.gpr.s1 = (uintptr_t)arg; // s1 寄存器保存函数参数

    // 设置 trapframe 中的 status 寄存器（SSTATUS）
    // SSTATUS_SPP：Supervisor Previous Privilege（设置为 supervisor 模式，因为这是一个内核线程）
    // SSTATUS_SPIE：Supervisor Previous Interrupt Enable（设置为启用中断，因为这是一个内核线程）
    // SSTATUS_SIE：Supervisor Interrupt Enable（设置为禁用中断，因为我们不希望该线程被中断）
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;

    // 将入口点（epc）设置为 kernel_thread_entry 函数，作用实际上是将pc指针指向它(*trapentry.S会用到)
    tf.epc = (uintptr_t)kernel_thread_entry;

    // 使用 do_fork 创建一个新进程（内核线程），这样才真正用设置的tf创建新进程。
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

注意，kernel_thread函数采用了局部变量tf来放置保存内核线程的临时中断帧，并把中断帧的指针传递给do_fork函数，而do_fork函数会调用copy_thread函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间。

给中断帧分配完空间后，就需要构造新进程的中断帧，具体过程是：首先给tf进行清零初始化，随后设置设置内核线程的参数和函数指针。要特别注意对tf.status的赋值过程，其读取sstatus寄存器的值，然后根据特定的位操作，设置SPP和SPIE位，并同时清除SIE位，从而实现特权级别切换、保留中断使能状态并禁用中断的操作。


do_fork执行了进程链接

```
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
  
    if ((proc = alloc_proc()) == NULL)
        goto fork_out;
    if ((ret = setup_kstack(proc)) != 0)
        goto fork_out;
    if ((ret = copy_mm(clone_flags, proc)) != 0)
        goto fork_out;
    copy_thread(proc, stack, tf);
    ret = proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));
    wakeup_proc(proc);  

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

这个函数首先检查系统中是否有空闲进程。如果没有，则函数返回错误代码 `-E_NO_FREE_PROC`。如果有，则函数调用 `alloc_proc` 函数来分配一个新的进程结构体。接下来，函数调用 `setup_kstack` 函数来为新进程分配内核栈。然后，函数调用 `copy_mm` 函数来复制或共享当前进程的内存空间。如果 `clone_flags` 中包含 `CLONE_VM` 标志，则函数共享内存；否则，函数复制内存。接下来，函数调用 `copy_thread` 函数来设置新进程的上下文和陷阱帧。然后，函数将新进程添加到进程哈希表和进程列表中。最后，函数调用 `wakeup_proc` 函数将新进程设置为可运行状态，并返回新进程的 PID 值。

```
// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

```

copythread在这里我们首先在上面分配的内核栈上分配出一片空间来保存 `trapframe`。然后，我们将 `trapframe`中的 `a0`寄存器（返回值）设置为0，说明这个进程是一个子进程。之后我们将上下文中的 `ra`设置为了 `forkret`函数的入口，并且把 `trapframe`放在上下文的栈顶。


#### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

* 请说明proc_struct中 `struct context context`和 `struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

```
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = NULL;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN+1);

    }
    return proc;
}
```

alloc_proc执行的是初始化idle进程之前，需要给他一个空的proc_struct，主要就是一步步进行初始化

上述三条语句中,第一条设置了进程的状态为“初始”态，这表示进程已经 “出生”了，正在获取资源茁壮成长中；第二条语句设置了进程的pid为-1，这表示进程的“身份证号”还没有办好；第三条语句表明由于该内核线程在内核中运行，故采用为uCore内核已经建立的页表，即设置为在uCore内核页表的起始地址boot_cr3。后续实验中可进一步看出所有内核线程的内核虚地址空间（也包括物理地址空间）是相同的。既然内核线程共用一个映射内核空间的页表，这表示内核空间对所有内核线程都是“可见”的，所以更精确地说，这些内核线程都应该是从属于同一个唯一的“大内核进程”—uCore内核。

#### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们 **实际需要"fork"的东西就是stack和trapframe** 。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

* 调用alloc_proc，首先获得一块用户信息块。
* 为进程分配一个内核栈。
* 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
* 复制原进程上下文到新进程
* 将新进程添加到进程列表
* 唤醒新进程
* 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

* 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。
* get_pid会分配唯一的id

```
    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
  
    if ((proc = alloc_proc()) == NULL)
        goto fork_out;
    if ((ret = setup_kstack(proc)) != 0)
        goto fork_out;
    if ((ret = copy_mm(clone_flags, proc)) != 0)
        goto fork_out;
    copy_thread(proc, stack, tf);
    ret = proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));
    wakeup_proc(proc);  
```

在运行过程中，调用get_pid();这个函数会给每个线程分配一个唯一的pid

```
// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

请注意，这个函数的实现方式是通过遍历系统中的所有进程来检查 PID 是否已在使用中。如果 PID 已在使用中，则函数增加上一个 PID 并重复该过程。如果 PID 未在使用中，则函数检查它是否大于上一个 PID 并小于下一个安全 PID。如果是，则函数将下一个安全 PID 设置为当前 PID。最后，函数返回上一个 PID 值。

安全PID相当于在每一次遍历过程中确定一个范围，在last_pid和next_safe之间的pid都是空闲的。如果last_pid增长到了next_safe，则遍历链表重新找到下一个safe。

#### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

* 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
* 禁用中断。你可以使用 `/kern/sync/sync.h`中定义好的宏 `local_intr_save(x)`和 `local_intr_restore(x)`来实现关、开中断。
* 切换当前进程为要运行的进程。
* 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了 `lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
* 实现上下文切换。`/kern/process`中已经预先编写好了 `switch.S`，其中定义了 `switch_to()`函数。可实现两个进程的context切换。
* 允许中断。

请回答如下问题：

* 在本实验的执行过程中，创建且运行了几个内核线程？

本实验执行过程中创建且运行了两个内核线程。

```
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */

        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = proc;
            lcr3(next->cr3);
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
   
    }
}

```

主要进行三个操作：

保存断点

切换进程

切换页表基址

切换上下文



完成代码编写后，编译并运行代码：make qemu

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

#### 扩展练习 Challenge：

* 说明语句 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

```
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

```

首先判断SIE是否为1，是否处于可以中断状态

使用intr_disable关中断

使用intr_enable开中断

在这里出现的local_intr_save和local_intr_restore，其功能就是避免执行中间语句的时候被打断，即某种意义上的原语操作。
