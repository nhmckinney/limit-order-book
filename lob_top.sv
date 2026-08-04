module lob_top #(
    parameter NUM_LEVELS          = 64,
    parameter QTY_WIDTH            = 16,
    parameter ORDER_ID_WIDTH       = 16,
    parameter MAX_ORDERS_PER_LEVEL = 8)
    (
    input logic clk, rst_n,

    //bid price level array inputs
    input  logic bid_add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] bid_add_price_idx,
    input  logic [ORDER_ID_WIDTH-1:0]     bid_add_order_id,
    input  logic [QTY_WIDTH-1:0]   bid_add_qty,
    output logic                    bid_add_reject,

    //ask price level array inputs
    input  logic ask_add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] ask_add_price_idx,
    input  logic [ORDER_ID_WIDTH-1:0]     ask_add_order_id,
    input  logic [QTY_WIDTH-1:0]  ask_add_qty,
    output logic                    ask_add_reject,

    output logic                              match_valid,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_bid_idx,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_ask_idx,
    output logic [QTY_WIDTH-1:0]       match_qty
);

    logic [QTY_WIDTH-1:0]  bid_qty_levels [NUM_LEVELS];
    logic [QTY_WIDTH-1:0]  ask_qty_levels [NUM_LEVELS];

    logic [$clog2(NUM_LEVELS)-1:0] best_bid_idx, best_ask_idx;
    logic                          best_bid_valid, best_ask_valid;

    logic [ORDER_ID_WIDTH-1:0] bid_head_order_id [NUM_LEVELS];
    logic [QTY_WIDTH-1:0]      bid_head_order_qty [NUM_LEVELS];
    logic                      bid_head_order_valid [NUM_LEVELS];
    logic                      bid_level_full [NUM_LEVELS];

    logic [ORDER_ID_WIDTH-1:0] ask_head_order_id [NUM_LEVELS];
    logic [QTY_WIDTH-1:0]      ask_head_order_qty [NUM_LEVELS];
    logic                      ask_head_order_valid [NUM_LEVELS];
    logic                      ask_level_full [NUM_LEVELS];


    matching_engine #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH)
    ) me (.*);

    price_level_array #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH),
        .ORDER_ID_WIDTH(ORDER_ID_WIDTH),
        .MAX_ORDERS_PER_LEVEL(MAX_ORDERS_PER_LEVEL)
    ) bidPLA (
                             .add_valid(bid_add_valid),
                             .add_price_idx(bid_add_price_idx),
                             .add_order_id(bid_add_order_id),
                             .add_qty(bid_add_qty),
                             .add_reject(bid_add_reject),
                             .sub_valid(match_valid),
                             .sub_price_idx(match_bid_idx),
                             .sub_qty(match_qty),
                             .qty_levels(bid_qty_levels),
                             .head_order_id(bid_head_order_id),
                             .head_order_qty(bid_head_order_qty),
                             .head_order_valid(bid_head_order_valid),
                             .level_full(bid_level_full),
                             .*);

    price_level_array #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH),
        .ORDER_ID_WIDTH(ORDER_ID_WIDTH),
        .MAX_ORDERS_PER_LEVEL(MAX_ORDERS_PER_LEVEL)
    ) askPLA (
                             .add_valid(ask_add_valid),
                             .add_price_idx(ask_add_price_idx),
                             .add_order_id(ask_add_order_id),
                             .add_qty(ask_add_qty),
                             .add_reject(ask_add_reject),
                             .sub_valid(match_valid),
                             .sub_price_idx(match_ask_idx),
                             .sub_qty(match_qty),
                             .qty_levels(ask_qty_levels),
                             .head_order_id(ask_head_order_id),
                             .head_order_qty(ask_head_order_qty),
                             .head_order_valid(ask_head_order_valid),
                             .level_full(ask_level_full),
                             .*);


   
    priority_encoder_bid #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH)
    ) peb (.qty_levels(bid_qty_levels),.*);

    priority_encoder_ask #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH)
    ) pea (.qty_levels(ask_qty_levels),.*);


    
endmodule
