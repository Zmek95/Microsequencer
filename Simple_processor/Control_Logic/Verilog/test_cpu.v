/* test_cpu.v:
 *
 * CPU test bench
 *
 * Test vectors kind of working 
 */

module TEST_CPU();
   
  
   wire [15:0]   DATA_O;
   reg  [15:0]   DATA_I;
   wire [15:0] 	 ADDR;
   wire 	 RD,WR;

   reg 		 CLK,RST;
   
   integer    Failures = 0;
   integer    Passes   = 0;
   integer    Cycle    = 0;
 		  
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

   /*RAM RAM1 (
	     // Outputs
	     .Q(DATA_I),
	     // Inputs
	     .DATA(DATA_O), .ADDRESS(ADDR[7:0]), .WREN(WR), .CLK(CLK)
	     ) ;*/
   
   
   task cpuop;
   
	input [15:0] DATA_I_i; //Need a data in because ram has not been implemented!
	input [15:0] DATA_O_i;
   	integer SubFails;
   	
   	begin 
   		SubFails = 0;

		DATA_I = DATA_I_i;
   		
   		@(posedge CLK);//Wait for one instruction cycle
   		
   		if(DATA_O !== DATA_O_i) begin
   			SubFails = SubFails + 1;
   			$display($time,":FAIL: CPU Output Mismatch DATA_O:", DATA_O,
		     		" expected:",DATA_O_i);
     		end
     		
     		if(RST == 1'b0)
     			Cycle = 0;
		else
			Cycle = Cycle + 1;
		
		if(SubFails) begin
			Failures = Failures + 1;
			$display($time,":Failed test case was:");
			$display($time,":cpuop(", DATA_O_i, " at instruction cycle:", Cycle, ")\n");
     		end
     		else
     			Passes = Passes + 1;
     		
	end
   endtask
   		
   /* Test bench */
   initial begin
      
	$dumpfile("test_cpu.vcd");
      	$dumpvars();
	$monitor("DATA OUT:",CPU1.DATA_O);
      	@(posedge CLK);  // Wait for clock
      	@(posedge CLK);  // Wait for clock
      	//RESET
	cpuop(16'h0004,16'h0004);//R1
	cpuop(16'h0002,16'h0002);//R2
	cpuop(16'h0007,16'h0007);//R4
	cpuop(16'h0005,16'h0002);//R1 - R2
	cpuop(16'h0005,16'h0005);//Carry check
	cpuop(16'h0005,16'h000B);//R1 + R4
	cpuop(16'h0001,16'h0000);//MULTI

	//@(posedge CLK);  // Wait for clock
	//@(posedge CLK);  // Wait for clock
	//@(posedge CLK);  // Wait for clock
	//@(posedge CLK);  // Wait for clock

     	while (CPU1.CAR !== 0)
	begin
		@(posedge CLK);  // Wait for clock
	end

      	//@(posedge CLK);  // Wait for clock
	//@(posedge CLK);  // Wait for clock
      
      	$display("There were ",Passes," passed test cases");
	if(Failures) begin
	    $display("FAIL: There were ",Failures,
		     " failures during the run");
	 end else begin
	    $display("PASS: All tests PASS");
	 end
	 
      $finish();
   end
endmodule // TEST_CPU
