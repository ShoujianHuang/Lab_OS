
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	0040006f          	j	8020000c <kern_init>

000000008020000c <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000c:	00004517          	auipc	a0,0x4
    80200010:	00450513          	addi	a0,a0,4 # 80204010 <edata>
    80200014:	00004617          	auipc	a2,0x4
    80200018:	01460613          	addi	a2,a2,20 # 80204028 <end>
int kern_init(void) {
    8020001c:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001e:	8e09                	sub	a2,a2,a0
    80200020:	4581                	li	a1,0
int kern_init(void) {
    80200022:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200024:	5f4000ef          	jal	ra,80200618 <memset>

    cons_init();  // init the console
    80200028:	150000ef          	jal	ra,80200178 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002c:	00001597          	auipc	a1,0x1
    80200030:	a4c58593          	addi	a1,a1,-1460 # 80200a78 <etext+0x2>
    80200034:	00001517          	auipc	a0,0x1
    80200038:	a6450513          	addi	a0,a0,-1436 # 80200a98 <etext+0x22>
    8020003c:	034000ef          	jal	ra,80200070 <cprintf>

    print_kerninfo();
    80200040:	064000ef          	jal	ra,802000a4 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200044:	144000ef          	jal	ra,80200188 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200048:	0ec000ef          	jal	ra,80200134 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004c:	136000ef          	jal	ra,80200182 <intr_enable>
    __asm__ volatile("mret\n");
    80200050:	30200073          	mret
    while (1)
        ;
    80200054:	a001                	j	80200054 <kern_init+0x48>

0000000080200056 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200056:	1141                	addi	sp,sp,-16
    80200058:	e022                	sd	s0,0(sp)
    8020005a:	e406                	sd	ra,8(sp)
    8020005c:	842e                	mv	s0,a1
    cons_putc(c);
    8020005e:	11c000ef          	jal	ra,8020017a <cons_putc>
    (*cnt)++;
    80200062:	401c                	lw	a5,0(s0)
}
    80200064:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200066:	2785                	addiw	a5,a5,1
    80200068:	c01c                	sw	a5,0(s0)
}
    8020006a:	6402                	ld	s0,0(sp)
    8020006c:	0141                	addi	sp,sp,16
    8020006e:	8082                	ret

0000000080200070 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200070:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200072:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200076:	f42e                	sd	a1,40(sp)
    80200078:	f832                	sd	a2,48(sp)
    8020007a:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020007c:	862a                	mv	a2,a0
    8020007e:	004c                	addi	a1,sp,4
    80200080:	00000517          	auipc	a0,0x0
    80200084:	fd650513          	addi	a0,a0,-42 # 80200056 <cputch>
    80200088:	869a                	mv	a3,t1
int cprintf(const char *fmt, ...) {
    8020008a:	ec06                	sd	ra,24(sp)
    8020008c:	e0ba                	sd	a4,64(sp)
    8020008e:	e4be                	sd	a5,72(sp)
    80200090:	e8c2                	sd	a6,80(sp)
    80200092:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200094:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200096:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200098:	5fe000ef          	jal	ra,80200696 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    8020009c:	60e2                	ld	ra,24(sp)
    8020009e:	4512                	lw	a0,4(sp)
    802000a0:	6125                	addi	sp,sp,96
    802000a2:	8082                	ret

00000000802000a4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a6:	00001517          	auipc	a0,0x1
    802000aa:	9fa50513          	addi	a0,a0,-1542 # 80200aa0 <etext+0x2a>
void print_kerninfo(void) {
    802000ae:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000b0:	fc1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b4:	00000597          	auipc	a1,0x0
    802000b8:	f5858593          	addi	a1,a1,-168 # 8020000c <kern_init>
    802000bc:	00001517          	auipc	a0,0x1
    802000c0:	a0450513          	addi	a0,a0,-1532 # 80200ac0 <etext+0x4a>
    802000c4:	fadff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000c8:	00001597          	auipc	a1,0x1
    802000cc:	9ae58593          	addi	a1,a1,-1618 # 80200a76 <etext>
    802000d0:	00001517          	auipc	a0,0x1
    802000d4:	a1050513          	addi	a0,a0,-1520 # 80200ae0 <etext+0x6a>
    802000d8:	f99ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000dc:	00004597          	auipc	a1,0x4
    802000e0:	f3458593          	addi	a1,a1,-204 # 80204010 <edata>
    802000e4:	00001517          	auipc	a0,0x1
    802000e8:	a1c50513          	addi	a0,a0,-1508 # 80200b00 <etext+0x8a>
    802000ec:	f85ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000f0:	00004597          	auipc	a1,0x4
    802000f4:	f3858593          	addi	a1,a1,-200 # 80204028 <end>
    802000f8:	00001517          	auipc	a0,0x1
    802000fc:	a2850513          	addi	a0,a0,-1496 # 80200b20 <etext+0xaa>
    80200100:	f71ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200104:	00004597          	auipc	a1,0x4
    80200108:	32358593          	addi	a1,a1,803 # 80204427 <end+0x3ff>
    8020010c:	00000797          	auipc	a5,0x0
    80200110:	f0078793          	addi	a5,a5,-256 # 8020000c <kern_init>
    80200114:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200118:	43f7d593          	srai	a1,a5,0x3f
}
    8020011c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011e:	3ff5f593          	andi	a1,a1,1023
    80200122:	95be                	add	a1,a1,a5
    80200124:	85a9                	srai	a1,a1,0xa
    80200126:	00001517          	auipc	a0,0x1
    8020012a:	a1a50513          	addi	a0,a0,-1510 # 80200b40 <etext+0xca>
}
    8020012e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200130:	f41ff06f          	j	80200070 <cprintf>

0000000080200134 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200134:	1141                	addi	sp,sp,-16
    80200136:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200138:	02000793          	li	a5,32
    8020013c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200140:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200144:	67e1                	lui	a5,0x18
    80200146:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    8020014a:	953e                	add	a0,a0,a5
    8020014c:	0f3000ef          	jal	ra,80200a3e <sbi_set_timer>
}
    80200150:	60a2                	ld	ra,8(sp)
    ticks = 0;
    80200152:	00004797          	auipc	a5,0x4
    80200156:	ec07b723          	sd	zero,-306(a5) # 80204020 <ticks>
    cprintf("++ setup timer interrupts\n");
    8020015a:	00001517          	auipc	a0,0x1
    8020015e:	a1650513          	addi	a0,a0,-1514 # 80200b70 <etext+0xfa>
}
    80200162:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200164:	f0dff06f          	j	80200070 <cprintf>

0000000080200168 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200168:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020016c:	67e1                	lui	a5,0x18
    8020016e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0x801e7960>
    80200172:	953e                	add	a0,a0,a5
    80200174:	0cb0006f          	j	80200a3e <sbi_set_timer>

0000000080200178 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200178:	8082                	ret

000000008020017a <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    8020017a:	0ff57513          	andi	a0,a0,255
    8020017e:	0a50006f          	j	80200a22 <sbi_console_putchar>

0000000080200182 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    80200182:	100167f3          	csrrsi	a5,sstatus,2
    80200186:	8082                	ret

0000000080200188 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200188:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    8020018c:	00000797          	auipc	a5,0x0
    80200190:	3b078793          	addi	a5,a5,944 # 8020053c <__alltraps>
    80200194:	10579073          	csrw	stvec,a5
}
    80200198:	8082                	ret

000000008020019a <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    8020019a:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    8020019c:	1141                	addi	sp,sp,-16
    8020019e:	e022                	sd	s0,0(sp)
    802001a0:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a2:	00001517          	auipc	a0,0x1
    802001a6:	b5650513          	addi	a0,a0,-1194 # 80200cf8 <etext+0x282>
void print_regs(struct pushregs *gpr) {
    802001aa:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001ac:	ec5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001b0:	640c                	ld	a1,8(s0)
    802001b2:	00001517          	auipc	a0,0x1
    802001b6:	b5e50513          	addi	a0,a0,-1186 # 80200d10 <etext+0x29a>
    802001ba:	eb7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001be:	680c                	ld	a1,16(s0)
    802001c0:	00001517          	auipc	a0,0x1
    802001c4:	b6850513          	addi	a0,a0,-1176 # 80200d28 <etext+0x2b2>
    802001c8:	ea9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001cc:	6c0c                	ld	a1,24(s0)
    802001ce:	00001517          	auipc	a0,0x1
    802001d2:	b7250513          	addi	a0,a0,-1166 # 80200d40 <etext+0x2ca>
    802001d6:	e9bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001da:	700c                	ld	a1,32(s0)
    802001dc:	00001517          	auipc	a0,0x1
    802001e0:	b7c50513          	addi	a0,a0,-1156 # 80200d58 <etext+0x2e2>
    802001e4:	e8dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e8:	740c                	ld	a1,40(s0)
    802001ea:	00001517          	auipc	a0,0x1
    802001ee:	b8650513          	addi	a0,a0,-1146 # 80200d70 <etext+0x2fa>
    802001f2:	e7fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f6:	780c                	ld	a1,48(s0)
    802001f8:	00001517          	auipc	a0,0x1
    802001fc:	b9050513          	addi	a0,a0,-1136 # 80200d88 <etext+0x312>
    80200200:	e71ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200204:	7c0c                	ld	a1,56(s0)
    80200206:	00001517          	auipc	a0,0x1
    8020020a:	b9a50513          	addi	a0,a0,-1126 # 80200da0 <etext+0x32a>
    8020020e:	e63ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    80200212:	602c                	ld	a1,64(s0)
    80200214:	00001517          	auipc	a0,0x1
    80200218:	ba450513          	addi	a0,a0,-1116 # 80200db8 <etext+0x342>
    8020021c:	e55ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    80200220:	642c                	ld	a1,72(s0)
    80200222:	00001517          	auipc	a0,0x1
    80200226:	bae50513          	addi	a0,a0,-1106 # 80200dd0 <etext+0x35a>
    8020022a:	e47ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    8020022e:	682c                	ld	a1,80(s0)
    80200230:	00001517          	auipc	a0,0x1
    80200234:	bb850513          	addi	a0,a0,-1096 # 80200de8 <etext+0x372>
    80200238:	e39ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    8020023c:	6c2c                	ld	a1,88(s0)
    8020023e:	00001517          	auipc	a0,0x1
    80200242:	bc250513          	addi	a0,a0,-1086 # 80200e00 <etext+0x38a>
    80200246:	e2bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    8020024a:	702c                	ld	a1,96(s0)
    8020024c:	00001517          	auipc	a0,0x1
    80200250:	bcc50513          	addi	a0,a0,-1076 # 80200e18 <etext+0x3a2>
    80200254:	e1dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200258:	742c                	ld	a1,104(s0)
    8020025a:	00001517          	auipc	a0,0x1
    8020025e:	bd650513          	addi	a0,a0,-1066 # 80200e30 <etext+0x3ba>
    80200262:	e0fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200266:	782c                	ld	a1,112(s0)
    80200268:	00001517          	auipc	a0,0x1
    8020026c:	be050513          	addi	a0,a0,-1056 # 80200e48 <etext+0x3d2>
    80200270:	e01ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200274:	7c2c                	ld	a1,120(s0)
    80200276:	00001517          	auipc	a0,0x1
    8020027a:	bea50513          	addi	a0,a0,-1046 # 80200e60 <etext+0x3ea>
    8020027e:	df3ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    80200282:	604c                	ld	a1,128(s0)
    80200284:	00001517          	auipc	a0,0x1
    80200288:	bf450513          	addi	a0,a0,-1036 # 80200e78 <etext+0x402>
    8020028c:	de5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    80200290:	644c                	ld	a1,136(s0)
    80200292:	00001517          	auipc	a0,0x1
    80200296:	bfe50513          	addi	a0,a0,-1026 # 80200e90 <etext+0x41a>
    8020029a:	dd7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    8020029e:	684c                	ld	a1,144(s0)
    802002a0:	00001517          	auipc	a0,0x1
    802002a4:	c0850513          	addi	a0,a0,-1016 # 80200ea8 <etext+0x432>
    802002a8:	dc9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002ac:	6c4c                	ld	a1,152(s0)
    802002ae:	00001517          	auipc	a0,0x1
    802002b2:	c1250513          	addi	a0,a0,-1006 # 80200ec0 <etext+0x44a>
    802002b6:	dbbff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002ba:	704c                	ld	a1,160(s0)
    802002bc:	00001517          	auipc	a0,0x1
    802002c0:	c1c50513          	addi	a0,a0,-996 # 80200ed8 <etext+0x462>
    802002c4:	dadff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c8:	744c                	ld	a1,168(s0)
    802002ca:	00001517          	auipc	a0,0x1
    802002ce:	c2650513          	addi	a0,a0,-986 # 80200ef0 <etext+0x47a>
    802002d2:	d9fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d6:	784c                	ld	a1,176(s0)
    802002d8:	00001517          	auipc	a0,0x1
    802002dc:	c3050513          	addi	a0,a0,-976 # 80200f08 <etext+0x492>
    802002e0:	d91ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e4:	7c4c                	ld	a1,184(s0)
    802002e6:	00001517          	auipc	a0,0x1
    802002ea:	c3a50513          	addi	a0,a0,-966 # 80200f20 <etext+0x4aa>
    802002ee:	d83ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002f2:	606c                	ld	a1,192(s0)
    802002f4:	00001517          	auipc	a0,0x1
    802002f8:	c4450513          	addi	a0,a0,-956 # 80200f38 <etext+0x4c2>
    802002fc:	d75ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    80200300:	646c                	ld	a1,200(s0)
    80200302:	00001517          	auipc	a0,0x1
    80200306:	c4e50513          	addi	a0,a0,-946 # 80200f50 <etext+0x4da>
    8020030a:	d67ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    8020030e:	686c                	ld	a1,208(s0)
    80200310:	00001517          	auipc	a0,0x1
    80200314:	c5850513          	addi	a0,a0,-936 # 80200f68 <etext+0x4f2>
    80200318:	d59ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    8020031c:	6c6c                	ld	a1,216(s0)
    8020031e:	00001517          	auipc	a0,0x1
    80200322:	c6250513          	addi	a0,a0,-926 # 80200f80 <etext+0x50a>
    80200326:	d4bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    8020032a:	706c                	ld	a1,224(s0)
    8020032c:	00001517          	auipc	a0,0x1
    80200330:	c6c50513          	addi	a0,a0,-916 # 80200f98 <etext+0x522>
    80200334:	d3dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200338:	746c                	ld	a1,232(s0)
    8020033a:	00001517          	auipc	a0,0x1
    8020033e:	c7650513          	addi	a0,a0,-906 # 80200fb0 <etext+0x53a>
    80200342:	d2fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200346:	786c                	ld	a1,240(s0)
    80200348:	00001517          	auipc	a0,0x1
    8020034c:	c8050513          	addi	a0,a0,-896 # 80200fc8 <etext+0x552>
    80200350:	d21ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200354:	7c6c                	ld	a1,248(s0)
}
    80200356:	6402                	ld	s0,0(sp)
    80200358:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    8020035a:	00001517          	auipc	a0,0x1
    8020035e:	c8650513          	addi	a0,a0,-890 # 80200fe0 <etext+0x56a>
}
    80200362:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200364:	d0dff06f          	j	80200070 <cprintf>

