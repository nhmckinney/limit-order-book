module price_level_array #(
    parameter NUM_LEVELS          = 64,
    parameter QTY_WIDTH            = 16,
    parameter ORDER_ID_WIDTH       = 16,
    parameter MAX_ORDERS_PER_LEVEL = 8)
(
    input  logic clk,
    input  logic rst_n,

    // Write port (ADD order) - pushes a new resting order to the tail
    // of the FIFO at add_price_idx. Ignored (see add_reject) if that
    // level's FIFO is already full.
    input  logic add_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0]      add_price_idx,
    input  logic [ORDER_ID_WIDTH-1:0]          add_order_id,
    input  logic [QTY_WIDTH-1:0]               add_qty,
    output logic                                add_reject,

    // Match/decrement port - fills against the order at the head of the
    // FIFO at sub_price_idx (price-time priority: oldest order first)
    input  logic sub_valid,
    input  logic [$clog2(NUM_LEVELS)-1:0]      sub_price_idx,
    input  logic [QTY_WIDTH-1:0]               sub_qty,

    // combinational aggregate output array (sum of resting qty per level)
    output logic [QTY_WIDTH-1:0]   qty_levels [NUM_LEVELS],

    // head-of-book order exposed per level, for matching/cancel logic
    output logic [ORDER_ID_WIDTH-1:0]          head_order_id [NUM_LEVELS],
    output logic [QTY_WIDTH-1:0]                head_order_qty [NUM_LEVELS],
    output logic                                head_order_valid [NUM_LEVELS],

    // per-level FIFO occupancy, exposed for backpressure / debug
    output logic                                level_full [NUM_LEVELS]
);

    localparam SLOT_W   = $clog2(MAX_ORDERS_PER_LEVEL);
    localparam COUNT_W  = $clog2(MAX_ORDERS_PER_LEVEL+1);

    logic [ORDER_ID_WIDTH-1:0] order_id [NUM_LEVELS][MAX_ORDERS_PER_LEVEL];
    logic [QTY_WIDTH-1:0]      order_qty[NUM_LEVELS][MAX_ORDERS_PER_LEVEL];
    logic                      order_valid[NUM_LEVELS][MAX_ORDERS_PER_LEVEL];

    logic [SLOT_W-1:0]  head_ptr [NUM_LEVELS];
    logic [SLOT_W-1:0]  tail_ptr [NUM_LEVELS];
    logic [COUNT_W-1:0] count    [NUM_LEVELS];

    assign add_reject = add_valid && (count[add_price_idx] == MAX_ORDERS_PER_LEVEL);

    always_comb begin
        for (int i = 0; i < NUM_LEVELS; i++) begin
            head_order_id[i]    = order_id[i][head_ptr[i]];
            head_order_qty[i]   = order_qty[i][head_ptr[i]];
            head_order_valid[i] = order_valid[i][head_ptr[i]];
            level_full[i]       = (count[i] == MAX_ORDERS_PER_LEVEL);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_LEVELS; i++) begin
                qty_levels[i] <= '0;
                head_ptr[i]   <= '0;
                tail_ptr[i]   <= '0;
                count[i]      <= '0;
                for (int s = 0; s < MAX_ORDERS_PER_LEVEL; s++) begin
                    order_valid[i][s] <= 1'b0;
                    order_qty[i][s]   <= '0;
                    order_id[i][s]    <= '0;
                end
            end
        end else begin
            if (add_valid && count[add_price_idx] != MAX_ORDERS_PER_LEVEL) begin
                order_id[add_price_idx][tail_ptr[add_price_idx]]    <= add_order_id;
                order_qty[add_price_idx][tail_ptr[add_price_idx]]   <= add_qty;
                order_valid[add_price_idx][tail_ptr[add_price_idx]] <= 1'b1;
                tail_ptr[add_price_idx] <= tail_ptr[add_price_idx] + 1'b1;
                count[add_price_idx]    <= count[add_price_idx] + 1'b1;
                qty_levels[add_price_idx] <= qty_levels[add_price_idx] + add_qty;
            end

            if (sub_valid) begin
                if (order_qty[sub_price_idx][head_ptr[sub_price_idx]] == sub_qty) begin
                    order_valid[sub_price_idx][head_ptr[sub_price_idx]] <= 1'b0;
                    order_qty[sub_price_idx][head_ptr[sub_price_idx]]   <= '0;
                    head_ptr[sub_price_idx] <= head_ptr[sub_price_idx] + 1'b1;
                    count[sub_price_idx]    <= count[sub_price_idx] - 1'b1;
                end else begin
                    order_qty[sub_price_idx][head_ptr[sub_price_idx]] <=
                        order_qty[sub_price_idx][head_ptr[sub_price_idx]] - sub_qty;
                end
                qty_levels[sub_price_idx] <= qty_levels[sub_price_idx] - sub_qty;
            end
        end
    end

endmodule
