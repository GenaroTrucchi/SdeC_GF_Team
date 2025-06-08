# Nombre del objeto que se convertirá en nuestro módulo .ko
obj-m += modulo_signals.o

# Target 'all' es el default. Invoca al make del kernel.
all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

# Target 'clean' para limpiar los archivos generados durante la compilación.
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
