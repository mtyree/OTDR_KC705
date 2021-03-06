module top_si5324_to_sma (
	input SYSCLK_P,
	input SYSCLK_N,
	input GT_SYSCLK_P,
	input GT_SYSCLK_N,
	input GPIO_SW_E,
	input GPIO_SW_C,
	input GPIO_SW_N,
	input SI5326_OUT_C_P,
	input SI5326_OUT_C_N,
	output REC_CLOCK_C_P,
	output REC_CLOCK_C_N,
	output SI5326_RST_LS,
	input SI5326_INT_ALM_LS,
	output GPIO_LED_0_LS,
	output GPIO_LED_1_LS,
	output GPIO_LED_2_LS,
	output GPIO_LED_3_LS,
	output GPIO_LED_4_LS,
	output GPIO_LED_5_LS,
	output GPIO_SMA_P,
	output GPIO_SMA_N,
	inout IIC_SCL_MAIN,
	inout IIC_SDA_MAIN,
	output IIC_MUX_RESET_B,
	input SGMII_TX_P,
	input SGMII_TX_N
);

localparam	RESET	= 2'b00,
			IDLE	= 2'b01,
			ADD		= 2'b10,
			CHECK	= 2'b11;
			
reg [1:0]	state;
reg [31:0]	count;
reg			hard_rst;
reg			reconfig;
reg			config_done;

wire	sysclk_out;
wire	sysclk_bufg;
wire	rec_clock_ddr;
wire	si5324_out;
wire	si5324_bufg;
wire	si5324_ddr;
wire	rst;
wire	i2c_scl_i;
wire	i2c_scl_o;
wire	i2c_scl_t;
wire	i2c_sda_i;
wire	i2c_sda_o;
wire	i2c_sda_t;
//wire	i2c_scl_probe;
//wire	i2c_sda_probe;

//assign	i2c_scl_probe = i2c_scl_t ? i2c_scl_i : i2c_scl_o;
//assign	i2c_sda_probe = i2c_sda_t ? i2c_sda_i : i2c_sda_o;

assign	rst 				= GPIO_SW_E;
assign	SI5326_RST_LS		= hard_rst;
assign	IIC_MUX_RESET_B		= hard_rst;
assign	GPIO_LED_0_LS		= config_done;
assign	GPIO_LED_1_LS		= hard_rst;
assign	GPIO_LED_2_LS		= SI5326_INT_ALM_LS;
assign	GPIO_LED_3_LS		= 1'b0;
assign	GPIO_LED_4_LS		= 1'b0;
assign	GPIO_LED_5_LS		= 1'b0;

always @(posedge sysclk_bufg) begin
	if (rst) begin
		state <= RESET; // Initial state
		config_done <= 0;
		count <= 32'b0;
		hard_rst <= 0;
		reconfig <= 0;
	end else begin
		case (state)
			RESET : begin
				count <= 32'b0;
				hard_rst <= 0;
				reconfig <= 0;
				state <= ADD;
				config_done	<= 0;
			end
			IDLE : begin
				state <= IDLE;
			end
			ADD : begin
				count <= count + 32'b1;
				state <= CHECK;
			end
			CHECK : begin
				if (config_done == 0) begin
					state <= ADD;
					if (count == 32'd4_000) begin
						 hard_rst <= 1;
					end else if (count == 32'd20_004_000) begin
						 reconfig <= 1;
					end else if (count == 32'd20_004_001) begin
						 reconfig <= 0;
						 config_done <= 1;
					end
				end else begin
					state <= IDLE;
				end
			end
			default : begin
				state <= RESET;
			end
		endcase
	end
end

i2c_config # (
	.CLK_FREQ		(200_000_000),
	.I2C_FREQ		(100_000)
) i2c_config_inst (
	.clk			(sysclk_bufg),
	.rst			(rst),
	.i_cfg_start	(reconfig),
	.o_cfg_done		(),
	.i2c_scl_i		(i2c_scl_i),
	.i2c_scl_o		(i2c_scl_o),
	.i2c_scl_t		(i2c_scl_t),
	.i2c_sda_i		(i2c_sda_i),
	.i2c_sda_o		(i2c_sda_o),
	.i2c_sda_t		(i2c_sda_t)
);

// SI5324_Config_5_8_at_125MHz #(
	// .clkFreq	(200_000_000),
	// .I2CFreq	(100_000)
// ) inst_SI5324_AutoConfig (
	// .clk		(sysclk_bufg),
	// .rst_n		(~rst),
	// .RECONFIG	(reconfig),
	// .scl		(iic_scl_o),
	// .sda_o		(iic_sda_o),
	// .sda_i		(iic_sda_i),
	// .sda_t		(iic_sda_t)
// );

IBUFDS IBUFDS_SYSCLK (
	.O	(sysclk_out),
	.I	(SYSCLK_P),
	.IB	(SYSCLK_N)
);

BUFG BUFG_SYSCLK (
	.O	(sysclk_bufg),
	.I	(sysclk_out)
);

ODDR #(
	.DDR_CLK_EDGE	("OPPOSITE_EDGE"),
	.INIT			(1'B0),
	.SRTYPE			("SYNC")
) ODDR_SYSCLK_TO_REC_CLOCK (
	.Q	(rec_clock_ddr),
	.C	(sysclk_bufg),
	.CE	(1'b1),
	.D1	(1'b1),
	.D2	(1'b0),
	.R	(),
	.S	()
);

OBUFDS OBUFDS_REC_CLOCK (
	.O	(REC_CLOCK_C_P),
	.OB	(REC_CLOCK_C_N),
	.I	(rec_clock_ddr)
);

IBUFDS_GTE2 IBUFDS_GTE2_SI5324 (
	.O	(si5324_out),
	.I	(SI5326_OUT_C_P),
	.IB	(SI5326_OUT_C_N)
);

BUFG BUFG_SI5324 (
	.O	(si5324_bufg),
	.I	(si5324_out)
);

ODDR #(
	.DDR_CLK_EDGE	("OPPOSITE_EDGE"),
	.INIT			(1'B0),
	.SRTYPE			("SYNC")
) ODDR_SI5324_TO_SMA (
	.Q	(si5324_ddr),
	.C	(si5324_bufg),
	.CE	(1'b1),
	.D1	(1'b1),
	.D2	(1'b0),
	.R	(),
	.S	()
);

OBUFDS OBUFDS_SMA (
	.O	(GPIO_SMA_P),
	.OB	(GPIO_SMA_N),
	.I	(si5324_ddr)
);

IOBUF IOBUF_SDA (
	.T	(i2c_sda_t),
	.I	(i2c_sda_o),
	.O	(i2c_sda_i),
	.IO	(IIC_SDA_MAIN)
);

IOBUF IOBUF_SCL (
	.T	(i2c_scl_t),
	.I	(i2c_scl_o),
	.O	(i2c_scl_i),
	.IO	(IIC_SCL_MAIN)
);

//OBUF OBUF_SDA_TO_SMA (
//	.I	(i2c_sda_probe),
//	.O	(GPIO_SMA_P)
//);

//OBUF OBUF_SCL_TO_SMA (
//	.I	(i2c_scl_probe),
//	.O	(GPIO_SMA_N)
//);

endmodule