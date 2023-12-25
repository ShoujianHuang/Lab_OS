# Lab8实验报告


## 练习0：填写已有实验

本实验依赖实验2/3/4/5/6/7。请把你做的实验2/3/4/5/6/7的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”/“LAB5”/“LAB6” /“LAB7”的注释相应部分。并确保编译通过。注意：为了能够正确执行lab8的测试应用程序，可能需对已完成的实验2/3/4/5/6/7的代码进行进一步改进。

## 练习1: 完成读文件操作的实现（需要编码）

首先了解打开文件的处理流程，然后参考本实验后续的文件读写操作的过程分析，填写在 kern/fs/sfs/sfs_inode.c中 的sfs_io_nolock()函数，实现读文件中数据的代码。

#### 关于inode

超级块默认存在block[0]，保存了整个文件系统的相关信息，包括块数、空闲块数等。操作系统一旦无法找到超级块，就无法正常工作。

然后是root-dir，存储在block[1]，相当于树的根节点，对于具体文件的索引都从这里开始。

然后有一个类似used_list的东西从第二个块开始，占据核块总数相同的bit数来表示是不是被占用；此后开始是正常的数据部分。

### 读文件的流程

一个读写文件的流程：

- 在一个进程调用了相关的库的接口。
- 用户进程下潜到内核调用抽象层的接口。抽象层是为了方便在各种使用不同的文件系统的操作系统中移植代码而使用的一个对上层提供通用接口的层次。
- 从抽象层进入到我们这个操作系统的真正的文件系统。
- 文件系统调用硬盘io接口。

那么现在来看看细节。在内核初始化的时候现在多了个文件系统的初始化。它干了三件事：

- 初始化vfs。这里包括给引导文件系统bootfs的信号量置为1，让它能正常执行然后加载必要项。同时初始化vfs的设备列表，它的对应的信号量也置为1.
- 设备初始化，主要是将这次实验用到的stdin、stdout和磁盘disk0初始化。
- 初始化sys。这里试图把disk0挂载，使其可以被访问和操作。

#### 具体的打开文件的处理流程

1. 通用文件系统访问接口层：

用户态能做到的仍然只是调用库函数写好的open然后发起系统调用。这里陷入内核态之后将要打开的文件路径和打开方式传给sysfile_open，首先把用户空间来的路径字符串复制到内核空间（如果返回的不是0，就说明返回的是-E_INVAL表示复制失败了）复制的时候得把现在的mm的信号量减少，代表正在用这个复制字符串。在路径处理完毕后，进入file_open函数。然后调用vfs_open进入虚拟接口层。

2. vfs：在vfs_open中， 调用vfs_lookup根据传入的路径试图获得一个inode。 然后进入一个vop_lookup宏。

```c
static const struct inode_ops sfs_node_dirops = {
    .vop_magic                      = VOP_MAGIC,
    .vop_open                       = sfs_opendir,
    .vop_close                      = sfs_close,
    .vop_fstat                      = sfs_fstat,
    .vop_fsync                      = sfs_fsync,
    .vop_namefile                   = sfs_namefile,
    .vop_getdirentry                = sfs_getdirentry,
    .vop_reclaim                    = sfs_reclaim,
    .vop_gettype                    = sfs_gettype,
    .vop_lookup                     = sfs_lookup,
};
```

可以看到在文件夹、文件的inode结点被创建时，会经过类似

```c
vop_init(node, sfs_get_ops(din->type), info2fs(sfs, sfs));
```

的过程。所有的inode要么是sfs_inode，要么是device：

```c
struct inode {
    union {
        struct device __device_info;
        struct sfs_inode __sfs_inode_info;
    } in_info;
	........
};
```

接下来进入vop_open。然后把一些引用计数进行调整，同时如果需求是创建文件或者截断，那么就可以调用vop_truncate(node, 0)将文件的长度截断为0，相当于重新创建了。


3.sfs

对于vop_open函数，如果打开的是一个文件夹，那么最终会来sfs_opendir。如果打开的是一个具体的文件，那么会到sfs_openfile。

4.具体设备

如果仅仅只是找到这个文件的描述符然后把它存起来（打开文件的处理流程），在这个过程中似乎不涉及到具体设备的交互。open操作也断在了sfs里面没有下文了。具体的文件操作在读写时会详细涉及。

#### 具体的打开文件的处理流程

