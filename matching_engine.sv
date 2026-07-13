module matching_engine #(
    parameter NUM_LEVELS = 64)
(
    input logic [$clog2(NUM_LEVELS)-1:0]     best_bid_idx,
    input logic                              best_bid_valid,
    input logic [$clog2(NUM_LEVELS)-1:0]     best_ask_idx,
    input logic                              best_ask_valid,

    output logic                              match_valid,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_bid_idx,
    output logic [$clog2(NUM_LEVELS)-1:0]     match_ask_idx
);

always_comb begin
    match_valid = '0;
    match_bid_idx = '0;
    match_ask_idx = '0;
    if (best_ask_valid && best_bid_valid && best_bid_idx >= best_ask_idx) begin
        match_valid = 1'b1;
        match_bid_idx = best_bid_idx;
        match_ask_idx = best_ask_idx;
    end
end

endmodule