/* RAM memory simulation */
module RAM (/*AUTOARG*/
   // Outputs
   Q,
   // Inputs
   DATA, ADDRESS, WREN, CLK
   ) ;
`define MEMFILE "ram.dat"
`define WIDTH 16
`define DEPTH 256
`define ADDR  8
   input [`WIDTH-1:0] DATA;
   input [`ADDR-1:0] ADDRESS;
   input       WREN;
   input       CLK;
   output reg [`WIDTH-1:0] Q;
   

   /* The memory array */
   reg [`WIDTH-1:0]   memory[`DEPTH-1:0];
   reg [`WIDTH-1:0]   data_r;
   reg [`ADDR-1:0]    address_r;
   reg 		      wren_r;

   integer 	      i;
   
   initial begin
      data_r    <= 0;
      address_r <= 0;
      wren_r    <= 0;
      Q         = 0;
      for(i=0; i<`DEPTH-1; i=i+1)
	memory[i] = 0;
      $readmemh(`MEMFILE,memory,0,`DEPTH-1);
   end
   
   /* Implement clocked registers */
   always @(posedge CLK) begin
      data_r    <= DATA;
      address_r <= ADDRESS;
      wren_r    <= WREN;
   end

   /* Implement RAM array */
   always @(data_r or address_r or wren_r) begin
      if(wren_r) begin
	 memory[address_r] = data_r;
      end
      Q = memory[address_r];
   end
   
endmodule // RAM
