# Lab1

### CSR

CSR 是支撑 RISC-V 特权指令集的一个重要概念。CSR 的全称为  **控制与状态寄存器** （control and status registers）。

简单来说，CSR 是 CPU 中的一系列特殊的寄存器，这些寄存器能够反映和控制 CPU 当前的状态和执行机制。在 RISC-V 特权指令集手册 中定义的一些典型的 CSR 如下：

* 八个控制状态寄存器（CSR）是机器模式下异常处理的必要部分：
  mtvec（Machine Trap Vector）它保存发生异常时处理器需要跳转到的地址。
  mepc（Machine Exception PC）它指向发生异常的指令。
  mcause（Machine Exception Cause）它指示发生异常的种类。
  mie（Machine Interrupt Enable）它指出处理器目前能处理和必须忽略的中断。
  mip（Machine Interrupt Pending）它列出目前正准备处理的中断。
  mtval（Machine Trap Value）它保存了陷入（trap）的附加信息：地址例外中出错
  的地址、发生非法指令例外的指令本身，对于其他异常，它的值为0。
  mscratch（Machine Scratch）它暂时存放一个字大小的数据。
  mstatus（Machine Status）它保存全局中断使能，以及许多其他的状态


##### M模式与S模式

默认情况下，发生所有异常（不论在什么权限模式下）的时候，控制权都会被移交到M模式的异常处理程序。但是Unix系统中的大多数例外都应该进行S模式下的系统调用。M模式的异常处理程序可以将异常重新导向S模式，但这些额外的操作会减慢大多数异常的处理速度。因此，RISC-V提供了一种异常委托机制。通过该机制可以选择性地将中断和同步异常交给S模式处理，而完全绕过M模式。

mideleg（Machine Interrupt Delegation，机器中断委托）CSR 控制将哪些中断委托给S模式。与mip和mie一样，mideleg中的每个位对应于图10.3中相同的异常。

sie（Supervisor InterruptEnable，监管者中断使能）和sip（Supervisor Interrupt Pending，监管者中断待处理）CSR
是S模式的控制状态寄存器，他们是mie和mip的子集。它们有着和M模式下相同的布局，但在sie和sip中只有与由mideleg委托的中断对应的位才能读写。那些没有被委派的中断对应的位始终为零。

S 模式有几个异常处理CSR：sepc、stvec、scause、sscratch、stval和sstatus，它们执行与M模式CSR相同的功能。监管者异常返回指令sret与mret的行为相同，但它作用于S模式的异常处理CSR，而不是M模式的CSR。

##### 指令

操作 CSR 的指令在 RISC-V 的 `Zicsr` 扩展模块中定义。包括伪指令在内，共有以下 7 种操作类型：

1. `csrr`，读取一个 CSR 的值到通用寄存器。如：`csrr t0, mstatus`，读取 `mstatus` 的值到 `t0` 中。
2. `csrw`，把一个通用寄存器中的值写入 CSR 中。如：`csrw mstatus, t0`，将 `t0` 的值写入 `mstatus`。
3. `csrs`，把 CSR 中指定的 bit 置 1。如：`csrsi mstatus, (1 << 2)`，将 `mstatus` 的右起第 3 位置 1。
4. `csrc`，把 CSR 中指定的 bit 置 0。如：`csrci mstatus, (1 << 2)`，将 `mstatus` 的右起第 3 位置 0。
5. `csrrw`，读取一个 CSR 的值到通用寄存器，然后把另一个值写入该 CSR。如：`csrrw t0, mstatus, t0`，将 `mstatus` 的值与 `t0` 的值交换。
6. `csrrs`，读取一个 CSR 的值到通用寄存器，然后把该 CSR 中指定的 bit 置 1。
7. `csrrc`，读取一个 CSR 的值到通用寄存器，然后把该 CSR 中指定的 bit 置 0。

##### 关于设置CSR寄存器的值

