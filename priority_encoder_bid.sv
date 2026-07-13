module priority_encoder_bid #(
    parameter NUM_LEVELS = 64,
    parameter QTY_WIDTH  = 16)
(
    input  logic [QTY_WIDTH-1:0]              qty_levels [NUM_LEVELS],

    output logic [$clog2(NUM_LEVELS)-1:0]     best_bid_idx,
    output logic                              best_bid_valid
);

    // YOUR CODE HERE

endmodule
