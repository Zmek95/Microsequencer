-- test_regfile.vhd
--
--   CPU test bench.
--
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity TEST_CPU is
end TEST_CPU;

architecture RTL of TEST_CPU is

  signal DATA_O   : unsigned(15 downto 0);
  signal DATA_I   : unsigned(15 downto 0);
  signal MADDR    : unsigned(15 downto 0);
  signal RD, WR   : std_logic;
  signal CLK, RST : std_logic := '1';
  
  signal Failures         : integer := 0;
  signal Passes           : integer := 0;

  component CPU is
    port(
      DATA_I : in unsigned(15 downto 0);
      DATA_O : out unsigned(15 downto 0);
      MADDR  : out unsigned(15 downto 0);
      RD     : out std_logic;
      WR     : out std_logic;
      CLK    : in std_logic;
      RST    : in std_logic
      );
  end component;

  component RAM is
    port (
      Q         : out unsigned(15 downto 0);
      DATA      : in  unsigned(15 downto 0);
      ADDRESS   : in  unsigned(7 downto 0);
      WREN, CLK : in  std_logic
      );
  end component;

constant clk_period : time := 1 ns;  
begin
  CPU1 : CPU port map(
    DATA_I => DATA_I,
    DATA_O => DATA_O,
    MADDR  => MADDR,
    RD     => RD,
    WR     => WR,
    RST    => RST,
    CLK    => CLK
    );

--  RAM1 : RAM port map(
--    Q       => DATA_I,
--    DATA    => DATA_O,
--    ADDRESS => MADDR(7 downto 0),
--    WREN    => WR,
--    CLK     => CLK
--    );
  
  
  -- Clock process definition
  clk_process: process
  begin
    CLK <= '0';
    wait for clk_period/2;
    CLK <= '1';
    wait for clk_period/2;
  end process;

  testbench: process

	procedure cpuop(
    DATA_I_i : in integer;
    DATA_O_i : in integer
    ) is
    
    variable SubFails : integer := 0;

  begin
  
    DATA_I <= TO_UNSIGNED(DATA_I_i,16);
    --DATA_O <= TO_UNSIGNED(DATA_O_i,16);
	
    wait until rising_edge(CLK);
    
    if( TO_UNSIGNED(DATA_O_i,16) /= DATA_O) then
      report "Mismatch on DATA_O, expected " & integer'image(DATA_O_i) &
          " got " & integer'image(to_integer(DATA_O));
      SubFails := SubFails + 1;
    end if;
    
    if(SubFails /= 0) then
      Failures <= Failures + 1;
      report "Failed test case was:";
      report "cpuop(" &
        integer'image(DATA_I_i) & "," &
        integer'image(DATA_O_i) & ",";
      report "";
    else
      Passes <= Passes+1;
    end if;
  end cpuop;




  begin
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '0';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
	-- Check that reset worked... all registers should be '0'
	--cpuop(0,0);
	cpuop(8,8);	-- Loading R1
    wait until rising_edge(CLK);
	cpuop(2,2);	-- Loading R2
    wait until rising_edge(CLK);
	cpuop(11,11);	-- Loading R4
    wait until rising_edge(CLK);
	cpuop(0,6);	-- R3 = R1 - R2
    wait until rising_edge(CLK);
	cpuop(0,0); 	-- Jump to label L1 if carry flag is set (in our case, no jump)
    wait until rising_edge(CLK);
	cpuop(0,19);	-- R4 = R1 + R4, then go to start
    wait until rising_edge(CLK);
	--cpuop(0,0);
    wait until rising_edge(CLK);
	--cpuop(0,20);
    wait until rising_edge(CLK);
	--cpuop(0,22);
    wait until rising_edge(CLK);
	--cpuop(0,22);
    wait until rising_edge(CLK);
   
  
    assert false report "end of Simulation" severity failure;
  end process;


end architecture;
  
