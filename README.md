# Hardware Limit Order Book (SystemVerilog)

A SystemVerilog RTL prototype of a bid/ask limit order book. It stores orders in per-price FIFO queues, selects the best occupied levels, and detects a crossed book. The design includes a Basys3-facing top module and a self-checking simulation testbench.

## What is implemented

- Separate bid and ask books with 64 price levels by default; higher indices represent higher prices.
- Per-level FIFO storage for order IDs and quantities (8 orders per level by default), with a full-level reject signal.
- Priority encoders that select the highest occupied bid and lowest occupied ask.
- Crossing detection when the best bid is at or above the best ask, plus a match quantity output.
- Head-order quantity decrement and FIFO advancement when an order is filled.
- A Basys3 top module (`basys_top.sv`) with switch/button inputs and LED outputs.

## Design map

| File | Role |
| --- | --- |
| `lob_top.sv` | Connects both books, priority encoders, and matching logic. |
| `price_level_array.sv` | Stores per-level order FIFOs, aggregate quantities, and full/reject state. |
| `priority_encoder_bid.sv` / `priority_encoder_ask.sv` | Find the best occupied price level on each side. |
| `matching_engine.sv` | Detects a crossed book and calculates `match_qty` from the selected level totals. |
| `lob_tb.sv` | Self-checking RTL simulation. |
| `basys_top.sv` / `basys3.xdc` | Basys3-facing top and pin constraints. |

Key defaults: `NUM_LEVELS=64`, `QTY_WIDTH=16`, `ORDER_ID_WIDTH=16`, and `MAX_ORDERS_PER_LEVEL=8`. The top-level order inputs include price index, order ID, and quantity on each side; outputs include add rejection, match validity, matched price indices, and match quantity.

## Run the testbench

Requires Icarus Verilog with SystemVerilog support. From the repository root:

```sh
iverilog -g2012 -o lob_sim.vvp lob_tb.sv lob_top.sv matching_engine.sv price_level_array.sv priority_encoder_ask.sv priority_encoder_bid.sv
vvp lob_sim.vvp
```

The testbench checks empty and one-sided books, crossed and non-crossed prices, exact-price matching, FIFO head behavior during partial and complete fills, and rejection at a full level. In the current version it reports `ALL 14 CHECKS PASSED`. It also writes `lob_sim.vcd` for waveform inspection.

## Scope and next steps

This is an RTL prototype, not a complete exchange matching engine. The current match quantity is calculated from aggregate quantities at the best price levels, while fills update the FIFO head order. Full order-by-order execution across multiple resting orders needs further implementation and verification. Cancellation/modification, randomized reference-model testing, and invariant assertions are also future work.
