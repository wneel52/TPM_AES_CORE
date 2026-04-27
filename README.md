# TPM_AES_CORE
Secure AES-128 Coprocessor with Hardware-Enforced Access Control

**Authors:** Carly Rosenstrauch, William Neel  
**Course:** ECE 559 – VLSI Design Project  
**University:** University of Massachusetts Amherst

---

## Overview

This project implements a secure AES-128 hardware coprocessor that combines a verified AES encryption engine with a TPM-inspired authentication and access-control subsystem.

Unlike conventional AES accelerators that focus only on encryption throughput and functional correctness, this design enforces a hardware authentication sequence before any cryptographic operation is allowed.

The result is a modular RTL system that demonstrates how hardware roots of trust can be integrated directly into cryptographic accelerators.

---

## Key Features

- AES-128 encryption core
- Hardware-enforced access control
- Multi-stage platform-key authentication FSM
- Internal platform-key storage
- 128-bit candidate key assembly from staged writes
- Zeroization / tamper response support
- ASIC synthesis and PPA evaluation
- FPGA prototype validation (iCE40 platform)
- Directed simulation + assertion-based verification

---

## Security Concept

The AES datapath remains disabled until successful authentication is completed.

### Example Triple-Key Unlock Flow

```text
WAIT_PK0 -> WAIT_PK1 -> WAIT_PK2 -> UNLOCKED
