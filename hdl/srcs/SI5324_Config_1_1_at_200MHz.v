//////////////////////////////////////////////////////////////////////////////////
// SI5324 AutoConfig generated based on 
//				SI5324 Config 1-1 at 200MHz generated from SI DSPLLsim software
//
// By Elliott Koehn
//
// Autogenerated on 2019/10/10 12:25:27
//
//////////////////////////////////////////////////////////////////////////////////

module SI5324_Config_1_1_at_200MHz#(

	parameter clkFreq = 200_000_000,
	parameter I2CFreq = 100_000

	)(
		input clk,
		input rst_n,
		input RECONFIG,
		output scl,
		inout sda
		);

	localparam IDLE = 3'd0; 
	localparam CHECK = 3'd1;
	localparam START = 3'd2;
	localparam WAIT_DONE = 3'd3;
	localparam CLR = 3'd4;
	localparam INC = 3'd5;
	localparam WAIT1 = 3'd6; 
	localparam DONE = 3'd7; 

	wire reset = ~rst_n;

	reg [23:0] SI_DATA;

	reg [5:0] counter;

	always @ (posedge clk or posedge reset) begin
		if(reset) begin
			counter <= 0;
		end
		else begin
			if(clr) begin
				counter <= 0;
			end
			else if (enc) begin
				counter <= counter + 1;
			end
		end
	end

	reg [2:0] state,nextstate;

	always @ (posedge clk or posedge reset) begin
		if(reset) begin
			state <= IDLE;
		end
		else begin
			state <= nextstate;
		end
	end
	reg clr;
	reg enc;
	reg start;
	wire done;
	always @ (*) begin
		clr = 0;
		enc = 0;
		start = 0;
		nextstate = state;
		case(state)
		IDLE:begin
			clr = 1;
			if(RECONFIG)
				nextstate = CHECK;
		end
		CHECK:begin
			clr = 0;
			if(counter < 6'd43) begin
				nextstate = START;
			end
			else begin
				nextstate = DONE;
			end
		end
		START:begin
			start = 1;
			nextstate = WAIT_DONE;
		end
		WAIT_DONE:begin
			start = 1;
			if(done) begin
				nextstate = CLR;
			end
		end
		CLR:begin
			if(done == 0) begin
				nextstate = INC;
			end
		end
		INC:begin
			enc = 1;
			nextstate = WAIT1;
		end
		WAIT1:begin
			nextstate = CHECK;
		end
		DONE:begin
			if(~RECONFIG) begin
				nextstate = DONE;
			end
		end
		endcase
	end


	always @ (*) begin
		case(counter)
		6'd0: begin SI_DATA = {8'hE8,8'h90,8'h90}; end
		6'd1: begin SI_DATA = {8'hD0,8'd0,8'h14}; end
		6'd2: begin SI_DATA = {8'hD0,8'd1,8'hE4}; end
		6'd3: begin SI_DATA = {8'hD0,8'd2,8'hA2}; end
		6'd4: begin SI_DATA = {8'hD0,8'd3,8'h15}; end
		6'd5: begin SI_DATA = {8'hD0,8'd4,8'h92}; end
		6'd6: begin SI_DATA = {8'hD0,8'd5,8'hED}; end
		6'd7: begin SI_DATA = {8'hD0,8'd6,8'h2D}; end
		6'd8: begin SI_DATA = {8'hD0,8'd7,8'h2A}; end
		6'd9: begin SI_DATA = {8'hD0,8'd8,8'h00}; end
		6'd10: begin SI_DATA = {8'hD0,8'd9,8'hC0}; end
		6'd11: begin SI_DATA = {8'hD0,8'd10,8'h08}; end
		6'd12: begin SI_DATA = {8'hD0,8'd11,8'h42}; end
		6'd13: begin SI_DATA = {8'hD0,8'd19,8'h29}; end
		6'd14: begin SI_DATA = {8'hD0,8'd20,8'h3E}; end
		6'd15: begin SI_DATA = {8'hD0,8'd21,8'hFF}; end
		6'd16: begin SI_DATA = {8'hD0,8'd22,8'hDF}; end
		6'd17: begin SI_DATA = {8'hD0,8'd23,8'h1F}; end
		6'd18: begin SI_DATA = {8'hD0,8'd24,8'h3F}; end
		6'd19: begin SI_DATA = {8'hD0,8'd25,8'h60}; end
		6'd20: begin SI_DATA = {8'hD0,8'd31,8'h00}; end
		6'd21: begin SI_DATA = {8'hD0,8'd32,8'h00}; end
		6'd22: begin SI_DATA = {8'hD0,8'd33,8'h03}; end
		6'd23: begin SI_DATA = {8'hD0,8'd34,8'h00}; end
		6'd24: begin SI_DATA = {8'hD0,8'd35,8'h00}; end
		6'd25: begin SI_DATA = {8'hD0,8'd36,8'h03}; end
		6'd26: begin SI_DATA = {8'hD0,8'd40,8'h20}; end
		6'd27: begin SI_DATA = {8'hD0,8'd41,8'h02}; end
		6'd28: begin SI_DATA = {8'hD0,8'd42,8'h2F}; end
		6'd29: begin SI_DATA = {8'hD0,8'd43,8'h00}; end
		6'd30: begin SI_DATA = {8'hD0,8'd44,8'h00}; end
		6'd31: begin SI_DATA = {8'hD0,8'd45,8'h63}; end
		6'd32: begin SI_DATA = {8'hD0,8'd46,8'h00}; end
		6'd33: begin SI_DATA = {8'hD0,8'd47,8'h00}; end
		6'd34: begin SI_DATA = {8'hD0,8'd48,8'h63}; end
		6'd35: begin SI_DATA = {8'hD0,8'd55,8'h00}; end
		6'd36: begin SI_DATA = {8'hD0,8'd131,8'h1F}; end
		6'd37: begin SI_DATA = {8'hD0,8'd132,8'h02}; end
		6'd38: begin SI_DATA = {8'hD0,8'd137,8'h01}; end
		6'd39: begin SI_DATA = {8'hD0,8'd138,8'h0F}; end
		6'd40: begin SI_DATA = {8'hD0,8'd139,8'hFF}; end
		6'd41: begin SI_DATA = {8'hD0,8'd142,8'h00}; end
		6'd42: begin SI_DATA = {8'hD0,8'd143,8'h00}; end
		6'd43: begin SI_DATA = {8'hD0,8'd136,8'h40}; end
		default: SI_DATA = 24'h000000;
		endcase
	end


	I2C_master #(
			.clkFreq(clkFreq),
			.I2CFreq(I2CFreq)
		) inst_I2C_master (
			.clk			(clk),
			.reset		(reset),
			.data_in	(SI_DATA),
			.start		(start),
			.wr				(1),
			.scl			(scl),
			.sda			(sda),
			.busy			(),
			.done			(done),
			.error		(),
			.data_out ()
		);

endmodule
