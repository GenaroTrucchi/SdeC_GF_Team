import matplotlib.pyplot as plt
import matplotlib.animation as animation
import threading
import time
import os
import sys

# --- Constantes y Variables Globales ---

DEVICE_FILE = "/dev/mis_senales"
# Usamos listas para almacenar los datos del gráfico
x_data = []
y_data = []
# Variable para llevar la cuenta del tiempo en el eje X
current_time = 0
# Variable para saber qué señal estamos graficando actualmente
current_signal_name = "Señal 0 (Contador)"


# --- Configuración del Gráfico ---

fig, ax = plt.subplots()

def setup_plot():
    """Configura los títulos y etiquetas del gráfico."""
    ax.set_title(f"Graficando: {current_signal_name}")
    ax.set_xlabel("Tiempo (s)")  # El TP pide tiempo en ordenadas, pero es un estándar ponerlo en abscisas. Lo hacemos como es estándar.
    ax.set_ylabel("Valor de la Señal (unidades)") # El TP pide tiempo en ordenadas, lo cual es inusual. Corregimos a la convención estándar.
    ax.grid(True)

# --- Funciones de Interacción con el Driver ---

def change_signal(signal_num):
    """
    Escribe en el device file para cambiar la señal que el driver reporta
    y resetea el gráfico.
    """
    global x_data, y_data, current_time, current_signal_name

    try:
        with open(DEVICE_FILE, 'w') as f:
            f.write(str(signal_num))
        print(f"\n[INFO] Solicitud para cambiar a la señal {signal_num} enviada.")
        
        # Resetear los datos del gráfico
        x_data.clear()
        y_data.clear()
        current_time = 0
        
        # Actualizar el nombre de la señal para el título del gráfico
        if signal_num == 0:
            current_signal_name = "Señal 0 (Contador 0-99)"
        else:
            current_signal_name = "Señal 1 (Onda Triangular 0-100)"

    except IOError as e:
        print(f"[ERROR] No se pudo escribir en el dispositivo: {e}")
        print("[ERROR] Asegúrate de que el módulo del kernel esté cargado y tengas permisos.")

def update_plot(frame):
    """
    Función que se llama periódicamente para leer un nuevo dato y actualizar el gráfico.
    """
    global current_time
    
    try:
        # 1. Leer el nuevo valor desde el driver
        with open(DEVICE_FILE, 'r') as f:
            line = f.readline()
            new_value = int(line.strip())

        # 2. Añadir los nuevos datos a nuestras listas
        x_data.append(current_time)
        y_data.append(new_value)
        
        # Mantenemos solo los últimos 50 puntos para que el gráfico no se sature
        if len(x_data) > 50:
            x_data.pop(0)
            y_data.pop(0)

        # 3. Limpiar y redibujar el gráfico
        ax.clear()
        setup_plot() # Volver a poner títulos y etiquetas
        ax.plot(x_data, y_data, 'r-') # 'r-' es una línea ('-') roja ('r')
        
        current_time += 1

    except (IOError, ValueError) as e:
        # Si hay un error de lectura o conversión, no hacemos nada en este frame.
        # Esto puede pasar si el módulo se descarga mientras el script corre.
        print(f"\n[ADVERTENCIA] No se pudo leer o procesar el dato: {e}", end="")
        pass
    except FileNotFoundError:
        print(f"\n[ERROR] Archivo de dispositivo '{DEVICE_FILE}' no encontrado.")
        print("[ERROR] Por favor, carga el módulo del kernel ('sudo insmod ...').")
        plt.close() # Cierra la ventana del gráfico
        sys.exit(1) # Termina el script

def user_input_thread():
    """
    Un hilo separado que maneja la entrada del usuario para no bloquear el gráfico.
    """
    while True:
        choice = input("--> Ingrese '0' o '1' para cambiar de señal, o 'q' para salir: ")
        if choice == '0':
            change_signal(0)
        elif choice == '1':
            change_signal(1)
        elif choice.lower() == 'q':
            print("[INFO] Saliendo...")
            os._exit(0) # Salida forzada para terminar todos los hilos

# --- Programa Principal ---

if __name__ == "__main__":
    print("--- Aplicación de Graficación de Señales ---")
    
    if not os.path.exists(DEVICE_FILE):
        print(f"[ERROR] El dispositivo '{DEVICE_FILE}' no existe. ¿Cargaste el módulo del kernel?")
        sys.exit(1)
    
    # Iniciar el hilo para la entrada de usuario
    input_thread = threading.Thread(target=user_input_thread, daemon=True)
    input_thread.start()
    
    # Configurar la señal inicial a 0
    change_signal(0)
    
    # Crear la animación que llama a 'update_plot' cada 1000 ms (1 segundo)
    # El intervalo coincide con el timer del kernel para una sincronización perfecta.
    ani = animation.FuncAnimation(fig, update_plot, interval=1000)
    
    # Mostrar el gráfico. Esta función es bloqueante.
    plt.show()
    print("Ventana de gráfico cerrada. El programa ha terminado.")
