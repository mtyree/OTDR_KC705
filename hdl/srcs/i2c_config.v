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
			if (i_cfg_start)
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
			if (r_cnt < 8'h59) begin
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
		8'h00: {r_adr_next, r_din_next, r_sel_next} = {3'h6, PRESCALE, 2'b11};
		// I2C MUX setup
		8'h01: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'b1111_1101_1001_0000, 2'b11};
		8'h02: {r_adr_next, r_din_next, r_sel_next} = {3'h2, 16'b1111_0101_1111_0100, 2'b11};
		// SI5324 setup
		8'h03: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h04: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD14, 2'b11};
		8'h05: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD01, 2'b11};
		8'h06: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDE4, 2'b11};
		8'h07: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD02, 2'b11};
		8'h08: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDA2, 2'b11};
		8'h09: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD03, 2'b11};
		8'h0A: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD15, 2'b11};
		8'h0B: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD04, 2'b11};
		8'h0C: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD92, 2'b11};
		8'h0D: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD05, 2'b11};
		8'h0E: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDED, 2'b11};
		8'h0F: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD06, 2'b11};
		8'h10: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2D, 2'b11};
		8'h11: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD07, 2'b11};
		8'h12: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2A, 2'b11};
		8'h13: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD08, 2'b11};
		8'h14: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h15: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD09, 2'b11};
		8'h16: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDC0, 2'b11};
		8'h17: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD0A, 2'b11};
		8'h18: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD08, 2'b11};
		8'h19: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD0B, 2'b11};
		8'h1A: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD42, 2'b11};
		8'h1B: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD13, 2'b11};
		8'h1C: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD29, 2'b11};
		8'h1D: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD14, 2'b11};
		8'h1E: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD3E, 2'b11};
		8'h1F: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD15, 2'b11};
		8'h20: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDFF, 2'b11};
		8'h21: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD16, 2'b11};
		8'h22: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDDF, 2'b11};
		8'h23: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD17, 2'b11};
		8'h24: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD1F, 2'b11};
		8'h25: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD18, 2'b11};
		8'h26: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD3F, 2'b11};
		8'h27: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD19, 2'b11};
		8'h28: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h29: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD1F, 2'b11};
		8'h2A: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h2B: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD20, 2'b11};
		8'h2C: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h2D: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD21, 2'b11};
		8'h2E: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD09, 2'b11};
		8'h2F: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD22, 2'b11};
		8'h30: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h31: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD23, 2'b11};
		8'h32: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h33: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD24, 2'b11};
		8'h34: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD09, 2'b11};
		8'h35: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD28, 2'b11};
		8'h36: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDC0, 2'b11};
		8'h37: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD29, 2'b11};
		8'h38: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h39: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2A, 2'b11};
		8'h3A: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDF9, 2'b11};
		8'h3B: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2B, 2'b11};
		8'h3C: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h3D: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2C, 2'b11};
		8'h3E: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h3F: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2D, 2'b11};
		8'h40: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD63, 2'b11};
		8'h41: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2E, 2'b11};
		8'h42: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h43: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD2F, 2'b11};
		8'h44: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h45: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD30, 2'b11};
		8'h46: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD63, 2'b11};
		8'h47: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD37, 2'b11};
		8'h48: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h49: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD83, 2'b11};
		8'h4A: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD1F, 2'b11};
		8'h4B: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD84, 2'b11};
		8'h4C: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD02, 2'b11};
		8'h4D: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD89, 2'b11};
		8'h4E: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD01, 2'b11};
		8'h4F: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD8A, 2'b11};
		8'h50: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD0F, 2'b11};
		8'h51: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD8B, 2'b11};
		8'h52: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFDFF, 2'b11};
		8'h53: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD8E, 2'b11};
		8'h54: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h55: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD8F, 2'b11};
		8'h56: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD00, 2'b11};
		8'h57: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFD88, 2'b11};
		8'h58: {r_adr_next, r_din_next, r_sel_next} = {3'h4, 16'hFF40, 2'b11};
		// Initiate Block Write
		8'h59: {r_adr_next, r_din_next, r_sel_next} = {3'h2, 16'b1111_1001_1110_1000, 2'b11};
		default: {r_adr_next, r_din_next, r_sel_next} = {3'h0, 16'h0000, 2'b00};
	endcase
end

i2c_master_wbs_16 # (
	.WRITE_FIFO_ADDR_WIDTH	(7)
) i2c_master_inst (
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