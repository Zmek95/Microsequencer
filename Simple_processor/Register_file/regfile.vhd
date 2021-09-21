-- regfile.vhd
--
--   Implementation of a register file.
--
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity REGFILE is
  port(
    ASEL, BSEL, DSEL : in unsigned(2 downto 0);
    RIN, DIN :         in unsigned(15 downto 0);
    ABUS, BBUS :       out unsigned(15 downto 0);
    CLK :              in std_logic;
    RST :              in std_logic
    );
end REGFILE;

architecture RTL of REGFILE is
type Register_Array is array (1 to 7) of unsigned(15 downto 0);
signal R_array : Register_Array := (others => (others => '0'));

begin

	process (CLK, RST) is

	variable Index : integer;
	begin
		if falling_edge(RST) then
			--RESET all registers in array to 0
			R_array <= (others => (others => '0'));
			
		elsif rising_edge(CLK) then
			--Store RIN into the register array R_array[x] where x depends on DSEL
			-- if DSEL == 0 nothing is done
			if DSEL /= "000" then
				Index := to_integer(DSEL);
				R_array(Index) <= RIN;
			end if;		
		end if;
	end process;

	process (ASEL, BSEL, DIN, R_array) is
	
	variable Index : integer;
	begin
		--Async logic	
		if (ASEL = "000") and (BSEL = "000") then
			ABUS <= DIN;
			BBUS <= DIN;
			
		elsif ASEL = "000" then
			ABUS <= DIN;
			
			Index := to_integer(BSEL);
			BBUS <= R_array(Index);
			
		elsif BSEL = "000" then
			BBUS <= DIN;
			
			Index := to_integer(ASEL);
			ABUS <= R_array(Index);
		
		else
			Index := to_integer(ASEL);
			ABUS <= R_array(Index);
			
			Index := to_integer(BSEL);
			BBUS <= R_array(Index);
		end if;
	end process;
end architecture;

