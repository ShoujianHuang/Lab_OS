
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	43260613          	addi	a2,a2,1074 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	5d2010ef          	jal	ra,ffffffffc0201620 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	aea50513          	addi	a0,a0,-1302 # ffffffffc0201b40 <etext+0x2>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	13c000ef          	jal	ra,ffffffffc020019e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	0f7000ef          	jal	ra,ffffffffc0200960 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	5f4010ef          	jal	ra,ffffffffc020169e <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	5c0010ef          	jal	ra,ffffffffc020169e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020013e:	00006317          	auipc	t1,0x6
ffffffffc0200142:	2d230313          	addi	t1,t1,722 # ffffffffc0206410 <is_panic>
ffffffffc0200146:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020014a:	715d                	addi	sp,sp,-80
ffffffffc020014c:	ec06                	sd	ra,24(sp)
ffffffffc020014e:	e822                	sd	s0,16(sp)
ffffffffc0200150:	f436                	sd	a3,40(sp)
ffffffffc0200152:	f83a                	sd	a4,48(sp)
ffffffffc0200154:	fc3e                	sd	a5,56(sp)
ffffffffc0200156:	e0c2                	sd	a6,64(sp)
ffffffffc0200158:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020015a:	02031c63          	bnez	t1,ffffffffc0200192 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020015e:	4785                	li	a5,1
ffffffffc0200160:	8432                	mv	s0,a2
ffffffffc0200162:	00006717          	auipc	a4,0x6
ffffffffc0200166:	2af72723          	sw	a5,686(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020016a:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc020016c:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020016e:	85aa                	mv	a1,a0
ffffffffc0200170:	00002517          	auipc	a0,0x2
ffffffffc0200174:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201b60 <etext+0x22>
    va_start(ap, fmt);
ffffffffc0200178:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020017a:	f3dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020017e:	65a2                	ld	a1,8(sp)
ffffffffc0200180:	8522                	mv	a0,s0
ffffffffc0200182:	f15ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	af250513          	addi	a0,a0,-1294 # ffffffffc0201c78 <etext+0x13a>
ffffffffc020018e:	f29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200192:	2d2000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200196:	4501                	li	a0,0
ffffffffc0200198:	132000ef          	jal	ra,ffffffffc02002ca <kmonitor>
ffffffffc020019c:	bfed                	j	ffffffffc0200196 <__panic+0x58>

ffffffffc020019e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020019e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	a1050513          	addi	a0,a0,-1520 # ffffffffc0201bb0 <etext+0x72>
void print_kerninfo(void) {
ffffffffc02001a8:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001aa:	f0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001ae:	00000597          	auipc	a1,0x0
ffffffffc02001b2:	e8858593          	addi	a1,a1,-376 # ffffffffc0200036 <kern_init>
ffffffffc02001b6:	00002517          	auipc	a0,0x2
ffffffffc02001ba:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0201bd0 <etext+0x92>
ffffffffc02001be:	ef9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001c2:	00002597          	auipc	a1,0x2
ffffffffc02001c6:	97c58593          	addi	a1,a1,-1668 # ffffffffc0201b3e <etext>
ffffffffc02001ca:	00002517          	auipc	a0,0x2
ffffffffc02001ce:	a2650513          	addi	a0,a0,-1498 # ffffffffc0201bf0 <etext+0xb2>
ffffffffc02001d2:	ee5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001d6:	00006597          	auipc	a1,0x6
ffffffffc02001da:	e3a58593          	addi	a1,a1,-454 # ffffffffc0206010 <edata>
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	a3250513          	addi	a0,a0,-1486 # ffffffffc0201c10 <etext+0xd2>
ffffffffc02001e6:	ed1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ea:	00006597          	auipc	a1,0x6
ffffffffc02001ee:	28658593          	addi	a1,a1,646 # ffffffffc0206470 <end>
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0201c30 <etext+0xf2>
ffffffffc02001fa:	ebdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001fe:	00006597          	auipc	a1,0x6
ffffffffc0200202:	67158593          	addi	a1,a1,1649 # ffffffffc020686f <end+0x3ff>
ffffffffc0200206:	00000797          	auipc	a5,0x0
ffffffffc020020a:	e3078793          	addi	a5,a5,-464 # ffffffffc0200036 <kern_init>
ffffffffc020020e:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200212:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200218:	3ff5f593          	andi	a1,a1,1023
ffffffffc020021c:	95be                	add	a1,a1,a5
ffffffffc020021e:	85a9                	srai	a1,a1,0xa
ffffffffc0200220:	00002517          	auipc	a0,0x2
ffffffffc0200224:	a3050513          	addi	a0,a0,-1488 # ffffffffc0201c50 <etext+0x112>
}
ffffffffc0200228:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020022a:	e8dff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020022e <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020022e:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200230:	00002617          	auipc	a2,0x2
ffffffffc0200234:	95060613          	addi	a2,a2,-1712 # ffffffffc0201b80 <etext+0x42>
ffffffffc0200238:	04e00593          	li	a1,78
ffffffffc020023c:	00002517          	auipc	a0,0x2
ffffffffc0200240:	95c50513          	addi	a0,a0,-1700 # ffffffffc0201b98 <etext+0x5a>
void print_stackframe(void) {
ffffffffc0200244:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200246:	ef9ff0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc020024a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	b1460613          	addi	a2,a2,-1260 # ffffffffc0201d60 <commands+0xe0>
ffffffffc0200254:	00002597          	auipc	a1,0x2
ffffffffc0200258:	b2c58593          	addi	a1,a1,-1236 # ffffffffc0201d80 <commands+0x100>
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0201d88 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200264:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200266:	e51ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020026a:	00002617          	auipc	a2,0x2
ffffffffc020026e:	b2e60613          	addi	a2,a2,-1234 # ffffffffc0201d98 <commands+0x118>
ffffffffc0200272:	00002597          	auipc	a1,0x2
ffffffffc0200276:	b4e58593          	addi	a1,a1,-1202 # ffffffffc0201dc0 <commands+0x140>
ffffffffc020027a:	00002517          	auipc	a0,0x2
ffffffffc020027e:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0201d88 <commands+0x108>
ffffffffc0200282:	e35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0201dd0 <commands+0x150>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	b6258593          	addi	a1,a1,-1182 # ffffffffc0201df0 <commands+0x170>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	af250513          	addi	a0,a0,-1294 # ffffffffc0201d88 <commands+0x108>
ffffffffc020029e:	e19ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc02002a2:	60a2                	ld	ra,8(sp)
ffffffffc02002a4:	4501                	li	a0,0
ffffffffc02002a6:	0141                	addi	sp,sp,16
ffffffffc02002a8:	8082                	ret

ffffffffc02002aa <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002aa:	1141                	addi	sp,sp,-16
ffffffffc02002ac:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ae:	ef1ff0ef          	jal	ra,ffffffffc020019e <print_kerninfo>
    return 0;
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
ffffffffc02002b4:	4501                	li	a0,0
ffffffffc02002b6:	0141                	addi	sp,sp,16
ffffffffc02002b8:	8082                	ret

ffffffffc02002ba <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ba:	1141                	addi	sp,sp,-16
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002be:	f71ff0ef          	jal	ra,ffffffffc020022e <print_stackframe>
    return 0;
}
ffffffffc02002c2:	60a2                	ld	ra,8(sp)
ffffffffc02002c4:	4501                	li	a0,0
ffffffffc02002c6:	0141                	addi	sp,sp,16
ffffffffc02002c8:	8082                	ret

ffffffffc02002ca <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002ca:	7115                	addi	sp,sp,-224
ffffffffc02002cc:	e962                	sd	s8,144(sp)
ffffffffc02002ce:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d0:	00002517          	auipc	a0,0x2
ffffffffc02002d4:	9f850513          	addi	a0,a0,-1544 # ffffffffc0201cc8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02002d8:	ed86                	sd	ra,216(sp)
ffffffffc02002da:	e9a2                	sd	s0,208(sp)
ffffffffc02002dc:	e5a6                	sd	s1,200(sp)
ffffffffc02002de:	e1ca                	sd	s2,192(sp)
ffffffffc02002e0:	fd4e                	sd	s3,184(sp)
ffffffffc02002e2:	f952                	sd	s4,176(sp)
ffffffffc02002e4:	f556                	sd	s5,168(sp)
ffffffffc02002e6:	f15a                	sd	s6,160(sp)
ffffffffc02002e8:	ed5e                	sd	s7,152(sp)
ffffffffc02002ea:	e566                	sd	s9,136(sp)
ffffffffc02002ec:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ee:	dc9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002f2:	00002517          	auipc	a0,0x2
ffffffffc02002f6:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0201cf0 <commands+0x70>
ffffffffc02002fa:	dbdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc02002fe:	000c0563          	beqz	s8,ffffffffc0200308 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200302:	8562                	mv	a0,s8
ffffffffc0200304:	346000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc0200308:	00002c97          	auipc	s9,0x2
ffffffffc020030c:	978c8c93          	addi	s9,s9,-1672 # ffffffffc0201c80 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200310:	00002997          	auipc	s3,0x2
ffffffffc0200314:	a0898993          	addi	s3,s3,-1528 # ffffffffc0201d18 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200318:	00002917          	auipc	s2,0x2
ffffffffc020031c:	a0890913          	addi	s2,s2,-1528 # ffffffffc0201d20 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200320:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200322:	00002b17          	auipc	s6,0x2
ffffffffc0200326:	a06b0b13          	addi	s6,s6,-1530 # ffffffffc0201d28 <commands+0xa8>
    if (argc == 0) {
ffffffffc020032a:	00002a97          	auipc	s5,0x2
ffffffffc020032e:	a56a8a93          	addi	s5,s5,-1450 # ffffffffc0201d80 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200332:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200334:	854e                	mv	a0,s3
ffffffffc0200336:	6f4010ef          	jal	ra,ffffffffc0201a2a <readline>
ffffffffc020033a:	842a                	mv	s0,a0
ffffffffc020033c:	dd65                	beqz	a0,ffffffffc0200334 <kmonitor+0x6a>
ffffffffc020033e:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200342:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	c999                	beqz	a1,ffffffffc020035a <kmonitor+0x90>
ffffffffc0200346:	854a                	mv	a0,s2
ffffffffc0200348:	2ba010ef          	jal	ra,ffffffffc0201602 <strchr>
ffffffffc020034c:	c925                	beqz	a0,ffffffffc02003bc <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc020034e:	00144583          	lbu	a1,1(s0)
ffffffffc0200352:	00040023          	sb	zero,0(s0)
ffffffffc0200356:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200358:	f5fd                	bnez	a1,ffffffffc0200346 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc020035a:	dce9                	beqz	s1,ffffffffc0200334 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020035c:	6582                	ld	a1,0(sp)
ffffffffc020035e:	00002d17          	auipc	s10,0x2
ffffffffc0200362:	922d0d13          	addi	s10,s10,-1758 # ffffffffc0201c80 <commands>
    if (argc == 0) {
ffffffffc0200366:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200368:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020036a:	0d61                	addi	s10,s10,24
ffffffffc020036c:	26c010ef          	jal	ra,ffffffffc02015d8 <strcmp>
ffffffffc0200370:	c919                	beqz	a0,ffffffffc0200386 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200372:	2405                	addiw	s0,s0,1
ffffffffc0200374:	09740463          	beq	s0,s7,ffffffffc02003fc <kmonitor+0x132>
ffffffffc0200378:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020037c:	6582                	ld	a1,0(sp)
ffffffffc020037e:	0d61                	addi	s10,s10,24
ffffffffc0200380:	258010ef          	jal	ra,ffffffffc02015d8 <strcmp>
ffffffffc0200384:	f57d                	bnez	a0,ffffffffc0200372 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200386:	00141793          	slli	a5,s0,0x1
ffffffffc020038a:	97a2                	add	a5,a5,s0
ffffffffc020038c:	078e                	slli	a5,a5,0x3
ffffffffc020038e:	97e6                	add	a5,a5,s9
ffffffffc0200390:	6b9c                	ld	a5,16(a5)
ffffffffc0200392:	8662                	mv	a2,s8
ffffffffc0200394:	002c                	addi	a1,sp,8
ffffffffc0200396:	fff4851b          	addiw	a0,s1,-1
ffffffffc020039a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020039c:	f8055ce3          	bgez	a0,ffffffffc0200334 <kmonitor+0x6a>
}
ffffffffc02003a0:	60ee                	ld	ra,216(sp)
ffffffffc02003a2:	644e                	ld	s0,208(sp)
ffffffffc02003a4:	64ae                	ld	s1,200(sp)
ffffffffc02003a6:	690e                	ld	s2,192(sp)
ffffffffc02003a8:	79ea                	ld	s3,184(sp)
ffffffffc02003aa:	7a4a                	ld	s4,176(sp)
ffffffffc02003ac:	7aaa                	ld	s5,168(sp)
ffffffffc02003ae:	7b0a                	ld	s6,160(sp)
ffffffffc02003b0:	6bea                	ld	s7,152(sp)
ffffffffc02003b2:	6c4a                	ld	s8,144(sp)
ffffffffc02003b4:	6caa                	ld	s9,136(sp)
ffffffffc02003b6:	6d0a                	ld	s10,128(sp)
ffffffffc02003b8:	612d                	addi	sp,sp,224
ffffffffc02003ba:	8082                	ret
        if (*buf == '\0') {
ffffffffc02003bc:	00044783          	lbu	a5,0(s0)
ffffffffc02003c0:	dfc9                	beqz	a5,ffffffffc020035a <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc02003c2:	03448863          	beq	s1,s4,ffffffffc02003f2 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc02003c6:	00349793          	slli	a5,s1,0x3
ffffffffc02003ca:	0118                	addi	a4,sp,128
ffffffffc02003cc:	97ba                	add	a5,a5,a4
ffffffffc02003ce:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d2:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003d6:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d8:	e591                	bnez	a1,ffffffffc02003e4 <kmonitor+0x11a>
ffffffffc02003da:	b749                	j	ffffffffc020035c <kmonitor+0x92>
            buf ++;
ffffffffc02003dc:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003de:	00044583          	lbu	a1,0(s0)
ffffffffc02003e2:	ddad                	beqz	a1,ffffffffc020035c <kmonitor+0x92>
ffffffffc02003e4:	854a                	mv	a0,s2
ffffffffc02003e6:	21c010ef          	jal	ra,ffffffffc0201602 <strchr>
ffffffffc02003ea:	d96d                	beqz	a0,ffffffffc02003dc <kmonitor+0x112>
ffffffffc02003ec:	00044583          	lbu	a1,0(s0)
ffffffffc02003f0:	bf91                	j	ffffffffc0200344 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003f2:	45c1                	li	a1,16
ffffffffc02003f4:	855a                	mv	a0,s6
ffffffffc02003f6:	cc1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc02003fa:	b7f1                	j	ffffffffc02003c6 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003fc:	6582                	ld	a1,0(sp)
ffffffffc02003fe:	00002517          	auipc	a0,0x2
ffffffffc0200402:	94a50513          	addi	a0,a0,-1718 # ffffffffc0201d48 <commands+0xc8>
ffffffffc0200406:	cb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc020040a:	b72d                	j	ffffffffc0200334 <kmonitor+0x6a>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	6e0010ef          	jal	ra,ffffffffc0201b04 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007b323          	sd	zero,6(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0201e00 <commands+0x180>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	6b80106f          	j	ffffffffc0201b04 <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	6920106f          	j	ffffffffc0201ae8 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	6c60106f          	j	ffffffffc0201b20 <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	37278793          	addi	a5,a5,882 # ffffffffc02007e0 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0201fa0 <commands+0x320>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	b2450513          	addi	a0,a0,-1244 # ffffffffc0201fb8 <commands+0x338>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0201fd0 <commands+0x350>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	b3850513          	addi	a0,a0,-1224 # ffffffffc0201fe8 <commands+0x368>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	b4250513          	addi	a0,a0,-1214 # ffffffffc0202000 <commands+0x380>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0202018 <commands+0x398>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202030 <commands+0x3b0>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	b6050513          	addi	a0,a0,-1184 # ffffffffc0202048 <commands+0x3c8>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202060 <commands+0x3e0>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	b7450513          	addi	a0,a0,-1164 # ffffffffc0202078 <commands+0x3f8>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0202090 <commands+0x410>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	b8850513          	addi	a0,a0,-1144 # ffffffffc02020a8 <commands+0x428>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	b9250513          	addi	a0,a0,-1134 # ffffffffc02020c0 <commands+0x440>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02020d8 <commands+0x458>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	ba650513          	addi	a0,a0,-1114 # ffffffffc02020f0 <commands+0x470>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	bb050513          	addi	a0,a0,-1104 # ffffffffc0202108 <commands+0x488>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	bba50513          	addi	a0,a0,-1094 # ffffffffc0202120 <commands+0x4a0>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202138 <commands+0x4b8>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202150 <commands+0x4d0>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202168 <commands+0x4e8>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	be250513          	addi	a0,a0,-1054 # ffffffffc0202180 <commands+0x500>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202198 <commands+0x518>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	bf650513          	addi	a0,a0,-1034 # ffffffffc02021b0 <commands+0x530>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	c0050513          	addi	a0,a0,-1024 # ffffffffc02021c8 <commands+0x548>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02021e0 <commands+0x560>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	c1450513          	addi	a0,a0,-1004 # ffffffffc02021f8 <commands+0x578>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	c1e50513          	addi	a0,a0,-994 # ffffffffc0202210 <commands+0x590>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	c2850513          	addi	a0,a0,-984 # ffffffffc0202228 <commands+0x5a8>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	c3250513          	addi	a0,a0,-974 # ffffffffc0202240 <commands+0x5c0>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202258 <commands+0x5d8>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	c4650513          	addi	a0,a0,-954 # ffffffffc0202270 <commands+0x5f0>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202288 <commands+0x608>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	c4e50513          	addi	a0,a0,-946 # ffffffffc02022a0 <commands+0x620>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	c4e50513          	addi	a0,a0,-946 # ffffffffc02022b8 <commands+0x638>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	c5650513          	addi	a0,a0,-938 # ffffffffc02022d0 <commands+0x650>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02022e8 <commands+0x668>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	c6250513          	addi	a0,a0,-926 # ffffffffc0202300 <commands+0x680>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76563          	bltu	a4,a5,ffffffffc0200742 <interrupt_handler+0x96>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	76070713          	addi	a4,a4,1888 # ffffffffc0201e1c <commands+0x19c>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00002517          	auipc	a0,0x2
ffffffffc02006d2:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201f38 <commands+0x2b8>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	83e50513          	addi	a0,a0,-1986 # ffffffffc0201f18 <commands+0x298>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	7f250513          	addi	a0,a0,2034 # ffffffffc0201ed8 <commands+0x258>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	86650513          	addi	a0,a0,-1946 # ffffffffc0201f58 <commands+0x2d8>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200702:	d3fff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200706:	00006797          	auipc	a5,0x6
ffffffffc020070a:	d2a78793          	addi	a5,a5,-726 # ffffffffc0206430 <ticks>
ffffffffc020070e:	639c                	ld	a5,0(a5)
ffffffffc0200710:	06400713          	li	a4,100
ffffffffc0200714:	0785                	addi	a5,a5,1
ffffffffc0200716:	02e7f733          	remu	a4,a5,a4
ffffffffc020071a:	00006697          	auipc	a3,0x6
ffffffffc020071e:	d0f6bb23          	sd	a5,-746(a3) # ffffffffc0206430 <ticks>
ffffffffc0200722:	c315                	beqz	a4,ffffffffc0200746 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200724:	60a2                	ld	ra,8(sp)
ffffffffc0200726:	0141                	addi	sp,sp,16
ffffffffc0200728:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020072a:	00002517          	auipc	a0,0x2
ffffffffc020072e:	85650513          	addi	a0,a0,-1962 # ffffffffc0201f80 <commands+0x300>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	7c250513          	addi	a0,a0,1986 # ffffffffc0201ef8 <commands+0x278>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00002517          	auipc	a0,0x2
ffffffffc0200750:	82450513          	addi	a0,a0,-2012 # ffffffffc0201f70 <commands+0x2f0>
}
ffffffffc0200754:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200756:	961ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020075a <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc020075a:	11853783          	ld	a5,280(a0)
ffffffffc020075e:	472d                	li	a4,11
ffffffffc0200760:	02f76563          	bltu	a4,a5,ffffffffc020078a <exception_handler+0x30>
ffffffffc0200764:	4705                	li	a4,1
ffffffffc0200766:	00f71733          	sll	a4,a4,a5
ffffffffc020076a:	6785                	lui	a5,0x1
ffffffffc020076c:	17cd                	addi	a5,a5,-13
ffffffffc020076e:	8ff9                	and	a5,a5,a4
ffffffffc0200770:	ef81                	bnez	a5,ffffffffc0200788 <exception_handler+0x2e>
void exception_handler(struct trapframe *tf) {
ffffffffc0200772:	1141                	addi	sp,sp,-16
ffffffffc0200774:	e406                	sd	ra,8(sp)
ffffffffc0200776:	00877793          	andi	a5,a4,8
ffffffffc020077a:	eb95                	bnez	a5,ffffffffc02007ae <exception_handler+0x54>
ffffffffc020077c:	8b11                	andi	a4,a4,4
ffffffffc020077e:	eb01                	bnez	a4,ffffffffc020078e <exception_handler+0x34>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200780:	60a2                	ld	ra,8(sp)
ffffffffc0200782:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200784:	ec7ff06f          	j	ffffffffc020064a <print_trapframe>
ffffffffc0200788:	8082                	ret
ffffffffc020078a:	ec1ff06f          	j	ffffffffc020064a <print_trapframe>
            cprintf("Illegal instruction caught at %x\n",tf->epc);
ffffffffc020078e:	10853583          	ld	a1,264(a0)
ffffffffc0200792:	00001517          	auipc	a0,0x1
ffffffffc0200796:	6be50513          	addi	a0,a0,1726 # ffffffffc0201e50 <commands+0x1d0>
ffffffffc020079a:	91dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
}
ffffffffc020079e:	60a2                	ld	ra,8(sp)
            cprintf("Exception type:Illegal instruction");
ffffffffc02007a0:	00001517          	auipc	a0,0x1
ffffffffc02007a4:	6d850513          	addi	a0,a0,1752 # ffffffffc0201e78 <commands+0x1f8>
}
ffffffffc02007a8:	0141                	addi	sp,sp,16
            cprintf("Exception type:Illegal instruction");
ffffffffc02007aa:	90dff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("ebreak caught at %x\n",tf->epc);
ffffffffc02007ae:	10853583          	ld	a1,264(a0)
ffffffffc02007b2:	00001517          	auipc	a0,0x1
ffffffffc02007b6:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201ea0 <commands+0x220>
ffffffffc02007ba:	8fdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
}
ffffffffc02007be:	60a2                	ld	ra,8(sp)
            cprintf("Exception type: breakpoint");
ffffffffc02007c0:	00001517          	auipc	a0,0x1
ffffffffc02007c4:	6f850513          	addi	a0,a0,1784 # ffffffffc0201eb8 <commands+0x238>
}
ffffffffc02007c8:	0141                	addi	sp,sp,16
            cprintf("Exception type: breakpoint");
