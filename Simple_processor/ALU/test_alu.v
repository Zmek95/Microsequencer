/* Test bench for ALU testing */
module test_alu();
   reg [15:0] ABUS,BBUS;
   reg [3:0] FSEL;
   reg 	     CIN;
   
   
   wire [15:0] FOUT;
   wire       Z,S,C,V;

   integer    Failures = 0;
   integer    Passes   = 0;
   
   /* Instantiate ALU */
   ALU alu1 (
   .FOUT(FOUT), .Z(Z), .S(S), .C(C), .V(V),
   // Inputs
   .ABUS(ABUS), .BBUS(BBUS), .FSEL(FSEL), .CIN(CIN)
   );

   task aluop;
      input [3:0] FSEL_i;
      input [15:0] ABUS_i;
      input [15:0] BBUS_i;
      input        CIN_i;
      input [15:0] FOUT_i;
      input 	   Z_i,S_i,C_i,V_i;
      
      integer 	   SubFails;
      
      begin
	 SubFails = 0;
	 
	 FSEL = FSEL_i;
	 ABUS = ABUS_i;
	 BBUS = BBUS_i;
	 CIN  = CIN_i;
	 #1;
	 if(FOUT !== FOUT_i) begin
	    SubFails = SubFails + 1;
	    $display($time,":FAIL: ALU Output Mismatch FOUT:", FOUT,
		     " expected:",FOUT_i);
	 end
	 if(Z !== Z_i) begin
	    SubFails = SubFails + 1;
	    $display($time,":FAIL: ALU Output Mismatch Z:", Z,
		     " expected:",Z_i);
	 end
	 if(S !== S_i) begin
	    SubFails = SubFails + 1;
	    $display($time,":FAIL: ALU Output Mismatch S:", S,
		     " expected:",S_i);
	 end
	 if(C !== C_i) begin
	    SubFails = SubFails + 1;
	    $display($time,":FAIL: ALU Output Mismatch C:", C,
		     " expected:",C_i);
	 end
	 if(V !== V_i) begin
	    SubFails = SubFails + 1;
	    $display($time,":FAIL: ALU Output Mismatch V:", V,
		     " expected:",V_i);
	 end
	 if(SubFails) begin
	    Failures = Failures+1;
	    $display($time,":Failed test case was:");
            $display($time,":aluop(",
		     FSEL_i, ",",
		     ABUS_i, ",",
		     BBUS_i, ",",
		     CIN_i, ",",
		     FOUT_i, ",",
		     Z_i, ",",S_i, ",",C_i, ",",V_i, ")\n");
	 end else begin
	    Passes = Passes + 1;
	 end
      end
   endtask

