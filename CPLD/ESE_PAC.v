`timescale 1ns / 1ps


//////////////////////////////////////////////////////////////////////////////////
// Company: illegal function call
// Engineer: @v9938
// 
// Create Date:    05/1/2021 
// Design Name: ESE Pana Amusement Cardridge
// Module Name:    ESE_PAC
// Project Name: ESE PAC
// Target Devices: XC9536XL
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision 1.0 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module ESE_PAC(
	input SLT_CLOCK,				//from MSX Slot
	input SLT_RESETn,				//from MSX Slot
	input SLT_SLTSL,				//from MSX Slot
	input SLT_WEn,					//from MSX Slot
	input SLT_RDn,					//from MSX Slot
    input [15:0] SLT_A,			//from MSX Slot
    input [7:0] SLT_D,				//from MSX Slot
    output ROM_WEn,					//To Flash ROM / MRAM
    output ROM_OEn,					//To Flash ROM / MRAM 
    output FRAM_CEn					//To MRAM
    );

//	Address Decoder==========================
// Enable SRAM
//     5FFEh: 4Dh
//     5FFFh: 69h
//
// SRAM Address
//     4000h - 5FFDh
	wire Bank1Sel;
	wire SRAMSwitchASel,SRAMSwitchBSel;
	wire SltControl;

	assign Bank1Sel				= (SLT_A[15:14]==2'b01);
	assign SRAMSwitchASel		= (SLT_A[15:0]==16'h5FFE);
	assign SRAMSwitchBSel 		= (SLT_A[15:0]==16'h5FFF);

//	Slot control==========================
	assign SltControl	= SLT_SLTSL;
	

	reg [7:0] SRAMSwitchAReg;
	reg [7:0] SRAMSwitchBReg;
	reg rdDelay;
	wire BankControlWrn;

	assign BankControlWrn	= ~(SLT_WEn |SltControl);


	always @(posedge SLT_CLOCK or negedge SLT_RESETn) begin
		if (!SLT_RESETn) begin
			SRAMSwitchAReg 	<= 8'h00;
			SRAMSwitchBReg 	<= 8'h00;
		end
		else begin
			if (BankControlWrn & SRAMSwitchASel) SRAMSwitchAReg 	<= SLT_D[7:0];
			if (BankControlWrn & SRAMSwitchBSel) SRAMSwitchBReg	 	<= SLT_D[7:0];
		end
	end

	always @(posedge SLT_CLOCK or negedge SLT_RESETn) begin
		if (!SLT_RESETn) begin
			rdDelay 	<= 1'b1;
		end
		else begin
			rdDelay  <= SLT_RDn;
		end
	end

//	Select Bank ==========================
	wire MRAMControlEnable;
	wire RamAddressEn;

	//Select BankReg
	assign MRAMControlEnable 	= (SRAMSwitchAReg == 8'h4D) & (SRAMSwitchBReg == 8'h69);


	//ROM/MRAM Address 
	assign RamAddressEn  = 		~Bank1Sel;

	// Maek ROM Conrol
    assign ROM_WEn =			SLT_WEn | RamAddressEn;
    assign ROM_OEn =			rdDelay | RamAddressEn;
    assign FRAM_CEn =			SltControl | ~(MRAMControlEnable);

endmodule
