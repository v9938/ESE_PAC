
`timescale 1ns / 100ps

// Code write by V9938

module sim_top();
parameter CYC = 145;
reg 		SLT_CLOCK;
reg 		SLT_RESETn;
reg 		SLT_SLTSL;
reg			SLT_WEn;
reg			SLT_RDn;
reg [15:0]	SLT_A;
reg [7:0]	SLT_D;

wire			ROM_WEn;
wire			ROM_OEn;
wire			FRAM_CEn;

// -----------------------------------------------------------------
task write_task; // writeタスク (addr,data)
input [15:0] addr_task;
input [7:0] data_task;
begin
	#(CYC+25)		SLT_A = addr_task;	//170
	#(CYC+10-25)	SLT_SLTSL = 1'b0;	//130+170 =300
					SLT_RDn = 1'b1;
	#(55)			SLT_D = data_task;	//355=145+210
	#(80+CYC-5)		SLT_WEn = 1'b0;		

	#(CYC+5)		$display("Write Data[%4h]=%8b ====================",SLT_A,SLT_D);
					$display("ROM WE=%1b / ROM_OE=%1b /FRAM_CEn=%1b",ROM_WEn,ROM_OEn,FRAM_CEn);
	#(CYC-25)		SLT_WEn = 1'b1;
	#(25+10)		SLT_SLTSL = 1'b1;
	#(CYC-10)		SLT_D = 8'bzzzz_zzzz;
	#(CYC);
end
endtask

task read_task; // readタスク (addr)
input [15:0] addr_task;
begin
	#(CYC+25)		SLT_A = addr_task;	//170
	#(CYC+10-25)	SLT_SLTSL = 1'b0;	//130+170 =300
					SLT_RDn = 1'b0;
	#(55+80+CYC*2)	$display("Read Data[%4h]=%8b ====================",SLT_A,SLT_D);
					$display("ROM WE=%1b / ROM_OE=%1b /FRAM_CEn=%1b",ROM_WEn,ROM_OEn,FRAM_CEn);
	#(CYC-25)		SLT_RDn = 1'b1;
	#(25+10)		SLT_SLTSL = 1'b1;
	#(CYC-10)		SLT_D = 8'bzzzz_zzzz;
	#(CYC);
end
endtask
// -----------------------------------------------------------------

initial	begin
	#40 SLT_CLOCK = 1'b1;

	forever begin
		#(CYC) SLT_CLOCK = ~SLT_CLOCK;
	end
	
end
initial begin
	SLT_RESETn = 1'bz;
	#(CYC)	SLT_RESETn = 1'b0;
	#(CYC*2)	SLT_RESETn = 1'b1;
end

initial begin
	#(CYC*5) ;
	write_task (16'h5FFE,8'h4d);
	write_task (16'h5FFF,8'h69);
	write_task (16'h4000,8'h00);
	write_task (16'h4001,8'h11);
	#(CYC*3) ;
	//Flash mode
	read_task (16'h4000);
	read_task (16'h5000);
	read_task (16'h6000);
	$finish;

end




// Instantiate the module
ESE_PAC instance_name (
    .SLT_CLOCK(SLT_CLOCK), 
    .SLT_RESETn(SLT_RESETn), 
    .SLT_SLTSL(SLT_SLTSL), 
    .SLT_WEn(SLT_WEn), 
    .SLT_RDn(SLT_RDn), 
    .SLT_A(SLT_A), 
    .SLT_D(SLT_D), 
    .ROM_WEn(ROM_WEn), 
    .ROM_OEn(ROM_OEn), 
    .FRAM_CEn(FRAM_CEn)
    );


endmodule
