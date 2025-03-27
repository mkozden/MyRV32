SV_FILES = ${wildcard ./src/pkg/*.sv} ${wildcard ./src/*.sv}
TB_FILES = ${wildcard ./tb/*.sv}
ALL_FILES = ${SV_FILES} ${TB_FILES}


lint:
	@echo "Running lint checks..."
	verilator --lint-only -Wall --timing -Wno-UNUSED -Wno-MULTIDRIVEN -Wno-CASEINCOMPLETE ${ALL_FILES}

build:
	verilator  --binary ${SV_FILES} ./tb/tb.sv --top tb -j 0 --trace -Wno-CASEINCOMPLETE  -Wno-MULTIDRIVEN

run: build
	obj_dir/Vtb

wave: run
	gtkwave --dark dump.vcd

clean:
	@echo "Cleaning temp files..."
	rm dump.vcd
	rm obj_dir/*


.PHONY: compile run wave lint clean help
