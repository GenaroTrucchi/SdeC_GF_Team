/* gini_processor.c – Lee un float de stdin, llama a calculate_gini_int (ASM) y
 * escribe el entero resultante a stdout. Compilar con -m32. */
#include <stdio.h>
#include <stdlib.h>

extern int calculate_gini_int(float);

int main(void) {
  float gini;
  if (scanf("%f", &gini) != 1) {
    fprintf(stderr, "Error: no se pudo leer el float desde stdin\n");
    return 1;
  }

  int result = calculate_gini_int(gini);
  printf("%d\n", result);
  return 0;
}
