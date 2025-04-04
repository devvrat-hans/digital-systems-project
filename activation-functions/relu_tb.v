`timescale 1ns / 1ps

module relu_tb;
    // Parameters
    parameter WIDTH = 128;
    parameter DATA_WIDTH = 16;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg enable;
    reg [WIDTH*DATA_WIDTH-1:0] input_vector;
    wire [WIDTH*DATA_WIDTH-1:0] output_vector;
    wire done;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // DUT instantiation
    relu #(
        .WIDTH(WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .input_vector(input_vector),
        .output_vector(output_vector),
        .done(done)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        enable = 0;
        input_vector = 0;
        
        // Initialize input vector with positive and negative values
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            if (i % 2 == 0) begin
                // Positive value: 2.0 in fixed point
                input_vector[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = 16'h0200;
            end else begin
                // Negative value: -2.0 in fixed point
                input_vector[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = 16'hFE00;
            end
        end
        
        // Add some special test cases
        input_vector[DATA_WIDTH-1:0] = 16'h0000;                  // Zero
        input_vector[2*DATA_WIDTH-1:DATA_WIDTH] = 16'hF000;       // Large negative value
        input_vector[3*DATA_WIDTH-1:2*DATA_WIDTH] = 16'h1000;     // Large positive value
        
        // Release reset and start computation
        #20 reset = 0;
        #10 enable = 1;
        
        // Wait for computation to complete
        wait(done);
        #20 enable = 0;
        
        // Display results for verification
        #10;
        $display("ReLU activation completed");
        $display("First few inputs and outputs:");
        for (integer i = 0; i < 10; i = i + 1) begin
            $display("input[%0d] = %h, output[%0d] = %h", 
                    i, input_vector[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH], 
                    i, output_vector[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH]);
        end
        
        // Run a bit longer and finish
        #100;
        $finish;
    end
    
    // Monitor for observing progress
    initial begin
        $monitor("Time: %t, Reset: %b, Enable: %b, Done: %b", 
                 $time, reset, enable, done);
    end
endmodule