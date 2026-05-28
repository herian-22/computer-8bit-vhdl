.PHONY: all clean analyze elaborate run view help

# GHDL settings
GHDL := ghdl
GHDLFLAGS := 
WORKDIR := work
SIMDIR := sim

# Source files
CPU_SRCS := src/cpu/alu.vhd \
            src/cpu/data_path.vhd \
            src/cpu/control_unit.vhd \
            src/cpu/cpu.vhd

MEM_SRCS := src/mem/rom_128x8_sync.vhd \
            src/mem/rw_96x8_sync.vhd \
            src/mem/memory_system.vhd

TOP_SRCS := src/top/computer_top.vhd

TB_SRCS := tb/tb_computer.vhd

ALL_SRCS := $(CPU_SRCS) $(MEM_SRCS) $(TOP_SRCS) $(TB_SRCS)

# Targets
ENTITY := tb_computer
WAVE := $(SIMDIR)/wave.ghw

help:
	@echo "8-bit Computer VHDL Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all       - Analyze, elaborate, and run simulation"
	@echo "  make analyze   - Analyze VHDL sources"
	@echo "  make elaborate - Elaborate design"
	@echo "  make run       - Run simulation"
	@echo "  make view      - Open waveform in GTKWave"
	@echo "  make clean     - Remove generated files"
	@echo ""

all: analyze elaborate run view

analyze: $(ALL_SRCS)
	@echo "[1/3] Analyzing VHDL sources..."
	$(GHDL) -a $(GHDLFLAGS) $(ALL_SRCS)
	@echo "      Done."

elaborate: analyze
	@echo "[2/3] Elaborating..."
	$(GHDL) -e $(GHDLFLAGS) $(ENTITY)
	@echo "      Done."

run: elaborate
	@echo "[3/3] Running simulation..."
	@mkdir -p $(SIMDIR)
	$(GHDL) -r $(GHDLFLAGS) $(ENTITY) --wave=$(WAVE) --stop-time=13us || true
	@echo "      Done (check output above)."

view: $(WAVE)
	@echo "Opening GTKWave..."
	@if command -v gtkwave >/dev/null 2>&1; then \
		gtkwave $(WAVE) & \
	elif command -v "C:\\msys64\\ucrt64\\bin\\gtkwave.exe" >/dev/null 2>&1; then \
		"C:\\msys64\\ucrt64\\bin\\gtkwave.exe" $(WAVE) & \
	else \
		echo "GTKWave not found in PATH"; \
	fi

clean:
	@echo "Cleaning..."
	$(GHDL) --clean $(GHDLFLAGS) || true
	rm -rf $(WORKDIR) $(SIMDIR)/*.ghw $(SIMDIR)/*.vcd
	@echo "      Done."

.PHONY: all clean analyze elaborate run view help
