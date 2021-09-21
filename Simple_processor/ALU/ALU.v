/* ALU.v: 
 * 
 * Processor ALU block.  This block is purely
 * combinational.  It implements 16 ALU operations, controlled by the
 * FSEL input.
 * 
 */
module ALU (

	// Outputs
   	FOUT, C, Z, S, V,
   	// Inputs
   	ABUS, BBUS, FSEL, CIN
   	) ;
   	input  [15:0] ABUS,BBUS;          /* Data busses */
   	input [3:0] 	 FSEL;	             /* Function select */
   	input         CIN;                /* Carry in */
   	output [15:0] FOUT;               /* Function out */
   	output 	 C,Z,S,V;            /* Current status out */

   	/* Reg for output so we can use them in always blocks. */
   	reg [15:0] 	 FOUT;
   	reg 		 C,Z,S,V;
	reg [16:0]	 TMP;
	
	always@(*)
	begin
		case (FSEL)
			
			4'b0000 : 	begin
						TMP = ABUS;					//Transfer ABUS
						C = 1'b0; V = 1'b0;
					end

			4'b0001 : 	begin
						TMP = ABUS + 1;					//Increment ABUS by one
						if (ABUS == 16'hFFFF) begin
							C = 1'b1; 
							V = 1'b0;
						end
						else if (ABUS == 16'h7FFF) begin
							V = 1'b1;
							C = 1'b0;
						end
						else begin
							V = 1'b0;
							C = 1'b0;
						end
					end

			4'b0010 : 	begin
						TMP = ABUS - 1;					//Decrement ABUS by one 
						if (ABUS == 16'h0000) begin
							C = 1'b1;
							V = 1'b0;
						end
						else if (ABUS == 16'h8000) begin
							V = 1'b1;
							C = 1'b0;
						end
						else begin
							V = 1'b0;
							C = 1'b0;
						end
					end

			4'b0011 : 	begin
						TMP = ABUS + BBUS + CIN;			//Add ABUS+BBUS+CIN	
						C = TMP[16];
						V = ((!(ABUS[15]^BBUS[15])) && (TMP[15]^BBUS[15]));
					end

			4'b0100 : 	begin
						TMP = ABUS - BBUS - CIN; 			//Subtract ABUS-BBUS-CIN
						C = TMP[16];
						V = ((!(ABUS[15]^!BBUS[15])) && (TMP[15]^!BBUS[15]));
					end

			4'b0101 : 	begin
						TMP = ABUS & BBUS;				//Bitwise ABUS & BBUS
						V = 1'b0; C = 1'b0;
					end

			4'b0110 : 	begin
						TMP = ABUS | BBUS;				//Bitwise ABUS | BBUS
						V = 1'b0; C = 1'b0;
					end

			4'b0111 : 	begin
						TMP = ABUS ^ BBUS;				//Bitwise ABUS ^ BBUS
						V = 1'b0; C = 1'b0;
					end

			4'b1000 : 	begin
						TMP = ~ABUS;					//Bitwise ! ABUS
						V = 1'b0; C = 1'b0;
					end

			4'b1001 : 	begin
						C = ABUS[15]; TMP = {ABUS[14:0],1'b0};		//Shift ABUS left, C = ABUS[15], FOUT[0] = 0
						if (ABUS[15] ^ ABUS[14])
							V = 1'b1;
						else
							V = 1'b0;
					end
	
			4'b1010 : 	begin
						C = ABUS[0]; TMP = ABUS[15:1];			//Shift ABUS right, C = ABUS[0], FOUT[15] = 0
						if (ABUS[15] == 1'b1)
							V = 1'b1;
						else
							V = 1'b0;
					end

			4'b1011 : 	begin
						if (ABUS == 16'hFFFF) 				//Arithmetic shift A right, bit C contains ABUS[0]
							TMP = 16'h0000;
						else
							TMP = {ABUS[15],ABUS[15:1]};
						C = ABUS[0]; V = 1'b0;
					end

			4'b1100 : 	begin
						TMP = {ABUS[14:0],CIN}; C = ABUS[15];		//Rotate left through carry, FOUT[0] = CIN, C = ABUS[15]
						if (ABUS[15] ^ ABUS[14])
							V = 1'b1;
						else
							V = 1'b0;
					end
	
			4'b1101 : 	begin
						TMP = {CIN,ABUS[15:1]}; C = ABUS[0];		//Rotate right through carry, FOUT[15] = CIN, C = ABUS[0]
						if (ABUS[15] ^ CIN)
							V = 1'b1;
						else
							V = 1'b0;
					end
	
			4'b1110 : 	begin
						TMP = {ABUS[7:0],ABUS[15:8]};			//Byte reverse
						C = 1'b0; V = 1'b0;
					end

			4'b1111 :	begin
						$display("Reserved 2");				//Reserved 2
						C = 1'b0; V = 1'b0;
						TMP = 16'hXXXX;
					end

			default: 	begin
						$display("Error in selection");
						C = 1'b0; V = 1'b0;
						TMP = 16'hXXXX;
					end
		
		endcase
		//zero check and signed check
		if (TMP[15:0] == 16'h0000) begin
			Z = 1'b1;
			S = 1'b0;
		end
		else if (TMP[15] == 1'b1) begin
			S = 1'b1;
			Z = 1'b0;
		end
		else begin
			S = 1'b0;
			Z = 1'b0;
		end

		FOUT = TMP[15:0];
		
	end

endmodule // ALU

