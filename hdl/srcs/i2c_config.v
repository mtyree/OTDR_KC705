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

localparam [15:0]	PRESCALE = CLK_FREQ / (4 * I2C_FREQ);

localparam [6:0]	I2C_MUX_ADDR	= 7'h74,
					SI5324_ADDR		= 7'h68;

localparam [7:0]	I2C_CORE_WRITE	= 8'hF5,
					I2C_CORE_READ	= 8'hF3;

localparam [15:0]	RATE = CLK_FREQ * 0.5 / 1000;

localparam	RESET		= 4'h0,
			PRS_0		= 4'h1,
			PRS_1		= 4'h2,
			CFG_0		= 4'h3,
			CFG_1		= 4'h4,
			CFG_2		= 4'h5,
			CFG_3		= 4'h6,
			READ_0		= 4'h7,
			READ_1		= 4'h8,
			READ_2		= 4'h9,
			READ_3		= 4'hA,
			READ_4		= 4'hB,
			READ_5		= 4'hC,
			WAIT_0		= 4'hD,
			WAIT_1		= 4'hE,
			CFG_DONE	= 4'hF;

reg [7:0]		r_cnt, r_cnt_next;
reg	[2:0]		r_adr, r_adr_next;
reg	[15:0]		r_din, r_din_next;
reg	[3:0]		r_state, r_state_next;
reg				r_we, r_we_next;
reg				r_stb, r_stb_next;
reg				r_cyc, r_cyc_next;
reg	[0:1]		r_start, r_start_next;
reg [15:0]		r_wait_cnt, r_wait_cnt_next;

wire			w_done;
wire			w_ack;
wire [2:0]		adr_vio;
wire [15:0]		din_vio, dout_vio;
wire			start_vio;
wire			i2c_scl_ila, i2c_sda_ila;
wire [7:0]		cfg_addr;
wire [15:0]		cfg_dout;
wire [6:0]		i2c_addr_vio;

assign	o_cfg_done	= w_done;
assign	w_done		= (r_state == CFG_DONE) ? 1'b1 : 1'b0;

always @ (posedge clk) begin
	if (rst) begin
		r_state		<= RESET;
		r_cnt		<= 8'h00;
		r_we		<= 1'b0;
		r_stb		<= 1'b0;
		r_cyc		<= 1'b0;
		r_adr		<= 3'h0;
		r_din		<= 16'h0000;
		r_start		<= 2'b00;
		r_wait_cnt	<= 16'h00;
	end else begin
		r_state		<= r_state_next;
		r_cnt		<= r_cnt_next;
		r_we		<= r_we_next;
		r_stb		<= r_stb_next;
		r_cyc		<= r_cyc_next;
		r_adr		<= r_adr_next;
		r_din		<= r_din_next;
		r_start		<= r_start_next;
		r_wait_cnt	<= r_wait_cnt_next;
	end
end

always @ (*) begin
	if (r_state == WAIT_0)
		r_wait_cnt_next	= r_wait_cnt + 1;
	else
		r_wait_cnt_next	= 16'h0000;
end
		
