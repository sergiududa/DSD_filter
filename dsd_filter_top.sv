`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2020 06:31:29 PM
// Design Name: 
// Module Name: avg_filter_top
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


module avg_filter_top;

// Interface wires
reg[31:0] data_in;
wire[31:0] data_out;
reg valid_in;
wire valid_out;
reg clk, rst_n;

/// DEBUG stuff
reg R,W;
wire debug_valid_out;
wire[31:0] debug_data_out;


avg_filter #( .DATA_WIDTH(32), .FIFO_DEPTH(8)) dut (
    .data_i(data_in),
    .valid_i(valid_in),
    .data_o(data_out),
    .valid_o(valid_out),
    .clk (clk),
    .rst_n(rst_n),
        
    .debug_valid_o(debug_valid_out),
    .debug_data_o(debug_data_out),
    .R(R),
    .W(W)
    );
    
// Testbench variables
integer input_index = 0;
integer output_index = 0;
integer expected_output_index = 0;
reg[31:0] input_data_buffer[39:0];
reg[31:0] expected_output[39:0];
reg[31:0] output_data_buffer[39:0];
reg error = 0;
integer sum;
initial clk = 0;

// Starting clock
always #10 clk = ~clk;

// Initial Block Reset
initial begin
rst_n = 0;
repeat(5)
    @(posedge clk);
   
rst_n = 1;
end

// Driving Module
initial begin
    repeat(10)
        @(posedge clk);
    
    // Initial values
    R <= 0;
    W <= 0;    
    
    // Starting initial traffic
    valid_in <= 1;
    repeat(15) begin
        data_in <= $urandom() % 20;
        @(posedge clk);
    end
    valid_in <= 0;
    
    // Keeping Valid 0 to check that the RTL is not outping anything without any input stimuli
    repeat(10)
            @(posedge clk);
    
    valid_in <= 1;
    repeat(5) begin
        data_in <= $urandom() % 20;
        @(posedge clk);
    end
    valid_in <= 0;
    repeat(2)
        @(posedge clk);
        
    // Checking if the RTL is properly reseted
    rst_n <= 0;
    
    repeat(10)
        @(posedge clk);
    
    // Releasing Reset
    rst_n <= 1;
    @(posedge clk);
    
    // Starting traffic
    valid_in <= 1;
    W <= 1;
    repeat(20) begin
        data_in <= $urandom() % 20;
        @(posedge clk);
    end
    W <= 0;
    R <= 1;
    @(posedge clk);
    R <= 0;
    
    repeat(20)
        @(posedge clk);
    $finish;
        
end

// Monitoring input 
always @(posedge clk) begin;
        if(rst_n == 0)
            input_index = 0;
        else
            if(valid_in === 1) begin
                input_data_buffer[input_index] = data_in;
                input_index = input_index + 1;
                if(input_index >= 8) begin
                    sum = 0;
                    for(int i = input_index - 1; i >= input_index - 8; i--)
                        sum = sum + input_data_buffer[i]; 
                    expected_output[expected_output_index] = sum >> 3;
                    expected_output_index = expected_output_index + 1;
                end               
            end             
 end


// Monitoring output block
always @(posedge clk) begin;
    if(valid_out === 1) begin
        output_data_buffer[output_index] = data_out;
        output_index = output_index + 1;   
    end    
end

// Checking block
final begin
    for(int i = 0; i < output_index; i = i + 1)
        if(output_data_buffer[i] !== expected_output[i]) begin
            $display("[ERROR] Expecting data == %d but received data == %0d", expected_output[i], output_data_buffer[i]);
            error = 1;
        end
    if(error == 1)
        $display("[TEST FAILED] Test finished with errors");
    else
        $display("[TEST ENDED] Test finished without errors");
end

endmodule
