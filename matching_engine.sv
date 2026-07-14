module matching_engine #(
        parameter NUM_LEVELS = 64,
        parameter QTY_WIDTH  = 16)
    (
        input logic [$clog2(NUM_LEVELS)-1:0]     best_bid_idx,
        input logic                              best_bid_valid,
        input logic [$clog2(NUM_LEVELS)-1:0]     best_ask_idx,
        input logic                              best_ask_valid,

        input logic [QTY_WIDTH-1:0]  bid_qty_levels [NUM_LEVELS],
        input logic [QTY_WIDTH-1:0]  ask_qty_levels [NUM_LEVELS],

        output logic                              match_valid,
        output logic [$clog2(NUM_LEVELS)-1:0]     match_bid_idx,
        output logic [$clog2(NUM_LEVELS)-1:0]     match_ask_idx,
        output logic [QTY_WIDTH-1:0]       match_qty
    );

    always_comb begin
        match_valid = '0;
        match_bid_idx = '0;
        match_ask_idx = '0;
        if (best_ask_valid && best_bid_valid && best_bid_idx >= best_ask_idx) begin
            match_valid = 1'b1;
            match_bid_idx = best_bid_idx;
            match_ask_idx = best_ask_idx;
            match_qty = (bid_qty_levels[best_bid_idx] < ask_qty_levels[best_ask_idx]) ? bid_qty_levels[best_bid_idx] : ask_qty_levels[best_ask_idx];
        end
    end

endmodule