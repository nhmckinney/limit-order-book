# Hardware Limit Order Book (SystemVerilog)

A synthesizable SystemVerilog implementation of a simplified limit order book (LOB) matching engine, modeling price-time priority order matching at the RTL level.

## Overview

The design maintains separate bid-side and ask-side price level arrays, tracks the best (highest) bid and best (lowest) ask combinationally, and asserts a match whenever the book is crossed (`best_bid_idx >= best_ask_idx`).

```
                 ┌───────────────────┐
  bid_add_* ───► │ price_level_array  │──► bid_qty_levels[NUM_LEVELS]
                 │      (bidPLA)      │
                 └───────────────────┘
                                          ┌────────────────────┐
                                          │ priority_encoder_bid│──► best_bid_idx, best_bid_valid
                                          └────────────────────┘
                                                     │
                                                     ▼
                                          ┌────────────────────┐
                                          │  matching_engine    │──► match_valid, match_bid_idx, match_ask_idx
                                          └────────────────────┘
                                                     ▲
                 ┌───────────────────┐               │
  ask_add_* ───► │ price_level_array  │──► ask_qty_levels[NUM_LEVELS]
                 │      (askPLA)      │    ┌────────────────────┐
                 └───────────────────┘     │ priority_encoder_ask│
                                            └────────────────────┘
```

## Modules

| File | Description |
|---|---|
| `lob_top.sv` | Top-level module wiring the two price level arrays, both priority encoders, and the matching engine. |
| `price_level_array.sv` | Clocked array of `NUM_LEVELS` quantity accumulators, indexed by price level. Adds incoming order quantity to the addressed level on `add_valid`. |
| `priority_encoder_bid.sv` | Combinationally scans the bid-side quantity array and returns the highest occupied index (best bid). |
| `priority_encoder_ask.sv` | Combinationally scans the ask-side quantity array and returns the lowest occupied index (best ask). |
| `matching_engine.sv` | Combinational match logic: asserts `match_valid` when `best_bid_idx >= best_ask_idx` and both sides are valid. |
| `lob_tb.sv` | Self-checking testbench exercising reset, one-sided books, crossed/non-crossed books, and exact-touch matching. |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `NUM_LEVELS` | 64 | Number of discrete price levels tracked per side. |
| `QTY_WIDTH` | 16 | Bit width of the quantity accumulator at each price level. |

Price levels are indexed such that **higher index = higher price**, consistent with the matching condition `best_bid_idx >= best_ask_idx`.

## Interface

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk`, `rst_n` | in | 1 | Clock and active-low async reset. |
| `bid_add_valid` | in | 1 | Add a bid order this cycle. |
| `bid_add_price_idx` | in | `$clog2(NUM_LEVELS)` | Price level index for the incoming bid. |
| `bid_add_qty` | in | `QTY_WIDTH` | Quantity to add at that bid level. |
| `ask_add_valid` | in | 1 | Add an ask order this cycle. |
| `ask_add_price_idx` | in | `$clog2(NUM_LEVELS)` | Price level index for the incoming ask. |
| `ask_add_qty` | in | `QTY_WIDTH` | Quantity to add at that ask level. |
| `match_valid` | out | 1 | Asserted when the book is crossed. |
| `match_bid_idx` | out | `$clog2(NUM_LEVELS)` | Best bid index at the time of match. |
| `match_ask_idx` | out | `$clog2(NUM_LEVELS)` | Best ask index at the time of match. |

## Simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/) (tested on v12.0).

```bash
iverilog -g2012 -o lob_sim.vvp lob_tb.sv lob_top.sv matching_engine.sv price_level_array.sv priority_encoder_ask.sv priority_encoder_bid.sv
vvp lob_sim.vvp
```

This produces `lob_sim.vcd`, viewable in [GTKWave](http://gtkwave.sourceforge.net/):

```bash
gtkwave lob_sim.vcd
```

## Testbench Coverage

`lob_tb.sv` runs seven checks:

1. Empty book → no match
2. Bid only, no ask → no match
3. Crossed book (bid above ask) → match
4. Non-crossed book (bid below ask) → no match
5. Best bid updates to a new higher-index bid → still no match while non-crossed
6. New ask crosses the updated best bid → match
7. Exact price touch (`bid_idx == ask_idx`) → match, since matching uses `>=`

## Future Work

- Price-time priority (currently just price-priority)
- Cancel/modify order support (currently add-only)
- Configurable tick size / price-to-index mapping
- Order quantity depletion on match (currently match detection only, no quantity decrement)