在syscall进入了sysfile_read。里首先file_testfd判断可行性，然后分配缓冲区。文件的需要读取长度是len，文件到每次操作为止实际读取的长度是alen。然后进入到file_read函数。先通过fd2file拿到fd索引的file（也就是我们要读取的文件）。根据读取的长度声明对应的buffer结构体之后，进入vop环节。直接跳转到sfs的sfs_read函数。从sfs_read进入sfs_io，写入位置为0，意思是正在读。接着又得到文件的信息sfs和索引节点的信息sin。对sin的信号量进行操作，防止在读时这个索引被人修改。在一切准备工作完毕后，调用sfs_io_nolock，：

```c
static int
sfs_io_nolock(struct sfs_fs *sfs, struct sfs_inode *sin, void *buf, off_t offset, size_t *alenp, bool write) {
    struct sfs_disk_inode *din = sin->din;
    assert(din->type != SFS_TYPE_DIR);
    off_t endpos = offset + *alenp, blkoff;
    *alenp = 0;
	// calculate the Rd/Wr end position
    if (offset < 0 || offset >= SFS_MAX_FILE_SIZE || offset > endpos) {
        return -E_INVAL;
    }
    if (offset == endpos) {
        return 0;
    }
    if (endpos > SFS_MAX_FILE_SIZE) {
        endpos = SFS_MAX_FILE_SIZE;
    }
    if (!write) {
        if (offset >= din->size) {
            return 0;
        }
        if (endpos > din->size) {
            endpos = din->size;
        }
    }

    int (*sfs_buf_op)(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
    int (*sfs_block_op)(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
    if (write) {
        sfs_buf_op = sfs_wbuf, sfs_block_op = sfs_wblock;
    }
    else {
        sfs_buf_op = sfs_rbuf, sfs_block_op = sfs_rblock;
    }

    int ret = 0;
    size_t size, alen = 0;
    uint32_t ino;
    uint32_t blkno = offset / SFS_BLKSIZE;          // The NO. of Rd/Wr begin block
    uint32_t nblks = endpos / SFS_BLKSIZE - blkno;  // The size of Rd/Wr blocks

 
  // (1)第一部分，用offset % SFS_BLKSIZE判断是否对齐，
  // 若没有对齐，则需要特殊处理，首先通过sfs_bmap_load_nolock找到这一块的inode，然后将这部分数据读出。
    if ((blkoff = offset % SFS_BLKSIZE) != 0) {
        size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
            goto out;
        }

        alen += size;
        buf += size;

        if (nblks == 0) {
            goto out;
        }

        blkno++;
        nblks--;
    }

    if (nblks > 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_block_op(sfs, buf, ino, nblks)) != 0) {
            goto out;
        }

        alen += nblks * SFS_BLKSIZE;
        buf += nblks * SFS_BLKSIZE;
        blkno += nblks;
        nblks -= nblks;
    }
    if ((size = endpos % SFS_BLKSIZE) != 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
            goto out;
        }
        alen += size;
    }
out:
    *alenp = alen;
    if (offset + alen > sin->din->size) {
        sin->din->size = offset + alen;
        sin->dirty = 1;
    }
    return ret;
}
```

- 1、首先进行越界判断。然后引入两个变量，blkno和nblks。
- 2、读取时，首先要对上一次读取的块是否读取完进行判断。如果offset 不能整除 SFS_BLKSIZE，则得到的余数是上一个被读取的块被读取了多少。拿SFS_BLKSIZE减去这个余数就是上一个块还剩多少需要被读取。

```c
size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
```

找到磁盘设备的初始化函数：

```c
static void
disk0_device_init(struct device *dev) {
    ......
	dev->d_io = disk0_io;
	.......
}
```

于是确定了d_io接下来要去到disk0_io。再disk0_io里，我们读文件会通过disk0_read_blks_nolock和iobuf_move的组合把数据读取到buffer里面。最终传回到sfs层。

## 练习2: 完成基于文件系统的执行程序机制的实现（需要编码）

改写proc.c中的load_icode函数和其他相关函数，实现基于文件系统的执行程序机制。执行：make qemu。如果能看看到sh用户程序的执行界面，则基本成功了。如果在sh用户界面上可以执行”ls”,”hello”等其他放置在sfs文件系统中的其他执行程序，则可以认为本实验基本成功。


更改后的alloc_proc函数如下：

