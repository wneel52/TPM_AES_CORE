module auth_uart_bridge(
    input  logic       clk,
    input  logic       reset,
    // from uart_rx
    input  logic [7:0] rx_data,
    input  logic       rx_valid,
    // to uart_tx
    output logic [7:0] tx_data,
    output logic       tx_start,
    input  logic       tx_busy,
    // to controller
    output logic       zeroize_in,
    output logic       do_compare,
    output logic       commit_illegal,
    output logic [15:0] auth_key_in,
    // from controller
    input  logic       aes_enable,
    input  logic       unlocked,
    input  logic       auth_zeroize,
    input  logic [1:0] key_sel,
    input  logic [1:0] state_debug
);

    typedef enum logic [3:0] {
        IDLE,
        LOAD_KEY_HI,
        LOAD_KEY_LO,
        SEND_ACK,
        SEND_STATUS_HDR,
        WAIT_STATUS_HDR_BUSY,
        WAIT_STATUS_HDR_DONE,
        SEND_STATUS_BYTE
    } state_t;

    state_t state;

    logic [7:0] key_hi;
    logic [7:0] ack_byte;
    logic [7:0] status_byte;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            tx_data        <= 8'd0;
            tx_start       <= 1'b0;
            zeroize_in     <= 1'b0;
            do_compare     <= 1'b0;
            commit_illegal <= 1'b0;
            auth_key_in    <= 16'b0;
            key_hi         <= 8'd0;
            ack_byte       <= 8'h55;
            status_byte    <= 8'd0;
        end else begin
            // default pulse outputs
            tx_start       <= 1'b0;
            zeroize_in     <= 1'b0;
            do_compare     <= 1'b0;
            commit_illegal <= 1'b0;

            case (state)
                IDLE: begin
                    if (rx_valid) begin
                        case (rx_data)
                            8'hA1: begin
                                state <= LOAD_KEY_HI;
                            end

                            8'hA2: begin
                                do_compare <= 1'b1;
                                ack_byte   <= 8'h55;
                                state      <= SEND_ACK;
                            end

                            8'hA3: begin
                                status_byte[0]   <= unlocked;
                                status_byte[1]   <= aes_enable;
                                status_byte[2]   <= auth_zeroize;
                                status_byte[4:3] <= key_sel;
                                status_byte[6:5] <= state_debug;
                                status_byte[7]   <= 1'b0;
                                state            <= SEND_STATUS_HDR;
                            end

                            8'hA4: begin
                                zeroize_in <= 1'b1;
                                ack_byte   <= 8'h55;
                                state      <= SEND_ACK;
                            end

                            8'hA5: begin
                                commit_illegal <= 1'b1;
                                ack_byte       <= 8'h55;
                                state          <= SEND_ACK;
                            end

                            default: begin
                                state <= IDLE;
                            end
                        endcase
                    end
                end

                LOAD_KEY_HI: begin
                    if (rx_valid) begin
                        key_hi <= rx_data;
                        state  <= LOAD_KEY_LO;
                    end
                end

                LOAD_KEY_LO: begin
                    if (rx_valid) begin
                        auth_key_in <= {key_hi, rx_data};
                        ack_byte    <= 8'h55;
                        state       <= SEND_ACK;
                    end
                end

                SEND_ACK: begin
                    if (!tx_busy) begin
                        tx_data  <= ack_byte;
                        tx_start <= 1'b1;
                        state    <= IDLE;
                    end
                end

                SEND_STATUS_HDR: begin
                    if (!tx_busy) begin
                        tx_data  <= 8'hD0;
                        tx_start <= 1'b1;
                        state    <= WAIT_STATUS_HDR_BUSY;
                    end
                end

                WAIT_STATUS_HDR_BUSY : begin
                    if (tx_busy) begin
                        state <= WAIT_STATUS_HDR_DONE;
                    end
                end
                
                WAIT_STATUS_HDR_DONE: begin
                    if (!tx_busy) begin
                        state <= SEND_STATUS_BYTE;
                    end
                end

                SEND_STATUS_BYTE: begin
                    if (!tx_busy) begin
                        tx_data  <= status_byte;
                        tx_start <= 1'b1;
                        state    <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
