RTL_COMPILE_OUTPUT 	= $(VEC_CACHE_PATH)/work/rtl_compile


TIMESTAMP			= $(shell date +%Y%m%d_%H%M_%S)
GIT_REVISION 		= $(shell git show -s --pretty=format:%h)
.PHONY: compile lint


# wsl compile
compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -kdb -lca -full64 -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM+WSL
