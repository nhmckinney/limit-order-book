/// Basys3 top-level for the limit order book.
///
/// LEDs remain a pure switch passthrough (led = sw), unchanged from the
/// original test module. The LOB is instantiated alongside it, driven by
/// switches/button for a simple manual "add order" demo:
///
///   sw[15]  = side select (0 = bid, 1 = ask)
///   sw[3:0] = add_price_idx (NUM_LEVELS = 16, so 4 bits is exact)
///   btnC    = add trigger (debounced, rising-edge one-shot -> add_valid pulse)
///
/// add_qty is fixed at 1 and add_order_id free-runs from an internal
/// counter, incremented once per accepted add, so each press adds a
/// distinct single-share order at the selected price level/side.
module basys_top (
    input  logic        clk,
    input  logic         rst_n,
    input  logic [15:0]  sw,
    input  logic         btnC,
    output logic [15:0]  led
);

    localparam NUM_LEVELS          = 16;
    localparam QTY_WIDTH            = 16;
    localparam ORDER_ID_WIDTH       = 16;
    localparam MAX_ORDERS_PER_LEVEL = 8;
    localparam IDX_W                = $clog2(NUM_LEVELS);

    // LEDs stay a pure switch passthrough.
    assign led = sw;

    // ---------------------------------------------------------------
    // Debounce + rising-edge one-shot on btnC -> single add_valid pulse
    // per physical button press.
    // ---------------------------------------------------------------
    logic btn_sync0, btn_sync1;
    logic btn_stable, btn_prev;
    logic [15:0] debounce_ctr;
    logic add_pulse;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync0    <= 1'b0;
            btn_sync1    <= 1'b0;
            btn_stable   <= 1'b0;
            btn_prev     <= 1'b0;
            debounce_ctr <= '0;
            add_pulse    <= 1'b0;
        end else begin
            // 2-flop synchronizer for the async button input
            btn_sync0 <= btnC;
            btn_sync1 <= btn_sync0;

            // simple debounce: only accept a new stable value once the
            // synchronized signal has held steady for the full counter
            if (btn_sync1 == btn_stable) begin
                debounce_ctr <= '0;
            end else if (debounce_ctr == 16'hFFFF) begin
                btn_stable   <= btn_sync1;
                debounce_ctr <= '0;
            end else begin
                debounce_ctr <= debounce_ctr + 1'b1;
            end

            btn_prev  <= btn_stable;
            add_pulse <= btn_stable && !btn_prev; // rising edge -> one-shot
        end
    end

    // ---------------------------------------------------------------
    // Order id generator: increments once per accepted add so that
    // consecutive button presses create distinct resting orders.
    // ---------------------------------------------------------------
    logic [ORDER_ID_WIDTH-1:0] next_order_id;
    logic                      side_is_ask;
    logic                      add_accepted;

    assign side_is_ask = sw[15];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_order_id <= '0;
        end else if (add_accepted) begin
            next_order_id <= next_order_id + 1'b1;
        end
    end

    // ---------------------------------------------------------------
    // LOB instantiation
    // ---------------------------------------------------------------
    logic                    bid_add_valid, ask_add_valid;
    logic [IDX_W-1:0]        bid_add_price_idx, ask_add_price_idx;
    logic [ORDER_ID_WIDTH-1:0] bid_add_order_id, ask_add_order_id;
    logic [QTY_WIDTH-1:0]    bid_add_qty, ask_add_qty;
    logic                    bid_add_reject, ask_add_reject;

    logic                    match_valid;
    logic [IDX_W-1:0]        match_bid_idx, match_ask_idx;
    logic [QTY_WIDTH-1:0]    match_qty;

    assign bid_add_valid     = add_pulse && !side_is_ask;
    assign ask_add_valid     = add_pulse && side_is_ask;
    assign bid_add_price_idx = sw[IDX_W-1:0];
    assign ask_add_price_idx = sw[IDX_W-1:0];
    assign bid_add_order_id  = next_order_id;
    assign ask_add_order_id  = next_order_id;
    assign bid_add_qty       = QTY_WIDTH'(1);
    assign ask_add_qty       = QTY_WIDTH'(1);

    // an add is "accepted" (advances the order-id counter) only if the
    // targeted level's FIFO wasn't full at the moment of the pulse
    assign add_accepted = (bid_add_valid && !bid_add_reject) ||
                           (ask_add_valid && !ask_add_reject);

    lob_top #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH),
        .ORDER_ID_WIDTH(ORDER_ID_WIDTH),
        .MAX_ORDERS_PER_LEVEL(MAX_ORDERS_PER_LEVEL)
    ) lob (
        .clk(clk),
        .rst_n(rst_n),
        .bid_add_valid(bid_add_valid),
        .bid_add_price_idx(bid_add_price_idx),
        .bid_add_order_id(bid_add_order_id),
        .bid_add_qty(bid_add_qty),
        .bid_add_reject(bid_add_reject),
        .ask_add_valid(ask_add_valid),
        .ask_add_price_idx(ask_add_price_idx),
        .ask_add_order_id(ask_add_order_id),
        .ask_add_qty(ask_add_qty),
        .ask_add_reject(ask_add_reject),
        .match_valid(match_valid),
        .match_bid_idx(match_bid_idx),
        .match_ask_idx(match_ask_idx),
        .match_qty(match_qty)
    );

endmodule
