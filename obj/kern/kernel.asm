
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 8c 79 11 f0       	mov    $0xf011798c,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 ae 37 00 00       	call   f0103816 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8f 04 00 00       	call   f01004fc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 3d 10 f0 	movl   $0xf0103d20,(%esp)
f010007c:	e8 55 2c 00 00       	call   f0102cd6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 6b 11 00 00       	call   f01011f1 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 51 07 00 00       	call   f01007e3 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 73 11 f0 00 	cmpl   $0x0,0xf0117300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 73 11 f0    	mov    %esi,0xf0117300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 3b 3d 10 f0 	movl   $0xf0103d3b,(%esp)
f01000c8:	e8 09 2c 00 00       	call   f0102cd6 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ca 2b 00 00       	call   f0102ca3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 0b 49 10 f0 	movl   $0xf010490b,(%esp)
f01000e0:	e8 f1 2b 00 00       	call   f0102cd6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 f2 06 00 00       	call   f01007e3 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 53 3d 10 f0 	movl   $0xf0103d53,(%esp)
f0100112:	e8 bf 2b 00 00       	call   f0102cd6 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 7d 2b 00 00       	call   f0102ca3 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 0b 49 10 f0 	movl   $0xf010490b,(%esp)
f010012d:	e8 a4 2b 00 00       	call   f0102cd6 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 44 75 11 f0    	mov    0xf0117544,%edx
f010017f:	88 82 40 73 11 f0    	mov    %al,-0xfee8cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 75 11 f0       	mov    %eax,0xf0117544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b8:	a8 20                	test   $0x20,%al
f01001ba:	75 1b                	jne    f01001d7 <cons_putc+0x30>
f01001bc:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c1:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c6:	e8 75 ff ff ff       	call   f0100140 <delay>
f01001cb:	89 f2                	mov    %esi,%edx
f01001cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	75 05                	jne    f01001d7 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d2:	83 eb 01             	sub    $0x1,%ebx
f01001d5:	75 ef                	jne    f01001c6 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d7:	89 fa                	mov    %edi,%edx
f01001d9:	89 f8                	mov    %edi,%eax
f01001db:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001de:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010020f:	ee                   	out    %al,(%dx)
f0100210:	b2 7a                	mov    $0x7a,%dl
f0100212:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100217:	ee                   	out    %al,(%dx)
f0100218:	b8 08 00 00 00       	mov    $0x8,%eax
f010021d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010021e:	89 fa                	mov    %edi,%edx
f0100220:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100226:	89 f8                	mov    %edi,%eax
f0100228:	80 cc 07             	or     $0x7,%ah
f010022b:	85 d2                	test   %edx,%edx
f010022d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100230:	89 f8                	mov    %edi,%eax
f0100232:	25 ff 00 00 00       	and    $0xff,%eax
f0100237:	83 f8 09             	cmp    $0x9,%eax
f010023a:	74 7c                	je     f01002b8 <cons_putc+0x111>
f010023c:	83 f8 09             	cmp    $0x9,%eax
f010023f:	7f 0b                	jg     f010024c <cons_putc+0xa5>
f0100241:	83 f8 08             	cmp    $0x8,%eax
f0100244:	0f 85 a2 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010024a:	eb 16                	jmp    f0100262 <cons_putc+0xbb>
f010024c:	83 f8 0a             	cmp    $0xa,%eax
f010024f:	90                   	nop
f0100250:	74 40                	je     f0100292 <cons_putc+0xeb>
f0100252:	83 f8 0d             	cmp    $0xd,%eax
f0100255:	0f 85 91 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010025b:	90                   	nop
f010025c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100260:	eb 38                	jmp    f010029a <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e4 00 00 00    	je     f0100356 <cons_putc+0x1af>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100283:	83 cf 20             	or     $0x20,%edi
f0100286:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f010028c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100290:	eb 77                	jmp    f0100309 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100292:	66 83 05 54 75 11 f0 	addw   $0x50,0xf0117554
f0100299:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029a:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002a1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a7:	c1 e8 16             	shr    $0x16,%eax
f01002aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ad:	c1 e0 04             	shl    $0x4,%eax
f01002b0:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
f01002b6:	eb 51                	jmp    f0100309 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f01002b8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bd:	e8 e5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c7:	e8 db fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d1:	e8 d1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002db:	e8 c7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e5:	e8 bd fe ff ff       	call   f01001a7 <cons_putc>
f01002ea:	eb 1d                	jmp    f0100309 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ec:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002f3:	0f b7 c8             	movzwl %ax,%ecx
f01002f6:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f01002fc:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100300:	83 c0 01             	add    $0x1,%eax
f0100303:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100309:	66 81 3d 54 75 11 f0 	cmpw   $0x7cf,0xf0117554
f0100310:	cf 07 
f0100312:	76 42                	jbe    f0100356 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100314:	a1 50 75 11 f0       	mov    0xf0117550,%eax
f0100319:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100320:	00 
f0100321:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100327:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032b:	89 04 24             	mov    %eax,(%esp)
f010032e:	e8 3e 35 00 00       	call   f0103871 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100333:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100339:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100344:	83 c0 01             	add    $0x1,%eax
f0100347:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034c:	75 f0                	jne    f010033e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034e:	66 83 2d 54 75 11 f0 	subw   $0x50,0xf0117554
f0100355:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100356:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010035c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100364:	0f b7 35 54 75 11 f0 	movzwl 0xf0117554,%esi
f010036b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036e:	89 f0                	mov    %esi,%eax
f0100370:	66 c1 e8 08          	shr    $0x8,%ax
f0100374:	89 da                	mov    %ebx,%edx
f0100376:	ee                   	out    %al,(%dx)
f0100377:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037c:	89 ca                	mov    %ecx,%edx
f010037e:	ee                   	out    %al,(%dx)
f010037f:	89 f0                	mov    %esi,%eax
f0100381:	89 da                	mov    %ebx,%edx
f0100383:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100384:	83 c4 2c             	add    $0x2c,%esp
f0100387:	5b                   	pop    %ebx
f0100388:	5e                   	pop    %esi
f0100389:	5f                   	pop    %edi
f010038a:	5d                   	pop    %ebp
f010038b:	c3                   	ret    

f010038c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038c:	55                   	push   %ebp
f010038d:	89 e5                	mov    %esp,%ebp
f010038f:	53                   	push   %ebx
f0100390:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100393:	ba 64 00 00 00       	mov    $0x64,%edx
f0100398:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100399:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039e:	a8 01                	test   $0x1,%al
f01003a0:	0f 84 de 00 00 00    	je     f0100484 <kbd_proc_data+0xf8>
f01003a6:	b2 60                	mov    $0x60,%dl
f01003a8:	ec                   	in     (%dx),%al
f01003a9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003ab:	3c e0                	cmp    $0xe0,%al
f01003ad:	75 11                	jne    f01003c0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003af:	83 0d 48 75 11 f0 40 	orl    $0x40,0xf0117548
		return 0;
f01003b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bb:	e9 c4 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003c0:	84 c0                	test   %al,%al
f01003c2:	79 37                	jns    f01003fb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c4:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f01003ca:	89 cb                	mov    %ecx,%ebx
f01003cc:	83 e3 40             	and    $0x40,%ebx
f01003cf:	83 e0 7f             	and    $0x7f,%eax
f01003d2:	85 db                	test   %ebx,%ebx
f01003d4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d7:	0f b6 d2             	movzbl %dl,%edx
f01003da:	0f b6 82 a0 3d 10 f0 	movzbl -0xfefc260(%edx),%eax
f01003e1:	83 c8 40             	or     $0x40,%eax
f01003e4:	0f b6 c0             	movzbl %al,%eax
f01003e7:	f7 d0                	not    %eax
f01003e9:	21 c1                	and    %eax,%ecx
f01003eb:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 89 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fb:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	74 0e                	je     f0100414 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040e:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
	}

	shift |= shiftcode[data];
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 a0 3d 10 f0 	movzbl -0xfefc260(%edx),%eax
f010041e:	0b 05 48 75 11 f0    	or     0xf0117548,%eax
	shift ^= togglecode[data];
f0100424:	0f b6 8a a0 3e 10 f0 	movzbl -0xfefc160(%edx),%ecx
f010042b:	31 c8                	xor    %ecx,%eax
f010042d:	a3 48 75 11 f0       	mov    %eax,0xf0117548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100432:	89 c1                	mov    %eax,%ecx
f0100434:	83 e1 03             	and    $0x3,%ecx
f0100437:	8b 0c 8d a0 3f 10 f0 	mov    -0xfefc060(,%ecx,4),%ecx
f010043e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100442:	a8 08                	test   $0x8,%al
f0100444:	74 19                	je     f010045f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100446:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100449:	83 fa 19             	cmp    $0x19,%edx
f010044c:	77 05                	ja     f0100453 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044e:	83 eb 20             	sub    $0x20,%ebx
f0100451:	eb 0c                	jmp    f010045f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100453:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100456:	8d 53 20             	lea    0x20(%ebx),%edx
f0100459:	83 f9 19             	cmp    $0x19,%ecx
f010045c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045f:	f7 d0                	not    %eax
f0100461:	a8 06                	test   $0x6,%al
f0100463:	75 1f                	jne    f0100484 <kbd_proc_data+0xf8>
f0100465:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046b:	75 17                	jne    f0100484 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046d:	c7 04 24 6d 3d 10 f0 	movl   $0xf0103d6d,(%esp)
f0100474:	e8 5d 28 00 00       	call   f0102cd6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100479:	ba 92 00 00 00       	mov    $0x92,%edx
f010047e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100483:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100484:	89 d8                	mov    %ebx,%eax
f0100486:	83 c4 14             	add    $0x14,%esp
f0100489:	5b                   	pop    %ebx
f010048a:	5d                   	pop    %ebp
f010048b:	c3                   	ret    

f010048c <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100492:	83 3d 20 73 11 f0 00 	cmpl   $0x0,0xf0117320
f0100499:	74 0a                	je     f01004a5 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049b:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a0:	e8 c5 fc ff ff       	call   f010016a <cons_intr>
}
f01004a5:	c9                   	leave  
f01004a6:	c3                   	ret    

f01004a7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a7:	55                   	push   %ebp
f01004a8:	89 e5                	mov    %esp,%ebp
f01004aa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ad:	b8 8c 03 10 f0       	mov    $0xf010038c,%eax
f01004b2:	e8 b3 fc ff ff       	call   f010016a <cons_intr>
}
f01004b7:	c9                   	leave  
f01004b8:	c3                   	ret    

f01004b9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b9:	55                   	push   %ebp
f01004ba:	89 e5                	mov    %esp,%ebp
f01004bc:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bf:	e8 c8 ff ff ff       	call   f010048c <serial_intr>
	kbd_intr();
f01004c4:	e8 de ff ff ff       	call   f01004a7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c9:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004cf:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d4:	3b 15 44 75 11 f0    	cmp    0xf0117544,%edx
f01004da:	74 1e                	je     f01004fa <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004dc:	0f b6 82 40 73 11 f0 	movzbl -0xfee8cc0(%edx),%eax
f01004e3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f1:	0f 44 d1             	cmove  %ecx,%edx
f01004f4:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
		return c;
	}
	return 0;
}
f01004fa:	c9                   	leave  
f01004fb:	c3                   	ret    

f01004fc <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	57                   	push   %edi
f0100500:	56                   	push   %esi
f0100501:	53                   	push   %ebx
f0100502:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100505:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100513:	5a a5 
	if (*cp != 0xA55A) {
f0100515:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100520:	74 11                	je     f0100533 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100522:	c7 05 4c 75 11 f0 b4 	movl   $0x3b4,0xf011754c
f0100529:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100531:	eb 16                	jmp    f0100549 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100533:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053a:	c7 05 4c 75 11 f0 d4 	movl   $0x3d4,0xf011754c
f0100541:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100544:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100549:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010054f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100554:	89 ca                	mov    %ecx,%edx
f0100556:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100557:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055a:	89 da                	mov    %ebx,%edx
f010055c:	ec                   	in     (%dx),%al
f010055d:	0f b6 f8             	movzbl %al,%edi
f0100560:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100563:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100568:	89 ca                	mov    %ecx,%edx
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056e:	89 35 50 75 11 f0    	mov    %esi,0xf0117550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100574:	0f b6 d8             	movzbl %al,%ebx
f0100577:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100579:	66 89 3d 54 75 11 f0 	mov    %di,0xf0117554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100580:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100585:	b8 00 00 00 00       	mov    $0x0,%eax
f010058a:	89 da                	mov    %ebx,%edx
f010058c:	ee                   	out    %al,(%dx)
f010058d:	b2 fb                	mov    $0xfb,%dl
f010058f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100594:	ee                   	out    %al,(%dx)
f0100595:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010059a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b2 f9                	mov    $0xf9,%dl
f01005a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 fb                	mov    $0xfb,%dl
f01005ac:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b2 fc                	mov    $0xfc,%dl
f01005b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b2 f9                	mov    $0xf9,%dl
f01005bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	b2 fd                	mov    $0xfd,%dl
f01005c4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c5:	3c ff                	cmp    $0xff,%al
f01005c7:	0f 95 c0             	setne  %al
f01005ca:	0f b6 c0             	movzbl %al,%eax
f01005cd:	89 c6                	mov    %eax,%esi
f01005cf:	a3 20 73 11 f0       	mov    %eax,0xf0117320
f01005d4:	89 da                	mov    %ebx,%edx
f01005d6:	ec                   	in     (%dx),%al
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005da:	85 f6                	test   %esi,%esi
f01005dc:	75 0c                	jne    f01005ea <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005de:	c7 04 24 79 3d 10 f0 	movl   $0xf0103d79,(%esp)
f01005e5:	e8 ec 26 00 00       	call   f0102cd6 <cprintf>
}
f01005ea:	83 c4 1c             	add    $0x1c,%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 a7 fb ff ff       	call   f01001a7 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 ac fe ff ff       	call   f01004b9 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    
f010061d:	00 00                	add    %al,(%eax)
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 b0 3f 10 f0 	movl   $0xf0103fb0,(%esp)
f010062d:	e8 a4 26 00 00       	call   f0102cd6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 98 40 10 f0 	movl   $0xf0104098,(%esp)
f0100649:	e8 88 26 00 00       	call   f0102cd6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 15 3d 10 	movl   $0x103d15,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 15 3d 10 	movl   $0xf0103d15,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 bc 40 10 f0 	movl   $0xf01040bc,(%esp)
f0100665:	e8 6c 26 00 00       	call   f0102cd6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 e0 40 10 f0 	movl   $0xf01040e0,(%esp)
f0100681:	e8 50 26 00 00       	call   f0102cd6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 04 41 10 f0 	movl   $0xf0104104,(%esp)
f010069d:	e8 34 26 00 00       	call   f0102cd6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 8b 7d 11 f0       	mov    $0xf0117d8b,%eax
f01006a7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ac:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006b2:	85 c0                	test   %eax,%eax
f01006b4:	0f 48 c2             	cmovs  %edx,%eax
f01006b7:	c1 f8 0a             	sar    $0xa,%eax
f01006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006be:	c7 04 24 28 41 10 f0 	movl   $0xf0104128,(%esp)
f01006c5:	e8 0c 26 00 00       	call   f0102cd6 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	53                   	push   %ebx
f01006d5:	83 ec 14             	sub    $0x14,%esp
f01006d8:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006dd:	8b 83 e4 41 10 f0    	mov    -0xfefbe1c(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 e0 41 10 f0    	mov    -0xfefbe20(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 c9 3f 10 f0 	movl   $0xf0103fc9,(%esp)
f01006f8:	e8 d9 25 00 00       	call   f0102cd6 <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 24             	cmp    $0x24,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100719:	c7 04 24 d2 3f 10 f0 	movl   $0xf0103fd2,(%esp)
f0100720:	e8 b1 25 00 00       	call   f0102cd6 <cprintf>

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100725:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f0100727:	89 74 24 04          	mov    %esi,0x4(%esp)
f010072b:	c7 04 24 e4 3f 10 f0 	movl   $0xf0103fe4,(%esp)
f0100732:	e8 9f 25 00 00       	call   f0102cd6 <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f0100737:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f010073a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010073e:	c7 04 24 ef 3f 10 f0 	movl   $0xf0103fef,(%esp)
f0100745:	e8 8c 25 00 00       	call   f0102cd6 <cprintf>
		for(i=2; i < 7; i++)
f010074a:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f010074f:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100752:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100756:	c7 04 24 e9 3f 10 f0 	movl   $0xf0103fe9,(%esp)
f010075d:	e8 74 25 00 00       	call   f0102cd6 <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f0100762:	83 c3 01             	add    $0x1,%ebx
f0100765:	83 fb 07             	cmp    $0x7,%ebx
f0100768:	75 e5                	jne    f010074f <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f010076a:	c7 04 24 0b 49 10 f0 	movl   $0xf010490b,(%esp)
f0100771:	e8 60 25 00 00       	call   f0102cd6 <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f0100776:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100779:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077d:	89 3c 24             	mov    %edi,(%esp)
f0100780:	e8 4b 26 00 00       	call   f0102dd0 <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f0100785:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100788:	89 44 24 08          	mov    %eax,0x8(%esp)
f010078c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010078f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100793:	c7 04 24 00 40 10 f0 	movl   $0xf0104000,(%esp)
f010079a:	e8 37 25 00 00       	call   f0102cd6 <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f010079f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ad:	c7 04 24 09 40 10 f0 	movl   $0xf0104009,(%esp)
f01007b4:	e8 1d 25 00 00       	call   f0102cd6 <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f01007b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c0:	c7 04 24 0e 40 10 f0 	movl   $0xf010400e,(%esp)
f01007c7:	e8 0a 25 00 00       	call   f0102cd6 <cprintf>
		ebp = *(uint32_t *)ebp;
f01007cc:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f01007ce:	85 f6                	test   %esi,%esi
f01007d0:	0f 85 51 ff ff ff    	jne    f0100727 <mon_backtrace+0x17>
	return 0;
}
f01007d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01007db:	83 c4 3c             	add    $0x3c,%esp
f01007de:	5b                   	pop    %ebx
f01007df:	5e                   	pop    %esi
f01007e0:	5f                   	pop    %edi
f01007e1:	5d                   	pop    %ebp
f01007e2:	c3                   	ret    

f01007e3 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e3:	55                   	push   %ebp
f01007e4:	89 e5                	mov    %esp,%ebp
f01007e6:	57                   	push   %edi
f01007e7:	56                   	push   %esi
f01007e8:	53                   	push   %ebx
f01007e9:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ec:	c7 04 24 54 41 10 f0 	movl   $0xf0104154,(%esp)
f01007f3:	e8 de 24 00 00       	call   f0102cd6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f8:	c7 04 24 78 41 10 f0 	movl   $0xf0104178,(%esp)
f01007ff:	e8 d2 24 00 00       	call   f0102cd6 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100804:	c7 04 24 13 40 10 f0 	movl   $0xf0104013,(%esp)
f010080b:	e8 80 2d 00 00       	call   f0103590 <readline>
f0100810:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100812:	85 c0                	test   %eax,%eax
f0100814:	74 ee                	je     f0100804 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100816:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010081d:	be 00 00 00 00       	mov    $0x0,%esi
f0100822:	eb 06                	jmp    f010082a <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100824:	c6 03 00             	movb   $0x0,(%ebx)
f0100827:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010082a:	0f b6 03             	movzbl (%ebx),%eax
f010082d:	84 c0                	test   %al,%al
f010082f:	74 6a                	je     f010089b <monitor+0xb8>
f0100831:	0f be c0             	movsbl %al,%eax
f0100834:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100838:	c7 04 24 17 40 10 f0 	movl   $0xf0104017,(%esp)
f010083f:	e8 77 2f 00 00       	call   f01037bb <strchr>
f0100844:	85 c0                	test   %eax,%eax
f0100846:	75 dc                	jne    f0100824 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100848:	80 3b 00             	cmpb   $0x0,(%ebx)
f010084b:	74 4e                	je     f010089b <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010084d:	83 fe 0f             	cmp    $0xf,%esi
f0100850:	75 16                	jne    f0100868 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100852:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100859:	00 
f010085a:	c7 04 24 1c 40 10 f0 	movl   $0xf010401c,(%esp)
f0100861:	e8 70 24 00 00       	call   f0102cd6 <cprintf>
f0100866:	eb 9c                	jmp    f0100804 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100868:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010086c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010086f:	0f b6 03             	movzbl (%ebx),%eax
f0100872:	84 c0                	test   %al,%al
f0100874:	75 0c                	jne    f0100882 <monitor+0x9f>
f0100876:	eb b2                	jmp    f010082a <monitor+0x47>
			buf++;
f0100878:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010087b:	0f b6 03             	movzbl (%ebx),%eax
f010087e:	84 c0                	test   %al,%al
f0100880:	74 a8                	je     f010082a <monitor+0x47>
f0100882:	0f be c0             	movsbl %al,%eax
f0100885:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100889:	c7 04 24 17 40 10 f0 	movl   $0xf0104017,(%esp)
f0100890:	e8 26 2f 00 00       	call   f01037bb <strchr>
f0100895:	85 c0                	test   %eax,%eax
f0100897:	74 df                	je     f0100878 <monitor+0x95>
f0100899:	eb 8f                	jmp    f010082a <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010089b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a3:	85 f6                	test   %esi,%esi
f01008a5:	0f 84 59 ff ff ff    	je     f0100804 <monitor+0x21>
f01008ab:	bb e0 41 10 f0       	mov    $0xf01041e0,%ebx
f01008b0:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b5:	8b 03                	mov    (%ebx),%eax
f01008b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008be:	89 04 24             	mov    %eax,(%esp)
f01008c1:	e8 7a 2e 00 00       	call   f0103740 <strcmp>
f01008c6:	85 c0                	test   %eax,%eax
f01008c8:	75 24                	jne    f01008ee <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008ca:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01008cd:	8b 55 08             	mov    0x8(%ebp),%edx
f01008d0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008d4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008d7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008db:	89 34 24             	mov    %esi,(%esp)
f01008de:	ff 14 85 e8 41 10 f0 	call   *-0xfefbe18(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008e5:	85 c0                	test   %eax,%eax
f01008e7:	78 28                	js     f0100911 <monitor+0x12e>
f01008e9:	e9 16 ff ff ff       	jmp    f0100804 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008ee:	83 c7 01             	add    $0x1,%edi
f01008f1:	83 c3 0c             	add    $0xc,%ebx
f01008f4:	83 ff 03             	cmp    $0x3,%edi
f01008f7:	75 bc                	jne    f01008b5 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008f9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100900:	c7 04 24 39 40 10 f0 	movl   $0xf0104039,(%esp)
f0100907:	e8 ca 23 00 00       	call   f0102cd6 <cprintf>
f010090c:	e9 f3 fe ff ff       	jmp    f0100804 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100911:	83 c4 5c             	add    $0x5c,%esp
f0100914:	5b                   	pop    %ebx
f0100915:	5e                   	pop    %esi
f0100916:	5f                   	pop    %edi
f0100917:	5d                   	pop    %ebp
f0100918:	c3                   	ret    

f0100919 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100919:	55                   	push   %ebp
f010091a:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010091c:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f010091f:	5d                   	pop    %ebp
f0100920:	c3                   	ret    
	...

f0100930 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100930:	55                   	push   %ebp
f0100931:	89 e5                	mov    %esp,%ebp
f0100933:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100936:	89 d1                	mov    %edx,%ecx
f0100938:	c1 e9 16             	shr    $0x16,%ecx
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
f010093b:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f010093e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
//cprintf("#pgdir is %x #",KADDR(PTE_ADDR(*pgdir)));
	if (!(*pgdir & PTE_P))
f0100943:	f6 c1 01             	test   $0x1,%cl
f0100946:	74 57                	je     f010099f <check_va2pa+0x6f>
		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100948:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010094e:	89 c8                	mov    %ecx,%eax
f0100950:	c1 e8 0c             	shr    $0xc,%eax
f0100953:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0100959:	72 20                	jb     f010097b <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010095b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010095f:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100966:	f0 
f0100967:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f010096e:	00 
f010096f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100976:	e8 19 f7 ff ff       	call   f0100094 <_panic>
//cprintf("#%d the p+PTX(va) is %x #\n",PTX(va), p + PTX(va));
	if (!(p[PTX(va)] & PTE_P))
f010097b:	c1 ea 0c             	shr    $0xc,%edx
f010097e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100984:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f010098b:	89 c2                	mov    %eax,%edx
f010098d:	83 e2 01             	and    $0x1,%edx
		return ~0;
//	cprintf("%x\n", PTE_ADDR(p[PTX(va)]));
	return PTE_ADDR(p[PTX(va)]);
f0100990:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100995:	85 d2                	test   %edx,%edx
f0100997:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010099c:	0f 44 c2             	cmove  %edx,%eax
}
f010099f:	c9                   	leave  
f01009a0:	c3                   	ret    

f01009a1 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009a1:	55                   	push   %ebp
f01009a2:	89 e5                	mov    %esp,%ebp
f01009a4:	83 ec 18             	sub    $0x18,%esp
f01009a7:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009a9:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f01009b0:	75 0f                	jne    f01009c1 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009b2:	b8 8b 89 11 f0       	mov    $0xf011898b,%eax
f01009b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009bc:	a3 5c 75 11 f0       	mov    %eax,0xf011755c
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
		return nextfree;
f01009c1:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009c6:	85 d2                	test   %edx,%edx
f01009c8:	74 47                	je     f0100a11 <boot_alloc+0x70>
		return nextfree;
	result = nextfree;
f01009ca:	a1 5c 75 11 f0       	mov    0xf011755c,%eax
	nextfree += (n/PGSIZE + 1)*PGSIZE;
f01009cf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009d5:	8d 94 10 00 10 00 00 	lea    0x1000(%eax,%edx,1),%edx
f01009dc:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
	if((int)nextfree >= npages * PGSIZE + KERNBASE)
f01009e2:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f01009e8:	81 c1 00 00 0f 00    	add    $0xf0000,%ecx
f01009ee:	c1 e1 0c             	shl    $0xc,%ecx
f01009f1:	39 ca                	cmp    %ecx,%edx
f01009f3:	72 1c                	jb     f0100a11 <boot_alloc+0x70>
		panic("Run out of memory!!\n");
f01009f5:	c7 44 24 08 f8 48 10 	movl   $0xf01048f8,0x8(%esp)
f01009fc:	f0 
f01009fd:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
f0100a04:	00 
f0100a05:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100a0c:	e8 83 f6 ff ff       	call   f0100094 <_panic>
	return result;
}
f0100a11:	c9                   	leave  
f0100a12:	c3                   	ret    

