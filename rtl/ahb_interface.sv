module ahb_interface(
    input logic trans_done,
    input logic hclk,
    input logic hresetn,
    input logic [31:0]haddr,
    input logic [31:0]hwdata,
    input logic hwrite,
    input logic [2:0]hsize,
    input logic [2:0]hburst,
    input logic [1:0]htrans,
    input logic hready, // indicates whether the AHB address/control phase can be accepted
    input logic [3:0]prot,// carries ahb protection attributes.
    input logic hsel,
    input logic accept_enable,

    output logic write_data_valid,
    output logic transfer_ready,
    output logic valid_trans,
    output logic [31:0]addr,
    output logic [31:0]data,
    output logic write_enable,
    output logic [2:0]size,
    output logic [2:0]burst,
    output logic [3:0]protect
   // output logic hreadyout // to stall ahb while apb is busy
);

typedef enum logic [1:0]{ 
    IDLE, BUSY, NONSEQ, SEQ } trans_type;

/*always_comb begin
    if(htrans == NONSEQ || htrans == SEQ)
        valid_trans = 1;
    else
        valid_trans = 0;
end*/
assign valid_trans = hsel &&
                     ((htrans == 2'b10) || (htrans == 2'b11));

always_ff @(posedge hclk) begin 
    if(!hresetn)begin
        addr <= 0;
        write_enable <= 0;
        size <= 0;
        burst <= 0;
        protect <= 0;
    end
    else if(accept_enable && valid_trans && hready)begin 
        addr <= haddr;
        //data <= hwdata;
        write_enable <= hwrite;
        size <= hsize;
        burst <= hburst;
        protect <= prot;
    end
end


logic data_phase_write;
logic data_phase_valid;
logic transfer_pending;

assign write_data_valid = data_phase_valid && data_phase_write;

always_ff @(posedge hclk) begin
    if (!hresetn) begin
        data_phase_write <= 1'b0;
        data_phase_valid <= 1'b0;
        data <= 32'b0;
    end else begin
        // Track the address phase accepted on this clock edge.
        if (hready) begin
            data_phase_valid <= accept_enable && valid_trans;
            if (accept_enable && valid_trans)
                data_phase_write <= hwrite;
        end

        // Capture write data for the previously accepted transfer.
        if (data_phase_valid && data_phase_write)
            data <= hwdata;
    end
end

/*
logic data_phase_write;
logic data_phase_valid;
logic aps_busy;

always_ff @(posedge hclk) begin
    if(!hresetn)begin
        data_phase_write <= 0;
        data_phase_valid <= 0;
        data <= 0;
    end
    else begin
        if(hready) begin 
            data_phase_valid <= valid_trans && hready;
            if(valid_trans && hready)
                data_phase_write <= hwrite;
        end
        if(data_phase_valid && hready && data_phase_write)
            data <= hwdata;
    end
end*/
/*always_comb begin
    hreadyout = 1'b1;
end*/
endmodule