/* ALU Operations */
`define TSA  4'h0
`define INC  4'h1
`define DEC  4'h2
`define ADD  4'h3
`define SUB  4'h4
`define AND  4'h5
`define OR   4'h6
`define XOR  4'h7
`define NOT  4'h8
`define SHL  4'h9
`define SHR  4'hA
`define ASR  4'hB
`define RLC  4'hC
`define RRC  4'hD
`define BREV 4'hE
`define RSV2 4'hF
   
   
      initial begin
	 $dumpfile("test_alu.vcd");
	 $dumpvars();

	 /* Transfer test, B input should not affect F */
	 /*                                Z S C V */
	 aluop(`TSA,16'h00,16'h00,0,16'h00,1,0,0,0);
	 aluop(`TSA,16'h01,16'h00,0,16'h01,0,0,0,0);
	 aluop(`TSA,16'h20,16'h42,0,16'h20,0,0,0,0);
	 aluop(`TSA,16'h40,16'h24,0,16'h40,0,0,0,0);
	 aluop(`TSA,16'h80,16'h00,0,16'h80,0,0,0,0);

	 /* Increment */
	 aluop(`INC,16'h00,16'h00,0,16'h01,0,0,0,0);
	 aluop(`INC,16'h01,16'h05,0,16'h02,0,0,0,0);
	 aluop(`INC,16'h7F,16'h10,0,16'h80,0,0,0,0);
	 aluop(`INC,16'h80,16'h00,0,16'h81,0,0,0,0);

	 /* Add */
	 aluop(`ADD,16'h00,16'h00,0,16'h00,1,0,0,0);
	 aluop(`ADD,16'h01,16'h01,0,16'h02,0,0,0,0);
	 aluop(`ADD,16'h02,16'h03,0,16'h05,0,0,0,0);
	 aluop(`ADD,16'h03,16'h02,0,16'h05,0,0,0,0);
	 aluop(`ADD,16'h7e,16'h03,0,16'd129,0,0,0,0);
	 aluop(`ADD,16'hfe,16'h02,0,16'd256,0,0,0,0);
	 aluop(`ADD,-32768, -1,0,16'd32767,0,0,1,1); // Overflow
	 aluop(`ADD, 32767,  1,0,16'd32768,0,1,0,1); // Overflow
	 aluop(`ADD,-5,      6,0,16'd1    ,0,0,1,0); // No overflow

	 /* Subtract */
	 aluop(`SUB,5,4,0,16'h0001,0,0,0,0);
	 aluop(`SUB,-4,5,0,-9,0,1,0,0);
	 aluop(`SUB,-32768,1,0,16'h7fff,0,0,0,1); // overflow
	 aluop(`SUB, 32767,-1,0,16'h8000,0,1,1,1); // overflow
	 aluop(`SUB, 10,    5,0,16'h05,0,0,0,0);

	 /* Decrement */
	 aluop(`DEC,1,0,0,16'h00,1,0,0,0);
	 aluop(`DEC,65535,0,0,16'hfffe,0,1,0,0);
	 aluop(`DEC,1,43,0,16'h00,1,0,0,0);
	 aluop(`DEC,255,0,0,254,0,0,0,0);

	 /* Logical operations */
	 aluop(`AND,16'h00,16'h00,0,16'h00,1,0,0,0);
	 aluop(`AND,16'haaaa,16'h5555,0,16'h0000,1,0,0,0);
	 aluop(`AND,16'h5a5a,16'ha5a5,0,16'h0000,1,0,0,0);
	 aluop(`AND,16'hffff,16'hffff,0,16'hffff,0,1,0,0);

	 aluop(`OR ,16'h00,16'h00,0,16'h00,1,0,0,0);
	 aluop(`OR ,16'haaaa,16'h5555,0,16'hffff,0,1,0,0);
	 aluop(`OR ,16'h5a5a,16'ha5a5,0,16'hffff,0,1,0,0);
	 aluop(`OR ,16'hffff,16'hffff,0,16'hffff,0,1,0,0);
	 aluop(`OR ,16'h0000,16'hffff,0,16'hffff,0,1,0,0);
	 aluop(`OR ,16'hffff,16'h0000,0,16'hffff,0,1,0,0);

	 aluop(`XOR,16'h0000,16'h0000,0,16'h0000,1,0,0,0);
	 aluop(`XOR,16'haaaa,16'h5555,0,16'hffff,0,1,0,0);
	 aluop(`XOR,16'h5a5a,16'ha5a5,0,16'hffff,0,1,0,0);
	 aluop(`XOR,16'hffff,16'hffff,0,16'h0000,1,0,0,0);

	 aluop(`NOT,16'h0000,16'h0000,0,16'hffff,0,1,0,0);
	 aluop(`NOT,16'haaaa,16'h5555,0,16'h5555,0,0,0,0);
	 aluop(`NOT,16'h5a5a,16'ha5a5,0,16'ha5a5,0,1,0,0);
	 aluop(`NOT,16'hffff,16'h0000,0,16'h0000,1,0,0,0);

	 aluop(`SHL,16'h0001,16'h0000,0,16'h0002,0,0,0,0);
	 aluop(`SHL,16'h4000,16'h0000,0,16'h8000,0,1,0,1);
	 aluop(`SHL,16'h8001,16'h0000,0,16'h0002,0,0,1,1);

	 aluop(`SHR,16'h0001,16'h0000,0,16'h0000,1,0,1,0);
	 aluop(`SHR,16'h4000,16'h0000,0,16'h2000,0,0,0,0);
	 aluop(`SHR,16'h8001,16'h0000,0,16'h4000,0,0,1,1);

	 aluop(`ASR,16'h0001,16'h0000,0,16'h0000,1,0,1,0);
	 aluop(`ASR,16'h4000,16'h0000,0,16'h2000,0,0,0,0);
	 aluop(`ASR,16'h8001,16'h0000,0,16'hC000,0,1,1,0);
	 aluop(`ASR,      -1,16'h0000,0,       0,1,0,1,0);

	 aluop(`RLC,16'h0001,16'h0000,0,16'h0002,0,0,0,0);
	 aluop(`RLC,16'h0001,16'h0000,1,16'h0003,0,0,0,0);
	 aluop(`RLC,16'h4000,16'h0000,0,16'h8000,0,1,0,1);
	 aluop(`RLC,16'h8001,16'h0000,0,16'h0002,0,0,1,1);
	 aluop(`RLC,16'h8001,16'h0000,1,16'h0003,0,0,1,1);

	 aluop(`RRC,16'h0001,16'h0000,0,16'h0000,1,0,1,0);
	 aluop(`RRC,16'h0001,16'h0000,1,16'h8000,0,1,1,1);
	 aluop(`RRC,16'h4000,16'h0000,0,16'h2000,0,0,0,0);
	 aluop(`RRC,16'h8001,16'h0000,0,16'h4000,0,0,1,1);
	 aluop(`RRC,16'h8001,16'h0000,1,16'hC000,0,1,1,0);

	 /* Byte reverse */
	 aluop(`BREV,16'h1234,16'h0000,0,16'h3412,0,0,0,0);
	 aluop(`BREV,16'h01FA,16'h0000,1,16'hFA01,0,1,0,0);
	 aluop(`BREV,16'h0000,16'h0000,0,16'h0000,1,0,0,0);

	 $display("There were ",Passes," passed test cases");
	 if(Failures) begin
	    $display("FAIL: There were ",Failures,
		     " failures during the run");
	 end else begin
	    $display("PASS: All tests PASS");
	 end
	 $finish;
      end
endmodule  // test_alu