```c
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
     //LAB5 YOUR CODE : (update LAB4 steps)
    /*
     * below fields(add in LAB5) in proc_struct need to be initialized
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    //LAB6 YOUR CODE : (update LAB5 steps)
    /*
     * below fields(add in LAB6) in proc_struct need to be initialized
     *     struct run_queue *rq;                       // running queue contains Process
     *     list_entry_t run_link;                      // the entry linked in run queue
     *     int time_slice;                             // time slice for occupying the CPU
     *     skew_heap_entry_t lab6_run_pool;            // FOR LAB6 ONLY: the entry in the run pool
     *     uint32_t lab6_stride;                       // FOR LAB6 ONLY: the current stride of the process
     *     uint32_t lab6_priority;                     // FOR LAB6 ONLY: the priority of process, set by lab6_set_priority(uint32_t)
     */

     //LAB8 YOUR CODE : (update LAB6 steps)
      /*
     * below fields(add in LAB6) in proc_struct need to be initialized
     *       struct files_struct * filesp;                file struct point        
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
        memset(proc->name, 0, PROC_NAME_LEN);
        proc->wait_state = 0; //PCB新增的条目，初始化进程等待状态
        proc->cptr = proc->optr = proc->yptr = NULL;//设置指针
        proc->filesp = NULL;
    }

    return proc;
}
```

然后就是要实现 `load_icode` 函数，实现后的函数如下所示：

```c
// load_icode -  called by sys_exec-->do_execve
static int
load_icode(int fd, int argc, char **kargv) {
    /* LAB8:EXERCISE2 YOUR CODE  HINT:how to load the file with handler fd  in to process's memory? how to setup argc/argv?
     * MACROs or Functions:
     *  mm_create        - create a mm
     *  setup_pgdir      - setup pgdir in mm
     *  load_icode_read  - read raw data content of program file
     *  mm_map           - build new vma
     *  pgdir_alloc_page - allocate new memory for  TEXT/DATA/BSS/stack parts
     *  lcr3             - update Page Directory Addr Register -- CR3
     */
  /* (1) create a new mm for current process
     * (2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
     * (3) copy TEXT/DATA/BSS parts in binary to memory space of process
     *    (3.1) read raw data content in file and resolve elfhdr
     *    (3.2) read raw data content in file and resolve proghdr based on info in elfhdr
     *    (3.3) call mm_map to build vma related to TEXT/DATA
     *    (3.4) callpgdir_alloc_page to allocate page for TEXT/DATA, read contents in file
     *          and copy them into the new allocated pages
     *    (3.5) callpgdir_alloc_page to allocate pages for BSS, memset zero in these pages
     * (4) call mm_map to setup user stack, and put parameters into user stack
     * (5) setup current process's mm, cr3, reset pgidr (using lcr3 MARCO)
     * (6) setup uargc and uargv in user stacks
     * (7) setup trapframe for user environment
     * (8) if up steps failed, you should cleanup the env.
     */
    assert(argc >= 0 && argc <= EXEC_MAX_ARG_NUM);
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    //(1) create a new mm for current process
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    //(2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    //(3) copy TEXT/DATA section, build BSS parts in binary to memory space of process
    struct Page *page;
    //(3.1) get the file header of the bianry program (ELF format)
    struct elfhdr __elf;
    struct elfhdr *elf = &__elf;
    if((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0)
        goto bad_elf_cleanup_pgdir;
    // struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    //struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }
    struct proghdr __ph, *ph = &__ph;
    uint32_t vm_flags, perm, phnum;
    for (phnum = 0; phnum < elf->e_phnum; phnum ++) {
        off_t phoff = elf->e_phoff + sizeof(struct proghdr) * phnum;
        if ((ret = load_icode_read(fd, ph, sizeof(struct proghdr), phoff)) != 0) {
            goto bad_cleanup_mmap;
        }
        //(3.4) find every program section headers
        if (ph->p_type != ELF_PT_LOAD) {
            continue ;
        }
        if (ph->p_filesz > ph->p_memsz) {
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        if (ph->p_filesz == 0) {
            continue ;
            // do nothing here since static variables may not occupy any space
        }
        //(3.5) call mm_map fun to setup the new vma ( ph->p_va, ph->p_memsz)
        vm_flags = 0, perm = PTE_U | PTE_V;
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
        // modify the perm bits here for RISC-V
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
            goto bad_cleanup_mmap;
        }
        off_t offset = ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

        //(3.6) alloc memory, and  copy the contents of every program section (from, from+end) to process's memory (la, la+end)
        end = ph->p_va + ph->p_filesz;
        //(3.6.1) copy TEXT/DATA section of bianry program
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                ret = -E_NO_MEM;
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            if ((ret = load_icode_read(fd, page2kva(page) + off, size, offset)) != 0) {
                goto bad_cleanup_mmap;
            }
            start += size, offset += size;
        }
        //(3.6.2) build BSS section of binary program
        end = ph->p_va + ph->p_memsz;

        if (start < la) {
            /* ph->p_memsz == ph->p_filesz */
            if (start == end) {
                continue ;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                ret = -E_NO_MEM;
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }
    //(4) build user stack memory
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
    //(5) set current process's mm, sr3, and set CR3 reg = physical addr of Page Directory
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));

    //(6) setup trapframe for user environment
    uint32_t argv_size=0, i;
    for (i = 0; i < argc; i ++) {
        argv_size += strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }

    uintptr_t stacktop = USTACKTOP - (argv_size/sizeof(long)+1)*sizeof(long);
    char** uargv=(char **)(stacktop  - argc * sizeof(char *));
    
    argv_size = 0;
    for (i = 0; i < argc; i ++) {
        uargv[i] = strcpy((char *)(stacktop + argv_size ), kargv[i]);
        argv_size +=  strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }
    
    stacktop = (uintptr_t)uargv - sizeof(int);
    *(int *)stacktop = argc;
    
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
     /* LAB5:EXERCISE1 2111805黄守建
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */
    tf->gpr.sp=stacktop;
    //tf->gpr.sp = USTACKTOP; // 设置tf->gpr.sp为用户栈的顶部地址
    tf->epc = elf->e_entry; // 设置tf->epc为用户程序的入口地址
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE); // 根据需要设置 tf->status 的值，清除 SSTATUS_SPP 和 SSTATUS_SPIE 位
    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}
```

