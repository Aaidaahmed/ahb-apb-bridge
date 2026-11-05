module ahb_apb_bridge(
    //AHB INPUTS
    input logic hclk,
    input logic hresetn,
    input logic [31:0]haddr,
    input logic [31:0]hwdata,
    input logic hwrite,
    input logic [2:0]hsize,
    input logic [2:0]hburst,
    input logic [1:0]htrans,
    input logic hready,
    input logic [3:0]hprot,
    input logic hsel,

    //AHB OUTPUTS
    output logic [31:0]hrdata,
    output logic hreadyout,
    output logic hresp,

    //APB OUTPUTS 
    output logic [31:0]paddr,
    output logic [31:0]pwdata,
    output logic pwrite,
    output logic [3:0]pstrb,
    output logic psel,
    output logic penable,
    output logic [2:0]pprot,

    //APB INPUTS
    input logic [31:0]prdata,
    input logic pready,
    input logic pslverr
    );

//AHB -> BRIDGE
logic valid_trans;
logic [31:0]ahb_addr_reg;
logic [31:0]ahb_data_reg;
logic ahb_write_reg;
logic [2:0]ahb_size_reg;
logic [2:0]ahb_burst_reg;
logic [3:0]ahb_prot_reg;
logic write_data_valid;


//BRIDGE FSM COMPLETE
logic trans_done;
logic ahb_accept;
assign ahb_accept = valid_trans && hready && !psel;

ahb_interface uwu_ahb_interface (
    .hclk         (hclk),
    .hresetn      (hresetn),
    .haddr        (haddr),
    .hwdata       (hwdata),
    .hwrite       (hwrite),
    .hsize        (hsize),
    .hburst       (hburst),
    .htrans       (htrans),
    .hready       (hready),
    .prot         (hprot),
    .hsel         (hsel),
    .accept_enable(ahb_accept),

    .valid_trans  (valid_trans),
    .write_data_valid(write_data_valid),
    .addr         (ahb_addr_reg),
    .data         (ahb_data_reg),
    .write_enable (ahb_write_reg),
    .size         (ahb_size_reg),
    .burst        (ahb_burst_reg),
    .protect      (ahb_prot_reg),

    .trans_done   (trans_done)
    //.hreadyout    (hreadyout)
);

logic fsm_psel;
logic fsm_penable;

bridge_fsm uwu_bridge_fsm (
    .hclk      (hclk),
    .hresetn   (hresetn),
    .valid_trans(ahb_accept),
    .more_trans(1'b0),
    .pready    (pready),
    .psel      (fsm_psel),
    .penable   (fsm_penable)
);

logic [3:0]apb_pstrb;


apb_controller uwu_apb_controller (
    .addr        (ahb_addr_reg),
    .data        (ahb_data_reg),
    .write_enable(ahb_write_reg),
    .size        (ahb_size_reg),

    .pready      (pready),
    .prdata      (prdata),
    .pslverr     (pslverr),

    .paddr       (paddr),
    .pwdata      (pwdata),
    .pwrite      (pwrite),
    .pstrb       (apb_pstrb),

    .addr_off    (ahb_addr_reg[1:0]),
    .hclk         (hclk),
    .hresetn      (hresetn),
    .apb_complete (trans_done),
    .hrdata       (hrdata),
    .hresp        (hresp)
);

assign psel = fsm_psel;
assign penable = fsm_penable;
assign pstrb = apb_pstrb;
assign trans_done = fsm_psel && fsm_penable && pready;
assign hreadyout = !psel || (penable && pready);

assign pprot[0] = ahb_prot_reg[1];
assign pprot[1] = 1'b0;
assign pprot[2] = ahb_prot_reg[0];

endmodule