`timescale 1ns/1ps

module tb();

    localparam NUM_LEVELS = 64;
    localparam QTY_WIDTH  = 16;
    localparam IDX_W      = $clog2(NUM_LEVELS);

    logic clk, rst_n;

    logic                bid_add_valid;
    logic [IDX_W-1:0]    bid_add_price_idx;
    logic [QTY_WIDTH-1:0] bid_add_qty;

    logic                ask_add_valid;
    logic [IDX_W-1:0]    ask_add_price_idx;
    logic [QTY_WIDTH-1:0] ask_add_qty;

    logic                match_valid;
    logic [IDX_W-1:0]    match_bid_idx;
    logic [IDX_W-1:0]    match_ask_idx;

    int errors = 0;
    int checks = 0;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    lob_top #(
        .NUM_LEVELS(NUM_LEVELS),
        .QTY_WIDTH(QTY_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .bid_add_valid(bid_add_valid),
        .bid_add_price_idx(bid_add_price_idx),
        .bid_add_qty(bid_add_qty),
        .ask_add_valid(ask_add_valid),
        .ask_add_price_idx(ask_add_price_idx),
        .ask_add_qty(ask_add_qty),
        .match_valid(match_valid),
        .match_bid_idx(match_bid_idx),
        .match_ask_idx(match_ask_idx)
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
        bid_add_qty = '0;
        ask_add_qty = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
    endtask

    task automatic add_bid(input [IDX_W-1:0] idx, input [QTY_WIDTH-1:0] qty);
        @(negedge clk);
        bid_add_valid     = 1'b1;
        bid_add_price_idx = idx;
        bid_add_qty       = qty;
        @(posedge clk);
        @(negedge clk);
        bid_add_valid = 1'b0;
    endtask

    task automatic add_ask(input [IDX_W-1:0] idx, input [QTY_WIDTH-1:0] qty);
        @(negedge clk);
        ask_add_valid     = 1'b1;
        ask_add_price_idx = idx;
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
        add_bid(10, 100);
        @(posedge clk);
        check("bid only: no match", 1'b0, '0, '0);

        // Test 3: add ask below the bid -> should cross and match
        // (bid idx 10, ask idx 5 -> best_bid_idx(10) >= best_ask_idx(5))
        add_ask(5, 50);
        @(posedge clk);
        check("crossed book: match", 1'b1, 10, 5);

        // Test 4: reset, then add non-crossing book -> no match
        reset_dut();
        add_bid(5, 20);
        add_ask(10, 20);
        @(posedge clk);
        check("non-crossed book: no match", 1'b0, '0, '0);

        // Test 5: add another bid at a higher index -> best bid should track max index
        add_bid(20, 30);
        @(posedge clk);
        check("higher bid still non-crossed", 1'b0, '0, '0);

        // Test 6: now push an ask down to cross with the new best bid (idx 20)
        add_ask(15, 5);
        @(posedge clk);
        check("second ask crosses new best bid", 1'b1, 20, 10);

        // Test 7: exact touch (bid_idx == ask_idx) should count as a match ('>=')
        reset_dut();
        add_bid(30, 10);
        add_ask(30, 10);
        @(posedge clk);
        check("exact touch: match", 1'b1, 30, 30);

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