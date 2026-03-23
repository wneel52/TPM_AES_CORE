`timescale 1ns/1ps
module fsm_using_one_always(
clock,
reset,
req_0,
req_1,
gnt_0,
gnt_1
);
// inputs
input clock, reset, req_0, req_1;
wire clock, reset, req_0, req_1;
// outputs
output gnt_0, gnt_1;
reg gnt_0, gnt_1;
// internal constraints
parameter size = 3;
parameter IDLE = 3'b001, GNT0 = 3'b010, GNT1 = 3'b100;
// internal vars
reg [size-1:0] state; // seq logic
reg [size-1:0] next_state; // comb logic
reg req0_d, req1_d;
//logic
always @(posedge clock) 
begin : FSM
    if (reset) begin
        state <= IDLE;
        gnt_0 <= 1'b0;
        gnt_1 <= 1'b0;
        req0_d <= 1'b0;
        req1_d <= 1'b0;
    end
    else begin
        req0_d <= req_0;
        req1_d <= req_1;
        // default state unless set
        gnt_0 <= 1'b0;
        gnt_1 <= 1'b0;
        case(state) 
            IDLE : 
                if(req0_d) begin
                    state <= GNT0;
                    gnt_0 <= 1;
                end   
                else if (req1_d) begin
                    state <= GNT1;
                    gnt_1 <= 1;
                end
                else begin
                    state <= IDLE;
                end
            GNT0 :
                if (req_0) begin
                    state <= GNT0;
                    gnt_0 <= 1'b1; 
               end
                else begin
                    state <= IDLE;  
                    gnt_0 <= 1'b0;
                end
            GNT1:
                if (req_1) begin
                    state <= GNT1;
                    gnt_1 <= 1'b1;
                end
                else begin
                    state <= IDLE;
                    gnt_1 <= 1'b0;
                end
            default : state <= #1 IDLE; 
        endcase
    end
end
endmodule

