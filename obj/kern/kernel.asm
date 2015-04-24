
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
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 a0 1a 10 f0 	movl   $0xf0101aa0,(%esp)
f0100055:	e8 88 09 00 00       	call   f01009e2 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 02 07 00 00       	call   f0100789 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 1a 10 f0 	movl   $0xf0101abc,(%esp)
f0100092:	e8 4b 09 00 00       	call   f01009e2 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 dc 14 00 00       	call   f01015a1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 92 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 1a 10 f0 	movl   $0xf0101ad7,(%esp)
f01000d9:	e8 04 09 00 00       	call   f01009e2 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 66 07 00 00       	call   f010085c <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 f2 1a 10 f0 	movl   $0xf0101af2,(%esp)
f010012c:	e8 b1 08 00 00       	call   f01009e2 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 72 08 00 00       	call   f01009af <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f0100144:	e8 99 08 00 00       	call   f01009e2 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 07 07 00 00       	call   f010085c <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 0a 1b 10 f0 	movl   $0xf0101b0a,(%esp)
f0100176:	e8 67 08 00 00       	call   f01009e2 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 25 08 00 00       	call   f01009af <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f0100191:	e8 4c 08 00 00       	call   f01009e2 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 24 25 11 f0    	mov    0xf0112524,%edx
f01001df:	88 82 20 23 11 f0    	mov    %al,-0xfeedce0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 24 25 11 f0       	mov    %eax,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010027e:	89 fa                	mov    %edi,%edx
f0100280:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0400;
f0100286:	89 f8                	mov    %edi,%eax
f0100288:	80 cc 04             	or     $0x4,%ah
f010028b:	85 d2                	test   %edx,%edx
f010028d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	25 ff 00 00 00       	and    $0xff,%eax
f0100297:	83 f8 09             	cmp    $0x9,%eax
f010029a:	74 7c                	je     f0100318 <cons_putc+0x111>
f010029c:	83 f8 09             	cmp    $0x9,%eax
f010029f:	7f 0b                	jg     f01002ac <cons_putc+0xa5>
f01002a1:	83 f8 08             	cmp    $0x8,%eax
f01002a4:	0f 85 a2 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002aa:	eb 16                	jmp    f01002c2 <cons_putc+0xbb>
f01002ac:	83 f8 0a             	cmp    $0xa,%eax
f01002af:	90                   	nop
f01002b0:	74 40                	je     f01002f2 <cons_putc+0xeb>
f01002b2:	83 f8 0d             	cmp    $0xd,%eax
f01002b5:	0f 85 91 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002bb:	90                   	nop
f01002bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002c0:	eb 38                	jmp    f01002fa <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e4 00 00 00    	je     f01003b6 <cons_putc+0x1af>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e3:	83 cf 20             	or     $0x20,%edi
f01002e6:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002ec:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f0:	eb 77                	jmp    f0100369 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f2:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002f9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fa:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100301:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100307:	c1 e8 16             	shr    $0x16,%eax
f010030a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030d:	c1 e0 04             	shl    $0x4,%eax
f0100310:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100316:	eb 51                	jmp    f0100369 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f0100318:	b8 20 00 00 00       	mov    $0x20,%eax
f010031d:	e8 e5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100322:	b8 20 00 00 00       	mov    $0x20,%eax
f0100327:	e8 db fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100331:	e8 d1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100336:	b8 20 00 00 00       	mov    $0x20,%eax
f010033b:	e8 c7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100340:	b8 20 00 00 00       	mov    $0x20,%eax
f0100345:	e8 bd fe ff ff       	call   f0100207 <cons_putc>
f010034a:	eb 1d                	jmp    f0100369 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034c:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100353:	0f b7 c8             	movzwl %ax,%ecx
f0100356:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010035c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100360:	83 c0 01             	add    $0x1,%eax
f0100363:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100369:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100370:	cf 07 
f0100372:	76 42                	jbe    f01003b6 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100374:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100379:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100380:	00 
f0100381:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100387:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038b:	89 04 24             	mov    %eax,(%esp)
f010038e:	e8 69 12 00 00       	call   f01015fc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100393:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100399:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a4:	83 c0 01             	add    $0x1,%eax
f01003a7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ac:	75 f0                	jne    f010039e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003ae:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003b5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b6:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	0f b7 35 34 25 11 f0 	movzwl 0xf0112534,%esi
f01003cb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ce:	89 f0                	mov    %esi,%eax
f01003d0:	66 c1 e8 08          	shr    $0x8,%ax
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	ee                   	out    %al,(%dx)
f01003d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dc:	89 ca                	mov    %ecx,%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	89 f0                	mov    %esi,%eax
f01003e1:	89 da                	mov    %ebx,%edx
f01003e3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e4:	83 c4 2c             	add    $0x2c,%esp
f01003e7:	5b                   	pop    %ebx
f01003e8:	5e                   	pop    %esi
f01003e9:	5f                   	pop    %edi
f01003ea:	5d                   	pop    %ebp
f01003eb:	c3                   	ret    

f01003ec <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ec:	55                   	push   %ebp
f01003ed:	89 e5                	mov    %esp,%ebp
f01003ef:	53                   	push   %ebx
f01003f0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fe:	a8 01                	test   $0x1,%al
f0100400:	0f 84 de 00 00 00    	je     f01004e4 <kbd_proc_data+0xf8>
f0100406:	b2 60                	mov    $0x60,%dl
f0100408:	ec                   	in     (%dx),%al
f0100409:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041b:	e9 c4 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 37                	jns    f010045b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010042a:	89 cb                	mov    %ecx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	83 e0 7f             	and    $0x7f,%eax
f0100432:	85 db                	test   %ebx,%ebx
f0100434:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100437:	0f b6 d2             	movzbl %dl,%edx
f010043a:	0f b6 82 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%eax
f0100441:	83 c8 40             	or     $0x40,%eax
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	f7 d0                	not    %eax
f0100449:	21 c1                	and    %eax,%ecx
f010044b:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100451:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100456:	e9 89 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010045b:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100461:	f6 c1 40             	test   $0x40,%cl
f0100464:	74 0e                	je     f0100474 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100466:	89 c2                	mov    %eax,%edx
f0100468:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046e:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100474:	0f b6 d2             	movzbl %dl,%edx
f0100477:	0f b6 82 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%eax
f010047e:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100484:	0f b6 8a 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%ecx
f010048b:	31 c8                	xor    %ecx,%eax
f010048d:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100492:	89 c1                	mov    %eax,%ecx
f0100494:	83 e1 03             	and    $0x3,%ecx
f0100497:	8b 0c 8d 60 1d 10 f0 	mov    -0xfefe2a0(,%ecx,4),%ecx
f010049e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a2:	a8 08                	test   $0x8,%al
f01004a4:	74 19                	je     f01004bf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a9:	83 fa 19             	cmp    $0x19,%edx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0c                	jmp    f01004bf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b9:	83 f9 19             	cmp    $0x19,%ecx
f01004bc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004bf:	f7 d0                	not    %eax
f01004c1:	a8 06                	test   $0x6,%al
f01004c3:	75 1f                	jne    f01004e4 <kbd_proc_data+0xf8>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 17                	jne    f01004e4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 24 1b 10 f0 	movl   $0xf0101b24,(%esp)
f01004d4:	e8 09 05 00 00       	call   f01009e2 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	83 c4 14             	add    $0x14,%esp
f01004e9:	5b                   	pop    %ebx
f01004ea:	5d                   	pop    %ebp
f01004eb:	c3                   	ret    

f01004ec <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f2:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f9:	74 0a                	je     f0100505 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004fb:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100500:	e8 c5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050d:	b8 ec 03 10 f0       	mov    $0xf01003ec,%eax
f0100512:	e8 b3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100517:	c9                   	leave  
f0100518:	c3                   	ret    

f0100519 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100519:	55                   	push   %ebp
f010051a:	89 e5                	mov    %esp,%ebp
f010051c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051f:	e8 c8 ff ff ff       	call   f01004ec <serial_intr>
	kbd_intr();
f0100524:	e8 de ff ff ff       	call   f0100507 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100529:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100534:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010053a:	74 1e                	je     f010055a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053c:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100543:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100546:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100551:	0f 44 d1             	cmove  %ecx,%edx
f0100554:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
		return c;
	}
	return 0;
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	74 11                	je     f0100593 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100582:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100589:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100591:	eb 16                	jmp    f01005a9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100593:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059a:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005a1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a9:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005af:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b4:	89 ca                	mov    %ecx,%edx
f01005b6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ec                   	in     (%dx),%al
f01005bd:	0f b6 f8             	movzbl %al,%edi
f01005c0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ce:	89 35 30 25 11 f0    	mov    %esi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d4:	0f b6 d8             	movzbl %al,%ebx
f01005d7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d9:	66 89 3d 34 25 11 f0 	mov    %di,0xf0112534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fb                	mov    $0xfb,%dl
f01005ef:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005fa:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 00 00 00 00       	mov    $0x0,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fb                	mov    $0xfb,%dl
f010060c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fc                	mov    $0xfc,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 f9                	mov    $0xf9,%dl
f010061c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100621:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	b2 fd                	mov    $0xfd,%dl
f0100624:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100625:	3c ff                	cmp    $0xff,%al
f0100627:	0f 95 c0             	setne  %al
f010062a:	89 c6                	mov    %eax,%esi
f010062c:	a2 00 23 11 f0       	mov    %al,0xf0112300
f0100631:	89 da                	mov    %ebx,%edx
f0100633:	ec                   	in     (%dx),%al
f0100634:	89 ca                	mov    %ecx,%edx
f0100636:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100637:	89 f0                	mov    %esi,%eax
f0100639:	84 c0                	test   %al,%al
f010063b:	75 0c                	jne    f0100649 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 30 1b 10 f0 	movl   $0xf0101b30,(%esp)
f0100644:	e8 99 03 00 00       	call   f01009e2 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 a8 fb ff ff       	call   f0100207 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 ad fe ff ff       	call   f0100519 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	00 00                	add    %al,(%eax)
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 70 1d 10 f0 	movl   $0xf0101d70,(%esp)
f010068d:	e8 50 03 00 00       	call   f01009e2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100692:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100699:	00 
f010069a:	c7 04 24 58 1e 10 f0 	movl   $0xf0101e58,(%esp)
f01006a1:	e8 3c 03 00 00       	call   f01009e2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f01006bd:	e8 20 03 00 00       	call   f01009e2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c2:	c7 44 24 08 95 1a 10 	movl   $0x101a95,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 95 1a 10 	movl   $0xf0101a95,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f01006d9:	e8 04 03 00 00       	call   f01009e2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006de:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f01006f5:	e8 e8 02 00 00       	call   f01009e2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fa:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f0100711:	e8 cc 02 00 00       	call   f01009e2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100716:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010071b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100720:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100725:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072b:	85 c0                	test   %eax,%eax
f010072d:	0f 48 c2             	cmovs  %edx,%eax
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 10 1f 10 f0 	movl   $0xf0101f10,(%esp)
f010073e:	e8 9f 02 00 00       	call   f01009e2 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	53                   	push   %ebx
f010074e:	83 ec 14             	sub    $0x14,%esp
f0100751:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100756:	8b 83 c4 1f 10 f0    	mov    -0xfefe03c(%ebx),%eax
f010075c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100760:	8b 83 c0 1f 10 f0    	mov    -0xfefe040(%ebx),%eax
f0100766:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076a:	c7 04 24 89 1d 10 f0 	movl   $0xf0101d89,(%esp)
f0100771:	e8 6c 02 00 00       	call   f01009e2 <cprintf>
f0100776:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100779:	83 fb 24             	cmp    $0x24,%ebx
f010077c:	75 d8                	jne    f0100756 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	83 c4 14             	add    $0x14,%esp
f0100786:	5b                   	pop    %ebx
f0100787:	5d                   	pop    %ebp
f0100788:	c3                   	ret    