ffffffffc02007ca:	8edff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02007ce <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc02007ce:	11853783          	ld	a5,280(a0)
ffffffffc02007d2:	0007c463          	bltz	a5,ffffffffc02007da <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02007d6:	f85ff06f          	j	ffffffffc020075a <exception_handler>
        interrupt_handler(tf);
ffffffffc02007da:	ed3ff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc02007e0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007e0:	14011073          	csrw	sscratch,sp
ffffffffc02007e4:	712d                	addi	sp,sp,-288
ffffffffc02007e6:	e002                	sd	zero,0(sp)
ffffffffc02007e8:	e406                	sd	ra,8(sp)
ffffffffc02007ea:	ec0e                	sd	gp,24(sp)
ffffffffc02007ec:	f012                	sd	tp,32(sp)
ffffffffc02007ee:	f416                	sd	t0,40(sp)
ffffffffc02007f0:	f81a                	sd	t1,48(sp)
ffffffffc02007f2:	fc1e                	sd	t2,56(sp)
ffffffffc02007f4:	e0a2                	sd	s0,64(sp)
ffffffffc02007f6:	e4a6                	sd	s1,72(sp)
ffffffffc02007f8:	e8aa                	sd	a0,80(sp)
ffffffffc02007fa:	ecae                	sd	a1,88(sp)
ffffffffc02007fc:	f0b2                	sd	a2,96(sp)
ffffffffc02007fe:	f4b6                	sd	a3,104(sp)
ffffffffc0200800:	f8ba                	sd	a4,112(sp)
ffffffffc0200802:	fcbe                	sd	a5,120(sp)
ffffffffc0200804:	e142                	sd	a6,128(sp)
ffffffffc0200806:	e546                	sd	a7,136(sp)
ffffffffc0200808:	e94a                	sd	s2,144(sp)
ffffffffc020080a:	ed4e                	sd	s3,152(sp)
ffffffffc020080c:	f152                	sd	s4,160(sp)
ffffffffc020080e:	f556                	sd	s5,168(sp)
ffffffffc0200810:	f95a                	sd	s6,176(sp)
ffffffffc0200812:	fd5e                	sd	s7,184(sp)
ffffffffc0200814:	e1e2                	sd	s8,192(sp)
ffffffffc0200816:	e5e6                	sd	s9,200(sp)
ffffffffc0200818:	e9ea                	sd	s10,208(sp)
ffffffffc020081a:	edee                	sd	s11,216(sp)
ffffffffc020081c:	f1f2                	sd	t3,224(sp)
ffffffffc020081e:	f5f6                	sd	t4,232(sp)
ffffffffc0200820:	f9fa                	sd	t5,240(sp)
ffffffffc0200822:	fdfe                	sd	t6,248(sp)
ffffffffc0200824:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200828:	100024f3          	csrr	s1,sstatus
ffffffffc020082c:	14102973          	csrr	s2,sepc
ffffffffc0200830:	143029f3          	csrr	s3,stval
ffffffffc0200834:	14202a73          	csrr	s4,scause
ffffffffc0200838:	e822                	sd	s0,16(sp)
ffffffffc020083a:	e226                	sd	s1,256(sp)
ffffffffc020083c:	e64a                	sd	s2,264(sp)
ffffffffc020083e:	ea4e                	sd	s3,272(sp)
ffffffffc0200840:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200842:	850a                	mv	a0,sp
    jal trap
ffffffffc0200844:	f8bff0ef          	jal	ra,ffffffffc02007ce <trap>

ffffffffc0200848 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200848:	6492                	ld	s1,256(sp)
ffffffffc020084a:	6932                	ld	s2,264(sp)
ffffffffc020084c:	10049073          	csrw	sstatus,s1
ffffffffc0200850:	14191073          	csrw	sepc,s2
ffffffffc0200854:	60a2                	ld	ra,8(sp)
ffffffffc0200856:	61e2                	ld	gp,24(sp)
ffffffffc0200858:	7202                	ld	tp,32(sp)
ffffffffc020085a:	72a2                	ld	t0,40(sp)
ffffffffc020085c:	7342                	ld	t1,48(sp)
ffffffffc020085e:	73e2                	ld	t2,56(sp)
ffffffffc0200860:	6406                	ld	s0,64(sp)
ffffffffc0200862:	64a6                	ld	s1,72(sp)
ffffffffc0200864:	6546                	ld	a0,80(sp)
ffffffffc0200866:	65e6                	ld	a1,88(sp)
ffffffffc0200868:	7606                	ld	a2,96(sp)
ffffffffc020086a:	76a6                	ld	a3,104(sp)
ffffffffc020086c:	7746                	ld	a4,112(sp)
ffffffffc020086e:	77e6                	ld	a5,120(sp)
ffffffffc0200870:	680a                	ld	a6,128(sp)
ffffffffc0200872:	68aa                	ld	a7,136(sp)
ffffffffc0200874:	694a                	ld	s2,144(sp)
ffffffffc0200876:	69ea                	ld	s3,152(sp)
ffffffffc0200878:	7a0a                	ld	s4,160(sp)
ffffffffc020087a:	7aaa                	ld	s5,168(sp)
ffffffffc020087c:	7b4a                	ld	s6,176(sp)
ffffffffc020087e:	7bea                	ld	s7,184(sp)
ffffffffc0200880:	6c0e                	ld	s8,192(sp)
ffffffffc0200882:	6cae                	ld	s9,200(sp)
ffffffffc0200884:	6d4e                	ld	s10,208(sp)
ffffffffc0200886:	6dee                	ld	s11,216(sp)
ffffffffc0200888:	7e0e                	ld	t3,224(sp)
ffffffffc020088a:	7eae                	ld	t4,232(sp)
ffffffffc020088c:	7f4e                	ld	t5,240(sp)
ffffffffc020088e:	7fee                	ld	t6,248(sp)
ffffffffc0200890:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200892:	10200073          	sret

ffffffffc0200896 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200896:	100027f3          	csrr	a5,sstatus
ffffffffc020089a:	8b89                	andi	a5,a5,2
ffffffffc020089c:	eb89                	bnez	a5,ffffffffc02008ae <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020089e:	00006797          	auipc	a5,0x6
ffffffffc02008a2:	bba78793          	addi	a5,a5,-1094 # ffffffffc0206458 <pmm_manager>
ffffffffc02008a6:	639c                	ld	a5,0(a5)
ffffffffc02008a8:	0187b303          	ld	t1,24(a5)
ffffffffc02008ac:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc02008ae:	1141                	addi	sp,sp,-16
ffffffffc02008b0:	e406                	sd	ra,8(sp)
ffffffffc02008b2:	e022                	sd	s0,0(sp)
ffffffffc02008b4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02008b6:	bafff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02008ba:	00006797          	auipc	a5,0x6
ffffffffc02008be:	b9e78793          	addi	a5,a5,-1122 # ffffffffc0206458 <pmm_manager>
ffffffffc02008c2:	639c                	ld	a5,0(a5)
ffffffffc02008c4:	8522                	mv	a0,s0
ffffffffc02008c6:	6f9c                	ld	a5,24(a5)
ffffffffc02008c8:	9782                	jalr	a5
ffffffffc02008ca:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02008cc:	b93ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02008d0:	8522                	mv	a0,s0
ffffffffc02008d2:	60a2                	ld	ra,8(sp)
ffffffffc02008d4:	6402                	ld	s0,0(sp)
ffffffffc02008d6:	0141                	addi	sp,sp,16
ffffffffc02008d8:	8082                	ret

