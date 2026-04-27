module fpga_top(
    input logic CLK,
    output logic LED0,
    output logic LED1,
    output logic LED2,
    output logic LED3
);
    // ins
    logic reset;
    logic zeroize_in;
    logic do_compare = 1'b0;
    logic commit_illegal;
    logic [15:0] auth_key_in = 16'd0;
    // outs
    logic aes_enable;
    logic unlocked;
    logic auth_zeroize;
    logic [1:0] key_sel;
    logic [1:0] state_debug;
    logic [23:0] hb_count;
    // platform keys
    localparam logic [15:0] PK0 = 16'hEEFF;
    localparam logic [15:0] PK1 = 16'h4444;
    localparam logic [15:0] PK2 = 16'h5678;
    //init control sigs
    assign reset = 1'b0;
    assign zeroize_in = 1'b0;
    assign commit_illegal = 1'b0;
    // init top level module
    auth_controller_top #(.KEY_W(16)) unit_top(
        .clk(CLK),
        .reset(reset),
        .zeroize_in(zeroize_in),
        .do_compare(do_compare),
        .commit_illegal(commit_illegal),
        .auth_key_in(auth_key_in),
        .aes_enable(aes_enable),
        .auth_zeroize(auth_zeroize),
        .unlocked(unlocked),
        .key_sel(key_sel),
        .state_debug(state_debug)
    );
    assign LED0 = hb_count[23];
    assign LED1 = unlocked;
    assign LED2 = aes_enable;
    assign LED3 = state_debug[1];
    // sequencer
    typedef enum logic [3:0]{
        S_LOAD0,
        S_PULSE0,
        S_WAIT0,
        S_LOAD1,
        S_PULSE1,
        S_WAIT1,
        S_LOAD2,
        S_PULSE2,
        S_DONE
    } state_t;
    state_t state = S_LOAD0;
    logic [23:0] delay_count = 24'd0;
    localparam int WAIT_CYCLES = 24'd6_000_000; // 0.5s delay
    always_ff @(posedge CLK) begin
        hb_count <= hb_count + 1;
        case(state)
            S_LOAD0:begin
                auth_key_in <= PK0;
                do_compare <= 1'b0;
                delay_count <= 24'd0;
                state <= S_PULSE0;
            end
            S_PULSE0:begin
                do_compare <= 1'b1;
                state <= S_WAIT0;
            end
            S_WAIT0:begin
                do_compare <= 1'b0;
                if (delay_count < WAIT_CYCLES)begin
                    delay_count <= delay_count + 1;
                end
                else begin
                    delay_count <= 24'd0;
                    state <= S_LOAD1;
                end
            end
            S_LOAD1:begin
                auth_key_in <= PK1;
                do_compare <= 1'b0;
                state <= S_PULSE1;
            end
            S_PULSE1:begin
                do_compare <= 1'b1;
                state <= S_WAIT1;
            end
            S_WAIT1:begin
                do_compare <= 1'b0;
                if (delay_count < WAIT_CYCLES) begin
                    delay_count <= delay_count + 1;
                end
                else begin
                    delay_count <= 24'd0;
                    state <= S_LOAD2;
                end
            end
            S_LOAD2:begin
                auth_key_in <= PK2;
                do_compare <= 1'b0;
                state <= S_PULSE2;
            end
            S_PULSE2:begin
                do_compare <= 1'b1;
                state <= S_DONE;
            end
            S_DONE:begin
                do_compare <= 1'b0;
                state <= S_DONE;
            end
            default:begin
                auth_key_in <= 16'd0;
                do_compare <= 1'b0;
                delay_count <= 24'd0;
                state <= S_LOAD0;
            end
        endcase
    end

endmodule
