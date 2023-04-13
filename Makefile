OBJDIR := build

CROSS_COMPILE := ~/opt/cross/bin/i686-elf-

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
NM := $(CROSS_COMPILE)nm
AR := $(CROSS_COMPILE)ar

CFLAGS += -g -std=gnu99 -O2 -Wall -Wextra -fno-stack-protector -mno-red-zone -ffreestanding -fno-asynchronous-unwind-tables
KERNEL_CFLAGS    := $(CFLAGS) -fno-pie -Ikernel/include/ -Ilibk/include/
USER_LIBC_CFLAGS := $(CFLAGS) -fno-pie -Ikernel/include/ -Ilibc/include/

LDFLAGS := -nostdlib -Wl,-no-pie
LIBS := -lgcc

KERNEL_SRCS = \
			kernel/boot.s \
			kernel/kernel.c \
			kernel/allocator.c \
			kernel/elf.c \
			kernel/event.c \
			kernel/framebuffer.c \
			kernel/gdt.c \
			kernel/ide.c \
			kernel/idt.c \
			kernel/io.c \
			kernel/isr.c \
			kernel/paging.c \
			kernel/process.c \
			kernel/pic.c \
			kernel/pit.c \
			kernel/ps2.c \
			kernel/queue.c \
			kernel/ramdisk.c \
			kernel/serial.c \
			kernel/syscall.c \
			kernel/timer.c \
			kernel/vfs.c \
			\
			kernel/fatfs/diskio.c \
			kernel/fatfs/ff.c \
			kernel/fatfs/ffsystem.c \
			kernel/fatfs/ffunicode.c \
			\
			kernel/syscall/sys_exit.c \
			kernel/syscall/sys_yield.c \
			kernel/syscall/sys_sleep.c \
			kernel/syscall/sys_new_process.c \
			kernel/syscall/sys_open.c \
			kernel/syscall/sys_close.c \
			kernel/syscall/sys_read.c \
			kernel/syscall/sys_write.c \
			kernel/syscall/sys_cwd.c \
			kernel/syscall/sys_chdir.c \
			kernel/syscall/sys_new_event.c \
			kernel/syscall/sys_get_next_event.c \
			\
			libk/stdio/kprintf.c \
			libk/stdio/printf.c \
			libk/stdio/putchar.c \
			libk/stdio/puts.c \
			libk/stdio/vprintf.c \
			\
			libk/stdlib/abort.c \
			libk/stdlib/itoa.c \
			libk/stdlib/utoa.c \
			\
			libk/string/memcmp.c \
			libk/string/memcpy.c \
			libk/string/memmove.c \
			libk/string/memset.c \
			libk/string/strlen.c \
			libk/string/strchr.c \
			libk/string/strcpy.c \
			libk/string/strcat.c \
			libk/string/strcmp.c

USER_LIBC_SRCS = \
			libc/stdio/printf.c \
			libc/stdio/putchar.c \
			libc/stdio/puts.c \
			libc/stdio/vprintf.c \
			libc/stdio/getchar.c \
			libc/stdio/gets.c \
			\
			libc/stdlib/itoa.c \
			libc/stdlib/utoa.c \
			\
			libc/string/memcmp.c \
			libc/string/memcpy.c \
			libc/string/memmove.c \
			libc/string/memset.c \
			libc/string/strlen.c \
			libc/string/strchr.c \
			libc/string/strcpy.c \
			libc/string/strcat.c \
			libc/string/strcmp.c \
			\
			libc/fox/string.c

USER_LIBU_SRCS = \
				user/crt0.s \
				user/framebuffer.c \
				user/keyboard.c \
				user/user.s

KERNEL_OBJS = $(addprefix $(OBJDIR)/,$(addsuffix .o, $(basename $(KERNEL_SRCS))))
USER_LIBC_OBJS = $(addprefix $(OBJDIR)/,$(addsuffix .o, $(basename $(USER_LIBC_SRCS))))
USER_LIBU_OBJS = $(addprefix $(OBJDIR)/,$(addsuffix .o, $(basename $(USER_LIBU_SRCS))))


all: kernel libc libu userapps
	$(MAKE) image
	
clean:
	rm -rf build/
	rm -f base_image/boot/fennecos.elf
	rm -f base_image/boot/fennecos.sym
	rm -f boot.img

libu: build/user/libu.a
libc: build/user/libc.a
kernel: base_image/boot/fennecos.elf

userapps:
	@mkdir -p base_image/bin/
	@mkdir -p build/user/applications/console/
	@$(CC) -c user/applications/console/main.c -o build/user/applications/console/main.o $(USER_LIBC_CFLAGS)
	@$(CC) -o base_image/bin/console.elf $(LDFLAGS) build/user/applications/console/main.o build/user/libc.a build/user/libu.a $(LIBS)
	@mkdir -p build/user/applications/demo
	@$(CC) -c user/applications/demo/main.c -o build/user/applications/demo/main.o $(USER_LIBC_CFLAGS)
	@$(CC) -o base_image/bin/demo.elf $(LDFLAGS) build/user/applications/demo/main.o build/user/libc.a build/user/libu.a $(LIBS)
	@mkdir -p build/user/applications/sh
	@$(CC) -c user/applications/sh/main.c -o build/user/applications/sh/main.o $(USER_LIBC_CFLAGS)
	@$(CC) -c user/applications/sh/commands/ls.c -o build/user/applications/sh/ls.o $(USER_LIBC_CFLAGS)
	@$(CC) -o base_image/bin/sh.elf $(LDFLAGS) build/user/applications/sh/main.o build/user/applications/sh/ls.o build/user/libc.a build/user/libu.a $(LIBS)

image:
	sudo ./image.sh

define buildrule # buildrule(outfile, infile, print, cflags)
$(1): $(2)
	@mkdir -p $$(@D) # i don't like this
	@echo "    $(3) $$<"
	@$(CC) -c $$< -o $$@ $(4)
endef

build/user/libu.a: $(USER_LIBU_OBJS)
	@mkdir -p $(@D) # i don't like this
	@echo "    AR $@"
	@$(AR) rcs $@ $^

$(eval $(call buildrule,$(OBJDIR)/user/%.o,user/%.s,AS,$(USER_LIBC_CFLAGS)))
$(eval $(call buildrule,$(OBJDIR)/user/%.o,user/%.c,CC,$(USER_LIBC_CFLAGS)))

build/user/libc.a: $(USER_LIBC_OBJS)
	@mkdir -p $(@D) # i don't like this
	@echo "    AR $@"
	@$(AR) rcs $@ $^

$(eval $(call buildrule,$(OBJDIR)/libc/%.o,libc/%.s,AS,$(USER_LIBC_CFLAGS)))
$(eval $(call buildrule,$(OBJDIR)/libc/%.o,libc/%.c,CC,$(USER_LIBC_CFLAGS)))

base_image/boot/fennecos.elf: $(KERNEL_OBJS)
	@echo "    LD $@"
	@$(CC) -T kernel/linker.ld -o $@ $(LDFLAGS) $^ $(LIBS)
	@echo "    NM $@"
	@$(NM) $@ -p | grep ' T \| t ' | awk '{ print $1" "$3 }' > base_image/boot/fennecos.sym

$(eval $(call buildrule,$(OBJDIR)/kernel/%.o,kernel/%.s,AS,$(KERNEL_CFLAGS)))
$(eval $(call buildrule,$(OBJDIR)/kernel/%.o,kernel/%.c,CC,$(KERNEL_CFLAGS)))
$(eval $(call buildrule,$(OBJDIR)/libk/%.o,libk/%.c,CC,$(KERNEL_CFLAGS)))
