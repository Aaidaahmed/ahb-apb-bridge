module apb_controller(
    input logic hclk,
    input logic hresetn,

    input logic [31:0]addr,
    input logic [31:0]data,
    input logic write_enable,
    input logic [2:0]size,

    input logic pready,
    input logic [31:0]prdata,
    input logic pslverr,

    output logic [31:0]paddr,
    output logic [31:0]pwdata,
    output logic pwrite,
    output logic [3:0]pstrb,

    input logic [1:0]addr_off,

    output logic [31:0]hrdata,
    output logic hresp,

    input logic apb_complete
);

always_comb begin 
    paddr = addr;
    pwdata = data;
    pwrite = write_enable;
end
always_comb begin 
    pstrb = 4'b0000;
    if(write_enable)begin
    case(size)
        (3'b000):begin 
            //byte logic
            if(addr_off == 2'b00)
                pstrb = 4'b0001;
            else if(addr_off == 2'b01)
                pstrb = 4'b0010;
            else if(addr_off == 2'b10)
                pstrb = 4'b0100;
            else if(addr_off == 2'b11)
                pstrb = 4'b1000;
        end
        (3'b001):begin 
            //halfword
            if(addr_off == 2'b00)
                pstrb = 4'b0011;
            else if(addr_off == 2'b10)
                pstrb = 4'b1100;
        end
        (3'b010):begin 
            //word
            if(addr_off == 2'b00)
                pstrb = 4'b1111;
        end
        default: pstrb = 4'b0000;
    endcase
    end
end

always_ff @(posedge hclk) begin 
    if(!hresetn)begin 
        hrdata <= 32'b0;
        hresp <= 1'b0;
    end
    else if(apb_complete)begin 
        hresp <= pslverr;
        if(!write_enable)begin 
            hrdata <= prdata;
        end
    end
end
endmodule