module price_level_array #(
    parameter NUM_LEVELS = 64,
    parameter QTY_WIDTH  = 16)
(
    input  logic clk,
    input  logic rst_n,

    // Write port (ADD order)
    input  logic add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] add_price_idx,
    input  logic [QTY_WIDTH-1:0]   add_qty,

    input  logic sub_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0] sub_price_idx,
    input  logic [QTY_WIDTH-1:0]   sub_qty,

    // combinational output array
    output logic [QTY_WIDTH-1:0]   qty_levels [NUM_LEVELS]
);

    always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < NUM_LEVELS; i++) begin
            qty_levels[i] <= '0;
        end
    end else begin
            if (add_valid) begin
                qty_levels[add_price_idx] <= qty_levels[add_price_idx] + add_qty;
            end
            if (sub_valid) begin
                qty_levels[sub_price_idx] <= qty_levels[sub_price_idx] - sub_qty;
            end
    end
end

endmodule
