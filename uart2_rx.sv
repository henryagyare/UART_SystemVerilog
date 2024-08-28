`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
    // Company: 
    // Engineer: 
    // 
    // Create Date: 07/30/2024 10:46:40 AM
    // Design Name: 
    // Module Name: uart2_rx
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


module uart2_rx import uart2_pkgs::*;
    #(
        parameter CPB = 868, // 50MHz / 115200 = 434.028 clocks-per-bits
        parameter half_CPB = 434    // CPB / 2 = 217.0138 clocks-per-bits
    )
    (
    input logic rx_in, clock, reset,
    output logic [7:0] rx_out,
    output logic rx_done
    );

    state_encoding current_state, next_state;

    logic [3:0] current_bit_count, next_bit_count;
    logic [10:0] current_sampling_count, next_sampling_count;
    
    logic [7:0] current_rx_reg_val, next_rx_reg_val;

    logic rx_done_current, rx_done_next;

    always_ff @(posedge clock, negedge reset) begin : Current_State_Block
        if (!reset)
            current_state <= IDLE_STATE;
        else
            current_state <= next_state;
    end
    

    always_ff @(posedge clock, negedge reset) begin
        if (!reset)begin
            current_bit_count <= '0;
            current_sampling_count <= '0;
            current_rx_reg_val <= '0;
            rx_done_current <= '0;
        end
        else begin
            current_bit_count <= next_bit_count;
            current_sampling_count <= next_sampling_count;
            current_rx_reg_val <= next_rx_reg_val;
            rx_done_current <= rx_done_next;
        end
        
    end

    // Next State Logic
    always_comb begin : Nex_State_Logic
        case (current_state)
            IDLE_STATE      :   begin
                                    rx_done_next = '0;
                                    next_bit_count = '0;
                                    next_sampling_count = '0;
                                    next_rx_reg_val = '0;
                                    if (!rx_in) begin
                                        next_state = START_STATE;
                                    end
                                    else begin
                                        next_state = current_state;
                                    end
                                end 
            START_STATE     :   begin
                                    rx_done_next = '0;
                                    next_bit_count = '0;
                                    next_rx_reg_val = 'X;
                                    if (current_sampling_count == half_CPB && !rx_in) begin
                                        next_state = MOVE_DATA_STATE;
                                        next_sampling_count = '0;
                                    end
                                    else begin
                                        next_state = current_state;
                                        next_sampling_count = current_sampling_count + 1;
                                    end
                                end
            MOVE_DATA_STATE :   begin
                                    rx_done_next = '0;
                                    if (current_bit_count == 7 && current_sampling_count == CPB) begin
                                        next_state = STOP_STATE;
                                        next_bit_count = '0;
                                        next_sampling_count = '0;
                                        next_rx_reg_val = {rx_in, current_rx_reg_val[7:1]};
                                    end
                                    else begin
                                        next_state = current_state;
                                        if (current_sampling_count == CPB) begin
                                            next_bit_count = current_bit_count + 1;
                                            next_sampling_count = '0;
                                            // next_rx_reg_val = {current_rx_reg_val, rx_out_reg[7:1]};
                                            next_rx_reg_val = {rx_in, current_rx_reg_val[7:1]};
                                        end
                                        else begin
                                            next_bit_count = current_bit_count;
                                            next_sampling_count = current_sampling_count + 1;
                                            next_rx_reg_val = current_rx_reg_val;
                                        end
                                    end
                                end
            STOP_STATE      :   begin
                                    next_rx_reg_val = current_rx_reg_val;                                        
                                    next_bit_count = '0;                                        
                                    if (current_sampling_count == CPB + half_CPB-1) begin
                                        next_state = IDLE_STATE;
                                        rx_done_next = '1;
                                        next_sampling_count = 0;
                                    end
                                    else begin
                                        next_state = current_state;
                                        next_sampling_count = current_sampling_count + 1;
                                        rx_done_next = '0;
                                    end
                                end
            default         :   begin
                                    rx_done_next = '0;
                                    next_state = IDLE_STATE;
                                    next_bit_count = '0;
                                    next_sampling_count = '0;
                                    next_rx_reg_val = '0;
                                end
        endcase
    end

    // Todo:
    //     Add rx_done_next and rx_done_current and then set rx_done_next to 1 @(CPB-1) and then at CPB, we turn off rx_done_next
    //     This way, we obtain a true value for rx_done in only one clock cycle.

    // Output
    // assign rx_out = current_rx_reg_val;
    // always_ff @( posedge clock ) begin
    //     rx_out <= current_rx_reg_val;
    // end

    assign rx_out = current_rx_reg_val;


    assign rx_done = rx_done_current;

endmodule
