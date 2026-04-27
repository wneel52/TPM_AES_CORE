filename = top
pcf_file = ./io.pcf

SRCS = top.v \
       uart_baud_tick_gen.v \
       uart_rx.v \
       uart_tx.v \
       auth_uart_bridge.v \
       auth_controller_top.v \
       platform_unlock_fsm.v \
       platform_key_store.v \
       key_activation_compare.v

ICELINK_DIR=$(shell df | grep iCELink | awk '{print $$6}')
${warning iCELink path: $(ICELINK_DIR)}

build:
	yosys -p "read_verilog -sv $(SRCS); synth_ice40 -top $(filename) -json $(filename).json -blif $(filename).blif"
	nextpnr-ice40 --lp1k --package cm36 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --freq 48
	icepack $(filename).asc $(filename).bin

prog_flash:
	@if [ -d '$(ICELINK_DIR)' ]; then \
		cp $(filename).bin $(ICELINK_DIR); \
	else \
		echo "iCELink not found"; \
		exit 1; \
	fi

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin $(filename).json
