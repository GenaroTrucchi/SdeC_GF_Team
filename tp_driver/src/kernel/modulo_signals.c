#include <linux/device.h>  // Para class_create y device_create
#include <linux/fs.h>      // Estructura file_operations
#include <linux/init.h>    // Macros __init y __exit
#include <linux/jiffies.h> // Para el valor de HZ y jiffies
#include <linux/kernel.h>  // Contiene KERN_INFO, etc.
#include <linux/module.h>  // Necesario para todos los módulos
#include <linux/timer.h>   // Para los timers del kernel
#include <linux/uaccess.h> // Para copy_to_user y copy_from_user

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tu Nombre");
MODULE_DESCRIPTION("Driver de Caracteres para sensar dos senales periodicas.");

#define DEVICE_NAME "mis_senales"
#define CLASS_NAME "señales_class"

// --- Variables Globales ---

static int major_number;
static struct class *mi_class = NULL;
static struct device *mi_device = NULL;

static struct timer_list mi_timer;

// Usamos 'volatile' porque estas variables son modificadas por el timer
// (contexto de interrupción) y leídas por las funciones de file_operations
// (contexto de proceso).
static volatile int valor_signal_0 = 0;
static volatile int valor_signal_1 = 50;
static volatile int dir_signal_1 = 1; // Dirección para la señal triangular

// Indica cuál señal está seleccionada por el usuario (0 o 1).
static volatile int senal_seleccionada = 0;

// --- Prototipos de Funciones ---

static int dev_open(struct inode *, struct file *);
static int dev_release(struct inode *, struct file *);
static ssize_t dev_read(struct file *, char *, size_t, loff_t *);
static ssize_t dev_write(struct file *, const char *, size_t, loff_t *);
void timer_callback(struct timer_list *t);

// --- Estructura File Operations ---
// Asocia las llamadas al sistema (open, read, write) con nuestras funciones.
static struct file_operations fops = {
    .open = dev_open,
    .read = dev_read,
    .write = dev_write,
    .release = dev_release,
};

// --- Implementación de Funciones ---

/**
 * @brief Esta función se ejecuta cada vez que el timer expira (cada segundo).
 */
void timer_callback(struct timer_list *t) {
  // 1. Simular/Actualizar los valores de las señales
  // Señal 0: Un simple contador que va de 0 a 99 y reinicia.
  valor_signal_0 = (valor_signal_0 + 2) % 100;

  // Señal 1: Una onda triangular que va de 0 a 100 y viceversa.
  if (valor_signal_1 >= 100)
    dir_signal_1 = -1;
  if (valor_signal_1 <= 0)
    dir_signal_1 = 1;
  valor_signal_1 += dir_signal_1 * 5;

  // printk(KERN_INFO "Timer tick: S0=%d, S1=%d\n", valor_signal_0,
  // valor_signal_1);

  // 2. Volver a armar el timer para que se dispare en 1 segundo (HZ jiffies).
  mod_timer(&mi_timer, jiffies + HZ);
}

/**
 * @brief Se llama cuando una aplicación abre el archivo de dispositivo.
 */
static int dev_open(struct inode *inodep, struct file *filep) {
  printk(KERN_INFO "Dispositivo de señales abierto.\n");
  return 0;
}

/**
 * @brief Se llama cuando una aplicación cierra el archivo de dispositivo.
 */
static int dev_release(struct inode *inodep, struct file *filep) {
  printk(KERN_INFO "Dispositivo de señales cerrado.\n");
  return 0;
}

/**
 * @brief Se llama cuando la aplicación intenta escribir en el archivo de
 * dispositivo. La usaremos para seleccionar la señal.
 */
static ssize_t dev_write(struct file *filep, const char *buffer, size_t len,
                         loff_t *offset) {
  char user_char;

  if (len == 0) {
    return 0; // No se escribió nada.
  }

  // Copiamos un solo caracter desde el espacio de usuario.
  if (copy_from_user(&user_char, buffer, 1)) {
    return -EFAULT; // Error al copiar.
  }

  if (user_char == '0') {
    senal_seleccionada = 0;
    printk(KERN_INFO "Señal 0 seleccionada.\n");
  } else if (user_char == '1') {
    senal_seleccionada = 1;
    printk(KERN_INFO "Señal 1 seleccionada.\n");
  } else {
    printk(KERN_WARNING "Entrada inválida. Usar '0' o '1'.\n");
  }

  // Devolvemos la cantidad de bytes escritos.
  return len;
}