开启中断共需要经过两个步骤，其中 `mstatus[MIE]` 是中断总开关（MIE 是 machine interrupt enabled 的缩写），`mie` CSR 是针对每种中断类型的独立开关。只有当两个 CSR 都正确设置时，才能够触发中断。

程序中sscratch寄存器

```
 //约定：若中断前处于S态，sscratch为0
    //若中断前处于U态，sscratch存储内核栈地址
    //那么之后就可以通过sscratch的数值判断是内核态产生的中断还是用户态产生的中断
```

在设置中断保存现场有这么一个汇编语句

```
   # Set sscratch register to 0, so that if a recursive exception
    # occurs, the exception vector knows it came from the kernel
    csrrw s0, sscratch, x0
```

目的就是设置ssr为0

riscv.h中定义了两个函数

```
#define set_csr(reg, bit) ({ unsigned long __tmp; \
  if (__builtin_constant_p(bit) && (unsigned long)(bit) < 32) \
    asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "i"(bit)); \
  else \
    asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "r"(bit)); \
  __tmp; })

#define clear_csr(reg, bit) ({ unsigned long __tmp; \
  if (__builtin_constant_p(bit) && (unsigned long)(bit) < 32) \
    asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "i"(bit)); \
  else \
    asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "r"(bit)); \
  __tmp; })
```

采用汇编方式实现了设置scr值。

使用这两个函数的地方有设置时钟

```
set_csr(sie, MIP_STIP);
```

设置开中断

```
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
```

分别对应上述两种情况

### 中断向量寄存器

 **sepc** (supervisor exception program counter)，它会记录触发中断的那条指令的地址；

 **scause** ，它会记录中断发生的原因，还会记录该中断是不是一个外部中断；

 **stval** ，它会记录一些中断处理所需要的辅助信息，比如指令获取(instruction fetch)、访存、缺页异常，它会把发生问题的目标地址或者出错的指令记录下来，这样我们在中断处理程序中就知道处理目标了。

### 练习1：理解内核启动中的程序入口操作

1. `la sp,bootstacktop`：将 `bootstacktop`对应的地址赋值给 `sp`寄存器，目的是初始化栈，为栈分配内存空间。
2. `tail kern_init`：尾调用，在函数 `kern_init`的位置继续执行，目的是进入操作系统的入口，也避免了这一次的函数调用影响 `sp`。


### 练习2：完善中断处理 （需要编程）

##### 中断处理流程

1. 在trap.c中执行kern_init()执行idt_init()创建中断向量
2. 执行clock_init()初始化时钟
3. 执行intr_enable()开中断,通过以下函数

```
/* intr_enable - enable irq interrupt, 设置sstatus的Supervisor中断使能位 */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
```

在idt_init中进行了sscratch寄存器设置，初始化，并且将中断处理程序地址放入stvec，之后能直接找到中断处理程序入口

```
void idt_init(void) {
    extern void __alltraps(void);
    //约定：若中断前处于S态，sscratch为0
    //若中断前处于U态，sscratch存储内核栈地址
    //那么之后就可以通过sscratch的数值判断是内核态产生的中断还是用户态产生的中断
    //我们现在是内核态所以给sscratch置零
    write_csr(sscratch, 0);
    //我们保证__alltraps的地址是四字节对齐的，将__alltraps这个符号的地址直接写到stvec寄存器
    write_csr(stvec, &__alltraps);
}
```

trapentry.S中进行了一些宏写的汇编

