module priority_encoder_ask #(
    parameter NUM_LEVELS = 64,
    parameter QTY_WIDTH  = 16)
(
    input  logic [QTY_WIDTH-1:0]              qty_levels [NUM_LEVELS],

    output logic [$clog2(NUM_LEVELS)-1:0]     best_ask_idx,
    output logic                              best_ask_valid
);

    always_comb begin
        best_ask_valid = 1'b0;
        best_ask_idx = 0;
        for (int i = NUM_LEVELS-1; i >= 0; i--) begin
            if (qty_levels[i] != '0) begin
                best_ask_valid = 1'b1;
                best_ask_idx = i;
            end
        end
    end
endmodule
