module relu #(
    parameter WIDTH = 128,          // Number of elements in vector
    parameter DATA_WIDTH = 16        // Bit width of each element
)(
    input wire clk,
    input wire reset,               // Active high reset
    input wire enable,              // Control signal to start computation
    
    // Input vector (flattened to bit vector)
    input wire [WIDTH*DATA_WIDTH-1:0] input_vector,
    
    // Output vector after ReLU activation (flattened to bit vector)
    output reg [WIDTH*DATA_WIDTH-1:0] output_vector,
    output reg done
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam FINISHED = 2'b10;
    
    // Internal registers
    reg [1:0] state;
    reg [$clog2(WIDTH)-1:0] index;
    
    // ReLU implementation
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            index <= 0;
            done <= 0;
            
            // Reset output vector
            output_vector <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable) begin
                        state <= PROCESSING;
                        index <= 0;
                        done <= 0;
                    end
                end
                
                PROCESSING: begin
                    // ReLU function: max(0, x)
                    // Extract current element using bit slicing
                    // Current input element: input_vector[(index+1)*DATA_WIDTH-1 -: DATA_WIDTH]
                    
                    // Check MSB to determine sign (fixed-point representation)
                    if (input_vector[(index+1)*DATA_WIDTH-1]) begin
                        // Negative value, output is 0
                        output_vector[(index+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= 0;
                    end else begin
                        // Positive or zero value, pass through
                        output_vector[(index+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= 
                            input_vector[(index+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                    end
                    
                    // Increment counter or finish
                    if (index < WIDTH - 1) begin
                        index <= index + 1;
                    end else begin
                        state <= FINISHED;
                    end
                end
                
                FINISHED: begin
                    done <= 1;
                    if (!enable) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule