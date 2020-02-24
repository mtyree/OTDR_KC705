`timescale 1ns/1ps

module wb_i2c_tb ();

reg		sim_clk = 0;
reg		sim_rst = 1;
reg		sim_reconfig = 0;

wire	cfg_done;
wire	i2c_scl_i;
wire	i2c_scl_o;
wire	i2c_scl_t;
wire	i2c_sda_i;
wire	i2c_sda_o;
wire	i2c_sda_t;
wire	i2c_scl;
wire	i2c_sda;

assign	i2c_scl	= i2c_scl_t ? 1'bz : i2c_scl_o;
assign	i2c_sda	= i2c_sda_t ? 1'bz : i2c_sda_o;

always begin
	#10	sim_clk	= ~sim_clk;
end

initial begin
	#15	sim_rst	= ~sim_rst;
	#45 sim_reconfig = 1;
	#65 sim_reconfig = 0;
end

i2c_config # (
	.CLK_FREQ		(50_000_000),
	.I2C_FREQ		(100_000)
) i2c_config_inst (
	.clk			(sim_clk),
	.rst			(sim_rst),
	.i_cfg_start	(sim_reconfig),
	.o_cfg_done		(cfg_done),
	.i2c_scl_i		(i2c_scl_i),
	.i2c_scl_o		(i2c_scl_o),
	.i2c_scl_t		(i2c_scl_t),
	.i2c_sda_i		(i2c_sda_i),
	.i2c_sda_o		(i2c_sda_o),
	.i2c_sda_t		(i2c_sda_t)
);

endmodule