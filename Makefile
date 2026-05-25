PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
SWIFTC ?= swiftc
SRC := Sources/KatanaMacSpeaker/main.swift
BIN := .build/release/katana-macspeaker

.PHONY: build install uninstall desktop-launcher test clean

build:
	mkdir -p .build/release
	$(SWIFTC) $(SRC) -o $(BIN)

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
