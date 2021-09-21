/* test_cpu.v:
 *
 * CPU test bench
 * 
 */

module TEST_CPU();
   
  
   wire [15:0]   DATA_O, DATA_I;
   wire [15:0] 	 ADDR;
   wire 	 RD,WR;

   reg 		 CLK,RST;
 		  
   initial CLK = 1'b0;
   
   
   /* Generate clock */
   always begin
      #1 CLK <= ~CLK;
   end

   /* Generate reset pulse */
   initial begin
      RST = 1'b1;
      #3 RST = 1'b0;
      #1 RST = 1'b1;
   end
  
   CPU CPU1 (
	     // Outputs
	     .DATA_O(DATA_O), .ADDR(ADDR), .RD(RD), .WR(WR),
	     // Inputs
	     .DATA_I(DATA_I), .CLK(CLK), .RST(RST)
	     );

   RAM RAM1 (
	     // Outputs
	     .Q(DATA_I),
	     // Inputs
	     .DATA(DATA_O), .ADDRESS(ADDR[7:0]), .WREN(WR), .CLK(CLK)
	     ) ;
   

   /* Test bench */
   initial begin
      
      $dumpfile("test_cpu.vcd");
      $dumpvars();

      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      @(posedge CLK);  // Wait for clock
      
      
      $finish();
   end
endmodule // TEST_CPU
