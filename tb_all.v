/**************************************************************************
***                            Testbench ALL                            ***     
***                            Author :   LAK                           ***  
**************************************************************************/

`timescale 1us / 1us
module tb_all ();

reg clk_sampling,clk_operation;
reg rst,enable_MUT1,enable_MUT2,enable_MUT3;
wire [15:0] sig16b;
wire [63:0] sig_double;
wire ready_MUT1,ready_MUT2,ready_MUT3;
wire [63:0] signal_lag,signal_align;
reg [63:0] para_in_0,para_in_1,para_in_2,para_in_3;
wire [63:0] para_0,para_1,para_2,para_3;

initial begin
clk_sampling = 1;
clk_operation = 1;
rst = 1;
#200
rst = 0;
para_in_0[63] = 0;
para_in_0[62:52] = 01111111110;
para_in_0[51:0] = $urandom;

para_in_1[63] = 0;
para_in_1[62:52] = 01111111110;
para_in_1[51:0] = $urandom;

para_in_2[63] = 0;
para_in_2[62:52] = 01111111110;
para_in_2[51:0] = $urandom;

para_in_3[63] = 0;
para_in_3[62:52] = 01111111110;
para_in_3[51:0] = $urandom;
end

always #1000 clk_sampling = ~clk_sampling; //looks like we want # to be odd number.
always #1 clk_operation = ~clk_operation;


signal_generator MUT0(
	.clk_sampling(clk_sampling),
		.signal(sig16b)
);

sig16b_to_double MUT1(
	.clk_operation(clk_operation),
	.rst(rst),
	.sig16b(sig16b),
	.enable(enable_MUT1),
		.double(sig_double),
		.ready(ready_MUT1)
);

lag_generator MUT2(
	.rst(rst),
	.enable(enable_MUT2),
	.clk_sampling(clk_sampling),
	.clk_operation(clk_operation),
	.signal(sig_double), 
	.para_0(para_in_0), 
	.para_1(para_in_1), 
	.para_2(para_in_2), 
	.para_3(para_in_3),
		.signal_lag(signal_lag),
		.signal_align(signal_align),
		.ready(ready_MUT2)
);

echo_approx MUT3(
.rst(rst),
.clk_sampling(clk_sampling),
.clk_operation(clk_operation),
.enable(enable_MUT3),
.signal(signal_align), 
.signal_lag(signal_lag),
.gamma(64'b0011111111010000000000000000000000000000000000000000000000000000),   //default 64'b0011111111010000000000000000000000000000000000000000000000000000; //0.01
.mu(64'b0011111111110000000000000000000000000000000000000000000000000000),	 //default 64'b0011111111110000000000000000000000000000000000000000000000000000; //1
	.para_0(para_0), 
	.para_1(para_1), 
	.para_2(para_2),
	.para_3(para_3),
	.ready(ready_MUT3)
);

always @(posedge clk_sampling) begin
	enable_MUT1 <= 1;
	#2            //double operation clk       
	enable_MUT1 <= 0;
end

always @(negedge clk_sampling) begin
	if (ready_MUT1) begin
		enable_MUT2 <= 1;
		#4 
		enable_MUT2 <= 0;
	end
end

always @(negedge clk_operation) begin
	if (ready_MUT2) begin
		enable_MUT3 <= 1;
		#4 
		enable_MUT3 <= 0;
	end
end
endmodule //tb_all
