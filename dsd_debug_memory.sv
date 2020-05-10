`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2020 02:06:38 PM
// Design Name: 
// Module Name: dsd_debug_memory
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


/*
      _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  
clk _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
          _____________________________________________________________
rst _____|
                  ___  
W   _____________|   |_______________________________________________
in  xxxxxxxxxxxxxxxxx<data><data><data><data>xxxxxxxxxxxxxxxxxxxxxxxxx 
                                          ___
R   _____________________________________|   |________________________
out xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx<data><data><data><data>
*/

module dsd_debug_memory  #(
    parameter DATA_WIDTH = 32,
    parameter MEMORY_DEPTH = 16
    )(
    input[DATA_WIDTH - 1 : 0] in,
    input R,
    input W,
    output [DATA_WIDTH - 1 : 0] out,
    
 
    input clk,
    input rst_n
    );
    
    function automatic int  get_bus_width(input int value);
        int buswidth;
        if (value <= 1)
            return 1;
        for (buswidth = 0; (2 ** buswidth) < value; buswidth++);
            return buswidth ;
    endfunction
    
    typedef enum {NO_SET, RESET, IDLE, WRITE_DATA, READ_DATA} state_t;
    state_t state, next_state;
    
    reg[get_bus_width(MEMORY_DEPTH) : 0] write_counter, next_write_counter;
    reg[get_bus_width(MEMORY_DEPTH) : 0] read_counter, next_read_counter; 
    reg[DATA_WIDTH - 1 : 0] debug_memory[MEMORY_DEPTH - 1 : 0];
    
    reg[DATA_WIDTH - 1 : 0] memory_out , next_memory_out;
    
    always @(posedge clk) begin
        if(rst_n == 0)
            state <= RESET;
        else begin
            state <= next_state;
            write_counter <= next_write_counter;
            read_counter <= next_read_counter;
            memory_out <=next_memory_out;
        end
    end
    
    always @(*) begin
        case(state)
        RESET: begin
            next_state = IDLE;
        end
        
        IDLE: begin
            next_write_counter = 0;
            next_read_counter = 0;
            next_memory_out = 0;
            if(R == 1) begin
                $display("Cannot Read an empty memory");
            end
            if(W == 1)
                next_state = WRITE_DATA;
        end
        WRITE_DATA: begin
             if(R !== 1 && write_counter < MEMORY_DEPTH) begin
                debug_memory[write_counter] = in;
                next_write_counter = write_counter + 1;
             end
             else
                if(R == 1)
                    next_state = READ_DATA;
        end
        
        READ_DATA: begin
            if( read_counter < write_counter) begin
                next_memory_out = debug_memory[read_counter];
                next_read_counter = read_counter + 1;
            end
            else
                next_state = IDLE;    
        end
        
        endcase
    end
    
    assign out = memory_out;
endmodule
