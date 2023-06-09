# directory definitions
BASE_DIR:=$(abspath ../)
SRC_DIR:=$(BASE_DIR)/src
BENCH_DIR:=$(BASE_DIR)/bench
IMPL_DIR:=$(BASE_DIR)/impl
BUILD_DIR:=$(BASE_DIR)/build
GEN_DIR:=$(BASE_DIR)/gen

# project definitions
PROJECT:=helloworld
SIM_SOURCES:=$(PROJECT).cpp uartsim.cpp
SOURCES:=$(PROJECT).sv wb_uart_tx.sv hello_world_mem.sv clock_div.sv
LPF:=$(PROJECT).lpf
TOP_MODULE:=$(PROJECT)
VINC:=/usr/share/verilator/include

.PHONY: all sim bit prove
.DELETE_ON_ERROR:
all: sim
sim: $(BUILD_DIR)/$(PROJECT).ln
bit: $(BUILD_DIR)/$(PROJECT).bit
prove: $(PROJECT).sby

CPPOPTS:= #-g

# sby stuff
$(PROJECT).sby: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	echo "[tasks]" > $@
	echo "prf" >> $@
	echo "cvr" >> $@
	echo "[options]" >> $@
	echo "depth 200" >> $@
	echo "prf: mode prove" >> $@
	echo "cvr: mode cover" >> $@
	echo "[engines]" >> $@
	echo "smtbmc" >> $@
	echo "[script]" >> $@
	echo "read -formal -sv $^" >> $@
	echo "prep -top $(TOP_MODULE)" >> $@
	echo "[files]" >> $@
	$(foreach var,$^, echo "$(var)" >> $@;)

# verilator build stuff

obj_dir/V$(PROJECT).cpp: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	verilator -Wall --trace -MMD  -cc $^ --top-module $(TOP_MODULE)

obj_dir/V$(PROJECT)__ALL.a: obj_dir/V$(PROJECT).cpp
	make -C obj_dir -f V$(PROJECT).mk

$(BUILD_DIR)/$(PROJECT).ln: \
	$(addprefix $(BENCH_DIR)/,$(SIM_SOURCES)) \
	obj_dir/V$(PROJECT)__ALL.a
	@echo "Building a Verilator-based simulation of $(PROJECT)"
	g++ -I$(VINC) -I obj_dir \
	$(VINC)/verilated.cpp \
	$(VINC)/verilated_vcd_c.cpp \
	$(CPPOPTS) \
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
