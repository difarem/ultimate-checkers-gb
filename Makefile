TARGET_NAME = hello_world

ASM = rgbasm
ASMFLAGS = -i include/
LINK = rgblink
LINKFLAGS =
FIX = rgbfix
FIXFLAGS = -v -p 0

TARGET = build/$(TARGET_NAME).gb
SOURCES = $(wildcard src/*.asm)
OBJECTS = $(SOURCES:src/%.asm=build/%.o)

.PHONY: all
all: ${TARGET}

build/%.o: src/%.asm build
	$(ASM) $(ASMFLAGS) -o $@ $^

$(TARGET): $(OBJECTS)
	$(LINK) $(LINKFLAGS) -o $@ $^
	$(FIX) $(FIXFLAGS) $@

build:
	mkdir $@

.PHONY: clean
clean:
	rm -f $(OBJECTS) $(TARGET)
