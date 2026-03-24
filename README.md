# TPM-Style AES Core

## Overview
This project implements a TPM-style secure wrapper around an AES core. It includes:
- key authentication path
- unlock control FSM
- AES input/output buffering
- protected key storage support

## Module Overview
- `comparator/` - key comparison primitive
- `key_commit_buffer/` - attempted key staging and commit/check logic
- `unlock_fsm/` - unlock FSM
- `key_vault_rom/` - protected key vault ROM
- `aes_input_buffer/` - AES input block staging
- `results_buffer/` - AES result capture and readback
- `aes-core/` - AES encryption/decryption engine

## Security/Control Rule
AES operation is only permitted when:
- `aes_enable == 1`
- input block is fully valid

## Documentation
See `docs/` for:
- port definitions
- integration notes
- system wiring summary

## Sources
AES Engine: https://github.com/secworks/aes
