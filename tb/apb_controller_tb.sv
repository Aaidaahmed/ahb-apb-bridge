
module apb_controller_tb;
    logic [31:0] addr, data;
    logic write_enable;
    logic [2:0] size;
    logic pready, pslverr;
    logic [31:0] prdata;
    logic [31:0] paddr, pwdata;
    logic pwrite;
    logic [3:0] pstrb;
    logic [1:0] addr_off;
    logic hclk, hresetn;
    logic apb_complete;
    logic [31:0] hrdata;
    logic hresp;

    apb_controller dut (
        .addr(addr),
        .data(data),
        .write_enable(write_enable),
        .size(size),
        .pready(pready),
        .prdata(prdata),
        .pslverr(pslverr),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .pstrb(pstrb),
        .addr_off(addr_off),
        .hclk(hclk),
        .hresetn(hresetn),
        .apb_complete(apb_complete),
        .hrdata(hrdata),
        .hresp(hresp)
    );

    initial begin 
        hclk = 1'b0;
        hresetn = 1'b0;
        apb_complete = 1'b0;
    end

    always #5 hclk = ~hclk;

    initial begin
        @(negedge hclk);
        hresetn = 1'b1;
        addr = 32'h1000;
        data = 32'hABCD1234;
        pready = 1;
        prdata = 0;
        pslverr = 0;

        // Byte write, offset 0
        write_enable = 1;
        size = 3'b000;
        addr_off = 2'b00;
        #10;
        $display("Byte offset 0: PSTRB=%b (expected 0001)", pstrb);

        // Byte write, offset 2
        addr_off = 2'b10;
        #10;
        $display("Byte offset 2: PSTRB=%b (expected 0100)", pstrb);

        // Halfword write, offset 2
        size = 3'b001;
        addr_off = 2'b10;
        #10;
        $display("Halfword offset 2: PSTRB=%b (expected 1100)", pstrb);

        // Word write
        size = 3'b010;
        addr_off = 2'b00;
        #10;
        $display("Word write: PSTRB=%b (expected 1111)", pstrb);

        // Read: strobes must be zero
        write_enable = 0;
        #10;
        $display("Read: PSTRB=%b (expected 0000)", pstrb);

        // Successful read response
        // Successful read response
        @(negedge hclk);
write_enable = 0;
prdata = 32'hCAFE_BABE;
pslverr = 0;
apb_complete = 1;

@(posedge hclk);
#1;
$display("Read data: %h (expected CAFE_BABE)", hrdata);
$display("Read error: %b (expected 0)", hresp);

        // Write error response
        @(negedge hclk);
apb_complete = 0;

@(negedge hclk);
write_enable = 1;
pslverr = 1;
apb_complete = 1;

@(posedge hclk);
#1;
$display("Write error: %b (expected 1)", hresp);

        $finish;
    end
endmodule
