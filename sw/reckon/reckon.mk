CHS_SW_RECKON_DIR ?= $(CHS_SW_DIR)/reckon
LABEL_DELAY ?= 4

RK_CDEF =  -DLABEL_DELAY=$(LABEL_DELAY)
RK_CDEF += -DTRAIN_DS_PATH=$(CHS_SW_RECKON_DIR)/$(DS_PATH)/train_ds.dat
RK_CDEF += -DTRAIN_LB_PATH=$(CHS_SW_RECKON_DIR)/$(DS_PATH)/train_labels.dat
RK_CDEF += -DVAL_DS_PATH=$(CHS_SW_RECKON_DIR)/$(DS_PATH)/val_ds.dat
RK_CDEF += -DVAL_LB_PATH=$(CHS_SW_RECKON_DIR)/$(DS_PATH)/val_labels.dat

# invoke with $ make chs-create-memfile LABEL_DELAY=4 DS_PATH=<subdir containing the files>
chs-create-memfile:
	gcc $(RK_CDEF) $(CHS_SW_RECKON_DIR)/add_labels.c -o $(CHS_SW_RECKON_DIR)/addlabels.o
	@echo "Generating .mem files for synthesis"
	@$(CHS_SW_RECKON_DIR)/addlabels.o
	@echo "Generated aertrain_ds.mem and aerval_ds.mem"

CHS_SW_RECKON_INCL_DIR ?= $(CHS_SW_DIR)/include/reckon

# Generate a random weight header file for RECKON.
# Usage: make chs-gen-weights-<type> WGEN_PRE=<pre> WGEN_POST=<post> [WGEN_SEED=<seed>]
#   <type> : winp | wrec | wout
#   <pre>  : number of presynaptic neurons
#   <post> : number of postsynaptic neurons
#   <seed> : (optional) random seed for reproducibility
#
# Example:
#   make chs-gen-weights-winp WGEN_PRE=6 WGEN_POST=38
#   make chs-gen-weights-wrec WGEN_PRE=38 WGEN_POST=38 WGEN_SEED=42
WGEN_PRE  ?= 0
WGEN_POST ?= 0
WGEN_SEED ?=

chs-gen-weights-%:
	@if [ "$(WGEN_PRE)" = "0" ] || [ "$(WGEN_POST)" = "0" ]; then \
		echo "Error: specify WGEN_PRE=<n> WGEN_POST=<n>"; exit 1; \
	fi
	@mkdir -p $(CHS_SW_RECKON_INCL_DIR)
	@python3 $(CHS_SW_RECKON_DIR)/weights_gen.py \
		--type $* \
		--pre $(WGEN_PRE) \
		--post $(WGEN_POST) \
		--output $(CHS_SW_RECKON_INCL_DIR)/$*.h \
		$(if $(WGEN_SEED),--seed $(WGEN_SEED))