//Testbench

`include "timescale.v"

module i2c_master_single_byte_TB();

    parameter MAIN_CLK_DELAY    = 50;   // Number of ticks to delay each clock edge
    parameter I2C_CLK_RATIO     = 100;  // MAIN_CLK_DELAY / I2C_CLK_RATIO = I2C_CLOCK 
    parameter SLAVE_ADDR        = 7'h51;// Address of slave peripheral
    
    reg r_Clock = 1'b0;
    reg r_Reset = 1'b1;     // Start in reset
    reg r_Wr_Start = 1'b0;
    reg r_Rd_Start = 1'b0;
    reg [7:0] r_Wr_Byte = 8'h00;
    wire [7:0] w_Rd_Byte;
    wire w_Busy, w_Error, w_SCL, w_SDA;
    
    // Instantiate the unit under test conditions.
    i2c_master_single_byte #(I2C_CLK_RATIO) I2C_M_test
    (
    .i_Clk          (r_Clock),      // Main FPGA clock
    .i_Rst          (r_Reset),      // Active-high asyhcronous reset
    .i_Enable       (1'b1),         // Enable for I2C Master
    
    .i_Slave_Addr   (SLAVE_ADDR),   // I2C Address of slave device
    .i_Wr_Start     (r_Wr_Start),   // Kicks off a write when pulsed
    .i_Rd_Start     (r_Rd_Start),   // Kicks off a read when pulsed
    .i_Wr_Byte      (r_Wr_Byte),    // Data to write (if write cmd)
    .o_Busy         (w_Busy),       // Falling edge = done
    .o_Rd_Byte      (w_Rd_Byte),    // Result of a read
    .o_Error        (w_Error),      // High if there is an error in the last transaction
    
    .io_scl         (w_SCL),        // Actual I2C clock
    .io_sda         (w_SDA)         // Actual I2C Data
    );
    
    // Instantiate I2C slave model and hookup to I2C master
    i2c_slave_model #(SLAVE_ADDR) I2C_slave
    (
    .scl(w_SCL),
    .sda(w_SDA)
    );
    
    // Clock generators:
    always #(MAIN_CLK_DELAY) r_Clock = ~r_Clock;
    
    pullup p1(w_SCL);   // pullup scl line
    pullup p2(w_SDA);   // pullup sda line
    
    initial 
    begin
        force I2C_slave.debug = 1'b0; // disable I2C_slave debug
        
        $display("\nstatus: %t Testbench started\n\n", $time);
        
        #10;
        @(posedge r_Clock);
        r_Reset <= 1'b0;
        repeat(10) @(posedge r_Clock);
        
        /* Testing out the core without the state machine implemented
        // Write 1 byte of data to the slave. Sets the slave address.
        r_Wr_Start  <= 1'b1;
        r_Wr_Byte   <= 8'hA2;   // 0x51 slave Addr + Write bit
        @(posedge r_Clock);
        r_Wr_Start  <= 1'b0;
        
        @(posedge r_Clock);
        while (w_Busy) @(posedge r_Clock);
        
        // Now write data
        r_Wr_Byte   <= 8'hAC;
        r_Wr_Start  <= 1'b1;
        @(posedge r_Clock);
        r_Wr_Start  <= 1'b0;
        @(posedge r_Clock);
        */
        
        r_Wr_Start <= 1'b1;
        r_Wr_Byte   <= 8'hAC;
        @(posedge r_Clock);
        r_Wr_Start <= 1'b0;
        @(posedge r_Clock);
        
        #400000; // wait 4us
        $display("\n\nstatus: %t Testbench done", $time);
        $finish;
    end
    
endmodule

