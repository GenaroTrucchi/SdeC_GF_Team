CC      = gcc
AS      = nasm
CFLAGS  = -m32 -g -Wall -Wextra -O2
ASFLAGS = -f elf32 -g
TARGET  = gini_processor

SRC_C   = gini_processor.c
SRC_ASM = gini_calc.asm

OBJ_DIR = build
BIN     = $(OBJ_DIR)/$(TARGET)
OBJ     = $(OBJ_DIR)/gini_processor.o $(OBJ_DIR)/gini_calc.o

.PHONY: all clean run

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: %.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.asm | $(OBJ_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

run: $(BIN)
	python3 fetch_gini.py

clean:
	rm -rf $(OBJ_DIR)

