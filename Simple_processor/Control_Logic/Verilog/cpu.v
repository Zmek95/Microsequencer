/* cpu.v:
 *
 * CPU implementation
 * 
 */

module CPU(/*AUTOARG*/
   // Outputs
   DATA_O, ADDR, RD, WR,
   // Inputs
   DATA_I, CLK, RST
   );
   input [15:0]  DATA_I;
   output [15:0] DATA_O;
   output [15:0] ADDR;
   output 	 RD;
   output 	 WR;
   
   input 	 CLK;
   input 	 RST;
 
   reg [15:0] 	 IR;
   reg [15:0] 	 MAR;
   reg [10:0] 	 CAR,CAR_next;
   wire [10:0] 	 EXT_ADRS;
   
   wire [15:0] 	 ABUS,BBUS,FOUT;
   wire 	 LDMAR,LDIR,RFMUX,DMUX;
	    
   /* Status flag registers, and wires */
   reg 		 Z,S,C,V;
   wire 	 ZOUT,SOUT,COUT,VOUT;
   wire          UPZ,UPS,UPC,UPV;
 	 
   
   /* Buffer address register, and data out signals */
   assign ADDR = MAR;
   assign DATA_O = FOUT;
   

   /* Instantiate microcode ROM */
   wire [44:0]  ROM_out;

   MICROCODE_ROM MICROCODE_ROM1(
      .ADDR_in(CAR),
      .ROM_out(ROM_out));

   wire [ 2:0]  ASEL;
   wire [ 2:0]  BSEL;
   wire [ 2:0]  DSEL;
   wire [ 3:0]  FSEL;
   wire [ 3:0]  UPDF;
   wire         MUX1;
   wire [ 3:0]  MUX2;
   wire [15:0]  DATA;
   wire [ 6:0]  MISC;

   assign                 ASEL = ROM_out[44:42];    // bit size:3
   assign                 BSEL = ROM_out[41:39];    // bit size:3
   assign                 DSEL = ROM_out[38:36];    // bit size:3
   assign                 FSEL = ROM_out[35:32];    // bit size:4
   assign                 UPDF = ROM_out[31:28];    // bit size:4
   assign                 MUX1 = ROM_out[27];       // bit size:1
   assign                 MUX2 = ROM_out[26:23];    // bit size:4
   assign                 DATA = ROM_out[22: 7];    // bit size:16
   assign                 MISC = ROM_out[ 6: 0];    // bit size:7

   /* Split out the MISC field */
   assign RD    = MISC[0];
   assign WR    = MISC[1];
   assign LDMAR = MISC[2];
   assign LDIR  = MISC[3];
   assign RFMUX = MISC[4];
   assign DMUX  = MISC[5];

   /* Split out Update Flags field */
   assign UPZ   = UPDF[3];
   assign UPS   = UPDF[2];
   assign UPC   = UPDF[1];
   assign UPV   = UPDF[0];
   
   /* Instantiate Register file */
   REGFILE REGFILE1(   // Outputs
		       .ABUS(ABUS),
		       .BBUS(BBUS),
		       // Inputs
	   	       .DSEL(RFMUX ? IR[2:0] : DSEL),
		       .BSEL(RFMUX ? IR[5:3] : BSEL),
	   	       .ASEL(RFMUX ? IR[8:6] : ASEL),
		       .DIN(DMUX ? DATA    : DATA_I),
		       .RIN(FOUT),
		       .CLK(CLK),
		       .RST(RST));
      
   /* Instantiate ALU */
   ALU ALU1(// Outputs
	    .FOUT(FOUT),
	    .C(COUT), .Z(ZOUT), .S(SOUT), .V(VOUT),
	    // Inputs
	    .ABUS(ABUS),
	    .BBUS(BBUS),
	    .FSEL(FSEL),
	    .CIN(C));

   /* ALU Flag updating */
   always @(posedge CLK or negedge RST)
     if(RST==1'b0) begin
	Z <= 0;
	S <= 0;
	C <= 0;
	V <= 0;
	MAR <= 0;
	IR <= 0;
     end else begin
	if(UPZ) begin
	   Z <= ZOUT;
	end

	if(UPS) begin
	   S <= SOUT;
	end
	
	if(UPC) begin
	   C <= COUT;
		$display("Carry = ",C);
	end
	
	if(UPV) begin
	   V <= VOUT;
	end

	if(LDMAR) begin
		MAR <= ABUS;
	end

	if(IR) begin
		IR <= DATA_I;
	end

     end

   /* Sequencer logic -- Implement your logic for CAR generation here */

   /* Muxes */
   reg [10:0] MUX1_OUT;
   reg MUX2_OUT;
   assign EXT_ADRS = {1'b0, IR[15:9], 3'b000};
   
   // Switch Synch and Async?
   /* Synchronous part */
	always@(posedge CLK or negedge RST )   
	begin
		if (RST == 1'b0)
			CAR <= 11'b00000000000;
		else if (MUX2_OUT == 1'b0)
			CAR <= CAR + 1;
		else
			CAR <= MUX1_OUT;
	end 

   /* Asynchronous part */
   	always@(*)
	begin
		case (MUX1)
		
			1'b0:	MUX1_OUT = DATA[10:0];
			
			1'b1:	MUX1_OUT = EXT_ADRS;
		
		endcase
		
		
		case (MUX2)
		
			4'b0000:	MUX2_OUT = 1'b0;
			
			4'b0001:	MUX2_OUT = 1'b1;
			
			4'b0010:	begin
					MUX2_OUT = C;
					$display("Carry = ",C);
					end
			
			4'b0011:	MUX2_OUT = !C;
		
			4'b0100:	MUX2_OUT = Z;
			
			4'b0101:	MUX2_OUT = !Z;
			
			4'b0110:	MUX2_OUT = S;
			
			4'b0111:	MUX2_OUT = !S;
			
			4'b1000:	MUX2_OUT = V;
			
			4'b1001:	MUX2_OUT = !V;
			
			4'b1010:	begin
						if (S ^ V)
							MUX2_OUT = 1'b1;
						else
							MUX2_OUT = 1'b0;
					end
					
			4'b1011:	begin
						if ((S ^ V == 0) & (Z == 0))
							MUX2_OUT = 1'b1;
						else
							MUX2_OUT = 1'b0;
					end
			
			default:	begin
						$display("Error in selection");
						MUX2_OUT = 1'bX;
					end
		
		endcase
	end
	

   
endmodule
	 