ffffffffc02008da <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008da:	100027f3          	csrr	a5,sstatus
ffffffffc02008de:	8b89                	andi	a5,a5,2
ffffffffc02008e0:	eb89                	bnez	a5,ffffffffc02008f2 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02008e2:	00006797          	auipc	a5,0x6
ffffffffc02008e6:	b7678793          	addi	a5,a5,-1162 # ffffffffc0206458 <pmm_manager>
ffffffffc02008ea:	639c                	ld	a5,0(a5)
ffffffffc02008ec:	0207b303          	ld	t1,32(a5)
ffffffffc02008f0:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc02008f2:	1101                	addi	sp,sp,-32
ffffffffc02008f4:	ec06                	sd	ra,24(sp)
ffffffffc02008f6:	e822                	sd	s0,16(sp)
ffffffffc02008f8:	e426                	sd	s1,8(sp)
ffffffffc02008fa:	842a                	mv	s0,a0
ffffffffc02008fc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02008fe:	b67ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200902:	00006797          	auipc	a5,0x6
ffffffffc0200906:	b5678793          	addi	a5,a5,-1194 # ffffffffc0206458 <pmm_manager>
ffffffffc020090a:	639c                	ld	a5,0(a5)
ffffffffc020090c:	85a6                	mv	a1,s1
ffffffffc020090e:	8522                	mv	a0,s0
ffffffffc0200910:	739c                	ld	a5,32(a5)
ffffffffc0200912:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200914:	6442                	ld	s0,16(sp)
ffffffffc0200916:	60e2                	ld	ra,24(sp)
ffffffffc0200918:	64a2                	ld	s1,8(sp)
ffffffffc020091a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020091c:	b43ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc0200920 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200920:	100027f3          	csrr	a5,sstatus
ffffffffc0200924:	8b89                	andi	a5,a5,2
ffffffffc0200926:	eb89                	bnez	a5,ffffffffc0200938 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200928:	00006797          	auipc	a5,0x6
ffffffffc020092c:	b3078793          	addi	a5,a5,-1232 # ffffffffc0206458 <pmm_manager>
ffffffffc0200930:	639c                	ld	a5,0(a5)
ffffffffc0200932:	0287b303          	ld	t1,40(a5)
ffffffffc0200936:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200938:	1141                	addi	sp,sp,-16
ffffffffc020093a:	e406                	sd	ra,8(sp)
ffffffffc020093c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020093e:	b27ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200942:	00006797          	auipc	a5,0x6
ffffffffc0200946:	b1678793          	addi	a5,a5,-1258 # ffffffffc0206458 <pmm_manager>
ffffffffc020094a:	639c                	ld	a5,0(a5)
ffffffffc020094c:	779c                	ld	a5,40(a5)
ffffffffc020094e:	9782                	jalr	a5
ffffffffc0200950:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200952:	b0dff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200956:	8522                	mv	a0,s0
ffffffffc0200958:	60a2                	ld	ra,8(sp)
ffffffffc020095a:	6402                	ld	s0,0(sp)
ffffffffc020095c:	0141                	addi	sp,sp,16
ffffffffc020095e:	8082                	ret

