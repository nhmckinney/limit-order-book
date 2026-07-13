module lob_top #(
    parameter NUM_LEVELS = 64,
    parameter QTY_WIDTH  = 16) 
    (
    input logic clk, rst_n,

    //bid price level array inputs
    input  logic bid_add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] bid_add_price_idx,
    input  logic [QTY_WIDTH-1:0]   bid_add_qty,

    //ask price level array inputs
    input  logic ask_add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] ask_add_price_idx,
    input  logic [QTY_WIDTH-1:0]  ask_add_qty,

    output logic                              match_valid,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_bid_idx,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_ask_idx
);
    
    logic [QTY_WIDTH-1:0]  bid_qty_levels [NUM_LEVELS];
    logic [QTY_WIDTH-1:0]  ask_qty_levels [NUM_LEVELS];

    logic [$clog2(NUM_LEVELS)-1:0] best_bid_idx, best_ask_idx;
    logic                          best_bid_valid, best_ask_valid;


    matching_engine me(.*);

    price_level_array bidPLA(.add_valid(bid_add_valid), 
                             .add_price_idx(bid_add_price_idx),
                             .add_qty(bid_add_qty),
                             .qty_levels(bid_qty_levels),.*);

    price_level_array askPLA(.add_valid(ask_add_valid), 
                             .add_price_idx(ask_add_price_idx),
                             .add_qty(ask_add_qty),
                             .qty_levels(ask_qty_levels),.*);


   
    priority_encoder_bid peb(.qty_levels(bid_qty_levels),.*);
    priority_encoder_ask pea(.qty_levels(ask_qty_levels),.*);
    
endmodule
