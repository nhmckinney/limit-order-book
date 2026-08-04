`timescale 1ns/1ps

module tb();

    localparam NUM_LEVELS          = 64;
    localparam QTY_WIDTH            = 16;
    localparam ORDER_ID_WIDTH       = 16;
    localparam MAX_ORDERS_PER_LEVEL = 4;
    localparam IDX_W      = $clog2(NUM_LEVELS);
    localparam OID_W      = ORDER_ID_WIDTH;

    logic clk, rst_n;

    logic                bid_add_valid;
    logic [IDX_W-1:0]    bid_add_price_idx;
    logic [OID_W-1:0]    bid_add_order_id;
    logic [QTY_WIDTH-1:0] bid_add_qty;
    logic                bid_add_reject;

    logic                ask_add_valid;
    logic [IDX_W-1:0]    ask_add_price_idx;
    logic [OID_W-1:0]    ask_add_order_id;
    logic [QTY_WIDTH-1:0] ask_add_qty;
    logic                ask_add_reject;

    logic                  match_valid;
    logic [IDX_W-1:0]      match_bid_idx;
    logic [IDX_W-1:0]      match_ask_idx;
    logic [QTY_WIDTH-1:0]  match_qty;

    int errors = 0;
    int checks = 0;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    lob_top #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH),
        .ORDER_ID_WIDTH(ORDER_ID_WIDTH),
        .MAX_ORDERS_PER_LEVEL(MAX_ORDERS_PER_LEVEL)
    ) dut (
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

 
    always #5 clk = ~clk; //10ns clock period

    // ---------------------------------------------------------------
    // Helper tasks
    // ---------------------------------------------------------------
    task automatic reset_dut();
        rst_n = 1'b0;
        bid_add_valid = 1'b0;
        ask_add_valid = 1'b0;
        bid_add_price_idx = '0;
        ask_add_price_idx = '0;
        bid_add_order_id = '0;
        ask_add_order_id = '0;
        bid_add_qty = '0;
        ask_add_qty = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
    endtask

    task automatic add_bid(input [IDX_W-1:0] idx, input [OID_W-1:0] oid, input [QTY_WIDTH-1:0] qty);
        @(negedge clk);
        bid_add_valid     = 1'b1;
        bid_add_price_idx = idx;
        bid_add_order_id  = oid;
        bid_add_qty       = qty;
        @(posedge clk);
        @(negedge clk);
        bid_add_valid = 1'b0;
    endtask

    task automatic add_bid_check_reject(input [IDX_W-1:0] idx, input [OID_W-1:0] oid, input [QTY_WIDTH-1:0] qty,
                                        output logic reject);
        @(negedge clk);
        bid_add_valid     = 1'b1;
        bid_add_price_idx = idx;
        bid_add_order_id  = oid;
        bid_add_qty       = qty;
        @(posedge clk);
        reject = bid_add_reject;
        @(negedge clk);
        bid_add_valid = 1'b0;
    endtask

    task automatic add_ask(input [IDX_W-1:0] idx, input [OID_W-1:0] oid, input [QTY_WIDTH-1:0] qty);
        @(negedge clk);
        ask_add_valid     = 1'b1;
        ask_add_price_idx = idx;
        ask_add_order_id  = oid;
        ask_add_qty       = qty;
        @(posedge clk);
        @(negedge clk);
        ask_add_valid = 1'b0;
    endtask

    task automatic check(input string name,
                          input logic exp_match_valid,
                          input [IDX_W-1:0] exp_bid_idx,
                          input [IDX_W-1:0] exp_ask_idx);
        checks++;
        if (match_valid !== exp_match_valid) begin
            errors++;
            $display("[FAIL] %s: match_valid = %0b, expected %0b",
                      name, match_valid, exp_match_valid);
        end else if (exp_match_valid && (match_bid_idx !== exp_bid_idx || match_ask_idx !== exp_ask_idx)) begin
            errors++;
            $display("[FAIL] %s: match_bid_idx=%0d match_ask_idx=%0d, expected bid=%0d ask=%0d",
                      name, match_bid_idx, match_ask_idx, exp_bid_idx, exp_ask_idx);
        end else begin
            $display("[PASS] %s", name);
        end
    endtask

    // ---------------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------------
    initial begin
        clk = 1'b0;

        $dumpfile("lob_sim.vcd");
        $dumpvars(0, tb);

        reset_dut();

        // Test 1: empty book -> no match
        @(posedge clk);
        check("empty book: no match", 1'b0, '0, '0);

        // Test 2: single bid, no ask -> no match
        add_bid(10, 1, 100);
        @(posedge clk);
        check("bid only: no match", 1'b0, '0, '0);

        // Test 3: add ask below the bid -> should cross and match
        // (bid idx 10, ask idx 5 -> best_bid_idx(10) >= best_ask_idx(5))
        add_ask(5, 2, 50);
        @(posedge clk);
        check("crossed book: match", 1'b1, 10, 5);

        // Test 4: reset, then add non-crossing book -> no match
        reset_dut();
        add_bid(5, 3, 20);
        add_ask(10, 4, 20);
        @(posedge clk);
        check("non-crossed book: no match", 1'b0, '0, '0);

        // Test 5: add another bid at a higher index (but still below the resting
        // ask at idx 10) -> best bid should track the max index, still non-crossed
        add_bid(8, 5, 30);
        @(posedge clk);
        check("higher bid still non-crossed", 1'b0, '0, '0);

        // Test 6: now push an ask down to cross with the new best bid (idx 8)
        add_ask(6, 6, 5);
        @(posedge clk);
        check("second ask crosses new best bid", 1'b1, 8, 6);

        // Test 7: exact touch (bid_idx == ask_idx) should count as a match ('>=')
        reset_dut();
        add_bid(30, 7, 10);
        add_ask(30, 8, 10);
        @(posedge clk);
        check("exact touch: match", 1'b1, 30, 30);

        // ---------------------------------------------------------------
        // Test 8: FIFO price-time priority within a level.
        // Two resting bids at idx 40: order 100 (qty 10) added first,
        // then order 101 (qty 5). A partial-filling ask should drain
        // order 100 first (head of FIFO) before touching order 101.
        // ---------------------------------------------------------------
        reset_dut();
        add_bid(40, 100, 10);
        add_bid(40, 101, 5);
        @(posedge clk);
        checks++;
        if (dut.bid_head_order_id[40] !== 16'd100 || dut.bid_head_order_qty[40] !== 16'd10) begin
            errors++;
            $display("[FAIL] fifo head before fill: id=%0d qty=%0d, expected id=100 qty=10",
                      dut.bid_head_order_id[40], dut.bid_head_order_qty[40]);
        end else begin
            $display("[PASS] fifo head before fill");
        end

        // ask for 4 shares crosses idx 40, partially filling order 100
        add_ask(40, 200, 4);
        @(posedge clk);
        check("fifo partial fill: match", 1'b1, 40, 40);
        @(posedge clk); // wait for the registered decrement to land
        checks++;
        if (dut.bid_head_order_id[40] !== 16'd100 || dut.bid_head_order_qty[40] !== 16'd6) begin
            errors++;
            $display("[FAIL] fifo head after partial fill: id=%0d qty=%0d, expected id=100 qty=6",
                      dut.bid_head_order_id[40], dut.bid_head_order_qty[40]);
        end else begin
            $display("[PASS] fifo head after partial fill");
        end

        // ask for 6 more shares fully drains order 100 (qty 6) -> head becomes order 101
        add_ask(40, 201, 6);
        @(posedge clk);
        check("fifo drain head order: match", 1'b1, 40, 40);
        @(posedge clk); // wait for the registered decrement/pop to land
        checks++;
        if (dut.bid_head_order_id[40] !== 16'd101 || dut.bid_head_order_qty[40] !== 16'd5) begin
            errors++;
            $display("[FAIL] fifo head after drain: id=%0d qty=%0d, expected id=101 qty=5",
                      dut.bid_head_order_id[40], dut.bid_head_order_qty[40]);
        end else begin
            $display("[PASS] fifo head after drain (advanced to next order)");
        end

        // ---------------------------------------------------------------
        // Test 9: level_full / add_reject when MAX_ORDERS_PER_LEVEL is exceeded.
        // ---------------------------------------------------------------
        reset_dut();
        add_bid(50, 300, 1);
        add_bid(50, 301, 1);
        add_bid(50, 302, 1);
        add_bid(50, 303, 1); // fills all MAX_ORDERS_PER_LEVEL=4 slots
        @(posedge clk);
        checks++;
        if (dut.bid_level_full[50] !== 1'b1) begin
            errors++;
            $display("[FAIL] level_full not asserted after filling all slots");
        end else begin
            $display("[PASS] level_full asserted after filling all slots");
        end

        begin
            logic reject5;
            add_bid_check_reject(50, 304, 1, reject5); // 5th order should be rejected
            checks++;
            if (reject5 !== 1'b1) begin
                errors++;
                $display("[FAIL] bid_add_reject not asserted when level is full");
            end else begin
                $display("[PASS] bid_add_reject asserted when level is full");
            end
        end

        @(posedge clk);
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d CHECKS PASSED", checks);
        else
            $display("%0d of %0d CHECKS FAILED", errors, checks);
        $display("--------------------------------------------------");

        $finish;
    end

    // Safety timeout
    initial begin
        #2000;
        $display("[TIMEOUT] Simulation did not finish in time");
        $finish;
    end

endmodule