f0100789 <mon_backtrace>:
 * 2. *ebp is the new ebp(actually old)
 * 3. get the end(ebp = 0 -> see kern/entry.S, stack movl $0, %ebp)
 */
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100789:	55                   	push   %ebp
f010078a:	89 e5                	mov    %esp,%ebp
f010078c:	57                   	push   %edi
f010078d:	56                   	push   %esi
f010078e:	53                   	push   %ebx
f010078f:	83 ec 3c             	sub    $0x3c,%esp
	// Your code here.
	uint32_t ebp,eip;
	int i;	
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100792:	c7 04 24 92 1d 10 f0 	movl   $0xf0101d92,(%esp)
f0100799:	e8 44 02 00 00       	call   f01009e2 <cprintf>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010079e:	89 ee                	mov    %ebp,%esi
	ebp = read_ebp();
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
f01007a0:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007a4:	c7 04 24 a4 1d 10 f0 	movl   $0xf0101da4,(%esp)
f01007ab:	e8 32 02 00 00       	call   f01009e2 <cprintf>
		eip = *(uint32_t *)(ebp + 4);
f01007b0:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  eip %08x  args",eip);
f01007b3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007b7:	c7 04 24 af 1d 10 f0 	movl   $0xf0101daf,(%esp)
f01007be:	e8 1f 02 00 00       	call   f01009e2 <cprintf>
		for(i=2; i < 7; i++)
f01007c3:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
f01007c8:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007cf:	c7 04 24 a9 1d 10 f0 	movl   $0xf0101da9,(%esp)
f01007d6:	e8 07 02 00 00       	call   f01009e2 <cprintf>
	do{
		/* print the ebp, eip, arg info -- lab1 -> exercise10 */
		cprintf("  ebp %08x",ebp);
		eip = *(uint32_t *)(ebp + 4);
		cprintf("  eip %08x  args",eip);
		for(i=2; i < 7; i++)
f01007db:	83 c3 01             	add    $0x1,%ebx
f01007de:	83 fb 07             	cmp    $0x7,%ebx
f01007e1:	75 e5                	jne    f01007c8 <mon_backtrace+0x3f>
			cprintf(" %08x",*(uint32_t *)(ebp+ 4 * i));
		cprintf("\n");
f01007e3:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f01007ea:	e8 f3 01 00 00       	call   f01009e2 <cprintf>
		/* print the function info -- lab1 -> exercise12 */
		debuginfo_eip((uintptr_t)eip, &info);
f01007ef:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f6:	89 3c 24             	mov    %edi,(%esp)
f01007f9:	e8 de 02 00 00       	call   f0100adc <debuginfo_eip>
		cprintf("\t%s:%d: ",info.eip_file, info.eip_line);
f01007fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100801:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100805:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100808:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080c:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f0100813:	e8 ca 01 00 00       	call   f01009e2 <cprintf>
		cprintf("%.*s",info.eip_fn_namelen, info.eip_fn_name);
f0100818:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010081b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010081f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100822:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100826:	c7 04 24 c9 1d 10 f0 	movl   $0xf0101dc9,(%esp)
f010082d:	e8 b0 01 00 00       	call   f01009e2 <cprintf>
		cprintf("+%d\n",info.eip_fn_addr);
f0100832:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100835:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100839:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f0100840:	e8 9d 01 00 00       	call   f01009e2 <cprintf>
		ebp = *(uint32_t *)ebp;
f0100845:	8b 36                	mov    (%esi),%esi
	}while(ebp);
f0100847:	85 f6                	test   %esi,%esi
f0100849:	0f 85 51 ff ff ff    	jne    f01007a0 <mon_backtrace+0x17>
	return 0;
}
f010084f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100854:	83 c4 3c             	add    $0x3c,%esp
f0100857:	5b                   	pop    %ebx
f0100858:	5e                   	pop    %esi
f0100859:	5f                   	pop    %edi
f010085a:	5d                   	pop    %ebp
f010085b:	c3                   	ret    

f010085c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010085c:	55                   	push   %ebp
f010085d:	89 e5                	mov    %esp,%ebp
f010085f:	57                   	push   %edi
f0100860:	56                   	push   %esi
f0100861:	53                   	push   %ebx
f0100862:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to %che JOS kernel monitor!\n",'t');
f0100865:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
f010086c:	00 
f010086d:	c7 04 24 3c 1f 10 f0 	movl   $0xf0101f3c,(%esp)
f0100874:	e8 69 01 00 00       	call   f01009e2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100879:	c7 04 24 64 1f 10 f0 	movl   $0xf0101f64,(%esp)
f0100880:	e8 5d 01 00 00       	call   f01009e2 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100885:	c7 04 24 d3 1d 10 f0 	movl   $0xf0101dd3,(%esp)
f010088c:	e8 5f 0a 00 00       	call   f01012f0 <readline>
f0100891:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100893:	85 c0                	test   %eax,%eax
f0100895:	74 ee                	je     f0100885 <monitor+0x29>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100897:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010089e:	be 00 00 00 00       	mov    $0x0,%esi
f01008a3:	eb 06                	jmp    f01008ab <monitor+0x4f>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008a5:	c6 03 00             	movb   $0x0,(%ebx)
f01008a8:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008ab:	0f b6 03             	movzbl (%ebx),%eax
f01008ae:	84 c0                	test   %al,%al
f01008b0:	74 6a                	je     f010091c <monitor+0xc0>
f01008b2:	0f be c0             	movsbl %al,%eax
f01008b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b9:	c7 04 24 d7 1d 10 f0 	movl   $0xf0101dd7,(%esp)
f01008c0:	e8 81 0c 00 00       	call   f0101546 <strchr>
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	75 dc                	jne    f01008a5 <monitor+0x49>
			*buf++ = 0;
		if (*buf == 0)
f01008c9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008cc:	74 4e                	je     f010091c <monitor+0xc0>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008ce:	83 fe 0f             	cmp    $0xf,%esi
f01008d1:	75 16                	jne    f01008e9 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008da:	00 
f01008db:	c7 04 24 dc 1d 10 f0 	movl   $0xf0101ddc,(%esp)
f01008e2:	e8 fb 00 00 00       	call   f01009e2 <cprintf>
f01008e7:	eb 9c                	jmp    f0100885 <monitor+0x29>
			return 0;
		}
		argv[argc++] = buf;
f01008e9:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008ed:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008f0:	0f b6 03             	movzbl (%ebx),%eax
f01008f3:	84 c0                	test   %al,%al
f01008f5:	75 0c                	jne    f0100903 <monitor+0xa7>
f01008f7:	eb b2                	jmp    f01008ab <monitor+0x4f>
			buf++;
f01008f9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008fc:	0f b6 03             	movzbl (%ebx),%eax
f01008ff:	84 c0                	test   %al,%al
f0100901:	74 a8                	je     f01008ab <monitor+0x4f>
f0100903:	0f be c0             	movsbl %al,%eax
f0100906:	89 44 24 04          	mov    %eax,0x4(%esp)
f010090a:	c7 04 24 d7 1d 10 f0 	movl   $0xf0101dd7,(%esp)
f0100911:	e8 30 0c 00 00       	call   f0101546 <strchr>
f0100916:	85 c0                	test   %eax,%eax
f0100918:	74 df                	je     f01008f9 <monitor+0x9d>
f010091a:	eb 8f                	jmp    f01008ab <monitor+0x4f>
			buf++;
	}
	argv[argc] = 0;
f010091c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100923:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100924:	85 f6                	test   %esi,%esi
f0100926:	0f 84 59 ff ff ff    	je     f0100885 <monitor+0x29>
f010092c:	bb c0 1f 10 f0       	mov    $0xf0101fc0,%ebx
f0100931:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100936:	8b 03                	mov    (%ebx),%eax
f0100938:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010093f:	89 04 24             	mov    %eax,(%esp)
f0100942:	e8 84 0b 00 00       	call   f01014cb <strcmp>
f0100947:	85 c0                	test   %eax,%eax
f0100949:	75 24                	jne    f010096f <monitor+0x113>
			return commands[i].func(argc, argv, tf);
f010094b:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010094e:	8b 55 08             	mov    0x8(%ebp),%edx
f0100951:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100955:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100958:	89 54 24 04          	mov    %edx,0x4(%esp)
f010095c:	89 34 24             	mov    %esi,(%esp)
f010095f:	ff 14 85 c8 1f 10 f0 	call   *-0xfefe038(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100966:	85 c0                	test   %eax,%eax
f0100968:	78 28                	js     f0100992 <monitor+0x136>
f010096a:	e9 16 ff ff ff       	jmp    f0100885 <monitor+0x29>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010096f:	83 c7 01             	add    $0x1,%edi
f0100972:	83 c3 0c             	add    $0xc,%ebx
f0100975:	83 ff 03             	cmp    $0x3,%edi
f0100978:	75 bc                	jne    f0100936 <monitor+0xda>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010097a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100981:	c7 04 24 f9 1d 10 f0 	movl   $0xf0101df9,(%esp)
f0100988:	e8 55 00 00 00       	call   f01009e2 <cprintf>
f010098d:	e9 f3 fe ff ff       	jmp    f0100885 <monitor+0x29>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100992:	83 c4 5c             	add    $0x5c,%esp
f0100995:	5b                   	pop    %ebx
f0100996:	5e                   	pop    %esi
f0100997:	5f                   	pop    %edi
f0100998:	5d                   	pop    %ebp
f0100999:	c3                   	ret    
	...

f010099c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010099c:	55                   	push   %ebp
f010099d:	89 e5                	mov    %esp,%ebp
f010099f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a5:	89 04 24             	mov    %eax,(%esp)
f01009a8:	e8 a4 fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f01009ad:	c9                   	leave  
f01009ae:	c3                   	ret    

f01009af <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009af:	55                   	push   %ebp
f01009b0:	89 e5                	mov    %esp,%ebp
f01009b2:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009ca:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d1:	c7 04 24 9c 09 10 f0 	movl   $0xf010099c,(%esp)
f01009d8:	e8 bd 04 00 00       	call   f0100e9a <vprintfmt>
	return cnt;
}
f01009dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e0:	c9                   	leave  
f01009e1:	c3                   	ret    

