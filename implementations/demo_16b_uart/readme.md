# 16-Bit Platform Key UART Authentication Demo

This demo targets the **iCESugar-Nano** FPGA board.

Official board repository:  
https://github.com/wuxx/icesugar-nano/tree/main

That repository includes programming instructions, board files, and general toolchain guidance for the iCESugar-Nano platform.

---

# Project Overview

This design demonstrates a **staged platform-key authentication controller** implemented on FPGA hardware.

Three platform keys must be entered in the correct order before protected functionality is enabled.

The demo currently uses a **16-bit reduced-width prototype configuration** to validate:

- UART command/control interface
- staged authentication FSM
- ordered key progression
- reset / zeroize behavior
- gated enable of protected logic

The architecture is intended to scale to wider key sizes later.

---

# Hardware Configuration

**Clock:** 12 MHz

**Board:** iCESugar-Nano

---

# UART Interface

The FPGA is controlled through a UART serial connection.

**Baud Rate:** `115200`

## Supported Commands

| Command | Hex | Description |
|---|---|---|
| Load Key | `0xA1` | Followed by 2 bytes (MSB first) |
| Compare | `0xA2` | Compare loaded key against expected platform key |
| Status | `0xA3` | Returns 2-byte status packet |
| Zeroize | `0xA4` | Reset controller to locked state |
| Illegal Commit | `0xA5` | Debug / fault injection path |

---

# Current 16-Bit Platform Keys

The active reduced-width platform keys are:

| Stage | Key |
|---|---|
| PK0 | `0xEEFF` |
| PK1 | `0x4444` |
| PK2 | `0x5678` |

These are derived from truncating wider platform-key constants into a 16-bit prototype implementation.

---

# Authentication Behavior

System boots in a locked state.

To unlock:

1. Load `0xEEFF` and compare  
2. Load `0x4444` and compare  
3. Load `0x5678` and compare

If entered correctly and in order, the controller asserts:

- `unlocked = 1`
- `aes_enable = 1`

Any incorrect key during the sequence resets the controller to the initial locked state.

---

# Status Response Format

Status command (`0xA3`) returns:

```text
0xD0 <status_byte>
