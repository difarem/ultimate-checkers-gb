TARGET_NAME = ultimate_checkers

ASM = rgbasm
ASMFLAGS = -i include/ -i build/
LINK = rgblink
LINKFLAGS =
FIX = rgbfix
FIXFLAGS = -v -p 0
GFX = rgbgfx
GFXFLAGS = -F

GBA = mgba-qt

SOURCES = src/header.asm src/main.asm

IMAGES = gfx/board.png

TARGET = build/$(TARGET_NAME).gb
OBJECTS = $(SOURCES:src/%.asm=build/%.o)

TILEMAPS = $(IMAGES:%.png=build/%.tilemap)
TILESETS = $(IMAGES:%.png=build/%.2bpp)

.PHONY: all
all: $(TARGET)

build/%.o: src/%.asm $(TILEMAPS) $(TILESETS) build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/gfx/%.tilemap build/gfx/%.2bpp: gfx/%.png build/gfx
	$(GFX) $(GFXFLAGS) -u -t build/gfx/$*.tilemap -o build/gfx/$*.2bpp $<

$(TARGET): $(OBJECTS) $(TILEMAPS) $(TILESETS)
	$(LINK) $(LINKFLAGS) -o $@ $(OBJECTS)
	$(FIX) $(FIXFLAGS) $@

build:
	mkdir -p build

build/gfx: build
	mkdir -p build/gfx

.PHONY: run
run: $(TARGET)
	$(GBA) $<

.PHONY: clean
clean:
	rm -rf build/*
