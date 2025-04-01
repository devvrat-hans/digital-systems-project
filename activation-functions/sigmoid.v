module sigmoid #(
    parameter WIDTH = 128,           // Number of elements in vector
    parameter DATA_WIDTH = 16,        // Bit width of each element
    parameter FRAC_BITS = 8          // Number of fractional bits in fixed-point format
)(
    input wire clk,
    input wire reset,                // Active high reset
    input wire enable,               // Control signal to start computation
    
    // Input vector 
    input wire [DATA_WIDTH-1:0] input_vector [0:WIDTH-1],
    
    // Output vector after sigmoid activation
    output reg [DATA_WIDTH-1:0] output_vector [0:WIDTH-1],
    output reg done
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam FINISHED = 2'b10;
    
    // Internal registers
    reg [1:0] state;
    reg [$clog2(WIDTH)-1:0] index;
    
    // Sigmoid constants for piecewise linear approximation (fixed-point)
    // 0.5 in fixed point with FRAC_BITS precision
    localparam [DATA_WIDTH-1:0] HALF = (1 << FRAC_BITS) >> 1;
    
    // 1.0 in fixed point
    localparam [DATA_WIDTH-1:0] ONE = (1 << FRAC_BITS);
    
    // 0.25 in fixed point (slope of linear approximation in middle region)
    localparam [DATA_WIDTH-1:0] SLOPE = (1 << FRAC_BITS) >> 2;
    
    // Thresholds for the piecewise approximation: -4.0 and 4.0
    localparam [DATA_WIDTH-1:0] NEG_THRESHOLD = (4 << FRAC_BITS) | {1'b1, {(DATA_WIDTH-1){1'b0}}};  // -4.0
    localparam [DATA_WIDTH-1:0] POS_THRESHOLD = (4 << FRAC_BITS);  // 4.0
    
    // Sigmoid implementation (piecewise linear approximation)
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            index <= 0;
            done <= 0;
            
            // Reset output vector
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                output_vector[i] <= 0;
            end
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
                    // Piecewise linear approximation of sigmoid
                    if ($signed(input_vector[index]) <= $signed(NEG_THRESHOLD)) begin
                        // If x <= -4.0, sigmoid(x) ≈ 0
                        output_vector[index] <= 0;
                    end else if ($signed(input_vector[index]) >= $signed(POS_THRESHOLD)) begin
                        // If x >= 4.0, sigmoid(x) ≈ 1
                        output_vector[index] <= ONE;
                    end else begin
                        // If -4.0 < x < 4.0, sigmoid(x) ≈ 0.5 + 0.25x
                        // This is a linear approximation in the middle region
                        output_vector[index] <= HALF + ((SLOPE * $signed(input_vector[index])) >>> FRAC_BITS);
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