ffffffffc0200960 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200960:	00002797          	auipc	a5,0x2
ffffffffc0200964:	e1878793          	addi	a5,a5,-488 # ffffffffc0202778 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200968:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020096a:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020096c:	00002517          	auipc	a0,0x2
ffffffffc0200970:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0202318 <commands+0x698>
void pmm_init(void) {
ffffffffc0200974:	ec06                	sd	ra,24(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200976:	00006717          	auipc	a4,0x6
ffffffffc020097a:	aef73123          	sd	a5,-1310(a4) # ffffffffc0206458 <pmm_manager>
void pmm_init(void) {
ffffffffc020097e:	e822                	sd	s0,16(sp)
ffffffffc0200980:	e426                	sd	s1,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200982:	00006417          	auipc	s0,0x6
ffffffffc0200986:	ad640413          	addi	s0,s0,-1322 # ffffffffc0206458 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020098a:	f2cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc020098e:	601c                	ld	a5,0(s0)
ffffffffc0200990:	679c                	ld	a5,8(a5)
ffffffffc0200992:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200994:	57f5                	li	a5,-3
ffffffffc0200996:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	99850513          	addi	a0,a0,-1640 # ffffffffc0202330 <commands+0x6b0>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02009a0:	00006717          	auipc	a4,0x6
ffffffffc02009a4:	acf73023          	sd	a5,-1344(a4) # ffffffffc0206460 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02009a8:	f0eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02009ac:	46c5                	li	a3,17
ffffffffc02009ae:	06ee                	slli	a3,a3,0x1b
ffffffffc02009b0:	40100613          	li	a2,1025
ffffffffc02009b4:	16fd                	addi	a3,a3,-1
ffffffffc02009b6:	0656                	slli	a2,a2,0x15
ffffffffc02009b8:	07e005b7          	lui	a1,0x7e00
ffffffffc02009bc:	00002517          	auipc	a0,0x2
ffffffffc02009c0:	98c50513          	addi	a0,a0,-1652 # ffffffffc0202348 <commands+0x6c8>
ffffffffc02009c4:	ef2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02009c8:	777d                	lui	a4,0xfffff
ffffffffc02009ca:	00007797          	auipc	a5,0x7
ffffffffc02009ce:	aa578793          	addi	a5,a5,-1371 # ffffffffc020746f <end+0xfff>
ffffffffc02009d2:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02009d4:	00088737          	lui	a4,0x88
ffffffffc02009d8:	00006697          	auipc	a3,0x6
ffffffffc02009dc:	a4e6b023          	sd	a4,-1472(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02009e0:	4601                	li	a2,0
ffffffffc02009e2:	00006717          	auipc	a4,0x6
ffffffffc02009e6:	a8f73323          	sd	a5,-1402(a4) # ffffffffc0206468 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02009ea:	4681                	li	a3,0
ffffffffc02009ec:	00006897          	auipc	a7,0x6
ffffffffc02009f0:	a2c88893          	addi	a7,a7,-1492 # ffffffffc0206418 <npage>
ffffffffc02009f4:	00006597          	auipc	a1,0x6
ffffffffc02009f8:	a7458593          	addi	a1,a1,-1420 # ffffffffc0206468 <pages>
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02009fc:	4805                	li	a6,1
ffffffffc02009fe:	fff80537          	lui	a0,0xfff80
ffffffffc0200a02:	a011                	j	ffffffffc0200a06 <pmm_init+0xa6>
ffffffffc0200a04:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc0200a06:	97b2                	add	a5,a5,a2
ffffffffc0200a08:	07a1                	addi	a5,a5,8
ffffffffc0200a0a:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200a0e:	0008b703          	ld	a4,0(a7)
ffffffffc0200a12:	0685                	addi	a3,a3,1
ffffffffc0200a14:	02860613          	addi	a2,a2,40
ffffffffc0200a18:	00a707b3          	add	a5,a4,a0
ffffffffc0200a1c:	fef6e4e3          	bltu	a3,a5,ffffffffc0200a04 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200a20:	6190                	ld	a2,0(a1)
ffffffffc0200a22:	00271793          	slli	a5,a4,0x2
ffffffffc0200a26:	97ba                	add	a5,a5,a4
ffffffffc0200a28:	fec006b7          	lui	a3,0xfec00
ffffffffc0200a2c:	078e                	slli	a5,a5,0x3
ffffffffc0200a2e:	96b2                	add	a3,a3,a2
ffffffffc0200a30:	96be                	add	a3,a3,a5
ffffffffc0200a32:	c02007b7          	lui	a5,0xc0200
ffffffffc0200a36:	08f6e863          	bltu	a3,a5,ffffffffc0200ac6 <pmm_init+0x166>
ffffffffc0200a3a:	00006497          	auipc	s1,0x6
ffffffffc0200a3e:	a2648493          	addi	s1,s1,-1498 # ffffffffc0206460 <va_pa_offset>
ffffffffc0200a42:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc0200a44:	45c5                	li	a1,17
ffffffffc0200a46:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200a48:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc0200a4a:	04b6e963          	bltu	a3,a1,ffffffffc0200a9c <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200a4e:	601c                	ld	a5,0(s0)
ffffffffc0200a50:	7b9c                	ld	a5,48(a5)
ffffffffc0200a52:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200a54:	00002517          	auipc	a0,0x2
ffffffffc0200a58:	98c50513          	addi	a0,a0,-1652 # ffffffffc02023e0 <commands+0x760>
ffffffffc0200a5c:	e5aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200a60:	00004697          	auipc	a3,0x4
ffffffffc0200a64:	5a068693          	addi	a3,a3,1440 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200a68:	00006797          	auipc	a5,0x6
ffffffffc0200a6c:	9ad7bc23          	sd	a3,-1608(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a70:	c02007b7          	lui	a5,0xc0200
ffffffffc0200a74:	06f6e563          	bltu	a3,a5,ffffffffc0200ade <pmm_init+0x17e>
ffffffffc0200a78:	609c                	ld	a5,0(s1)
}
ffffffffc0200a7a:	6442                	ld	s0,16(sp)
ffffffffc0200a7c:	60e2                	ld	ra,24(sp)
ffffffffc0200a7e:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a80:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a82:	8e9d                	sub	a3,a3,a5
ffffffffc0200a84:	00006797          	auipc	a5,0x6
ffffffffc0200a88:	9cd7b623          	sd	a3,-1588(a5) # ffffffffc0206450 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a8c:	00002517          	auipc	a0,0x2
ffffffffc0200a90:	97450513          	addi	a0,a0,-1676 # ffffffffc0202400 <commands+0x780>
ffffffffc0200a94:	8636                	mv	a2,a3
}
ffffffffc0200a96:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a98:	e1eff06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200a9c:	6785                	lui	a5,0x1
ffffffffc0200a9e:	17fd                	addi	a5,a5,-1
ffffffffc0200aa0:	96be                	add	a3,a3,a5
ffffffffc0200aa2:	77fd                	lui	a5,0xfffff
ffffffffc0200aa4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200aa6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200aaa:	04e7f663          	bleu	a4,a5,ffffffffc0200af6 <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc0200aae:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200ab0:	97aa                	add	a5,a5,a0
ffffffffc0200ab2:	00279513          	slli	a0,a5,0x2
ffffffffc0200ab6:	953e                	add	a0,a0,a5
ffffffffc0200ab8:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200aba:	8d95                	sub	a1,a1,a3
ffffffffc0200abc:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200abe:	81b1                	srli	a1,a1,0xc
ffffffffc0200ac0:	9532                	add	a0,a0,a2
ffffffffc0200ac2:	9782                	jalr	a5
ffffffffc0200ac4:	b769                	j	ffffffffc0200a4e <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ac6:	00002617          	auipc	a2,0x2
ffffffffc0200aca:	8b260613          	addi	a2,a2,-1870 # ffffffffc0202378 <commands+0x6f8>
ffffffffc0200ace:	07000593          	li	a1,112
ffffffffc0200ad2:	00002517          	auipc	a0,0x2
ffffffffc0200ad6:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02023a0 <commands+0x720>
ffffffffc0200ada:	e64ff0ef          	jal	ra,ffffffffc020013e <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ade:	00002617          	auipc	a2,0x2
ffffffffc0200ae2:	89a60613          	addi	a2,a2,-1894 # ffffffffc0202378 <commands+0x6f8>
ffffffffc0200ae6:	08b00593          	li	a1,139
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	8b650513          	addi	a0,a0,-1866 # ffffffffc02023a0 <commands+0x720>
ffffffffc0200af2:	e4cff0ef          	jal	ra,ffffffffc020013e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200af6:	00002617          	auipc	a2,0x2
ffffffffc0200afa:	8ba60613          	addi	a2,a2,-1862 # ffffffffc02023b0 <commands+0x730>
ffffffffc0200afe:	06b00593          	li	a1,107
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02023d0 <commands+0x750>
ffffffffc0200b0a:	e34ff0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc0200b0e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b0e:	00006797          	auipc	a5,0x6
ffffffffc0200b12:	92a78793          	addi	a5,a5,-1750 # ffffffffc0206438 <free_area>
ffffffffc0200b16:	e79c                	sd	a5,8(a5)
ffffffffc0200b18:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b1a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b1e:	8082                	ret

ffffffffc0200b20 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b20:	00006517          	auipc	a0,0x6
ffffffffc0200b24:	92856503          	lwu	a0,-1752(a0) # ffffffffc0206448 <free_area+0x10>
ffffffffc0200b28:	8082                	ret

ffffffffc0200b2a <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200b2a:	c15d                	beqz	a0,ffffffffc0200bd0 <best_fit_alloc_pages+0xa6>
    if (n > nr_free) {
ffffffffc0200b2c:	00006617          	auipc	a2,0x6
ffffffffc0200b30:	90c60613          	addi	a2,a2,-1780 # ffffffffc0206438 <free_area>
ffffffffc0200b34:	01062803          	lw	a6,16(a2)
ffffffffc0200b38:	86aa                	mv	a3,a0
ffffffffc0200b3a:	02081793          	slli	a5,a6,0x20
ffffffffc0200b3e:	9381                	srli	a5,a5,0x20
ffffffffc0200b40:	08a7e663          	bltu	a5,a0,ffffffffc0200bcc <best_fit_alloc_pages+0xa2>
    size_t min_size = nr_free + 1;
ffffffffc0200b44:	0018059b          	addiw	a1,a6,1
ffffffffc0200b48:	1582                	slli	a1,a1,0x20
ffffffffc0200b4a:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc0200b4c:	87b2                	mv	a5,a2
    struct Page *page = NULL;
ffffffffc0200b4e:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b50:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b52:	00c78e63          	beq	a5,a2,ffffffffc0200b6e <best_fit_alloc_pages+0x44>
        if (p->property >= n) {
ffffffffc0200b56:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200b5a:	fed76be3          	bltu	a4,a3,ffffffffc0200b50 <best_fit_alloc_pages+0x26>
            if(p->property<min_size){
ffffffffc0200b5e:	feb779e3          	bleu	a1,a4,ffffffffc0200b50 <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc0200b62:	fe878513          	addi	a0,a5,-24
ffffffffc0200b66:	679c                	ld	a5,8(a5)
ffffffffc0200b68:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b6a:	fec796e3          	bne	a5,a2,ffffffffc0200b56 <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc0200b6e:	c125                	beqz	a0,ffffffffc0200bce <best_fit_alloc_pages+0xa4>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b70:	7118                	ld	a4,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200b72:	6d10                	ld	a2,24(a0)
        if (page->property > n) {
ffffffffc0200b74:	490c                	lw	a1,16(a0)
ffffffffc0200b76:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200b7a:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200b7c:	e310                	sd	a2,0(a4)
ffffffffc0200b7e:	02059713          	slli	a4,a1,0x20
ffffffffc0200b82:	9301                	srli	a4,a4,0x20
ffffffffc0200b84:	02e6f863          	bleu	a4,a3,ffffffffc0200bb4 <best_fit_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc0200b88:	00269713          	slli	a4,a3,0x2
ffffffffc0200b8c:	9736                	add	a4,a4,a3
ffffffffc0200b8e:	070e                	slli	a4,a4,0x3
ffffffffc0200b90:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0200b92:	411585bb          	subw	a1,a1,a7
ffffffffc0200b96:	cb0c                	sw	a1,16(a4)
ffffffffc0200b98:	4689                	li	a3,2
ffffffffc0200b9a:	00870593          	addi	a1,a4,8
ffffffffc0200b9e:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200ba2:	6614                	ld	a3,8(a2)
            list_add(prev, &(p->page_link));
ffffffffc0200ba4:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200ba8:	0107a803          	lw	a6,16(a5)
ffffffffc0200bac:	e28c                	sd	a1,0(a3)
ffffffffc0200bae:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc0200bb0:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0200bb2:	ef10                	sd	a2,24(a4)
        nr_free -= n;
ffffffffc0200bb4:	4118083b          	subw	a6,a6,a7
ffffffffc0200bb8:	00006797          	auipc	a5,0x6
ffffffffc0200bbc:	8907a823          	sw	a6,-1904(a5) # ffffffffc0206448 <free_area+0x10>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200bc0:	57f5                	li	a5,-3
ffffffffc0200bc2:	00850713          	addi	a4,a0,8
ffffffffc0200bc6:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0200bca:	8082                	ret
        return NULL;
ffffffffc0200bcc:	4501                	li	a0,0
}
ffffffffc0200bce:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200bd0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200bd2:	00002697          	auipc	a3,0x2
ffffffffc0200bd6:	86e68693          	addi	a3,a3,-1938 # ffffffffc0202440 <commands+0x7c0>
ffffffffc0200bda:	00002617          	auipc	a2,0x2
ffffffffc0200bde:	86e60613          	addi	a2,a2,-1938 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200be2:	06a00593          	li	a1,106
ffffffffc0200be6:	00002517          	auipc	a0,0x2
ffffffffc0200bea:	87a50513          	addi	a0,a0,-1926 # ffffffffc0202460 <commands+0x7e0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200bee:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200bf0:	d4eff0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc0200bf4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200bf4:	715d                	addi	sp,sp,-80
ffffffffc0200bf6:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200bf8:	00006917          	auipc	s2,0x6
ffffffffc0200bfc:	84090913          	addi	s2,s2,-1984 # ffffffffc0206438 <free_area>
ffffffffc0200c00:	00893783          	ld	a5,8(s2)
ffffffffc0200c04:	e486                	sd	ra,72(sp)
ffffffffc0200c06:	e0a2                	sd	s0,64(sp)
ffffffffc0200c08:	fc26                	sd	s1,56(sp)
ffffffffc0200c0a:	f44e                	sd	s3,40(sp)
ffffffffc0200c0c:	f052                	sd	s4,32(sp)
ffffffffc0200c0e:	ec56                	sd	s5,24(sp)
ffffffffc0200c10:	e85a                	sd	s6,16(sp)
ffffffffc0200c12:	e45e                	sd	s7,8(sp)
ffffffffc0200c14:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c16:	2d278363          	beq	a5,s2,ffffffffc0200edc <best_fit_check+0x2e8>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c1a:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200c1e:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c20:	8b05                	andi	a4,a4,1
ffffffffc0200c22:	2c070163          	beqz	a4,ffffffffc0200ee4 <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc0200c26:	4401                	li	s0,0
ffffffffc0200c28:	4481                	li	s1,0
ffffffffc0200c2a:	a031                	j	ffffffffc0200c36 <best_fit_check+0x42>
ffffffffc0200c2c:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200c30:	8b09                	andi	a4,a4,2
ffffffffc0200c32:	2a070963          	beqz	a4,ffffffffc0200ee4 <best_fit_check+0x2f0>
        count ++, total += p->property;
ffffffffc0200c36:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c3a:	679c                	ld	a5,8(a5)
ffffffffc0200c3c:	2485                	addiw	s1,s1,1
ffffffffc0200c3e:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c40:	ff2796e3          	bne	a5,s2,ffffffffc0200c2c <best_fit_check+0x38>
ffffffffc0200c44:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200c46:	cdbff0ef          	jal	ra,ffffffffc0200920 <nr_free_pages>
ffffffffc0200c4a:	37351d63          	bne	a0,s3,ffffffffc0200fc4 <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c4e:	4505                	li	a0,1
ffffffffc0200c50:	c47ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200c54:	8a2a                	mv	s4,a0
ffffffffc0200c56:	3a050763          	beqz	a0,ffffffffc0201004 <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c5a:	4505                	li	a0,1
ffffffffc0200c5c:	c3bff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200c60:	89aa                	mv	s3,a0
ffffffffc0200c62:	38050163          	beqz	a0,ffffffffc0200fe4 <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c66:	4505                	li	a0,1
ffffffffc0200c68:	c2fff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200c6c:	8aaa                	mv	s5,a0
ffffffffc0200c6e:	30050b63          	beqz	a0,ffffffffc0200f84 <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c72:	293a0963          	beq	s4,s3,ffffffffc0200f04 <best_fit_check+0x310>
ffffffffc0200c76:	28aa0763          	beq	s4,a0,ffffffffc0200f04 <best_fit_check+0x310>
ffffffffc0200c7a:	28a98563          	beq	s3,a0,ffffffffc0200f04 <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c7e:	000a2783          	lw	a5,0(s4)
ffffffffc0200c82:	2a079163          	bnez	a5,ffffffffc0200f24 <best_fit_check+0x330>
ffffffffc0200c86:	0009a783          	lw	a5,0(s3)
ffffffffc0200c8a:	28079d63          	bnez	a5,ffffffffc0200f24 <best_fit_check+0x330>
ffffffffc0200c8e:	411c                	lw	a5,0(a0)
ffffffffc0200c90:	28079a63          	bnez	a5,ffffffffc0200f24 <best_fit_check+0x330>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c94:	00005797          	auipc	a5,0x5
ffffffffc0200c98:	7d478793          	addi	a5,a5,2004 # ffffffffc0206468 <pages>
ffffffffc0200c9c:	639c                	ld	a5,0(a5)
ffffffffc0200c9e:	00001717          	auipc	a4,0x1
ffffffffc0200ca2:	7da70713          	addi	a4,a4,2010 # ffffffffc0202478 <commands+0x7f8>
ffffffffc0200ca6:	630c                	ld	a1,0(a4)
ffffffffc0200ca8:	40fa0733          	sub	a4,s4,a5
ffffffffc0200cac:	870d                	srai	a4,a4,0x3
ffffffffc0200cae:	02b70733          	mul	a4,a4,a1
ffffffffc0200cb2:	00002697          	auipc	a3,0x2
ffffffffc0200cb6:	d5e68693          	addi	a3,a3,-674 # ffffffffc0202a10 <nbase>
ffffffffc0200cba:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cbc:	00005697          	auipc	a3,0x5
ffffffffc0200cc0:	75c68693          	addi	a3,a3,1884 # ffffffffc0206418 <npage>
ffffffffc0200cc4:	6294                	ld	a3,0(a3)
ffffffffc0200cc6:	06b2                	slli	a3,a3,0xc
ffffffffc0200cc8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cca:	0732                	slli	a4,a4,0xc
ffffffffc0200ccc:	26d77c63          	bleu	a3,a4,ffffffffc0200f44 <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cd0:	40f98733          	sub	a4,s3,a5
ffffffffc0200cd4:	870d                	srai	a4,a4,0x3
ffffffffc0200cd6:	02b70733          	mul	a4,a4,a1
ffffffffc0200cda:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cdc:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cde:	42d77363          	bleu	a3,a4,ffffffffc0201104 <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ce2:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ce6:	878d                	srai	a5,a5,0x3
ffffffffc0200ce8:	02b787b3          	mul	a5,a5,a1
ffffffffc0200cec:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cee:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200cf0:	3ed7fa63          	bleu	a3,a5,ffffffffc02010e4 <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200cf4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cf6:	00093c03          	ld	s8,0(s2)
ffffffffc0200cfa:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200cfe:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200d02:	00005797          	auipc	a5,0x5
ffffffffc0200d06:	7327bf23          	sd	s2,1854(a5) # ffffffffc0206440 <free_area+0x8>
ffffffffc0200d0a:	00005797          	auipc	a5,0x5
ffffffffc0200d0e:	7327b723          	sd	s2,1838(a5) # ffffffffc0206438 <free_area>
    nr_free = 0;
ffffffffc0200d12:	00005797          	auipc	a5,0x5
ffffffffc0200d16:	7207ab23          	sw	zero,1846(a5) # ffffffffc0206448 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d1a:	b7dff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d1e:	3a051363          	bnez	a0,ffffffffc02010c4 <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200d22:	4585                	li	a1,1
ffffffffc0200d24:	8552                	mv	a0,s4
ffffffffc0200d26:	bb5ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    free_page(p1);
ffffffffc0200d2a:	4585                	li	a1,1
ffffffffc0200d2c:	854e                	mv	a0,s3
ffffffffc0200d2e:	badff0ef          	jal	ra,ffffffffc02008da <free_pages>
    free_page(p2);
ffffffffc0200d32:	4585                	li	a1,1
ffffffffc0200d34:	8556                	mv	a0,s5
ffffffffc0200d36:	ba5ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    assert(nr_free == 3);
ffffffffc0200d3a:	01092703          	lw	a4,16(s2)
ffffffffc0200d3e:	478d                	li	a5,3
ffffffffc0200d40:	36f71263          	bne	a4,a5,ffffffffc02010a4 <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d44:	4505                	li	a0,1
ffffffffc0200d46:	b51ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d4a:	89aa                	mv	s3,a0
ffffffffc0200d4c:	32050c63          	beqz	a0,ffffffffc0201084 <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d50:	4505                	li	a0,1
ffffffffc0200d52:	b45ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d56:	8aaa                	mv	s5,a0
ffffffffc0200d58:	30050663          	beqz	a0,ffffffffc0201064 <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d5c:	4505                	li	a0,1
ffffffffc0200d5e:	b39ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d62:	8a2a                	mv	s4,a0
ffffffffc0200d64:	2e050063          	beqz	a0,ffffffffc0201044 <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200d68:	4505                	li	a0,1
ffffffffc0200d6a:	b2dff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d6e:	2a051b63          	bnez	a0,ffffffffc0201024 <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200d72:	4585                	li	a1,1
ffffffffc0200d74:	854e                	mv	a0,s3
ffffffffc0200d76:	b65ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d7a:	00893783          	ld	a5,8(s2)
ffffffffc0200d7e:	1f278363          	beq	a5,s2,ffffffffc0200f64 <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200d82:	4505                	li	a0,1
ffffffffc0200d84:	b13ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d88:	54a99e63          	bne	s3,a0,ffffffffc02012e4 <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200d8c:	4505                	li	a0,1
ffffffffc0200d8e:	b09ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200d92:	52051963          	bnez	a0,ffffffffc02012c4 <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200d96:	01092783          	lw	a5,16(s2)
ffffffffc0200d9a:	50079563          	bnez	a5,ffffffffc02012a4 <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200d9e:	854e                	mv	a0,s3
ffffffffc0200da0:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200da2:	00005797          	auipc	a5,0x5
ffffffffc0200da6:	6987bb23          	sd	s8,1686(a5) # ffffffffc0206438 <free_area>
ffffffffc0200daa:	00005797          	auipc	a5,0x5
ffffffffc0200dae:	6977bb23          	sd	s7,1686(a5) # ffffffffc0206440 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200db2:	00005797          	auipc	a5,0x5
ffffffffc0200db6:	6967ab23          	sw	s6,1686(a5) # ffffffffc0206448 <free_area+0x10>
    free_page(p);
ffffffffc0200dba:	b21ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    free_page(p1);
ffffffffc0200dbe:	4585                	li	a1,1
ffffffffc0200dc0:	8556                	mv	a0,s5
ffffffffc0200dc2:	b19ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    free_page(p2);
ffffffffc0200dc6:	4585                	li	a1,1
ffffffffc0200dc8:	8552                	mv	a0,s4
ffffffffc0200dca:	b11ff0ef          	jal	ra,ffffffffc02008da <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200dce:	4515                	li	a0,5
ffffffffc0200dd0:	ac7ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200dd4:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200dd6:	4a050763          	beqz	a0,ffffffffc0201284 <best_fit_check+0x690>
ffffffffc0200dda:	651c                	ld	a5,8(a0)
ffffffffc0200ddc:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200dde:	8b85                	andi	a5,a5,1
ffffffffc0200de0:	48079263          	bnez	a5,ffffffffc0201264 <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200de4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200de6:	00093b03          	ld	s6,0(s2)
ffffffffc0200dea:	00893a83          	ld	s5,8(s2)
ffffffffc0200dee:	00005797          	auipc	a5,0x5
ffffffffc0200df2:	6527b523          	sd	s2,1610(a5) # ffffffffc0206438 <free_area>
ffffffffc0200df6:	00005797          	auipc	a5,0x5
ffffffffc0200dfa:	6527b523          	sd	s2,1610(a5) # ffffffffc0206440 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200dfe:	a99ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e02:	44051163          	bnez	a0,ffffffffc0201244 <best_fit_check+0x650>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200e06:	4589                	li	a1,2
ffffffffc0200e08:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200e0c:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200e10:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200e14:	00005797          	auipc	a5,0x5
ffffffffc0200e18:	6207aa23          	sw	zero,1588(a5) # ffffffffc0206448 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200e1c:	abfff0ef          	jal	ra,ffffffffc02008da <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200e20:	8562                	mv	a0,s8
ffffffffc0200e22:	4585                	li	a1,1
ffffffffc0200e24:	ab7ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e28:	4511                	li	a0,4
ffffffffc0200e2a:	a6dff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e2e:	3e051b63          	bnez	a0,ffffffffc0201224 <best_fit_check+0x630>
ffffffffc0200e32:	0309b783          	ld	a5,48(s3)
ffffffffc0200e36:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e38:	8b85                	andi	a5,a5,1
ffffffffc0200e3a:	3c078563          	beqz	a5,ffffffffc0201204 <best_fit_check+0x610>
ffffffffc0200e3e:	0389a703          	lw	a4,56(s3)
ffffffffc0200e42:	4789                	li	a5,2
ffffffffc0200e44:	3cf71063          	bne	a4,a5,ffffffffc0201204 <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e48:	4505                	li	a0,1
ffffffffc0200e4a:	a4dff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e4e:	8a2a                	mv	s4,a0
ffffffffc0200e50:	38050a63          	beqz	a0,ffffffffc02011e4 <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e54:	4509                	li	a0,2
ffffffffc0200e56:	a41ff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e5a:	36050563          	beqz	a0,ffffffffc02011c4 <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200e5e:	354c1363          	bne	s8,s4,ffffffffc02011a4 <best_fit_check+0x5b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200e62:	854e                	mv	a0,s3
ffffffffc0200e64:	4595                	li	a1,5
ffffffffc0200e66:	a75ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e6a:	4515                	li	a0,5
ffffffffc0200e6c:	a2bff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e70:	89aa                	mv	s3,a0
ffffffffc0200e72:	30050963          	beqz	a0,ffffffffc0201184 <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200e76:	4505                	li	a0,1
ffffffffc0200e78:	a1fff0ef          	jal	ra,ffffffffc0200896 <alloc_pages>
ffffffffc0200e7c:	2e051463          	bnez	a0,ffffffffc0201164 <best_fit_check+0x570>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200e80:	01092783          	lw	a5,16(s2)
ffffffffc0200e84:	2c079063          	bnez	a5,ffffffffc0201144 <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e88:	4595                	li	a1,5
ffffffffc0200e8a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e8c:	00005797          	auipc	a5,0x5
ffffffffc0200e90:	5b77ae23          	sw	s7,1468(a5) # ffffffffc0206448 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200e94:	00005797          	auipc	a5,0x5
ffffffffc0200e98:	5b67b223          	sd	s6,1444(a5) # ffffffffc0206438 <free_area>
ffffffffc0200e9c:	00005797          	auipc	a5,0x5
ffffffffc0200ea0:	5b57b223          	sd	s5,1444(a5) # ffffffffc0206440 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200ea4:	a37ff0ef          	jal	ra,ffffffffc02008da <free_pages>
    return listelm->next;
ffffffffc0200ea8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eac:	01278963          	beq	a5,s2,ffffffffc0200ebe <best_fit_check+0x2ca>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200eb0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb4:	679c                	ld	a5,8(a5)
ffffffffc0200eb6:	34fd                	addiw	s1,s1,-1
ffffffffc0200eb8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eba:	ff279be3          	bne	a5,s2,ffffffffc0200eb0 <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200ebe:	26049363          	bnez	s1,ffffffffc0201124 <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200ec2:	e06d                	bnez	s0,ffffffffc0200fa4 <best_fit_check+0x3b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200ec4:	60a6                	ld	ra,72(sp)
ffffffffc0200ec6:	6406                	ld	s0,64(sp)
ffffffffc0200ec8:	74e2                	ld	s1,56(sp)
ffffffffc0200eca:	7942                	ld	s2,48(sp)
ffffffffc0200ecc:	79a2                	ld	s3,40(sp)
ffffffffc0200ece:	7a02                	ld	s4,32(sp)
ffffffffc0200ed0:	6ae2                	ld	s5,24(sp)
ffffffffc0200ed2:	6b42                	ld	s6,16(sp)
ffffffffc0200ed4:	6ba2                	ld	s7,8(sp)
ffffffffc0200ed6:	6c02                	ld	s8,0(sp)
ffffffffc0200ed8:	6161                	addi	sp,sp,80
ffffffffc0200eda:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200edc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ede:	4401                	li	s0,0
ffffffffc0200ee0:	4481                	li	s1,0
ffffffffc0200ee2:	b395                	j	ffffffffc0200c46 <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0200ee4:	00001697          	auipc	a3,0x1
ffffffffc0200ee8:	59c68693          	addi	a3,a3,1436 # ffffffffc0202480 <commands+0x800>
ffffffffc0200eec:	00001617          	auipc	a2,0x1
ffffffffc0200ef0:	55c60613          	addi	a2,a2,1372 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200ef4:	10c00593          	li	a1,268
ffffffffc0200ef8:	00001517          	auipc	a0,0x1
ffffffffc0200efc:	56850513          	addi	a0,a0,1384 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200f00:	a3eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f04:	00001697          	auipc	a3,0x1
ffffffffc0200f08:	60c68693          	addi	a3,a3,1548 # ffffffffc0202510 <commands+0x890>
ffffffffc0200f0c:	00001617          	auipc	a2,0x1
ffffffffc0200f10:	53c60613          	addi	a2,a2,1340 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200f14:	0d800593          	li	a1,216
ffffffffc0200f18:	00001517          	auipc	a0,0x1
ffffffffc0200f1c:	54850513          	addi	a0,a0,1352 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200f20:	a1eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f24:	00001697          	auipc	a3,0x1
ffffffffc0200f28:	61468693          	addi	a3,a3,1556 # ffffffffc0202538 <commands+0x8b8>
ffffffffc0200f2c:	00001617          	auipc	a2,0x1
ffffffffc0200f30:	51c60613          	addi	a2,a2,1308 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200f34:	0d900593          	li	a1,217
ffffffffc0200f38:	00001517          	auipc	a0,0x1
ffffffffc0200f3c:	52850513          	addi	a0,a0,1320 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200f40:	9feff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f44:	00001697          	auipc	a3,0x1
ffffffffc0200f48:	63468693          	addi	a3,a3,1588 # ffffffffc0202578 <commands+0x8f8>
ffffffffc0200f4c:	00001617          	auipc	a2,0x1
ffffffffc0200f50:	4fc60613          	addi	a2,a2,1276 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200f54:	0db00593          	li	a1,219
ffffffffc0200f58:	00001517          	auipc	a0,0x1
ffffffffc0200f5c:	50850513          	addi	a0,a0,1288 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200f60:	9deff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f64:	00001697          	auipc	a3,0x1
ffffffffc0200f68:	69c68693          	addi	a3,a3,1692 # ffffffffc0202600 <commands+0x980>
ffffffffc0200f6c:	00001617          	auipc	a2,0x1
ffffffffc0200f70:	4dc60613          	addi	a2,a2,1244 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200f74:	0f400593          	li	a1,244
ffffffffc0200f78:	00001517          	auipc	a0,0x1
ffffffffc0200f7c:	4e850513          	addi	a0,a0,1256 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200f80:	9beff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f84:	00001697          	auipc	a3,0x1
ffffffffc0200f88:	56c68693          	addi	a3,a3,1388 # ffffffffc02024f0 <commands+0x870>
ffffffffc0200f8c:	00001617          	auipc	a2,0x1
ffffffffc0200f90:	4bc60613          	addi	a2,a2,1212 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200f94:	0d600593          	li	a1,214
ffffffffc0200f98:	00001517          	auipc	a0,0x1
ffffffffc0200f9c:	4c850513          	addi	a0,a0,1224 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200fa0:	99eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(total == 0);
ffffffffc0200fa4:	00001697          	auipc	a3,0x1
ffffffffc0200fa8:	78c68693          	addi	a3,a3,1932 # ffffffffc0202730 <commands+0xab0>
ffffffffc0200fac:	00001617          	auipc	a2,0x1
ffffffffc0200fb0:	49c60613          	addi	a2,a2,1180 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200fb4:	14e00593          	li	a1,334
ffffffffc0200fb8:	00001517          	auipc	a0,0x1
ffffffffc0200fbc:	4a850513          	addi	a0,a0,1192 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200fc0:	97eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(total == nr_free_pages());
ffffffffc0200fc4:	00001697          	auipc	a3,0x1
ffffffffc0200fc8:	4cc68693          	addi	a3,a3,1228 # ffffffffc0202490 <commands+0x810>
ffffffffc0200fcc:	00001617          	auipc	a2,0x1
ffffffffc0200fd0:	47c60613          	addi	a2,a2,1148 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200fd4:	10f00593          	li	a1,271
ffffffffc0200fd8:	00001517          	auipc	a0,0x1
ffffffffc0200fdc:	48850513          	addi	a0,a0,1160 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0200fe0:	95eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fe4:	00001697          	auipc	a3,0x1
ffffffffc0200fe8:	4ec68693          	addi	a3,a3,1260 # ffffffffc02024d0 <commands+0x850>
ffffffffc0200fec:	00001617          	auipc	a2,0x1
ffffffffc0200ff0:	45c60613          	addi	a2,a2,1116 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0200ff4:	0d500593          	li	a1,213
ffffffffc0200ff8:	00001517          	auipc	a0,0x1
ffffffffc0200ffc:	46850513          	addi	a0,a0,1128 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201000:	93eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201004:	00001697          	auipc	a3,0x1
ffffffffc0201008:	4ac68693          	addi	a3,a3,1196 # ffffffffc02024b0 <commands+0x830>
ffffffffc020100c:	00001617          	auipc	a2,0x1
ffffffffc0201010:	43c60613          	addi	a2,a2,1084 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201014:	0d400593          	li	a1,212
ffffffffc0201018:	00001517          	auipc	a0,0x1
ffffffffc020101c:	44850513          	addi	a0,a0,1096 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201020:	91eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201024:	00001697          	auipc	a3,0x1
ffffffffc0201028:	5b468693          	addi	a3,a3,1460 # ffffffffc02025d8 <commands+0x958>
ffffffffc020102c:	00001617          	auipc	a2,0x1
ffffffffc0201030:	41c60613          	addi	a2,a2,1052 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201034:	0f100593          	li	a1,241
ffffffffc0201038:	00001517          	auipc	a0,0x1
ffffffffc020103c:	42850513          	addi	a0,a0,1064 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201040:	8feff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201044:	00001697          	auipc	a3,0x1
ffffffffc0201048:	4ac68693          	addi	a3,a3,1196 # ffffffffc02024f0 <commands+0x870>
ffffffffc020104c:	00001617          	auipc	a2,0x1
ffffffffc0201050:	3fc60613          	addi	a2,a2,1020 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201054:	0ef00593          	li	a1,239
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	40850513          	addi	a0,a0,1032 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201060:	8deff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201064:	00001697          	auipc	a3,0x1
ffffffffc0201068:	46c68693          	addi	a3,a3,1132 # ffffffffc02024d0 <commands+0x850>
ffffffffc020106c:	00001617          	auipc	a2,0x1
ffffffffc0201070:	3dc60613          	addi	a2,a2,988 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201074:	0ee00593          	li	a1,238
ffffffffc0201078:	00001517          	auipc	a0,0x1
ffffffffc020107c:	3e850513          	addi	a0,a0,1000 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201080:	8beff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201084:	00001697          	auipc	a3,0x1
ffffffffc0201088:	42c68693          	addi	a3,a3,1068 # ffffffffc02024b0 <commands+0x830>
ffffffffc020108c:	00001617          	auipc	a2,0x1
ffffffffc0201090:	3bc60613          	addi	a2,a2,956 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201094:	0ed00593          	li	a1,237
ffffffffc0201098:	00001517          	auipc	a0,0x1
ffffffffc020109c:	3c850513          	addi	a0,a0,968 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02010a0:	89eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(nr_free == 3);
ffffffffc02010a4:	00001697          	auipc	a3,0x1
ffffffffc02010a8:	54c68693          	addi	a3,a3,1356 # ffffffffc02025f0 <commands+0x970>
ffffffffc02010ac:	00001617          	auipc	a2,0x1
ffffffffc02010b0:	39c60613          	addi	a2,a2,924 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02010b4:	0eb00593          	li	a1,235
ffffffffc02010b8:	00001517          	auipc	a0,0x1
ffffffffc02010bc:	3a850513          	addi	a0,a0,936 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02010c0:	87eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010c4:	00001697          	auipc	a3,0x1
ffffffffc02010c8:	51468693          	addi	a3,a3,1300 # ffffffffc02025d8 <commands+0x958>
ffffffffc02010cc:	00001617          	auipc	a2,0x1
ffffffffc02010d0:	37c60613          	addi	a2,a2,892 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02010d4:	0e600593          	li	a1,230
ffffffffc02010d8:	00001517          	auipc	a0,0x1
ffffffffc02010dc:	38850513          	addi	a0,a0,904 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02010e0:	85eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010e4:	00001697          	auipc	a3,0x1
ffffffffc02010e8:	4d468693          	addi	a3,a3,1236 # ffffffffc02025b8 <commands+0x938>
ffffffffc02010ec:	00001617          	auipc	a2,0x1
ffffffffc02010f0:	35c60613          	addi	a2,a2,860 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02010f4:	0dd00593          	li	a1,221
ffffffffc02010f8:	00001517          	auipc	a0,0x1
ffffffffc02010fc:	36850513          	addi	a0,a0,872 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201100:	83eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201104:	00001697          	auipc	a3,0x1
ffffffffc0201108:	49468693          	addi	a3,a3,1172 # ffffffffc0202598 <commands+0x918>
ffffffffc020110c:	00001617          	auipc	a2,0x1
ffffffffc0201110:	33c60613          	addi	a2,a2,828 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201114:	0dc00593          	li	a1,220
ffffffffc0201118:	00001517          	auipc	a0,0x1
ffffffffc020111c:	34850513          	addi	a0,a0,840 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201120:	81eff0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(count == 0);
ffffffffc0201124:	00001697          	auipc	a3,0x1
ffffffffc0201128:	5fc68693          	addi	a3,a3,1532 # ffffffffc0202720 <commands+0xaa0>
ffffffffc020112c:	00001617          	auipc	a2,0x1
ffffffffc0201130:	31c60613          	addi	a2,a2,796 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201134:	14d00593          	li	a1,333
ffffffffc0201138:	00001517          	auipc	a0,0x1
ffffffffc020113c:	32850513          	addi	a0,a0,808 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201140:	ffffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(nr_free == 0);
ffffffffc0201144:	00001697          	auipc	a3,0x1
ffffffffc0201148:	4f468693          	addi	a3,a3,1268 # ffffffffc0202638 <commands+0x9b8>
ffffffffc020114c:	00001617          	auipc	a2,0x1
ffffffffc0201150:	2fc60613          	addi	a2,a2,764 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201154:	14200593          	li	a1,322
ffffffffc0201158:	00001517          	auipc	a0,0x1
ffffffffc020115c:	30850513          	addi	a0,a0,776 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201160:	fdffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201164:	00001697          	auipc	a3,0x1
ffffffffc0201168:	47468693          	addi	a3,a3,1140 # ffffffffc02025d8 <commands+0x958>
ffffffffc020116c:	00001617          	auipc	a2,0x1
ffffffffc0201170:	2dc60613          	addi	a2,a2,732 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201174:	13c00593          	li	a1,316
ffffffffc0201178:	00001517          	auipc	a0,0x1
ffffffffc020117c:	2e850513          	addi	a0,a0,744 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201180:	fbffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201184:	00001697          	auipc	a3,0x1
ffffffffc0201188:	57c68693          	addi	a3,a3,1404 # ffffffffc0202700 <commands+0xa80>
ffffffffc020118c:	00001617          	auipc	a2,0x1
ffffffffc0201190:	2bc60613          	addi	a2,a2,700 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201194:	13b00593          	li	a1,315
ffffffffc0201198:	00001517          	auipc	a0,0x1
ffffffffc020119c:	2c850513          	addi	a0,a0,712 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02011a0:	f9ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(p0 + 4 == p1);
ffffffffc02011a4:	00001697          	auipc	a3,0x1
ffffffffc02011a8:	54c68693          	addi	a3,a3,1356 # ffffffffc02026f0 <commands+0xa70>
ffffffffc02011ac:	00001617          	auipc	a2,0x1
ffffffffc02011b0:	29c60613          	addi	a2,a2,668 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02011b4:	13300593          	li	a1,307
ffffffffc02011b8:	00001517          	auipc	a0,0x1
ffffffffc02011bc:	2a850513          	addi	a0,a0,680 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02011c0:	f7ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02011c4:	00001697          	auipc	a3,0x1
ffffffffc02011c8:	51468693          	addi	a3,a3,1300 # ffffffffc02026d8 <commands+0xa58>
ffffffffc02011cc:	00001617          	auipc	a2,0x1
ffffffffc02011d0:	27c60613          	addi	a2,a2,636 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02011d4:	13200593          	li	a1,306
ffffffffc02011d8:	00001517          	auipc	a0,0x1
ffffffffc02011dc:	28850513          	addi	a0,a0,648 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02011e0:	f5ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02011e4:	00001697          	auipc	a3,0x1
ffffffffc02011e8:	4d468693          	addi	a3,a3,1236 # ffffffffc02026b8 <commands+0xa38>
ffffffffc02011ec:	00001617          	auipc	a2,0x1
ffffffffc02011f0:	25c60613          	addi	a2,a2,604 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02011f4:	13100593          	li	a1,305
ffffffffc02011f8:	00001517          	auipc	a0,0x1
ffffffffc02011fc:	26850513          	addi	a0,a0,616 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201200:	f3ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201204:	00001697          	auipc	a3,0x1
ffffffffc0201208:	48468693          	addi	a3,a3,1156 # ffffffffc0202688 <commands+0xa08>
ffffffffc020120c:	00001617          	auipc	a2,0x1
ffffffffc0201210:	23c60613          	addi	a2,a2,572 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201214:	12f00593          	li	a1,303
ffffffffc0201218:	00001517          	auipc	a0,0x1
ffffffffc020121c:	24850513          	addi	a0,a0,584 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201220:	f1ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201224:	00001697          	auipc	a3,0x1
ffffffffc0201228:	44c68693          	addi	a3,a3,1100 # ffffffffc0202670 <commands+0x9f0>
ffffffffc020122c:	00001617          	auipc	a2,0x1
ffffffffc0201230:	21c60613          	addi	a2,a2,540 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201234:	12e00593          	li	a1,302
ffffffffc0201238:	00001517          	auipc	a0,0x1
ffffffffc020123c:	22850513          	addi	a0,a0,552 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201240:	efffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201244:	00001697          	auipc	a3,0x1
ffffffffc0201248:	39468693          	addi	a3,a3,916 # ffffffffc02025d8 <commands+0x958>
ffffffffc020124c:	00001617          	auipc	a2,0x1
ffffffffc0201250:	1fc60613          	addi	a2,a2,508 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201254:	12200593          	li	a1,290
ffffffffc0201258:	00001517          	auipc	a0,0x1
ffffffffc020125c:	20850513          	addi	a0,a0,520 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201260:	edffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201264:	00001697          	auipc	a3,0x1
ffffffffc0201268:	3f468693          	addi	a3,a3,1012 # ffffffffc0202658 <commands+0x9d8>
ffffffffc020126c:	00001617          	auipc	a2,0x1
ffffffffc0201270:	1dc60613          	addi	a2,a2,476 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201274:	11900593          	li	a1,281
ffffffffc0201278:	00001517          	auipc	a0,0x1
ffffffffc020127c:	1e850513          	addi	a0,a0,488 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201280:	ebffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(p0 != NULL);
ffffffffc0201284:	00001697          	auipc	a3,0x1
ffffffffc0201288:	3c468693          	addi	a3,a3,964 # ffffffffc0202648 <commands+0x9c8>
ffffffffc020128c:	00001617          	auipc	a2,0x1
ffffffffc0201290:	1bc60613          	addi	a2,a2,444 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201294:	11800593          	li	a1,280
ffffffffc0201298:	00001517          	auipc	a0,0x1
ffffffffc020129c:	1c850513          	addi	a0,a0,456 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02012a0:	e9ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(nr_free == 0);
ffffffffc02012a4:	00001697          	auipc	a3,0x1
ffffffffc02012a8:	39468693          	addi	a3,a3,916 # ffffffffc0202638 <commands+0x9b8>
ffffffffc02012ac:	00001617          	auipc	a2,0x1
ffffffffc02012b0:	19c60613          	addi	a2,a2,412 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02012b4:	0fa00593          	li	a1,250
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	1a850513          	addi	a0,a0,424 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02012c0:	e7ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012c4:	00001697          	auipc	a3,0x1
ffffffffc02012c8:	31468693          	addi	a3,a3,788 # ffffffffc02025d8 <commands+0x958>
ffffffffc02012cc:	00001617          	auipc	a2,0x1
ffffffffc02012d0:	17c60613          	addi	a2,a2,380 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02012d4:	0f800593          	li	a1,248
ffffffffc02012d8:	00001517          	auipc	a0,0x1
ffffffffc02012dc:	18850513          	addi	a0,a0,392 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02012e0:	e5ffe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02012e4:	00001697          	auipc	a3,0x1
ffffffffc02012e8:	33468693          	addi	a3,a3,820 # ffffffffc0202618 <commands+0x998>
ffffffffc02012ec:	00001617          	auipc	a2,0x1
ffffffffc02012f0:	15c60613          	addi	a2,a2,348 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02012f4:	0f700593          	li	a1,247
ffffffffc02012f8:	00001517          	auipc	a0,0x1
ffffffffc02012fc:	16850513          	addi	a0,a0,360 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201300:	e3ffe0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc0201304 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201304:	1141                	addi	sp,sp,-16
ffffffffc0201306:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201308:	18058063          	beqz	a1,ffffffffc0201488 <best_fit_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc020130c:	00259693          	slli	a3,a1,0x2
ffffffffc0201310:	96ae                	add	a3,a3,a1
ffffffffc0201312:	068e                	slli	a3,a3,0x3
ffffffffc0201314:	96aa                	add	a3,a3,a0
ffffffffc0201316:	02d50d63          	beq	a0,a3,ffffffffc0201350 <best_fit_free_pages+0x4c>
ffffffffc020131a:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020131c:	8b85                	andi	a5,a5,1
ffffffffc020131e:	14079563          	bnez	a5,ffffffffc0201468 <best_fit_free_pages+0x164>
ffffffffc0201322:	651c                	ld	a5,8(a0)
ffffffffc0201324:	8385                	srli	a5,a5,0x1
ffffffffc0201326:	8b85                	andi	a5,a5,1
ffffffffc0201328:	14079063          	bnez	a5,ffffffffc0201468 <best_fit_free_pages+0x164>
ffffffffc020132c:	87aa                	mv	a5,a0
ffffffffc020132e:	a809                	j	ffffffffc0201340 <best_fit_free_pages+0x3c>
ffffffffc0201330:	6798                	ld	a4,8(a5)
ffffffffc0201332:	8b05                	andi	a4,a4,1
ffffffffc0201334:	12071a63          	bnez	a4,ffffffffc0201468 <best_fit_free_pages+0x164>
ffffffffc0201338:	6798                	ld	a4,8(a5)
ffffffffc020133a:	8b09                	andi	a4,a4,2
ffffffffc020133c:	12071663          	bnez	a4,ffffffffc0201468 <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc0201340:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201344:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201348:	02878793          	addi	a5,a5,40
ffffffffc020134c:	fed792e3          	bne	a5,a3,ffffffffc0201330 <best_fit_free_pages+0x2c>
    base->property = n;
ffffffffc0201350:	2581                	sext.w	a1,a1
ffffffffc0201352:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201354:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201358:	4789                	li	a5,2
ffffffffc020135a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020135e:	00005697          	auipc	a3,0x5
ffffffffc0201362:	0da68693          	addi	a3,a3,218 # ffffffffc0206438 <free_area>
ffffffffc0201366:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201368:	669c                	ld	a5,8(a3)
ffffffffc020136a:	9db9                	addw	a1,a1,a4
ffffffffc020136c:	00005717          	auipc	a4,0x5
ffffffffc0201370:	0cb72e23          	sw	a1,220(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201374:	08d78f63          	beq	a5,a3,ffffffffc0201412 <best_fit_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201378:	fe878713          	addi	a4,a5,-24
ffffffffc020137c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020137e:	4801                	li	a6,0
ffffffffc0201380:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201384:	00e56a63          	bltu	a0,a4,ffffffffc0201398 <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc0201388:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020138a:	02d70563          	beq	a4,a3,ffffffffc02013b4 <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020138e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201390:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201394:	fee57ae3          	bleu	a4,a0,ffffffffc0201388 <best_fit_free_pages+0x84>
ffffffffc0201398:	00080663          	beqz	a6,ffffffffc02013a4 <best_fit_free_pages+0xa0>
ffffffffc020139c:	00005817          	auipc	a6,0x5
ffffffffc02013a0:	08b83e23          	sd	a1,156(a6) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02013a4:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc02013a6:	e390                	sd	a2,0(a5)
ffffffffc02013a8:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02013aa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02013ac:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc02013ae:	02d59163          	bne	a1,a3,ffffffffc02013d0 <best_fit_free_pages+0xcc>
ffffffffc02013b2:	a091                	j	ffffffffc02013f6 <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc02013b4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013b6:	f114                	sd	a3,32(a0)
ffffffffc02013b8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013ba:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02013bc:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013be:	00d70563          	beq	a4,a3,ffffffffc02013c8 <best_fit_free_pages+0xc4>
ffffffffc02013c2:	4805                	li	a6,1
ffffffffc02013c4:	87ba                	mv	a5,a4
ffffffffc02013c6:	b7e9                	j	ffffffffc0201390 <best_fit_free_pages+0x8c>
ffffffffc02013c8:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02013ca:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc02013cc:	02d78163          	beq	a5,a3,ffffffffc02013ee <best_fit_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc02013d0:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc02013d4:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base) {
ffffffffc02013d8:	02081713          	slli	a4,a6,0x20
ffffffffc02013dc:	9301                	srli	a4,a4,0x20
ffffffffc02013de:	00271793          	slli	a5,a4,0x2
ffffffffc02013e2:	97ba                	add	a5,a5,a4
ffffffffc02013e4:	078e                	slli	a5,a5,0x3
ffffffffc02013e6:	97b2                	add	a5,a5,a2
ffffffffc02013e8:	02f50e63          	beq	a0,a5,ffffffffc0201424 <best_fit_free_pages+0x120>
ffffffffc02013ec:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02013ee:	fe878713          	addi	a4,a5,-24
ffffffffc02013f2:	00d78d63          	beq	a5,a3,ffffffffc020140c <best_fit_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc02013f6:	490c                	lw	a1,16(a0)
ffffffffc02013f8:	02059613          	slli	a2,a1,0x20
ffffffffc02013fc:	9201                	srli	a2,a2,0x20
ffffffffc02013fe:	00261693          	slli	a3,a2,0x2
ffffffffc0201402:	96b2                	add	a3,a3,a2
ffffffffc0201404:	068e                	slli	a3,a3,0x3
ffffffffc0201406:	96aa                	add	a3,a3,a0
ffffffffc0201408:	04d70063          	beq	a4,a3,ffffffffc0201448 <best_fit_free_pages+0x144>
}
ffffffffc020140c:	60a2                	ld	ra,8(sp)
ffffffffc020140e:	0141                	addi	sp,sp,16
ffffffffc0201410:	8082                	ret
ffffffffc0201412:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201414:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201418:	e398                	sd	a4,0(a5)
ffffffffc020141a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020141c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020141e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201420:	0141                	addi	sp,sp,16
ffffffffc0201422:	8082                	ret
            p->property += base->property;
ffffffffc0201424:	491c                	lw	a5,16(a0)
ffffffffc0201426:	0107883b          	addw	a6,a5,a6
ffffffffc020142a:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020142e:	57f5                	li	a5,-3
ffffffffc0201430:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201434:	01853803          	ld	a6,24(a0)
ffffffffc0201438:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc020143a:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020143c:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201440:	659c                	ld	a5,8(a1)
ffffffffc0201442:	01073023          	sd	a6,0(a4)
ffffffffc0201446:	b765                	j	ffffffffc02013ee <best_fit_free_pages+0xea>
            base->property += p->property;
ffffffffc0201448:	ff87a703          	lw	a4,-8(a5)
ffffffffc020144c:	ff078693          	addi	a3,a5,-16
ffffffffc0201450:	9db9                	addw	a1,a1,a4
ffffffffc0201452:	c90c                	sw	a1,16(a0)
ffffffffc0201454:	5775                	li	a4,-3
ffffffffc0201456:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020145a:	6398                	ld	a4,0(a5)
ffffffffc020145c:	679c                	ld	a5,8(a5)
}
ffffffffc020145e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201460:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201462:	e398                	sd	a4,0(a5)
ffffffffc0201464:	0141                	addi	sp,sp,16
ffffffffc0201466:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201468:	00001697          	auipc	a3,0x1
ffffffffc020146c:	2d868693          	addi	a3,a3,728 # ffffffffc0202740 <commands+0xac0>
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	fd860613          	addi	a2,a2,-40 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201478:	09300593          	li	a1,147
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	fe450513          	addi	a0,a0,-28 # ffffffffc0202460 <commands+0x7e0>
ffffffffc0201484:	cbbfe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(n > 0);
ffffffffc0201488:	00001697          	auipc	a3,0x1
ffffffffc020148c:	fb868693          	addi	a3,a3,-72 # ffffffffc0202440 <commands+0x7c0>
ffffffffc0201490:	00001617          	auipc	a2,0x1
ffffffffc0201494:	fb860613          	addi	a2,a2,-72 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201498:	09000593          	li	a1,144
ffffffffc020149c:	00001517          	auipc	a0,0x1
ffffffffc02014a0:	fc450513          	addi	a0,a0,-60 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02014a4:	c9bfe0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc02014a8 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02014a8:	1141                	addi	sp,sp,-16
ffffffffc02014aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014ac:	c1fd                	beqz	a1,ffffffffc0201592 <best_fit_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc02014ae:	00259693          	slli	a3,a1,0x2
ffffffffc02014b2:	96ae                	add	a3,a3,a1
ffffffffc02014b4:	068e                	slli	a3,a3,0x3
ffffffffc02014b6:	96aa                	add	a3,a3,a0
ffffffffc02014b8:	02d50463          	beq	a0,a3,ffffffffc02014e0 <best_fit_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02014bc:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02014be:	87aa                	mv	a5,a0
ffffffffc02014c0:	8b05                	andi	a4,a4,1
ffffffffc02014c2:	e709                	bnez	a4,ffffffffc02014cc <best_fit_init_memmap+0x24>
ffffffffc02014c4:	a07d                	j	ffffffffc0201572 <best_fit_init_memmap+0xca>
ffffffffc02014c6:	6798                	ld	a4,8(a5)
ffffffffc02014c8:	8b05                	andi	a4,a4,1
ffffffffc02014ca:	c745                	beqz	a4,ffffffffc0201572 <best_fit_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc02014cc:	0007a823          	sw	zero,16(a5)
ffffffffc02014d0:	0007b423          	sd	zero,8(a5)
ffffffffc02014d4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014d8:	02878793          	addi	a5,a5,40
ffffffffc02014dc:	fed795e3          	bne	a5,a3,ffffffffc02014c6 <best_fit_init_memmap+0x1e>
    base->property = n;
ffffffffc02014e0:	2581                	sext.w	a1,a1
ffffffffc02014e2:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014e4:	4789                	li	a5,2
ffffffffc02014e6:	00850713          	addi	a4,a0,8
ffffffffc02014ea:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02014ee:	00005697          	auipc	a3,0x5
ffffffffc02014f2:	f4a68693          	addi	a3,a3,-182 # ffffffffc0206438 <free_area>
ffffffffc02014f6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014f8:	669c                	ld	a5,8(a3)
ffffffffc02014fa:	9db9                	addw	a1,a1,a4
ffffffffc02014fc:	00005717          	auipc	a4,0x5
ffffffffc0201500:	f4b72623          	sw	a1,-180(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201504:	04d78a63          	beq	a5,a3,ffffffffc0201558 <best_fit_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0201508:	fe878713          	addi	a4,a5,-24
ffffffffc020150c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020150e:	4801                	li	a6,0
ffffffffc0201510:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201514:	00e56a63          	bltu	a0,a4,ffffffffc0201528 <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc0201518:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020151a:	02d70563          	beq	a4,a3,ffffffffc0201544 <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020151e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201520:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201524:	fee57ae3          	bleu	a4,a0,ffffffffc0201518 <best_fit_init_memmap+0x70>
ffffffffc0201528:	00080663          	beqz	a6,ffffffffc0201534 <best_fit_init_memmap+0x8c>
ffffffffc020152c:	00005717          	auipc	a4,0x5
ffffffffc0201530:	f0b73623          	sd	a1,-244(a4) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201534:	6398                	ld	a4,0(a5)
}
ffffffffc0201536:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201538:	e390                	sd	a2,0(a5)
ffffffffc020153a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020153c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020153e:	ed18                	sd	a4,24(a0)
ffffffffc0201540:	0141                	addi	sp,sp,16
ffffffffc0201542:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201544:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201546:	f114                	sd	a3,32(a0)
ffffffffc0201548:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020154a:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020154c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020154e:	00d70e63          	beq	a4,a3,ffffffffc020156a <best_fit_init_memmap+0xc2>
ffffffffc0201552:	4805                	li	a6,1
ffffffffc0201554:	87ba                	mv	a5,a4
ffffffffc0201556:	b7e9                	j	ffffffffc0201520 <best_fit_init_memmap+0x78>
}
ffffffffc0201558:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020155a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020155e:	e398                	sd	a4,0(a5)
ffffffffc0201560:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201562:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201564:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201566:	0141                	addi	sp,sp,16
ffffffffc0201568:	8082                	ret
ffffffffc020156a:	60a2                	ld	ra,8(sp)
ffffffffc020156c:	e290                	sd	a2,0(a3)
ffffffffc020156e:	0141                	addi	sp,sp,16
ffffffffc0201570:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201572:	00001697          	auipc	a3,0x1
ffffffffc0201576:	1f668693          	addi	a3,a3,502 # ffffffffc0202768 <commands+0xae8>
ffffffffc020157a:	00001617          	auipc	a2,0x1
ffffffffc020157e:	ece60613          	addi	a2,a2,-306 # ffffffffc0202448 <commands+0x7c8>
ffffffffc0201582:	04a00593          	li	a1,74
ffffffffc0201586:	00001517          	auipc	a0,0x1
ffffffffc020158a:	eda50513          	addi	a0,a0,-294 # ffffffffc0202460 <commands+0x7e0>
ffffffffc020158e:	bb1fe0ef          	jal	ra,ffffffffc020013e <__panic>
    assert(n > 0);
ffffffffc0201592:	00001697          	auipc	a3,0x1
ffffffffc0201596:	eae68693          	addi	a3,a3,-338 # ffffffffc0202440 <commands+0x7c0>
ffffffffc020159a:	00001617          	auipc	a2,0x1
ffffffffc020159e:	eae60613          	addi	a2,a2,-338 # ffffffffc0202448 <commands+0x7c8>
ffffffffc02015a2:	04700593          	li	a1,71
ffffffffc02015a6:	00001517          	auipc	a0,0x1
ffffffffc02015aa:	eba50513          	addi	a0,a0,-326 # ffffffffc0202460 <commands+0x7e0>
ffffffffc02015ae:	b91fe0ef          	jal	ra,ffffffffc020013e <__panic>

ffffffffc02015b2 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015b2:	c185                	beqz	a1,ffffffffc02015d2 <strnlen+0x20>
ffffffffc02015b4:	00054783          	lbu	a5,0(a0)
ffffffffc02015b8:	cf89                	beqz	a5,ffffffffc02015d2 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02015ba:	4781                	li	a5,0
ffffffffc02015bc:	a021                	j	ffffffffc02015c4 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015be:	00074703          	lbu	a4,0(a4)
ffffffffc02015c2:	c711                	beqz	a4,ffffffffc02015ce <strnlen+0x1c>
        cnt ++;
ffffffffc02015c4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015c6:	00f50733          	add	a4,a0,a5
ffffffffc02015ca:	fef59ae3          	bne	a1,a5,ffffffffc02015be <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02015ce:	853e                	mv	a0,a5
ffffffffc02015d0:	8082                	ret
    size_t cnt = 0;
ffffffffc02015d2:	4781                	li	a5,0
}
ffffffffc02015d4:	853e                	mv	a0,a5
ffffffffc02015d6:	8082                	ret

ffffffffc02015d8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015d8:	00054783          	lbu	a5,0(a0)
ffffffffc02015dc:	0005c703          	lbu	a4,0(a1)
ffffffffc02015e0:	cb91                	beqz	a5,ffffffffc02015f4 <strcmp+0x1c>
ffffffffc02015e2:	00e79c63          	bne	a5,a4,ffffffffc02015fa <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02015e6:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015e8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02015ec:	0585                	addi	a1,a1,1
ffffffffc02015ee:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015f2:	fbe5                	bnez	a5,ffffffffc02015e2 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015f4:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015f6:	9d19                	subw	a0,a0,a4
ffffffffc02015f8:	8082                	ret
ffffffffc02015fa:	0007851b          	sext.w	a0,a5
ffffffffc02015fe:	9d19                	subw	a0,a0,a4
ffffffffc0201600:	8082                	ret

ffffffffc0201602 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201602:	00054783          	lbu	a5,0(a0)
ffffffffc0201606:	cb91                	beqz	a5,ffffffffc020161a <strchr+0x18>
        if (*s == c) {
ffffffffc0201608:	00b79563          	bne	a5,a1,ffffffffc0201612 <strchr+0x10>
ffffffffc020160c:	a809                	j	ffffffffc020161e <strchr+0x1c>
ffffffffc020160e:	00b78763          	beq	a5,a1,ffffffffc020161c <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201612:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201614:	00054783          	lbu	a5,0(a0)
ffffffffc0201618:	fbfd                	bnez	a5,ffffffffc020160e <strchr+0xc>
    }
    return NULL;
ffffffffc020161a:	4501                	li	a0,0
}
ffffffffc020161c:	8082                	ret
ffffffffc020161e:	8082                	ret

ffffffffc0201620 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201620:	ca01                	beqz	a2,ffffffffc0201630 <memset+0x10>
ffffffffc0201622:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201624:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201626:	0785                	addi	a5,a5,1
ffffffffc0201628:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020162c:	fec79de3          	bne	a5,a2,ffffffffc0201626 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201630:	8082                	ret

ffffffffc0201632 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201632:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201636:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201638:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020163c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020163e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201642:	f022                	sd	s0,32(sp)
ffffffffc0201644:	ec26                	sd	s1,24(sp)
ffffffffc0201646:	e84a                	sd	s2,16(sp)
ffffffffc0201648:	f406                	sd	ra,40(sp)
ffffffffc020164a:	e44e                	sd	s3,8(sp)
ffffffffc020164c:	84aa                	mv	s1,a0
ffffffffc020164e:	892e                	mv	s2,a1
ffffffffc0201650:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201654:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201656:	03067e63          	bleu	a6,a2,ffffffffc0201692 <printnum+0x60>
ffffffffc020165a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020165c:	00805763          	blez	s0,ffffffffc020166a <printnum+0x38>
ffffffffc0201660:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201662:	85ca                	mv	a1,s2
ffffffffc0201664:	854e                	mv	a0,s3
ffffffffc0201666:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201668:	fc65                	bnez	s0,ffffffffc0201660 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020166a:	1a02                	slli	s4,s4,0x20
ffffffffc020166c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201670:	00001797          	auipc	a5,0x1
ffffffffc0201674:	2e878793          	addi	a5,a5,744 # ffffffffc0202958 <error_string+0x38>
ffffffffc0201678:	9a3e                	add	s4,s4,a5
}
ffffffffc020167a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020167c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201680:	70a2                	ld	ra,40(sp)
ffffffffc0201682:	69a2                	ld	s3,8(sp)
ffffffffc0201684:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201686:	85ca                	mv	a1,s2
ffffffffc0201688:	8326                	mv	t1,s1
}
ffffffffc020168a:	6942                	ld	s2,16(sp)
ffffffffc020168c:	64e2                	ld	s1,24(sp)
ffffffffc020168e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201690:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201692:	03065633          	divu	a2,a2,a6
ffffffffc0201696:	8722                	mv	a4,s0
ffffffffc0201698:	f9bff0ef          	jal	ra,ffffffffc0201632 <printnum>
ffffffffc020169c:	b7f9                	j	ffffffffc020166a <printnum+0x38>

