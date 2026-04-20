<h1> *16 Bit Platform Key Functionality Demo* </h1>

This demo is intended to be ran on an ICESugar-Nano
Github Repo for the ICESugar can be found here: https://github.com/wuxx/icesugar-nano/tree/main
Explains toolchain & basic functions needed to build this demo on an ICESugar-nano FPGA



The expected behavior is as follows:
  LED0: 1 Hz heartbeat
  LED1: High indicates unlocked
  LED2: High indicates aes_enable
  LED3: Should go high before LED1 and LED2 indicating the WAIT_PK2 (waiting for second platform key (state 2)) occurs before the unlock as LED2 repserents the state_debug singals MSB which correlates to states 2 and 3



Demo: 
https://github.com/user-attachments/assets/192a6adc-cf0c-41f8-a9ec-5ffe0928e9e5