0000000080200368 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    80200368:	1141                	addi	sp,sp,-16
    8020036a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    8020036c:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    8020036e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    80200370:	00001517          	auipc	a0,0x1
    80200374:	c8850513          	addi	a0,a0,-888 # 80200ff8 <etext+0x582>
void print_trapframe(struct trapframe *tf) {
    80200378:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    8020037a:	cf7ff0ef          	jal	ra,80200070 <cprintf>
    print_regs(&tf->gpr);
    8020037e:	8522                	mv	a0,s0
    80200380:	e1bff0ef          	jal	ra,8020019a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200384:	10043583          	ld	a1,256(s0)
    80200388:	00001517          	auipc	a0,0x1
    8020038c:	c8850513          	addi	a0,a0,-888 # 80201010 <etext+0x59a>
    80200390:	ce1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200394:	10843583          	ld	a1,264(s0)
    80200398:	00001517          	auipc	a0,0x1
    8020039c:	c9050513          	addi	a0,a0,-880 # 80201028 <etext+0x5b2>
    802003a0:	cd1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a4:	11043583          	ld	a1,272(s0)
    802003a8:	00001517          	auipc	a0,0x1
    802003ac:	c9850513          	addi	a0,a0,-872 # 80201040 <etext+0x5ca>
    802003b0:	cc1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b4:	11843583          	ld	a1,280(s0)
}
    802003b8:	6402                	ld	s0,0(sp)
    802003ba:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003bc:	00001517          	auipc	a0,0x1
    802003c0:	c9c50513          	addi	a0,a0,-868 # 80201058 <etext+0x5e2>
}
    802003c4:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c6:	cabff06f          	j	80200070 <cprintf>

