KDIR=/lib/modules/$(shell uname -r)/build

obj-m += calc.o
obj-m += livepatch-calc.o
calc-objs += main.o expression.o
livepatch-calc-objs += live-calc.o expression.o
ccflags-y := -std=gnu11 -Wno-declaration-after-statement \
	-Wall -W -Werror -Wno-unused-variable -Wno-unused-parameter

GIT_HOOKS := .git/hooks/applied

all: $(GIT_HOOKS)
	make -C $(KDIR) M=$(PWD) modules

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

check: all
	scripts/test.sh

clean:
	make -C $(KDIR) M=$(PWD) clean