f01009e2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009e2:	55                   	push   %ebp
f01009e3:	89 e5                	mov    %esp,%ebp
f01009e5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009e8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01009f2:	89 04 24             	mov    %eax,(%esp)
f01009f5:	e8 b5 ff ff ff       	call   f01009af <vcprintf>
	va_end(ap);

	return cnt;
}
f01009fa:	c9                   	leave  
f01009fb:	c3                   	ret    

f01009fc <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009fc:	55                   	push   %ebp
f01009fd:	89 e5                	mov    %esp,%ebp
f01009ff:	57                   	push   %edi
f0100a00:	56                   	push   %esi
f0100a01:	53                   	push   %ebx
f0100a02:	83 ec 10             	sub    $0x10,%esp
f0100a05:	89 c3                	mov    %eax,%ebx
f0100a07:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a0a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a0d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a10:	8b 0a                	mov    (%edx),%ecx
f0100a12:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a15:	8b 00                	mov    (%eax),%eax
f0100a17:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a1a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a21:	eb 77                	jmp    f0100a9a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100a23:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a26:	01 c8                	add    %ecx,%eax
f0100a28:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a2d:	99                   	cltd   
f0100a2e:	f7 ff                	idiv   %edi
f0100a30:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a32:	eb 01                	jmp    f0100a35 <stab_binsearch+0x39>
			m--;
f0100a34:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a35:	39 ca                	cmp    %ecx,%edx
f0100a37:	7c 1d                	jl     f0100a56 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a39:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a3c:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a41:	39 f7                	cmp    %esi,%edi
f0100a43:	75 ef                	jne    f0100a34 <stab_binsearch+0x38>
f0100a45:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a48:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100a4b:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100a4f:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a52:	73 18                	jae    f0100a6c <stab_binsearch+0x70>
f0100a54:	eb 05                	jmp    f0100a5b <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a56:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a59:	eb 3f                	jmp    f0100a9a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a5b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a5e:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a60:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a63:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a6a:	eb 2e                	jmp    f0100a9a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a6c:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a6f:	76 15                	jbe    f0100a86 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a71:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a74:	4f                   	dec    %edi
f0100a75:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a7b:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a7d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a84:	eb 14                	jmp    f0100a9a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a86:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a89:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a8c:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100a8e:	ff 45 0c             	incl   0xc(%ebp)
f0100a91:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a93:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a9a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100a9d:	7e 84                	jle    f0100a23 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a9f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100aa3:	75 0d                	jne    f0100ab2 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100aa5:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aa8:	8b 02                	mov    (%edx),%eax
f0100aaa:	48                   	dec    %eax
f0100aab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aae:	89 01                	mov    %eax,(%ecx)
f0100ab0:	eb 22                	jmp    f0100ad4 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ab5:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ab7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aba:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100abc:	eb 01                	jmp    f0100abf <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100abe:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100abf:	39 c1                	cmp    %eax,%ecx
f0100ac1:	7d 0c                	jge    f0100acf <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ac3:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100ac6:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100acb:	39 f2                	cmp    %esi,%edx
f0100acd:	75 ef                	jne    f0100abe <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100acf:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ad2:	89 02                	mov    %eax,(%edx)
	}
}
f0100ad4:	83 c4 10             	add    $0x10,%esp
f0100ad7:	5b                   	pop    %ebx
f0100ad8:	5e                   	pop    %esi
f0100ad9:	5f                   	pop    %edi
f0100ada:	5d                   	pop    %ebp
f0100adb:	c3                   	ret    

f0100adc <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100adc:	55                   	push   %ebp
f0100add:	89 e5                	mov    %esp,%ebp
f0100adf:	83 ec 58             	sub    $0x58,%esp
f0100ae2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100ae5:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ae8:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100aeb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100af1:	c7 03 e4 1f 10 f0    	movl   $0xf0101fe4,(%ebx)
	info->eip_line = 0;
f0100af7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100afe:	c7 43 08 e4 1f 10 f0 	movl   $0xf0101fe4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b05:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b0c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b0f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b16:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b1c:	76 12                	jbe    f0100b30 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b1e:	b8 38 78 10 f0       	mov    $0xf0107838,%eax
f0100b23:	3d e9 5e 10 f0       	cmp    $0xf0105ee9,%eax
f0100b28:	0f 86 f1 01 00 00    	jbe    f0100d1f <debuginfo_eip+0x243>
f0100b2e:	eb 1c                	jmp    f0100b4c <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b30:	c7 44 24 08 ee 1f 10 	movl   $0xf0101fee,0x8(%esp)
f0100b37:	f0 
f0100b38:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b3f:	00 
f0100b40:	c7 04 24 fb 1f 10 f0 	movl   $0xf0101ffb,(%esp)
f0100b47:	e8 ac f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b51:	80 3d 37 78 10 f0 00 	cmpb   $0x0,0xf0107837
f0100b58:	0f 85 cd 01 00 00    	jne    f0100d2b <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b5e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b65:	b8 e8 5e 10 f0       	mov    $0xf0105ee8,%eax
f0100b6a:	2d 1c 22 10 f0       	sub    $0xf010221c,%eax
f0100b6f:	c1 f8 02             	sar    $0x2,%eax
f0100b72:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b78:	83 e8 01             	sub    $0x1,%eax
f0100b7b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b7e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b82:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b89:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b8c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b8f:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100b94:	e8 63 fe ff ff       	call   f01009fc <stab_binsearch>
	if (lfile == 0)
f0100b99:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100ba1:	85 d2                	test   %edx,%edx
f0100ba3:	0f 84 82 01 00 00    	je     f0100d2b <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ba9:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100bac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100baf:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bb2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb6:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bbd:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bc3:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100bc8:	e8 2f fe ff ff       	call   f01009fc <stab_binsearch>

	if (lfun <= rfun) {
f0100bcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bd0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bd3:	39 d0                	cmp    %edx,%eax
f0100bd5:	7f 3d                	jg     f0100c14 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bd7:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bda:	8d b9 1c 22 10 f0    	lea    -0xfefdde4(%ecx),%edi
f0100be0:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100be3:	8b 89 1c 22 10 f0    	mov    -0xfefdde4(%ecx),%ecx
f0100be9:	bf 38 78 10 f0       	mov    $0xf0107838,%edi
f0100bee:	81 ef e9 5e 10 f0    	sub    $0xf0105ee9,%edi
f0100bf4:	39 f9                	cmp    %edi,%ecx
f0100bf6:	73 09                	jae    f0100c01 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bf8:	81 c1 e9 5e 10 f0    	add    $0xf0105ee9,%ecx
f0100bfe:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c01:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100c04:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c07:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c0a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c0c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c0f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c12:	eb 0f                	jmp    f0100c23 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c14:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c1a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c20:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c23:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c2a:	00 
f0100c2b:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c2e:	89 04 24             	mov    %eax,(%esp)
f0100c31:	e8 44 09 00 00       	call   f010157a <strfind>
f0100c36:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c39:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
f0100c3c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c40:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c47:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c4a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c4d:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100c52:	e8 a5 fd ff ff       	call   f01009fc <stab_binsearch>
	if(lline > rline)
f0100c57:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		return -1;
f0100c5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline,N_SLINE,addr);
	if(lline > rline)
f0100c5f:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100c62:	0f 8f c3 00 00 00    	jg     f0100d2b <debuginfo_eip+0x24f>
		return -1;
		//cprintf("lline %d, rline %d",lline, rline);
	info -> eip_line = stabs[lline].n_desc;
f0100c68:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100c6b:	0f b7 82 22 22 10 f0 	movzwl -0xfefddde(%edx),%eax
f0100c72:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c78:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c7b:	39 c8                	cmp    %ecx,%eax
f0100c7d:	7c 5f                	jl     f0100cde <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100c7f:	89 c2                	mov    %eax,%edx
f0100c81:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100c84:	80 be 20 22 10 f0 84 	cmpb   $0x84,-0xfefdde0(%esi)
f0100c8b:	75 18                	jne    f0100ca5 <debuginfo_eip+0x1c9>
f0100c8d:	eb 30                	jmp    f0100cbf <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c8f:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c92:	39 c1                	cmp    %eax,%ecx
f0100c94:	7f 48                	jg     f0100cde <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100c96:	89 c2                	mov    %eax,%edx
f0100c98:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100c9b:	80 3c b5 20 22 10 f0 	cmpb   $0x84,-0xfefdde0(,%esi,4)
f0100ca2:	84 
f0100ca3:	74 1a                	je     f0100cbf <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ca5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100ca8:	8d 14 95 1c 22 10 f0 	lea    -0xfefdde4(,%edx,4),%edx
f0100caf:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100cb3:	75 da                	jne    f0100c8f <debuginfo_eip+0x1b3>
f0100cb5:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100cb9:	74 d4                	je     f0100c8f <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cbb:	39 c1                	cmp    %eax,%ecx
f0100cbd:	7f 1f                	jg     f0100cde <debuginfo_eip+0x202>
f0100cbf:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cc2:	8b 80 1c 22 10 f0    	mov    -0xfefdde4(%eax),%eax
f0100cc8:	ba 38 78 10 f0       	mov    $0xf0107838,%edx
f0100ccd:	81 ea e9 5e 10 f0    	sub    $0xf0105ee9,%edx
f0100cd3:	39 d0                	cmp    %edx,%eax
f0100cd5:	73 07                	jae    f0100cde <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cd7:	05 e9 5e 10 f0       	add    $0xf0105ee9,%eax
f0100cdc:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cde:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ce1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100ce4:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce9:	39 ca                	cmp    %ecx,%edx
f0100ceb:	7d 3e                	jge    f0100d2b <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0100ced:	83 c2 01             	add    $0x1,%edx
f0100cf0:	39 d1                	cmp    %edx,%ecx
f0100cf2:	7e 37                	jle    f0100d2b <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cf4:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100cf7:	80 be 20 22 10 f0 a0 	cmpb   $0xa0,-0xfefdde0(%esi)
f0100cfe:	75 2b                	jne    f0100d2b <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0100d00:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d04:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d07:	39 d1                	cmp    %edx,%ecx
f0100d09:	7e 1b                	jle    f0100d26 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d0b:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100d0e:	80 3c 85 20 22 10 f0 	cmpb   $0xa0,-0xfefdde0(,%eax,4)
f0100d15:	a0 
f0100d16:	74 e8                	je     f0100d00 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100d18:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1d:	eb 0c                	jmp    f0100d2b <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d24:	eb 05                	jmp    f0100d2b <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;

	//cprintf("\neip_file %s\neip_line %d\neip_fn_name %s\neip_fn_namelen %d\neip_fn_addr %08x\neip_fn_narg\n",info->eip_file,info->eip_line,info->eip_fn_name,info->eip_fn_namelen,info->eip_fn_addr,info->eip_fn_narg);

	return 0;
f0100d26:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d2b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d2e:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d31:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d34:	89 ec                	mov    %ebp,%esp
f0100d36:	5d                   	pop    %ebp
f0100d37:	c3                   	ret    
	...