f0100a13 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a13:	55                   	push   %ebp
f0100a14:	89 e5                	mov    %esp,%ebp
f0100a16:	83 ec 18             	sub    $0x18,%esp
f0100a19:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a1c:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a1f:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a21:	89 04 24             	mov    %eax,(%esp)
f0100a24:	e8 3f 22 00 00       	call   f0102c68 <mc146818_read>
f0100a29:	89 c6                	mov    %eax,%esi
f0100a2b:	83 c3 01             	add    $0x1,%ebx
f0100a2e:	89 1c 24             	mov    %ebx,(%esp)
f0100a31:	e8 32 22 00 00       	call   f0102c68 <mc146818_read>
f0100a36:	c1 e0 08             	shl    $0x8,%eax
f0100a39:	09 f0                	or     %esi,%eax
}
f0100a3b:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a3e:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a41:	89 ec                	mov    %ebp,%esp
f0100a43:	5d                   	pop    %ebp
f0100a44:	c3                   	ret    

f0100a45 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a45:	55                   	push   %ebp
f0100a46:	89 e5                	mov    %esp,%ebp
f0100a48:	57                   	push   %edi
f0100a49:	56                   	push   %esi
f0100a4a:	53                   	push   %ebx
f0100a4b:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a4e:	83 f8 01             	cmp    $0x1,%eax
f0100a51:	19 f6                	sbb    %esi,%esi
f0100a53:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a59:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a5c:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100a62:	85 db                	test   %ebx,%ebx
f0100a64:	75 1c                	jne    f0100a82 <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a66:	c7 44 24 08 28 42 10 	movl   $0xf0104228,0x8(%esp)
f0100a6d:	f0 
f0100a6e:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f0100a75:	00 
f0100a76:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100a7d:	e8 12 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a82:	85 c0                	test   %eax,%eax
f0100a84:	74 50                	je     f0100ad6 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a86:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a89:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a8c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a8f:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a92:	89 d8                	mov    %ebx,%eax
f0100a94:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100a9a:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a9d:	c1 e8 16             	shr    $0x16,%eax
f0100aa0:	39 f0                	cmp    %esi,%eax
f0100aa2:	0f 93 c0             	setae  %al
f0100aa5:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100aa8:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100aac:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100aae:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab2:	8b 1b                	mov    (%ebx),%ebx
f0100ab4:	85 db                	test   %ebx,%ebx
f0100ab6:	75 da                	jne    f0100a92 <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ab8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100abb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ac1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ac7:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ac9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100acc:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ad2:	85 db                	test   %ebx,%ebx
f0100ad4:	74 67                	je     f0100b3d <check_page_free_list+0xf8>
f0100ad6:	89 d8                	mov    %ebx,%eax
f0100ad8:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ade:	c1 f8 03             	sar    $0x3,%eax
f0100ae1:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ae4:	89 c2                	mov    %eax,%edx
f0100ae6:	c1 ea 16             	shr    $0x16,%edx
f0100ae9:	39 f2                	cmp    %esi,%edx
f0100aeb:	73 4a                	jae    f0100b37 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aed:	89 c2                	mov    %eax,%edx
f0100aef:	c1 ea 0c             	shr    $0xc,%edx
f0100af2:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100af8:	72 20                	jb     f0100b1a <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100afa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100afe:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100b05:	f0 
f0100b06:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b0d:	00 
f0100b0e:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0100b15:	e8 7a f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b1a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b21:	00 
f0100b22:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b29:	00 
	return (void *)(pa + KERNBASE);
f0100b2a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2f:	89 04 24             	mov    %eax,(%esp)
f0100b32:	e8 df 2c 00 00       	call   f0103816 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b37:	8b 1b                	mov    (%ebx),%ebx
f0100b39:	85 db                	test   %ebx,%ebx
f0100b3b:	75 99                	jne    f0100ad6 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b42:	e8 5a fe ff ff       	call   f01009a1 <boot_alloc>
f0100b47:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b4a:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100b50:	85 d2                	test   %edx,%edx
f0100b52:	0f 84 f6 01 00 00    	je     f0100d4e <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b58:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b5e:	39 da                	cmp    %ebx,%edx
f0100b60:	72 4d                	jb     f0100baf <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b62:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b67:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b6a:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b6d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b70:	39 c2                	cmp    %eax,%edx
f0100b72:	73 64                	jae    f0100bd8 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b74:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b77:	89 d0                	mov    %edx,%eax
f0100b79:	29 d8                	sub    %ebx,%eax
f0100b7b:	a8 07                	test   $0x7,%al
f0100b7d:	0f 85 82 00 00 00    	jne    f0100c05 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b83:	c1 f8 03             	sar    $0x3,%eax
f0100b86:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b89:	85 c0                	test   %eax,%eax
f0100b8b:	0f 84 a2 00 00 00    	je     f0100c33 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b91:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b96:	0f 84 c2 00 00 00    	je     f0100c5e <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b9c:	be 00 00 00 00       	mov    $0x0,%esi
f0100ba1:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ba6:	e9 d7 00 00 00       	jmp    f0100c82 <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bab:	39 da                	cmp    %ebx,%edx
f0100bad:	73 24                	jae    f0100bd3 <check_page_free_list+0x18e>
f0100baf:	c7 44 24 0c 1b 49 10 	movl   $0xf010491b,0xc(%esp)
f0100bb6:	f0 
f0100bb7:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100bbe:	f0 
f0100bbf:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f0100bc6:	00 
f0100bc7:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100bce:	e8 c1 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bd3:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bd6:	72 24                	jb     f0100bfc <check_page_free_list+0x1b7>
f0100bd8:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f0100bdf:	f0 
f0100be0:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100be7:	f0 
f0100be8:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100bef:	00 
f0100bf0:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100bf7:	e8 98 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bfc:	89 d0                	mov    %edx,%eax
f0100bfe:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c01:	a8 07                	test   $0x7,%al
f0100c03:	74 24                	je     f0100c29 <check_page_free_list+0x1e4>
f0100c05:	c7 44 24 0c 4c 42 10 	movl   $0xf010424c,0xc(%esp)
f0100c0c:	f0 
f0100c0d:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100c14:	f0 
f0100c15:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0100c1c:	00 
f0100c1d:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100c24:	e8 6b f4 ff ff       	call   f0100094 <_panic>
f0100c29:	c1 f8 03             	sar    $0x3,%eax
f0100c2c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c2f:	85 c0                	test   %eax,%eax
f0100c31:	75 24                	jne    f0100c57 <check_page_free_list+0x212>
f0100c33:	c7 44 24 0c 50 49 10 	movl   $0xf0104950,0xc(%esp)
f0100c3a:	f0 
f0100c3b:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100c42:	f0 
f0100c43:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100c4a:	00 
f0100c4b:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100c52:	e8 3d f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c57:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c5c:	75 24                	jne    f0100c82 <check_page_free_list+0x23d>
f0100c5e:	c7 44 24 0c 61 49 10 	movl   $0xf0104961,0xc(%esp)
f0100c65:	f0 
f0100c66:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100c6d:	f0 
f0100c6e:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100c75:	00 
f0100c76:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100c7d:	e8 12 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c82:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c87:	75 24                	jne    f0100cad <check_page_free_list+0x268>
f0100c89:	c7 44 24 0c 80 42 10 	movl   $0xf0104280,0xc(%esp)
f0100c90:	f0 
f0100c91:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100c98:	f0 
f0100c99:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100ca0:	00 
f0100ca1:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100ca8:	e8 e7 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cad:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cb2:	75 24                	jne    f0100cd8 <check_page_free_list+0x293>
f0100cb4:	c7 44 24 0c 7a 49 10 	movl   $0xf010497a,0xc(%esp)
f0100cbb:	f0 
f0100cbc:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100cc3:	f0 
f0100cc4:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100ccb:	00 
f0100ccc:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100cd3:	e8 bc f3 ff ff       	call   f0100094 <_panic>
f0100cd8:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cda:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cdf:	76 57                	jbe    f0100d38 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ce1:	c1 e8 0c             	shr    $0xc,%eax
f0100ce4:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100ce7:	77 20                	ja     f0100d09 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100ced:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100cf4:	f0 
f0100cf5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cfc:	00 
f0100cfd:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0100d04:	e8 8b f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d09:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d0f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d12:	76 29                	jbe    f0100d3d <check_page_free_list+0x2f8>
f0100d14:	c7 44 24 0c a4 42 10 	movl   $0xf01042a4,0xc(%esp)
f0100d1b:	f0 
f0100d1c:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100d23:	f0 
f0100d24:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100d2b:	00 
f0100d2c:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100d33:	e8 5c f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d38:	83 c7 01             	add    $0x1,%edi
f0100d3b:	eb 03                	jmp    f0100d40 <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d3d:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d40:	8b 12                	mov    (%edx),%edx
f0100d42:	85 d2                	test   %edx,%edx
f0100d44:	0f 85 61 fe ff ff    	jne    f0100bab <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d4a:	85 ff                	test   %edi,%edi
f0100d4c:	7f 24                	jg     f0100d72 <check_page_free_list+0x32d>
f0100d4e:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f0100d55:	f0 
f0100d56:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100d5d:	f0 
f0100d5e:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0100d65:	00 
f0100d66:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100d6d:	e8 22 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d72:	85 f6                	test   %esi,%esi
f0100d74:	7f 24                	jg     f0100d9a <check_page_free_list+0x355>
f0100d76:	c7 44 24 0c a6 49 10 	movl   $0xf01049a6,0xc(%esp)
f0100d7d:	f0 
f0100d7e:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0100d85:	f0 
f0100d86:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0100d8d:	00 
f0100d8e:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100d95:	e8 fa f2 ff ff       	call   f0100094 <_panic>
}
f0100d9a:	83 c4 3c             	add    $0x3c,%esp
f0100d9d:	5b                   	pop    %ebx
f0100d9e:	5e                   	pop    %esi
f0100d9f:	5f                   	pop    %edi
f0100da0:	5d                   	pop    %ebp
f0100da1:	c3                   	ret    

f0100da2 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100da2:	55                   	push   %ebp
f0100da3:	89 e5                	mov    %esp,%ebp
f0100da5:	56                   	push   %esi
f0100da6:	53                   	push   %ebx
f0100da7:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
f0100daa:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0100daf:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100db5:	8b 35 58 75 11 f0    	mov    0xf0117558,%esi
f0100dbb:	83 fe 01             	cmp    $0x1,%esi
f0100dbe:	76 37                	jbe    f0100df7 <page_init+0x55>
f0100dc0:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100dc6:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100dcb:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100dd2:	8b 0d 88 79 11 f0    	mov    0xf0117988,%ecx
f0100dd8:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100ddf:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100de2:	89 d3                	mov    %edx,%ebx
f0100de4:	03 1d 88 79 11 f0    	add    0xf0117988,%ebx
	pages[0].pp_ref = 1;	/* the first page is in use, so I set the ref is 1 */
	//pages[0].pp_link = &pages[1];
	//page_free_list = &pages[1];
	//struct Page *p_page_free_list = page_free_list;
	//panic("pa2page(IOPHYSMEM) %d",npages_basemem);
	for (i = 1; i < npages_basemem; i++) {
f0100dea:	83 c0 01             	add    $0x1,%eax
f0100ded:	39 c6                	cmp    %eax,%esi
f0100def:	77 da                	ja     f0100dcb <page_init+0x29>
f0100df1:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	size_t page_num = PADDR(boot_alloc(0)) / PGSIZE;
f0100df7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dfc:	e8 a0 fb ff ff       	call   f01009a1 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e01:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e06:	77 20                	ja     f0100e28 <page_init+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e08:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e0c:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f0100e13:	f0 
f0100e14:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
f0100e1b:	00 
f0100e1c:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100e23:	e8 6c f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e28:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e2d:	c1 e8 0c             	shr    $0xc,%eax
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100e30:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0100e36:	73 39                	jae    f0100e71 <page_init+0xcf>
f0100e38:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100e3e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e45:	89 d1                	mov    %edx,%ecx
f0100e47:	03 0d 88 79 11 f0    	add    0xf0117988,%ecx
f0100e4d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e53:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e55:	89 d3                	mov    %edx,%ebx
f0100e57:	03 1d 88 79 11 f0    	add    0xf0117988,%ebx
	//for(;i < page_num;i++){
	//	pages[i].pp_ref = 1;
	//	pages[i].pp_link = pages + i + 1;
	//}
	//panic("page_num %d, npages %d",page_num, npages);
	for(i = page_num; i < npages; i++){
f0100e5d:	83 c0 01             	add    $0x1,%eax
f0100e60:	83 c2 08             	add    $0x8,%edx
f0100e63:	39 05 80 79 11 f0    	cmp    %eax,0xf0117980
f0100e69:	77 da                	ja     f0100e45 <page_init+0xa3>
f0100e6b:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
//	panic("here");
	
}
f0100e71:	83 c4 10             	add    $0x10,%esp
f0100e74:	5b                   	pop    %ebx
f0100e75:	5e                   	pop    %esi
f0100e76:	5d                   	pop    %ebp
f0100e77:	c3                   	ret    

f0100e78 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100e78:	55                   	push   %ebp
f0100e79:	89 e5                	mov    %esp,%ebp
f0100e7b:	53                   	push   %ebx
f0100e7c:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if(!page_free_list)
f0100e7f:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100e85:	85 db                	test   %ebx,%ebx
f0100e87:	74 6b                	je     f0100ef4 <page_alloc+0x7c>
		return NULL;
	struct Page *alloc_page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100e89:	8b 03                	mov    (%ebx),%eax
f0100e8b:	a3 60 75 11 f0       	mov    %eax,0xf0117560
	alloc_page -> pp_link = NULL;
f0100e90:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100e96:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e9a:	74 58                	je     f0100ef4 <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9c:	89 d8                	mov    %ebx,%eax
f0100e9e:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ea4:	c1 f8 03             	sar    $0x3,%eax
f0100ea7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eaa:	89 c2                	mov    %eax,%edx
f0100eac:	c1 ea 0c             	shr    $0xc,%edx
f0100eaf:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100eb5:	72 20                	jb     f0100ed7 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eb7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ebb:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100ec2:	f0 
f0100ec3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100eca:	00 
f0100ecb:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0100ed2:	e8 bd f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(alloc_page), 0, PGSIZE);
f0100ed7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ede:	00 
f0100edf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ee6:	00 
	return (void *)(pa + KERNBASE);
f0100ee7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100eec:	89 04 24             	mov    %eax,(%esp)
f0100eef:	e8 22 29 00 00       	call   f0103816 <memset>
	
	return alloc_page;
}
f0100ef4:	89 d8                	mov    %ebx,%eax
f0100ef6:	83 c4 14             	add    $0x14,%esp
f0100ef9:	5b                   	pop    %ebx
f0100efa:	5d                   	pop    %ebp
f0100efb:	c3                   	ret    

f0100efc <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100efc:	55                   	push   %ebp
f0100efd:	89 e5                	mov    %esp,%ebp
f0100eff:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if(pp -> pp_ref)	// If the ref is not 0, return
f0100f02:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f07:	75 0d                	jne    f0100f16 <page_free+0x1a>
		return;
	pp->pp_link = page_free_list;
f0100f09:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100f0f:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f11:	a3 60 75 11 f0       	mov    %eax,0xf0117560
}
f0100f16:	5d                   	pop    %ebp
f0100f17:	c3                   	ret    

f0100f18 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f18:	55                   	push   %ebp
f0100f19:	89 e5                	mov    %esp,%ebp
f0100f1b:	83 ec 04             	sub    $0x4,%esp
f0100f1e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f21:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f25:	83 ea 01             	sub    $0x1,%edx
f0100f28:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f2c:	66 85 d2             	test   %dx,%dx
f0100f2f:	75 08                	jne    f0100f39 <page_decref+0x21>
		page_free(pp);
f0100f31:	89 04 24             	mov    %eax,(%esp)
f0100f34:	e8 c3 ff ff ff       	call   f0100efc <page_free>
}
f0100f39:	c9                   	leave  
f0100f3a:	c3                   	ret    

f0100f3b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{/* see the check_va2pa() */
f0100f3b:	55                   	push   %ebp
f0100f3c:	89 e5                	mov    %esp,%ebp
f0100f3e:	56                   	push   %esi
f0100f3f:	53                   	push   %ebx
f0100f40:	83 ec 10             	sub    $0x10,%esp
f0100f43:	8b 75 0c             	mov    0xc(%ebp),%esi
	/* va is a linear address */
	pde_t *ptdir = pgdir + PDX(va);
f0100f46:	89 f3                	mov    %esi,%ebx
f0100f48:	c1 eb 16             	shr    $0x16,%ebx
f0100f4b:	c1 e3 02             	shl    $0x2,%ebx
f0100f4e:	03 5d 08             	add    0x8(%ebp),%ebx
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
f0100f51:	8b 03                	mov    (%ebx),%eax
f0100f53:	a8 01                	test   $0x1,%al
f0100f55:	74 44                	je     f0100f9b <pgdir_walk+0x60>
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100f57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f5c:	89 c2                	mov    %eax,%edx
f0100f5e:	c1 ea 0c             	shr    $0xc,%edx
f0100f61:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100f67:	72 20                	jb     f0100f89 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f6d:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100f74:	f0 
f0100f75:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
f0100f7c:	00 
f0100f7d:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100f84:	e8 0b f1 ff ff       	call   f0100094 <_panic>
f0100f89:	c1 ee 0a             	shr    $0xa,%esi
f0100f8c:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f92:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f99:	eb 7c                	jmp    f0101017 <pgdir_walk+0xdc>
	if(!create)
f0100f9b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f9f:	74 6a                	je     f010100b <pgdir_walk+0xd0>
		return NULL;
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
f0100fa1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fa8:	e8 cb fe ff ff       	call   f0100e78 <page_alloc>
	if(!page_create)
f0100fad:	85 c0                	test   %eax,%eax
f0100faf:	74 61                	je     f0101012 <pgdir_walk+0xd7>
		return NULL; /* allocation fails */
	page_create -> pp_ref++; /* reference count increase */
f0100fb1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fb6:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100fbc:	c1 f8 03             	sar    $0x3,%eax
f0100fbf:	c1 e0 0c             	shl    $0xc,%eax
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
f0100fc2:	83 c8 07             	or     $0x7,%eax
f0100fc5:	89 03                	mov    %eax,(%ebx)
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
f0100fc7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcc:	89 c2                	mov    %eax,%edx
f0100fce:	c1 ea 0c             	shr    $0xc,%edx
f0100fd1:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100fd7:	72 20                	jb     f0100ff9 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fdd:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0100fe4:	f0 
f0100fe5:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f0100fec:	00 
f0100fed:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0100ff4:	e8 9b f0 ff ff       	call   f0100094 <_panic>
f0100ff9:	c1 ee 0a             	shr    $0xa,%esi
f0100ffc:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101002:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101009:	eb 0c                	jmp    f0101017 <pgdir_walk+0xdc>
	pde_t *ptdir = pgdir + PDX(va);
	//cprintf("*%d the ptdir is %x*",PTX(va), KADDR(PTE_ADDR(*ptdir)));
	if(*ptdir & PTE_P) /* check it is a valid one? last bit is 1 */
		return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
	if(!create)
		return NULL;
f010100b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101010:	eb 05                	jmp    f0101017 <pgdir_walk+0xdc>
	struct Page *page_create = page_alloc(ALLOC_ZERO); /* page_alloc and filled with \0 */
	if(!page_create)
		return NULL; /* allocation fails */
f0101012:	b8 00 00 00 00       	mov    $0x0,%eax
	page_create -> pp_ref++; /* reference count increase */
	*ptdir = page2pa(page_create)|PTE_P|PTE_W|PTE_U; /* insert into the new page table page */
	return (pte_t *)KADDR(PTE_ADDR(*ptdir)) + PTX(va);
}
f0101017:	83 c4 10             	add    $0x10,%esp
f010101a:	5b                   	pop    %ebx
f010101b:	5e                   	pop    %esi
f010101c:	5d                   	pop    %ebp
f010101d:	c3                   	ret    

