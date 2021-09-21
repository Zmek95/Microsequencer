/*******************************************************************************
  * File Name          : i2c_master_single_byte
  * Description        : Wrapper for I2C master that writes a byte of data to a
  *                      slave peripheral.
  *
  * Author: Ziyad Mekhemer and Shamseddin Elmasri
  * Credits: Orginal code was modified from Russel Merrick I2C core wrapper implementation
  * 	     https://www.youtube.com/watch?v=ZJpKK4dIH1k
  * Date: 16/12/20                
  ******************************************************************************
  */

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "i2c_master_defines.v"

module i2c_master_single_byte #(parameter CLK_RATIO = 25)
    (input i_Clk,                   // Main FPGA Clock
     input i_Rst,                   // Active-high asyhcronous reset
     input i_Enable,                // Enable for I2C master
     //
     input [6:0]    i_Slave_Addr,   // I2C Address of Slave device
     input          i_Wr_Start,     // Kicks off a write when pulled
     input          i_Rd_Start,     // Kicks off a read when pulled
     input [7:0]    i_Wr_Byte,      // Data to write (if write cmd)
     output reg     o_Busy,         // Falling edge = done
     output [7:0]   o_Rd_Byte,      // Result of a read
     output         o_Error,        // High if error in last transaction
     //
     inout io_scl,                  // Actual I2C clock
     inout io_sda                   // Actual I2C data
     );
     
     // Defines the upper limit of an internal counter, This sets the frequency of the I2C
     // clock, which depends on the input clock frequency. For details check section 3.2.1
     // in the user guide
     localparam [15:0] CLK_COUNT = CLK_RATIO / 5 - 1;
     
     localparam [2:0] IDLE              = 2'b00;
     localparam [2:0] WAIT_SLAVE_ADDR   = 2'b01;
     localparam [2:0] WAIT_WR_DATA      = 2'b10;
     
     
     wire w_sck_en, w_sda_en;
     wire w_Arb_Lost, w_Cmd_Ack, w_Slave_Ack;
     reg r_Cmd_Start;
     reg r_Cmd_Stop;
     reg r_Wr_Cmd, r_Rd_Cmd;
     reg [7:0] r_Cmd_Byte, r_Wr_Byte;
     reg r_Cmd_Ack;
     
     reg [2:0] r_SM_Main;
     
     
     assign o_Done = w_Arb_Lost | w_Cmd_Ack;
     
     // hookup byte controller block
     i2c_master_byte_ctrl byte_controller (
        .clk        (i_Clk),        
        .rst        (1'b0),         // Use async reset below only 
        .nReset     (~i_Rst),       // Active low, invert required
        .ena        (i_Enable),
        .clk_cnt    (CLK_COUNT),
        .start      (r_Cmd_Start),  // Single clock cycle pulse to start command
        .stop       (r_Cmd_Stop),   // Used to set end of command
        .read       (r_Rd_Cmd),   // Read command
        .write      (r_Wr_Cmd),   // Write command
        .ack_in     (1'b0),         // When Master is receiving. 0=ACK, 1=NACK, NACK can indicate end
        .din        (r_Cmd_Byte),    
        .cmd_ack    (w_Cmd_Ack),    // From Slave, when command is done this is set.
        .ack_out    (w_Slave_Ack),  // When Slave is receiving, 0=ACK, 1=NACK.
        .dout       (o_Rd_Byte),
        .i2c_busy   (),              //This module generates its own busy signal
        .i2c_al     (w_Arb_Lost),    
        .scl_i      (io_scl),
        .scl_o      (),             // Tied to ground inside bit_ctrl, don't need
        .scl_oen    (w_sck_en),
        .sda_i      (io_sda),
        .sda_o      (),             // Tied to ground inside but_ctrl, don't need
        .sda_oen    (w_sda_en)
    );
    
    // Creates tri-state buffer,
    // When enable is high, go high impedance (1), when low, pull low to zero.
    assign io_scl = w_sck_en ? 1'bZ : 1'b0;
    assign io_sda = w_sda_en ? 1'bZ : 1'b0;
    
    // Purpose: Create one clock cycle delay to detect
    // Falling edge of Cmd_Ack from core. Assume this is when command is done.
    always @(posedge i_Clk)
    begin
        r_Cmd_Ack <= w_Cmd_Ack;
    end
    
    // create a state machine here to drive a write transmission correctly.
    
    // Purpose: Main State Machine for control
    always @(posedge i_Rst or posedge i_Clk)
    begin
        if (i_Rst)
        begin
            r_SM_Main   <= IDLE;
            r_Cmd_Start <= 1'b0;
            o_Busy      <= 1'b0;
        end
        else
        begin
        
            //Default assignments
            r_Cmd_Start <= 1'b0;
            r_Cmd_Stop  <= 1'b0;
            
            case (r_SM_Main)
            IDLE:
            begin
                if (i_Wr_Start)
                begin
                    r_Cmd_Start <= 1'b1;
                    r_Wr_Cmd    <= 1'b1;
                    o_Busy      <= 1'b1;
                    r_Wr_Byte   <= i_Wr_Byte;
                    r_Cmd_Byte  <= {i_Slave_Addr, 1'b0}; // 1'b0 = Write command
                    r_SM_Main   <= WAIT_SLAVE_ADDR;
                end
                else
                begin
                    r_Rd_Cmd <= 1'b0;
                    r_Wr_Cmd <= 1'b0;
                    o_Busy   <= 1'b0;
                end
            end
            
            // Wait for Cmd Ack from Core to know slave addr is written.
            WAIT_SLAVE_ADDR:
            begin
                // Done when Cmd Ack has falling edge
                if (r_Cmd_Ack & ~w_Cmd_Ack)
                begin
			r_Cmd_Stop  <= 1'b1;
			o_Busy      <= 1'b0;
			r_Wr_Cmd    <= 1'b0;
                	r_Cmd_Byte  <= r_Wr_Byte; //Write data to slave
                	r_SM_Main   <= WAIT_WR_DATA;
                end
            end
            
            // Wait for the slave to acknowledge the write.
            WAIT_WR_DATA:
            begin
                // Done when Cmd Ack has falling edge
                if (r_Cmd_Ack & ~w_Cmd_Ack)
                begin
                    r_SM_Main <= IDLE;
                end
            end
            endcase
            
        end
    end
    
endmodule
