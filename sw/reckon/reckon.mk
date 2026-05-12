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