00000000802003ca <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003ca:	11853783          	ld	a5,280(a0)
    802003ce:	577d                	li	a4,-1
    802003d0:	8305                	srli	a4,a4,0x1
    802003d2:	8ff9                	and	a5,a5,a4
    switch (cause) {
    802003d4:	472d                	li	a4,11
    802003d6:	06f76f63          	bltu	a4,a5,80200454 <interrupt_handler+0x8a>
    802003da:	00000717          	auipc	a4,0x0
    802003de:	7b270713          	addi	a4,a4,1970 # 80200b8c <etext+0x116>
    802003e2:	078a                	slli	a5,a5,0x2
    802003e4:	97ba                	add	a5,a5,a4
    802003e6:	439c                	lw	a5,0(a5)
    802003e8:	97ba                	add	a5,a5,a4
    802003ea:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003ec:	00001517          	auipc	a0,0x1
    802003f0:	8bc50513          	addi	a0,a0,-1860 # 80200ca8 <etext+0x232>
    802003f4:	c7dff06f          	j	80200070 <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003f8:	00001517          	auipc	a0,0x1
    802003fc:	89050513          	addi	a0,a0,-1904 # 80200c88 <etext+0x212>
    80200400:	c71ff06f          	j	80200070 <cprintf>
            cprintf("User software interrupt\n");
    80200404:	00001517          	auipc	a0,0x1
    80200408:	84450513          	addi	a0,a0,-1980 # 80200c48 <etext+0x1d2>
    8020040c:	c65ff06f          	j	80200070 <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200410:	00001517          	auipc	a0,0x1
    80200414:	85850513          	addi	a0,a0,-1960 # 80200c68 <etext+0x1f2>
    80200418:	c59ff06f          	j	80200070 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
    8020041c:	00001517          	auipc	a0,0x1
    80200420:	8bc50513          	addi	a0,a0,-1860 # 80200cd8 <etext+0x262>
    80200424:	c4dff06f          	j	80200070 <cprintf>
void interrupt_handler(struct trapframe *tf) {
    80200428:	1141                	addi	sp,sp,-16
    8020042a:	e406                	sd	ra,8(sp)
            clock_set_next_event();
    8020042c:	d3dff0ef          	jal	ra,80200168 <clock_set_next_event>
            ticks++;
    80200430:	00004717          	auipc	a4,0x4
    80200434:	bf070713          	addi	a4,a4,-1040 # 80204020 <ticks>
    80200438:	631c                	ld	a5,0(a4)
            if(ticks==100){
    8020043a:	06400693          	li	a3,100
            ticks++;
    8020043e:	0785                	addi	a5,a5,1
    80200440:	00004617          	auipc	a2,0x4
    80200444:	bef63023          	sd	a5,-1056(a2) # 80204020 <ticks>
            if(ticks==100){
    80200448:	631c                	ld	a5,0(a4)
    8020044a:	00d78763          	beq	a5,a3,80200458 <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    8020044e:	60a2                	ld	ra,8(sp)
    80200450:	0141                	addi	sp,sp,16
    80200452:	8082                	ret
            print_trapframe(tf);
    80200454:	f15ff06f          	j	80200368 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    80200458:	06400593          	li	a1,100
    8020045c:	00001517          	auipc	a0,0x1
    80200460:	86c50513          	addi	a0,a0,-1940 # 80200cc8 <etext+0x252>
    80200464:	c0dff0ef          	jal	ra,80200070 <cprintf>
                num ++;
    80200468:	00004717          	auipc	a4,0x4
    8020046c:	ba870713          	addi	a4,a4,-1112 # 80204010 <edata>
    80200470:	631c                	ld	a5,0(a4)
                if(num==10){
    80200472:	46a9                	li	a3,10
                num ++;
    80200474:	0785                	addi	a5,a5,1
    80200476:	00004617          	auipc	a2,0x4
    8020047a:	b8f63d23          	sd	a5,-1126(a2) # 80204010 <edata>
                ticks = 0;
    8020047e:	00004797          	auipc	a5,0x4
    80200482:	ba07b123          	sd	zero,-1118(a5) # 80204020 <ticks>
                if(num==10){
    80200486:	631c                	ld	a5,0(a4)
    80200488:	fcd793e3          	bne	a5,a3,8020044e <interrupt_handler+0x84>
}
    8020048c:	60a2                	ld	ra,8(sp)
    8020048e:	0141                	addi	sp,sp,16
                    sbi_shutdown();
    80200490:	5ca0006f          	j	80200a5a <sbi_shutdown>

0000000080200494 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    80200494:	11853783          	ld	a5,280(a0)
    80200498:	472d                	li	a4,11
    8020049a:	02f76863          	bltu	a4,a5,802004ca <exception_handler+0x36>
    8020049e:	4705                	li	a4,1
    802004a0:	00f71733          	sll	a4,a4,a5
    802004a4:	6785                	lui	a5,0x1
    802004a6:	17cd                	addi	a5,a5,-13
    802004a8:	8ff9                	and	a5,a5,a4
    802004aa:	ef99                	bnez	a5,802004c8 <exception_handler+0x34>
void exception_handler(struct trapframe *tf) {
    802004ac:	1141                	addi	sp,sp,-16
    802004ae:	e022                	sd	s0,0(sp)
    802004b0:	e406                	sd	ra,8(sp)
    802004b2:	00877793          	andi	a5,a4,8
    802004b6:	842a                	mv	s0,a0
    802004b8:	e3b1                	bnez	a5,802004fc <exception_handler+0x68>
    802004ba:	8b11                	andi	a4,a4,4
    802004bc:	eb09                	bnez	a4,802004ce <exception_handler+0x3a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802004be:	6402                	ld	s0,0(sp)
    802004c0:	60a2                	ld	ra,8(sp)
    802004c2:	0141                	addi	sp,sp,16
            print_trapframe(tf);
    802004c4:	ea5ff06f          	j	80200368 <print_trapframe>
    802004c8:	8082                	ret
    802004ca:	e9fff06f          	j	80200368 <print_trapframe>
            cprintf("Illegal instruction caught at 0x%x\n",tf->epc);
    802004ce:	10853583          	ld	a1,264(a0)
    802004d2:	00000517          	auipc	a0,0x0
    802004d6:	6ee50513          	addi	a0,a0,1774 # 80200bc0 <etext+0x14a>
    802004da:	b97ff0ef          	jal	ra,80200070 <cprintf>
            cprintf("Exception type:Illegal instruction\n");
    802004de:	00000517          	auipc	a0,0x0
    802004e2:	70a50513          	addi	a0,a0,1802 # 80200be8 <etext+0x172>
    802004e6:	b8bff0ef          	jal	ra,80200070 <cprintf>
            tf->epc ++;
    802004ea:	10843783          	ld	a5,264(s0)
}
    802004ee:	60a2                	ld	ra,8(sp)
            tf->epc ++;
    802004f0:	0785                	addi	a5,a5,1
    802004f2:	10f43423          	sd	a5,264(s0)
}
    802004f6:	6402                	ld	s0,0(sp)
    802004f8:	0141                	addi	sp,sp,16
    802004fa:	8082                	ret
            cprintf("ebreak caught at 0x%x\n",tf->epc);
    802004fc:	10853583          	ld	a1,264(a0)
    80200500:	00000517          	auipc	a0,0x0
    80200504:	71050513          	addi	a0,a0,1808 # 80200c10 <etext+0x19a>
    80200508:	b69ff0ef          	jal	ra,80200070 <cprintf>
            cprintf("Exception type: breakpoint\n");
    8020050c:	00000517          	auipc	a0,0x0
    80200510:	71c50513          	addi	a0,a0,1820 # 80200c28 <etext+0x1b2>
    80200514:	b5dff0ef          	jal	ra,80200070 <cprintf>
            tf->epc ++;
    80200518:	10843783          	ld	a5,264(s0)
}
    8020051c:	60a2                	ld	ra,8(sp)
            tf->epc ++;
    8020051e:	0785                	addi	a5,a5,1
    80200520:	10f43423          	sd	a5,264(s0)
}
    80200524:	6402                	ld	s0,0(sp)
    80200526:	0141                	addi	sp,sp,16
    80200528:	8082                	ret

000000008020052a <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    8020052a:	11853783          	ld	a5,280(a0)
    8020052e:	0007c463          	bltz	a5,80200536 <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    80200532:	f63ff06f          	j	80200494 <exception_handler>
        interrupt_handler(tf);
    80200536:	e95ff06f          	j	802003ca <interrupt_handler>
	...

000000008020053c <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    8020053c:	14011073          	csrw	sscratch,sp
    80200540:	712d                	addi	sp,sp,-288
    80200542:	e002                	sd	zero,0(sp)
    80200544:	e406                	sd	ra,8(sp)
    80200546:	ec0e                	sd	gp,24(sp)
    80200548:	f012                	sd	tp,32(sp)
    8020054a:	f416                	sd	t0,40(sp)
    8020054c:	f81a                	sd	t1,48(sp)
    8020054e:	fc1e                	sd	t2,56(sp)
    80200550:	e0a2                	sd	s0,64(sp)
    80200552:	e4a6                	sd	s1,72(sp)
    80200554:	e8aa                	sd	a0,80(sp)
    80200556:	ecae                	sd	a1,88(sp)
    80200558:	f0b2                	sd	a2,96(sp)
    8020055a:	f4b6                	sd	a3,104(sp)
    8020055c:	f8ba                	sd	a4,112(sp)
    8020055e:	fcbe                	sd	a5,120(sp)
    80200560:	e142                	sd	a6,128(sp)
    80200562:	e546                	sd	a7,136(sp)
    80200564:	e94a                	sd	s2,144(sp)
    80200566:	ed4e                	sd	s3,152(sp)
    80200568:	f152                	sd	s4,160(sp)
    8020056a:	f556                	sd	s5,168(sp)
    8020056c:	f95a                	sd	s6,176(sp)
    8020056e:	fd5e                	sd	s7,184(sp)
    80200570:	e1e2                	sd	s8,192(sp)
    80200572:	e5e6                	sd	s9,200(sp)
    80200574:	e9ea                	sd	s10,208(sp)
    80200576:	edee                	sd	s11,216(sp)
    80200578:	f1f2                	sd	t3,224(sp)
    8020057a:	f5f6                	sd	t4,232(sp)
    8020057c:	f9fa                	sd	t5,240(sp)
    8020057e:	fdfe                	sd	t6,248(sp)
    80200580:	14001473          	csrrw	s0,sscratch,zero
    80200584:	100024f3          	csrr	s1,sstatus
    80200588:	14102973          	csrr	s2,sepc
    8020058c:	143029f3          	csrr	s3,stval
    80200590:	14202a73          	csrr	s4,scause
    80200594:	e822                	sd	s0,16(sp)
    80200596:	e226                	sd	s1,256(sp)
    80200598:	e64a                	sd	s2,264(sp)
    8020059a:	ea4e                	sd	s3,272(sp)
    8020059c:	ee52                	sd	s4,280(sp)

    move  a0, sp
    8020059e:	850a                	mv	a0,sp
    jal trap
    802005a0:	f8bff0ef          	jal	ra,8020052a <trap>

00000000802005a4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    802005a4:	6492                	ld	s1,256(sp)
    802005a6:	6932                	ld	s2,264(sp)
    802005a8:	10049073          	csrw	sstatus,s1
    802005ac:	14191073          	csrw	sepc,s2
    802005b0:	60a2                	ld	ra,8(sp)
    802005b2:	61e2                	ld	gp,24(sp)
    802005b4:	7202                	ld	tp,32(sp)
    802005b6:	72a2                	ld	t0,40(sp)
    802005b8:	7342                	ld	t1,48(sp)
    802005ba:	73e2                	ld	t2,56(sp)
    802005bc:	6406                	ld	s0,64(sp)
    802005be:	64a6                	ld	s1,72(sp)
    802005c0:	6546                	ld	a0,80(sp)
    802005c2:	65e6                	ld	a1,88(sp)
    802005c4:	7606                	ld	a2,96(sp)
    802005c6:	76a6                	ld	a3,104(sp)
    802005c8:	7746                	ld	a4,112(sp)
    802005ca:	77e6                	ld	a5,120(sp)
    802005cc:	680a                	ld	a6,128(sp)
    802005ce:	68aa                	ld	a7,136(sp)
    802005d0:	694a                	ld	s2,144(sp)
    802005d2:	69ea                	ld	s3,152(sp)
    802005d4:	7a0a                	ld	s4,160(sp)
    802005d6:	7aaa                	ld	s5,168(sp)
    802005d8:	7b4a                	ld	s6,176(sp)
    802005da:	7bea                	ld	s7,184(sp)
    802005dc:	6c0e                	ld	s8,192(sp)
    802005de:	6cae                	ld	s9,200(sp)
    802005e0:	6d4e                	ld	s10,208(sp)
    802005e2:	6dee                	ld	s11,216(sp)
    802005e4:	7e0e                	ld	t3,224(sp)
    802005e6:	7eae                	ld	t4,232(sp)
    802005e8:	7f4e                	ld	t5,240(sp)
    802005ea:	7fee                	ld	t6,248(sp)
    802005ec:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    802005ee:	10200073          	sret

00000000802005f2 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
    802005f2:	c185                	beqz	a1,80200612 <strnlen+0x20>
    802005f4:	00054783          	lbu	a5,0(a0)
    802005f8:	cf89                	beqz	a5,80200612 <strnlen+0x20>
    size_t cnt = 0;
    802005fa:	4781                	li	a5,0
    802005fc:	a021                	j	80200604 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
    802005fe:	00074703          	lbu	a4,0(a4)
    80200602:	c711                	beqz	a4,8020060e <strnlen+0x1c>
        cnt ++;
    80200604:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    80200606:	00f50733          	add	a4,a0,a5
    8020060a:	fef59ae3          	bne	a1,a5,802005fe <strnlen+0xc>
    }
    return cnt;
}
    8020060e:	853e                	mv	a0,a5
    80200610:	8082                	ret
    size_t cnt = 0;
    80200612:	4781                	li	a5,0
}
    80200614:	853e                	mv	a0,a5
    80200616:	8082                	ret