f0100d40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
f0100d43:	57                   	push   %edi
f0100d44:	56                   	push   %esi
f0100d45:	53                   	push   %ebx
f0100d46:	83 ec 3c             	sub    $0x3c,%esp
f0100d49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d4c:	89 d7                	mov    %edx,%edi
f0100d4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d51:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d57:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d5a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100d5d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d60:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d65:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d68:	72 11                	jb     f0100d7b <printnum+0x3b>
f0100d6a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d6d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d70:	76 09                	jbe    f0100d7b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d72:	83 eb 01             	sub    $0x1,%ebx
f0100d75:	85 db                	test   %ebx,%ebx
f0100d77:	7f 51                	jg     f0100dca <printnum+0x8a>
f0100d79:	eb 5e                	jmp    f0100dd9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d7b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100d7f:	83 eb 01             	sub    $0x1,%ebx
f0100d82:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d86:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d89:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d8d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100d91:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100d95:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d9c:	00 
f0100d9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100da0:	89 04 24             	mov    %eax,(%esp)
f0100da3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100da6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100daa:	e8 41 0a 00 00       	call   f01017f0 <__udivdi3>
f0100daf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100db3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100db7:	89 04 24             	mov    %eax,(%esp)
f0100dba:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dbe:	89 fa                	mov    %edi,%edx
f0100dc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dc3:	e8 78 ff ff ff       	call   f0100d40 <printnum>
f0100dc8:	eb 0f                	jmp    f0100dd9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dce:	89 34 24             	mov    %esi,(%esp)
f0100dd1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dd4:	83 eb 01             	sub    $0x1,%ebx
f0100dd7:	75 f1                	jne    f0100dca <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dd9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ddd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100de1:	8b 45 10             	mov    0x10(%ebp),%eax
f0100de4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100de8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100def:	00 
f0100df0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100df3:	89 04 24             	mov    %eax,(%esp)
f0100df6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100df9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dfd:	e8 1e 0b 00 00       	call   f0101920 <__umoddi3>
f0100e02:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e06:	0f be 80 09 20 10 f0 	movsbl -0xfefdff7(%eax),%eax
f0100e0d:	89 04 24             	mov    %eax,(%esp)
f0100e10:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e13:	83 c4 3c             	add    $0x3c,%esp
f0100e16:	5b                   	pop    %ebx
f0100e17:	5e                   	pop    %esi
f0100e18:	5f                   	pop    %edi
f0100e19:	5d                   	pop    %ebp
f0100e1a:	c3                   	ret    

f0100e1b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e1b:	55                   	push   %ebp
f0100e1c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e1e:	83 fa 01             	cmp    $0x1,%edx
f0100e21:	7e 0e                	jle    f0100e31 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e23:	8b 10                	mov    (%eax),%edx
f0100e25:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e28:	89 08                	mov    %ecx,(%eax)
f0100e2a:	8b 02                	mov    (%edx),%eax
f0100e2c:	8b 52 04             	mov    0x4(%edx),%edx
f0100e2f:	eb 22                	jmp    f0100e53 <getuint+0x38>
	else if (lflag)
f0100e31:	85 d2                	test   %edx,%edx
f0100e33:	74 10                	je     f0100e45 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e35:	8b 10                	mov    (%eax),%edx
f0100e37:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e3a:	89 08                	mov    %ecx,(%eax)
f0100e3c:	8b 02                	mov    (%edx),%eax
f0100e3e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e43:	eb 0e                	jmp    f0100e53 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e45:	8b 10                	mov    (%eax),%edx
f0100e47:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e4a:	89 08                	mov    %ecx,(%eax)
f0100e4c:	8b 02                	mov    (%edx),%eax
f0100e4e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e53:	5d                   	pop    %ebp
f0100e54:	c3                   	ret    

f0100e55 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e55:	55                   	push   %ebp
f0100e56:	89 e5                	mov    %esp,%ebp
f0100e58:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e5b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e5f:	8b 10                	mov    (%eax),%edx
f0100e61:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e64:	73 0a                	jae    f0100e70 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e66:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e69:	88 0a                	mov    %cl,(%edx)
f0100e6b:	83 c2 01             	add    $0x1,%edx
f0100e6e:	89 10                	mov    %edx,(%eax)
}
f0100e70:	5d                   	pop    %ebp
f0100e71:	c3                   	ret    

f0100e72 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e72:	55                   	push   %ebp
f0100e73:	89 e5                	mov    %esp,%ebp
f0100e75:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e78:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e7b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e7f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e82:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e86:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e90:	89 04 24             	mov    %eax,(%esp)
f0100e93:	e8 02 00 00 00       	call   f0100e9a <vprintfmt>
	va_end(ap);
}
f0100e98:	c9                   	leave  
f0100e99:	c3                   	ret    

f0100e9a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e9a:	55                   	push   %ebp
f0100e9b:	89 e5                	mov    %esp,%ebp
f0100e9d:	57                   	push   %edi
f0100e9e:	56                   	push   %esi
f0100e9f:	53                   	push   %ebx
f0100ea0:	83 ec 4c             	sub    $0x4c,%esp
f0100ea3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ea6:	8b 75 10             	mov    0x10(%ebp),%esi
f0100ea9:	eb 12                	jmp    f0100ebd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100eab:	85 c0                	test   %eax,%eax
f0100ead:	0f 84 a9 03 00 00    	je     f010125c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0100eb3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eb7:	89 04 24             	mov    %eax,(%esp)
f0100eba:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ebd:	0f b6 06             	movzbl (%esi),%eax
f0100ec0:	83 c6 01             	add    $0x1,%esi
f0100ec3:	83 f8 25             	cmp    $0x25,%eax
f0100ec6:	75 e3                	jne    f0100eab <vprintfmt+0x11>
f0100ec8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ecc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100ed3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100ed8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100edf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ee4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ee7:	eb 2b                	jmp    f0100f14 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100eec:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ef0:	eb 22                	jmp    f0100f14 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ef5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100ef9:	eb 19                	jmp    f0100f14 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100efe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100f05:	eb 0d                	jmp    f0100f14 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f07:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f0a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f0d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f14:	0f b6 06             	movzbl (%esi),%eax
f0100f17:	0f b6 d0             	movzbl %al,%edx
f0100f1a:	8d 7e 01             	lea    0x1(%esi),%edi
f0100f1d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100f20:	83 e8 23             	sub    $0x23,%eax
f0100f23:	3c 55                	cmp    $0x55,%al
f0100f25:	0f 87 0b 03 00 00    	ja     f0101236 <vprintfmt+0x39c>
f0100f2b:	0f b6 c0             	movzbl %al,%eax
f0100f2e:	ff 24 85 98 20 10 f0 	jmp    *-0xfefdf68(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f35:	83 ea 30             	sub    $0x30,%edx
f0100f38:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100f3b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f3f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100f45:	83 fa 09             	cmp    $0x9,%edx
f0100f48:	77 4a                	ja     f0100f94 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f4d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f50:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100f53:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100f57:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f5a:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100f5d:	83 fa 09             	cmp    $0x9,%edx
f0100f60:	76 eb                	jbe    f0100f4d <vprintfmt+0xb3>
f0100f62:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f65:	eb 2d                	jmp    f0100f94 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f67:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6a:	8d 50 04             	lea    0x4(%eax),%edx
f0100f6d:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f70:	8b 00                	mov    (%eax),%eax
f0100f72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f75:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f78:	eb 1a                	jmp    f0100f94 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100f7d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f81:	79 91                	jns    f0100f14 <vprintfmt+0x7a>
f0100f83:	e9 73 ff ff ff       	jmp    f0100efb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f88:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f8b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100f92:	eb 80                	jmp    f0100f14 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100f94:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f98:	0f 89 76 ff ff ff    	jns    f0100f14 <vprintfmt+0x7a>
f0100f9e:	e9 64 ff ff ff       	jmp    f0100f07 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fa3:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fa9:	e9 66 ff ff ff       	jmp    f0100f14 <vprintfmt+0x7a>

		// character
		case 'c':
			ch = va_arg(ap, int) + (2<<8);
f0100fae:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb4:	89 55 14             	mov    %edx,0x14(%ebp)
			putch(ch, putdat);
f0100fb7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
			lflag++;
			goto reswitch;

		// character
		case 'c':
			ch = va_arg(ap, int) + (2<<8);
f0100fbb:	8b 00                	mov    (%eax),%eax
f0100fbd:	05 00 02 00 00       	add    $0x200,%eax
			putch(ch, putdat);
f0100fc2:	89 04 24             	mov    %eax,(%esp)
f0100fc5:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc8:	8b 75 e0             	mov    -0x20(%ebp),%esi
		// character
		case 'c':
			ch = va_arg(ap, int) + (2<<8);
			putch(ch, putdat);
			//Color = 0;
			break;
f0100fcb:	e9 ed fe ff ff       	jmp    f0100ebd <vprintfmt+0x23>
				default:
					Color = 0;					
			}
*/		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd3:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd9:	8b 00                	mov    (%eax),%eax
f0100fdb:	89 c2                	mov    %eax,%edx
f0100fdd:	c1 fa 1f             	sar    $0x1f,%edx
f0100fe0:	31 d0                	xor    %edx,%eax
f0100fe2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fe4:	83 f8 06             	cmp    $0x6,%eax
f0100fe7:	7f 0b                	jg     f0100ff4 <vprintfmt+0x15a>
f0100fe9:	8b 14 85 f0 21 10 f0 	mov    -0xfefde10(,%eax,4),%edx
f0100ff0:	85 d2                	test   %edx,%edx
f0100ff2:	75 23                	jne    f0101017 <vprintfmt+0x17d>
				printfmt(putch, putdat, "error %d", err);
f0100ff4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ff8:	c7 44 24 08 21 20 10 	movl   $0xf0102021,0x8(%esp)
f0100fff:	f0 
f0101000:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101004:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101007:	89 3c 24             	mov    %edi,(%esp)
f010100a:	e8 63 fe ff ff       	call   f0100e72 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010100f:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101012:	e9 a6 fe ff ff       	jmp    f0100ebd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0101017:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010101b:	c7 44 24 08 2a 20 10 	movl   $0xf010202a,0x8(%esp)
f0101022:	f0 
f0101023:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101027:	8b 7d 08             	mov    0x8(%ebp),%edi
f010102a:	89 3c 24             	mov    %edi,(%esp)
f010102d:	e8 40 fe ff ff       	call   f0100e72 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101032:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101035:	e9 83 fe ff ff       	jmp    f0100ebd <vprintfmt+0x23>
f010103a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010103d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101040:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101043:	8b 45 14             	mov    0x14(%ebp),%eax
f0101046:	8d 50 04             	lea    0x4(%eax),%edx
f0101049:	89 55 14             	mov    %edx,0x14(%ebp)
f010104c:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010104e:	85 f6                	test   %esi,%esi
f0101050:	ba 1a 20 10 f0       	mov    $0xf010201a,%edx
f0101055:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101058:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010105c:	7e 06                	jle    f0101064 <vprintfmt+0x1ca>
f010105e:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0101062:	75 10                	jne    f0101074 <vprintfmt+0x1da>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101064:	0f be 06             	movsbl (%esi),%eax
f0101067:	83 c6 01             	add    $0x1,%esi
f010106a:	85 c0                	test   %eax,%eax
f010106c:	0f 85 86 00 00 00    	jne    f01010f8 <vprintfmt+0x25e>
f0101072:	eb 76                	jmp    f01010ea <vprintfmt+0x250>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101074:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101078:	89 34 24             	mov    %esi,(%esp)
f010107b:	e8 5b 03 00 00       	call   f01013db <strnlen>
f0101080:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101083:	29 c2                	sub    %eax,%edx
f0101085:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101088:	85 d2                	test   %edx,%edx
f010108a:	7e d8                	jle    f0101064 <vprintfmt+0x1ca>
					putch(padc, putdat);