always @ (*) begin
	case(r_state)
		RESET: begin	// Reset state
			if (i_cfg_start == 1'b1)
				r_state_next	= PRS_0;
			else
				r_state_next	= RESET;
			r_cnt_next		= 8'h00;
			r_adr_next		= 3'h0;
			r_din_next		= 16'h0000;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		PRS_0: begin	// Set I2C clock frequency
			r_state_next	= PRS_1;
			r_cnt_next		= 8'h00;
			r_adr_next		= 3'h6;
			r_din_next		= PRESCALE;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		PRS_1: begin
			r_state_next	= WAIT_0;
			r_cnt_next		= 8'h00;
			r_adr_next		= 3'h6;
			r_din_next		= PRESCALE;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		WAIT_0: begin
			if (r_wait_cnt == RATE)
				r_state_next = CFG_0;
			else
				r_state_next = WAIT_0;
			r_cnt_next		= r_cnt;
			r_adr_next		= r_adr;
			r_din_next		= cfg_dout;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		WAIT_1: begin
			r_state_next	= CFG_0;
			r_cnt_next		= r_cnt;
			r_adr_next		= r_adr;
			r_din_next		= cfg_dout;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		CFG_0: begin	// Send data to core
			r_state_next	= CFG_1;
			r_cnt_next		= r_cnt;
			r_adr_next		= 3'h4;
			r_din_next		= cfg_dout;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		CFG_1: begin
			r_state_next	= CFG_2;
			r_cnt_next		= r_cnt;
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		CFG_2: begin	// Initiate write, set I2C address
			r_state_next	= CFG_3;
			r_cnt_next		= r_cnt;
			r_adr_next		= 3'h2;
			if (r_cnt == 8'h00)		// Set I2C stop when writing data
				r_din_next[15:0]	= {8'hF5, 1'b0, I2C_MUX_ADDR};
			else begin
				if (r_cnt[0] == 1'b1)
					r_din_next[15:0]	= {8'hE5, 1'b0, SI5324_ADDR};
				else
					r_din_next[15:0] 	= {8'hF4, 1'b0, SI5324_ADDR};
			end
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		CFG_3: begin
			if (r_cnt < 8'h56) begin
				if (r_cnt[0] == 1'b0)
					r_state_next	= WAIT_0;
				else
					r_state_next	= WAIT_1;
			end else begin
				r_state_next	= CFG_DONE;
			end
			r_cnt_next		= r_cnt + 1;
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		CFG_DONE: begin		// Wait for VIO signal
			if (r_start == 2'b01) begin
				r_state_next	= READ_0;
			end else begin
				r_state_next	= CFG_DONE;
			end
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= {start_vio, r_start[0]};
		end
		READ_0: begin		// Write desired address
			r_state_next	= READ_1;
			r_adr_next		= 3'h4;
			r_din_next		= din_vio;
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		READ_1: begin
			r_state_next	= READ_2;
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		READ_2: begin		// Initiate write, start I2C transmissions
			r_state_next	= READ_3;
			r_adr_next		= 3'h2;
			r_din_next		= {8'hE5, 1'b1, i2c_addr_vio};
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		READ_3: begin
			r_state_next	= READ_4;
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		READ_4: begin		// Send repeated start, read from slave
			r_state_next	= READ_5;
			r_adr_next		= 3'h2;
			r_din_next		= {8'hF3, 1'b1, i2c_addr_vio};
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b1;
			r_stb_next		= 1'b1;
			r_cyc_next		= 1'b1;
			r_start_next	= 2'b00;
		end
		READ_5: begin
			r_state_next	= CFG_DONE;
			r_adr_next		= r_adr;
			r_din_next		= r_din;
			r_cnt_next		= 8'hFF;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
		default: begin
			r_state_next	= RESET;
			r_adr_next		= 3'h0;
			r_din_next		= 16'h0000;
			r_cnt_next		= 8'h00;
			r_we_next		= 1'b0;
			r_stb_next		= 1'b0;
			r_cyc_next		= 1'b0;
			r_start_next	= 2'b00;
		end
	endcase
end

assign	cfg_addr = r_cnt;

cfg_rom cfg_rom_inst (
	.clka	(clk),
	.addra	(cfg_addr),
	.douta	(cfg_dout)
);

i2c_master_wbs_16 # (
	.WRITE_FIFO_ADDR_WIDTH	(8)
) i2c_master_inst (
	.clk			(clk),
	.rst			(rst),
	// Wishbone interface signals
	.wbs_adr_i		(r_adr),
	.wbs_dat_i		(r_din),
	.wbs_dat_o		(dout_vio),
	.wbs_we_i		(r_we),
	.wbs_sel_i		(2'b11),
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

assign	i2c_scl_ila = i2c_scl_t ? i2c_scl_i : i2c_scl_o;
assign	i2c_sda_ila = i2c_sda_t ? i2c_sda_i : i2c_sda_o;

ila_1 ila_i2c_inst (
	.clk		(clk),
	.probe0		(i2c_scl_ila),
	.probe1		(i2c_sda_ila),
	.probe2		(r_stb),
	.probe3		(r_cyc),
	.probe4		(w_ack)
);

vio_wb vio_wb_inst (
	.clk		(clk),
	.probe_out0	(adr_vio),
	.probe_out1	(din_vio),
	.probe_out2	(i2c_addr_vio),
	.probe_out3	(),
	.probe_out4	(start_vio),
	.probe_in0	(dout_vio)
);

endmodule