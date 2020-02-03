// Company: Next Lab @ URI
// Author: Maxwell Tyree
// Description: Top level module for testing GTX loopback

module top_gtx_loopback_test (
    input SYSCLK_P,
    input SYSCLK_N,
    input GPIO_SW_E,
    input GPIO_SW_C,
    input GPIO_SW_N,
    input SI5326_OUT_C_P,
    input SI5326_OUT_C_N,
    output REC_CLOCK_C_P,
    output REC_CLOCK_C_N,
    output SI5326_RST_LS,
    output SI5326_INT_ALM_LS,
    output GPIO_LED_0_LS,
    output GPIO_LED_1_LS,
    output GPIO_LED_2_LS,
    output GPIO_LED_3_LS,
    output GPIO_LED_4_LS,
    output GPIO_LED_5_LS,
    output IIC_SCL_MAIN,
    inout IIC_SDA_MAIN,
    output IIC_MUX_RESET_B,
	input RXP_IN,
	input RXN_IN,
	output TXP_OUT,
	output TXN_OUT
);

localparam	RESET	= 2'b00,
			IDLE	= 2'b01,
			ADD		= 2'b10,
			CHECK	= 2'b11;
			
reg [1:0]	state;
reg [31:0]  count;
reg			hard_rst;
reg			reconfig;
reg			config_done;

reg         rst;
reg         rst_r;
reg         rst_r_r;

wire	sysclk;
wire    drpclk;
wire	usrclk_out;

wire	gt_rxdata_out;
wire	gt_txdata_in;

assign	REC_CLOCK_C_P	= sysclk;
assign	REC_CLOCK_C_N	= ~sysclk;

assign	GPIO_LED_5_LS	= rst;
assign	SI5326_RST_LS	= hard_rst;
assign	IIC_MUX_RESET_B	= hard_rst;
assign	GPIO_LED_0_LS	= config_done;

assign	gt_txdata_in	= 16'h1234;

always @(posedge sysclk) begin
    rst_r   <= GPIO_SW_E;
    rst_r_r <= rst_r;
    rst     <= rst_r_r;
end

always @(posedge sysclk) begin
    if (rst) begin
        state <= RESET; // Initial state
        config_done <= 0;
    end else begin
        case (state)
            RESET : begin
                count <= 32'b0;
                hard_rst = 0;
                reconfig = 0;
                state <= ADD;
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
                       hard_rst = 1;
                    end else if (count == 32'd8_000) begin
                       reconfig = 1;
                    end else if (count == 32'd12_000) begin
                       reconfig = 0;
                       config_done = 1;
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

IBUFGDS #(
	.DIFF_TERM		("FALSE"),
	.IBUF_LOW_PWR	("TRUE"),
	.IOSTANDARD		("DEFAULT")
) IBUFGDS_inst (
	.O	(sysclk),
	.I	(SYSCLK_P),
	.IB	(SYSCLK_N)
);

SI5324_Config_1_1_at_200MHz #(
    .clkFreq	(200_000_000),
    .I2CFreq	(100_000)
) inst_SI5324_AutoConfig (
    .clk        (sysclk),
	.rst_n      (~rst),
	.RECONFIG   (reconfig),
	.scl        (IIC_SCL_MAIN),
	.sda        (IIC_SDA_MAIN)
);

gtx_0 gtx_0_i (
	.soft_reset_tx_in				(~rst), // input wire soft_reset_tx_in
	.soft_reset_rx_in				(~rst), // input wire soft_reset_rx_in
	.dont_reset_on_data_error_in	(1'b1), // input wire dont_reset_on_data_error_in
	.q1_clk0_gtrefclk_pad_n_in		(SI5326_OUT_C_N), // input wire q1_clk0_gtrefclk_pad_n_in
	.q1_clk0_gtrefclk_pad_p_in		(SI5326_OUT_C_P), // input wire q1_clk0_gtrefclk_pad_p_in
	.gt0_tx_fsm_reset_done_out		(), // output wire gt0_tx_fsm_reset_done_out
	.gt0_rx_fsm_reset_done_out		(), // output wire gt0_rx_fsm_reset_done_out
	.gt0_data_valid_in				(1'b1), // input wire gt0_data_valid_in

	.gt0_txusrclk_out				(usrclk_out), // output wire gt0_txusrclk_out
	.gt0_txusrclk2_out				(), // output wire gt0_txusrclk2_out
	.gt0_rxusrclk_out				(), // output wire gt0_rxusrclk_out
	.gt0_rxusrclk2_out				(), // output wire gt0_rxusrclk2_out
//_________________________________________________________________________
//GT0  (X0Y8)
//____________________________CHANNEL PORTS________________________________
//-------------------------- Channel - DRP Ports  --------------------------
    .gt0_drpaddr_in                 (9'b0), // input wire [8:0] gt0_drpaddr_in
    .gt0_drpdi_in                   (16'b0), // input wire [15:0] gt0_drpdi_in
    .gt0_drpdo_out                  (), // output wire [15:0] gt0_drpdo_out
    .gt0_drpen_in                   (1'b0), // input wire gt0_drpen_in
    .gt0_drprdy_out                 (), // output wire gt0_drprdy_out
    .gt0_drpwe_in                   (1'b0), // input wire gt0_drpwe_in
//------------------------- Digital Monitor Ports --------------------------
    .gt0_dmonitorout_out            (), // output wire [7:0] gt0_dmonitorout_out
//------------------- RX Initialization and Reset Ports --------------------
    .gt0_eyescanreset_in            (1'b0), // input wire gt0_eyescanreset_in
    .gt0_rxuserrdy_in               (1'b1), // input wire gt0_rxuserrdy_in
//------------------------ RX Margin Analysis Ports ------------------------
    .gt0_eyescandataerror_out       (), // output wire gt0_eyescandataerror_out
    .gt0_eyescantrigger_in          (1'b0), // input wire gt0_eyescantrigger_in
//---------------- Receive Ports - FPGA RX interface Ports -----------------
    .gt0_rxdata_out                 (gt_rxdata_out), // output wire [15:0] gt0_rxdata_out
//------------------------- Receive Ports - RX AFE -------------------------
    .gt0_gtxrxp_in                  (RXP_IN), // input wire gt0_gtxrxp_in
//---------------------- Receive Ports - RX AFE Ports ----------------------
    .gt0_gtxrxn_in                  (RXN_IN), // input wire gt0_gtxrxn_in
//------------------- Receive Ports - RX Equalizer Ports -------------------
    .gt0_rxdfelpmreset_in           (1'b0), // input wire gt0_rxdfelpmreset_in
    .gt0_rxmonitorout_out           (), // output wire [6:0] gt0_rxmonitorout_out
    .gt0_rxmonitorsel_in            (2'b0), // input wire [1:0] gt0_rxmonitorsel_in
//------------- Receive Ports - RX Fabric Output Control Ports -------------
    .gt0_rxoutclkfabric_out         (), // output wire gt0_rxoutclkfabric_out
//----------- Receive Ports - RX Initialization and Reset Ports ------------
    .gt0_gtrxreset_in               (1'b0), // input wire gt0_gtrxreset_in
    .gt0_rxpmareset_in              (1'b0), // input wire gt0_rxpmareset_in
//------------ Receive Ports -RX Initialization and Reset Ports ------------
    .gt0_rxresetdone_out            (), // output wire gt0_rxresetdone_out
//------------------- TX Initialization and Reset Ports --------------------
    .gt0_gttxreset_in               (1'b0), // input wire gt0_gttxreset_in
    .gt0_txuserrdy_in               (1'b1), // input wire gt0_txuserrdy_in
//---------------- Transmit Ports - TX Data Path interface -----------------
    .gt0_txdata_in                  (gt_txdata_in), // input wire [15:0] gt0_txdata_in
//-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .gt0_gtxtxn_out                 (TXN_OUT), // output wire gt0_gtxtxn_out
    .gt0_gtxtxp_out                 (TXP_OUT), // output wire gt0_gtxtxp_out
//--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    .gt0_txoutclkfabric_out         (), // output wire gt0_txoutclkfabric_out
    .gt0_txoutclkpcs_out            (), // output wire gt0_txoutclkpcs_out
//----------- Transmit Ports - TX Initialization and Reset Ports -----------
    .gt0_txresetdone_out            (), // output wire gt0_txresetdone_out

//____________________________COMMON PORTS________________________________
	.gt0_qplllock_out				(), // output wire gt0_qplllock_out
	.gt0_qpllrefclklost_out			(), // output wire gt0_qpllrefclklost_out
	.gt0_qplloutclk_out				(), // output wire gt0_qplloutclk_out 
	.gt0_qplloutrefclk_out			(), // output wire gt0_qplloutrefclk_out
	.sysclk_in						(sysclk) // input wire sysclk_in
);

ila_0 usrclk_ila (
	.clk	(usrclk_out),
	.probe0	(1'b0),
	.probe1	(gt_txdata_in),
	.probe2	(1'b0),
	.probe3	(gt_rxdata_out),
	.probe4	(1'b0)
);

endmodule