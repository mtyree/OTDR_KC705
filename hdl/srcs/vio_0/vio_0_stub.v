// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
// Date        : Fri Feb  7 11:39:24 2020
// Host        : nextlab running 64-bit Ubuntu 18.04.3 LTS
// Command     : write_verilog -force -mode synth_stub /home/mtyree/ugrad_research/OTDR_KC705/hdl/srcs/vio_0/vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2019.1" *)
module vio_0(clk, probe_out0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_out0[2:0]" */;
  input clk;
  output [2:0]probe_out0;
endmodule
