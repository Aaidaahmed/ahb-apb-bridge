`timescale 1ns/1ps
module bridge_fsm_tb;
//tb drives them
logic hclk;
logic hresetn;
logic valid_trans;
logic more_trans;
logic pready;
//dut bridge_fsm drives them
logic psel;
logic penable;

bridge_fsm dut(
    .hclk(hclk),
    .hresetn(hresetn),
    .valid_trans(valid_trans),
    .more_trans(more_trans),
    .pready(pready),
    .psel(psel),
    .penable(penable)
);

initial begin
hclk = 0;
valid_trans = 0;
more_trans = 0;
pready = 0;
end

always #5 hclk = ~hclk;

initial begin 
    hresetn = 0;
    #5;
    hresetn = 1;
    #5;
    valid_trans = 0;
    #2;
    valid_trans = 1;
    #15;
    pready = 1;
    #15;
    more_trans = 1;
    pready = 0;
    #15;
    pready = 1;
    #10;
    $finish(); 
end
initial begin 
    $dumpfile("bridge_fsm.vcd");
    $dumpvars(0,bridge_fsm_tb);
end
endmodule