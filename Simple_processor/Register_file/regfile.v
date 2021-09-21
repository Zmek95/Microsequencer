/* regfile.v:
 *
 * Register file for processor.
 * 
 * Contains 7 registers, and muxes to move the data in and out.
 * 
 */

module REGFILE (
   // Outputs
   ABUS, BBUS,
   // Inputs
   ASEL, BSEL, DSEL, DIN, RIN, CLK, RST
   );
   input [2:0]   ASEL,BSEL,DSEL;
   input [15:0]  DIN,RIN;
   output [15:0] ABUS,BBUS;
   input 	 CLK;
   input 	 RST;

reg [15:0] ABUS, BBUS;	
reg [15:0] R [1:7];		// Array of 7 registers 16-bit wide
integer i = 1;			// Used as counter in the for-loop

/* Reset all registers on negative edge of reset signal */
always @(negedge RST)
begin
	for(i = 1; i < 8; i = i + 1)
		R[i] = 0;
end

/* Write RIN into selected register based on value of DSEL, do nothing if DSEL equals 0 */
always @(posedge CLK)
begin

	if(DSEL != 0)
		R[DSEL] = RIN;
		
end

/* Implement ABUS and BBUS MUX's for selecting R1-R7 based on ASEL and BSEL respectively */
/* DIN is passed to the bus if the select line equals 0 */
assign R_vector = {R[1],R[2],R[3],R[4],R[5],R[6],R[7]};// Used in sensitivity list for R
always @(ASEL or BSEL or DIN or R_vector)
begin

	if(ASEL == 0)
		ABUS = DIN;
	else
		ABUS = R[ASEL];

	if(BSEL == 0)
		BBUS = DIN;
	else
		BBUS = R[BSEL];
		
end
   
endmodule // REGFILE
