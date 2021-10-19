# directory definitions
BASE_DIR:=$(abspath ../)
SRC_DIR:=$(BASE_DIR)/src
BENCH_DIR:=$(BASE_DIR)/bench
IMPL_DIR:=$(BASE_DIR)/impl
BUILD_DIR:=$(BASE_DIR)/build
GEN_DIR:=$(BASE_DIR)/gen

# project definitions
PROJECT:=data_debugger
SIM_SOURCES:=$(PROJECT).cpp
COSIMS:=uartsim.cpp btnsim.cpp
SOURCES:=$(PROJECT).sv detect_change.sv counter.sv wb_data_tx.sv wb_uart_tx.sv debouncer.sv
LPF:=$(PROJECT).lpf
TOP_MODULE:=$(PROJECT)

VERILATOR:=verilator
VFLAGS:= -O3 -MMD --trace -Wall
VDEFS:=$(shell ./vversion.sh)
VERILATOR_ROOT ?= $(shell bash -c '$(VERILATOR) -V|grep VERILATOR_ROOT | head -1 | sed -e "s/^.*=\s*//"')
VINC:= $(VERILATOR_ROOT)/include
LIBS := -lncurses


.PHONY: all sim prove bit
.DELETE_ON_ERROR:
all: sim
sim: $(BUILD_DIR)/$(PROJECT).ln
bit: $(BUILD_DIR)/$(PROJECT).bit
prove: $(PROJECT).sby

GCC := clang++
VDIRFB:=obj_dir
CFLAGS:= -g -Wall -I$(VINC) -I $(VDIRFB)

# sby stuff
$(PROJECT).sby: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	echo "[tasks]" > $@
	echo "prf" >> $@
	echo "cvr" >> $@
	echo "bmc" >> $@
	echo "[options]" >> $@
	echo "depth 50" >> $@
	echo "prf: mode prove" >> $@
	echo "cvr: mode cover" >> $@
	echo "bmc: mode bmc" >> $@
	echo "[engines]" >> $@
	echo "smtbmc" >> $@
	echo "[script]" >> $@
	echo "read_verilog -DDM -formal -sv $^" >> $@
	echo "prep -top $(TOP_MODULE)" >> $@
	echo "[files]" >> $@
	$(foreach var,$^, echo "$(var)" >> $@;)

# verilator build stuff

obj_dir/V$(PROJECT).cpp: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	verilator $(VFLAGS) -cc $^ --top-module $(TOP_MODULE)

obj_dir/V$(PROJECT)__ALL.a: obj_dir/V$(PROJECT).cpp
	make -C obj_dir -f V$(PROJECT).mk

$(BUILD_DIR)/$(PROJECT).ln: \
	$(addprefix $(BENCH_DIR)/,$(SIM_SOURCES)) \
	obj_dir/V$(PROJECT)__ALL.a \
	$(addprefix $(BENCH_DIR)/,$(COSIMS))
	@echo "Building a Verilator-based simulation of $(PROJECT)"
	$(GCC) $(CFLAGS) $(VDEFS) \
	$(VINC)/verilated.cpp \
	$(VINC)/verilated_vcd_c.cpp \
	$(LIBS) \
	$^ \
	-o $@
	ln -sf $@ $(notdir $@)


# yosys + nextpnr build stuff

# 12F: 0x21111043
# 25F: 0x41111043
# 45F: 0x41112043
# 85F: 0x41113043
IDCODE ?= 0x41113043 #85

%.v: Makefile


$(PROJECT).ys: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	echo "read_verilog -sv $^" > $@
	echo "hierarchy -top $(TOP_MODULE)" >> $@
	echo "synth_ecp5 -json $(BUILD_DIR)/$(PROJECT).json" >> $@
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.json: %.ys
	yosys \
		-E .$(basename $(notdir $@)).d \
		$<

$(BUILD_DIR)/%.config: $(BUILD_DIR)/%.json $(IMPL_DIR)/$(LPF)
	nextpnr-ecp5 \
		--json $< \
		--textcfg $@ \
		--lpf $(IMPL_DIR)/$(LPF) \
		--85k \
		--package CABGA381

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%.config
	ecppack --idcode $(IDCODE) $< $@

%.svf: %.config
	ecppack --idcode $(IDCODE) --input $< --svf $@

%.flash: %.bit
	ujprog $<
%.terminal: %.bit
	ujprog -t -b 3000000 $<

clean:
	$(RM) -r *.config *.bit .*.d *.svf $(BUILD_DIR)/* $(GEN_DIR)/* obj_dir *.ln *.sby *.ys *.vcd*
-include .*.d
