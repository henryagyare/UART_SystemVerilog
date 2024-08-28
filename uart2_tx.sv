`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2024 10:46:40 AM
// Design Name: 
// Module Name: uart2_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart2_tx import uart2_pkgs::*; 
    #(
        parameter CPB = 868, // 50MHz / 115200 = 434.028 clocks-per-bits
        parameter half_CPB = 434    // CPB / 2 = 217.0138 clocks-per-bits
        // parameter tx_in = 8'b1001_0110,
        // parameter tx_start = 1'b1
    )
    (
        input logic [7:0] tx_in,
        input logic tx_start, clock, reset,
        // input logic clock, reset,
        output logic tx_out, tx_done
    );
    
    state_encoding current_state, next_state;

    logic [10:0] current_sampling_count, next_sampling_count;
    logic [3:0] current_bit_count, next_bit_count;

    logic [7:0] current_tx_reg_val, next_tx_reg_val;
    logic current_tx_out, next_tx_out;
    logic tx_done_current, tx_done_next;

    // Current State Block
    always_ff @( posedge clock, negedge reset ) begin : Current_State_Block
        if (!reset)
            current_state <= IDLE_STATE;
        else
            current_state <= next_state;
    end

    // Signals Initializations
    always_ff @( posedge clock, negedge reset ) begin
        if (!reset) begin
            current_sampling_count <= '0;
            current_bit_count <= '0;
            current_tx_reg_val <= '0;
            current_tx_out <= '1;
            tx_done_current <= '0;
        end
        else begin
            current_sampling_count <= next_sampling_count;
            current_bit_count <= next_bit_count;
            current_tx_reg_val <= next_tx_reg_val;
            current_tx_out <= next_tx_out;
            tx_done_current <= tx_done_next;
        end
    end


    // Next State Logic
    always_comb begin : Next_State_Logic
       case (current_state)
        IDLE_STATE      :   begin
                                next_tx_out = '1;
                                tx_done_next = '0;
                                next_bit_count = '0;
                                next_sampling_count = '0;
                                next_tx_reg_val = tx_in;
                                if (tx_start) begin
                                    next_state = START_STATE;
                                    next_bit_count = 3'b001;   
                                end 
                                else begin
                                    next_state = IDLE_STATE;
                                end 
                            end 
        START_STATE     :   begin
                                next_tx_out = '0;
                                tx_done_next = '0;
                                next_tx_reg_val = current_tx_reg_val;
                                next_bit_count = current_bit_count;
                                if (current_sampling_count == CPB) begin
                                    next_state          = MOVE_DATA_STATE;
                                    next_sampling_count = 0;
                                    next_tx_out         = current_tx_reg_val[0];
                                end
                                else begin
                                    next_state = START_STATE;
                                    next_sampling_count = current_sampling_count + 1;
                                end
                            end 
        MOVE_DATA_STATE :   begin
                                tx_done_next = '0;
                                if (current_bit_count == 8 && current_sampling_count == CPB)  begin
                                    next_state = STOP_STATE;
                                    next_bit_count = '0;
                                    next_sampling_count = '0;
                                    next_tx_reg_val = '0;
                                    next_tx_out = '1;
                                end
                                else begin
                                    next_state = MOVE_DATA_STATE;
                                    if (current_sampling_count == CPB) begin
                                        next_bit_count = current_bit_count + 1;
                                        next_sampling_count = '0;
                                        next_tx_out = current_tx_reg_val[current_bit_count];
                                        next_tx_reg_val = current_tx_reg_val;
                                    end
                                    else begin
                                        next_bit_count = current_bit_count;
                                        next_sampling_count = current_sampling_count + 1;
                                        next_tx_out = current_tx_out;
                                        next_tx_reg_val = current_tx_reg_val;
                                    end
                                end            
                            end
        STOP_STATE      :   begin
                                next_tx_reg_val = current_tx_reg_val;
                                next_tx_out = '1;
                                if (current_sampling_count == CPB) begin
                                    tx_done_next = '1;    
                                    next_state = IDLE_STATE;
                                    next_sampling_count = '0;
                                    next_bit_count = '0;
                                end
                                else begin
                                    tx_done_next = '0;
                                    next_state = STOP_STATE;
                                    next_sampling_count = current_sampling_count + 1;
                                    next_bit_count = current_bit_count;
                                end            
                            end
        default         :   begin
                                next_state = IDLE_STATE;
                                tx_done_next = '0;
                                next_sampling_count = '0;
                                next_bit_count = '0;
                                next_tx_reg_val = '0;
                                next_tx_out = '1;
                            end
       endcase 
    end

    // always_ff @( posedge clock ) begin
    //     tx_out <= current_tx_out;        
    // end
    assign tx_out = current_tx_out;

    assign tx_done = tx_done_current;

endmodule
