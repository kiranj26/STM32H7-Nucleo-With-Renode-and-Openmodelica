# ADR-0004: One COBS+CRC16 link protocol, pluggable transport

- **Status:** Accepted
- **Date:** 2026-10-10
- **Project:** P1

## Context
From P1, the firmware exchanges actuation and sensor values with a Python bridge that steps the plant FMU. The same firmware must talk to the bridge over a Renode socket terminal (TCP) and over the real board's VCP (serial). Text protocols are easy to debug, but they're slow and ambiguous for floats. Raw binary needs framing.

## Decision
Use binary frames: `COBS( msg_id:u8 | seq:u16 | payload | crc16:u16 )` followed by a `0x00` delimiter. Payloads are little-endian packed structs, and each message ID has a fixed layout. There's one C implementation (`fw/common/link`) and one Python implementation (`tools/labkit/link.py`), with a shared round-trip test. The Python side abstracts the transport (TCP or serial) behind one interface.

## Alternatives considered
- **ASCII lines (`T=23.4\n`):** human-readable, but slow, with parsing and float formatting cost in the ISR context.
- **SLIP:** similar, but COBS has a bounded overhead and simpler zero-delimiter resync.
- **Protobuf/nanopb:** schema evolution isn't needed here, and it's heavier.

## Consequences
- **Easier:** the same bridge drives Renode and hardware; robust resync; the sequence number detects lost or late frames.
- **Harder:** frames aren't human-readable, so add a `labkit.link` decoder CLI for debugging.
- **Revisit when:** P4 moves sensors and actuators to peripheral models; the link then becomes telemetry-only.