load_icode 主要是将文件加载到内存中执行，具体步骤如下：

- 1、建立内存管理器，创建一个新的mm（内存管理）结构体来管理当前进程的内存。
- 2、建立页目录，创建一个新的页目录表（PDT），并将mm的pgdir字段设置为页目录表的内核虚拟地址。
- 3、将程序文件的TEXT（代码）、DATA（数据）和BSS（未初始化数据）部分复制到进程的内存空间中：
  
  - 读取程序文件的原始数据内容，并解析ELF头部信息。
  - 根据ELF头部信息，在程序文件中读取原始数据内容，并根据ELF头部中的程序头部信息进行解析。
  - 调用mm_map函数来创建与TEXT和DATA相关的虚拟内存区域（VMA）。
  - 调用pgdir_alloc_page函数为TEXT和DATA部分分配内存页面，并将文件内容复制到新分配的页面中。
  - 调用pgdir_alloc_page函数为BSS部分分配内存页面，并将页面中的内容清零。
- 4、调用mm_map函数设置用户栈，并将参数放入用户栈中，建立并初始化用户堆栈
- 5、设置当前进程的mm结构、页目录表（使用lcr3宏定义）。
- 6、在用户栈中设置uargc和uargv参数，并且处理用户栈中传入的参数，
- 7、最后是设置用户进程的中断帧（trapframe）。
- 8、如果在上述步骤中出现错误，需要清理环境。

#### 加载ELF文件与lab5的不同：

lab5中使用的方法是直接获取ELF文件在内存当中的·位置；这里则是通过fd文件描述符对其进行加载，具体使用了load_icode_read函数。


```c
//lab5中
    //(3.1) get the file header of the bianry program (ELF format)
    struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

//lab8中
    //(3.1) get the file header of the bianry program (ELF format)
    struct elfhdr __elf;
    struct elfhdr *elf = &__elf;
    if((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0)
        goto bad_elf_cleanup_pgdir;
    // struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    //struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }
    struct proghdr __ph, *ph = &__ph;
    uint32_t vm_flags, perm, phnum;
```

上面仅展示了一部分，`load_icode_read`应用第三步里各个对在进行硬盘文件读取部分，涉及到读取就要把原来的代码改成调用它。

此外，加入了任意大小参数`argc`和`argv`的功能，使得应用程序能够接受命令行参数输入，这部分改动加在第六步，具体如下：

```c
uint32_t argv_size=0, i;
    for (i = 0; i < argc; i ++) {
        argv_size += strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }

    uintptr_t stacktop = USTACKTOP - (argv_size/sizeof(long)+1)*sizeof(long);
    char** uargv=(char **)(stacktop  - argc * sizeof(char *));
    
    argv_size = 0;
    for (i = 0; i < argc; i ++) {
        uargv[i] = strcpy((char *)(stacktop + argv_size ), kargv[i]);
        argv_size +=  strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }
    
    stacktop = (uintptr_t)uargv - sizeof(int);
    *(int *)stacktop = argc;
```