f010108c:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101090:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0101093:	89 d6                	mov    %edx,%esi
f0101095:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101098:	89 c7                	mov    %eax,%edi
f010109a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010109e:	89 3c 24             	mov    %edi,(%esp)
f01010a1:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a4:	83 ee 01             	sub    $0x1,%esi
f01010a7:	75 f1                	jne    f010109a <vprintfmt+0x200>
f01010a9:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010ac:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01010af:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01010b2:	eb b0                	jmp    f0101064 <vprintfmt+0x1ca>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010b4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010b8:	74 18                	je     f01010d2 <vprintfmt+0x238>
f01010ba:	8d 50 e0             	lea    -0x20(%eax),%edx
f01010bd:	83 fa 5e             	cmp    $0x5e,%edx
f01010c0:	76 10                	jbe    f01010d2 <vprintfmt+0x238>
					putch('?', putdat);
f01010c2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010cd:	ff 55 08             	call   *0x8(%ebp)
f01010d0:	eb 0a                	jmp    f01010dc <vprintfmt+0x242>
				else
					putch(ch, putdat);
f01010d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d6:	89 04 24             	mov    %eax,(%esp)
f01010d9:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010dc:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01010e0:	0f be 06             	movsbl (%esi),%eax
f01010e3:	83 c6 01             	add    $0x1,%esi
f01010e6:	85 c0                	test   %eax,%eax
f01010e8:	75 0e                	jne    f01010f8 <vprintfmt+0x25e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010f1:	7f 11                	jg     f0101104 <vprintfmt+0x26a>
f01010f3:	e9 c5 fd ff ff       	jmp    f0100ebd <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010f8:	85 ff                	test   %edi,%edi
f01010fa:	78 b8                	js     f01010b4 <vprintfmt+0x21a>
f01010fc:	83 ef 01             	sub    $0x1,%edi
f01010ff:	90                   	nop
f0101100:	79 b2                	jns    f01010b4 <vprintfmt+0x21a>
f0101102:	eb e6                	jmp    f01010ea <vprintfmt+0x250>
f0101104:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101107:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010110a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010110e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101115:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101117:	83 ee 01             	sub    $0x1,%esi
f010111a:	75 ee                	jne    f010110a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010111c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010111f:	e9 99 fd ff ff       	jmp    f0100ebd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101124:	83 f9 01             	cmp    $0x1,%ecx
f0101127:	7e 10                	jle    f0101139 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101129:	8b 45 14             	mov    0x14(%ebp),%eax
f010112c:	8d 50 08             	lea    0x8(%eax),%edx
f010112f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101132:	8b 30                	mov    (%eax),%esi
f0101134:	8b 78 04             	mov    0x4(%eax),%edi
f0101137:	eb 26                	jmp    f010115f <vprintfmt+0x2c5>
	else if (lflag)
f0101139:	85 c9                	test   %ecx,%ecx
f010113b:	74 12                	je     f010114f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010113d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101140:	8d 50 04             	lea    0x4(%eax),%edx
f0101143:	89 55 14             	mov    %edx,0x14(%ebp)
f0101146:	8b 30                	mov    (%eax),%esi
f0101148:	89 f7                	mov    %esi,%edi
f010114a:	c1 ff 1f             	sar    $0x1f,%edi
f010114d:	eb 10                	jmp    f010115f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010114f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101152:	8d 50 04             	lea    0x4(%eax),%edx
f0101155:	89 55 14             	mov    %edx,0x14(%ebp)
f0101158:	8b 30                	mov    (%eax),%esi
f010115a:	89 f7                	mov    %esi,%edi
f010115c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010115f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101164:	85 ff                	test   %edi,%edi
f0101166:	0f 89 8c 00 00 00    	jns    f01011f8 <vprintfmt+0x35e>
				putch('-', putdat);
f010116c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101170:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101177:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010117a:	f7 de                	neg    %esi
f010117c:	83 d7 00             	adc    $0x0,%edi
f010117f:	f7 df                	neg    %edi
			}
			base = 10;
f0101181:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101186:	eb 70                	jmp    f01011f8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101188:	89 ca                	mov    %ecx,%edx
f010118a:	8d 45 14             	lea    0x14(%ebp),%eax
f010118d:	e8 89 fc ff ff       	call   f0100e1b <getuint>
f0101192:	89 c6                	mov    %eax,%esi
f0101194:	89 d7                	mov    %edx,%edi
			base = 10;
f0101196:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010119b:	eb 5b                	jmp    f01011f8 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010119d:	89 ca                	mov    %ecx,%edx
f010119f:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a2:	e8 74 fc ff ff       	call   f0100e1b <getuint>
f01011a7:	89 c6                	mov    %eax,%esi
f01011a9:	89 d7                	mov    %edx,%edi
			base = 8;
f01011ab:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f01011b0:	eb 46                	jmp    f01011f8 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f01011b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d1:	8d 50 04             	lea    0x4(%eax),%edx
f01011d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011d7:	8b 30                	mov    (%eax),%esi
f01011d9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011de:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01011e3:	eb 13                	jmp    f01011f8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011e5:	89 ca                	mov    %ecx,%edx
f01011e7:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ea:	e8 2c fc ff ff       	call   f0100e1b <getuint>
f01011ef:	89 c6                	mov    %eax,%esi
f01011f1:	89 d7                	mov    %edx,%edi
			base = 16;
f01011f3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011f8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01011fc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101200:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101203:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101207:	89 44 24 08          	mov    %eax,0x8(%esp)
f010120b:	89 34 24             	mov    %esi,(%esp)
f010120e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101212:	89 da                	mov    %ebx,%edx
f0101214:	8b 45 08             	mov    0x8(%ebp),%eax
f0101217:	e8 24 fb ff ff       	call   f0100d40 <printnum>
			break;
f010121c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010121f:	e9 99 fc ff ff       	jmp    f0100ebd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101224:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101228:	89 14 24             	mov    %edx,(%esp)
f010122b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010122e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101231:	e9 87 fc ff ff       	jmp    f0100ebd <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101236:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010123a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101241:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101244:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101248:	0f 84 6f fc ff ff    	je     f0100ebd <vprintfmt+0x23>
f010124e:	83 ee 01             	sub    $0x1,%esi
f0101251:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101255:	75 f7                	jne    f010124e <vprintfmt+0x3b4>
f0101257:	e9 61 fc ff ff       	jmp    f0100ebd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010125c:	83 c4 4c             	add    $0x4c,%esp
f010125f:	5b                   	pop    %ebx
f0101260:	5e                   	pop    %esi
f0101261:	5f                   	pop    %edi
f0101262:	5d                   	pop    %ebp
f0101263:	c3                   	ret    

f0101264 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101264:	55                   	push   %ebp
f0101265:	89 e5                	mov    %esp,%ebp
f0101267:	83 ec 28             	sub    $0x28,%esp
f010126a:	8b 45 08             	mov    0x8(%ebp),%eax
f010126d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101270:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101273:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101277:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010127a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101281:	85 c0                	test   %eax,%eax
f0101283:	74 30                	je     f01012b5 <vsnprintf+0x51>
f0101285:	85 d2                	test   %edx,%edx
f0101287:	7e 2c                	jle    f01012b5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101289:	8b 45 14             	mov    0x14(%ebp),%eax
f010128c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101290:	8b 45 10             	mov    0x10(%ebp),%eax
f0101293:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101297:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010129a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129e:	c7 04 24 55 0e 10 f0 	movl   $0xf0100e55,(%esp)
f01012a5:	e8 f0 fb ff ff       	call   f0100e9a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012ad:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012b3:	eb 05                	jmp    f01012ba <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012b5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012ba:	c9                   	leave  
f01012bb:	c3                   	ret    

f01012bc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012bc:	55                   	push   %ebp
f01012bd:	89 e5                	mov    %esp,%ebp
f01012bf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012c2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c9:	8b 45 10             	mov    0x10(%ebp),%eax
f01012cc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012da:	89 04 24             	mov    %eax,(%esp)
f01012dd:	e8 82 ff ff ff       	call   f0101264 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012e2:	c9                   	leave  
f01012e3:	c3                   	ret    
	...

f01012f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	57                   	push   %edi
f01012f4:	56                   	push   %esi
f01012f5:	53                   	push   %ebx
f01012f6:	83 ec 1c             	sub    $0x1c,%esp
f01012f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012fc:	85 c0                	test   %eax,%eax
f01012fe:	74 10                	je     f0101310 <readline+0x20>
		cprintf("%s", prompt);
f0101300:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101304:	c7 04 24 2a 20 10 f0 	movl   $0xf010202a,(%esp)
f010130b:	e8 d2 f6 ff ff       	call   f01009e2 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101310:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101317:	e8 56 f3 ff ff       	call   f0100672 <iscons>
f010131c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010131e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101323:	e8 39 f3 ff ff       	call   f0100661 <getchar>
f0101328:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010132a:	85 c0                	test   %eax,%eax
f010132c:	79 17                	jns    f0101345 <readline+0x55>
			cprintf("read error: %e\n", c);
f010132e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101332:	c7 04 24 0c 22 10 f0 	movl   $0xf010220c,(%esp)
f0101339:	e8 a4 f6 ff ff       	call   f01009e2 <cprintf>
			return NULL;
f010133e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101343:	eb 6d                	jmp    f01013b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101345:	83 f8 08             	cmp    $0x8,%eax
f0101348:	74 05                	je     f010134f <readline+0x5f>
f010134a:	83 f8 7f             	cmp    $0x7f,%eax
f010134d:	75 19                	jne    f0101368 <readline+0x78>
f010134f:	85 f6                	test   %esi,%esi
f0101351:	7e 15                	jle    f0101368 <readline+0x78>
			if (echoing)
f0101353:	85 ff                	test   %edi,%edi
f0101355:	74 0c                	je     f0101363 <readline+0x73>
				cputchar('\b');
f0101357:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010135e:	e8 ee f2 ff ff       	call   f0100651 <cputchar>
			i--;
f0101363:	83 ee 01             	sub    $0x1,%esi
f0101366:	eb bb                	jmp    f0101323 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101368:	83 fb 1f             	cmp    $0x1f,%ebx
f010136b:	7e 1f                	jle    f010138c <readline+0x9c>
f010136d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101373:	7f 17                	jg     f010138c <readline+0x9c>
			if (echoing)
f0101375:	85 ff                	test   %edi,%edi
f0101377:	74 08                	je     f0101381 <readline+0x91>
				cputchar(c);
