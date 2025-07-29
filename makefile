RTL_COMPILE_OUTPUT 	= $(VEC_CACHE_PATH)/work/rtl_compile
RTL_SIM_OUTPUT      = $(VEC_CACHE_PATH)/work/rtl_sim

TIMESTAMP			= $(shell date +%Y%m%d_%H%M_%S)
GIT_REVISION 		= $(shell git show -s --pretty=format:%h)

VCS_COMMAND			= vcs -sverilog -lca -kdb +v2k -debug_access+all -debug_all -full64 -timescale=1ns/1ns -l com.log
WSL_VCS_COMMAND     = vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -kdb -lca -full64 -debug_access -sverilog -l com.log

.PHONY: compile lint


# wsl compile
compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -kdb -lca -full64 -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM+WSL

comp_testbench:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -kdb -lca -full64 -debug_access -sverilog -f $(TB_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM+WSL


sanity:
	mkdir -p $(RTL_SIM_OUTPUT)
	cd $(RTL_SIM_OUTPUT); $(WSL_VCS_COMMAND) -f $(SIM_FILELIST) -R +WAVE +testname=sanity