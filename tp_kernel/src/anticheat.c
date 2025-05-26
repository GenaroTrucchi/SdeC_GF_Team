/**
 * @file anti_file_logger.c
 * @brief Módulo kernel: Detecta y loguea intentos de acceso a un archivo
 * específico usando kprobes.
 *
 * Este módulo de ejemplo registra un kprobe sobre la función interna de
 * apertura de archivos
 * (`do_sys_openat2` o `ksys_openat`, según kernel) para detectar cuando un
 * proceso intenta abrir
 * `/tmp/trampa.txt`. Cuando detecta el acceso, imprime un mensaje de
 * advertencia en el log del kernel. No bloquea el acceso, solo lo registra. Es
 * útil para demostrar cómo los módulos pueden monitorear acciones en el sistema
 * y la importancia de la seguridad en la carga de módulos.
 *
 * Compatible con kernels recientes (5.x+). Para otros kernels, cambiar el
 * símbolo hookeado si es necesario.
 *
 */

#include <linux/kernel.h>
#include <linux/kprobes.h>
#include <linux/module.h>
#include <linux/uaccess.h>

#define FILE_MONITORED "/tmp/trampa.txt"
#define PATH_LEN 128

/// kprobe structure to register our probe
static struct kprobe kp;

/**
 * @brief Handler previo al llamado de la función hookeada.
 *
 * Este handler se ejecuta antes de que se ejecute la función real de
 * openat/openat2 en el kernel. Lee el path recibido y, si coincide con el
 * archivo monitoreado, lo imprime en el log del kernel.
 *
 * @param p     Puntero a la estructura kprobe
 * @param regs  Registros de la llamada (contienen los argumentos)
 * @return 0 para continuar la ejecución normal
 */
static int handler_pre(struct kprobe *p, struct pt_regs *regs) {
  char filename[PATH_LEN] = {0};
#if defined(__x86_64__)
  // En x86_64 el segundo argumento es el path del archivo, en rsi
  char __user *user_filename = (char __user *)regs->si;
#elif defined(__aarch64__)
  // En ARM64 el segundo argumento está en x1
  char __user *user_filename = (char __user *)regs->regs[1];
#else
#error "Arquitectura no soportada por este ejemplo"
#endif

  if (user_filename) {
    // Copia el path de espacio de usuario a kernel
    if (strncpy_from_user(filename, user_filename, PATH_LEN) > 0) {
      // Compara con el archivo a monitorear
      if (strcmp(filename, FILE_MONITORED) == 0) {
        printk(KERN_WARNING
               "[anti_file_logger] Intento de abrir '%s' por PID %d (%s)\n",
               filename, current->pid, current->comm);
      }
    }
  }
  return 0; // Permite la ejecución normal del openat
}

/**
 * @brief Función de inicialización del módulo.
 *
 * Registra el kprobe sobre la función de apertura de archivos interna del
 * kernel. Imprime un mensaje informando el éxito o fracaso.
 *
 * @return 0 si se inicializó correctamente, negativo en error.
 */
static int __init aflogger_init(void) {
  kp.symbol_name = "do_sys_openat2";
  kp.pre_handler = handler_pre;
  if (register_kprobe(&kp) < 0) {
    printk(KERN_ERR "[anti_file_logger] No se pudo registrar el kprobe. Prueba "
                    "otro símbolo!\n");
    return -1;
  }
  printk(KERN_INFO
         "[anti_file_logger] Módulo cargado y monitoreando acceso a '%s'\n",
         FILE_MONITORED);
  return 0;
}

/**
 * @brief Función de limpieza del módulo.
 *
 * Elimina el kprobe y libera recursos. Imprime mensaje de log.
 */
static void __exit aflogger_exit(void) {
  unregister_kprobe(&kp);
  printk(KERN_INFO "[anti_file_logger] Módulo descargado\n");
}

module_init(aflogger_init);
module_exit(aflogger_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Agustin");
MODULE_DESCRIPTION(
    "Logger de intentos de apertura de archivo específico usando kprobe");
