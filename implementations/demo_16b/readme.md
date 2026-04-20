<h1> 16 Bit Platform Key Functionality Demo</h1>

This demo is intended to be ran on an ICESugar-Nano
Github Repo for the ICESugar can be found here: https://github.com/wuxx/icesugar-nano/tree/main
Explains toolchain & basic functions needed to build this demo on an ICESugar-nano FPGA

Behavior:
After boot, internal sequencer submits three 16-bit keys.
On success, unlocked + aes_enable assert.

The expected output is as follows:
  Clock: 12 MHz
  LED0 heartbeat
  LED1 unlocked
  LED2 aes_enable
  LED3 state_debug[1] Should go high before LED1 and LED2 indicating the WAIT_PK2 (waiting for second platform key (state 2)) occurs before the unlock as LED2 repserents the state_debug singals MSB which correlates to states 2 and 3



Demo: 
https://github.com/user-attachments/assets/192a6adc-cf0c-41f8-a9ec-5ffe0928e9e5