ffffffffc020169e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020169e:	7119                	addi	sp,sp,-128
ffffffffc02016a0:	f4a6                	sd	s1,104(sp)
ffffffffc02016a2:	f0ca                	sd	s2,96(sp)
ffffffffc02016a4:	e8d2                	sd	s4,80(sp)
ffffffffc02016a6:	e4d6                	sd	s5,72(sp)
ffffffffc02016a8:	e0da                	sd	s6,64(sp)
ffffffffc02016aa:	fc5e                	sd	s7,56(sp)
ffffffffc02016ac:	f862                	sd	s8,48(sp)
ffffffffc02016ae:	f06a                	sd	s10,32(sp)
ffffffffc02016b0:	fc86                	sd	ra,120(sp)
ffffffffc02016b2:	f8a2                	sd	s0,112(sp)
ffffffffc02016b4:	ecce                	sd	s3,88(sp)
ffffffffc02016b6:	f466                	sd	s9,40(sp)
ffffffffc02016b8:	ec6e                	sd	s11,24(sp)
ffffffffc02016ba:	892a                	mv	s2,a0
ffffffffc02016bc:	84ae                	mv	s1,a1
ffffffffc02016be:	8d32                	mv	s10,a2
ffffffffc02016c0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02016c2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016c4:	00001a17          	auipc	s4,0x1
ffffffffc02016c8:	104a0a13          	addi	s4,s4,260 # ffffffffc02027c8 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016cc:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016d0:	00001c17          	auipc	s8,0x1
ffffffffc02016d4:	250c0c13          	addi	s8,s8,592 # ffffffffc0202920 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016d8:	000d4503          	lbu	a0,0(s10)
ffffffffc02016dc:	02500793          	li	a5,37
ffffffffc02016e0:	001d0413          	addi	s0,s10,1
ffffffffc02016e4:	00f50e63          	beq	a0,a5,ffffffffc0201700 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02016e8:	c521                	beqz	a0,ffffffffc0201730 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016ea:	02500993          	li	s3,37
ffffffffc02016ee:	a011                	j	ffffffffc02016f2 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02016f0:	c121                	beqz	a0,ffffffffc0201730 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02016f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02016f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016f8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02016fc:	ff351ae3          	bne	a0,s3,ffffffffc02016f0 <vprintfmt+0x52>
ffffffffc0201700:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201704:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201708:	4981                	li	s3,0
ffffffffc020170a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020170c:	5cfd                	li	s9,-1
ffffffffc020170e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201710:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201714:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201716:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020171a:	0ff6f693          	andi	a3,a3,255
ffffffffc020171e:	00140d13          	addi	s10,s0,1
ffffffffc0201722:	20d5e563          	bltu	a1,a3,ffffffffc020192c <vprintfmt+0x28e>
ffffffffc0201726:	068a                	slli	a3,a3,0x2
ffffffffc0201728:	96d2                	add	a3,a3,s4
ffffffffc020172a:	4294                	lw	a3,0(a3)
ffffffffc020172c:	96d2                	add	a3,a3,s4
ffffffffc020172e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201730:	70e6                	ld	ra,120(sp)
ffffffffc0201732:	7446                	ld	s0,112(sp)
ffffffffc0201734:	74a6                	ld	s1,104(sp)
ffffffffc0201736:	7906                	ld	s2,96(sp)
ffffffffc0201738:	69e6                	ld	s3,88(sp)
ffffffffc020173a:	6a46                	ld	s4,80(sp)
ffffffffc020173c:	6aa6                	ld	s5,72(sp)
ffffffffc020173e:	6b06                	ld	s6,64(sp)
ffffffffc0201740:	7be2                	ld	s7,56(sp)
ffffffffc0201742:	7c42                	ld	s8,48(sp)
ffffffffc0201744:	7ca2                	ld	s9,40(sp)
ffffffffc0201746:	7d02                	ld	s10,32(sp)
ffffffffc0201748:	6de2                	ld	s11,24(sp)
ffffffffc020174a:	6109                	addi	sp,sp,128
ffffffffc020174c:	8082                	ret
    if (lflag >= 2) {
ffffffffc020174e:	4705                	li	a4,1
ffffffffc0201750:	008a8593          	addi	a1,s5,8
ffffffffc0201754:	01074463          	blt	a4,a6,ffffffffc020175c <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201758:	26080363          	beqz	a6,ffffffffc02019be <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020175c:	000ab603          	ld	a2,0(s5)
ffffffffc0201760:	46c1                	li	a3,16
ffffffffc0201762:	8aae                	mv	s5,a1
ffffffffc0201764:	a06d                	j	ffffffffc020180e <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201766:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020176a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020176c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020176e:	b765                	j	ffffffffc0201716 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201770:	000aa503          	lw	a0,0(s5)
ffffffffc0201774:	85a6                	mv	a1,s1
ffffffffc0201776:	0aa1                	addi	s5,s5,8
ffffffffc0201778:	9902                	jalr	s2
            break;
ffffffffc020177a:	bfb9                	j	ffffffffc02016d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020177c:	4705                	li	a4,1
ffffffffc020177e:	008a8993          	addi	s3,s5,8
ffffffffc0201782:	01074463          	blt	a4,a6,ffffffffc020178a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201786:	22080463          	beqz	a6,ffffffffc02019ae <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020178a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020178e:	24044463          	bltz	s0,ffffffffc02019d6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201792:	8622                	mv	a2,s0
ffffffffc0201794:	8ace                	mv	s5,s3
ffffffffc0201796:	46a9                	li	a3,10
ffffffffc0201798:	a89d                	j	ffffffffc020180e <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020179a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020179e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02017a0:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02017a2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02017a6:	8fb5                	xor	a5,a5,a3
ffffffffc02017a8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017ac:	1ad74363          	blt	a4,a3,ffffffffc0201952 <vprintfmt+0x2b4>
ffffffffc02017b0:	00369793          	slli	a5,a3,0x3
ffffffffc02017b4:	97e2                	add	a5,a5,s8
ffffffffc02017b6:	639c                	ld	a5,0(a5)
ffffffffc02017b8:	18078d63          	beqz	a5,ffffffffc0201952 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02017bc:	86be                	mv	a3,a5
ffffffffc02017be:	00001617          	auipc	a2,0x1
ffffffffc02017c2:	24a60613          	addi	a2,a2,586 # ffffffffc0202a08 <error_string+0xe8>
ffffffffc02017c6:	85a6                	mv	a1,s1
ffffffffc02017c8:	854a                	mv	a0,s2
ffffffffc02017ca:	240000ef          	jal	ra,ffffffffc0201a0a <printfmt>
ffffffffc02017ce:	b729                	j	ffffffffc02016d8 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02017d0:	00144603          	lbu	a2,1(s0)
ffffffffc02017d4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017d8:	bf3d                	j	ffffffffc0201716 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02017da:	4705                	li	a4,1
ffffffffc02017dc:	008a8593          	addi	a1,s5,8
ffffffffc02017e0:	01074463          	blt	a4,a6,ffffffffc02017e8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02017e4:	1e080263          	beqz	a6,ffffffffc02019c8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02017e8:	000ab603          	ld	a2,0(s5)
ffffffffc02017ec:	46a1                	li	a3,8
ffffffffc02017ee:	8aae                	mv	s5,a1
ffffffffc02017f0:	a839                	j	ffffffffc020180e <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02017f2:	03000513          	li	a0,48
ffffffffc02017f6:	85a6                	mv	a1,s1
ffffffffc02017f8:	e03e                	sd	a5,0(sp)
ffffffffc02017fa:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	07800513          	li	a0,120
ffffffffc0201802:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201804:	0aa1                	addi	s5,s5,8
ffffffffc0201806:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020180a:	6782                	ld	a5,0(sp)
ffffffffc020180c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020180e:	876e                	mv	a4,s11
ffffffffc0201810:	85a6                	mv	a1,s1
ffffffffc0201812:	854a                	mv	a0,s2
ffffffffc0201814:	e1fff0ef          	jal	ra,ffffffffc0201632 <printnum>
            break;
ffffffffc0201818:	b5c1                	j	ffffffffc02016d8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020181a:	000ab603          	ld	a2,0(s5)
ffffffffc020181e:	0aa1                	addi	s5,s5,8
ffffffffc0201820:	1c060663          	beqz	a2,ffffffffc02019ec <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201824:	00160413          	addi	s0,a2,1
ffffffffc0201828:	17b05c63          	blez	s11,ffffffffc02019a0 <vprintfmt+0x302>
ffffffffc020182c:	02d00593          	li	a1,45
ffffffffc0201830:	14b79263          	bne	a5,a1,ffffffffc0201974 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201834:	00064783          	lbu	a5,0(a2)
ffffffffc0201838:	0007851b          	sext.w	a0,a5
ffffffffc020183c:	c905                	beqz	a0,ffffffffc020186c <vprintfmt+0x1ce>
ffffffffc020183e:	000cc563          	bltz	s9,ffffffffc0201848 <vprintfmt+0x1aa>
ffffffffc0201842:	3cfd                	addiw	s9,s9,-1
ffffffffc0201844:	036c8263          	beq	s9,s6,ffffffffc0201868 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201848:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020184a:	18098463          	beqz	s3,ffffffffc02019d2 <vprintfmt+0x334>
ffffffffc020184e:	3781                	addiw	a5,a5,-32
ffffffffc0201850:	18fbf163          	bleu	a5,s7,ffffffffc02019d2 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201854:	03f00513          	li	a0,63
ffffffffc0201858:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020185a:	0405                	addi	s0,s0,1
ffffffffc020185c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201860:	3dfd                	addiw	s11,s11,-1
ffffffffc0201862:	0007851b          	sext.w	a0,a5
ffffffffc0201866:	fd61                	bnez	a0,ffffffffc020183e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201868:	e7b058e3          	blez	s11,ffffffffc02016d8 <vprintfmt+0x3a>
ffffffffc020186c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020186e:	85a6                	mv	a1,s1
ffffffffc0201870:	02000513          	li	a0,32
ffffffffc0201874:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201876:	e60d81e3          	beqz	s11,ffffffffc02016d8 <vprintfmt+0x3a>
ffffffffc020187a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020187c:	85a6                	mv	a1,s1
ffffffffc020187e:	02000513          	li	a0,32
ffffffffc0201882:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201884:	fe0d94e3          	bnez	s11,ffffffffc020186c <vprintfmt+0x1ce>
ffffffffc0201888:	bd81                	j	ffffffffc02016d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020188a:	4705                	li	a4,1
ffffffffc020188c:	008a8593          	addi	a1,s5,8
ffffffffc0201890:	01074463          	blt	a4,a6,ffffffffc0201898 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201894:	12080063          	beqz	a6,ffffffffc02019b4 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201898:	000ab603          	ld	a2,0(s5)
ffffffffc020189c:	46a9                	li	a3,10
ffffffffc020189e:	8aae                	mv	s5,a1
ffffffffc02018a0:	b7bd                	j	ffffffffc020180e <vprintfmt+0x170>
ffffffffc02018a2:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02018a6:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018aa:	846a                	mv	s0,s10
ffffffffc02018ac:	b5ad                	j	ffffffffc0201716 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02018ae:	85a6                	mv	a1,s1
ffffffffc02018b0:	02500513          	li	a0,37
ffffffffc02018b4:	9902                	jalr	s2
            break;
ffffffffc02018b6:	b50d                	j	ffffffffc02016d8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02018b8:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02018bc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02018c0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018c2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02018c4:	e40dd9e3          	bgez	s11,ffffffffc0201716 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02018c8:	8de6                	mv	s11,s9
ffffffffc02018ca:	5cfd                	li	s9,-1
ffffffffc02018cc:	b5a9                	j	ffffffffc0201716 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02018ce:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02018d2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018d8:	bd3d                	j	ffffffffc0201716 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02018da:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02018de:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018e2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02018e4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02018e8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018ec:	fcd56ce3          	bltu	a0,a3,ffffffffc02018c4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02018f0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02018f2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02018f6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02018fa:	0196873b          	addw	a4,a3,s9
ffffffffc02018fe:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201902:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201906:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020190a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020190e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201912:	fcd57fe3          	bleu	a3,a0,ffffffffc02018f0 <vprintfmt+0x252>
ffffffffc0201916:	b77d                	j	ffffffffc02018c4 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201918:	fffdc693          	not	a3,s11
ffffffffc020191c:	96fd                	srai	a3,a3,0x3f
ffffffffc020191e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201922:	00144603          	lbu	a2,1(s0)
ffffffffc0201926:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201928:	846a                	mv	s0,s10
ffffffffc020192a:	b3f5                	j	ffffffffc0201716 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc020192c:	85a6                	mv	a1,s1
ffffffffc020192e:	02500513          	li	a0,37
ffffffffc0201932:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201934:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201938:	02500793          	li	a5,37
ffffffffc020193c:	8d22                	mv	s10,s0
ffffffffc020193e:	d8f70de3          	beq	a4,a5,ffffffffc02016d8 <vprintfmt+0x3a>
ffffffffc0201942:	02500713          	li	a4,37
ffffffffc0201946:	1d7d                	addi	s10,s10,-1
ffffffffc0201948:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020194c:	fee79de3          	bne	a5,a4,ffffffffc0201946 <vprintfmt+0x2a8>
ffffffffc0201950:	b361                	j	ffffffffc02016d8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201952:	00001617          	auipc	a2,0x1
ffffffffc0201956:	0a660613          	addi	a2,a2,166 # ffffffffc02029f8 <error_string+0xd8>
ffffffffc020195a:	85a6                	mv	a1,s1
ffffffffc020195c:	854a                	mv	a0,s2
ffffffffc020195e:	0ac000ef          	jal	ra,ffffffffc0201a0a <printfmt>
ffffffffc0201962:	bb9d                	j	ffffffffc02016d8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201964:	00001617          	auipc	a2,0x1
ffffffffc0201968:	08c60613          	addi	a2,a2,140 # ffffffffc02029f0 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020196c:	00001417          	auipc	s0,0x1
ffffffffc0201970:	08540413          	addi	s0,s0,133 # ffffffffc02029f1 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201974:	8532                	mv	a0,a2
ffffffffc0201976:	85e6                	mv	a1,s9
ffffffffc0201978:	e032                	sd	a2,0(sp)
ffffffffc020197a:	e43e                	sd	a5,8(sp)
ffffffffc020197c:	c37ff0ef          	jal	ra,ffffffffc02015b2 <strnlen>
ffffffffc0201980:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201984:	6602                	ld	a2,0(sp)
ffffffffc0201986:	01b05d63          	blez	s11,ffffffffc02019a0 <vprintfmt+0x302>
ffffffffc020198a:	67a2                	ld	a5,8(sp)
ffffffffc020198c:	2781                	sext.w	a5,a5
ffffffffc020198e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201990:	6522                	ld	a0,8(sp)
ffffffffc0201992:	85a6                	mv	a1,s1
ffffffffc0201994:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201996:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201998:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020199a:	6602                	ld	a2,0(sp)
ffffffffc020199c:	fe0d9ae3          	bnez	s11,ffffffffc0201990 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019a0:	00064783          	lbu	a5,0(a2)
ffffffffc02019a4:	0007851b          	sext.w	a0,a5
ffffffffc02019a8:	e8051be3          	bnez	a0,ffffffffc020183e <vprintfmt+0x1a0>
ffffffffc02019ac:	b335                	j	ffffffffc02016d8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02019ae:	000aa403          	lw	s0,0(s5)
ffffffffc02019b2:	bbf1                	j	ffffffffc020178e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02019b4:	000ae603          	lwu	a2,0(s5)
ffffffffc02019b8:	46a9                	li	a3,10
ffffffffc02019ba:	8aae                	mv	s5,a1
ffffffffc02019bc:	bd89                	j	ffffffffc020180e <vprintfmt+0x170>
ffffffffc02019be:	000ae603          	lwu	a2,0(s5)
ffffffffc02019c2:	46c1                	li	a3,16
ffffffffc02019c4:	8aae                	mv	s5,a1
ffffffffc02019c6:	b5a1                	j	ffffffffc020180e <vprintfmt+0x170>
ffffffffc02019c8:	000ae603          	lwu	a2,0(s5)
ffffffffc02019cc:	46a1                	li	a3,8
ffffffffc02019ce:	8aae                	mv	s5,a1
ffffffffc02019d0:	bd3d                	j	ffffffffc020180e <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02019d2:	9902                	jalr	s2
ffffffffc02019d4:	b559                	j	ffffffffc020185a <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02019d6:	85a6                	mv	a1,s1
ffffffffc02019d8:	02d00513          	li	a0,45
ffffffffc02019dc:	e03e                	sd	a5,0(sp)
ffffffffc02019de:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02019e0:	8ace                	mv	s5,s3
ffffffffc02019e2:	40800633          	neg	a2,s0
ffffffffc02019e6:	46a9                	li	a3,10
ffffffffc02019e8:	6782                	ld	a5,0(sp)
ffffffffc02019ea:	b515                	j	ffffffffc020180e <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02019ec:	01b05663          	blez	s11,ffffffffc02019f8 <vprintfmt+0x35a>
ffffffffc02019f0:	02d00693          	li	a3,45
ffffffffc02019f4:	f6d798e3          	bne	a5,a3,ffffffffc0201964 <vprintfmt+0x2c6>
ffffffffc02019f8:	00001417          	auipc	s0,0x1
ffffffffc02019fc:	ff940413          	addi	s0,s0,-7 # ffffffffc02029f1 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a00:	02800513          	li	a0,40
ffffffffc0201a04:	02800793          	li	a5,40
ffffffffc0201a08:	bd1d                	j	ffffffffc020183e <vprintfmt+0x1a0>

ffffffffc0201a0a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a0a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201a0c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a10:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a12:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a14:	ec06                	sd	ra,24(sp)
ffffffffc0201a16:	f83a                	sd	a4,48(sp)
ffffffffc0201a18:	fc3e                	sd	a5,56(sp)
ffffffffc0201a1a:	e0c2                	sd	a6,64(sp)
ffffffffc0201a1c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201a1e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a20:	c7fff0ef          	jal	ra,ffffffffc020169e <vprintfmt>
}
ffffffffc0201a24:	60e2                	ld	ra,24(sp)
ffffffffc0201a26:	6161                	addi	sp,sp,80
ffffffffc0201a28:	8082                	ret

