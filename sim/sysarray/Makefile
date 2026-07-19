# =============================================================================
# cocotb setup for only systolic array testing (run `make` in this dir to use)
# =============================================================================

SIM          = questa-compat
TOPLEVEL_LANG = verilog

COCOTB_TOPLEVEL     = sysarray_top
COCOTB_TEST_MODULES = test_sysarray

RTL_ROOT 	= $(abspath ../../rtl)
SIM_ROOT 	= $(abspath $(CURDIR)/..)
COMMON_ROOT = $(SIM_ROOT)/common

SIM_BUILD           = ../results/sysarray/sim_build
COCOTB_RESULTS_FILE = ../results/sysarray/results.xml

VERILOG_SOURCES  = $(RTL_ROOT)/tpu/tpu_pkg.sv
VERILOG_SOURCES += $(RTL_ROOT)/std/std_sync_fifo.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/ws_pe.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray_skew.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray_buf.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray_core.sv
VERILOG_SOURCES += $(RTL_ROOT)/sysarray/sysarray_top.sv

COMPILE_ARGS += -sv
COMPILE_ARGS += -suppress 2583
COMPILE_ARGS += -suppress 12110

SIM_ARGS += +acc
SIM_ARGS += -suppress 2583
SIM_ARGS += -suppress 12110
SIM_ARGS += -do "$(COMMON_ROOT)/wave.do"
SIM_ARGS += -wlf "$(SIM_BUILD)/waves.wlf"


include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: info

info:
	@echo $(RTL_ROOT)

waves:
	@cd $(SIM_BUILD) && vsim -view waves.wlf