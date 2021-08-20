# directory definitions
BASE_DIR:=$(abspath ../)
SRC_DIR:=$(BASE_DIR)/src
BENCH_DIR:=$(BASE_DIR)/bench
IMPL_DIR:=$(BASE_DIR)/impl
BUILD_DIR:=$(BASE_DIR)/build
GEN_DIR:=$(BASE_DIR)/gen

# project definitions
PROJECT:=thruwire
SIM_SOURCES:=$(PROJECT).cpp
SOURCES:=$(PROJECT).sv
LPF:=$(PROJECT).lpf
TOP_MODULE:=$(PROJECT)

.PHONY: all sim bit
all: sim
sim: $(BUILD_DIR)/$(PROJECT).ln
bit: $(BUILD_DIR)/$(PROJECT).bit

# verilator build stuff

obj_dir/V$(PROJECT).cpp: \
	$(addprefix $(SRC_DIR)/,$(SOURCES))
	verilator -Wall -cc $<

obj_dir/V$(PROJECT)__ALL.a: obj_dir/V$(PROJECT).cpp
	make -C obj_dir -f V$(PROJECT).mk

$(BUILD_DIR)/$(PROJECT).ln: \
	$(addprefix $(BENCH_DIR)/,$(SIM_SOURCES)) \
	obj_dir/V$(PROJECT)__ALL.a
	@echo "Building a Verilator-based simulation of $(PROJECT)"
	g++ -I/usr/share/verilator/include -I obj_dir \
	/usr/share/verilator/include/verilated.cpp \
	$^ \
	-o $@
	ln -s $@ $(notdir $@)


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
	$(RM) -r *.config *.bit .*.d *.svf $(BUILD_DIR)/* $(GEN_DIR)/* obj_dir *.ln
-include .*.d