ffffffffc0201a2a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201a2a:	715d                	addi	sp,sp,-80
ffffffffc0201a2c:	e486                	sd	ra,72(sp)
ffffffffc0201a2e:	e0a2                	sd	s0,64(sp)
ffffffffc0201a30:	fc26                	sd	s1,56(sp)
ffffffffc0201a32:	f84a                	sd	s2,48(sp)
ffffffffc0201a34:	f44e                	sd	s3,40(sp)
ffffffffc0201a36:	f052                	sd	s4,32(sp)
ffffffffc0201a38:	ec56                	sd	s5,24(sp)
ffffffffc0201a3a:	e85a                	sd	s6,16(sp)
ffffffffc0201a3c:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201a3e:	c901                	beqz	a0,ffffffffc0201a4e <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201a40:	85aa                	mv	a1,a0
ffffffffc0201a42:	00001517          	auipc	a0,0x1
ffffffffc0201a46:	fc650513          	addi	a0,a0,-58 # ffffffffc0202a08 <error_string+0xe8>
ffffffffc0201a4a:	e6cfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc0201a4e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a50:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201a52:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201a54:	4aa9                	li	s5,10
ffffffffc0201a56:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201a58:	00004b97          	auipc	s7,0x4
ffffffffc0201a5c:	5b8b8b93          	addi	s7,s7,1464 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a60:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201a64:	ecafe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a68:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a6a:	00054b63          	bltz	a0,ffffffffc0201a80 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a6e:	00a95b63          	ble	a0,s2,ffffffffc0201a84 <readline+0x5a>
ffffffffc0201a72:	029a5463          	ble	s1,s4,ffffffffc0201a9a <readline+0x70>
        c = getchar();
