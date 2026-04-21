`include "clock_mul.sv"

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

reg [1:0] state;
reg [2:0] bit_index;
reg [7:0] data_reg;
reg uart_done;

// STATES: State of the state machine
localparam DATA_BITS = 8;
localparam 
    INIT = 0, 
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

// CLOCK MULTIPLIER: Instantiate the clock multiplier

wire uart_clk;

clock_mul #(
    .SRC_FREQ(SRC_FREQ),
    .OUT_FREQ(BAUDRATE)
) clk_mul_inst (
    .src_clk(clk),
    .out_clk(uart_clk)
);

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set 1 one for one source 
// clock cycle. Use the cross clock domain technique discussed in class to handle this.
reg sync_1 = 0, sync_2 = 0;

always @(posedge clk) begin
    sync_1 <= uart_done;
    sync_2 <= sync_1;

    // one-cycle pulse
    rx_ready <= sync_1 & ~sync_2;

    if (sync_1 & ~sync_2) begin
        rx_data <= data_reg;
    end
end

// STATE MACHINE: Use the UART clock to drive that state machine that receves a byte from the rx signal

initial state = INIT;

always @(posedge uart_clk) begin
    case (state)
        INIT: begin
            state <= IDLE;
            uart_done <= 0;
        end

        IDLE: begin
            uart_done <= 0;
            if (rx == 0) begin // start bit detected
                bit_index <= 0;
                state <= RX_DATA;
            end
        end

        RX_DATA: begin
            data_reg[bit_index] <= rx; // LSB first
            if (bit_index == DATA_BITS-1) begin
                state <= STOP;
            end else begin
                bit_index <= bit_index + 1;
            end
        end

        STOP: begin
            uart_done <= 1;
            state <= IDLE;
        end
    endcase
end

endmodule