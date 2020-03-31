// Company: Next Lab @ URI
// Author: Maxwell Tyree
// Description: Top level module for testing GTX loopback

module top_gtx_loopback_test (
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
//	output GPIO_SMA_P,
//	output GPIO_SMA_N,
	inout IIC_SCL_MAIN,
	inout IIC_SDA_MAIN,
	output IIC_MUX_RESET_B,
	input RXP_IN,
	input RXN_IN,
	output TXP_OUT,
	output TXN_OUT,
	input SGMII_TX_P,
	input SGMII_TX_N
);

reg			rst_r;
reg			rst_r_r;
reg			gt_soft_reset_r;
reg			gt_soft_reset_r_r;
reg			gt_txresetdone_r1;
reg			gt_txresetdone_r2;
reg			gt_txresetdone_r3;
reg			gt_rxresetdone_r1;
reg			gt_rxresetdone_r2;
reg			gt_rxresetdone_r3;

wire		rst;
wire		gt_soft_reset;
wire		sysclk;
wire		sysclk_in;
wire		gt_sysclk;
wire		gt_sysclk_in;
wire		rec_clock_ddr;
wire		usrclk_out;
wire		gt_txresetdone_ila;
wire		gt_txresetdone;
wire		gt_rxresetdone_ila;
wire		gt_rxresetdone;
wire [2:0]	gt_loopback_vio;
wire		gt_soft_reset_vio;
wire		gt_reset_vio;
wire		gt_tx_fsm_reset_done_i;
wire		gt_rx_fsm_reset_done_i;
wire		gt_tx_fsm_reset_done_ila;
wire		gt_rx_fsm_reset_done_ila;
wire		gt_qplllock_ila;
wire		gt_qpllrefclklost_ila;
wire		gt_cplllock_ila;
wire		gt_cpllfbclklost_ila;
wire		gt_cpllreset_vio;
wire		i2c_scl_i, i2c_scl_o, i2c_scl_t;
wire		i2c_sda_i, i2c_sda_o, i2c_sda_t;
wire		w_chip_rst_n;
wire [15:0]	gt_rxdata_out;
wire [15:0]	gt_txdata_in;

assign	SI5326_RST_LS		= w_chip_rst_n;
assign	IIC_MUX_RESET_B		= w_chip_rst_n;
assign	GPIO_LED_3_LS		= 1'b0;
assign	GPIO_LED_4_LS		= SI5326_INT_ALM_LS;
assign	GPIO_LED_5_LS		= rst;
assign	gt_txdata_in		= 16'h1234;

assign	rst					= rst_r_r;
assign	gt_soft_reset		= gt_soft_reset_vio;

// Synchronize GPIO SW reset to sysclk
always @(posedge sysclk) begin
	rst_r	<= GPIO_SW_E;
	rst_r_r <= rst_r;
end

// Synchronize config_done to gt soft reset
//always @(posedge gt_sysclk) begin
//	gt_soft_reset_r		<= config_done;
//	gt_soft_reset_r_r	<= gt_soft_reset_r;
//end

// Synchronize resetdone signals to usrclk
always @(posedge gt_sysclk) begin
	gt_txresetdone_r1	<= gt_txresetdone;
	gt_rxresetdone_r1	<= gt_rxresetdone;
	
	gt_txresetdone_r2	<= gt_txresetdone_r1;
	gt_rxresetdone_r2	<= gt_rxresetdone_r1;
	
	gt_txresetdone_r3	<= gt_txresetdone_r2;
	gt_rxresetdone_r3	<= gt_rxresetdone_r2;
end

assign gt_txresetdone_ila	= gt_txresetdone_r3;
assign gt_rxresetdone_ila	= gt_rxresetdone_r3;

// RESET FSM

reset_fsm # (
	.CLK_FREQ		(200_000_000),
	.I2C_FREQ		(100_000)
) reset_fsm_inst (
	.clk			(sysclk),
	.rst			(rst),
	.o_chip_rst_n	(w_chip_rst_n),
	.o_done			(GPIO_LED_0_LS),
	.i2c_scl_i		(i2c_scl_i),
	.i2c_scl_o		(i2c_scl_o),
	.i2c_scl_t		(i2c_scl_t),
	.i2c_sda_i		(i2c_sda_i),
	.i2c_sda_o		(i2c_sda_o),
	.i2c_sda_t		(i2c_sda_t)
);

// SYSCLK BUFFERS