f0101379:	89 1c 24             	mov    %ebx,(%esp)
f010137c:	e8 d0 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101381:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101387:	83 c6 01             	add    $0x1,%esi
f010138a:	eb 97                	jmp    f0101323 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010138c:	83 fb 0a             	cmp    $0xa,%ebx
f010138f:	74 05                	je     f0101396 <readline+0xa6>
f0101391:	83 fb 0d             	cmp    $0xd,%ebx
f0101394:	75 8d                	jne    f0101323 <readline+0x33>
			if (echoing)
f0101396:	85 ff                	test   %edi,%edi
f0101398:	74 0c                	je     f01013a6 <readline+0xb6>
				cputchar('\n');
f010139a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013a1:	e8 ab f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f01013a6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013ad:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013b2:	83 c4 1c             	add    $0x1c,%esp
f01013b5:	5b                   	pop    %ebx
f01013b6:	5e                   	pop    %esi
f01013b7:	5f                   	pop    %edi
f01013b8:	5d                   	pop    %ebp
f01013b9:	c3                   	ret    
f01013ba:	00 00                	add    %al,(%eax)
f01013bc:	00 00                	add    %al,(%eax)
	...

f01013c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013cb:	80 3a 00             	cmpb   $0x0,(%edx)
f01013ce:	74 09                	je     f01013d9 <strlen+0x19>
		n++;
f01013d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013d7:	75 f7                	jne    f01013d0 <strlen+0x10>
		n++;
	return n;
}
f01013d9:	5d                   	pop    %ebp
f01013da:	c3                   	ret    

f01013db <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013db:	55                   	push   %ebp
f01013dc:	89 e5                	mov    %esp,%ebp
f01013de:	53                   	push   %ebx
f01013df:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ea:	85 c9                	test   %ecx,%ecx
f01013ec:	74 1a                	je     f0101408 <strnlen+0x2d>
f01013ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013f1:	74 15                	je     f0101408 <strnlen+0x2d>
f01013f3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013f8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013fa:	39 ca                	cmp    %ecx,%edx
f01013fc:	74 0a                	je     f0101408 <strnlen+0x2d>
f01013fe:	83 c2 01             	add    $0x1,%edx
f0101401:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101406:	75 f0                	jne    f01013f8 <strnlen+0x1d>
		n++;
	return n;
}
f0101408:	5b                   	pop    %ebx
f0101409:	5d                   	pop    %ebp
f010140a:	c3                   	ret    

f010140b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010140b:	55                   	push   %ebp
f010140c:	89 e5                	mov    %esp,%ebp
f010140e:	53                   	push   %ebx
f010140f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101412:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101415:	ba 00 00 00 00       	mov    $0x0,%edx
f010141a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010141e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101421:	83 c2 01             	add    $0x1,%edx
f0101424:	84 c9                	test   %cl,%cl
f0101426:	75 f2                	jne    f010141a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101428:	5b                   	pop    %ebx
f0101429:	5d                   	pop    %ebp
f010142a:	c3                   	ret    

f010142b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010142b:	55                   	push   %ebp
f010142c:	89 e5                	mov    %esp,%ebp
f010142e:	53                   	push   %ebx
f010142f:	83 ec 08             	sub    $0x8,%esp
f0101432:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101435:	89 1c 24             	mov    %ebx,(%esp)
f0101438:	e8 83 ff ff ff       	call   f01013c0 <strlen>
	strcpy(dst + len, src);
f010143d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101440:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101444:	01 d8                	add    %ebx,%eax
f0101446:	89 04 24             	mov    %eax,(%esp)
f0101449:	e8 bd ff ff ff       	call   f010140b <strcpy>
	return dst;
}
f010144e:	89 d8                	mov    %ebx,%eax
f0101450:	83 c4 08             	add    $0x8,%esp
f0101453:	5b                   	pop    %ebx
f0101454:	5d                   	pop    %ebp
f0101455:	c3                   	ret    

f0101456 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101456:	55                   	push   %ebp
f0101457:	89 e5                	mov    %esp,%ebp
f0101459:	56                   	push   %esi
f010145a:	53                   	push   %ebx
f010145b:	8b 45 08             	mov    0x8(%ebp),%eax
f010145e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101461:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101464:	85 f6                	test   %esi,%esi
f0101466:	74 18                	je     f0101480 <strncpy+0x2a>
f0101468:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010146d:	0f b6 1a             	movzbl (%edx),%ebx
f0101470:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101473:	80 3a 01             	cmpb   $0x1,(%edx)
f0101476:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101479:	83 c1 01             	add    $0x1,%ecx
f010147c:	39 f1                	cmp    %esi,%ecx
f010147e:	75 ed                	jne    f010146d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101480:	5b                   	pop    %ebx
f0101481:	5e                   	pop    %esi
f0101482:	5d                   	pop    %ebp
f0101483:	c3                   	ret    

f0101484 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101484:	55                   	push   %ebp
f0101485:	89 e5                	mov    %esp,%ebp
f0101487:	57                   	push   %edi
f0101488:	56                   	push   %esi
f0101489:	53                   	push   %ebx
f010148a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010148d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101490:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101493:	89 f8                	mov    %edi,%eax
f0101495:	85 f6                	test   %esi,%esi
f0101497:	74 2b                	je     f01014c4 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101499:	83 fe 01             	cmp    $0x1,%esi
f010149c:	74 23                	je     f01014c1 <strlcpy+0x3d>
f010149e:	0f b6 0b             	movzbl (%ebx),%ecx
f01014a1:	84 c9                	test   %cl,%cl
f01014a3:	74 1c                	je     f01014c1 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01014a5:	83 ee 02             	sub    $0x2,%esi
f01014a8:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014ad:	88 08                	mov    %cl,(%eax)
f01014af:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014b2:	39 f2                	cmp    %esi,%edx
f01014b4:	74 0b                	je     f01014c1 <strlcpy+0x3d>
f01014b6:	83 c2 01             	add    $0x1,%edx
f01014b9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014bd:	84 c9                	test   %cl,%cl
f01014bf:	75 ec                	jne    f01014ad <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01014c1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014c4:	29 f8                	sub    %edi,%eax
}
f01014c6:	5b                   	pop    %ebx
f01014c7:	5e                   	pop    %esi
f01014c8:	5f                   	pop    %edi
f01014c9:	5d                   	pop    %ebp
f01014ca:	c3                   	ret    

f01014cb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014cb:	55                   	push   %ebp
f01014cc:	89 e5                	mov    %esp,%ebp
f01014ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014d1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014d4:	0f b6 01             	movzbl (%ecx),%eax
f01014d7:	84 c0                	test   %al,%al
f01014d9:	74 16                	je     f01014f1 <strcmp+0x26>
f01014db:	3a 02                	cmp    (%edx),%al
f01014dd:	75 12                	jne    f01014f1 <strcmp+0x26>
		p++, q++;
f01014df:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014e2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01014e6:	84 c0                	test   %al,%al
f01014e8:	74 07                	je     f01014f1 <strcmp+0x26>
f01014ea:	83 c1 01             	add    $0x1,%ecx
f01014ed:	3a 02                	cmp    (%edx),%al
f01014ef:	74 ee                	je     f01014df <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f1:	0f b6 c0             	movzbl %al,%eax
f01014f4:	0f b6 12             	movzbl (%edx),%edx
f01014f7:	29 d0                	sub    %edx,%eax
}
f01014f9:	5d                   	pop    %ebp
f01014fa:	c3                   	ret    

f01014fb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014fb:	55                   	push   %ebp
f01014fc:	89 e5                	mov    %esp,%ebp
f01014fe:	53                   	push   %ebx
f01014ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101502:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101505:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101508:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010150d:	85 d2                	test   %edx,%edx
f010150f:	74 28                	je     f0101539 <strncmp+0x3e>
f0101511:	0f b6 01             	movzbl (%ecx),%eax
f0101514:	84 c0                	test   %al,%al
f0101516:	74 24                	je     f010153c <strncmp+0x41>
f0101518:	3a 03                	cmp    (%ebx),%al
f010151a:	75 20                	jne    f010153c <strncmp+0x41>
f010151c:	83 ea 01             	sub    $0x1,%edx
f010151f:	74 13                	je     f0101534 <strncmp+0x39>
		n--, p++, q++;
f0101521:	83 c1 01             	add    $0x1,%ecx
f0101524:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101527:	0f b6 01             	movzbl (%ecx),%eax
f010152a:	84 c0                	test   %al,%al
f010152c:	74 0e                	je     f010153c <strncmp+0x41>
f010152e:	3a 03                	cmp    (%ebx),%al
f0101530:	74 ea                	je     f010151c <strncmp+0x21>
f0101532:	eb 08                	jmp    f010153c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101534:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101539:	5b                   	pop    %ebx
f010153a:	5d                   	pop    %ebp
f010153b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010153c:	0f b6 01             	movzbl (%ecx),%eax
f010153f:	0f b6 13             	movzbl (%ebx),%edx
f0101542:	29 d0                	sub    %edx,%eax
f0101544:	eb f3                	jmp    f0101539 <strncmp+0x3e>

f0101546 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101546:	55                   	push   %ebp
f0101547:	89 e5                	mov    %esp,%ebp
f0101549:	8b 45 08             	mov    0x8(%ebp),%eax
f010154c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101550:	0f b6 10             	movzbl (%eax),%edx
f0101553:	84 d2                	test   %dl,%dl
f0101555:	74 1c                	je     f0101573 <strchr+0x2d>
		if (*s == c)
f0101557:	38 ca                	cmp    %cl,%dl
f0101559:	75 09                	jne    f0101564 <strchr+0x1e>
f010155b:	eb 1b                	jmp    f0101578 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010155d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101560:	38 ca                	cmp    %cl,%dl
f0101562:	74 14                	je     f0101578 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101564:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101568:	84 d2                	test   %dl,%dl
f010156a:	75 f1                	jne    f010155d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010156c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101571:	eb 05                	jmp    f0101578 <strchr+0x32>
f0101573:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101578:	5d                   	pop    %ebp
f0101579:	c3                   	ret    

f010157a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010157a:	55                   	push   %ebp
f010157b:	89 e5                	mov    %esp,%ebp
f010157d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101580:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101584:	0f b6 10             	movzbl (%eax),%edx
f0101587:	84 d2                	test   %dl,%dl
f0101589:	74 14                	je     f010159f <strfind+0x25>
		if (*s == c)
f010158b:	38 ca                	cmp    %cl,%dl
f010158d:	75 06                	jne    f0101595 <strfind+0x1b>
f010158f:	eb 0e                	jmp    f010159f <strfind+0x25>
f0101591:	38 ca                	cmp    %cl,%dl
f0101593:	74 0a                	je     f010159f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101595:	83 c0 01             	add    $0x1,%eax
f0101598:	0f b6 10             	movzbl (%eax),%edx
f010159b:	84 d2                	test   %dl,%dl
f010159d:	75 f2                	jne    f0101591 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010159f:	5d                   	pop    %ebp
f01015a0:	c3                   	ret    

f01015a1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	83 ec 0c             	sub    $0xc,%esp
f01015a7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01015aa:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01015ad:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01015b0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015b9:	85 c9                	test   %ecx,%ecx
f01015bb:	74 30                	je     f01015ed <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015bd:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015c3:	75 25                	jne    f01015ea <memset+0x49>
f01015c5:	f6 c1 03             	test   $0x3,%cl
f01015c8:	75 20                	jne    f01015ea <memset+0x49>
		c &= 0xFF;
