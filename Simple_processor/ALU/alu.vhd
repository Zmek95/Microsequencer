-- alu.vhd:
-- 
-- Processor ALU block.  This block is purely
-- combinational.  It implements 16 ALU operations, controlled by the
-- FSEL input.
-- 

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity ALU is
  port(
    ABUS : in unsigned(15 downto 0);
    BBUS : in unsigned(15 downto 0);
    FSEL : in std_logic_vector(3 downto 0);
    CIN  : in std_logic;

    C,Z,S,V : out std_logic;
    FOUT : out unsigned(15 downto 0)
    );
end ALU;

architecture RTL of ALU is

begin
	
	process(ABUS, BBUS, FSEL, CIN)
		variable output : unsigned(16 downto 0);
	begin	
		case(FSEL) is
		
			when "0000" =>	-- Transfer ABUS
					output	:= '0' & ABUS;	
					V 	<= '0';

			when "0001" =>	-- Increment ABUS by one
					output	:= '0' & ABUS + 1;
					V	<= '0';

			when "0010" =>	-- Decrement ABUS by one
					output	:= '0' & ABUS - 1;
					V	<= '0';

			when "0011" =>	-- Add ABUS + BBUS + CIN
					output	:= ('0' & ABUS) + ('0' & BBUS) + (x"0000" & CIN);
					V <= (NOT(ABUS(15) XOR BBUS(15))) AND (ABUS(15) XOR output(15));
							
			when "0100" =>	-- Subtract ABUS - BBUS - CIN
					output	:= ('0' & ABUS) - ('0' & BBUS) - (x"0000" & CIN);
					V <= ((NOT(ABUS(15) XOR (NOT(BBUS(15)))))) AND ((NOT(BBUS(15))) XOR output(15));

			when "0101" =>	-- Bitwise ABUS AND BBUS
					output	:= '0' & (ABUS AND BBUS);
					V	<= '0';

			when "0110" =>	-- Bitwise ABUS OR BBUS
					output	:= '0' & (ABUS OR BBUS);
					V	<= '0';

			when "0111" =>	-- Bitwise ABUS XOR BBUS
					output	:= '0' & (ABUS XOR BBUS);
					V	<= '0';

			when "1000" =>	-- Bitwise NOT ABUS
					output	:= '0' & NOT ABUS;
					V	<= '0';

			when "1001" =>	-- Shift ABUS left, C contains ABUS[15], FOUT[0] contains 0
					output	:= ABUS(15) & shift_left(ABUS, 1);
					V	<= ABUS(15) XOR ABUS(14);

			when "1010" =>	-- Shift ABUS right, C contains ABUS[0], FOUT[15] contains 0
					output(16)	:= ABUS(0);
					output		:= output(16) & shift_right(ABUS, 1);
					V 		<= ABUS(15);

			when "1011" =>	-- Arithmetic shift A right, bit C contains ABUS[0]
					if(ABUS = x"FFFF") then
						output	:= "10000000000000000";
					else
						output	:= ABUS(0) & ABUS(15) & ABUS(15 downto 1);
					end if;
					V	<= '0';

			when "1100" =>	-- Rotate left through carry, FOUT[0] contains CIN, C contains ABUS[15]
					output	:= ABUS & CIN;
					V	<= ABUS(15) XOR ABUS(14);

			when "1101" =>	-- Rotate right through carry, FOUT[15] contains CIN, C conntains ABUS[0]
					output	:= rotate_right(CIN & ABUS, 1);
					V	<= ABUS(15) XOR CIN;	

			when "1110" => -- Reverse order of bytes
					output	:= '0' & ABUS(7 downto 0) & ABUS(15 downto 8);
					V	<= '0';
			when others =>
					output	:= (others => 'X');
					V	<= '0';
		end case;
		
		C <= output(16);
		S <= output(15);
		if(output(15 downto 0) = x"0000") then
			Z <= '1';
		else
			Z <= '0';
		end if;
		FOUT <= output(15 downto 0) ;
		
	end process;

end architecture;
