# 16-Bit Platform Key Functionality Demo

This demo is intended to run on the **iCESugar-Nano** FPGA board.

The iCESugar-Nano GitHub repository can be found here:  
https://github.com/wuxx/icesugar-nano/tree/main

That repository includes the toolchain setup and the basic board information needed to build and program this demo.

## Demo Behavior

After boot, an internal sequencer submits three 16-bit platform keys to the authentication controller.  
If all three keys are accepted in the correct sequence, the controller asserts:

- `unlocked`
- `aes_enable`

## Expected Output

**Clock:** 12 MHz

- **LED0** — heartbeat
- **LED1** — `unlocked`
- **LED2** — `aes_enable`
- **LED3** — `state_debug[1]`

### LED3 Behavior

`LED3` should go high before `LED1` and `LED2`.

This indicates that the controller reaches the intermediate wait state before the final unlock condition is reached. Since `LED3` is driven by `state_debug[1]`, it reflects the MSB of the controller state encoding, which becomes active in the later wait/unlock progression.

## Demo Video

https://github.com/user-attachments/assets/192a6adc-cf0c-41f8-a9ec-5ffe0928e9e5