```
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

上一步将这一块代码的地址放入stvec，在每次发生中断时都能够通过stvec找到中断向量表

##### 中断处理分配

根据trap结构体分别处理

```
/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) { trap_dispatch(tf); }
```

可以看到trapframe中根据cause分发给异常处理句柄和中断处理句柄

##### 时钟中断处理流程

在kern_init()执行clock_init()

1. 所以我们要在初始化的时候，使能时钟中断
2. 设置一个时钟中断事件

```
void clock_init(void) {
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}
```

sbi_call函数可以直接使用，他将调用ecall汇编进入sbi。我们可以通过 `ecall`指令(environment call)调用OpenSBI。通过寄存器传递给OpenSBI一个”调用编号“，如果编号在 `0-8` 之间，则由OpenSBI进行处理，否则交由我们自己的中断处理程序处理。

```
uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
        "mv x17, %[sbi_type]\n"
        "mv x10, %[arg0]\n"
        "mv x11, %[arg1]\n"
        "mv x12, %[arg2]\n"
        "ecall\n"
        "mv %[ret_val], x10"
        : [ret_val] "=r" (ret_val)
        : [sbi_type] "r" (sbi_type), [arg0] "r" (arg0), [arg1] "r" (arg1), [arg2] "r" (arg2)
        : "memory"
    );
    return ret_val;
}
```

对于时钟中断设置函数

```
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```

```
void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
```

OpenSBI提供的 `sbi_set_timer()`接口，可以传入一个时刻，让它在那个时刻触发一次时钟中断

```
static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
#else
    uint32_t lo, hi, tmp;
    __asm__ __volatile__(
        "1:\n"
        "rdtimeh %0\n"
        "rdtime %1\n"
        "rdtimeh %2\n"
        "bne %0, %2, 1b"
        : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
#endif
}
```

get_cycles利用rd_time获取当前时间

* `rdtime`伪指令，读取一个叫做 `time`的CSR的数值，表示CPU启动之后经过的真实时间。在不同硬件平台，时钟频率可能不同。在QEMU上，这个时钟的频率是10MHz, 每过1s, `rdtime`返回的结果增大 `10000000`

timebase被设置为100000，即0.01s，加上计数器每100次触发一次输出，就有了1s输出一次信息。

##### 实现细节

```
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   YOUR CODE :2013095  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
            ticks++;
            if(ticks==100){
                print_ticks();
                num ++;
                ticks = 0;
                if(num==10){
                    sbi_shutdown();
                }
            }
            break;
```


### 扩展练习 Challenge1：描述与理解中断流程

回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

1. 执行 `mov a0,sp`的原因是，根据RISC-V的函数调用规范，`a0~a7`寄存器用于存储函数参数。而 `trap`函数只有一个参数，是指向一个结构体的指针，所以需要将该结构体的首地址保存在寄存器 `a0`中。
2. 寄存器保存的位置是由[trapentry.S]中描述的汇编栈结构决定的，按照一定顺序保存在结构体 `trapframe`和 `pushregs`中，因为后续这些寄存器都要作为函数 `trap`的参数的具体内容。
3. 需要保存所有的寄存器。因为这些寄存器都将用于函数 `trap`参数的一部分。


### 扩增练习 Challenge2：理解上下文切换机制

回答：在trapentry.S中汇编代码 `csrw sscratch, sp；csrrw s0, sscratch, x0`实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

* `csrw sscratch, sp`：将 `sp`的值赋值给 `sscratch`
* `csrrw s0, sscratch, x0`：将 `sscratch`赋值给 `s0`，将 `sscratch`置0

使用sscratch寄存器暂存sp的值。之后会传递给s0，来保存到tf中对应位置。

将 `sscratch`置0，这样如果产生了递归异常，异常向量就会知道它来自于内核。

store的意义在于处理中断可能需要一些判断条件，而不还原那些 `csr`，是因为异常已经由 `trap`处理过了，没有必要再去还原。我们所需要的仅仅是spec返回地址，sstatus全局中断使能，将这两个csr还原即可。

### 扩展练习Challenge3：完善异常中断

编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

简单起见，我们直接在 `kernel_init`中初始化中断后直接通过 `__asm__ volatile();`生成汇编 `mret`。

```

	case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   2013095  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction caught at 0x%x\n",tf->epc);
            cprintf("Exception type:Illegal instruction\n");
            tf->epc ++;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   2013095  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("ebreak caught at 0x%x\n",tf->epc);
            cprintf("Exception type: breakpoint\n");
            tf->epc ++;
            break;
```

在处理函数中，注意输出后需要将tf值修改，否则会一直sret后回到当前的指令，连续循环触发中断无法退出。