0000000080200618 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    80200618:	ca01                	beqz	a2,80200628 <memset+0x10>
    8020061a:	962a                	add	a2,a2,a0
    char *p = s;
    8020061c:	87aa                	mv	a5,a0
        *p ++ = c;
    8020061e:	0785                	addi	a5,a5,1
    80200620:	feb78fa3          	sb	a1,-1(a5) # fff <BASE_ADDRESS-0x801ff001>
    while (n -- > 0) {
    80200624:	fec79de3          	bne	a5,a2,8020061e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    80200628:	8082                	ret

000000008020062a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    8020062a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020062e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200630:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200634:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    80200636:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    8020063a:	f022                	sd	s0,32(sp)
    8020063c:	ec26                	sd	s1,24(sp)
    8020063e:	e84a                	sd	s2,16(sp)
    80200640:	f406                	sd	ra,40(sp)
    80200642:	e44e                	sd	s3,8(sp)
    80200644:	84aa                	mv	s1,a0
    80200646:	892e                	mv	s2,a1
    80200648:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    8020064c:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
    8020064e:	03067e63          	bleu	a6,a2,8020068a <printnum+0x60>
    80200652:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    80200654:	00805763          	blez	s0,80200662 <printnum+0x38>
    80200658:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    8020065a:	85ca                	mv	a1,s2
    8020065c:	854e                	mv	a0,s3
    8020065e:	9482                	jalr	s1
        while (-- width > 0)
    80200660:	fc65                	bnez	s0,80200658 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    80200662:	1a02                	slli	s4,s4,0x20
    80200664:	020a5a13          	srli	s4,s4,0x20
    80200668:	00001797          	auipc	a5,0x1
    8020066c:	b9878793          	addi	a5,a5,-1128 # 80201200 <error_string+0x38>
    80200670:	9a3e                	add	s4,s4,a5
}
    80200672:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    80200674:	000a4503          	lbu	a0,0(s4)
}
    80200678:	70a2                	ld	ra,40(sp)
    8020067a:	69a2                	ld	s3,8(sp)
    8020067c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    8020067e:	85ca                	mv	a1,s2
    80200680:	8326                	mv	t1,s1
}
    80200682:	6942                	ld	s2,16(sp)
    80200684:	64e2                	ld	s1,24(sp)
    80200686:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    80200688:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
    8020068a:	03065633          	divu	a2,a2,a6
    8020068e:	8722                	mv	a4,s0
    80200690:	f9bff0ef          	jal	ra,8020062a <printnum>
    80200694:	b7f9                	j	80200662 <printnum+0x38>

