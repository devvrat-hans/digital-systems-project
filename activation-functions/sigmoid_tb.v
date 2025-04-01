`timescale 1ns / 1ps

module sigmoid_tb;
    // Parameters
    parameter WIDTH = 128;
    parameter DATA_WIDTH = 16;
    parameter FRAC_BITS = 8;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg enable;
    reg [DATA_WIDTH-1:0] input_vector [0:WIDTH-1];
    wire [DATA_WIDTH-1:0] output_vector [0:WIDTH-1];
    wire done;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // DUT instantiation
    sigmoid #(
        .WIDTH(WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .input_vector(input_vector),
        .output_vector(output_vector),
        .done(done)
    );
    
    // Fixed-point conversion helper function (for display)
    function real fixed_to_real;
        input [DATA_WIDTH-1:0] fixed_point;
        begin
            if (fixed_point[DATA_WIDTH-1] == 1'b1) begin
                // Negative number
                fixed_to_real = -$signed(~fixed_point + 1) / (2.0 ** FRAC_BITS);
            end else begin
                // Positive number
                fixed_to_real = fixed_point / (2.0 ** FRAC_BITS);
            end
        end
    endfunction
    
    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        enable = 0;
        
        // Generate a range of input values from -5.0 to 5.0
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            // Convert from -5.0 to 5.0 range to fixed point
            real value = -5.0 + (10.0 * i) / (WIDTH - 1);
            input_vector[i] = $rtoi(value * (2 ** FRAC_BITS));
        end
        
        // Add specific test cases for the threshold regions
        input_vector[0] = 16'hDC00;    // -4.5 (below lower threshold)
        input_vector[1] = 16'hC000;    // -4.0 (at lower threshold)
        input_vector[2] = 16'hE000;    // -2.0 (in linear region)
        input_vector[3] = 16'h0000;    // 0.0 (should be 0.5)
        input_vector[4] = 16'h0200;    // 2.0 (in linear region)
        input_vector[5] = 16'h0400;    // 4.0 (at upper threshold)
        input_vector[6] = 16'h0480;    // 4.5 (above upper threshold)
        
        // Release reset and start computation
        #20 reset = 0;
        #10 enable = 1;
        
        // Wait for computation to complete
        wait(done);
        #20 enable = 0;
        
        // Display results for verification
        #10;
        $display("Sigmoid activation completed");
        $display("Test cases around thresholds:");
        
        for (integer i = 0; i < 7; i = i + 1) begin
            $display("input[%0d] = %h (%.3f), output[%0d] = %h (%.3f)", 
                    i, input_vector[i], fixed_to_real(input_vector[i]),
                    i, output_vector[i], fixed_to_real(output_vector[i]));
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