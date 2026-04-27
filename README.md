# TPM_AES_CORE  
Secure AES-128 Coprocessor with Hardware-Enforced Access Control  

**Authors:** Carly Rosenstrauch, William Neel  
**Course:** ECE 559 / VLSI Design Project  
**University:** University of Massachusetts Amherst  

---

## Overview

This project implements a **secure AES-128 hardware coprocessor** that combines a verified AES encryption engine with a **TPM-inspired authentication and access-control subsystem**.

Unlike conventional AES accelerators that focus only on performance and correctness, this design requires successful hardware authentication before cryptographic operations are permitted.

The system demonstrates how **root-of-trust concepts** can be integrated directly into RTL hardware using modular Verilog/SystemVerilog design.

---

## Key Features

- AES-128 hardware encryption core  
- Hardware-enforced authentication gating  
- Multi-stage platform key unlock FSM  
- Internal platform-key storage  
- Candidate key commit buffer (4x32-bit staged writes → 128-bit key)  
- Zeroization / tamper response support  
- ASIC synthesis and PPA evaluation  
- FPGA prototype validation (iCE40 platform)  
- Directed testbenches + assertion-based verification  

---

## Security Concept

The AES datapath remains disabled until the required authentication sequence is completed.

### Triple-Key Example Flow

```text
WAIT_PK0 → WAIT_PK1 → WAIT_PK2 → UNLOCKED
