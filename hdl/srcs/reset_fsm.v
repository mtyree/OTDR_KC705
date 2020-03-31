`timescale 1ns / 1ps

module reset_fsm # (
	parameter DELAY		= 10,
	parameter CLK_FREQ	= 100_000_000,
	parameter I2C_FREQ	= 100_000
) (
	input	wire	clk,
	input	wire	rst,
	output	wire	o_chip_rst_n,
	output	wire	o_done,
	input	wire	i2c_scl_i,
	output	wire	i2c_scl_o,
	output	wire	i2c_scl_t,
	input	wire	i2c_sda_i,
	output	wire	i2c_sda_o,
	output	wire	i2c_sda_t
);
    
    localparam	DELAY_END	= CLK_FREQ * DELAY / 1_000,
    			RST_WIDTH	= CLK_FREQ / 1_000_000;
    
    localparam	RESET	= 2'b00,
    			WAIT	= 2'b01,
    			CFG		= 2'b11,
    			DONE	= 2'b10;
    
    reg [1:0]	r_state, r_state_next;
	reg	[31:0]	r_delay, r_delay_next;
	reg			r_chip_rst, r_chip_rst_next;
	reg			r_cfg_start, r_cfg_start_next;
	
	assign	o_chip_rst_n	= ~r_chip_rst;
	
	always @(posedge clk) begin
		if (rst) begin
			r_state		<= RESET;
			r_delay		<= 32'd0;
			r_chip_rst	<= 1'b1;
			r_cfg_start	<= 1'b0;
		end else begin
			r_state		<= r_state_next;
			r_delay		<= r_delay_next;
			r_chip_rst	<= r_chip_rst_next;
			r_cfg_start	<= r_cfg_start_next;
		end
	end
	
	always @ (*) begin
		case(r_state)
			RESET:	r_state_next	<= WAIT;
			WAIT:
				if(r_delay == DELAY_END)
					r_state_next	<= CFG;
				else
					r_state_next	<= WAIT;
			CFG:	r_state_next	<= DONE;
			DONE:	r_state_next	<= DONE;
		endcase
	end
	
	always @ (*) begin
		case(r_state)
			RESET: begin
				r_delay_next		<= 32'd0;
				r_chip_rst_next		<= 1'b1;
				r_cfg_start_next	<= 1'b0;
			end
			WAIT: begin
				r_delay_next		<= r_delay + 1;
				if (r_delay < RST_WIDTH)
					r_chip_rst_next		<= 1'b1;
				else
					r_chip_rst_next		<= 1'b0;
				r_cfg_start_next	<= 1'b0;
			end
			CFG: begin
				r_delay_next		<= 32'd0;
				r_chip_rst_next		<= 1'b0;
				r_cfg_start_next	<= 1'b1;
			end
			DONE: begin
				r_delay_next		<= 32'd0;
				r_chip_rst_next		<= 1'b0;
				r_cfg_start_next	<= 1'b0;
			end
		endcase
	end
	
	i2c_config # (
		.CLK_FREQ	(CLK_FREQ),
		.I2C_FREQ	(I2C_FREQ)
	) i2c_config_inst (
		.clk			(clk),
		.rst			(rst),
		.i_cfg_start	(r_cfg_start),
		.o_cfg_done		(o_done),
		.i2c_scl_i		(i2c_scl_i),
		.i2c_scl_o		(i2c_scl_o),
		.i2c_scl_t		(i2c_scl_t),
		.i2c_sda_i		(i2c_sda_i),
		.i2c_sda_o		(i2c_sda_o),
		.i2c_sda_t		(i2c_sda_t)
	);
	
endmodule