f010101e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010101e:	55                   	push   %ebp
f010101f:	89 e5                	mov    %esp,%ebp
f0101021:	57                   	push   %edi
f0101022:	56                   	push   %esi
f0101023:	53                   	push   %ebx
f0101024:	83 ec 2c             	sub    $0x2c,%esp
f0101027:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010102a:	89 d7                	mov    %edx,%edi
f010102c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f010102f:	85 c9                	test   %ecx,%ecx
f0101031:	74 38                	je     f010106b <boot_map_region+0x4d>
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
f0101033:	bb 00 00 00 00       	mov    $0x0,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101038:	8b 75 08             	mov    0x8(%ebp),%esi
f010103b:	01 de                	add    %ebx,%esi
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f010103d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101044:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101045:	8d 04 3b             	lea    (%ebx,%edi,1),%eax
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
		pte_t *pte = pgdir_walk(pgdir, (const void *)va, 1);
f0101048:	89 44 24 04          	mov    %eax,0x4(%esp)
f010104c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010104f:	89 04 24             	mov    %eax,(%esp)
f0101052:	e8 e4 fe ff ff       	call   f0100f3b <pgdir_walk>
		if(!pte)
f0101057:	85 c0                	test   %eax,%eax
f0101059:	74 10                	je     f010106b <boot_map_region+0x4d>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
f010105b:	0b 75 0c             	or     0xc(%ebp),%esi
f010105e:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ii~~~~~~`~\n");
	// Fill this function in
	int i = 0;
	for(; i < size; i+=PGSIZE,va+=PGSIZE,pa+=PGSIZE){
f0101060:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101066:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101069:	77 cd                	ja     f0101038 <boot_map_region+0x1a>
			return;// If it alloc fail
//		cprintf("the pte is %x\n", pte);
		*pte = pa|perm;
	}
//cprintf("~~~~~~~~~~~~~~~~~~~~~~~~~\n");
}
f010106b:	83 c4 2c             	add    $0x2c,%esp
f010106e:	5b                   	pop    %ebx
f010106f:	5e                   	pop    %esi
f0101070:	5f                   	pop    %edi
f0101071:	5d                   	pop    %ebp
f0101072:	c3                   	ret    

f0101073 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101073:	55                   	push   %ebp
f0101074:	89 e5                	mov    %esp,%ebp
f0101076:	53                   	push   %ebx
f0101077:	83 ec 14             	sub    $0x14,%esp
f010107a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f010107d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101084:	00 
f0101085:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101088:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108c:	8b 45 08             	mov    0x8(%ebp),%eax
f010108f:	89 04 24             	mov    %eax,(%esp)
f0101092:	e8 a4 fe ff ff       	call   f0100f3b <pgdir_walk>
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
f0101097:	85 c0                	test   %eax,%eax
f0101099:	74 3f                	je     f01010da <page_lookup+0x67>
f010109b:	f6 00 01             	testb  $0x1,(%eax)
f010109e:	74 41                	je     f01010e1 <page_lookup+0x6e>
		return NULL;
	if(pte_store)
f01010a0:	85 db                	test   %ebx,%ebx
f01010a2:	74 02                	je     f01010a6 <page_lookup+0x33>
		*pte_store = pte;
f01010a4:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f01010a6:	8b 00                	mov    (%eax),%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010a8:	c1 e8 0c             	shr    $0xc,%eax
f01010ab:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01010b1:	72 1c                	jb     f01010cf <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01010b3:	c7 44 24 08 10 43 10 	movl   $0xf0104310,0x8(%esp)
f01010ba:	f0 
f01010bb:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01010c2:	00 
f01010c3:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f01010ca:	e8 c5 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01010cf:	c1 e0 03             	shl    $0x3,%eax
f01010d2:	03 05 88 79 11 f0    	add    0xf0117988,%eax
f01010d8:	eb 0c                	jmp    f01010e6 <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(!pte || !(*pte & 1)) /* if pte is null, pte & 1 is 0 */
		return NULL;
f01010da:	b8 00 00 00 00       	mov    $0x0,%eax
f01010df:	eb 05                	jmp    f01010e6 <page_lookup+0x73>
f01010e1:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01010e6:	83 c4 14             	add    $0x14,%esp
f01010e9:	5b                   	pop    %ebx
f01010ea:	5d                   	pop    %ebp
f01010eb:	c3                   	ret    

f01010ec <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010ec:	55                   	push   %ebp
f01010ed:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f2:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01010f5:	5d                   	pop    %ebp
f01010f6:	c3                   	ret    

f01010f7 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010f7:	55                   	push   %ebp
f01010f8:	89 e5                	mov    %esp,%ebp
f01010fa:	83 ec 28             	sub    $0x28,%esp
f01010fd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101100:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101103:	8b 75 08             	mov    0x8(%ebp),%esi
f0101106:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct Page *pp = page_lookup(pgdir, va, &pte);
f0101109:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010110c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101110:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101114:	89 34 24             	mov    %esi,(%esp)
f0101117:	e8 57 ff ff ff       	call   f0101073 <page_lookup>
	if(!pp)
f010111c:	85 c0                	test   %eax,%eax
f010111e:	74 1d                	je     f010113d <page_remove+0x46>
		return;
	page_decref(pp);
f0101120:	89 04 24             	mov    %eax,(%esp)
f0101123:	e8 f0 fd ff ff       	call   f0100f18 <page_decref>
	*pte = 0;
f0101128:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010112b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101135:	89 34 24             	mov    %esi,(%esp)
f0101138:	e8 af ff ff ff       	call   f01010ec <tlb_invalidate>
	
}
f010113d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101140:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101143:	89 ec                	mov    %ebp,%esp
f0101145:	5d                   	pop    %ebp
f0101146:	c3                   	ret    

f0101147 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101147:	55                   	push   %ebp
f0101148:	89 e5                	mov    %esp,%ebp
f010114a:	83 ec 28             	sub    $0x28,%esp
f010114d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101150:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101153:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101156:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101159:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010115c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101163:	00 
f0101164:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101168:	8b 45 08             	mov    0x8(%ebp),%eax
f010116b:	89 04 24             	mov    %eax,(%esp)
f010116e:	e8 c8 fd ff ff       	call   f0100f3b <pgdir_walk>
f0101173:	89 c3                	mov    %eax,%ebx
	if(!pte)
f0101175:	85 c0                	test   %eax,%eax
f0101177:	74 66                	je     f01011df <page_insert+0x98>
		return -E_NO_MEM;
	if(*pte & PTE_P) { /* already a page */
f0101179:	8b 00                	mov    (%eax),%eax
f010117b:	a8 01                	test   $0x1,%al
f010117d:	74 3c                	je     f01011bb <page_insert+0x74>
		if(PTE_ADDR(*pte) == page2pa(pp)){	/* the same one */
f010117f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101184:	89 f2                	mov    %esi,%edx
f0101186:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010118c:	c1 fa 03             	sar    $0x3,%edx
f010118f:	c1 e2 0c             	shl    $0xc,%edx
f0101192:	39 d0                	cmp    %edx,%eax
f0101194:	75 16                	jne    f01011ac <page_insert+0x65>
			tlb_invalidate(pgdir, va);
f0101196:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010119a:	8b 45 08             	mov    0x8(%ebp),%eax
f010119d:	89 04 24             	mov    %eax,(%esp)
f01011a0:	e8 47 ff ff ff       	call   f01010ec <tlb_invalidate>
			pp -> pp_ref--;
f01011a5:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f01011aa:	eb 0f                	jmp    f01011bb <page_insert+0x74>
		}else
			page_remove(pgdir, va);
f01011ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b3:	89 04 24             	mov    %eax,(%esp)
f01011b6:	e8 3c ff ff ff       	call   f01010f7 <page_remove>
	}
	*pte = page2pa(pp)|perm|PTE_P;
f01011bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011be:	83 c8 01             	or     $0x1,%eax
f01011c1:	89 f2                	mov    %esi,%edx
f01011c3:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01011c9:	c1 fa 03             	sar    $0x3,%edx
f01011cc:	c1 e2 0c             	shl    $0xc,%edx
f01011cf:	09 d0                	or     %edx,%eax
f01011d1:	89 03                	mov    %eax,(%ebx)
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
f01011d3:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f01011d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011dd:	eb 05                	jmp    f01011e4 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);
	if(!pte)
		return -E_NO_MEM;
f01011df:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*pte = page2pa(pp)|perm|PTE_P;
	//cprintf("* is %x, *", *pte);
	pp -> pp_ref++;
	return 0;
}
f01011e4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01011e7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01011ea:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01011ed:	89 ec                	mov    %ebp,%esp
f01011ef:	5d                   	pop    %ebp
f01011f0:	c3                   	ret    

f01011f1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011f1:	55                   	push   %ebp
f01011f2:	89 e5                	mov    %esp,%ebp
f01011f4:	57                   	push   %edi
f01011f5:	56                   	push   %esi
f01011f6:	53                   	push   %ebx
f01011f7:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011fa:	b8 15 00 00 00       	mov    $0x15,%eax
f01011ff:	e8 0f f8 ff ff       	call   f0100a13 <nvram_read>
f0101204:	c1 e0 0a             	shl    $0xa,%eax
f0101207:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010120d:	85 c0                	test   %eax,%eax
f010120f:	0f 48 c2             	cmovs  %edx,%eax
f0101212:	c1 f8 0c             	sar    $0xc,%eax
f0101215:	a3 58 75 11 f0       	mov    %eax,0xf0117558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010121a:	b8 17 00 00 00       	mov    $0x17,%eax
f010121f:	e8 ef f7 ff ff       	call   f0100a13 <nvram_read>
f0101224:	c1 e0 0a             	shl    $0xa,%eax
f0101227:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010122d:	85 c0                	test   %eax,%eax
f010122f:	0f 48 c2             	cmovs  %edx,%eax
f0101232:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101235:	85 c0                	test   %eax,%eax
f0101237:	74 0e                	je     f0101247 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101239:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010123f:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f0101245:	eb 0c                	jmp    f0101253 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101247:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
f010124d:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101253:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101256:	c1 e8 0a             	shr    $0xa,%eax
f0101259:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010125d:	a1 58 75 11 f0       	mov    0xf0117558,%eax
f0101262:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101265:	c1 e8 0a             	shr    $0xa,%eax
f0101268:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010126c:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101271:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101274:	c1 e8 0a             	shr    $0xa,%eax
f0101277:	89 44 24 04          	mov    %eax,0x4(%esp)
f010127b:	c7 04 24 30 43 10 f0 	movl   $0xf0104330,(%esp)
f0101282:	e8 4f 1a 00 00       	call   f0102cd6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101287:	b8 00 10 00 00       	mov    $0x1000,%eax
f010128c:	e8 10 f7 ff ff       	call   f01009a1 <boot_alloc>
f0101291:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	memset(kern_pgdir, 0, PGSIZE);
f0101296:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010129d:	00 
f010129e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012a5:	00 
f01012a6:	89 04 24             	mov    %eax,(%esp)
f01012a9:	e8 68 25 00 00       	call   f0103816 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012ae:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012b8:	77 20                	ja     f01012da <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012be:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f01012c5:	f0 
f01012c6:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f01012cd:	00 
f01012ce:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01012d5:	e8 ba ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012da:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012e0:	83 ca 05             	or     $0x5,%edx
f01012e3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct Page *)boot_alloc(npages * sizeof(struct Page));
f01012e9:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01012ee:	c1 e0 03             	shl    $0x3,%eax
f01012f1:	e8 ab f6 ff ff       	call   f01009a1 <boot_alloc>
f01012f6:	a3 88 79 11 f0       	mov    %eax,0xf0117988
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012fb:	e8 a2 fa ff ff       	call   f0100da2 <page_init>

	check_page_free_list(1);
f0101300:	b8 01 00 00 00       	mov    $0x1,%eax
f0101305:	e8 3b f7 ff ff       	call   f0100a45 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f010130a:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f0101311:	75 1c                	jne    f010132f <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f0101313:	c7 44 24 08 b7 49 10 	movl   $0xf01049b7,0x8(%esp)
f010131a:	f0 
f010131b:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0101322:	00 
f0101323:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010132a:	e8 65 ed ff ff       	call   f0100094 <_panic>
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010132f:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f0101334:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101339:	85 c0                	test   %eax,%eax
f010133b:	74 09                	je     f0101346 <mem_init+0x155>
		++nfree;
f010133d:	83 c3 01             	add    $0x1,%ebx
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101340:	8b 00                	mov    (%eax),%eax
f0101342:	85 c0                	test   %eax,%eax
f0101344:	75 f7                	jne    f010133d <mem_init+0x14c>
		++nfree;
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101346:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010134d:	e8 26 fb ff ff       	call   f0100e78 <page_alloc>
f0101352:	89 c6                	mov    %eax,%esi
f0101354:	85 c0                	test   %eax,%eax
f0101356:	75 24                	jne    f010137c <mem_init+0x18b>
f0101358:	c7 44 24 0c d2 49 10 	movl   $0xf01049d2,0xc(%esp)
f010135f:	f0 
f0101360:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101367:	f0 
f0101368:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f010136f:	00 
f0101370:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101377:	e8 18 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010137c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101383:	e8 f0 fa ff ff       	call   f0100e78 <page_alloc>
f0101388:	89 c7                	mov    %eax,%edi
f010138a:	85 c0                	test   %eax,%eax
f010138c:	75 24                	jne    f01013b2 <mem_init+0x1c1>
f010138e:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f0101395:	f0 
f0101396:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010139d:	f0 
f010139e:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f01013a5:	00 
f01013a6:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01013ad:	e8 e2 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013b9:	e8 ba fa ff ff       	call   f0100e78 <page_alloc>
f01013be:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	75 24                	jne    f01013e9 <mem_init+0x1f8>
f01013c5:	c7 44 24 0c fe 49 10 	movl   $0xf01049fe,0xc(%esp)
f01013cc:	f0 
f01013cd:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01013d4:	f0 
f01013d5:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f01013dc:	00 
f01013dd:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01013e4:	e8 ab ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e9:	39 fe                	cmp    %edi,%esi
f01013eb:	75 24                	jne    f0101411 <mem_init+0x220>
f01013ed:	c7 44 24 0c 14 4a 10 	movl   $0xf0104a14,0xc(%esp)
f01013f4:	f0 
f01013f5:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01013fc:	f0 
f01013fd:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101404:	00 
f0101405:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010140c:	e8 83 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101411:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101414:	74 05                	je     f010141b <mem_init+0x22a>
f0101416:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101419:	75 24                	jne    f010143f <mem_init+0x24e>
f010141b:	c7 44 24 0c 6c 43 10 	movl   $0xf010436c,0xc(%esp)
f0101422:	f0 
f0101423:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010142a:	f0 
f010142b:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f0101432:	00 
f0101433:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010143a:	e8 55 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010143f:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101445:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f010144a:	c1 e0 0c             	shl    $0xc,%eax
f010144d:	89 f1                	mov    %esi,%ecx
f010144f:	29 d1                	sub    %edx,%ecx
f0101451:	c1 f9 03             	sar    $0x3,%ecx
f0101454:	c1 e1 0c             	shl    $0xc,%ecx
f0101457:	39 c1                	cmp    %eax,%ecx
f0101459:	72 24                	jb     f010147f <mem_init+0x28e>
f010145b:	c7 44 24 0c 26 4a 10 	movl   $0xf0104a26,0xc(%esp)
f0101462:	f0 
f0101463:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010146a:	f0 
f010146b:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0101472:	00 
f0101473:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010147a:	e8 15 ec ff ff       	call   f0100094 <_panic>
f010147f:	89 f9                	mov    %edi,%ecx
f0101481:	29 d1                	sub    %edx,%ecx
f0101483:	c1 f9 03             	sar    $0x3,%ecx
f0101486:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101489:	39 c8                	cmp    %ecx,%eax
f010148b:	77 24                	ja     f01014b1 <mem_init+0x2c0>
f010148d:	c7 44 24 0c 43 4a 10 	movl   $0xf0104a43,0xc(%esp)
f0101494:	f0 
f0101495:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010149c:	f0 
f010149d:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f01014a4:	00 
f01014a5:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01014ac:	e8 e3 eb ff ff       	call   f0100094 <_panic>
f01014b1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014b4:	29 d1                	sub    %edx,%ecx
f01014b6:	89 ca                	mov    %ecx,%edx
f01014b8:	c1 fa 03             	sar    $0x3,%edx
f01014bb:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014be:	39 d0                	cmp    %edx,%eax
f01014c0:	77 24                	ja     f01014e6 <mem_init+0x2f5>
f01014c2:	c7 44 24 0c 60 4a 10 	movl   $0xf0104a60,0xc(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01014d1:	f0 
f01014d2:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f01014d9:	00 
f01014da:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01014e1:	e8 ae eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014e6:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f01014eb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014ee:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f01014f5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ff:	e8 74 f9 ff ff       	call   f0100e78 <page_alloc>
f0101504:	85 c0                	test   %eax,%eax
f0101506:	74 24                	je     f010152c <mem_init+0x33b>
f0101508:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f010150f:	f0 
f0101510:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101517:	f0 
f0101518:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f010151f:	00 
f0101520:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101527:	e8 68 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010152c:	89 34 24             	mov    %esi,(%esp)
f010152f:	e8 c8 f9 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f0101534:	89 3c 24             	mov    %edi,(%esp)
f0101537:	e8 c0 f9 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f010153c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010153f:	89 04 24             	mov    %eax,(%esp)
f0101542:	e8 b5 f9 ff ff       	call   f0100efc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101547:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010154e:	e8 25 f9 ff ff       	call   f0100e78 <page_alloc>
f0101553:	89 c6                	mov    %eax,%esi
f0101555:	85 c0                	test   %eax,%eax
f0101557:	75 24                	jne    f010157d <mem_init+0x38c>
f0101559:	c7 44 24 0c d2 49 10 	movl   $0xf01049d2,0xc(%esp)
f0101560:	f0 
f0101561:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101568:	f0 
f0101569:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f0101570:	00 
f0101571:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101578:	e8 17 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010157d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101584:	e8 ef f8 ff ff       	call   f0100e78 <page_alloc>
f0101589:	89 c7                	mov    %eax,%edi
f010158b:	85 c0                	test   %eax,%eax
f010158d:	75 24                	jne    f01015b3 <mem_init+0x3c2>
f010158f:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f0101596:	f0 
f0101597:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010159e:	f0 
f010159f:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01015a6:	00 
f01015a7:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01015ae:	e8 e1 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ba:	e8 b9 f8 ff ff       	call   f0100e78 <page_alloc>
f01015bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c2:	85 c0                	test   %eax,%eax
f01015c4:	75 24                	jne    f01015ea <mem_init+0x3f9>
f01015c6:	c7 44 24 0c fe 49 10 	movl   $0xf01049fe,0xc(%esp)
f01015cd:	f0 
f01015ce:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01015d5:	f0 
f01015d6:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f01015dd:	00 
f01015de:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01015e5:	e8 aa ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015ea:	39 fe                	cmp    %edi,%esi
f01015ec:	75 24                	jne    f0101612 <mem_init+0x421>
f01015ee:	c7 44 24 0c 14 4a 10 	movl   $0xf0104a14,0xc(%esp)
f01015f5:	f0 
f01015f6:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01015fd:	f0 
f01015fe:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101605:	00 
f0101606:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010160d:	e8 82 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101612:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101615:	74 05                	je     f010161c <mem_init+0x42b>
f0101617:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010161a:	75 24                	jne    f0101640 <mem_init+0x44f>
f010161c:	c7 44 24 0c 6c 43 10 	movl   $0xf010436c,0xc(%esp)
f0101623:	f0 
f0101624:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010162b:	f0 
f010162c:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101633:	00 
f0101634:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010163b:	e8 54 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101640:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101647:	e8 2c f8 ff ff       	call   f0100e78 <page_alloc>
f010164c:	85 c0                	test   %eax,%eax
f010164e:	74 24                	je     f0101674 <mem_init+0x483>
f0101650:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f0101657:	f0 
f0101658:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010165f:	f0 
f0101660:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101667:	00 
f0101668:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010166f:	e8 20 ea ff ff       	call   f0100094 <_panic>
f0101674:	89 f0                	mov    %esi,%eax
f0101676:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010167c:	c1 f8 03             	sar    $0x3,%eax
f010167f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101682:	89 c2                	mov    %eax,%edx
f0101684:	c1 ea 0c             	shr    $0xc,%edx
f0101687:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010168d:	72 20                	jb     f01016af <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010168f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101693:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f010169a:	f0 
f010169b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01016a2:	00 
f01016a3:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f01016aa:	e8 e5 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016af:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016b6:	00 
f01016b7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016be:	00 
	return (void *)(pa + KERNBASE);
f01016bf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016c4:	89 04 24             	mov    %eax,(%esp)
f01016c7:	e8 4a 21 00 00       	call   f0103816 <memset>
	page_free(pp0);
f01016cc:	89 34 24             	mov    %esi,(%esp)
f01016cf:	e8 28 f8 ff ff       	call   f0100efc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016d4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016db:	e8 98 f7 ff ff       	call   f0100e78 <page_alloc>
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	75 24                	jne    f0101708 <mem_init+0x517>
f01016e4:	c7 44 24 0c 8c 4a 10 	movl   $0xf0104a8c,0xc(%esp)
f01016eb:	f0 
f01016ec:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01016f3:	f0 
f01016f4:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01016fb:	00 
f01016fc:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101703:	e8 8c e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101708:	39 c6                	cmp    %eax,%esi
f010170a:	74 24                	je     f0101730 <mem_init+0x53f>
f010170c:	c7 44 24 0c aa 4a 10 	movl   $0xf0104aaa,0xc(%esp)
f0101713:	f0 
f0101714:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010171b:	f0 
f010171c:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101723:	00 
f0101724:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010172b:	e8 64 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101730:	89 f2                	mov    %esi,%edx
f0101732:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101738:	c1 fa 03             	sar    $0x3,%edx
f010173b:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010173e:	89 d0                	mov    %edx,%eax
f0101740:	c1 e8 0c             	shr    $0xc,%eax
f0101743:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101749:	72 20                	jb     f010176b <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010174b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010174f:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0101756:	f0 
f0101757:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010175e:	00 
f010175f:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0101766:	e8 29 e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010176b:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101772:	75 11                	jne    f0101785 <mem_init+0x594>
f0101774:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010177a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101780:	80 38 00             	cmpb   $0x0,(%eax)
f0101783:	74 24                	je     f01017a9 <mem_init+0x5b8>
f0101785:	c7 44 24 0c ba 4a 10 	movl   $0xf0104aba,0xc(%esp)
f010178c:	f0 
f010178d:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101794:	f0 
f0101795:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010179c:	00 
f010179d:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01017a4:	e8 eb e8 ff ff       	call   f0100094 <_panic>
f01017a9:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017ac:	39 d0                	cmp    %edx,%eax
f01017ae:	75 d0                	jne    f0101780 <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017b0:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017b3:	89 15 60 75 11 f0    	mov    %edx,0xf0117560

	// free the pages we took
	page_free(pp0);
f01017b9:	89 34 24             	mov    %esi,(%esp)
f01017bc:	e8 3b f7 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f01017c1:	89 3c 24             	mov    %edi,(%esp)
f01017c4:	e8 33 f7 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f01017c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017cc:	89 04 24             	mov    %eax,(%esp)
f01017cf:	e8 28 f7 ff ff       	call   f0100efc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017d4:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f01017d9:	85 c0                	test   %eax,%eax
f01017db:	74 09                	je     f01017e6 <mem_init+0x5f5>
		--nfree;
f01017dd:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017e0:	8b 00                	mov    (%eax),%eax
f01017e2:	85 c0                	test   %eax,%eax
f01017e4:	75 f7                	jne    f01017dd <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f01017e6:	85 db                	test   %ebx,%ebx
f01017e8:	74 24                	je     f010180e <mem_init+0x61d>
f01017ea:	c7 44 24 0c c4 4a 10 	movl   $0xf0104ac4,0xc(%esp)
f01017f1:	f0 
f01017f2:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01017f9:	f0 
f01017fa:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101801:	00 
f0101802:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101809:	e8 86 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010180e:	c7 04 24 8c 43 10 f0 	movl   $0xf010438c,(%esp)
f0101815:	e8 bc 14 00 00       	call   f0102cd6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010181a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101821:	e8 52 f6 ff ff       	call   f0100e78 <page_alloc>
f0101826:	89 c3                	mov    %eax,%ebx
f0101828:	85 c0                	test   %eax,%eax
f010182a:	75 24                	jne    f0101850 <mem_init+0x65f>
f010182c:	c7 44 24 0c d2 49 10 	movl   $0xf01049d2,0xc(%esp)
f0101833:	f0 
f0101834:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010183b:	f0 
f010183c:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101843:	00 
f0101844:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010184b:	e8 44 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101850:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101857:	e8 1c f6 ff ff       	call   f0100e78 <page_alloc>
f010185c:	89 c7                	mov    %eax,%edi
f010185e:	85 c0                	test   %eax,%eax
f0101860:	75 24                	jne    f0101886 <mem_init+0x695>
f0101862:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f0101869:	f0 
f010186a:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101871:	f0 
f0101872:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0101879:	00 
f010187a:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101881:	e8 0e e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101886:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010188d:	e8 e6 f5 ff ff       	call   f0100e78 <page_alloc>
f0101892:	89 c6                	mov    %eax,%esi
f0101894:	85 c0                	test   %eax,%eax
f0101896:	75 24                	jne    f01018bc <mem_init+0x6cb>
f0101898:	c7 44 24 0c fe 49 10 	movl   $0xf01049fe,0xc(%esp)
f010189f:	f0 
f01018a0:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01018a7:	f0 
f01018a8:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01018af:	00 
f01018b0:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01018b7:	e8 d8 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018bc:	39 fb                	cmp    %edi,%ebx
f01018be:	75 24                	jne    f01018e4 <mem_init+0x6f3>
f01018c0:	c7 44 24 0c 14 4a 10 	movl   $0xf0104a14,0xc(%esp)
f01018c7:	f0 
f01018c8:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01018cf:	f0 
f01018d0:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f01018d7:	00 
f01018d8:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01018df:	e8 b0 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018e4:	39 c7                	cmp    %eax,%edi
f01018e6:	74 04                	je     f01018ec <mem_init+0x6fb>
f01018e8:	39 c3                	cmp    %eax,%ebx
f01018ea:	75 24                	jne    f0101910 <mem_init+0x71f>
f01018ec:	c7 44 24 0c 6c 43 10 	movl   $0xf010436c,0xc(%esp)
f01018f3:	f0 
f01018f4:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01018fb:	f0 
f01018fc:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101903:	00 
f0101904:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010190b:	e8 84 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101910:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0101916:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101919:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0101920:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101923:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010192a:	e8 49 f5 ff ff       	call   f0100e78 <page_alloc>
f010192f:	85 c0                	test   %eax,%eax
f0101931:	74 24                	je     f0101957 <mem_init+0x766>
f0101933:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f010193a:	f0 
f010193b:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101942:	f0 
f0101943:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f010194a:	00 
f010194b:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101952:	e8 3d e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101957:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010195a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010195e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101965:	00 
f0101966:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010196b:	89 04 24             	mov    %eax,(%esp)
f010196e:	e8 00 f7 ff ff       	call   f0101073 <page_lookup>
f0101973:	85 c0                	test   %eax,%eax
f0101975:	74 24                	je     f010199b <mem_init+0x7aa>
f0101977:	c7 44 24 0c ac 43 10 	movl   $0xf01043ac,0xc(%esp)
f010197e:	f0 
f010197f:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101986:	f0 
f0101987:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f010198e:	00 
f010198f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101996:	e8 f9 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010199b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019a2:	00 
f01019a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019aa:	00 
f01019ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01019af:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01019b4:	89 04 24             	mov    %eax,(%esp)
f01019b7:	e8 8b f7 ff ff       	call   f0101147 <page_insert>
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	78 24                	js     f01019e4 <mem_init+0x7f3>
f01019c0:	c7 44 24 0c e4 43 10 	movl   $0xf01043e4,0xc(%esp)
f01019c7:	f0 
f01019c8:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01019cf:	f0 
f01019d0:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f01019d7:	00 
f01019d8:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01019df:	e8 b0 e6 ff ff       	call   f0100094 <_panic>
//panic("\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019e4:	89 1c 24             	mov    %ebx,(%esp)
f01019e7:	e8 10 f5 ff ff       	call   f0100efc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019ec:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019f3:	00 
f01019f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019fb:	00 
f01019fc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a00:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101a05:	89 04 24             	mov    %eax,(%esp)
f0101a08:	e8 3a f7 ff ff       	call   f0101147 <page_insert>
f0101a0d:	85 c0                	test   %eax,%eax
f0101a0f:	74 24                	je     f0101a35 <mem_init+0x844>
f0101a11:	c7 44 24 0c 14 44 10 	movl   $0xf0104414,0xc(%esp)
f0101a18:	f0 
f0101a19:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101a20:	f0 
f0101a21:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101a28:	00 
f0101a29:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101a30:	e8 5f e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a35:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f0101a3b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a3e:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0101a43:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a46:	8b 11                	mov    (%ecx),%edx
f0101a48:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a4e:	89 d8                	mov    %ebx,%eax
f0101a50:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a53:	c1 f8 03             	sar    $0x3,%eax
f0101a56:	c1 e0 0c             	shl    $0xc,%eax
f0101a59:	39 c2                	cmp    %eax,%edx
f0101a5b:	74 24                	je     f0101a81 <mem_init+0x890>
f0101a5d:	c7 44 24 0c 44 44 10 	movl   $0xf0104444,0xc(%esp)
f0101a64:	f0 
f0101a65:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101a6c:	f0 
f0101a6d:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101a74:	00 
f0101a75:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101a7c:	e8 13 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a81:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a89:	e8 a2 ee ff ff       	call   f0100930 <check_va2pa>
f0101a8e:	89 fa                	mov    %edi,%edx
f0101a90:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a93:	c1 fa 03             	sar    $0x3,%edx
f0101a96:	c1 e2 0c             	shl    $0xc,%edx
f0101a99:	39 d0                	cmp    %edx,%eax
f0101a9b:	74 24                	je     f0101ac1 <mem_init+0x8d0>
f0101a9d:	c7 44 24 0c 6c 44 10 	movl   $0xf010446c,0xc(%esp)
f0101aa4:	f0 
f0101aa5:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101aac:	f0 
f0101aad:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101ab4:	00 
f0101ab5:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101abc:	e8 d3 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101ac1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ac6:	74 24                	je     f0101aec <mem_init+0x8fb>
f0101ac8:	c7 44 24 0c cf 4a 10 	movl   $0xf0104acf,0xc(%esp)
f0101acf:	f0 
f0101ad0:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101ad7:	f0 
f0101ad8:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101adf:	00 
f0101ae0:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101ae7:	e8 a8 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101aec:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101af1:	74 24                	je     f0101b17 <mem_init+0x926>
f0101af3:	c7 44 24 0c e0 4a 10 	movl   $0xf0104ae0,0xc(%esp)
f0101afa:	f0 
f0101afb:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101b02:	f0 
f0101b03:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101b0a:	00 
f0101b0b:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101b12:	e8 7d e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b17:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b1e:	00 
f0101b1f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b26:	00 
f0101b27:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b2b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b2e:	89 14 24             	mov    %edx,(%esp)
f0101b31:	e8 11 f6 ff ff       	call   f0101147 <page_insert>
f0101b36:	85 c0                	test   %eax,%eax
f0101b38:	74 24                	je     f0101b5e <mem_init+0x96d>
f0101b3a:	c7 44 24 0c 9c 44 10 	movl   $0xf010449c,0xc(%esp)
f0101b41:	f0 
f0101b42:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101b49:	f0 
f0101b4a:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101b51:	00 
f0101b52:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101b59:	e8 36 e5 ff ff       	call   f0100094 <_panic>
	//panic("va2pa: %x,page %x", check_va2pa(kern_pgdir, PGSIZE), page2pa(pp2));
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b5e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b63:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101b68:	e8 c3 ed ff ff       	call   f0100930 <check_va2pa>
f0101b6d:	89 f2                	mov    %esi,%edx
f0101b6f:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101b75:	c1 fa 03             	sar    $0x3,%edx
f0101b78:	c1 e2 0c             	shl    $0xc,%edx
f0101b7b:	39 d0                	cmp    %edx,%eax
f0101b7d:	74 24                	je     f0101ba3 <mem_init+0x9b2>
f0101b7f:	c7 44 24 0c d8 44 10 	movl   $0xf01044d8,0xc(%esp)
f0101b86:	f0 
f0101b87:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101b8e:	f0 
f0101b8f:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101b96:	00 
f0101b97:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101b9e:	e8 f1 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ba3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ba8:	74 24                	je     f0101bce <mem_init+0x9dd>
f0101baa:	c7 44 24 0c f1 4a 10 	movl   $0xf0104af1,0xc(%esp)
f0101bb1:	f0 
f0101bb2:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101bb9:	f0 
f0101bba:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101bc1:	00 
f0101bc2:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101bc9:	e8 c6 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bd5:	e8 9e f2 ff ff       	call   f0100e78 <page_alloc>
f0101bda:	85 c0                	test   %eax,%eax
f0101bdc:	74 24                	je     f0101c02 <mem_init+0xa11>
f0101bde:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f0101be5:	f0 
f0101be6:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101bed:	f0 
f0101bee:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101bf5:	00 
f0101bf6:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101bfd:	e8 92 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c02:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c09:	00 
f0101c0a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c11:	00 
f0101c12:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c16:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101c1b:	89 04 24             	mov    %eax,(%esp)
f0101c1e:	e8 24 f5 ff ff       	call   f0101147 <page_insert>
f0101c23:	85 c0                	test   %eax,%eax
f0101c25:	74 24                	je     f0101c4b <mem_init+0xa5a>
f0101c27:	c7 44 24 0c 9c 44 10 	movl   $0xf010449c,0xc(%esp)
f0101c2e:	f0 
f0101c2f:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101c36:	f0 
f0101c37:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101c3e:	00 
f0101c3f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101c46:	e8 49 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c50:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101c55:	e8 d6 ec ff ff       	call   f0100930 <check_va2pa>
f0101c5a:	89 f2                	mov    %esi,%edx
f0101c5c:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101c62:	c1 fa 03             	sar    $0x3,%edx
f0101c65:	c1 e2 0c             	shl    $0xc,%edx
f0101c68:	39 d0                	cmp    %edx,%eax
f0101c6a:	74 24                	je     f0101c90 <mem_init+0xa9f>
f0101c6c:	c7 44 24 0c d8 44 10 	movl   $0xf01044d8,0xc(%esp)
f0101c73:	f0 
f0101c74:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101c7b:	f0 
f0101c7c:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101c83:	00 
f0101c84:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101c8b:	e8 04 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c90:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c95:	74 24                	je     f0101cbb <mem_init+0xaca>
f0101c97:	c7 44 24 0c f1 4a 10 	movl   $0xf0104af1,0xc(%esp)
f0101c9e:	f0 
f0101c9f:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101ca6:	f0 
f0101ca7:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101cae:	00 
f0101caf:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101cb6:	e8 d9 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cbb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cc2:	e8 b1 f1 ff ff       	call   f0100e78 <page_alloc>
f0101cc7:	85 c0                	test   %eax,%eax
f0101cc9:	74 24                	je     f0101cef <mem_init+0xafe>
f0101ccb:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101cda:	f0 
f0101cdb:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101ce2:	00 
f0101ce3:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101cea:	e8 a5 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cef:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101cf5:	8b 02                	mov    (%edx),%eax
f0101cf7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cfc:	89 c1                	mov    %eax,%ecx
f0101cfe:	c1 e9 0c             	shr    $0xc,%ecx
f0101d01:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101d07:	72 20                	jb     f0101d29 <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d09:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d0d:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0101d14:	f0 
f0101d15:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101d1c:	00 
f0101d1d:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101d24:	e8 6b e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d29:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d2e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d31:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d38:	00 
f0101d39:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d40:	00 
f0101d41:	89 14 24             	mov    %edx,(%esp)
f0101d44:	e8 f2 f1 ff ff       	call   f0100f3b <pgdir_walk>
f0101d49:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d4c:	83 c2 04             	add    $0x4,%edx
f0101d4f:	39 d0                	cmp    %edx,%eax
f0101d51:	74 24                	je     f0101d77 <mem_init+0xb86>
f0101d53:	c7 44 24 0c 08 45 10 	movl   $0xf0104508,0xc(%esp)
f0101d5a:	f0 
f0101d5b:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101d62:	f0 
f0101d63:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101d6a:	00 
f0101d6b:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101d72:	e8 1d e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d77:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d7e:	00 
f0101d7f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d86:	00 
f0101d87:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d8b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101d90:	89 04 24             	mov    %eax,(%esp)
f0101d93:	e8 af f3 ff ff       	call   f0101147 <page_insert>
f0101d98:	85 c0                	test   %eax,%eax
f0101d9a:	74 24                	je     f0101dc0 <mem_init+0xbcf>
f0101d9c:	c7 44 24 0c 48 45 10 	movl   $0xf0104548,0xc(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101dab:	f0 
f0101dac:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101db3:	00 
f0101db4:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101dbb:	e8 d4 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dc0:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f0101dc6:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101dc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dce:	89 c8                	mov    %ecx,%eax
f0101dd0:	e8 5b eb ff ff       	call   f0100930 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101dd5:	89 f2                	mov    %esi,%edx
f0101dd7:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101ddd:	c1 fa 03             	sar    $0x3,%edx
f0101de0:	c1 e2 0c             	shl    $0xc,%edx
f0101de3:	39 d0                	cmp    %edx,%eax
f0101de5:	74 24                	je     f0101e0b <mem_init+0xc1a>
f0101de7:	c7 44 24 0c d8 44 10 	movl   $0xf01044d8,0xc(%esp)
f0101dee:	f0 
f0101def:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101dfe:	00 
f0101dff:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101e06:	e8 89 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e0b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e10:	74 24                	je     f0101e36 <mem_init+0xc45>
f0101e12:	c7 44 24 0c f1 4a 10 	movl   $0xf0104af1,0xc(%esp)
f0101e19:	f0 
f0101e1a:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101e21:	f0 
f0101e22:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101e29:	00 
f0101e2a:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101e31:	e8 5e e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e36:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e3d:	00 
f0101e3e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e45:	00 
f0101e46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e49:	89 04 24             	mov    %eax,(%esp)
f0101e4c:	e8 ea f0 ff ff       	call   f0100f3b <pgdir_walk>
f0101e51:	f6 00 04             	testb  $0x4,(%eax)
f0101e54:	75 24                	jne    f0101e7a <mem_init+0xc89>
f0101e56:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0101e5d:	f0 
f0101e5e:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101e65:	f0 
f0101e66:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101e6d:	00 
f0101e6e:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101e75:	e8 1a e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e7a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101e7f:	f6 00 04             	testb  $0x4,(%eax)
f0101e82:	75 24                	jne    f0101ea8 <mem_init+0xcb7>
f0101e84:	c7 44 24 0c 02 4b 10 	movl   $0xf0104b02,0xc(%esp)
f0101e8b:	f0 
f0101e8c:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101e93:	f0 
f0101e94:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101e9b:	00 
f0101e9c:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101ea3:	e8 ec e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ea8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eaf:	00 
f0101eb0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101eb7:	00 
f0101eb8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ebc:	89 04 24             	mov    %eax,(%esp)
f0101ebf:	e8 83 f2 ff ff       	call   f0101147 <page_insert>
f0101ec4:	85 c0                	test   %eax,%eax
f0101ec6:	78 24                	js     f0101eec <mem_init+0xcfb>
f0101ec8:	c7 44 24 0c bc 45 10 	movl   $0xf01045bc,0xc(%esp)
f0101ecf:	f0 
f0101ed0:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101ed7:	f0 
f0101ed8:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101edf:	00 
f0101ee0:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101ee7:	e8 a8 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101eec:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ef3:	00 
f0101ef4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101efb:	00 
f0101efc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f00:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f05:	89 04 24             	mov    %eax,(%esp)
f0101f08:	e8 3a f2 ff ff       	call   f0101147 <page_insert>
f0101f0d:	85 c0                	test   %eax,%eax
f0101f0f:	74 24                	je     f0101f35 <mem_init+0xd44>
f0101f11:	c7 44 24 0c f4 45 10 	movl   $0xf01045f4,0xc(%esp)
f0101f18:	f0 
f0101f19:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101f20:	f0 
f0101f21:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101f28:	00 
f0101f29:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101f30:	e8 5f e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f35:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f3c:	00 
f0101f3d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f44:	00 
f0101f45:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f4a:	89 04 24             	mov    %eax,(%esp)
f0101f4d:	e8 e9 ef ff ff       	call   f0100f3b <pgdir_walk>
f0101f52:	f6 00 04             	testb  $0x4,(%eax)
f0101f55:	74 24                	je     f0101f7b <mem_init+0xd8a>
f0101f57:	c7 44 24 0c 30 46 10 	movl   $0xf0104630,0xc(%esp)
f0101f5e:	f0 
f0101f5f:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101f6e:	00 
f0101f6f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101f76:	e8 19 e1 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f7b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101f80:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101f83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f88:	e8 a3 e9 ff ff       	call   f0100930 <check_va2pa>
f0101f8d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f90:	89 f8                	mov    %edi,%eax
f0101f92:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101f98:	c1 f8 03             	sar    $0x3,%eax
f0101f9b:	c1 e0 0c             	shl    $0xc,%eax
f0101f9e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fa1:	74 24                	je     f0101fc7 <mem_init+0xdd6>
f0101fa3:	c7 44 24 0c 68 46 10 	movl   $0xf0104668,0xc(%esp)
f0101faa:	f0 
f0101fab:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101fba:	00 
f0101fbb:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101fc2:	e8 cd e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fc7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fcc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fcf:	e8 5c e9 ff ff       	call   f0100930 <check_va2pa>
f0101fd4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fd7:	74 24                	je     f0101ffd <mem_init+0xe0c>
f0101fd9:	c7 44 24 0c 94 46 10 	movl   $0xf0104694,0xc(%esp)
f0101fe0:	f0 
f0101fe1:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0101fe8:	f0 
f0101fe9:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101ff0:	00 
f0101ff1:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0101ff8:	e8 97 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ffd:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102002:	74 24                	je     f0102028 <mem_init+0xe37>
f0102004:	c7 44 24 0c 18 4b 10 	movl   $0xf0104b18,0xc(%esp)
f010200b:	f0 
f010200c:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102013:	f0 
f0102014:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f010201b:	00 
f010201c:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102023:	e8 6c e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102028:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010202d:	74 24                	je     f0102053 <mem_init+0xe62>
f010202f:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0102036:	f0 
f0102037:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010203e:	f0 
f010203f:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0102046:	00 
f0102047:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010204e:	e8 41 e0 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102053:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010205a:	e8 19 ee ff ff       	call   f0100e78 <page_alloc>
f010205f:	85 c0                	test   %eax,%eax
f0102061:	74 04                	je     f0102067 <mem_init+0xe76>
f0102063:	39 c6                	cmp    %eax,%esi
f0102065:	74 24                	je     f010208b <mem_init+0xe9a>
f0102067:	c7 44 24 0c c4 46 10 	movl   $0xf01046c4,0xc(%esp)
f010206e:	f0 
f010206f:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102076:	f0 
f0102077:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f010207e:	00 
f010207f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102086:	e8 09 e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010208b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102092:	00 
f0102093:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102098:	89 04 24             	mov    %eax,(%esp)
f010209b:	e8 57 f0 ff ff       	call   f01010f7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020a0:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f01020a6:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01020a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b1:	e8 7a e8 ff ff       	call   f0100930 <check_va2pa>
f01020b6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b9:	74 24                	je     f01020df <mem_init+0xeee>
f01020bb:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f01020c2:	f0 
f01020c3:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01020ca:	f0 
f01020cb:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01020d2:	00 
f01020d3:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01020da:	e8 b5 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020df:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e7:	e8 44 e8 ff ff       	call   f0100930 <check_va2pa>
f01020ec:	89 fa                	mov    %edi,%edx
f01020ee:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01020f4:	c1 fa 03             	sar    $0x3,%edx
f01020f7:	c1 e2 0c             	shl    $0xc,%edx
f01020fa:	39 d0                	cmp    %edx,%eax
f01020fc:	74 24                	je     f0102122 <mem_init+0xf31>
f01020fe:	c7 44 24 0c 94 46 10 	movl   $0xf0104694,0xc(%esp)
f0102105:	f0 
f0102106:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010210d:	f0 
f010210e:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102115:	00 
f0102116:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010211d:	e8 72 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102122:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102127:	74 24                	je     f010214d <mem_init+0xf5c>
f0102129:	c7 44 24 0c cf 4a 10 	movl   $0xf0104acf,0xc(%esp)
f0102130:	f0 
f0102131:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102138:	f0 
f0102139:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0102140:	00 
f0102141:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102148:	e8 47 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010214d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102152:	74 24                	je     f0102178 <mem_init+0xf87>
f0102154:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f010215b:	f0 
f010215c:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102163:	f0 
f0102164:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f010216b:	00 
f010216c:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102173:	e8 1c df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102178:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010217f:	00 
f0102180:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102183:	89 0c 24             	mov    %ecx,(%esp)
f0102186:	e8 6c ef ff ff       	call   f01010f7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010218b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102190:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102193:	ba 00 00 00 00       	mov    $0x0,%edx
f0102198:	e8 93 e7 ff ff       	call   f0100930 <check_va2pa>
f010219d:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021a0:	74 24                	je     f01021c6 <mem_init+0xfd5>
f01021a2:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f01021a9:	f0 
f01021aa:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01021b1:	f0 
f01021b2:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01021b9:	00 
f01021ba:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01021c1:	e8 ce de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021c6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ce:	e8 5d e7 ff ff       	call   f0100930 <check_va2pa>
f01021d3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021d6:	74 24                	je     f01021fc <mem_init+0x100b>
f01021d8:	c7 44 24 0c 0c 47 10 	movl   $0xf010470c,0xc(%esp)
f01021df:	f0 
f01021e0:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01021e7:	f0 
f01021e8:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f01021ef:	00 
f01021f0:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01021f7:	e8 98 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01021fc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102201:	74 24                	je     f0102227 <mem_init+0x1036>
f0102203:	c7 44 24 0c 3a 4b 10 	movl   $0xf0104b3a,0xc(%esp)
f010220a:	f0 
f010220b:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102212:	f0 
f0102213:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f010221a:	00 
f010221b:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102222:	e8 6d de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102227:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010222c:	74 24                	je     f0102252 <mem_init+0x1061>
f010222e:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0102235:	f0 
f0102236:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010223d:	f0 
f010223e:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102245:	00 
f0102246:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010224d:	e8 42 de ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102252:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102259:	e8 1a ec ff ff       	call   f0100e78 <page_alloc>
f010225e:	85 c0                	test   %eax,%eax
f0102260:	74 04                	je     f0102266 <mem_init+0x1075>
f0102262:	39 c7                	cmp    %eax,%edi
f0102264:	74 24                	je     f010228a <mem_init+0x1099>
f0102266:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f010226d:	f0 
f010226e:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102275:	f0 
f0102276:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f010227d:	00 
f010227e:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102285:	e8 0a de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010228a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102291:	e8 e2 eb ff ff       	call   f0100e78 <page_alloc>
f0102296:	85 c0                	test   %eax,%eax
f0102298:	74 24                	je     f01022be <mem_init+0x10cd>
f010229a:	c7 44 24 0c 7d 4a 10 	movl   $0xf0104a7d,0xc(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01022a9:	f0 
f01022aa:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f01022b1:	00 
f01022b2:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01022b9:	e8 d6 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022be:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01022c3:	8b 08                	mov    (%eax),%ecx
f01022c5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01022cb:	89 da                	mov    %ebx,%edx
f01022cd:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01022d3:	c1 fa 03             	sar    $0x3,%edx
f01022d6:	c1 e2 0c             	shl    $0xc,%edx
f01022d9:	39 d1                	cmp    %edx,%ecx
f01022db:	74 24                	je     f0102301 <mem_init+0x1110>
f01022dd:	c7 44 24 0c 44 44 10 	movl   $0xf0104444,0xc(%esp)
f01022e4:	f0 
f01022e5:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01022ec:	f0 
f01022ed:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01022f4:	00 
f01022f5:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01022fc:	e8 93 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102301:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102307:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010230c:	74 24                	je     f0102332 <mem_init+0x1141>
f010230e:	c7 44 24 0c e0 4a 10 	movl   $0xf0104ae0,0xc(%esp)
f0102315:	f0 
f0102316:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010231d:	f0 
f010231e:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102325:	00 
f0102326:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010232d:	e8 62 dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102332:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102338:	89 1c 24             	mov    %ebx,(%esp)
f010233b:	e8 bc eb ff ff       	call   f0100efc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102340:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102347:	00 
f0102348:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010234f:	00 
f0102350:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102355:	89 04 24             	mov    %eax,(%esp)
f0102358:	e8 de eb ff ff       	call   f0100f3b <pgdir_walk>
f010235d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102360:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f0102366:	8b 51 04             	mov    0x4(%ecx),%edx
f0102369:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010236f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102372:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f0102378:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010237b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010237e:	c1 ea 0c             	shr    $0xc,%edx
f0102381:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102384:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102387:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010238a:	72 23                	jb     f01023af <mem_init+0x11be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010238c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010238f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102393:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f010239a:	f0 
f010239b:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01023a2:	00 
f01023a3:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01023aa:	e8 e5 dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01023af:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01023b2:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01023b8:	39 d0                	cmp    %edx,%eax
f01023ba:	74 24                	je     f01023e0 <mem_init+0x11ef>
f01023bc:	c7 44 24 0c 4b 4b 10 	movl   $0xf0104b4b,0xc(%esp)
f01023c3:	f0 
f01023c4:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01023cb:	f0 
f01023cc:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01023d3:	00 
f01023d4:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01023db:	e8 b4 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01023e0:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01023e7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01023ed:	89 d8                	mov    %ebx,%eax
f01023ef:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01023f5:	c1 f8 03             	sar    $0x3,%eax
f01023f8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023fb:	89 c1                	mov    %eax,%ecx
f01023fd:	c1 e9 0c             	shr    $0xc,%ecx
f0102400:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102403:	77 20                	ja     f0102425 <mem_init+0x1234>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102405:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102409:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0102410:	f0 
f0102411:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102418:	00 
f0102419:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0102420:	e8 6f dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102425:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010242c:	00 
f010242d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102434:	00 
	return (void *)(pa + KERNBASE);
f0102435:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010243a:	89 04 24             	mov    %eax,(%esp)
f010243d:	e8 d4 13 00 00       	call   f0103816 <memset>
	page_free(pp0);
f0102442:	89 1c 24             	mov    %ebx,(%esp)
f0102445:	e8 b2 ea ff ff       	call   f0100efc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010244a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102451:	00 
f0102452:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102459:	00 
f010245a:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010245f:	89 04 24             	mov    %eax,(%esp)
f0102462:	e8 d4 ea ff ff       	call   f0100f3b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102467:	89 da                	mov    %ebx,%edx
f0102469:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010246f:	c1 fa 03             	sar    $0x3,%edx
f0102472:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102475:	89 d0                	mov    %edx,%eax
f0102477:	c1 e8 0c             	shr    $0xc,%eax
f010247a:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0102480:	72 20                	jb     f01024a2 <mem_init+0x12b1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102482:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102486:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f010248d:	f0 
f010248e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102495:	00 
f0102496:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f010249d:	e8 f2 db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024a2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01024a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024ab:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01024b2:	75 11                	jne    f01024c5 <mem_init+0x12d4>
f01024b4:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01024ba:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024c0:	f6 00 01             	testb  $0x1,(%eax)
f01024c3:	74 24                	je     f01024e9 <mem_init+0x12f8>
f01024c5:	c7 44 24 0c 63 4b 10 	movl   $0xf0104b63,0xc(%esp)
f01024cc:	f0 
f01024cd:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01024d4:	f0 
f01024d5:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01024dc:	00 
f01024dd:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01024e4:	e8 ab db ff ff       	call   f0100094 <_panic>
f01024e9:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01024ec:	39 d0                	cmp    %edx,%eax
f01024ee:	75 d0                	jne    f01024c0 <mem_init+0x12cf>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01024f0:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01024f5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01024fb:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102501:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102504:	89 0d 60 75 11 f0    	mov    %ecx,0xf0117560

	// free the pages we took
	page_free(pp0);
f010250a:	89 1c 24             	mov    %ebx,(%esp)
f010250d:	e8 ea e9 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f0102512:	89 3c 24             	mov    %edi,(%esp)
f0102515:	e8 e2 e9 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f010251a:	89 34 24             	mov    %esi,(%esp)
f010251d:	e8 da e9 ff ff       	call   f0100efc <page_free>

	cprintf("check_page() succeeded!\n");
f0102522:	c7 04 24 7a 4b 10 f0 	movl   $0xf0104b7a,(%esp)
f0102529:	e8 a8 07 00 00       	call   f0102cd6 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
//pte_t *p = (pte_t *)0xf03fd000;
	boot_map_region(kern_pgdir,UPAGES, npages * sizeof(struct Page), PADDR(pages), PTE_U|PTE_P);
f010252e:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102533:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102538:	77 20                	ja     f010255a <mem_init+0x1369>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010253a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010253e:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f0102545:	f0 
f0102546:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
f010254d:	00 
f010254e:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102555:	e8 3a db ff ff       	call   f0100094 <_panic>
f010255a:	8b 0d 80 79 11 f0    	mov    0xf0117980,%ecx
f0102560:	c1 e1 03             	shl    $0x3,%ecx
f0102563:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010256a:	00 
	return (physaddr_t)kva - KERNBASE;
f010256b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102570:	89 04 24             	mov    %eax,(%esp)
f0102573:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102578:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010257d:	e8 9c ea ff ff       	call   f010101e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102582:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102587:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010258c:	77 20                	ja     f01025ae <mem_init+0x13bd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010258e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102592:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f0102599:	f0 
f010259a:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01025a9:	e8 e6 da ff ff       	call   f0100094 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
//	cprintf("\n%x\n", KSTACKTOP - KSTKSIZE);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_P|PTE_W);
f01025ae:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01025b5:	00 
f01025b6:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f01025bd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025c2:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01025c7:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025cc:	e8 4d ea ff ff       	call   f010101e <boot_map_region>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ~0x0 - KERNBASE + 1;
	//cprintf("the size is %x", size);
	boot_map_region(kern_pgdir, KERNBASE, size, (physaddr_t)0,PTE_P|PTE_W);
f01025d1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01025d8:	00 
f01025d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025e0:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01025e5:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01025ea:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025ef:	e8 2a ea ff ff       	call   f010101e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025f4:	8b 1d 84 79 11 f0    	mov    0xf0117984,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01025fa:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f0102600:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102603:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f010260a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102610:	74 79                	je     f010268b <mem_init+0x149a>
f0102612:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102617:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010261d:	89 d8                	mov    %ebx,%eax
f010261f:	e8 0c e3 ff ff       	call   f0100930 <check_va2pa>
f0102624:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010262a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102630:	77 20                	ja     f0102652 <mem_init+0x1461>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102632:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102636:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f010263d:	f0 
f010263e:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0102645:	00 
f0102646:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010264d:	e8 42 da ff ff       	call   f0100094 <_panic>
f0102652:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102659:	39 d0                	cmp    %edx,%eax
f010265b:	74 24                	je     f0102681 <mem_init+0x1490>
f010265d:	c7 44 24 0c 58 47 10 	movl   $0xf0104758,0xc(%esp)
f0102664:	f0 
f0102665:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010266c:	f0 
f010266d:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0102674:	00 
f0102675:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010267c:	e8 13 da ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102681:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102687:	39 f7                	cmp    %esi,%edi
f0102689:	77 8c                	ja     f0102617 <mem_init+0x1426>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010268b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010268e:	c1 e7 0c             	shl    $0xc,%edi
f0102691:	85 ff                	test   %edi,%edi
f0102693:	74 44                	je     f01026d9 <mem_init+0x14e8>
f0102695:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010269a:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01026a0:	89 d8                	mov    %ebx,%eax
f01026a2:	e8 89 e2 ff ff       	call   f0100930 <check_va2pa>
f01026a7:	39 c6                	cmp    %eax,%esi
f01026a9:	74 24                	je     f01026cf <mem_init+0x14de>
f01026ab:	c7 44 24 0c 8c 47 10 	movl   $0xf010478c,0xc(%esp)
f01026b2:	f0 
f01026b3:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01026ba:	f0 
f01026bb:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f01026c2:	00 
f01026c3:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01026ca:	e8 c5 d9 ff ff       	call   f0100094 <_panic>
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026cf:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01026d5:	39 fe                	cmp    %edi,%esi
f01026d7:	72 c1                	jb     f010269a <mem_init+0x14a9>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01026d9:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01026de:	89 d8                	mov    %ebx,%eax
f01026e0:	e8 4b e2 ff ff       	call   f0100930 <check_va2pa>
f01026e5:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01026ea:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
f01026ef:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f01026f5:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01026f8:	39 c2                	cmp    %eax,%edx
f01026fa:	74 24                	je     f0102720 <mem_init+0x152f>
f01026fc:	c7 44 24 0c b4 47 10 	movl   $0xf01047b4,0xc(%esp)
f0102703:	f0 
f0102704:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010270b:	f0 
f010270c:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102713:	00 
f0102714:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010271b:	e8 74 d9 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102720:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f0102726:	0f 85 27 05 00 00    	jne    f0102c53 <mem_init+0x1a62>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010272c:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102731:	89 d8                	mov    %ebx,%eax
f0102733:	e8 f8 e1 ff ff       	call   f0100930 <check_va2pa>
f0102738:	83 f8 ff             	cmp    $0xffffffff,%eax
f010273b:	74 24                	je     f0102761 <mem_init+0x1570>
f010273d:	c7 44 24 0c fc 47 10 	movl   $0xf01047fc,0xc(%esp)
f0102744:	f0 
f0102745:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010274c:	f0 
f010274d:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0102754:	00 
f0102755:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010275c:	e8 33 d9 ff ff       	call   f0100094 <_panic>
f0102761:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102766:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f010276c:	83 fa 02             	cmp    $0x2,%edx
f010276f:	77 2e                	ja     f010279f <mem_init+0x15ae>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102771:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102775:	0f 85 aa 00 00 00    	jne    f0102825 <mem_init+0x1634>
f010277b:	c7 44 24 0c 93 4b 10 	movl   $0xf0104b93,0xc(%esp)
f0102782:	f0 
f0102783:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f010278a:	f0 
f010278b:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0102792:	00 
f0102793:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f010279a:	e8 f5 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010279f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01027a4:	76 55                	jbe    f01027fb <mem_init+0x160a>
				assert(pgdir[i] & PTE_P);
f01027a6:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01027a9:	f6 c2 01             	test   $0x1,%dl
f01027ac:	75 24                	jne    f01027d2 <mem_init+0x15e1>
f01027ae:	c7 44 24 0c 93 4b 10 	movl   $0xf0104b93,0xc(%esp)
f01027b5:	f0 
f01027b6:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01027bd:	f0 
f01027be:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01027c5:	00 
f01027c6:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01027cd:	e8 c2 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01027d2:	f6 c2 02             	test   $0x2,%dl
f01027d5:	75 4e                	jne    f0102825 <mem_init+0x1634>
f01027d7:	c7 44 24 0c a4 4b 10 	movl   $0xf0104ba4,0xc(%esp)
f01027de:	f0 
f01027df:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01027e6:	f0 
f01027e7:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01027ee:	00 
f01027ef:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01027f6:	e8 99 d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01027fb:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01027ff:	74 24                	je     f0102825 <mem_init+0x1634>
f0102801:	c7 44 24 0c b5 4b 10 	movl   $0xf0104bb5,0xc(%esp)
f0102808:	f0 
f0102809:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102810:	f0 
f0102811:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0102818:	00 
f0102819:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102820:	e8 6f d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102825:	83 c0 01             	add    $0x1,%eax
f0102828:	3d 00 04 00 00       	cmp    $0x400,%eax
f010282d:	0f 85 33 ff ff ff    	jne    f0102766 <mem_init+0x1575>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102833:	c7 04 24 2c 48 10 f0 	movl   $0xf010482c,(%esp)
f010283a:	e8 97 04 00 00       	call   f0102cd6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010283f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102844:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102849:	77 20                	ja     f010286b <mem_init+0x167a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010284b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010284f:	c7 44 24 08 ec 42 10 	movl   $0xf01042ec,0x8(%esp)
f0102856:	f0 
f0102857:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f010285e:	00 
f010285f:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102866:	e8 29 d8 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010286b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102870:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102873:	b8 00 00 00 00       	mov    $0x0,%eax
f0102878:	e8 c8 e1 ff ff       	call   f0100a45 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010287d:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102880:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102885:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102888:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010288b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102892:	e8 e1 e5 ff ff       	call   f0100e78 <page_alloc>
f0102897:	89 c6                	mov    %eax,%esi
f0102899:	85 c0                	test   %eax,%eax
f010289b:	75 24                	jne    f01028c1 <mem_init+0x16d0>
f010289d:	c7 44 24 0c d2 49 10 	movl   $0xf01049d2,0xc(%esp)
f01028a4:	f0 
f01028a5:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01028ac:	f0 
f01028ad:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f01028b4:	00 
f01028b5:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01028bc:	e8 d3 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01028c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028c8:	e8 ab e5 ff ff       	call   f0100e78 <page_alloc>
f01028cd:	89 c7                	mov    %eax,%edi
f01028cf:	85 c0                	test   %eax,%eax
f01028d1:	75 24                	jne    f01028f7 <mem_init+0x1706>
f01028d3:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f01028da:	f0 
f01028db:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f01028e2:	f0 
f01028e3:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f01028ea:	00 
f01028eb:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f01028f2:	e8 9d d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01028f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028fe:	e8 75 e5 ff ff       	call   f0100e78 <page_alloc>
f0102903:	89 c3                	mov    %eax,%ebx
f0102905:	85 c0                	test   %eax,%eax
f0102907:	75 24                	jne    f010292d <mem_init+0x173c>
f0102909:	c7 44 24 0c fe 49 10 	movl   $0xf01049fe,0xc(%esp)
f0102910:	f0 
f0102911:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102918:	f0 
f0102919:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102920:	00 
f0102921:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102928:	e8 67 d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010292d:	89 34 24             	mov    %esi,(%esp)
f0102930:	e8 c7 e5 ff ff       	call   f0100efc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102935:	89 f8                	mov    %edi,%eax
f0102937:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f010293d:	c1 f8 03             	sar    $0x3,%eax
f0102940:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102943:	89 c2                	mov    %eax,%edx
f0102945:	c1 ea 0c             	shr    $0xc,%edx
f0102948:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f010294e:	72 20                	jb     f0102970 <mem_init+0x177f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102950:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102954:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f010295b:	f0 
f010295c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102963:	00 
f0102964:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f010296b:	e8 24 d7 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102970:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102977:	00 
f0102978:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010297f:	00 
	return (void *)(pa + KERNBASE);
f0102980:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102985:	89 04 24             	mov    %eax,(%esp)
f0102988:	e8 89 0e 00 00       	call   f0103816 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010298d:	89 d8                	mov    %ebx,%eax
f010298f:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102995:	c1 f8 03             	sar    $0x3,%eax
f0102998:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010299b:	89 c2                	mov    %eax,%edx
f010299d:	c1 ea 0c             	shr    $0xc,%edx
f01029a0:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f01029a6:	72 20                	jb     f01029c8 <mem_init+0x17d7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029ac:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f01029b3:	f0 
f01029b4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029bb:	00 
f01029bc:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f01029c3:	e8 cc d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01029c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029cf:	00 
f01029d0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029d7:	00 
	return (void *)(pa + KERNBASE);
f01029d8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029dd:	89 04 24             	mov    %eax,(%esp)
f01029e0:	e8 31 0e 00 00       	call   f0103816 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029e5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029ec:	00 
f01029ed:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029f4:	00 
f01029f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01029f9:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01029fe:	89 04 24             	mov    %eax,(%esp)
f0102a01:	e8 41 e7 ff ff       	call   f0101147 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a06:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a0b:	74 24                	je     f0102a31 <mem_init+0x1840>
f0102a0d:	c7 44 24 0c cf 4a 10 	movl   $0xf0104acf,0xc(%esp)
f0102a14:	f0 
f0102a15:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102a1c:	f0 
f0102a1d:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102a24:	00 
f0102a25:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102a2c:	e8 63 d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a31:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a38:	01 01 01 
f0102a3b:	74 24                	je     f0102a61 <mem_init+0x1870>
f0102a3d:	c7 44 24 0c 4c 48 10 	movl   $0xf010484c,0xc(%esp)
f0102a44:	f0 
f0102a45:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102a4c:	f0 
f0102a4d:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102a54:	00 
f0102a55:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102a5c:	e8 33 d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a61:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a68:	00 
f0102a69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a70:	00 
f0102a71:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a75:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102a7a:	89 04 24             	mov    %eax,(%esp)
f0102a7d:	e8 c5 e6 ff ff       	call   f0101147 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a82:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a89:	02 02 02 
f0102a8c:	74 24                	je     f0102ab2 <mem_init+0x18c1>
f0102a8e:	c7 44 24 0c 70 48 10 	movl   $0xf0104870,0xc(%esp)
f0102a95:	f0 
f0102a96:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102a9d:	f0 
f0102a9e:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102aa5:	00 
f0102aa6:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102aad:	e8 e2 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102ab2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ab7:	74 24                	je     f0102add <mem_init+0x18ec>
f0102ab9:	c7 44 24 0c f1 4a 10 	movl   $0xf0104af1,0xc(%esp)
f0102ac0:	f0 
f0102ac1:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102ac8:	f0 
f0102ac9:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102ad0:	00 
f0102ad1:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102ad8:	e8 b7 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102add:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ae2:	74 24                	je     f0102b08 <mem_init+0x1917>
f0102ae4:	c7 44 24 0c 3a 4b 10 	movl   $0xf0104b3a,0xc(%esp)
f0102aeb:	f0 
f0102aec:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102af3:	f0 
f0102af4:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102afb:	00 
f0102afc:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102b03:	e8 8c d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b08:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b0f:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b12:	89 d8                	mov    %ebx,%eax
f0102b14:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102b1a:	c1 f8 03             	sar    $0x3,%eax
f0102b1d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b20:	89 c2                	mov    %eax,%edx
f0102b22:	c1 ea 0c             	shr    $0xc,%edx
f0102b25:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0102b2b:	72 20                	jb     f0102b4d <mem_init+0x195c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b2d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b31:	c7 44 24 08 04 42 10 	movl   $0xf0104204,0x8(%esp)
f0102b38:	f0 
f0102b39:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b40:	00 
f0102b41:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0102b48:	e8 47 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b4d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b54:	03 03 03 
f0102b57:	74 24                	je     f0102b7d <mem_init+0x198c>
f0102b59:	c7 44 24 0c 94 48 10 	movl   $0xf0104894,0xc(%esp)
f0102b60:	f0 
f0102b61:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102b68:	f0 
f0102b69:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102b70:	00 
f0102b71:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102b78:	e8 17 d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b7d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b84:	00 
f0102b85:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102b8a:	89 04 24             	mov    %eax,(%esp)
f0102b8d:	e8 65 e5 ff ff       	call   f01010f7 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b92:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102b97:	74 24                	je     f0102bbd <mem_init+0x19cc>
f0102b99:	c7 44 24 0c 29 4b 10 	movl   $0xf0104b29,0xc(%esp)
f0102ba0:	f0 
f0102ba1:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102ba8:	f0 
f0102ba9:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102bb0:	00 
f0102bb1:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102bb8:	e8 d7 d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bbd:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102bc2:	8b 08                	mov    (%eax),%ecx
f0102bc4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bca:	89 f2                	mov    %esi,%edx
f0102bcc:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102bd2:	c1 fa 03             	sar    $0x3,%edx
f0102bd5:	c1 e2 0c             	shl    $0xc,%edx
f0102bd8:	39 d1                	cmp    %edx,%ecx
f0102bda:	74 24                	je     f0102c00 <mem_init+0x1a0f>
f0102bdc:	c7 44 24 0c 44 44 10 	movl   $0xf0104444,0xc(%esp)
f0102be3:	f0 
f0102be4:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102beb:	f0 
f0102bec:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102bf3:	00 
f0102bf4:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102bfb:	e8 94 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c06:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c0b:	74 24                	je     f0102c31 <mem_init+0x1a40>
f0102c0d:	c7 44 24 0c e0 4a 10 	movl   $0xf0104ae0,0xc(%esp)
f0102c14:	f0 
f0102c15:	c7 44 24 08 27 49 10 	movl   $0xf0104927,0x8(%esp)
f0102c1c:	f0 
f0102c1d:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102c24:	00 
f0102c25:	c7 04 24 ec 48 10 f0 	movl   $0xf01048ec,(%esp)
f0102c2c:	e8 63 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c31:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102c37:	89 34 24             	mov    %esi,(%esp)
f0102c3a:	e8 bd e2 ff ff       	call   f0100efc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c3f:	c7 04 24 c0 48 10 f0 	movl   $0xf01048c0,(%esp)
f0102c46:	e8 8b 00 00 00       	call   f0102cd6 <cprintf>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();

}
f0102c4b:	83 c4 3c             	add    $0x3c,%esp
f0102c4e:	5b                   	pop    %ebx
f0102c4f:	5e                   	pop    %esi
f0102c50:	5f                   	pop    %edi
f0102c51:	5d                   	pop    %ebp
f0102c52:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c53:	89 f2                	mov    %esi,%edx
f0102c55:	89 d8                	mov    %ebx,%eax
f0102c57:	e8 d4 dc ff ff       	call   f0100930 <check_va2pa>
f0102c5c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102c62:	e9 8e fa ff ff       	jmp    f01026f5 <mem_init+0x1504>
	...

f0102c68 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c68:	55                   	push   %ebp
f0102c69:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c6b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c70:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c73:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102c74:	b2 71                	mov    $0x71,%dl
f0102c76:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102c77:	0f b6 c0             	movzbl %al,%eax
}
f0102c7a:	5d                   	pop    %ebp
f0102c7b:	c3                   	ret    

f0102c7c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102c7c:	55                   	push   %ebp
f0102c7d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c7f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c84:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c87:	ee                   	out    %al,(%dx)
f0102c88:	b2 71                	mov    $0x71,%dl
f0102c8a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c8d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102c8e:	5d                   	pop    %ebp
f0102c8f:	c3                   	ret    

f0102c90 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102c90:	55                   	push   %ebp
f0102c91:	89 e5                	mov    %esp,%ebp
f0102c93:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102c96:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c99:	89 04 24             	mov    %eax,(%esp)
f0102c9c:	e8 51 d9 ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0102ca1:	c9                   	leave  
f0102ca2:	c3                   	ret    

f0102ca3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ca3:	55                   	push   %ebp
f0102ca4:	89 e5                	mov    %esp,%ebp
f0102ca6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102ca9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102cb0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cb3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cba:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cbe:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cc1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cc5:	c7 04 24 90 2c 10 f0 	movl   $0xf0102c90,(%esp)
f0102ccc:	e8 69 04 00 00       	call   f010313a <vprintfmt>
	return cnt;
}
f0102cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102cd4:	c9                   	leave  
f0102cd5:	c3                   	ret    

f0102cd6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102cd6:	55                   	push   %ebp
f0102cd7:	89 e5                	mov    %esp,%ebp
f0102cd9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102cdc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102cdf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ce3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ce6:	89 04 24             	mov    %eax,(%esp)
f0102ce9:	e8 b5 ff ff ff       	call   f0102ca3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102cee:	c9                   	leave  
f0102cef:	c3                   	ret    

f0102cf0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
f0102cf3:	57                   	push   %edi
f0102cf4:	56                   	push   %esi
f0102cf5:	53                   	push   %ebx
f0102cf6:	83 ec 10             	sub    $0x10,%esp
f0102cf9:	89 c3                	mov    %eax,%ebx
f0102cfb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102cfe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d01:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d04:	8b 0a                	mov    (%edx),%ecx
f0102d06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d09:	8b 00                	mov    (%eax),%eax
f0102d0b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d0e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d15:	eb 77                	jmp    f0102d8e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102d17:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d1a:	01 c8                	add    %ecx,%eax
f0102d1c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102d21:	99                   	cltd   
f0102d22:	f7 ff                	idiv   %edi
f0102d24:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d26:	eb 01                	jmp    f0102d29 <stab_binsearch+0x39>
			m--;
f0102d28:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d29:	39 ca                	cmp    %ecx,%edx
f0102d2b:	7c 1d                	jl     f0102d4a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102d2d:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d30:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102d35:	39 f7                	cmp    %esi,%edi
f0102d37:	75 ef                	jne    f0102d28 <stab_binsearch+0x38>
f0102d39:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d3c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102d3f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102d43:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102d46:	73 18                	jae    f0102d60 <stab_binsearch+0x70>
f0102d48:	eb 05                	jmp    f0102d4f <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102d4a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102d4d:	eb 3f                	jmp    f0102d8e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102d4f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102d52:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102d54:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d57:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d5e:	eb 2e                	jmp    f0102d8e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102d60:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102d63:	76 15                	jbe    f0102d7a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102d65:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102d68:	4f                   	dec    %edi
f0102d69:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102d6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d6f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d71:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d78:	eb 14                	jmp    f0102d8e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102d7a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102d7d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102d80:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102d82:	ff 45 0c             	incl   0xc(%ebp)
f0102d85:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d87:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102d8e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102d91:	7e 84                	jle    f0102d17 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102d93:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102d97:	75 0d                	jne    f0102da6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102d99:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d9c:	8b 02                	mov    (%edx),%eax
f0102d9e:	48                   	dec    %eax
f0102d9f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102da2:	89 01                	mov    %eax,(%ecx)
f0102da4:	eb 22                	jmp    f0102dc8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102da6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102da9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102dab:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102dae:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102db0:	eb 01                	jmp    f0102db3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102db2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102db3:	39 c1                	cmp    %eax,%ecx
f0102db5:	7d 0c                	jge    f0102dc3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102db7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102dba:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102dbf:	39 f2                	cmp    %esi,%edx
f0102dc1:	75 ef                	jne    f0102db2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102dc3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102dc6:	89 02                	mov    %eax,(%edx)
	}
}
f0102dc8:	83 c4 10             	add    $0x10,%esp
f0102dcb:	5b                   	pop    %ebx
f0102dcc:	5e                   	pop    %esi
f0102dcd:	5f                   	pop    %edi
f0102dce:	5d                   	pop    %ebp
f0102dcf:	c3                   	ret    

f0102dd0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102dd0:	55                   	push   %ebp
f0102dd1:	89 e5                	mov    %esp,%ebp
f0102dd3:	83 ec 38             	sub    $0x38,%esp
f0102dd6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102dd9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102ddc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102ddf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102de2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102de5:	c7 03 c3 4b 10 f0    	movl   $0xf0104bc3,(%ebx)
	info->eip_line = 0;
f0102deb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102df2:	c7 43 08 c3 4b 10 f0 	movl   $0xf0104bc3,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102df9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e00:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e03:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e0a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e10:	76 12                	jbe    f0102e24 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e12:	b8 ec cb 10 f0       	mov    $0xf010cbec,%eax
f0102e17:	3d 11 ae 10 f0       	cmp    $0xf010ae11,%eax
f0102e1c:	0f 86 9b 01 00 00    	jbe    f0102fbd <debuginfo_eip+0x1ed>
f0102e22:	eb 1c                	jmp    f0102e40 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e24:	c7 44 24 08 cd 4b 10 	movl   $0xf0104bcd,0x8(%esp)
f0102e2b:	f0 
f0102e2c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e33:	00 
f0102e34:	c7 04 24 da 4b 10 f0 	movl   $0xf0104bda,(%esp)
f0102e3b:	e8 54 d2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102e40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e45:	80 3d eb cb 10 f0 00 	cmpb   $0x0,0xf010cbeb
f0102e4c:	0f 85 77 01 00 00    	jne    f0102fc9 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102e52:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102e59:	b8 10 ae 10 f0       	mov    $0xf010ae10,%eax
f0102e5e:	2d f8 4d 10 f0       	sub    $0xf0104df8,%eax
f0102e63:	c1 f8 02             	sar    $0x2,%eax
f0102e66:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102e6c:	83 e8 01             	sub    $0x1,%eax
f0102e6f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102e72:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e76:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102e7d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102e80:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102e83:	b8 f8 4d 10 f0       	mov    $0xf0104df8,%eax
f0102e88:	e8 63 fe ff ff       	call   f0102cf0 <stab_binsearch>
	if (lfile == 0)
f0102e8d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102e90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102e95:	85 d2                	test   %edx,%edx
f0102e97:	0f 84 2c 01 00 00    	je     f0102fc9 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102e9d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102ea0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ea3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102ea6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102eaa:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102eb1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102eb4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102eb7:	b8 f8 4d 10 f0       	mov    $0xf0104df8,%eax
f0102ebc:	e8 2f fe ff ff       	call   f0102cf0 <stab_binsearch>

	if (lfun <= rfun) {
f0102ec1:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102ec4:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102ec7:	7f 2e                	jg     f0102ef7 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102ec9:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102ecc:	8d 90 f8 4d 10 f0    	lea    -0xfefb208(%eax),%edx
f0102ed2:	8b 80 f8 4d 10 f0    	mov    -0xfefb208(%eax),%eax
f0102ed8:	b9 ec cb 10 f0       	mov    $0xf010cbec,%ecx
f0102edd:	81 e9 11 ae 10 f0    	sub    $0xf010ae11,%ecx
f0102ee3:	39 c8                	cmp    %ecx,%eax
f0102ee5:	73 08                	jae    f0102eef <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ee7:	05 11 ae 10 f0       	add    $0xf010ae11,%eax
f0102eec:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102eef:	8b 42 08             	mov    0x8(%edx),%eax
f0102ef2:	89 43 10             	mov    %eax,0x10(%ebx)
f0102ef5:	eb 06                	jmp    f0102efd <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102ef7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102efa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102efd:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f04:	00 
f0102f05:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f08:	89 04 24             	mov    %eax,(%esp)
f0102f0b:	e8 df 08 00 00       	call   f01037ef <strfind>
f0102f10:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f13:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f16:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102f19:	39 d7                	cmp    %edx,%edi
f0102f1b:	7c 5f                	jl     f0102f7c <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f1d:	89 f8                	mov    %edi,%eax
f0102f1f:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102f22:	80 b9 fc 4d 10 f0 84 	cmpb   $0x84,-0xfefb204(%ecx)
f0102f29:	75 18                	jne    f0102f43 <debuginfo_eip+0x173>
f0102f2b:	eb 30                	jmp    f0102f5d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f2d:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f30:	39 fa                	cmp    %edi,%edx
f0102f32:	7f 48                	jg     f0102f7c <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102f34:	89 f8                	mov    %edi,%eax
f0102f36:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102f39:	80 3c 8d fc 4d 10 f0 	cmpb   $0x84,-0xfefb204(,%ecx,4)
f0102f40:	84 
f0102f41:	74 1a                	je     f0102f5d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102f43:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102f46:	8d 04 85 f8 4d 10 f0 	lea    -0xfefb208(,%eax,4),%eax
f0102f4d:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0102f51:	75 da                	jne    f0102f2d <debuginfo_eip+0x15d>
f0102f53:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102f57:	74 d4                	je     f0102f2d <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102f59:	39 fa                	cmp    %edi,%edx
f0102f5b:	7f 1f                	jg     f0102f7c <debuginfo_eip+0x1ac>
f0102f5d:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102f60:	8b 87 f8 4d 10 f0    	mov    -0xfefb208(%edi),%eax
f0102f66:	ba ec cb 10 f0       	mov    $0xf010cbec,%edx
f0102f6b:	81 ea 11 ae 10 f0    	sub    $0xf010ae11,%edx
f0102f71:	39 d0                	cmp    %edx,%eax
f0102f73:	73 07                	jae    f0102f7c <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102f75:	05 11 ae 10 f0       	add    $0xf010ae11,%eax
f0102f7a:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f7c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f7f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102f82:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102f87:	39 ca                	cmp    %ecx,%edx
f0102f89:	7d 3e                	jge    f0102fc9 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0102f8b:	83 c2 01             	add    $0x1,%edx
f0102f8e:	39 d1                	cmp    %edx,%ecx
f0102f90:	7e 37                	jle    f0102fc9 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102f92:	6b f2 0c             	imul   $0xc,%edx,%esi
f0102f95:	80 be fc 4d 10 f0 a0 	cmpb   $0xa0,-0xfefb204(%esi)
f0102f9c:	75 2b                	jne    f0102fc9 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0102f9e:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102fa2:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102fa5:	39 d1                	cmp    %edx,%ecx
f0102fa7:	7e 1b                	jle    f0102fc4 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102fa9:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102fac:	80 3c 85 fc 4d 10 f0 	cmpb   $0xa0,-0xfefb204(,%eax,4)
f0102fb3:	a0 
f0102fb4:	74 e8                	je     f0102f9e <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fb6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fbb:	eb 0c                	jmp    f0102fc9 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102fbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fc2:	eb 05                	jmp    f0102fc9 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102fc4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fc9:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102fcc:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102fcf:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102fd2:	89 ec                	mov    %ebp,%esp
f0102fd4:	5d                   	pop    %ebp
f0102fd5:	c3                   	ret    
	...

f0102fe0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
f0102fe3:	57                   	push   %edi
f0102fe4:	56                   	push   %esi
f0102fe5:	53                   	push   %ebx
f0102fe6:	83 ec 3c             	sub    $0x3c,%esp
f0102fe9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102fec:	89 d7                	mov    %edx,%edi
f0102fee:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102ff4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ffa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0102ffd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103000:	b8 00 00 00 00       	mov    $0x0,%eax
f0103005:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103008:	72 11                	jb     f010301b <printnum+0x3b>
f010300a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010300d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103010:	76 09                	jbe    f010301b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103012:	83 eb 01             	sub    $0x1,%ebx
f0103015:	85 db                	test   %ebx,%ebx
f0103017:	7f 51                	jg     f010306a <printnum+0x8a>
f0103019:	eb 5e                	jmp    f0103079 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010301b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010301f:	83 eb 01             	sub    $0x1,%ebx
f0103022:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103026:	8b 45 10             	mov    0x10(%ebp),%eax
f0103029:	89 44 24 08          	mov    %eax,0x8(%esp)
f010302d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103031:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103035:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010303c:	00 
f010303d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103040:	89 04 24             	mov    %eax,(%esp)
f0103043:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103046:	89 44 24 04          	mov    %eax,0x4(%esp)
f010304a:	e8 21 0a 00 00       	call   f0103a70 <__udivdi3>
f010304f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103053:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103057:	89 04 24             	mov    %eax,(%esp)
f010305a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010305e:	89 fa                	mov    %edi,%edx
f0103060:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103063:	e8 78 ff ff ff       	call   f0102fe0 <printnum>
f0103068:	eb 0f                	jmp    f0103079 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010306a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010306e:	89 34 24             	mov    %esi,(%esp)
f0103071:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103074:	83 eb 01             	sub    $0x1,%ebx
f0103077:	75 f1                	jne    f010306a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103079:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010307d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103081:	8b 45 10             	mov    0x10(%ebp),%eax
f0103084:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103088:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010308f:	00 
f0103090:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103093:	89 04 24             	mov    %eax,(%esp)
f0103096:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103099:	89 44 24 04          	mov    %eax,0x4(%esp)
f010309d:	e8 fe 0a 00 00       	call   f0103ba0 <__umoddi3>
f01030a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030a6:	0f be 80 e8 4b 10 f0 	movsbl -0xfefb418(%eax),%eax
f01030ad:	89 04 24             	mov    %eax,(%esp)
f01030b0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01030b3:	83 c4 3c             	add    $0x3c,%esp
f01030b6:	5b                   	pop    %ebx
f01030b7:	5e                   	pop    %esi
f01030b8:	5f                   	pop    %edi
f01030b9:	5d                   	pop    %ebp
f01030ba:	c3                   	ret    

f01030bb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01030bb:	55                   	push   %ebp
f01030bc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01030be:	83 fa 01             	cmp    $0x1,%edx
f01030c1:	7e 0e                	jle    f01030d1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01030c3:	8b 10                	mov    (%eax),%edx
f01030c5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01030c8:	89 08                	mov    %ecx,(%eax)
f01030ca:	8b 02                	mov    (%edx),%eax
f01030cc:	8b 52 04             	mov    0x4(%edx),%edx
f01030cf:	eb 22                	jmp    f01030f3 <getuint+0x38>
	else if (lflag)
f01030d1:	85 d2                	test   %edx,%edx
f01030d3:	74 10                	je     f01030e5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01030d5:	8b 10                	mov    (%eax),%edx
f01030d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01030da:	89 08                	mov    %ecx,(%eax)
f01030dc:	8b 02                	mov    (%edx),%eax
f01030de:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e3:	eb 0e                	jmp    f01030f3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01030e5:	8b 10                	mov    (%eax),%edx
f01030e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01030ea:	89 08                	mov    %ecx,(%eax)
f01030ec:	8b 02                	mov    (%edx),%eax
f01030ee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01030f3:	5d                   	pop    %ebp
f01030f4:	c3                   	ret    

f01030f5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01030f5:	55                   	push   %ebp
f01030f6:	89 e5                	mov    %esp,%ebp
f01030f8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01030fb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01030ff:	8b 10                	mov    (%eax),%edx
f0103101:	3b 50 04             	cmp    0x4(%eax),%edx
f0103104:	73 0a                	jae    f0103110 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103106:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103109:	88 0a                	mov    %cl,(%edx)
f010310b:	83 c2 01             	add    $0x1,%edx
f010310e:	89 10                	mov    %edx,(%eax)
}
f0103110:	5d                   	pop    %ebp
f0103111:	c3                   	ret    

f0103112 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103112:	55                   	push   %ebp
f0103113:	89 e5                	mov    %esp,%ebp
f0103115:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103118:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010311b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010311f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103126:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010312d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103130:	89 04 24             	mov    %eax,(%esp)
f0103133:	e8 02 00 00 00       	call   f010313a <vprintfmt>
	va_end(ap);
}
f0103138:	c9                   	leave  
f0103139:	c3                   	ret    

f010313a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010313a:	55                   	push   %ebp
f010313b:	89 e5                	mov    %esp,%ebp
f010313d:	57                   	push   %edi
f010313e:	56                   	push   %esi
f010313f:	53                   	push   %ebx
f0103140:	83 ec 4c             	sub    $0x4c,%esp
f0103143:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103146:	8b 75 10             	mov    0x10(%ebp),%esi
f0103149:	eb 12                	jmp    f010315d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010314b:	85 c0                	test   %eax,%eax
f010314d:	0f 84 a9 03 00 00    	je     f01034fc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103153:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103157:	89 04 24             	mov    %eax,(%esp)
f010315a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010315d:	0f b6 06             	movzbl (%esi),%eax
f0103160:	83 c6 01             	add    $0x1,%esi
f0103163:	83 f8 25             	cmp    $0x25,%eax
f0103166:	75 e3                	jne    f010314b <vprintfmt+0x11>
f0103168:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010316c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103173:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103178:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010317f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103184:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103187:	eb 2b                	jmp    f01031b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103189:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010318c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103190:	eb 22                	jmp    f01031b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103192:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103195:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103199:	eb 19                	jmp    f01031b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010319b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010319e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01031a5:	eb 0d                	jmp    f01031b4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01031a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01031ad:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031b4:	0f b6 06             	movzbl (%esi),%eax
f01031b7:	0f b6 d0             	movzbl %al,%edx
f01031ba:	8d 7e 01             	lea    0x1(%esi),%edi
f01031bd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01031c0:	83 e8 23             	sub    $0x23,%eax
f01031c3:	3c 55                	cmp    $0x55,%al
f01031c5:	0f 87 0b 03 00 00    	ja     f01034d6 <vprintfmt+0x39c>
f01031cb:	0f b6 c0             	movzbl %al,%eax
f01031ce:	ff 24 85 74 4c 10 f0 	jmp    *-0xfefb38c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01031d5:	83 ea 30             	sub    $0x30,%edx
f01031d8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01031db:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01031df:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01031e5:	83 fa 09             	cmp    $0x9,%edx
f01031e8:	77 4a                	ja     f0103234 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031ea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01031ed:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01031f0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01031f3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01031f7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01031fa:	8d 50 d0             	lea    -0x30(%eax),%edx
f01031fd:	83 fa 09             	cmp    $0x9,%edx
f0103200:	76 eb                	jbe    f01031ed <vprintfmt+0xb3>
f0103202:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103205:	eb 2d                	jmp    f0103234 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103207:	8b 45 14             	mov    0x14(%ebp),%eax
f010320a:	8d 50 04             	lea    0x4(%eax),%edx
f010320d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103210:	8b 00                	mov    (%eax),%eax
f0103212:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103215:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103218:	eb 1a                	jmp    f0103234 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010321a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010321d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103221:	79 91                	jns    f01031b4 <vprintfmt+0x7a>
f0103223:	e9 73 ff ff ff       	jmp    f010319b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103228:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010322b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103232:	eb 80                	jmp    f01031b4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103234:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103238:	0f 89 76 ff ff ff    	jns    f01031b4 <vprintfmt+0x7a>
f010323e:	e9 64 ff ff ff       	jmp    f01031a7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103243:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103246:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103249:	e9 66 ff ff ff       	jmp    f01031b4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010324e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103251:	8d 50 04             	lea    0x4(%eax),%edx
f0103254:	89 55 14             	mov    %edx,0x14(%ebp)
f0103257:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010325b:	8b 00                	mov    (%eax),%eax
f010325d:	89 04 24             	mov    %eax,(%esp)
f0103260:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103263:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103266:	e9 f2 fe ff ff       	jmp    f010315d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010326b:	8b 45 14             	mov    0x14(%ebp),%eax
f010326e:	8d 50 04             	lea    0x4(%eax),%edx
f0103271:	89 55 14             	mov    %edx,0x14(%ebp)
f0103274:	8b 00                	mov    (%eax),%eax
f0103276:	89 c2                	mov    %eax,%edx
f0103278:	c1 fa 1f             	sar    $0x1f,%edx
f010327b:	31 d0                	xor    %edx,%eax
f010327d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010327f:	83 f8 06             	cmp    $0x6,%eax
f0103282:	7f 0b                	jg     f010328f <vprintfmt+0x155>
f0103284:	8b 14 85 cc 4d 10 f0 	mov    -0xfefb234(,%eax,4),%edx
f010328b:	85 d2                	test   %edx,%edx
f010328d:	75 23                	jne    f01032b2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010328f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103293:	c7 44 24 08 00 4c 10 	movl   $0xf0104c00,0x8(%esp)
f010329a:	f0 
f010329b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010329f:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032a2:	89 3c 24             	mov    %edi,(%esp)
f01032a5:	e8 68 fe ff ff       	call   f0103112 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01032ad:	e9 ab fe ff ff       	jmp    f010315d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01032b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01032b6:	c7 44 24 08 39 49 10 	movl   $0xf0104939,0x8(%esp)
f01032bd:	f0 
f01032be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032c2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032c5:	89 3c 24             	mov    %edi,(%esp)
f01032c8:	e8 45 fe ff ff       	call   f0103112 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01032d0:	e9 88 fe ff ff       	jmp    f010315d <vprintfmt+0x23>
f01032d5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01032d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01032de:	8b 45 14             	mov    0x14(%ebp),%eax
f01032e1:	8d 50 04             	lea    0x4(%eax),%edx
f01032e4:	89 55 14             	mov    %edx,0x14(%ebp)
f01032e7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01032e9:	85 f6                	test   %esi,%esi
f01032eb:	ba f9 4b 10 f0       	mov    $0xf0104bf9,%edx
f01032f0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01032f3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01032f7:	7e 06                	jle    f01032ff <vprintfmt+0x1c5>
f01032f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01032fd:	75 10                	jne    f010330f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01032ff:	0f be 06             	movsbl (%esi),%eax
f0103302:	83 c6 01             	add    $0x1,%esi
f0103305:	85 c0                	test   %eax,%eax
f0103307:	0f 85 86 00 00 00    	jne    f0103393 <vprintfmt+0x259>
f010330d:	eb 76                	jmp    f0103385 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010330f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103313:	89 34 24             	mov    %esi,(%esp)
f0103316:	e8 60 03 00 00       	call   f010367b <strnlen>
f010331b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010331e:	29 c2                	sub    %eax,%edx
f0103320:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103323:	85 d2                	test   %edx,%edx
f0103325:	7e d8                	jle    f01032ff <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103327:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010332b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010332e:	89 d6                	mov    %edx,%esi
f0103330:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103333:	89 c7                	mov    %eax,%edi
f0103335:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103339:	89 3c 24             	mov    %edi,(%esp)
f010333c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010333f:	83 ee 01             	sub    $0x1,%esi
f0103342:	75 f1                	jne    f0103335 <vprintfmt+0x1fb>
f0103344:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103347:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010334a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010334d:	eb b0                	jmp    f01032ff <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010334f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103353:	74 18                	je     f010336d <vprintfmt+0x233>
f0103355:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103358:	83 fa 5e             	cmp    $0x5e,%edx
f010335b:	76 10                	jbe    f010336d <vprintfmt+0x233>
					putch('?', putdat);
f010335d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103361:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103368:	ff 55 08             	call   *0x8(%ebp)
f010336b:	eb 0a                	jmp    f0103377 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010336d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103371:	89 04 24             	mov    %eax,(%esp)
f0103374:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103377:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010337b:	0f be 06             	movsbl (%esi),%eax
f010337e:	83 c6 01             	add    $0x1,%esi
f0103381:	85 c0                	test   %eax,%eax
f0103383:	75 0e                	jne    f0103393 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103385:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103388:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010338c:	7f 16                	jg     f01033a4 <vprintfmt+0x26a>
f010338e:	e9 ca fd ff ff       	jmp    f010315d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103393:	85 ff                	test   %edi,%edi
f0103395:	78 b8                	js     f010334f <vprintfmt+0x215>
f0103397:	83 ef 01             	sub    $0x1,%edi
f010339a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033a0:	79 ad                	jns    f010334f <vprintfmt+0x215>
f01033a2:	eb e1                	jmp    f0103385 <vprintfmt+0x24b>
f01033a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01033a7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01033aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033ae:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01033b5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01033b7:	83 ee 01             	sub    $0x1,%esi
f01033ba:	75 ee                	jne    f01033aa <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01033bf:	e9 99 fd ff ff       	jmp    f010315d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01033c4:	83 f9 01             	cmp    $0x1,%ecx
f01033c7:	7e 10                	jle    f01033d9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01033c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01033cc:	8d 50 08             	lea    0x8(%eax),%edx
f01033cf:	89 55 14             	mov    %edx,0x14(%ebp)
f01033d2:	8b 30                	mov    (%eax),%esi
f01033d4:	8b 78 04             	mov    0x4(%eax),%edi
f01033d7:	eb 26                	jmp    f01033ff <vprintfmt+0x2c5>
	else if (lflag)
f01033d9:	85 c9                	test   %ecx,%ecx
f01033db:	74 12                	je     f01033ef <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01033dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01033e0:	8d 50 04             	lea    0x4(%eax),%edx
f01033e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01033e6:	8b 30                	mov    (%eax),%esi
f01033e8:	89 f7                	mov    %esi,%edi
f01033ea:	c1 ff 1f             	sar    $0x1f,%edi
f01033ed:	eb 10                	jmp    f01033ff <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01033ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01033f2:	8d 50 04             	lea    0x4(%eax),%edx
f01033f5:	89 55 14             	mov    %edx,0x14(%ebp)
f01033f8:	8b 30                	mov    (%eax),%esi
f01033fa:	89 f7                	mov    %esi,%edi
f01033fc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01033ff:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103404:	85 ff                	test   %edi,%edi
f0103406:	0f 89 8c 00 00 00    	jns    f0103498 <vprintfmt+0x35e>
				putch('-', putdat);
f010340c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103410:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103417:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010341a:	f7 de                	neg    %esi
f010341c:	83 d7 00             	adc    $0x0,%edi
f010341f:	f7 df                	neg    %edi
			}
			base = 10;
f0103421:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103426:	eb 70                	jmp    f0103498 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103428:	89 ca                	mov    %ecx,%edx
f010342a:	8d 45 14             	lea    0x14(%ebp),%eax
f010342d:	e8 89 fc ff ff       	call   f01030bb <getuint>
f0103432:	89 c6                	mov    %eax,%esi
f0103434:	89 d7                	mov    %edx,%edi
			base = 10;
f0103436:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010343b:	eb 5b                	jmp    f0103498 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010343d:	89 ca                	mov    %ecx,%edx
f010343f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103442:	e8 74 fc ff ff       	call   f01030bb <getuint>
f0103447:	89 c6                	mov    %eax,%esi
f0103449:	89 d7                	mov    %edx,%edi
			base = 8;
f010344b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103450:	eb 46                	jmp    f0103498 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f0103452:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103456:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010345d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103460:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103464:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010346b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010346e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103471:	8d 50 04             	lea    0x4(%eax),%edx
f0103474:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103477:	8b 30                	mov    (%eax),%esi
f0103479:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010347e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103483:	eb 13                	jmp    f0103498 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103485:	89 ca                	mov    %ecx,%edx
f0103487:	8d 45 14             	lea    0x14(%ebp),%eax
f010348a:	e8 2c fc ff ff       	call   f01030bb <getuint>
f010348f:	89 c6                	mov    %eax,%esi
f0103491:	89 d7                	mov    %edx,%edi
			base = 16;
f0103493:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103498:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010349c:	89 54 24 10          	mov    %edx,0x10(%esp)
f01034a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034a3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01034a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034ab:	89 34 24             	mov    %esi,(%esp)
f01034ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034b2:	89 da                	mov    %ebx,%edx
f01034b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b7:	e8 24 fb ff ff       	call   f0102fe0 <printnum>
			break;
f01034bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01034bf:	e9 99 fc ff ff       	jmp    f010315d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01034c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034c8:	89 14 24             	mov    %edx,(%esp)
f01034cb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01034d1:	e9 87 fc ff ff       	jmp    f010315d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01034d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034da:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01034e1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01034e4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01034e8:	0f 84 6f fc ff ff    	je     f010315d <vprintfmt+0x23>
f01034ee:	83 ee 01             	sub    $0x1,%esi
f01034f1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01034f5:	75 f7                	jne    f01034ee <vprintfmt+0x3b4>
f01034f7:	e9 61 fc ff ff       	jmp    f010315d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01034fc:	83 c4 4c             	add    $0x4c,%esp
f01034ff:	5b                   	pop    %ebx
f0103500:	5e                   	pop    %esi
f0103501:	5f                   	pop    %edi
f0103502:	5d                   	pop    %ebp
f0103503:	c3                   	ret    

f0103504 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103504:	55                   	push   %ebp
f0103505:	89 e5                	mov    %esp,%ebp
f0103507:	83 ec 28             	sub    $0x28,%esp
f010350a:	8b 45 08             	mov    0x8(%ebp),%eax
f010350d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103510:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103513:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103517:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010351a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103521:	85 c0                	test   %eax,%eax
f0103523:	74 30                	je     f0103555 <vsnprintf+0x51>
f0103525:	85 d2                	test   %edx,%edx
f0103527:	7e 2c                	jle    f0103555 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103529:	8b 45 14             	mov    0x14(%ebp),%eax
f010352c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103530:	8b 45 10             	mov    0x10(%ebp),%eax
f0103533:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103537:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010353a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010353e:	c7 04 24 f5 30 10 f0 	movl   $0xf01030f5,(%esp)
f0103545:	e8 f0 fb ff ff       	call   f010313a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010354a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010354d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103550:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103553:	eb 05                	jmp    f010355a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103555:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010355a:	c9                   	leave  
f010355b:	c3                   	ret    

f010355c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010355c:	55                   	push   %ebp
f010355d:	89 e5                	mov    %esp,%ebp
f010355f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103562:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103565:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103569:	8b 45 10             	mov    0x10(%ebp),%eax
f010356c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103570:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103573:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103577:	8b 45 08             	mov    0x8(%ebp),%eax
f010357a:	89 04 24             	mov    %eax,(%esp)
f010357d:	e8 82 ff ff ff       	call   f0103504 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103582:	c9                   	leave  
f0103583:	c3                   	ret    
	...

f0103590 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103590:	55                   	push   %ebp
f0103591:	89 e5                	mov    %esp,%ebp
f0103593:	57                   	push   %edi
f0103594:	56                   	push   %esi
f0103595:	53                   	push   %ebx
f0103596:	83 ec 1c             	sub    $0x1c,%esp
f0103599:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010359c:	85 c0                	test   %eax,%eax
f010359e:	74 10                	je     f01035b0 <readline+0x20>
		cprintf("%s", prompt);
f01035a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035a4:	c7 04 24 39 49 10 f0 	movl   $0xf0104939,(%esp)
f01035ab:	e8 26 f7 ff ff       	call   f0102cd6 <cprintf>

	i = 0;
	echoing = iscons(0);
f01035b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035b7:	e8 57 d0 ff ff       	call   f0100613 <iscons>
f01035bc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01035be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01035c3:	e8 3a d0 ff ff       	call   f0100602 <getchar>
f01035c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035ca:	85 c0                	test   %eax,%eax
f01035cc:	79 17                	jns    f01035e5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01035ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035d2:	c7 04 24 e8 4d 10 f0 	movl   $0xf0104de8,(%esp)
f01035d9:	e8 f8 f6 ff ff       	call   f0102cd6 <cprintf>
			return NULL;
f01035de:	b8 00 00 00 00       	mov    $0x0,%eax
f01035e3:	eb 6d                	jmp    f0103652 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01035e5:	83 f8 08             	cmp    $0x8,%eax
f01035e8:	74 05                	je     f01035ef <readline+0x5f>
f01035ea:	83 f8 7f             	cmp    $0x7f,%eax
f01035ed:	75 19                	jne    f0103608 <readline+0x78>
f01035ef:	85 f6                	test   %esi,%esi
f01035f1:	7e 15                	jle    f0103608 <readline+0x78>
			if (echoing)
f01035f3:	85 ff                	test   %edi,%edi
f01035f5:	74 0c                	je     f0103603 <readline+0x73>
				cputchar('\b');
f01035f7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01035fe:	e8 ef cf ff ff       	call   f01005f2 <cputchar>
			i--;
f0103603:	83 ee 01             	sub    $0x1,%esi
f0103606:	eb bb                	jmp    f01035c3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103608:	83 fb 1f             	cmp    $0x1f,%ebx
f010360b:	7e 1f                	jle    f010362c <readline+0x9c>
f010360d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103613:	7f 17                	jg     f010362c <readline+0x9c>
			if (echoing)
f0103615:	85 ff                	test   %edi,%edi
f0103617:	74 08                	je     f0103621 <readline+0x91>
				cputchar(c);
f0103619:	89 1c 24             	mov    %ebx,(%esp)
f010361c:	e8 d1 cf ff ff       	call   f01005f2 <cputchar>
			buf[i++] = c;
f0103621:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f0103627:	83 c6 01             	add    $0x1,%esi
f010362a:	eb 97                	jmp    f01035c3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010362c:	83 fb 0a             	cmp    $0xa,%ebx
f010362f:	74 05                	je     f0103636 <readline+0xa6>
f0103631:	83 fb 0d             	cmp    $0xd,%ebx
f0103634:	75 8d                	jne    f01035c3 <readline+0x33>
			if (echoing)
f0103636:	85 ff                	test   %edi,%edi
f0103638:	74 0c                	je     f0103646 <readline+0xb6>
				cputchar('\n');
f010363a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103641:	e8 ac cf ff ff       	call   f01005f2 <cputchar>
			buf[i] = 0;
f0103646:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f010364d:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f0103652:	83 c4 1c             	add    $0x1c,%esp
f0103655:	5b                   	pop    %ebx
f0103656:	5e                   	pop    %esi
f0103657:	5f                   	pop    %edi
f0103658:	5d                   	pop    %ebp
f0103659:	c3                   	ret    
f010365a:	00 00                	add    %al,(%eax)
f010365c:	00 00                	add    %al,(%eax)
	...

f0103660 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103660:	55                   	push   %ebp
f0103661:	89 e5                	mov    %esp,%ebp
f0103663:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103666:	b8 00 00 00 00       	mov    $0x0,%eax
f010366b:	80 3a 00             	cmpb   $0x0,(%edx)
f010366e:	74 09                	je     f0103679 <strlen+0x19>
		n++;
f0103670:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103673:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103677:	75 f7                	jne    f0103670 <strlen+0x10>
		n++;
	return n;
}
f0103679:	5d                   	pop    %ebp
f010367a:	c3                   	ret    

f010367b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010367b:	55                   	push   %ebp
f010367c:	89 e5                	mov    %esp,%ebp
f010367e:	53                   	push   %ebx
f010367f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103682:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103685:	b8 00 00 00 00       	mov    $0x0,%eax
f010368a:	85 c9                	test   %ecx,%ecx
f010368c:	74 1a                	je     f01036a8 <strnlen+0x2d>
f010368e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103691:	74 15                	je     f01036a8 <strnlen+0x2d>
f0103693:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103698:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010369a:	39 ca                	cmp    %ecx,%edx
f010369c:	74 0a                	je     f01036a8 <strnlen+0x2d>
f010369e:	83 c2 01             	add    $0x1,%edx
f01036a1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01036a6:	75 f0                	jne    f0103698 <strnlen+0x1d>
		n++;
	return n;
}
f01036a8:	5b                   	pop    %ebx
f01036a9:	5d                   	pop    %ebp
f01036aa:	c3                   	ret    

f01036ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01036ab:	55                   	push   %ebp
f01036ac:	89 e5                	mov    %esp,%ebp
f01036ae:	53                   	push   %ebx
f01036af:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01036b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01036ba:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01036be:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01036c1:	83 c2 01             	add    $0x1,%edx
f01036c4:	84 c9                	test   %cl,%cl
f01036c6:	75 f2                	jne    f01036ba <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01036c8:	5b                   	pop    %ebx
f01036c9:	5d                   	pop    %ebp
f01036ca:	c3                   	ret    

f01036cb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01036cb:	55                   	push   %ebp
f01036cc:	89 e5                	mov    %esp,%ebp
f01036ce:	56                   	push   %esi
f01036cf:	53                   	push   %ebx
f01036d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036d6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036d9:	85 f6                	test   %esi,%esi
f01036db:	74 18                	je     f01036f5 <strncpy+0x2a>
f01036dd:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01036e2:	0f b6 1a             	movzbl (%edx),%ebx
f01036e5:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036e8:	80 3a 01             	cmpb   $0x1,(%edx)
f01036eb:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036ee:	83 c1 01             	add    $0x1,%ecx
f01036f1:	39 f1                	cmp    %esi,%ecx
f01036f3:	75 ed                	jne    f01036e2 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01036f5:	5b                   	pop    %ebx
f01036f6:	5e                   	pop    %esi
f01036f7:	5d                   	pop    %ebp
f01036f8:	c3                   	ret    

f01036f9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036f9:	55                   	push   %ebp
f01036fa:	89 e5                	mov    %esp,%ebp
f01036fc:	57                   	push   %edi
f01036fd:	56                   	push   %esi
f01036fe:	53                   	push   %ebx
f01036ff:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103702:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103705:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103708:	89 f8                	mov    %edi,%eax
f010370a:	85 f6                	test   %esi,%esi
f010370c:	74 2b                	je     f0103739 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010370e:	83 fe 01             	cmp    $0x1,%esi
f0103711:	74 23                	je     f0103736 <strlcpy+0x3d>
f0103713:	0f b6 0b             	movzbl (%ebx),%ecx
f0103716:	84 c9                	test   %cl,%cl
f0103718:	74 1c                	je     f0103736 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010371a:	83 ee 02             	sub    $0x2,%esi
f010371d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103722:	88 08                	mov    %cl,(%eax)
f0103724:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103727:	39 f2                	cmp    %esi,%edx
f0103729:	74 0b                	je     f0103736 <strlcpy+0x3d>
f010372b:	83 c2 01             	add    $0x1,%edx
f010372e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103732:	84 c9                	test   %cl,%cl
f0103734:	75 ec                	jne    f0103722 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103736:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103739:	29 f8                	sub    %edi,%eax
}
f010373b:	5b                   	pop    %ebx
f010373c:	5e                   	pop    %esi
f010373d:	5f                   	pop    %edi
f010373e:	5d                   	pop    %ebp
f010373f:	c3                   	ret    

f0103740 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103740:	55                   	push   %ebp
f0103741:	89 e5                	mov    %esp,%ebp
f0103743:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103746:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103749:	0f b6 01             	movzbl (%ecx),%eax
f010374c:	84 c0                	test   %al,%al
f010374e:	74 16                	je     f0103766 <strcmp+0x26>
f0103750:	3a 02                	cmp    (%edx),%al
f0103752:	75 12                	jne    f0103766 <strcmp+0x26>
		p++, q++;
f0103754:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103757:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010375b:	84 c0                	test   %al,%al
f010375d:	74 07                	je     f0103766 <strcmp+0x26>
f010375f:	83 c1 01             	add    $0x1,%ecx
f0103762:	3a 02                	cmp    (%edx),%al
f0103764:	74 ee                	je     f0103754 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103766:	0f b6 c0             	movzbl %al,%eax
f0103769:	0f b6 12             	movzbl (%edx),%edx
f010376c:	29 d0                	sub    %edx,%eax
}
f010376e:	5d                   	pop    %ebp
f010376f:	c3                   	ret    

f0103770 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	53                   	push   %ebx
f0103774:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103777:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010377a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010377d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103782:	85 d2                	test   %edx,%edx
f0103784:	74 28                	je     f01037ae <strncmp+0x3e>
f0103786:	0f b6 01             	movzbl (%ecx),%eax
f0103789:	84 c0                	test   %al,%al
f010378b:	74 24                	je     f01037b1 <strncmp+0x41>
f010378d:	3a 03                	cmp    (%ebx),%al
f010378f:	75 20                	jne    f01037b1 <strncmp+0x41>
f0103791:	83 ea 01             	sub    $0x1,%edx
f0103794:	74 13                	je     f01037a9 <strncmp+0x39>
		n--, p++, q++;
f0103796:	83 c1 01             	add    $0x1,%ecx
f0103799:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010379c:	0f b6 01             	movzbl (%ecx),%eax
f010379f:	84 c0                	test   %al,%al
f01037a1:	74 0e                	je     f01037b1 <strncmp+0x41>
f01037a3:	3a 03                	cmp    (%ebx),%al
f01037a5:	74 ea                	je     f0103791 <strncmp+0x21>
f01037a7:	eb 08                	jmp    f01037b1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01037a9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01037ae:	5b                   	pop    %ebx
f01037af:	5d                   	pop    %ebp
f01037b0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01037b1:	0f b6 01             	movzbl (%ecx),%eax
f01037b4:	0f b6 13             	movzbl (%ebx),%edx
f01037b7:	29 d0                	sub    %edx,%eax
f01037b9:	eb f3                	jmp    f01037ae <strncmp+0x3e>

f01037bb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01037bb:	55                   	push   %ebp
f01037bc:	89 e5                	mov    %esp,%ebp
f01037be:	8b 45 08             	mov    0x8(%ebp),%eax
f01037c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037c5:	0f b6 10             	movzbl (%eax),%edx
f01037c8:	84 d2                	test   %dl,%dl
f01037ca:	74 1c                	je     f01037e8 <strchr+0x2d>
		if (*s == c)
f01037cc:	38 ca                	cmp    %cl,%dl
f01037ce:	75 09                	jne    f01037d9 <strchr+0x1e>
f01037d0:	eb 1b                	jmp    f01037ed <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01037d2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01037d5:	38 ca                	cmp    %cl,%dl
f01037d7:	74 14                	je     f01037ed <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01037d9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01037dd:	84 d2                	test   %dl,%dl
f01037df:	75 f1                	jne    f01037d2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01037e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037e6:	eb 05                	jmp    f01037ed <strchr+0x32>
f01037e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037ed:	5d                   	pop    %ebp
f01037ee:	c3                   	ret    

f01037ef <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01037ef:	55                   	push   %ebp
f01037f0:	89 e5                	mov    %esp,%ebp
f01037f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037f9:	0f b6 10             	movzbl (%eax),%edx
f01037fc:	84 d2                	test   %dl,%dl
f01037fe:	74 14                	je     f0103814 <strfind+0x25>
		if (*s == c)
f0103800:	38 ca                	cmp    %cl,%dl
f0103802:	75 06                	jne    f010380a <strfind+0x1b>
f0103804:	eb 0e                	jmp    f0103814 <strfind+0x25>
f0103806:	38 ca                	cmp    %cl,%dl
f0103808:	74 0a                	je     f0103814 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010380a:	83 c0 01             	add    $0x1,%eax
f010380d:	0f b6 10             	movzbl (%eax),%edx
f0103810:	84 d2                	test   %dl,%dl
f0103812:	75 f2                	jne    f0103806 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103814:	5d                   	pop    %ebp
f0103815:	c3                   	ret    

f0103816 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103816:	55                   	push   %ebp
f0103817:	89 e5                	mov    %esp,%ebp
f0103819:	83 ec 0c             	sub    $0xc,%esp
f010381c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010381f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103822:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103825:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103828:	8b 45 0c             	mov    0xc(%ebp),%eax
f010382b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010382e:	85 c9                	test   %ecx,%ecx
f0103830:	74 30                	je     f0103862 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103832:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103838:	75 25                	jne    f010385f <memset+0x49>
f010383a:	f6 c1 03             	test   $0x3,%cl
f010383d:	75 20                	jne    f010385f <memset+0x49>
		c &= 0xFF;
f010383f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103842:	89 d3                	mov    %edx,%ebx
f0103844:	c1 e3 08             	shl    $0x8,%ebx
f0103847:	89 d6                	mov    %edx,%esi
f0103849:	c1 e6 18             	shl    $0x18,%esi
f010384c:	89 d0                	mov    %edx,%eax
f010384e:	c1 e0 10             	shl    $0x10,%eax
f0103851:	09 f0                	or     %esi,%eax
f0103853:	09 d0                	or     %edx,%eax
f0103855:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103857:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010385a:	fc                   	cld    
f010385b:	f3 ab                	rep stos %eax,%es:(%edi)
f010385d:	eb 03                	jmp    f0103862 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010385f:	fc                   	cld    
f0103860:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103862:	89 f8                	mov    %edi,%eax
f0103864:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103867:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010386a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010386d:	89 ec                	mov    %ebp,%esp
f010386f:	5d                   	pop    %ebp
f0103870:	c3                   	ret    

f0103871 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103871:	55                   	push   %ebp
f0103872:	89 e5                	mov    %esp,%ebp
f0103874:	83 ec 08             	sub    $0x8,%esp
f0103877:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010387a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010387d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103880:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103883:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103886:	39 c6                	cmp    %eax,%esi
f0103888:	73 36                	jae    f01038c0 <memmove+0x4f>
f010388a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010388d:	39 d0                	cmp    %edx,%eax
f010388f:	73 2f                	jae    f01038c0 <memmove+0x4f>
		s += n;
		d += n;
f0103891:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103894:	f6 c2 03             	test   $0x3,%dl
f0103897:	75 1b                	jne    f01038b4 <memmove+0x43>
f0103899:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010389f:	75 13                	jne    f01038b4 <memmove+0x43>
f01038a1:	f6 c1 03             	test   $0x3,%cl
f01038a4:	75 0e                	jne    f01038b4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01038a6:	83 ef 04             	sub    $0x4,%edi
f01038a9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01038ac:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01038af:	fd                   	std    
f01038b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038b2:	eb 09                	jmp    f01038bd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01038b4:	83 ef 01             	sub    $0x1,%edi
f01038b7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01038ba:	fd                   	std    
f01038bb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01038bd:	fc                   	cld    
f01038be:	eb 20                	jmp    f01038e0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038c0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01038c6:	75 13                	jne    f01038db <memmove+0x6a>
f01038c8:	a8 03                	test   $0x3,%al
f01038ca:	75 0f                	jne    f01038db <memmove+0x6a>
f01038cc:	f6 c1 03             	test   $0x3,%cl
f01038cf:	75 0a                	jne    f01038db <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01038d1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01038d4:	89 c7                	mov    %eax,%edi
f01038d6:	fc                   	cld    
f01038d7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038d9:	eb 05                	jmp    f01038e0 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01038db:	89 c7                	mov    %eax,%edi
f01038dd:	fc                   	cld    
f01038de:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01038e0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01038e3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01038e6:	89 ec                	mov    %ebp,%esp
f01038e8:	5d                   	pop    %ebp
f01038e9:	c3                   	ret    

f01038ea <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01038ea:	55                   	push   %ebp
f01038eb:	89 e5                	mov    %esp,%ebp
f01038ed:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01038f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01038f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103901:	89 04 24             	mov    %eax,(%esp)
f0103904:	e8 68 ff ff ff       	call   f0103871 <memmove>
}
f0103909:	c9                   	leave  
f010390a:	c3                   	ret    

f010390b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010390b:	55                   	push   %ebp
f010390c:	89 e5                	mov    %esp,%ebp
f010390e:	57                   	push   %edi
f010390f:	56                   	push   %esi
f0103910:	53                   	push   %ebx
f0103911:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103914:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103917:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010391a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010391f:	85 ff                	test   %edi,%edi
f0103921:	74 37                	je     f010395a <memcmp+0x4f>
		if (*s1 != *s2)
f0103923:	0f b6 03             	movzbl (%ebx),%eax
f0103926:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103929:	83 ef 01             	sub    $0x1,%edi
f010392c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103931:	38 c8                	cmp    %cl,%al
f0103933:	74 1c                	je     f0103951 <memcmp+0x46>
f0103935:	eb 10                	jmp    f0103947 <memcmp+0x3c>
f0103937:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010393c:	83 c2 01             	add    $0x1,%edx
f010393f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103943:	38 c8                	cmp    %cl,%al
f0103945:	74 0a                	je     f0103951 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103947:	0f b6 c0             	movzbl %al,%eax
f010394a:	0f b6 c9             	movzbl %cl,%ecx
f010394d:	29 c8                	sub    %ecx,%eax
f010394f:	eb 09                	jmp    f010395a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103951:	39 fa                	cmp    %edi,%edx
f0103953:	75 e2                	jne    f0103937 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103955:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010395a:	5b                   	pop    %ebx
f010395b:	5e                   	pop    %esi
f010395c:	5f                   	pop    %edi
f010395d:	5d                   	pop    %ebp
f010395e:	c3                   	ret    

f010395f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010395f:	55                   	push   %ebp
f0103960:	89 e5                	mov    %esp,%ebp
f0103962:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103965:	89 c2                	mov    %eax,%edx
f0103967:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010396a:	39 d0                	cmp    %edx,%eax
f010396c:	73 15                	jae    f0103983 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010396e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103972:	38 08                	cmp    %cl,(%eax)
f0103974:	75 06                	jne    f010397c <memfind+0x1d>
f0103976:	eb 0b                	jmp    f0103983 <memfind+0x24>
f0103978:	38 08                	cmp    %cl,(%eax)
f010397a:	74 07                	je     f0103983 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010397c:	83 c0 01             	add    $0x1,%eax
f010397f:	39 d0                	cmp    %edx,%eax
f0103981:	75 f5                	jne    f0103978 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103983:	5d                   	pop    %ebp
f0103984:	c3                   	ret    

f0103985 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103985:	55                   	push   %ebp
f0103986:	89 e5                	mov    %esp,%ebp
f0103988:	57                   	push   %edi
f0103989:	56                   	push   %esi
f010398a:	53                   	push   %ebx
f010398b:	8b 55 08             	mov    0x8(%ebp),%edx
f010398e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103991:	0f b6 02             	movzbl (%edx),%eax
f0103994:	3c 20                	cmp    $0x20,%al
f0103996:	74 04                	je     f010399c <strtol+0x17>
f0103998:	3c 09                	cmp    $0x9,%al
f010399a:	75 0e                	jne    f01039aa <strtol+0x25>
		s++;
f010399c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010399f:	0f b6 02             	movzbl (%edx),%eax
f01039a2:	3c 20                	cmp    $0x20,%al
f01039a4:	74 f6                	je     f010399c <strtol+0x17>
f01039a6:	3c 09                	cmp    $0x9,%al
f01039a8:	74 f2                	je     f010399c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01039aa:	3c 2b                	cmp    $0x2b,%al
f01039ac:	75 0a                	jne    f01039b8 <strtol+0x33>
		s++;
f01039ae:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01039b1:	bf 00 00 00 00       	mov    $0x0,%edi
f01039b6:	eb 10                	jmp    f01039c8 <strtol+0x43>
f01039b8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01039bd:	3c 2d                	cmp    $0x2d,%al
f01039bf:	75 07                	jne    f01039c8 <strtol+0x43>
		s++, neg = 1;
f01039c1:	83 c2 01             	add    $0x1,%edx
f01039c4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01039c8:	85 db                	test   %ebx,%ebx
f01039ca:	0f 94 c0             	sete   %al
f01039cd:	74 05                	je     f01039d4 <strtol+0x4f>
f01039cf:	83 fb 10             	cmp    $0x10,%ebx
f01039d2:	75 15                	jne    f01039e9 <strtol+0x64>
f01039d4:	80 3a 30             	cmpb   $0x30,(%edx)
f01039d7:	75 10                	jne    f01039e9 <strtol+0x64>
f01039d9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01039dd:	75 0a                	jne    f01039e9 <strtol+0x64>
		s += 2, base = 16;
f01039df:	83 c2 02             	add    $0x2,%edx
f01039e2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01039e7:	eb 13                	jmp    f01039fc <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01039e9:	84 c0                	test   %al,%al
f01039eb:	74 0f                	je     f01039fc <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01039ed:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01039f2:	80 3a 30             	cmpb   $0x30,(%edx)
f01039f5:	75 05                	jne    f01039fc <strtol+0x77>
		s++, base = 8;
f01039f7:	83 c2 01             	add    $0x1,%edx
f01039fa:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01039fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a01:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a03:	0f b6 0a             	movzbl (%edx),%ecx
f0103a06:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103a09:	80 fb 09             	cmp    $0x9,%bl
f0103a0c:	77 08                	ja     f0103a16 <strtol+0x91>
			dig = *s - '0';
f0103a0e:	0f be c9             	movsbl %cl,%ecx
f0103a11:	83 e9 30             	sub    $0x30,%ecx
f0103a14:	eb 1e                	jmp    f0103a34 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103a16:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103a19:	80 fb 19             	cmp    $0x19,%bl
f0103a1c:	77 08                	ja     f0103a26 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103a1e:	0f be c9             	movsbl %cl,%ecx
f0103a21:	83 e9 57             	sub    $0x57,%ecx
f0103a24:	eb 0e                	jmp    f0103a34 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103a26:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103a29:	80 fb 19             	cmp    $0x19,%bl
f0103a2c:	77 14                	ja     f0103a42 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103a2e:	0f be c9             	movsbl %cl,%ecx
f0103a31:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a34:	39 f1                	cmp    %esi,%ecx
f0103a36:	7d 0e                	jge    f0103a46 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103a38:	83 c2 01             	add    $0x1,%edx
f0103a3b:	0f af c6             	imul   %esi,%eax
f0103a3e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103a40:	eb c1                	jmp    f0103a03 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103a42:	89 c1                	mov    %eax,%ecx
f0103a44:	eb 02                	jmp    f0103a48 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103a46:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103a48:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a4c:	74 05                	je     f0103a53 <strtol+0xce>
		*endptr = (char *) s;
f0103a4e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a51:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103a53:	89 ca                	mov    %ecx,%edx
f0103a55:	f7 da                	neg    %edx
f0103a57:	85 ff                	test   %edi,%edi
f0103a59:	0f 45 c2             	cmovne %edx,%eax
}
f0103a5c:	5b                   	pop    %ebx
f0103a5d:	5e                   	pop    %esi
f0103a5e:	5f                   	pop    %edi
f0103a5f:	5d                   	pop    %ebp
f0103a60:	c3                   	ret    
	...

f0103a70 <__udivdi3>:
f0103a70:	83 ec 1c             	sub    $0x1c,%esp
f0103a73:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103a77:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103a7b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103a7f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103a83:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103a87:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103a8b:	85 ff                	test   %edi,%edi
f0103a8d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103a91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a95:	89 cd                	mov    %ecx,%ebp
f0103a97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a9b:	75 33                	jne    f0103ad0 <__udivdi3+0x60>
f0103a9d:	39 f1                	cmp    %esi,%ecx
f0103a9f:	77 57                	ja     f0103af8 <__udivdi3+0x88>
f0103aa1:	85 c9                	test   %ecx,%ecx
f0103aa3:	75 0b                	jne    f0103ab0 <__udivdi3+0x40>
f0103aa5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103aaa:	31 d2                	xor    %edx,%edx
f0103aac:	f7 f1                	div    %ecx
f0103aae:	89 c1                	mov    %eax,%ecx
f0103ab0:	89 f0                	mov    %esi,%eax
f0103ab2:	31 d2                	xor    %edx,%edx
f0103ab4:	f7 f1                	div    %ecx
f0103ab6:	89 c6                	mov    %eax,%esi
f0103ab8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103abc:	f7 f1                	div    %ecx
f0103abe:	89 f2                	mov    %esi,%edx
f0103ac0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ac4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ac8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103acc:	83 c4 1c             	add    $0x1c,%esp
f0103acf:	c3                   	ret    
f0103ad0:	31 d2                	xor    %edx,%edx
f0103ad2:	31 c0                	xor    %eax,%eax
f0103ad4:	39 f7                	cmp    %esi,%edi
f0103ad6:	77 e8                	ja     f0103ac0 <__udivdi3+0x50>
f0103ad8:	0f bd cf             	bsr    %edi,%ecx
f0103adb:	83 f1 1f             	xor    $0x1f,%ecx
f0103ade:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ae2:	75 2c                	jne    f0103b10 <__udivdi3+0xa0>
f0103ae4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103ae8:	76 04                	jbe    f0103aee <__udivdi3+0x7e>
f0103aea:	39 f7                	cmp    %esi,%edi
f0103aec:	73 d2                	jae    f0103ac0 <__udivdi3+0x50>
f0103aee:	31 d2                	xor    %edx,%edx
f0103af0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103af5:	eb c9                	jmp    f0103ac0 <__udivdi3+0x50>
f0103af7:	90                   	nop
f0103af8:	89 f2                	mov    %esi,%edx
f0103afa:	f7 f1                	div    %ecx
f0103afc:	31 d2                	xor    %edx,%edx
f0103afe:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b02:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b06:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b0a:	83 c4 1c             	add    $0x1c,%esp
f0103b0d:	c3                   	ret    
f0103b0e:	66 90                	xchg   %ax,%ax
f0103b10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b15:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b1a:	89 ea                	mov    %ebp,%edx
f0103b1c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103b20:	d3 e7                	shl    %cl,%edi
f0103b22:	89 c1                	mov    %eax,%ecx
f0103b24:	d3 ea                	shr    %cl,%edx
f0103b26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b2b:	09 fa                	or     %edi,%edx
f0103b2d:	89 f7                	mov    %esi,%edi
f0103b2f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b33:	89 f2                	mov    %esi,%edx
f0103b35:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103b39:	d3 e5                	shl    %cl,%ebp
f0103b3b:	89 c1                	mov    %eax,%ecx
f0103b3d:	d3 ef                	shr    %cl,%edi
f0103b3f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b44:	d3 e2                	shl    %cl,%edx
f0103b46:	89 c1                	mov    %eax,%ecx
f0103b48:	d3 ee                	shr    %cl,%esi
f0103b4a:	09 d6                	or     %edx,%esi
f0103b4c:	89 fa                	mov    %edi,%edx
f0103b4e:	89 f0                	mov    %esi,%eax
f0103b50:	f7 74 24 0c          	divl   0xc(%esp)
f0103b54:	89 d7                	mov    %edx,%edi
f0103b56:	89 c6                	mov    %eax,%esi
f0103b58:	f7 e5                	mul    %ebp
f0103b5a:	39 d7                	cmp    %edx,%edi
f0103b5c:	72 22                	jb     f0103b80 <__udivdi3+0x110>
f0103b5e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103b62:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b67:	d3 e5                	shl    %cl,%ebp
f0103b69:	39 c5                	cmp    %eax,%ebp
f0103b6b:	73 04                	jae    f0103b71 <__udivdi3+0x101>
f0103b6d:	39 d7                	cmp    %edx,%edi
f0103b6f:	74 0f                	je     f0103b80 <__udivdi3+0x110>
f0103b71:	89 f0                	mov    %esi,%eax
f0103b73:	31 d2                	xor    %edx,%edx
f0103b75:	e9 46 ff ff ff       	jmp    f0103ac0 <__udivdi3+0x50>
f0103b7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b80:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103b83:	31 d2                	xor    %edx,%edx
f0103b85:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b89:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b8d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b91:	83 c4 1c             	add    $0x1c,%esp
f0103b94:	c3                   	ret    
	...

f0103ba0 <__umoddi3>:
f0103ba0:	83 ec 1c             	sub    $0x1c,%esp
f0103ba3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103ba7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103bab:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103baf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bb3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103bb7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103bbb:	85 ed                	test   %ebp,%ebp
f0103bbd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103bc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bc5:	89 cf                	mov    %ecx,%edi
f0103bc7:	89 04 24             	mov    %eax,(%esp)
f0103bca:	89 f2                	mov    %esi,%edx
f0103bcc:	75 1a                	jne    f0103be8 <__umoddi3+0x48>
f0103bce:	39 f1                	cmp    %esi,%ecx
f0103bd0:	76 4e                	jbe    f0103c20 <__umoddi3+0x80>
f0103bd2:	f7 f1                	div    %ecx
f0103bd4:	89 d0                	mov    %edx,%eax
f0103bd6:	31 d2                	xor    %edx,%edx
f0103bd8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bdc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103be0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103be4:	83 c4 1c             	add    $0x1c,%esp
f0103be7:	c3                   	ret    
f0103be8:	39 f5                	cmp    %esi,%ebp
f0103bea:	77 54                	ja     f0103c40 <__umoddi3+0xa0>
f0103bec:	0f bd c5             	bsr    %ebp,%eax
f0103bef:	83 f0 1f             	xor    $0x1f,%eax
f0103bf2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf6:	75 60                	jne    f0103c58 <__umoddi3+0xb8>
f0103bf8:	3b 0c 24             	cmp    (%esp),%ecx
f0103bfb:	0f 87 07 01 00 00    	ja     f0103d08 <__umoddi3+0x168>
f0103c01:	89 f2                	mov    %esi,%edx
f0103c03:	8b 34 24             	mov    (%esp),%esi
f0103c06:	29 ce                	sub    %ecx,%esi
f0103c08:	19 ea                	sbb    %ebp,%edx
f0103c0a:	89 34 24             	mov    %esi,(%esp)
f0103c0d:	8b 04 24             	mov    (%esp),%eax
f0103c10:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c14:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c18:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c1c:	83 c4 1c             	add    $0x1c,%esp
f0103c1f:	c3                   	ret    
f0103c20:	85 c9                	test   %ecx,%ecx
f0103c22:	75 0b                	jne    f0103c2f <__umoddi3+0x8f>
f0103c24:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c29:	31 d2                	xor    %edx,%edx
f0103c2b:	f7 f1                	div    %ecx
f0103c2d:	89 c1                	mov    %eax,%ecx
f0103c2f:	89 f0                	mov    %esi,%eax
f0103c31:	31 d2                	xor    %edx,%edx
f0103c33:	f7 f1                	div    %ecx
f0103c35:	8b 04 24             	mov    (%esp),%eax
f0103c38:	f7 f1                	div    %ecx
f0103c3a:	eb 98                	jmp    f0103bd4 <__umoddi3+0x34>
f0103c3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c40:	89 f2                	mov    %esi,%edx
f0103c42:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c46:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c4a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c4e:	83 c4 1c             	add    $0x1c,%esp
f0103c51:	c3                   	ret    
f0103c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c58:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c5d:	89 e8                	mov    %ebp,%eax
f0103c5f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103c64:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103c68:	89 fa                	mov    %edi,%edx
f0103c6a:	d3 e0                	shl    %cl,%eax
f0103c6c:	89 e9                	mov    %ebp,%ecx
f0103c6e:	d3 ea                	shr    %cl,%edx
f0103c70:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c75:	09 c2                	or     %eax,%edx
f0103c77:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c7b:	89 14 24             	mov    %edx,(%esp)
f0103c7e:	89 f2                	mov    %esi,%edx
f0103c80:	d3 e7                	shl    %cl,%edi
f0103c82:	89 e9                	mov    %ebp,%ecx
f0103c84:	d3 ea                	shr    %cl,%edx
f0103c86:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c8f:	d3 e6                	shl    %cl,%esi
f0103c91:	89 e9                	mov    %ebp,%ecx
f0103c93:	d3 e8                	shr    %cl,%eax
f0103c95:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c9a:	09 f0                	or     %esi,%eax
f0103c9c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ca0:	f7 34 24             	divl   (%esp)
f0103ca3:	d3 e6                	shl    %cl,%esi
f0103ca5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103ca9:	89 d6                	mov    %edx,%esi
f0103cab:	f7 e7                	mul    %edi
f0103cad:	39 d6                	cmp    %edx,%esi
f0103caf:	89 c1                	mov    %eax,%ecx
f0103cb1:	89 d7                	mov    %edx,%edi
f0103cb3:	72 3f                	jb     f0103cf4 <__umoddi3+0x154>
f0103cb5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103cb9:	72 35                	jb     f0103cf0 <__umoddi3+0x150>
f0103cbb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103cbf:	29 c8                	sub    %ecx,%eax
f0103cc1:	19 fe                	sbb    %edi,%esi
f0103cc3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cc8:	89 f2                	mov    %esi,%edx
f0103cca:	d3 e8                	shr    %cl,%eax
f0103ccc:	89 e9                	mov    %ebp,%ecx
f0103cce:	d3 e2                	shl    %cl,%edx
f0103cd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cd5:	09 d0                	or     %edx,%eax
f0103cd7:	89 f2                	mov    %esi,%edx
f0103cd9:	d3 ea                	shr    %cl,%edx
f0103cdb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cdf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ce3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ce7:	83 c4 1c             	add    $0x1c,%esp
f0103cea:	c3                   	ret    
f0103ceb:	90                   	nop
f0103cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cf0:	39 d6                	cmp    %edx,%esi
f0103cf2:	75 c7                	jne    f0103cbb <__umoddi3+0x11b>
f0103cf4:	89 d7                	mov    %edx,%edi
f0103cf6:	89 c1                	mov    %eax,%ecx
f0103cf8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103cfc:	1b 3c 24             	sbb    (%esp),%edi
f0103cff:	eb ba                	jmp    f0103cbb <__umoddi3+0x11b>
f0103d01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d08:	39 f5                	cmp    %esi,%ebp
f0103d0a:	0f 82 f1 fe ff ff    	jb     f0103c01 <__umoddi3+0x61>
f0103d10:	e9 f8 fe ff ff       	jmp    f0103c0d <__umoddi3+0x6d>
