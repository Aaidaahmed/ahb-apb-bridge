module ahb_interface_tb;
//tb drives them
logic hclk;
logic hresetn;
logic [31:0]haddr;
logic [31:0]hwdata;
logic hwrite;
logic [2:0]hsize;
logic [2:0]hburst;
logic [1:0]htrans;
//dut drives them
logic valid_trans;
logic [31:0]addr;
logic [31:0]data;
logic write_enable;
logic [2:0]size;
logic [2:0]burst;
logic hready;
logic [3:0]prot;
logic [3:0]protect;

localparam logic [1:0] IDLE   = 2'b00;
localparam logic [1:0] BUSY   = 2'b01;
localparam logic [1:0] NONSEQ = 2'b10;
localparam logic [1:0] SEQ    = 2'b11;

ahb_interface dut (
    .hclk(hclk),
    .hresetn(hresetn),
    .haddr(haddr),
    .hwdata(hwdata),
    .hwrite(hwrite),
    .hsize(hsize),
    .hburst(hburst),
    .htrans(htrans),
    .valid_trans(valid_trans),
    .addr(addr),
    .data(data),
    .write_enable(write_enable),
    .size(size),
    .burst(burst),
    .hready(hready),
    .prot(prot),
    .protect(protect)
    );

    initial begin 
        hclk = 0;
        hresetn = 0;
        haddr = 32'b0;
        hwdata = 32'b0;
        hwrite = 0;
        hsize = 3'b0;
        hburst = 3'b0;
        htrans = 2'b0;
        hready = 1;
        prot = 4'b0011;
    end
    always #5 hclk = ~hclk;

    
initial begin
    #10;
    hresetn = 1;

    // Cycle 1: Accept first write address
    @(negedge hclk);
    htrans = NONSEQ;
    haddr  = 32'h0000_1000;
    hwrite = 1;
    hsize  = 3'b010;
    hburst = 3'b011;
    prot   = 4'b0011;

    // Cycle 2: First write data, and accept second address
    @(negedge hclk);
    htrans = SEQ;
    haddr  = 32'h0000_1004;
    hwdata = 32'hABCD_1234;
    hwrite = 1;

    // Cycle 3: Second write data; no new address
    @(negedge hclk);
    htrans = IDLE;
    hwdata = 32'h5555_AAAA;

    // Allow the final data phase to complete
    @(negedge hclk);
    htrans = IDLE;

    #2;


    // Read transfer test
    @(negedge hclk);
    htrans = NONSEQ;
    haddr  = 32'h0000_2000;
    hwrite = 0;
    hsize  = 3'b010;
    hburst = 3'b000;

    @(negedge hclk);
    htrans = IDLE;
    hwdata = 32'hDEAD_BEEF;

    @(negedge hclk);

    $finish;
end

    initial begin 
        $dumpfile("ahb_interface.vcd");
        $dumpvars(0,ahb_interface_tb);
    end
endmodule