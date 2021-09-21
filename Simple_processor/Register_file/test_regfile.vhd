-- test_regfile.vhd
--
--   Register file test bench.
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

entity TEST_REGFILE is
end TEST_REGFILE;

architecture RTL of TEST_REGFILE is

    signal ASEL, BSEL, DSEL : unsigned(2 downto 0) := (others => '0');
    signal RIN, DIN         : unsigned(15 downto 0) := (others => '0');
    signal A, B             : unsigned(15 downto 0);
    signal CLK, RST         : std_logic;

    signal Failures         : integer := 0;
    signal Passes           : integer := 0;
    
    component REGFILE is
      port(
        ASEL, BSEL, DSEL : in unsigned(2 downto 0);
        RIN, DIN :         in unsigned(15 downto 0);
        ABUS, BBUS :       out unsigned(15 downto 0);
        CLK,RST :          in std_logic
        );
    end component;
    
    --random value generator function referenced from: https://vhdlwhiz.com/random-numbers/
	impure function rand_int(min_val, max_val : integer) return integer is
	  variable r : real;
	variable seed1, seed2 : integer := 999;
	begin
	  uniform(seed1, seed2, r);
	  return integer(
	    round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
	end function;

-- Modelsim student edition seems to have a default resolution of
-- 1ns. If we use a time delay less than that, it rounds it to 0, and the
-- time does not advance in the simulation.  Since the time does not advance,
-- all test cases fail.
constant clk_period : time := 2 ns;
begin
  REGFILE1 : REGFILE port map (
    ASEL => ASEL,
    BSEL => BSEL,
    DSEL => DSEL,
    RIN  => RIN,
    DIN  => DIN,
    ABUS => A,
    BBUS => B,
    RST  => RST,
    CLK  => CLK);
  
   -- Clock process definition
  clk_process: process
  begin
    CLK <= '0';
    wait for clk_period/2;
    CLK <= '1';
    wait for clk_period/2;
  end process;

  testbench: process
  -- Procedure to update inputs
	variable random_ASEL : integer := 0;
	variable random_DSEL : integer := 0;
	variable random_BSEL : integer;
	variable random_DIN : integer;
	variable random_RIN : integer;
	variable expected_ABUS : integer;
	variable expected_BBUS : integer;
	

  procedure microop(
    ASEL_i, BSEL_i, DSEL_i : in integer;
    DIN_i, RIN_i :           in integer;
    A_i, B_i :               in integer
    ) is
    
    variable SubFails : integer := 0;

  begin
    ASEL <= TO_UNSIGNED(ASEL_i,3);
    BSEL <= TO_UNSIGNED(BSEL_i,3);
    DSEL <= TO_UNSIGNED(DSEL_i,3);
    DIN  <= TO_UNSIGNED(DIN_i,16);
    RIN  <= TO_UNSIGNED(RIN_i,16);
    wait until rising_edge(CLK);
    
    if( TO_UNSIGNED(A_i,16) /= A) then
      report "Mismatch on A bus, expected " & integer'image(A_i) &
          " got " & integer'image(to_integer(A));
      SubFails := SubFails + 1;
    end if;
    if( TO_UNSIGNED(B_i,16) /= B) then
      report "Mismatch on B bus, expected " & integer'image(B_i) &
          " got " & integer'image(to_integer(B));
      SubFails := SubFails + 1;
    end if;

    if(SubFails /= 0) then
      Failures <= Failures + 1;
      report "Failed test case was:";
      report "microop(" &
        integer'image(ASEL_i) & "," &
        integer'image(BSEL_i) & "," &
        integer'image(DSEL_i) & "," &
        integer'image(DIN_i) & "," &
        integer'image(RIN_i) & "," &
        integer'image(A_i) & "," &
        integer'image(B_i) & ");";
      report "";
    else
      Passes <= Passes+1;
    end if;
  end microop;

  begin
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '0';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '1';
    wait until rising_edge(CLK);
    -- Check that reset worked... all registers should be '0'
    microop(1,0,0,0,0,0,0);
    microop(2,0,0,0,0,0,0);
    microop(3,0,0,0,0,0,0);
    microop(4,0,0,0,0,0,0);
    microop(5,0,0,0,0,0,0);
    microop(6,0,0,0,0,0,0);
    microop(7,0,0,0,0,0,0);
    microop(0,1,0,0,0,0,0);
    microop(0,2,0,0,0,0,0);
    microop(0,3,0,0,0,0,0);
    microop(0,4,0,0,0,0,0);
    microop(0,5,0,0,0,0,0);
    microop(0,6,0,0,0,0,0);
    microop(0,7,0,0,0,0,0);

    -- Write some values into the registers
    microop(0,0,1,0,1,0,0);
    microop(0,0,2,0,2,0,0);
    microop(0,0,3,0,3,0,0);
    microop(0,0,4,0,4,0,0);
    microop(0,0,5,0,5,0,0);
    microop(0,0,6,0,6,0,0);
    microop(0,0,7,0,7,0,0);

    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    
    --  Read back on A bus 
    microop(0,0,0,15,10,15,15);
    microop(1,0,0,0,10,1,0);
    microop(2,0,0,0,10,2,0);
    microop(3,0,0,0,10,3,0);
    microop(4,0,0,0,10,4,0);
    microop(5,0,0,0,10,5,0);
    microop(6,0,0,0,10,6,0);
    microop(7,0,0,0,10,7,0);

    wait until rising_edge(CLK);
    wait until rising_edge(CLK);

    -- Read back on B bus
    microop(0,0,0,16,12,16,16);
    microop(0,1,0,0,10,0,1);
    microop(0,2,0,0,10,0,2);
    microop(0,3,0,0,10,0,3);
    microop(0,4,0,0,10,0,4);
    microop(0,5,0,0,10,0,5);
    microop(0,6,0,0,10,0,6);
    microop(0,7,0,0,10,0,7);
    
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    
    --random value testing
	for i in 0 to 10 loop
	
		random_BSEL := rand_int(0,7);
		random_DIN := rand_int(0,65535);
		random_RIN := rand_int(0,65535);
		expected_ABUS := random_DIN;
		
		if random_BSEL = 0 then
			expected_BBUS := random_DIN;
		else
			expected_BBUS := random_BSEL;
		end if;
			
		microop(random_ASEL, random_BSEL, random_DSEL, random_DIN, random_RIN, expected_ABUS, expected_BBUS);
	end loop;

    report "Number of passed Test cases:" & integer'image(Passes);
    if (Failures /= 0) then
      report "FAIL: " & integer'image(Failures) & " Test cases failed";
    else
      report "PASS: all test cases passed";
    end if;

    assert false report "end of Simulation" severity failure;
  end process;
end architecture;
  