0000000080200696 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200696:	7119                	addi	sp,sp,-128
    80200698:	f4a6                	sd	s1,104(sp)
    8020069a:	f0ca                	sd	s2,96(sp)
    8020069c:	e8d2                	sd	s4,80(sp)
    8020069e:	e4d6                	sd	s5,72(sp)
    802006a0:	e0da                	sd	s6,64(sp)
    802006a2:	fc5e                	sd	s7,56(sp)
    802006a4:	f862                	sd	s8,48(sp)
    802006a6:	f06a                	sd	s10,32(sp)
    802006a8:	fc86                	sd	ra,120(sp)
    802006aa:	f8a2                	sd	s0,112(sp)
    802006ac:	ecce                	sd	s3,88(sp)
    802006ae:	f466                	sd	s9,40(sp)
    802006b0:	ec6e                	sd	s11,24(sp)
    802006b2:	892a                	mv	s2,a0
    802006b4:	84ae                	mv	s1,a1
    802006b6:	8d32                	mv	s10,a2
    802006b8:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    802006ba:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
    802006bc:	00001a17          	auipc	s4,0x1
    802006c0:	9b0a0a13          	addi	s4,s4,-1616 # 8020106c <etext+0x5f6>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
    802006c4:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802006c8:	00001c17          	auipc	s8,0x1
    802006cc:	b00c0c13          	addi	s8,s8,-1280 # 802011c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006d0:	000d4503          	lbu	a0,0(s10)
    802006d4:	02500793          	li	a5,37
    802006d8:	001d0413          	addi	s0,s10,1
    802006dc:	00f50e63          	beq	a0,a5,802006f8 <vprintfmt+0x62>
            if (ch == '\0') {
    802006e0:	c521                	beqz	a0,80200728 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006e2:	02500993          	li	s3,37
    802006e6:	a011                	j	802006ea <vprintfmt+0x54>
            if (ch == '\0') {
    802006e8:	c121                	beqz	a0,80200728 <vprintfmt+0x92>
            putch(ch, putdat);
    802006ea:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006ec:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    802006ee:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    802006f0:	fff44503          	lbu	a0,-1(s0)
    802006f4:	ff351ae3          	bne	a0,s3,802006e8 <vprintfmt+0x52>
    802006f8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    802006fc:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200700:	4981                	li	s3,0
    80200702:	4801                	li	a6,0
        width = precision = -1;
    80200704:	5cfd                	li	s9,-1
    80200706:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
    80200708:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
    8020070c:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
    8020070e:	fdd6069b          	addiw	a3,a2,-35
    80200712:	0ff6f693          	andi	a3,a3,255
    80200716:	00140d13          	addi	s10,s0,1
    8020071a:	20d5e563          	bltu	a1,a3,80200924 <vprintfmt+0x28e>
    8020071e:	068a                	slli	a3,a3,0x2
    80200720:	96d2                	add	a3,a3,s4
    80200722:	4294                	lw	a3,0(a3)
    80200724:	96d2                	add	a3,a3,s4
    80200726:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200728:	70e6                	ld	ra,120(sp)
    8020072a:	7446                	ld	s0,112(sp)
    8020072c:	74a6                	ld	s1,104(sp)
    8020072e:	7906                	ld	s2,96(sp)
    80200730:	69e6                	ld	s3,88(sp)
    80200732:	6a46                	ld	s4,80(sp)
    80200734:	6aa6                	ld	s5,72(sp)
    80200736:	6b06                	ld	s6,64(sp)
    80200738:	7be2                	ld	s7,56(sp)
    8020073a:	7c42                	ld	s8,48(sp)
    8020073c:	7ca2                	ld	s9,40(sp)
    8020073e:	7d02                	ld	s10,32(sp)
    80200740:	6de2                	ld	s11,24(sp)
    80200742:	6109                	addi	sp,sp,128
    80200744:	8082                	ret
    if (lflag >= 2) {
    80200746:	4705                	li	a4,1
    80200748:	008a8593          	addi	a1,s5,8
    8020074c:	01074463          	blt	a4,a6,80200754 <vprintfmt+0xbe>
    else if (lflag) {
    80200750:	26080363          	beqz	a6,802009b6 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
    80200754:	000ab603          	ld	a2,0(s5)
    80200758:	46c1                	li	a3,16
    8020075a:	8aae                	mv	s5,a1
    8020075c:	a06d                	j	80200806 <vprintfmt+0x170>
            goto reswitch;
    8020075e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200762:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200764:	846a                	mv	s0,s10
            goto reswitch;
    80200766:	b765                	j	8020070e <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
    80200768:	000aa503          	lw	a0,0(s5)
    8020076c:	85a6                	mv	a1,s1
    8020076e:	0aa1                	addi	s5,s5,8
    80200770:	9902                	jalr	s2
            break;
    80200772:	bfb9                	j	802006d0 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200774:	4705                	li	a4,1
    80200776:	008a8993          	addi	s3,s5,8
    8020077a:	01074463          	blt	a4,a6,80200782 <vprintfmt+0xec>
    else if (lflag) {
    8020077e:	22080463          	beqz	a6,802009a6 <vprintfmt+0x310>
        return va_arg(*ap, long);
    80200782:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
    80200786:	24044463          	bltz	s0,802009ce <vprintfmt+0x338>
            num = getint(&ap, lflag);
    8020078a:	8622                	mv	a2,s0
    8020078c:	8ace                	mv	s5,s3
    8020078e:	46a9                	li	a3,10
    80200790:	a89d                	j	80200806 <vprintfmt+0x170>
            err = va_arg(ap, int);
    80200792:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200796:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200798:	0aa1                	addi	s5,s5,8
            if (err < 0) {
    8020079a:	41f7d69b          	sraiw	a3,a5,0x1f
    8020079e:	8fb5                	xor	a5,a5,a3
    802007a0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    802007a4:	1ad74363          	blt	a4,a3,8020094a <vprintfmt+0x2b4>
    802007a8:	00369793          	slli	a5,a3,0x3
    802007ac:	97e2                	add	a5,a5,s8
    802007ae:	639c                	ld	a5,0(a5)
    802007b0:	18078d63          	beqz	a5,8020094a <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
    802007b4:	86be                	mv	a3,a5
    802007b6:	00001617          	auipc	a2,0x1
    802007ba:	afa60613          	addi	a2,a2,-1286 # 802012b0 <error_string+0xe8>
    802007be:	85a6                	mv	a1,s1
    802007c0:	854a                	mv	a0,s2
    802007c2:	240000ef          	jal	ra,80200a02 <printfmt>
    802007c6:	b729                	j	802006d0 <vprintfmt+0x3a>
            lflag ++;
    802007c8:	00144603          	lbu	a2,1(s0)
    802007cc:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
    802007ce:	846a                	mv	s0,s10
            goto reswitch;
    802007d0:	bf3d                	j	8020070e <vprintfmt+0x78>
    if (lflag >= 2) {
    802007d2:	4705                	li	a4,1
    802007d4:	008a8593          	addi	a1,s5,8
    802007d8:	01074463          	blt	a4,a6,802007e0 <vprintfmt+0x14a>
    else if (lflag) {
    802007dc:	1e080263          	beqz	a6,802009c0 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
    802007e0:	000ab603          	ld	a2,0(s5)
    802007e4:	46a1                	li	a3,8
    802007e6:	8aae                	mv	s5,a1
    802007e8:	a839                	j	80200806 <vprintfmt+0x170>
            putch('0', putdat);
    802007ea:	03000513          	li	a0,48
    802007ee:	85a6                	mv	a1,s1
    802007f0:	e03e                	sd	a5,0(sp)
    802007f2:	9902                	jalr	s2
            putch('x', putdat);
    802007f4:	85a6                	mv	a1,s1
    802007f6:	07800513          	li	a0,120
    802007fa:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007fc:	0aa1                	addi	s5,s5,8
    802007fe:	ff8ab603          	ld	a2,-8(s5)
            goto number;
    80200802:	6782                	ld	a5,0(sp)
    80200804:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
    80200806:	876e                	mv	a4,s11
    80200808:	85a6                	mv	a1,s1
    8020080a:	854a                	mv	a0,s2
    8020080c:	e1fff0ef          	jal	ra,8020062a <printnum>
            break;
    80200810:	b5c1                	j	802006d0 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
    80200812:	000ab603          	ld	a2,0(s5)
    80200816:	0aa1                	addi	s5,s5,8
    80200818:	1c060663          	beqz	a2,802009e4 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
    8020081c:	00160413          	addi	s0,a2,1
    80200820:	17b05c63          	blez	s11,80200998 <vprintfmt+0x302>
    80200824:	02d00593          	li	a1,45
    80200828:	14b79263          	bne	a5,a1,8020096c <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020082c:	00064783          	lbu	a5,0(a2)
    80200830:	0007851b          	sext.w	a0,a5
    80200834:	c905                	beqz	a0,80200864 <vprintfmt+0x1ce>
    80200836:	000cc563          	bltz	s9,80200840 <vprintfmt+0x1aa>
    8020083a:	3cfd                	addiw	s9,s9,-1
    8020083c:	036c8263          	beq	s9,s6,80200860 <vprintfmt+0x1ca>
                    putch('?', putdat);
    80200840:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    80200842:	18098463          	beqz	s3,802009ca <vprintfmt+0x334>
    80200846:	3781                	addiw	a5,a5,-32
    80200848:	18fbf163          	bleu	a5,s7,802009ca <vprintfmt+0x334>
                    putch('?', putdat);
    8020084c:	03f00513          	li	a0,63
    80200850:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200852:	0405                	addi	s0,s0,1
    80200854:	fff44783          	lbu	a5,-1(s0)
    80200858:	3dfd                	addiw	s11,s11,-1
    8020085a:	0007851b          	sext.w	a0,a5
    8020085e:	fd61                	bnez	a0,80200836 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
    80200860:	e7b058e3          	blez	s11,802006d0 <vprintfmt+0x3a>
    80200864:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200866:	85a6                	mv	a1,s1
    80200868:	02000513          	li	a0,32
    8020086c:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020086e:	e60d81e3          	beqz	s11,802006d0 <vprintfmt+0x3a>
    80200872:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    80200874:	85a6                	mv	a1,s1
    80200876:	02000513          	li	a0,32
    8020087a:	9902                	jalr	s2
            for (; width > 0; width --) {
    8020087c:	fe0d94e3          	bnez	s11,80200864 <vprintfmt+0x1ce>
    80200880:	bd81                	j	802006d0 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200882:	4705                	li	a4,1
    80200884:	008a8593          	addi	a1,s5,8
    80200888:	01074463          	blt	a4,a6,80200890 <vprintfmt+0x1fa>
    else if (lflag) {
    8020088c:	12080063          	beqz	a6,802009ac <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
    80200890:	000ab603          	ld	a2,0(s5)
    80200894:	46a9                	li	a3,10
    80200896:	8aae                	mv	s5,a1
    80200898:	b7bd                	j	80200806 <vprintfmt+0x170>
    8020089a:	00144603          	lbu	a2,1(s0)
            padc = '-';
    8020089e:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
    802008a2:	846a                	mv	s0,s10
    802008a4:	b5ad                	j	8020070e <vprintfmt+0x78>
            putch(ch, putdat);
    802008a6:	85a6                	mv	a1,s1
    802008a8:	02500513          	li	a0,37
    802008ac:	9902                	jalr	s2
            break;
    802008ae:	b50d                	j	802006d0 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
    802008b0:	000aac83          	lw	s9,0(s5)
            goto process_precision;
    802008b4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    802008b8:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
    802008ba:	846a                	mv	s0,s10
            if (width < 0)
    802008bc:	e40dd9e3          	bgez	s11,8020070e <vprintfmt+0x78>
                width = precision, precision = -1;
    802008c0:	8de6                	mv	s11,s9
    802008c2:	5cfd                	li	s9,-1
    802008c4:	b5a9                	j	8020070e <vprintfmt+0x78>
            goto reswitch;
    802008c6:	00144603          	lbu	a2,1(s0)
            padc = '0';
    802008ca:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
    802008ce:	846a                	mv	s0,s10
            goto reswitch;
    802008d0:	bd3d                	j	8020070e <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
    802008d2:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
    802008d6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802008da:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    802008dc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802008e0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    802008e4:	fcd56ce3          	bltu	a0,a3,802008bc <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
    802008e8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    802008ea:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
    802008ee:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
    802008f2:	0196873b          	addw	a4,a3,s9
    802008f6:	0017171b          	slliw	a4,a4,0x1
    802008fa:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
    802008fe:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
    80200902:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
    80200906:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    8020090a:	fcd57fe3          	bleu	a3,a0,802008e8 <vprintfmt+0x252>
    8020090e:	b77d                	j	802008bc <vprintfmt+0x226>
            if (width < 0)
    80200910:	fffdc693          	not	a3,s11
    80200914:	96fd                	srai	a3,a3,0x3f
    80200916:	00ddfdb3          	and	s11,s11,a3
    8020091a:	00144603          	lbu	a2,1(s0)
    8020091e:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
    80200920:	846a                	mv	s0,s10
    80200922:	b3f5                	j	8020070e <vprintfmt+0x78>
            putch('%', putdat);
    80200924:	85a6                	mv	a1,s1
    80200926:	02500513          	li	a0,37
    8020092a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    8020092c:	fff44703          	lbu	a4,-1(s0)
    80200930:	02500793          	li	a5,37
    80200934:	8d22                	mv	s10,s0
    80200936:	d8f70de3          	beq	a4,a5,802006d0 <vprintfmt+0x3a>
    8020093a:	02500713          	li	a4,37
    8020093e:	1d7d                	addi	s10,s10,-1
    80200940:	fffd4783          	lbu	a5,-1(s10)
    80200944:	fee79de3          	bne	a5,a4,8020093e <vprintfmt+0x2a8>
    80200948:	b361                	j	802006d0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    8020094a:	00001617          	auipc	a2,0x1
    8020094e:	95660613          	addi	a2,a2,-1706 # 802012a0 <error_string+0xd8>
    80200952:	85a6                	mv	a1,s1
    80200954:	854a                	mv	a0,s2
    80200956:	0ac000ef          	jal	ra,80200a02 <printfmt>
    8020095a:	bb9d                	j	802006d0 <vprintfmt+0x3a>
                p = "(null)";
    8020095c:	00001617          	auipc	a2,0x1
    80200960:	93c60613          	addi	a2,a2,-1732 # 80201298 <error_string+0xd0>
            if (width > 0 && padc != '-') {
    80200964:	00001417          	auipc	s0,0x1
    80200968:	93540413          	addi	s0,s0,-1739 # 80201299 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020096c:	8532                	mv	a0,a2
    8020096e:	85e6                	mv	a1,s9
    80200970:	e032                	sd	a2,0(sp)
    80200972:	e43e                	sd	a5,8(sp)
    80200974:	c7fff0ef          	jal	ra,802005f2 <strnlen>
    80200978:	40ad8dbb          	subw	s11,s11,a0
    8020097c:	6602                	ld	a2,0(sp)
    8020097e:	01b05d63          	blez	s11,80200998 <vprintfmt+0x302>
    80200982:	67a2                	ld	a5,8(sp)
    80200984:	2781                	sext.w	a5,a5
    80200986:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
    80200988:	6522                	ld	a0,8(sp)
    8020098a:	85a6                	mv	a1,s1
    8020098c:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
    8020098e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    80200990:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    80200992:	6602                	ld	a2,0(sp)
    80200994:	fe0d9ae3          	bnez	s11,80200988 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200998:	00064783          	lbu	a5,0(a2)
    8020099c:	0007851b          	sext.w	a0,a5
    802009a0:	e8051be3          	bnez	a0,80200836 <vprintfmt+0x1a0>
    802009a4:	b335                	j	802006d0 <vprintfmt+0x3a>
        return va_arg(*ap, int);
    802009a6:	000aa403          	lw	s0,0(s5)
    802009aa:	bbf1                	j	80200786 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
    802009ac:	000ae603          	lwu	a2,0(s5)
    802009b0:	46a9                	li	a3,10
    802009b2:	8aae                	mv	s5,a1
    802009b4:	bd89                	j	80200806 <vprintfmt+0x170>
    802009b6:	000ae603          	lwu	a2,0(s5)
    802009ba:	46c1                	li	a3,16
    802009bc:	8aae                	mv	s5,a1
    802009be:	b5a1                	j	80200806 <vprintfmt+0x170>
    802009c0:	000ae603          	lwu	a2,0(s5)
    802009c4:	46a1                	li	a3,8
    802009c6:	8aae                	mv	s5,a1
    802009c8:	bd3d                	j	80200806 <vprintfmt+0x170>
                    putch(ch, putdat);
    802009ca:	9902                	jalr	s2
    802009cc:	b559                	j	80200852 <vprintfmt+0x1bc>
                putch('-', putdat);
    802009ce:	85a6                	mv	a1,s1
    802009d0:	02d00513          	li	a0,45
    802009d4:	e03e                	sd	a5,0(sp)
    802009d6:	9902                	jalr	s2
                num = -(long long)num;
    802009d8:	8ace                	mv	s5,s3
    802009da:	40800633          	neg	a2,s0
    802009de:	46a9                	li	a3,10
    802009e0:	6782                	ld	a5,0(sp)
    802009e2:	b515                	j	80200806 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
    802009e4:	01b05663          	blez	s11,802009f0 <vprintfmt+0x35a>
    802009e8:	02d00693          	li	a3,45
    802009ec:	f6d798e3          	bne	a5,a3,8020095c <vprintfmt+0x2c6>
    802009f0:	00001417          	auipc	s0,0x1
    802009f4:	8a940413          	addi	s0,s0,-1879 # 80201299 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802009f8:	02800513          	li	a0,40
    802009fc:	02800793          	li	a5,40
    80200a00:	bd1d                	j	80200836 <vprintfmt+0x1a0>

0000000080200a02 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200a02:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    80200a04:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200a08:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200a0a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200a0c:	ec06                	sd	ra,24(sp)
    80200a0e:	f83a                	sd	a4,48(sp)
    80200a10:	fc3e                	sd	a5,56(sp)
    80200a12:	e0c2                	sd	a6,64(sp)
    80200a14:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200a16:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200a18:	c7fff0ef          	jal	ra,80200696 <vprintfmt>
}
    80200a1c:	60e2                	ld	ra,24(sp)
    80200a1e:	6161                	addi	sp,sp,80
    80200a20:	8082                	ret

0000000080200a22 <sbi_console_putchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
    80200a22:	00003797          	auipc	a5,0x3
    80200a26:	5de78793          	addi	a5,a5,1502 # 80204000 <bootstacktop>
    __asm__ volatile (
    80200a2a:	6398                	ld	a4,0(a5)
    80200a2c:	4781                	li	a5,0
    80200a2e:	88ba                	mv	a7,a4
    80200a30:	852a                	mv	a0,a0
    80200a32:	85be                	mv	a1,a5
    80200a34:	863e                	mv	a2,a5
    80200a36:	00000073          	ecall
    80200a3a:	87aa                	mv	a5,a0
}
    80200a3c:	8082                	ret

0000000080200a3e <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
    80200a3e:	00003797          	auipc	a5,0x3
    80200a42:	5da78793          	addi	a5,a5,1498 # 80204018 <SBI_SET_TIMER>
    __asm__ volatile (
    80200a46:	6398                	ld	a4,0(a5)
    80200a48:	4781                	li	a5,0
    80200a4a:	88ba                	mv	a7,a4
    80200a4c:	852a                	mv	a0,a0
    80200a4e:	85be                	mv	a1,a5
    80200a50:	863e                	mv	a2,a5
    80200a52:	00000073          	ecall
    80200a56:	87aa                	mv	a5,a0
}
    80200a58:	8082                	ret

0000000080200a5a <sbi_shutdown>:


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    80200a5a:	00003797          	auipc	a5,0x3
    80200a5e:	5ae78793          	addi	a5,a5,1454 # 80204008 <SBI_SHUTDOWN>
    __asm__ volatile (
    80200a62:	6398                	ld	a4,0(a5)
    80200a64:	4781                	li	a5,0
    80200a66:	88ba                	mv	a7,a4
    80200a68:	853e                	mv	a0,a5
    80200a6a:	85be                	mv	a1,a5
    80200a6c:	863e                	mv	a2,a5
    80200a6e:	00000073          	ecall
    80200a72:	87aa                	mv	a5,a0
    80200a74:	8082                	ret
