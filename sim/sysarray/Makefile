# =============================================================================
# Layer 1: Systolic Array Core
# Pure RTL, no vendor primitives — Icarus works fine here too.
# Switch to icarus with: make SIM=icarus
# =============================================================================

LAYER    = sysarray
TOPLEVEL = sysarray_core
MODULE   = test_sysarray

# ── Sources ───────────────────────────────────────────────────────────────────
VERILOG_SOURCES += $(RTL_ROOT)/tpu/tpu_pkg.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/ws_pe.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarraw_skew.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray_core.sv


.PHONY: sim

sim:
	mkdir -p ../results/$(LAYER)
	cd ../results/$(LAYER) && $(MAKE) -f $(CURDIR)/Makefile _sim

_sim: results.xml

include ../Makefile.common