ffffffffc0201a76:	eb8fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a7a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a7c:	fe0559e3          	bgez	a0,ffffffffc0201a6e <readline+0x44>
            return NULL;
ffffffffc0201a80:	4501                	li	a0,0
ffffffffc0201a82:	a099                	j	ffffffffc0201ac8 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201a84:	03341463          	bne	s0,s3,ffffffffc0201aac <readline+0x82>
ffffffffc0201a88:	e8b9                	bnez	s1,ffffffffc0201ade <readline+0xb4>
        c = getchar();
ffffffffc0201a8a:	ea4fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a8e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a90:	fe0548e3          	bltz	a0,ffffffffc0201a80 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a94:	fea958e3          	ble	a0,s2,ffffffffc0201a84 <readline+0x5a>
ffffffffc0201a98:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201a9a:	8522                	mv	a0,s0
ffffffffc0201a9c:	e4efe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201aa0:	009b87b3          	add	a5,s7,s1
ffffffffc0201aa4:	00878023          	sb	s0,0(a5)
ffffffffc0201aa8:	2485                	addiw	s1,s1,1
ffffffffc0201aaa:	bf6d                	j	ffffffffc0201a64 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201aac:	01540463          	beq	s0,s5,ffffffffc0201ab4 <readline+0x8a>
ffffffffc0201ab0:	fb641ae3          	bne	s0,s6,ffffffffc0201a64 <readline+0x3a>
            cputchar(c);
