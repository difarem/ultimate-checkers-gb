TARGET_NAME = hello_world

ASM = rgbasm
ASMFLAGS = -i include/ -i build/
LINK = rgblink
LINKFLAGS =
FIX = rgbfix
FIXFLAGS = -v -p 0
GFX = rgbgfx
GFXFLAGS = -F

TARGET = build/$(TARGET_NAME).gb
SOURCES = $(wildcard src/*.asm)
OBJECTS = $(SOURCES:src/%.asm=build/%.o)

IMAGES = $(wildcard gfx/*.png)
TILEMAPS = $(IMAGES:%.png=build/%.tilemap)
TILESETS = $(IMAGES:%.png=build/%.2bpp)

.PHONY: all
all: ${TARGET}

build/%.o: src/%.asm $(TILEMAPS) $(TILESETS)
	mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/gfx/%.tilemap build/gfx/%.2bpp: gfx/%.png
	mkdir -p build/gfx
	$(GFX) $(GFXFLAGS) -u -t build/gfx/$*.tilemap -o build/gfx/$*.2bpp $^

$(TARGET): $(OBJECTS) $(TILEMAPS) $(TILESETS)
	$(LINK) $(LINKFLAGS) -o $@ $(OBJECTS)
	$(FIX) $(FIXFLAGS) $@

.PHONY: clean
clean:
	rm -rf build/*