IBUFGDS #(
	.DIFF_TERM		("FALSE"),
	.IBUF_LOW_PWR	("TRUE"),
	.IOSTANDARD		("DEFAULT")
) SYSCLK_IBUFGDS (
	.O	(sysclk_in),
	.I	(SYSCLK_P),
	.IB	(SYSCLK_N)
);

BUFG SYSCLK_BUFG (
	.O	(sysclk),
	.I	(sysclk_in)
);

// REC CLOCK BUFFERS (TO SI5324)

ODDR #(
	.DDR_CLK_EDGE	("OPPOSITE_EDGE"),
	.INIT			(1'B0),
	.SRTYPE			("SYNC")
) ODDR_SYSCLK_TO_REC_CLOCK (
	.Q	(rec_clock_ddr),
	.C	(sysclk),
	.CE	(1'b1),
	.D1	(1'b1),
	.D2	(1'b0),
	.R	(),
	.S	()
);

OBUFDS #(
	.IOSTANDARD		("LVDS_25")
) SI5324_OBUFDS (
	.O	(REC_CLOCK_C_P),
	.OB	(REC_CLOCK_C_N),
	.I	(rec_clock_ddr)
);

// SI574 CLOCK BUFFERS

IBUFGDS GT_SYSCLK_IBUFGDS (
	.O	(gt_sysclk_in),
	.I	(GT_SYSCLK_P),
	.IB	(GT_SYSCLK_N)
);

BUFG GT_SYSCLK_BUFG (
	.O	(gt_sysclk),
	.I	(gt_sysclk_in)
);

// I2C CLOCK IO BUFFERS

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

// DEBUG DIVIDERS

Divider #(
	.PERIOD		(156_250_000)
) SI570_debug (
	.clk		(gt_sysclk),
	.rst_n		(1'b1),
	.square_out	(GPIO_LED_1_LS)
);

Divider #(
	.PERIOD		(200_000_000)
) usrclk_debug (
	.clk		(usrclk_out),
	.rst_n		(1'b1),
	.square_out	(GPIO_LED_2_LS)
);

// GT CORE INSTANCE

gtx_0 gtx_0_i (
	.soft_reset_tx_in				(gt_soft_reset), // input wire soft_reset_tx_in
	.soft_reset_rx_in				(gt_soft_reset), // input wire soft_reset_rx_in
	.dont_reset_on_data_error_in	(1'b0), // input wire dont_reset_on_data_error_in
	.q1_clk0_gtrefclk_pad_n_in		(SI5326_OUT_C_N), // input wire q1_clk0_gtrefclk_pad_n_in
	.q1_clk0_gtrefclk_pad_p_in		(SI5326_OUT_C_P), // input wire q1_clk0_gtrefclk_pad_p_in
	.gt0_tx_fsm_reset_done_out		(gt_tx_fsm_reset_done_ila), // output wire gt0_tx_fsm_reset_done_out
	.gt0_rx_fsm_reset_done_out		(gt_rx_fsm_reset_done_ila), // output wire gt0_rx_fsm_reset_done_out
	.gt0_data_valid_in				(1'b1), // input wire gt0_data_valid_in

	.gt0_txusrclk_out				(usrclk_out), // output wire gt0_txusrclk_out
	.gt0_txusrclk2_out				(), // output wire gt0_txusrclk2_out
	.gt0_rxusrclk_out				(), // output wire gt0_rxusrclk_out
	.gt0_rxusrclk2_out				(), // output wire gt0_rxusrclk2_out
//_________________________________________________________________________
//GT0  (X0Y8)
//____________________________CHANNEL PORTS________________________________
//-------------------------- Channel - DRP Ports	--------------------------
	.gt0_drpaddr_in					(9'b0), // input wire [8:0] gt0_drpaddr_in
	.gt0_drpdi_in					(16'b0), // input wire [15:0] gt0_drpdi_in
	.gt0_drpdo_out					(), // output wire [15:0] gt0_drpdo_out
	.gt0_drpen_in					(1'b0), // input wire gt0_drpen_in
	.gt0_drprdy_out					(), // output wire gt0_drprdy_out
	.gt0_drpwe_in					(1'b0), // input wire gt0_drpwe_in
//------------------------- Digital Monitor Ports --------------------------
	.gt0_dmonitorout_out			(), // output wire [7:0] gt0_dmonitorout_out
//----------------------------- Loopback Ports -----------------------------
	.gt0_loopback_in				(gt_loopback_vio),
//------------------- RX Initialization and Reset Ports --------------------
	.gt0_eyescanreset_in			(1'b0), // input wire gt0_eyescanreset_in
	.gt0_rxuserrdy_in				(1'b1), // input wire gt0_rxuserrdy_in
//------------------------ RX Margin Analysis Ports ------------------------
	.gt0_eyescandataerror_out		(), // output wire gt0_eyescandataerror_out
	.gt0_eyescantrigger_in			(1'b0), // input wire gt0_eyescantrigger_in
//---------------- Receive Ports - FPGA RX interface Ports -----------------
	.gt0_rxdata_out					(gt_rxdata_out), // output wire [15:0] gt0_rxdata_out
//------------------------- Receive Ports - RX AFE -------------------------
	.gt0_gtxrxp_in					(RXP_IN), // input wire gt0_gtxrxp_in
//---------------------- Receive Ports - RX AFE Ports ----------------------
	.gt0_gtxrxn_in					(RXN_IN), // input wire gt0_gtxrxn_in
//------------------- Receive Ports - RX Equalizer Ports -------------------
	.gt0_rxdfelpmreset_in			(1'b0), // input wire gt0_rxdfelpmreset_in
	.gt0_rxmonitorout_out			(), // output wire [6:0] gt0_rxmonitorout_out
	.gt0_rxmonitorsel_in			(2'b0), // input wire [1:0] gt0_rxmonitorsel_in
//------------- Receive Ports - RX Fabric Output Control Ports -------------
	.gt0_rxoutclkfabric_out			(), // output wire gt0_rxoutclkfabric_out
//----------- Receive Ports - RX Initialization and Reset Ports ------------
	.gt0_gtrxreset_in				(gt_reset_vio), // input wire gt0_gtrxreset_in
	.gt0_rxpmareset_in				(1'b0), // input wire gt0_rxpmareset_in
//------------ Receive Ports -RX Initialization and Reset Ports ------------
	.gt0_rxresetdone_out			(gt_rxresetdone), // output wire gt0_rxresetdone_out
//------------------- TX Initialization and Reset Ports --------------------
	.gt0_gttxreset_in				(gt_reset_vio), // input wire gt0_gttxreset_in
	.gt0_txuserrdy_in				(1'b1), // input wire gt0_txuserrdy_in
//---------------- Transmit Ports - TX Data Path interface -----------------
	.gt0_txdata_in					(gt_txdata_in), // input wire [15:0] gt0_txdata_in
//-------------- Transmit Ports - TX Driver and OOB signaling --------------
	.gt0_gtxtxn_out					(TXN_OUT), // output wire gt0_gtxtxn_out
	.gt0_gtxtxp_out					(TXP_OUT), // output wire gt0_gtxtxp_out
//--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
	.gt0_txoutclkfabric_out			(), // output wire gt0_txoutclkfabric_out
	.gt0_txoutclkpcs_out			(), // output wire gt0_txoutclkpcs_out
//----------- Transmit Ports - TX Initialization and Reset Ports -----------
	.gt0_txresetdone_out			(gt_txresetdone), // output wire gt0_txresetdone_out
//------------------------------- CPLL Ports -------------------------------
//    .gt0_cpllfbclklost_out			(gt_cpllfbclklost_ila),
//    .gt0_cplllock_out				(gt_cplllock_ila),
//    .gt0_cpllreset_in				(gt_cpllreset_vio),
//____________________________COMMON PORTS________________________________
	.gt0_qplllock_out				(gt_qplllock_ila), // output wire gt0_qplllock_out
	.gt0_qpllrefclklost_out			(gt_qpllrefclklost_ila), // output wire gt0_qpllrefclklost_out
	.gt0_qplloutclk_out				(), // output wire gt0_qplloutclk_out 
	.gt0_qplloutrefclk_out			(), // output wire gt0_qplloutrefclk_out
	.sysclk_in						(gt_sysclk) // input wire sysclk_in
);

// DEBUG CORES

vio_0 gt_control_vio (
	.clk		(gt_sysclk),
	.probe_out0	(gt_loopback_vio),
	.probe_out1	(gt_soft_reset_vio),
	.probe_out2	()
);

ila_0 gt_sys_ila (
	.clk	(gt_sysclk),
	.probe0	(gt_txresetdone_ila),
	.probe1	(gt_rxresetdone_ila),
	.probe2	(gt_tx_fsm_reset_done_ila),
	.probe3	(gt_rx_fsm_reset_done_ila),
	.probe4	(gt_qplllock_ila),
	.probe5	(gt_qpllrefclklost_ila)
);

ila_2 usrclk_ila (
	.clk	(usrclk_out),
	.probe0	(gt_txdata_in),
	.probe1	(gt_rxdata_out)
);

endmodule