ffffffffc0201ab4:	8522                	mv	a0,s0
ffffffffc0201ab6:	e34fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201aba:	00004517          	auipc	a0,0x4
ffffffffc0201abe:	55650513          	addi	a0,a0,1366 # ffffffffc0206010 <edata>
ffffffffc0201ac2:	94aa                	add	s1,s1,a0
ffffffffc0201ac4:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ac8:	60a6                	ld	ra,72(sp)
ffffffffc0201aca:	6406                	ld	s0,64(sp)
ffffffffc0201acc:	74e2                	ld	s1,56(sp)
ffffffffc0201ace:	7942                	ld	s2,48(sp)
ffffffffc0201ad0:	79a2                	ld	s3,40(sp)
ffffffffc0201ad2:	7a02                	ld	s4,32(sp)
ffffffffc0201ad4:	6ae2                	ld	s5,24(sp)
ffffffffc0201ad6:	6b42                	ld	s6,16(sp)
ffffffffc0201ad8:	6ba2                	ld	s7,8(sp)
ffffffffc0201ada:	6161                	addi	sp,sp,80
ffffffffc0201adc:	8082                	ret
            cputchar(c);
ffffffffc0201ade:	4521                	li	a0,8
ffffffffc0201ae0:	e0afe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201ae4:	34fd                	addiw	s1,s1,-1
ffffffffc0201ae6:	bfbd                	j	ffffffffc0201a64 <readline+0x3a>

ffffffffc0201ae8 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201ae8:	00004797          	auipc	a5,0x4
ffffffffc0201aec:	52078793          	addi	a5,a5,1312 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201af0:	6398                	ld	a4,0(a5)
ffffffffc0201af2:	4781                	li	a5,0
ffffffffc0201af4:	88ba                	mv	a7,a4
ffffffffc0201af6:	852a                	mv	a0,a0
ffffffffc0201af8:	85be                	mv	a1,a5
ffffffffc0201afa:	863e                	mv	a2,a5
ffffffffc0201afc:	00000073          	ecall
ffffffffc0201b00:	87aa                	mv	a5,a0
}
ffffffffc0201b02:	8082                	ret

ffffffffc0201b04 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201b04:	00005797          	auipc	a5,0x5
ffffffffc0201b08:	92478793          	addi	a5,a5,-1756 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201b0c:	6398                	ld	a4,0(a5)
ffffffffc0201b0e:	4781                	li	a5,0
ffffffffc0201b10:	88ba                	mv	a7,a4
ffffffffc0201b12:	852a                	mv	a0,a0
ffffffffc0201b14:	85be                	mv	a1,a5
ffffffffc0201b16:	863e                	mv	a2,a5
ffffffffc0201b18:	00000073          	ecall
ffffffffc0201b1c:	87aa                	mv	a5,a0
}
ffffffffc0201b1e:	8082                	ret

ffffffffc0201b20 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201b20:	00004797          	auipc	a5,0x4
ffffffffc0201b24:	4e078793          	addi	a5,a5,1248 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201b28:	639c                	ld	a5,0(a5)
ffffffffc0201b2a:	4501                	li	a0,0
ffffffffc0201b2c:	88be                	mv	a7,a5
ffffffffc0201b2e:	852a                	mv	a0,a0
ffffffffc0201b30:	85aa                	mv	a1,a0
ffffffffc0201b32:	862a                	mv	a2,a0
ffffffffc0201b34:	00000073          	ecall
ffffffffc0201b38:	852a                	mv	a0,a0
ffffffffc0201b3a:	2501                	sext.w	a0,a0
ffffffffc0201b3c:	8082                	ret
