module matrix_multiplication #(
    parameter INPUT_WIDTH = 1152,
    parameter OUTPUT_WIDTH = 128,
    parameter DATA_WIDTH = 16  // Using 16-bit fixed point representation
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Input vector interface
    input wire [DATA_WIDTH-1:0] input_vector [0:INPUT_WIDTH-1],
    
    // Weight matrix interface - assuming weights are stored in block RAM
    input wire [DATA_WIDTH-1:0] weight_data,
    output reg [$clog2(INPUT_WIDTH*OUTPUT_WIDTH)-1:0] weight_addr,
    output reg weight_read_en,
    
    // Output vector interface
    output reg [DATA_WIDTH-1:0] output_vector [0:OUTPUT_WIDTH-1],
    output reg done
);

    // State machine
    localparam IDLE = 3'b000;
    localparam INIT_ACC = 3'b001;
    localparam LOAD_WEIGHT = 3'b010;
    localparam ACCUMULATE = 3'b011;
    localparam STORE_OUTPUT = 3'b100;
    localparam DONE = 3'b101;
    reg [2:0] state;
    
    // Internal registers
    reg [$clog2(INPUT_WIDTH)-1:0] i;        // Input index
    reg [$clog2(OUTPUT_WIDTH)-1:0] j;       // Output index
    reg [2*DATA_WIDTH-1:0] acc;             // Accumulator (double width to prevent overflow)
    
    // Main computation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            i <= 0;
            j <= 0;
            acc <= 0;
            weight_read_en <= 0;
            weight_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= INIT_ACC;
                        j <= 0;
                        done <= 0;
                    end
                end
                
                INIT_ACC: begin
                    // Initialize accumulator for a new output element
                    acc <= 0;
                    i <= 0;
                    state <= LOAD_WEIGHT;
                end
                
                LOAD_WEIGHT: begin
                    // Calculate weight address (row-major order: j * INPUT_WIDTH + i)
                    weight_addr <= j * INPUT_WIDTH + i;
                    weight_read_en <= 1;
                    state <= ACCUMULATE;
                end
                
                ACCUMULATE: begin
                    // Accumulate product of input and weight
                    acc <= acc + input_vector[i] * weight_data;
                    weight_read_en <= 0;
                    
                    // Move to next input element or finish current output
                    if (i < INPUT_WIDTH - 1) begin
                        i <= i + 1;
                        state <= LOAD_WEIGHT;
                    end else begin
                        state <= STORE_OUTPUT;
                    end
                end
                
                STORE_OUTPUT: begin
                    // Store computed output (truncating to DATA_WIDTH bits)
                    output_vector[j] <= acc[DATA_WIDTH-1:0];
                    
                    // Move to next output element or finish
                    if (j < OUTPUT_WIDTH - 1) begin
                        j <= j + 1;
                        state <= INIT_ACC;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule