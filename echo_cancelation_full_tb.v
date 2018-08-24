module echo_cancelation_full_tb ();

reg sampling_light;

reg clk_operation;
reg [12:0] sampling_cycle, sampling_cycle_counter;

reg rst,enable_MUT1,enable_MUT2,enable_MUT3,enable_MUT4,enable_MUT5;
wire [15:0] sig16b;
wire [63:0] sig_double;
wire [63:0] signal_without_echo;
wire [10:0] signal_without_echo_exp;
wire ready_MUT1,ready_MUT2,ready_MUT3;
wire [63:0] signal_lag,signal_align_MUT2;
reg [63:0] para_in_0,para_in_1,para_in_2,para_in_3;
wire [63:0] para_0,para_1,para_2,para_3;
wire [10:0] e_exp,normalize_amp_exp;
wire [63:0] e;
integer iteration;
reg enable_sampling_MUT2, enable_sampling_MUT3, enable_sampling_MUT4;
reg enable_para_approx;
reg [63:0] double_MUT5;
wire [15:0] sig16b_MUT5;          //final output

initial begin
clk_operation = 1;
enable_para_approx = 1;
sampling_cycle = 4000;
sampling_cycle_counter = 0;
rst = 1;
#200
rst = 0;
para_in_0[63] = 0;
para_in_0[62:52] = 11'b01111111110;
para_in_0[51:0] = $urandom;

para_in_1[63] = 0;
para_in_1[62:52] = 11'b01111111110;
para_in_1[51:0] = $urandom;

para_in_2[63] = 0;
para_in_2[62:52] = 11'b01111111110;
para_in_2[51:0] = $urandom;

para_in_3[63] = 0;
para_in_3[62:52] = 11'b01111111110;
para_in_3[51:0] = $urandom;

iteration = 0;

#400000
enable_para_approx <= 0;
end

always #1 begin
	clk_operation <= ~clk_operation;
	sampling_cycle_counter <= sampling_cycle_counter + 1;
		if (sampling_cycle_counter >= sampling_cycle - 1) begin
			sampling_cycle_counter <= 0;
			sampling_light <= 1;
		end
		else sampling_light <= 0;
end

signal_generator MUT0(
	.sampling_cycle_counter(sampling_cycle_counter),
	.clk_operation(clk_operation),
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
	.enable_sampling(enable_sampling_MUT2),
	.enable(enable_MUT2),
	.sampling_cycle_counter(sampling_cycle_counter),
	.clk_operation(clk_operation),
	.signal(sig_double), 
	.para_0(para_in_0), 
	.para_1(para_in_1), 
	.para_2(para_in_2), 
	.para_3(para_in_3),
		.signal_lag(signal_lag),
		.signal_align(signal_align_MUT2),
		.ready(ready_MUT2)
);

double_to_sig16b MUT3(
	.sampling_cycle_counter(sampling_cycle_counter),
	.clk_operation(clk_operation),
	.rst(rst),
	.enable(enable_MUT3),		
	.double(signal_lag),
		.sig16b(sig16b_lag_MUT3)
);

double_to_sig16b MUT4(
	.sampling_cycle_counter(sampling_cycle_counter),
	.clk_operation(clk_operation),
	.rst(rst),
	.enable(enable_MUT4),		
	.double(signal_align_MUT2),
		.sig16b(sig16b_MUT4)
);

echo_cancelation_full MUT5(
	.sig16b(sig16b_MUT4),
	.sig16b_lag(sig16b_lag_MUT3),
	.clk_operation(clk_operation),
	.sampling_cycle(sampling_cycle),
	.sampling_cycle_counter(sampling_cycle_counter),
	.rst(rst),
	.enable(enable_MUT5),
		.sig16b_without_echo(sig16b_without_echo)
);

initial begin
	enable_sampling_MUT2 <= 0;
	enable_sampling_MUT3 <= 0;
	enable_sampling_MUT4 <= 0;
	#8000;	
	enable_sampling_MUT2 <= 1;
	enable_sampling_MUT3 <= 0;
	enable_sampling_MUT4 <= 1;
	#8000;
	enable_sampling_MUT2 <= 1;
	enable_sampling_MUT3 <= 1;
	enable_sampling_MUT4 <= 1;
end

always @(posedge clk_operation) begin
	if (enable_para_approx) begin
		if (sampling_cycle_counter == 0) begin
			enable_MUT1 <= 1;
			#4            //double operation clk       
			enable_MUT1 <= 0;
			#16
			if (ready_MUT1) begin
				enable_MUT2 <= 1;
				#4 
				enable_MUT2 <= 0;
/*$display(
"##iteration: %d", iteration
);*/
			end
			#1200
			if (ready_MUT2) begin
				enable_MUT3 <= 1;
				#4 
				enable_MUT3 <= 0;
			end
			#2500
			if (ready_MUT3) begin
				enable_MUT5 <= 1;
				double_MUT5 <= e;
				iteration <= iteration + 1;
			end
		end
	end
	else begin
		if (sampling_cycle_counter == 0) begin
			enable_MUT1 <= 1;
			#4            //double operation clk       
			enable_MUT1 <= 0;
			#16
			if (ready_MUT1) begin
				enable_MUT2 <= 1;
				#4 
				enable_MUT2 <= 0;
/*$display(
"##iteration: %d", iteration
);*/
			end
			#1200
			enable_MUT4 <= 1;
			enable_MUT5 <= 1;

			#4 
			enable_MUT4 <= 0;
			#1200
			if (ready_MUT4) begin
				enable_MUT5 <= 1;
				double_MUT5 <= signal_without_echo;
			end
		end
	end
end
endmodule //echo_cancelation_full_tb