f01015ca:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015cd:	89 d3                	mov    %edx,%ebx
f01015cf:	c1 e3 08             	shl    $0x8,%ebx
f01015d2:	89 d6                	mov    %edx,%esi
f01015d4:	c1 e6 18             	shl    $0x18,%esi
f01015d7:	89 d0                	mov    %edx,%eax
f01015d9:	c1 e0 10             	shl    $0x10,%eax
f01015dc:	09 f0                	or     %esi,%eax
f01015de:	09 d0                	or     %edx,%eax
f01015e0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015e2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015e5:	fc                   	cld    
f01015e6:	f3 ab                	rep stos %eax,%es:(%edi)
f01015e8:	eb 03                	jmp    f01015ed <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015ea:	fc                   	cld    
f01015eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015ed:	89 f8                	mov    %edi,%eax
f01015ef:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01015f2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015f5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015f8:	89 ec                	mov    %ebp,%esp
f01015fa:	5d                   	pop    %ebp
f01015fb:	c3                   	ret    

f01015fc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015fc:	55                   	push   %ebp
f01015fd:	89 e5                	mov    %esp,%ebp
f01015ff:	83 ec 08             	sub    $0x8,%esp
f0101602:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101605:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101608:	8b 45 08             	mov    0x8(%ebp),%eax
f010160b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010160e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101611:	39 c6                	cmp    %eax,%esi
f0101613:	73 36                	jae    f010164b <memmove+0x4f>
f0101615:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101618:	39 d0                	cmp    %edx,%eax
f010161a:	73 2f                	jae    f010164b <memmove+0x4f>
		s += n;
		d += n;
f010161c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010161f:	f6 c2 03             	test   $0x3,%dl
f0101622:	75 1b                	jne    f010163f <memmove+0x43>
f0101624:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010162a:	75 13                	jne    f010163f <memmove+0x43>
f010162c:	f6 c1 03             	test   $0x3,%cl
f010162f:	75 0e                	jne    f010163f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101631:	83 ef 04             	sub    $0x4,%edi
f0101634:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101637:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010163a:	fd                   	std    
f010163b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010163d:	eb 09                	jmp    f0101648 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010163f:	83 ef 01             	sub    $0x1,%edi
f0101642:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101645:	fd                   	std    
f0101646:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101648:	fc                   	cld    
f0101649:	eb 20                	jmp    f010166b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010164b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101651:	75 13                	jne    f0101666 <memmove+0x6a>
f0101653:	a8 03                	test   $0x3,%al
f0101655:	75 0f                	jne    f0101666 <memmove+0x6a>
f0101657:	f6 c1 03             	test   $0x3,%cl
f010165a:	75 0a                	jne    f0101666 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010165c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010165f:	89 c7                	mov    %eax,%edi
f0101661:	fc                   	cld    
f0101662:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101664:	eb 05                	jmp    f010166b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101666:	89 c7                	mov    %eax,%edi
f0101668:	fc                   	cld    
f0101669:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010166b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010166e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101671:	89 ec                	mov    %ebp,%esp
f0101673:	5d                   	pop    %ebp
f0101674:	c3                   	ret    

f0101675 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101675:	55                   	push   %ebp
f0101676:	89 e5                	mov    %esp,%ebp
f0101678:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010167b:	8b 45 10             	mov    0x10(%ebp),%eax
f010167e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101682:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101685:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101689:	8b 45 08             	mov    0x8(%ebp),%eax
f010168c:	89 04 24             	mov    %eax,(%esp)
f010168f:	e8 68 ff ff ff       	call   f01015fc <memmove>
}
f0101694:	c9                   	leave  
f0101695:	c3                   	ret    

f0101696 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101696:	55                   	push   %ebp
f0101697:	89 e5                	mov    %esp,%ebp
f0101699:	57                   	push   %edi
f010169a:	56                   	push   %esi
f010169b:	53                   	push   %ebx
f010169c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010169f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016a2:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016a5:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016aa:	85 ff                	test   %edi,%edi
f01016ac:	74 37                	je     f01016e5 <memcmp+0x4f>
		if (*s1 != *s2)
f01016ae:	0f b6 03             	movzbl (%ebx),%eax
f01016b1:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016b4:	83 ef 01             	sub    $0x1,%edi
f01016b7:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01016bc:	38 c8                	cmp    %cl,%al
f01016be:	74 1c                	je     f01016dc <memcmp+0x46>
f01016c0:	eb 10                	jmp    f01016d2 <memcmp+0x3c>
f01016c2:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016c7:	83 c2 01             	add    $0x1,%edx
f01016ca:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016ce:	38 c8                	cmp    %cl,%al
f01016d0:	74 0a                	je     f01016dc <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01016d2:	0f b6 c0             	movzbl %al,%eax
f01016d5:	0f b6 c9             	movzbl %cl,%ecx
f01016d8:	29 c8                	sub    %ecx,%eax
f01016da:	eb 09                	jmp    f01016e5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016dc:	39 fa                	cmp    %edi,%edx
f01016de:	75 e2                	jne    f01016c2 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016e5:	5b                   	pop    %ebx
f01016e6:	5e                   	pop    %esi
f01016e7:	5f                   	pop    %edi
f01016e8:	5d                   	pop    %ebp
f01016e9:	c3                   	ret    

f01016ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016ea:	55                   	push   %ebp
f01016eb:	89 e5                	mov    %esp,%ebp
f01016ed:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01016f0:	89 c2                	mov    %eax,%edx
f01016f2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016f5:	39 d0                	cmp    %edx,%eax
f01016f7:	73 19                	jae    f0101712 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016f9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01016fd:	38 08                	cmp    %cl,(%eax)
f01016ff:	75 06                	jne    f0101707 <memfind+0x1d>
f0101701:	eb 0f                	jmp    f0101712 <memfind+0x28>
f0101703:	38 08                	cmp    %cl,(%eax)
f0101705:	74 0b                	je     f0101712 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101707:	83 c0 01             	add    $0x1,%eax
f010170a:	39 d0                	cmp    %edx,%eax
f010170c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101710:	75 f1                	jne    f0101703 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101712:	5d                   	pop    %ebp
f0101713:	c3                   	ret    

f0101714 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101714:	55                   	push   %ebp
f0101715:	89 e5                	mov    %esp,%ebp
f0101717:	57                   	push   %edi
f0101718:	56                   	push   %esi
f0101719:	53                   	push   %ebx
f010171a:	8b 55 08             	mov    0x8(%ebp),%edx
f010171d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101720:	0f b6 02             	movzbl (%edx),%eax
f0101723:	3c 20                	cmp    $0x20,%al
f0101725:	74 04                	je     f010172b <strtol+0x17>
f0101727:	3c 09                	cmp    $0x9,%al
f0101729:	75 0e                	jne    f0101739 <strtol+0x25>
		s++;
f010172b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010172e:	0f b6 02             	movzbl (%edx),%eax
f0101731:	3c 20                	cmp    $0x20,%al
f0101733:	74 f6                	je     f010172b <strtol+0x17>
f0101735:	3c 09                	cmp    $0x9,%al
f0101737:	74 f2                	je     f010172b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101739:	3c 2b                	cmp    $0x2b,%al
f010173b:	75 0a                	jne    f0101747 <strtol+0x33>
		s++;
f010173d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101740:	bf 00 00 00 00       	mov    $0x0,%edi
f0101745:	eb 10                	jmp    f0101757 <strtol+0x43>
f0101747:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010174c:	3c 2d                	cmp    $0x2d,%al
f010174e:	75 07                	jne    f0101757 <strtol+0x43>
		s++, neg = 1;
f0101750:	83 c2 01             	add    $0x1,%edx
f0101753:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101757:	85 db                	test   %ebx,%ebx
f0101759:	0f 94 c0             	sete   %al
f010175c:	74 05                	je     f0101763 <strtol+0x4f>
f010175e:	83 fb 10             	cmp    $0x10,%ebx
f0101761:	75 15                	jne    f0101778 <strtol+0x64>
f0101763:	80 3a 30             	cmpb   $0x30,(%edx)
f0101766:	75 10                	jne    f0101778 <strtol+0x64>
f0101768:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010176c:	75 0a                	jne    f0101778 <strtol+0x64>
		s += 2, base = 16;
f010176e:	83 c2 02             	add    $0x2,%edx
f0101771:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101776:	eb 13                	jmp    f010178b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101778:	84 c0                	test   %al,%al
f010177a:	74 0f                	je     f010178b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010177c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101781:	80 3a 30             	cmpb   $0x30,(%edx)
f0101784:	75 05                	jne    f010178b <strtol+0x77>
		s++, base = 8;
f0101786:	83 c2 01             	add    $0x1,%edx
f0101789:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010178b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101790:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101792:	0f b6 0a             	movzbl (%edx),%ecx
f0101795:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101798:	80 fb 09             	cmp    $0x9,%bl
f010179b:	77 08                	ja     f01017a5 <strtol+0x91>
			dig = *s - '0';
f010179d:	0f be c9             	movsbl %cl,%ecx
f01017a0:	83 e9 30             	sub    $0x30,%ecx
f01017a3:	eb 1e                	jmp    f01017c3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01017a5:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01017a8:	80 fb 19             	cmp    $0x19,%bl
f01017ab:	77 08                	ja     f01017b5 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01017ad:	0f be c9             	movsbl %cl,%ecx
f01017b0:	83 e9 57             	sub    $0x57,%ecx
f01017b3:	eb 0e                	jmp    f01017c3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01017b5:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01017b8:	80 fb 19             	cmp    $0x19,%bl
f01017bb:	77 14                	ja     f01017d1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01017bd:	0f be c9             	movsbl %cl,%ecx
f01017c0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017c3:	39 f1                	cmp    %esi,%ecx
f01017c5:	7d 0e                	jge    f01017d5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01017c7:	83 c2 01             	add    $0x1,%edx
f01017ca:	0f af c6             	imul   %esi,%eax
f01017cd:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01017cf:	eb c1                	jmp    f0101792 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01017d1:	89 c1                	mov    %eax,%ecx
f01017d3:	eb 02                	jmp    f01017d7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01017d5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01017d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017db:	74 05                	je     f01017e2 <strtol+0xce>
		*endptr = (char *) s;
f01017dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017e0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01017e2:	89 ca                	mov    %ecx,%edx
f01017e4:	f7 da                	neg    %edx
f01017e6:	85 ff                	test   %edi,%edi
f01017e8:	0f 45 c2             	cmovne %edx,%eax
}
f01017eb:	5b                   	pop    %ebx
f01017ec:	5e                   	pop    %esi
f01017ed:	5f                   	pop    %edi
f01017ee:	5d                   	pop    %ebp
f01017ef:	c3                   	ret    

