PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
SWIFTC ?= swiftc
SRC := Sources/KatanaMacSpeaker/main.swift
BIN := .build/release/katana-macspeaker

.PHONY: build dist install uninstall desktop-launcher test clean

build:
	mkdir -p .build/release
	$(SWIFTC) $(SRC) -o $(BIN)

dist: build
	mkdir -p dist
	cp "$(BIN)" dist/katana-macspeaker
	cp scripts/boss.command dist/boss.command
	chmod +x dist/katana-macspeaker dist/boss.command
	@echo "Updated dist/katana-macspeaker and dist/boss.command"

install: build
	mkdir -p "$(BINDIR)"
	cp "$(BIN)" "$(BINDIR)/katana-macspeaker"
	chmod +x "$(BINDIR)/katana-macspeaker"
	@echo "Installed $(BINDIR)/katana-macspeaker"

uninstall:
	rm -f "$(BINDIR)/katana-macspeaker"
	@echo "Removed $(BINDIR)/katana-macspeaker"

desktop-launcher: install
	mkdir -p "$(HOME)/Desktop"
	cp scripts/boss.command "$(HOME)/Desktop/boss.command"
	chmod +x "$(HOME)/Desktop/boss.command"
	@echo "Installed $(HOME)/Desktop/boss.command"

test: build
	$(BIN) --help >/dev/null
	$(BIN) --list >/dev/null

clean:
	rm -rf .build
