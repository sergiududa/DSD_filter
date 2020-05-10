`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2020 04:18:55 PM
// Design Name: 
// Module Name: avg_filter
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


module avg_filter
    #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 4
    )(
    
    // Filter Interface
    input[DATA_WIDTH - 1 : 0] data_i,
    input valid_i,
    output[DATA_WIDTH - 1 : 0] data_o,
    output valid_o,
    
    // Clock and reset interface
    input clk,
    input rst_n,
    
    // Debug interface
    input R,
    input W,
    output[DATA_WIDTH - 1 : 0] debug_data_o,
    output debug_valid_o
    
    );
    
    function automatic int  get_bus_width(input int value);
        int buswidth;
        if (value <= 1)
            return 1;
        for (buswidth = 0; (2 ** buswidth) < value; buswidth++);
        return buswidth ;
    endfunction
    
    reg[DATA_WIDTH - 1 : 0] data_o_reg, next_data_o_reg;
    reg valid_o_reg, next_valid_o_reg;
    reg[get_bus_width(FIFO_DEPTH) : 0] counter;
    reg[get_bus_width(FIFO_DEPTH) - 1 : 0] shift = '1;
    
    integer sum, next_sum;
    
    typedef enum {NO_SET, RESET, COLLECT_DATA, SEND_OUTPUT} state_t;
    state_t state, next_state;  
    
    reg[DATA_WIDTH - 1 : 0] memory[FIFO_DEPTH - 1 : 0];
    
    always @(posedge clk) begin
        if(rst_n == 0)
            state <= RESET;
        else begin
            state <= next_state;
            sum   <= next_sum;
            valid_o_reg <= next_valid_o_reg;
            data_o_reg <= next_data_o_reg;
        end
    end
    
    always @(*) begin
        
        case(state)
            RESET: begin
                counter = 0;
                valid_o_reg = 0;
                data_o_reg = 0;                
                foreach(memory[i])
                    memory[i] = 0;
                next_sum = 0;
                next_state = COLLECT_DATA;
            end
            COLLECT_DATA: begin
                if(valid_i == 1) begin
                    for(int i = shift; i > 0; i = i - 1)
                        memory[i] = memory[i - 1];
                    next_sum = sum + data_i;
                    memory[0] = data_i;
                    counter = counter + 1;
                end
                if(counter == FIFO_DEPTH - 1)
                    next_state = SEND_OUTPUT;
            end
            SEND_OUTPUT: begin
                if(valid_i == 1) begin
                    next_sum = sum - memory[shift] + data_i;
                    for(int i = shift; i > 0; i = i - 1) 
                        memory[i] = memory[i - 1];
                    memory[0] = data_i;
                    next_data_o_reg =  (next_sum >> get_bus_width(FIFO_DEPTH));
                    next_valid_o_reg = 1;
                end
                else begin
                    next_valid_o_reg = 0;
                    next_data_o_reg = '0;
                end
                
            end
        endcase
    end
    dsd_debug_memory #( .DATA_WIDTH(DATA_WIDTH),.MEMORY_DEPTH(16)) data_out_debug_memory (
        .W(W),
        .R(R),
        .in (data_o),
        .out(debug_data_o),
        .clk(clk),
        .rst_n(rst_n)  
    );
    
    dsd_debug_memory #( .DATA_WIDTH(1),.MEMORY_DEPTH(16)) valid_out_debug_memory (
            .W(W),
            .R(R),
            .in (valid_o),
            .out(debug_valid_o),
            .clk(clk),
            .rst_n(rst_n)  
        );
    
    assign valid_o = valid_o_reg;
    assign data_o = data_o_reg;
endmodule
