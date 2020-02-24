// Wishbone master interface for I2C peripheral
module i2c_config # (
	parameter CLK_FREQ = 100_000_000,
	parameter I2C_FREQ = 100_000
) (
	input	wire		clk,
	input	wire		rst,
	
	input	wire		i_cfg_start,
	output	wire		o_cfg_done,
	
	input	wire		i2c_scl_i,
	output	wire		i2c_scl_o,
	output	wire		i2c_scl_t,
	input	wire		i2c_sda_i,
	output	wire		i2c_sda_o,
	output	wire		i2c_sda_t
);

localparam	PRESCALE	= CLK_FREQ / (4 * I2C_FREQ);

localparam	RESET		= 4'h0,
			CFG_0		= 4'h1,
			CFG_1		= 4'h2,
			CFG_DONE	= 4'hF;

reg [7:0]		r_cnt, r_cnt_next;
reg	[2:0]		r_adr, r_adr_next;
reg	[15:0]		r_din, r_din_next;
reg	[3:0]		r_state, r_state_next;
reg				r_we, r_we_next;
reg	[1:0]		r_sel, r_sel_next;
reg				r_stb, r_stb_next;
reg				r_cyc, r_cyc_next;
reg				r_cfg_done, r_cfg_done_next;

wire			w_ack;

assign	o_cfg_done = r_cfg_done;

always @ (posedge clk) begin
	if (rst) begin
		r_state		<= RESET;
		r_cnt		<= 8'h00;
		r_we		<= 1'b0;
		r_stb		<= 1'b0;
		r_cyc		<= 1'b0;
		r_cfg_done	<= 1'b0;
		r_adr		<= 3'h0;
		r_din		<= 16'h0000;
		r_sel		<= 2'b00;
	end else begin
		r_state		<= r_state_next;
		r_cnt		<= r_cnt_next;
		r_we		<= r_we_next;
		r_stb		<= r_stb_next;
		r_cyc		<= r_cyc_next;
		r_cfg_done	<= r_cfg_done_next;
		r_adr		<= r_adr_next;
		r_din		<= r_din_next;
		r_sel		<= r_sel_next;
	end
end

always @ (*) begin
	case(r_state)
		RESET: begin
			if (i_cfg_start == 1'b1)
				r_state_next	= CFG_0;
			else
				r_state_next	= RESET;
			r_cnt_next		= 8'h00;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_cfg_done_next	= 1'b0;
		end
		CFG_0: begin
			r_state_next	= CFG_1;
			r_cnt_next		= r_cnt;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_cfg_done_next	= 1'b0;
		end
		CFG_1: begin
			if (r_cnt < 8'h02) begin
				r_state_next	= CFG_0;
				r_cnt_next		= r_cnt + 1;
			end else begin
				r_state_next	= CFG_DONE;
				r_cnt_next		= r_cnt;
			end
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_cfg_done_next	= 1'b0;
		end
		CFG_DONE: begin
			r_state_next	= CFG_DONE;
			r_cnt_next		= r_cnt;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_cfg_done_next	= 1'b1;
		end
		default: begin
			r_state_next	= RESET;
			r_cnt_next		= 1'b0;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_cfg_done_next	= 1'b0;
		end
	endcase
end

always @ (*) begin
	case(r_cnt)
		// Set prescale
		8'h00: begin
			r_adr_next	= 3'h6;
			r_din_next	= PRESCALE;
			r_sel_next	= 2'b11;
		end
		// I2C MUX setup
		8'h01: begin
			// Write I2C data
			r_adr_next	= 3'h4;
			r_din_next	= 16'b1111_1101_1001_0000;
			r_sel_next	= 2'b11;
		end
		8'h02: begin
			// Inititate start, write, stop, and write I2C address
			r_adr_next	= 3'h2;
			r_din_next	= 16'b1111_0101_1111_0100;
			r_sel_next	= 2'b11;
		end
		// SI5234 addr / data will follow
		// 8'h02: begin
			// r_adr_next	= 3'h4;
			// r_din_next	= 16'b1111_1101_
		// 8'hFF: begin
			// Initiate block write
			// r_adr_next	= 3'h2;
			// r_din_next	= 16'b1111_1001_1110_1000;
		default: begin
			r_adr_next	= 3'h0;
			r_din_next	= 16'b0000_0000_0000_0000;
			r_sel_next	= 2'b00;
		end
	endcase
end

i2c_master_wbs_16 i2c_master_inst (
	.clk			(clk),
	.rst			(rst),
	// Wishbone interface signals
	.wbs_adr_i		(r_adr),
	.wbs_dat_i		(r_din),
	.wbs_dat_o		(),
	.wbs_we_i		(r_we),
	.wbs_sel_i		(r_sel),
	.wbs_stb_i		(r_stb),
	.wbs_ack_o		(w_ack),
	.wbs_cyc_i		(r_cyc),
	// I2C interface signals
	.i2c_scl_i		(i2c_scl_i),
	.i2c_scl_o		(i2c_scl_o),
	.i2c_scl_t		(i2c_scl_t),
	.i2c_sda_i		(i2c_sda_i),
	.i2c_sda_o		(i2c_sda_o),
	.i2c_sda_t		(i2c_sda_t)
);

endmodule