/**
 * @brief Se llama cuando la aplicación intenta leer del archivo de dispositivo.
 *        Entregaremos el valor de la señal seleccionada.
 */
static ssize_t dev_read(struct file *filep, char *buffer, size_t len,
                        loff_t *offset) {
  char msg_buffer[32];
  int msg_len;
  int valor_a_enviar;

  // Esto evita que la aplicación lea el mismo valor una y otra vez en un solo
  // 'read'. Si el offset es > 0, significa que ya hemos enviado los datos.
  if (*offset > 0) {
    return 0; // Fin de archivo (EOF).
  }

  // Seleccionamos el valor a enviar basado en la variable global.
  if (senal_seleccionada == 0) {
    valor_a_enviar = valor_signal_0;
  } else {
    valor_a_enviar = valor_signal_1;
  }

  // Convertimos el valor entero a una cadena de texto.
  msg_len = snprintf(msg_buffer, sizeof(msg_buffer), "%d\n", valor_a_enviar);

  // Copiamos la cadena al buffer del usuario.
  if (copy_to_user(buffer, msg_buffer, msg_len)) {
    return -EFAULT; // Error al copiar.
  }

  // Actualizamos el offset para indicar cuántos bytes se leyeron.
  *offset = msg_len;

  // Devolvemos el número de bytes leídos.
  return msg_len;
}

// --- Función de Inicialización del Módulo ---

static int __init modulo_init(void) {
  printk(KERN_INFO "Iniciando el módulo de señales...\n");

  // 1. Registrar el driver de caracteres y obtener un número 'major'.
  major_number = register_chrdev(0, DEVICE_NAME, &fops);
  if (major_number < 0) {
    printk(KERN_ALERT "Fallo al registrar un número major\n");
    return major_number;
  }
  printk(KERN_INFO "Registrado con número major %d\n", major_number);

  // 2. Crear una clase de dispositivo.
  mi_class = class_create(CLASS_NAME);
  if (IS_ERR(mi_class)) {
    unregister_chrdev(major_number, DEVICE_NAME);
    printk(KERN_ALERT "Fallo al crear la clase de dispositivo\n");
    return PTR_ERR(mi_class);
  }
  printk(KERN_INFO "Clase de dispositivo creada correctamente.\n");

  // 3. Crear el archivo de dispositivo en /dev/.
  mi_device =
      device_create(mi_class, NULL, MKDEV(major_number, 0), NULL, DEVICE_NAME);
  if (IS_ERR(mi_device)) {
    class_destroy(mi_class);
    unregister_chrdev(major_number, DEVICE_NAME);
    printk(KERN_ALERT "Fallo al crear el dispositivo /dev/%s\n", DEVICE_NAME);
    return PTR_ERR(mi_device);
  }
  printk(KERN_INFO "Dispositivo /dev/%s creado correctamente.\n", DEVICE_NAME);

  // 4. Inicializar y arrancar el timer.
  timer_setup(&mi_timer, timer_callback, 0);
  // HZ es una constante del kernel que representa un segundo en 'jiffies'
  // (ticks del sistema).
  mod_timer(&mi_timer, jiffies + HZ);

  printk(KERN_INFO "Timer iniciado. Sensado cada 1 segundo.\n");

  return 0;
}

// --- Función de Salida del Módulo ---

static void __exit modulo_exit(void) {
  printk(KERN_INFO "Saliendo del módulo de señales...\n");

  // Detener el timer. Es importante hacerlo antes de destruir los dispositivos.
  del_timer_sync(&mi_timer);

  // Destruir los elementos en el orden inverso a la creación.
  device_destroy(mi_class, MKDEV(major_number, 0));
  class_destroy(mi_class);
  unregister_chrdev(major_number, DEVICE_NAME);

  printk(KERN_INFO "Módulo de señales descargado.\n");
}

module_init(modulo_init);
module_exit(modulo_exit);