f01017f0 <__udivdi3>:
f01017f0:	83 ec 1c             	sub    $0x1c,%esp
f01017f3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01017f7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01017fb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01017ff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101803:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101807:	8b 74 24 24          	mov    0x24(%esp),%esi
f010180b:	85 ff                	test   %edi,%edi
f010180d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101811:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101815:	89 cd                	mov    %ecx,%ebp
f0101817:	89 44 24 04          	mov    %eax,0x4(%esp)
f010181b:	75 33                	jne    f0101850 <__udivdi3+0x60>
f010181d:	39 f1                	cmp    %esi,%ecx
f010181f:	77 57                	ja     f0101878 <__udivdi3+0x88>
f0101821:	85 c9                	test   %ecx,%ecx
f0101823:	75 0b                	jne    f0101830 <__udivdi3+0x40>
f0101825:	b8 01 00 00 00       	mov    $0x1,%eax
f010182a:	31 d2                	xor    %edx,%edx
f010182c:	f7 f1                	div    %ecx
f010182e:	89 c1                	mov    %eax,%ecx
f0101830:	89 f0                	mov    %esi,%eax
f0101832:	31 d2                	xor    %edx,%edx
f0101834:	f7 f1                	div    %ecx
f0101836:	89 c6                	mov    %eax,%esi
f0101838:	8b 44 24 04          	mov    0x4(%esp),%eax
f010183c:	f7 f1                	div    %ecx
f010183e:	89 f2                	mov    %esi,%edx
f0101840:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101844:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101848:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010184c:	83 c4 1c             	add    $0x1c,%esp
f010184f:	c3                   	ret    
f0101850:	31 d2                	xor    %edx,%edx
f0101852:	31 c0                	xor    %eax,%eax
f0101854:	39 f7                	cmp    %esi,%edi
f0101856:	77 e8                	ja     f0101840 <__udivdi3+0x50>
f0101858:	0f bd cf             	bsr    %edi,%ecx
f010185b:	83 f1 1f             	xor    $0x1f,%ecx
f010185e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101862:	75 2c                	jne    f0101890 <__udivdi3+0xa0>
f0101864:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101868:	76 04                	jbe    f010186e <__udivdi3+0x7e>
f010186a:	39 f7                	cmp    %esi,%edi
f010186c:	73 d2                	jae    f0101840 <__udivdi3+0x50>
f010186e:	31 d2                	xor    %edx,%edx
f0101870:	b8 01 00 00 00       	mov    $0x1,%eax
f0101875:	eb c9                	jmp    f0101840 <__udivdi3+0x50>
f0101877:	90                   	nop
f0101878:	89 f2                	mov    %esi,%edx
f010187a:	f7 f1                	div    %ecx
f010187c:	31 d2                	xor    %edx,%edx
f010187e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101882:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101886:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010188a:	83 c4 1c             	add    $0x1c,%esp
f010188d:	c3                   	ret    
f010188e:	66 90                	xchg   %ax,%ax
f0101890:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101895:	b8 20 00 00 00       	mov    $0x20,%eax
f010189a:	89 ea                	mov    %ebp,%edx
f010189c:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018a0:	d3 e7                	shl    %cl,%edi
f01018a2:	89 c1                	mov    %eax,%ecx
f01018a4:	d3 ea                	shr    %cl,%edx
f01018a6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018ab:	09 fa                	or     %edi,%edx
f01018ad:	89 f7                	mov    %esi,%edi
f01018af:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01018b3:	89 f2                	mov    %esi,%edx
f01018b5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01018b9:	d3 e5                	shl    %cl,%ebp
f01018bb:	89 c1                	mov    %eax,%ecx
f01018bd:	d3 ef                	shr    %cl,%edi
f01018bf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018c4:	d3 e2                	shl    %cl,%edx
f01018c6:	89 c1                	mov    %eax,%ecx
f01018c8:	d3 ee                	shr    %cl,%esi
f01018ca:	09 d6                	or     %edx,%esi
f01018cc:	89 fa                	mov    %edi,%edx
f01018ce:	89 f0                	mov    %esi,%eax
f01018d0:	f7 74 24 0c          	divl   0xc(%esp)
f01018d4:	89 d7                	mov    %edx,%edi
f01018d6:	89 c6                	mov    %eax,%esi
f01018d8:	f7 e5                	mul    %ebp
f01018da:	39 d7                	cmp    %edx,%edi
f01018dc:	72 22                	jb     f0101900 <__udivdi3+0x110>
f01018de:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01018e2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018e7:	d3 e5                	shl    %cl,%ebp
f01018e9:	39 c5                	cmp    %eax,%ebp
f01018eb:	73 04                	jae    f01018f1 <__udivdi3+0x101>
f01018ed:	39 d7                	cmp    %edx,%edi
f01018ef:	74 0f                	je     f0101900 <__udivdi3+0x110>
f01018f1:	89 f0                	mov    %esi,%eax
f01018f3:	31 d2                	xor    %edx,%edx
f01018f5:	e9 46 ff ff ff       	jmp    f0101840 <__udivdi3+0x50>
f01018fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101900:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101903:	31 d2                	xor    %edx,%edx
f0101905:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101909:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010190d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101911:	83 c4 1c             	add    $0x1c,%esp
f0101914:	c3                   	ret    
	...

f0101920 <__umoddi3>:
f0101920:	83 ec 1c             	sub    $0x1c,%esp
f0101923:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101927:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010192b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010192f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101933:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101937:	8b 74 24 24          	mov    0x24(%esp),%esi
f010193b:	85 ed                	test   %ebp,%ebp
f010193d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101941:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101945:	89 cf                	mov    %ecx,%edi
f0101947:	89 04 24             	mov    %eax,(%esp)
f010194a:	89 f2                	mov    %esi,%edx
f010194c:	75 1a                	jne    f0101968 <__umoddi3+0x48>
f010194e:	39 f1                	cmp    %esi,%ecx
f0101950:	76 4e                	jbe    f01019a0 <__umoddi3+0x80>
f0101952:	f7 f1                	div    %ecx
f0101954:	89 d0                	mov    %edx,%eax
f0101956:	31 d2                	xor    %edx,%edx
f0101958:	8b 74 24 10          	mov    0x10(%esp),%esi
f010195c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101960:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101964:	83 c4 1c             	add    $0x1c,%esp
f0101967:	c3                   	ret    
f0101968:	39 f5                	cmp    %esi,%ebp
f010196a:	77 54                	ja     f01019c0 <__umoddi3+0xa0>
f010196c:	0f bd c5             	bsr    %ebp,%eax
f010196f:	83 f0 1f             	xor    $0x1f,%eax
f0101972:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101976:	75 60                	jne    f01019d8 <__umoddi3+0xb8>
f0101978:	3b 0c 24             	cmp    (%esp),%ecx
f010197b:	0f 87 07 01 00 00    	ja     f0101a88 <__umoddi3+0x168>
f0101981:	89 f2                	mov    %esi,%edx
f0101983:	8b 34 24             	mov    (%esp),%esi
f0101986:	29 ce                	sub    %ecx,%esi
f0101988:	19 ea                	sbb    %ebp,%edx
f010198a:	89 34 24             	mov    %esi,(%esp)
f010198d:	8b 04 24             	mov    (%esp),%eax
f0101990:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101994:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101998:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010199c:	83 c4 1c             	add    $0x1c,%esp
f010199f:	c3                   	ret    
f01019a0:	85 c9                	test   %ecx,%ecx
f01019a2:	75 0b                	jne    f01019af <__umoddi3+0x8f>
f01019a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01019a9:	31 d2                	xor    %edx,%edx
f01019ab:	f7 f1                	div    %ecx
f01019ad:	89 c1                	mov    %eax,%ecx
f01019af:	89 f0                	mov    %esi,%eax
f01019b1:	31 d2                	xor    %edx,%edx
f01019b3:	f7 f1                	div    %ecx
f01019b5:	8b 04 24             	mov    (%esp),%eax
f01019b8:	f7 f1                	div    %ecx
f01019ba:	eb 98                	jmp    f0101954 <__umoddi3+0x34>
f01019bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c0:	89 f2                	mov    %esi,%edx
f01019c2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019c6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019ca:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019ce:	83 c4 1c             	add    $0x1c,%esp
f01019d1:	c3                   	ret    
f01019d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019d8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019dd:	89 e8                	mov    %ebp,%eax
f01019df:	bd 20 00 00 00       	mov    $0x20,%ebp
f01019e4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f01019e8:	89 fa                	mov    %edi,%edx
f01019ea:	d3 e0                	shl    %cl,%eax
f01019ec:	89 e9                	mov    %ebp,%ecx
f01019ee:	d3 ea                	shr    %cl,%edx
f01019f0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019f5:	09 c2                	or     %eax,%edx
f01019f7:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019fb:	89 14 24             	mov    %edx,(%esp)
f01019fe:	89 f2                	mov    %esi,%edx
f0101a00:	d3 e7                	shl    %cl,%edi
f0101a02:	89 e9                	mov    %ebp,%ecx
f0101a04:	d3 ea                	shr    %cl,%edx
f0101a06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a0f:	d3 e6                	shl    %cl,%esi
f0101a11:	89 e9                	mov    %ebp,%ecx
f0101a13:	d3 e8                	shr    %cl,%eax
f0101a15:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a1a:	09 f0                	or     %esi,%eax
f0101a1c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101a20:	f7 34 24             	divl   (%esp)
f0101a23:	d3 e6                	shl    %cl,%esi
f0101a25:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101a29:	89 d6                	mov    %edx,%esi
f0101a2b:	f7 e7                	mul    %edi
f0101a2d:	39 d6                	cmp    %edx,%esi
f0101a2f:	89 c1                	mov    %eax,%ecx
f0101a31:	89 d7                	mov    %edx,%edi
f0101a33:	72 3f                	jb     f0101a74 <__umoddi3+0x154>
f0101a35:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101a39:	72 35                	jb     f0101a70 <__umoddi3+0x150>
f0101a3b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a3f:	29 c8                	sub    %ecx,%eax
f0101a41:	19 fe                	sbb    %edi,%esi
f0101a43:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a48:	89 f2                	mov    %esi,%edx
f0101a4a:	d3 e8                	shr    %cl,%eax
f0101a4c:	89 e9                	mov    %ebp,%ecx
f0101a4e:	d3 e2                	shl    %cl,%edx
f0101a50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a55:	09 d0                	or     %edx,%eax
f0101a57:	89 f2                	mov    %esi,%edx
f0101a59:	d3 ea                	shr    %cl,%edx
f0101a5b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a5f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a63:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a67:	83 c4 1c             	add    $0x1c,%esp
f0101a6a:	c3                   	ret    
f0101a6b:	90                   	nop
f0101a6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a70:	39 d6                	cmp    %edx,%esi
f0101a72:	75 c7                	jne    f0101a3b <__umoddi3+0x11b>
f0101a74:	89 d7                	mov    %edx,%edi
f0101a76:	89 c1                	mov    %eax,%ecx
f0101a78:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101a7c:	1b 3c 24             	sbb    (%esp),%edi
f0101a7f:	eb ba                	jmp    f0101a3b <__umoddi3+0x11b>
f0101a81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a88:	39 f5                	cmp    %esi,%ebp
f0101a8a:	0f 82 f1 fe ff ff    	jb     f0101981 <__umoddi3+0x61>
f0101a90:	e9 f8 fe ff ff       	jmp    f010198d <__umoddi3+0x6d>
