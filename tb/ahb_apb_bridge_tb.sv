
`timescale 1ns/1ps

module ahb_apb_bridge_tb;

    logic hclk;
    logic hresetn;

    logic [31:0] haddr;
    logic [31:0] hwdata;
    logic hwrite;
    logic [2:0] hsize;
    logic [2:0] hburst;
    logic [1:0] htrans;
    logic hready;
    logic hsel;
    logic [3:0] hprot;

    logic [31:0] hrdata;
    logic hreadyout;
    logic hresp;

    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic pwrite;
    logic [3:0] pstrb;
    logic psel;
    logic penable;
    logic [2:0] pprot;

    logic [31:0] prdata;
    logic pready;
    logic pslverr;

    ahb_apb_bridge dut (
        .hclk(hclk),
        .hresetn(hresetn),
        .haddr(haddr),
        .hwdata(hwdata),
        .hwrite(hwrite),
        .hsize(hsize),
        .hburst(hburst),
        .htrans(htrans),
        .hready(hready),
        .hsel(hsel),
        .hprot(hprot),

        .hrdata(hrdata),
        .hreadyout(hreadyout),
        .hresp(hresp),

        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .pstrb(pstrb),
        .psel(psel),
        .penable(penable),
        .pprot(pprot),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)
    );
assign hready = hreadyout;
initial hclk = 1'b0;
always #5 hclk = ~hclk;

logic [31:0] prev_paddr;
logic [31:0] prev_pwdata;
logic prev_pwrite;
logic [3:0] prev_pstrb;
logic prev_wait;
always @(posedge hclk) begin
    if (hresetn) begin
        // ACCESS must always follow SETUP or remain in ACCESS.
        if (penable && !psel)
            $error("APB protocol violation: PENABLE=1 while PSEL=0");

        // PSTRB must be zero for reads.
        if (psel && !pwrite && pstrb !== 4'b0000)
            $error("APB protocol violation: PSTRB must be zero for reads");

        // ACCESS must remain active while the peripheral waits.
        if (psel && penable && !pready) begin
            $display("APB wait state observed at time %0t", $time);
        end
        if (prev_wait) begin
    if (psel !== 1'b1 || penable !== 1'b1 ||
        paddr !== prev_paddr ||
        pwrite !== prev_pwrite ||
        pwdata !== prev_pwdata ||
        pstrb !== prev_pstrb)
        $error("APB signals changed during a wait state");
end

prev_wait  <= psel && penable && !pready;
prev_paddr <= paddr;
prev_pwdata <= pwdata;
prev_pwrite <= pwrite;
prev_pstrb <= pstrb;
    end
    else begin 
        prev_wait   <= 1'b0;
prev_paddr  <= '0;
prev_pwdata <= '0;
prev_pwrite <= 1'b0;
prev_pstrb  <= '0;
    end
end



initial begin
    hresetn = 1'b0;

    haddr   = 32'b0;
    hwdata  = 32'b0;
    hwrite  = 1'b0;
    hsize   = 3'b010;
    hburst  = 3'b000;
    htrans  = 2'b00;
   // hready  = 1'b1;
    hsel    = 1'b0;
    hprot   = 4'b0011;

    prdata  = 32'b0;
    pready  = 1'b0;
    pslverr = 1'b0;

    repeat (2) @(posedge hclk);
    @(negedge hclk);
    hresetn = 1'b1;

    $display("Reset released at time %0t", $time);


    // AHB write transaction
    @(negedge hclk);
    hsel   = 1'b1;
    htrans = 2'b10;       // NONSEQ
    haddr  = 32'h00001000;
    hwrite = 1'b1;
    hsize  = 3'b010;      // Word transfer
    hburst = 3'b000;      // SINGLE
    //hready = 1'b1;

    // Allow the bridge to capture the address
    @(negedge hclk);
    hsel   = 1'b0;
    htrans = 2'b00;       // IDLE
    hwdata = 32'hABCD1234;

    // Wait for APB SETUP
    wait (psel == 1'b1);
    #1;
    $display("APB SETUP: PADDR=%h PWRITE=%b PSTRB=%b",
             paddr, pwrite, pstrb);

    // Wait for APB ACCESS
    wait (penable == 1'b1);
    #1;
    $display("APB ACCESS: PADDR=%h PWDATA=%h PWRITE=%b PSTRB=%b",
             paddr, pwdata, pwrite, pstrb);
    
    if (paddr !== 32'h00001000 ||
    pwdata !== 32'hABCD1234 ||
    pwrite !== 1'b1 ||
    pstrb !== 4'b1111)
    $error("FAIL: First APB write data/control mismatch");
    else
    $display("PASS: First APB write data/control correct");

    
    // Complete first write
    @(negedge hclk);
    pready = 1'b1;
    @(negedge hclk);
    pready = 1'b0;

    // Start second write
    hsel   = 1'b1;
    htrans = 2'b10;
    haddr  = 32'h00001004;
    hwrite = 1'b1;
    hsize  = 3'b010;
    hwdata = 32'hDEADBEEF;

    @(negedge hclk);
    hsel   = 1'b0;
    htrans = 2'b00;

    // Wait for APB ACCESS
    wait (penable == 1'b1);
    #1;
    $display("Wait-state test begins: PADDR=%h", paddr);
    if (paddr !== 32'h00001004 ||
    pwdata !== 32'hDEADBEEF ||
    pwrite !== 1'b1 ||
    pstrb !== 4'b1111)
    $error("FAIL: Second APB write data/control mismatch");
else
    $display("PASS: Second APB write data/control correct");
    // PREADY remains low for three cycles
    repeat (3) begin
        @(negedge hclk);
        $display("Wait: PSEL=%b PENABLE=%b HREADYOUT=%b",
                 psel, penable, hreadyout);
    end

    // Complete second write
    pready = 1'b1;
    @(negedge hclk);
    $display("Wait-state test complete: HREADYOUT=%b", hreadyout);
    pready = 1'b0;


    // AHB read transaction
    @(negedge hclk);
    hsel    = 1'b1;
    htrans  = 2'b10;          // NONSEQ
    haddr   = 32'h00001008;
    hwrite  = 1'b0;           // Read
    hsize   = 3'b010;         // Word
    hburst  = 3'b000;         // SINGLE
    //hready  = 1'b1;
    prdata  = 32'hCAFE_BABE;
    pslverr = 1'b1;
    pready  = 1'b0;

    // Address phase accepted
    @(negedge hclk);
    hsel   = 1'b0;
    htrans = 2'b00;           // IDLE
    // Wait for APB ACCESS
    wait (penable == 1'b1);
    #1;
    $display("Read ACCESS: PADDR=%h PWRITE=%b",
             paddr, pwrite);

    // Complete the APB read
    @(negedge hclk);
    pready = 1'b1;

    // Allow the completion clock edge to occur
    @(posedge hclk);
    #1;
    $display("Read result: HRDATA=%h HRESP=%b",
             hrdata, hresp);

    if (hrdata !== 32'hCAFE_BABE)
        $error("FAIL: HRDATA expected CAFE_BABE");
    else
        $display("PASS: HRDATA matches CAFE_BABE");

    
if (hresp !== 1'b1)
    $error("FAIL: HRESP expected 1 for APB error");
else
    $display("PASS: HRESP correctly indicates APB error");


    @(negedge hclk);
    pready = 1'b0;


    #10;
    $finish;



end


endmodule
