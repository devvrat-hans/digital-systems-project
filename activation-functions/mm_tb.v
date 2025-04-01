`timescale 1ns / 1ps

module matrix_multiplication_tb;
    // Parameters
    parameter INPUT_WIDTH = 1152;
    parameter OUTPUT_WIDTH = 128;
    parameter DATA_WIDTH = 16;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg enable;
    reg [DATA_WIDTH-1:0] input_vector [0:INPUT_WIDTH-1];
    reg [DATA_WIDTH-1:0] weight_matrix [0:INPUT_WIDTH*OUTPUT_WIDTH-1];
    wire [DATA_WIDTH-1:0] output_vector [0:OUTPUT_WIDTH-1];
    wire done;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // DUT instantiation
    matrix_multiplication #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .input_vector(input_vector),
        .weight_matrix(weight_matrix),
        .output_vector(output_vector),
        .done(done)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        enable = 0;
        
        // Initialize input vector (all 1's for simplicity)
        for (integer i = 0; i < INPUT_WIDTH; i = i + 1) begin
            input_vector[i] = 16'h0100; // 1.0 in fixed point (assuming 8 fractional bits)
        end
        
        // Initialize weight matrix (identity pattern for easy verification)
        for (integer j = 0; j < OUTPUT_WIDTH; j = j + 1) begin
            for (integer i = 0; i < INPUT_WIDTH; i = i + 1) begin
                if (i % OUTPUT_WIDTH == j) begin
                    weight_matrix[j*INPUT_WIDTH + i] = 16'h0100; // 1.0 in fixed point
                end else begin
                    weight_matrix[j*INPUT_WIDTH + i] = 16'h0000; // 0.0
                end
            end
        end
        
        // Release reset and start computation
        #20 reset = 0;
        #10 enable = 1;
        
        // Wait for computation to complete
        wait(done);
        #20 enable = 0;
        
        // Display some results for verification
        #10;
        $display("Matrix multiplication completed");
        $display("First few outputs:");
        for (integer i = 0; i < 5; i = i + 1) begin
            $display("output_vector[%0d] = %h", i, output_vector[i]);
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