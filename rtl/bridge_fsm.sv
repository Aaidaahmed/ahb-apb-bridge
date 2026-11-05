module bridge_fsm(
    input logic hclk,
    input logic hresetn,// reset here is active low. the n in the end is the indication
    input logic valid_trans,
    input logic more_trans,
    input logic pready,
    //input logic write_data_valid,

    output logic psel,
    output logic penable
);

typedef enum logic [1:0]{
    IDLE   = 2'b00,
    SETUP  = 2'b01,
    ENABLE = 2'b10
}state;

state cs, ns;

always_ff @( posedge hclk ) begin

    cs <= (hresetn == 0) ? IDLE : ns;
end

always_comb begin// it is combinational l;ogic so we use Blocking assignment here =
    ns = IDLE;
    case(cs)
        IDLE : 
        begin
            if(valid_trans)
                ns = SETUP;
            else
                ns = IDLE;
            //ns = state'(valid_trans == 0) ? IDLE : SETUP; 
        end
        SETUP : 
            ns = ENABLE;
        ENABLE : 
        begin
        if(pready == 0)
            ns = ENABLE;
        else if(pready == 1)
            if(more_trans)
                ns = SETUP;
            else 
                ns = IDLE;
            //ns = state'(more_trans == 1) ? SETUP : IDLE; 
            /*HERE IN THE TERNARY OPERATOR WE USE state' THIS IS 
            CALLED EXPLICIT CASTING this is because we use enum
            BUT THIS SV DOES NOT DOES IT
            SO WE WERE UNABLE TO USE IT AND USED IF ELSE INSTEAD*/
        end
    endcase
end

always_comb begin
    psel = 0;
    penable = 0;
    case(cs)
        IDLE:
        begin
            psel = 0;
            penable = 0;
        end
        SETUP:
        begin
            psel = 1;
            penable = 0;
        end
        ENABLE:
        begin
            psel = 1;
            penable = 1;
        end
    endcase
end
endmodule