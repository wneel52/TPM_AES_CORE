# TPM_AES_CORE

## Secure AES-128 Coprocessor with Hardware-Enforced Access Control

**Authors:** Carly Rosenstrauch, William Neel
**Course:** ECE 559 – VLSI Design Project
**University:** University of Massachusetts Amherst

---

## Overview

TPM_AES_CORE is a secure AES-128 hardware coprocessor that combines a verified AES encryption engine with a TPM-inspired authentication and access-control subsystem.

Unlike conventional AES accelerators that prioritize only throughput and functional correctness, this design requires successful hardware authentication before encryption operations are permitted.

The project demonstrates how hardware root-of-trust concepts can be integrated directly into RTL cryptographic accelerators.

---

## Key Features

* AES-128 encryption core
* Hardware-enforced access control
* Multi-stage platform-key authentication FSM
* Internal platform-key storage
* Candidate key assembly from staged 32-bit writes
* Zeroization / tamper response logic
* ASIC synthesis and PPA evaluation
* FPGA prototype validation on iCE40
* Directed simulation and assertion-based verification

---

## Security Concept

The AES datapath remains disabled until successful authentication is completed.

Example triple-key unlock flow:

`WAIT_PK0 -> WAIT_PK1 -> WAIT_PK2 -> UNLOCKED`

If an invalid authentication attempt occurs, the system enters a trapped state where AES functionality remains disabled until reset.

---

## Repository Structure

```text
aes-core/               AES-128 encryption engine
aes_input_buffer/       Plaintext input buffering
aes_result_buffer/      Ciphertext output buffering
comparator/             128-bit comparison logic
key_commit_buffer/      Candidate key assembly logic
key_vault_rom/          Secure ROM / vault concepts
platform_key_rom/       Multi-key platform storage
platform_unlock_fsm/    Final authentication FSM
top/                    Final integrated secure top-level design
implementations/        FPGA demos / UART implementations
scripts/                Helper scripts / synthesis support
docs/                   Reports, diagrams, documentation
```

---

## System Architecture

### AES Datapath

* AES encryption engine
* Plaintext input buffering
* Ciphertext result buffering

### Security / Control Path

* Authentication controller
* Unlock FSM
* Platform-key storage
* Candidate key commit buffer
* Comparator logic
* Zeroization controls

This modular separation improves scalability, debugging, and verification efficiency.

---

## Verification Methodology

### Module-Level Testing

* AES known-answer test vectors (FIPS-197)
* Comparator correctness
* Key commit buffer write / commit behavior
* FSM state transition testing

### Integration Testing

* Locked-state AES denial
* Successful unlock sequencing
* Invalid authentication rejection
* Trap-state behavior
* Zeroization reset behavior

### FPGA Hardware Validation

* UART command interface
* Live unlock testing
* Trap-state demonstration
* Repeated randomized invalid authentication attempts

---

## Results Summary

### ASIC Synthesis (45nm GPDK)

| Design              | Area Overhead |
| ------------------- | ------------- |
| Single Platform Key | 14.14%        |
| Triple Platform Key | 15.53%        |

### Security Validation

* 108,817 randomized invalid authentication attempts
* 0 false accepts observed

### Timing

* Positive slack across synthesized designs

---

## Build / Simulation Flow

### Top-Level Simulation

```bash
cd top/sim
make
```

### Module-Level Simulation

```bash
cd key_commit_buffer/sim
make
```

*(Exact commands may vary depending on installed toolchain.)*

---

## FPGA Prototype

The authentication controller was validated on an iCE40 FPGA platform using a UART-connected host.

Validated features:

* Platform-key entry
* Unlock sequence progression
* Trap-state response
* Real hardware status indication
* Secure AES gating behavior

## References

* NIST FIPS-197 Advanced Encryption Standard (AES)
* Trusted Computing Group TPM 2.0 Library
* Hardware security / logic locking literature

---

## License

Academic project repository intended for educational and research purposes.
