-- test_alu.vhd:
--
--  ALU test bench
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity TEST_ALU is
end TEST_ALU;

architecture RTL of TEST_ALU is

  signal ABUS, BBUS : unsigned(15 downto 0) := (others => '0');
  signal FSEL       : std_logic_vector(3 downto 0) := (others => '0');
  signal CIN        : std_logic;
  
  signal FOUT       : unsigned(15 downto 0);
  signal Z,S,C,V    : std_logic;

  signal Passes     : integer := 0;
  signal Failures   : integer := 0;
  
  component ALU is
    port(
      ABUS, BBUS :   in unsigned(15 downto 0);
      FSEL :         in std_logic_vector(3 downto 0);
      CIN :          in std_logic;
      FOUT :        out unsigned(15 downto 0);
      Z,S,C,V :     out std_logic
      );
  end component;

  constant delay_time : time := 1 ns;
  -- ALU Operations
  constant OP_TSA  : integer := 0;
  constant OP_INC  : integer := 1;
  constant OP_DEC  : integer := 2;
  constant OP_ADD  : integer := 3;
  constant OP_SUB  : integer := 4;
  constant OP_AND  : integer := 5;
  constant OP_OR   : integer := 6;
  constant OP_XOR  : integer := 7;
  constant OP_NOT  : integer := 8;
  constant OP_SHL  : integer := 9;
  constant OP_SHR  : integer := 10;
  constant OP_ASR  : integer := 11;
  constant OP_RLC  : integer := 12;
  constant OP_RRC  : integer := 13;
  constant OP_REVS : integer := 14;
  constant OP_RSV2 : integer := 15;

begin

  -- Instantiate ALU
  ALU1 : ALU port map (
    ABUS => ABUS,
    BBUS => BBUS,
    FSEL => FSEL,
    CIN  => CIN,
    FOUT => FOUT,
    Z => Z,
    S => S,
    C => C,
    V => V
    );


  testbench: process
    -- Procedure to update inputs
    procedure aluop(
      FSEL_i : in integer;
      ABUS_i    : in integer;
      BBUS_i    : in integer;
      CIN_i     : in integer;
      FOUT_i    : in integer;
      Z_i,S_i,C_i,V_i : in integer
      ) is
      variable SubFails : integer := 0;
    begin
      FSEL <= STD_LOGIC_VECTOR(TO_UNSIGNED(FSEL_i,4));
      ABUS <= TO_UNSIGNED(ABUS_I,16);
      BBUS <= TO_UNSIGNED(BBUS_I,16);
      CIN  <= TO_UNSIGNED(CIN_i,1)(0);
      wait for delay_time;

      if(FOUT /= TO_UNSIGNED(FOUT_i,16)) then
        report "Mismatch on FOUT expected " & integer'image(FOUT_i) &
          " got " & integer'image(to_integer(FOUT));
        SubFails := SubFails + 1;
      end if;

      if(Z /= TO_UNSIGNED(Z_i,1)(0)) then
        report "Mismatch on Z expected " & integer'image(Z_i)
          & " got " & std_logic'image(Z);
        SubFails := SubFails + 1;
      end if;

      if(S /= TO_UNSIGNED(S_i,1)(0)) then
        report "Mismatch on S expected " & integer'image(S_i)
          & " got " & std_logic'image(S);
        SubFails := SubFails + 1;
      end if;

      if(C /= TO_UNSIGNED(C_i,1)(0)) then
        report "Mismatch on C expected " & integer'image(C_i)
          & " got " & std_logic'image(C);
        SubFails := SubFails + 1;
      end if;

      if(V /= TO_UNSIGNED(V_i,1)(0)) then
        report "Mismatch on V expected " & integer'image(V_i)
          & " got " & std_logic'image(V);
        SubFails := SubFails + 1;
      end if;

      if(SubFails /= 0) then
        Failures <= Failures + 1;
        report "Failed test case was:";
        report "aluop(" & integer'image(FSEL_i)
          & "," & integer'image(ABUS_i)
          & "," & integer'image(BBUS_i)
          & "," & integer'image(CIN_i)
          & "," & integer'image(FOUT_i)
          & "," & integer'image(Z_i)
          & "," & integer'image(S_i)
          & "," & integer'image(C_i)
          & "," & integer'image(V_i)
          & ");";
        report "";
      else
        Passes <= Passes+1;
      end if;
      
    end aluop;
  begin

    -- Transfer test, B input should not affect F
    --                                  Z S C V
    aluop(OP_TSA,16#00#,16#00#,0,16#00#,1,0,0,0);
    aluop(OP_TSA,16#01#,16#00#,0,16#01#,0,0,0,0);
    aluop(OP_TSA,16#20#,16#42#,0,16#20#,0,0,0,0);
    aluop(OP_TSA,16#40#,16#24#,0,16#40#,0,0,0,0);
    aluop(OP_TSA,16#80#,16#00#,0,16#80#,0,0,0,0);
    
    -- Increment
    aluop(OP_INC,16#00#,16#00#,0,16#01#,0,0,0,0);
    aluop(OP_INC,16#01#,16#05#,0,16#02#,0,0,0,0);
    aluop(OP_INC,16#7F#,16#10#,0,16#80#,0,0,0,0);
    aluop(OP_INC,16#80#,16#00#,0,16#81#,0,0,0,0);

    -- Add
    aluop(OP_ADD,16#00#,16#00#,0,16#00#,1,0,0,0);
    aluop(OP_ADD,16#01#,16#01#,0,16#02#,0,0,0,0);
    aluop(OP_ADD,16#02#,16#03#,0,16#05#,0,0,0,0);
    aluop(OP_ADD,16#03#,16#02#,0,16#05#,0,0,0,0);
    aluop(OP_ADD,16#7e#,16#03#,0,129,0,0,0,0);
    aluop(OP_ADD,16#fe#,16#02#,0,256,0,0,0,0);
    aluop(OP_ADD,16#8000#,16#ffff#,0,32767,0,0,1,1); -- Overflow
    aluop(OP_ADD, 32767,  1,0,32768,0,1,0,1); -- Overflow
    aluop(OP_ADD,16#fffb#,6,0,1    ,0,0,1,0); -- No overflow
    
    -- Subtract
    aluop(OP_SUB,5,4,0,16#0001#,0,0,0,0);
    aluop(OP_SUB,16#fffc#,5,0,16#fff7#,0,1,0,0); -- -4,-9
    aluop(OP_SUB,16#8000#,1,0,16#7fff#,0,0,0,1); -- -32768 overflow
    aluop(OP_SUB, 32767,16#ffff#,0,16#8000#,0,1,1,1); -- overflow
    aluop(OP_SUB, 10,    5,0,16#05#,0,0,0,0);

    -- Decrement
    aluop(OP_DEC,1,0,0,16#00#,1,0,0,0);
    aluop(OP_DEC,65535,0,0,16#fffe#,0,1,0,0);        
    aluop(OP_DEC,1,43,0,16#00#,1,0,0,0);
    aluop(OP_DEC,255,0,0,254,0,0,0,0);

    -- Logical operations
    aluop(OP_AND,16#00#,16#00#,0,16#00#,1,0,0,0);
    aluop(OP_AND,16#aaaa#,16#5555#,0,16#0000#,1,0,0,0);
    aluop(OP_AND,16#5a5a#,16#a5a5#,0,16#0000#,1,0,0,0);
    aluop(OP_AND,16#ffff#,16#ffff#,0,16#ffff#,0,1,0,0);

    aluop(OP_OR ,16#00#,16#00#,0,16#00#,1,0,0,0);
    aluop(OP_OR ,16#aaaa#,16#5555#,0,16#ffff#,0,1,0,0);
    aluop(OP_OR ,16#5a5a#,16#a5a5#,0,16#ffff#,0,1,0,0);
    aluop(OP_OR ,16#ffff#,16#ffff#,0,16#ffff#,0,1,0,0);
    aluop(OP_OR ,16#0000#,16#ffff#,0,16#ffff#,0,1,0,0);
    aluop(OP_OR ,16#ffff#,16#0000#,0,16#ffff#,0,1,0,0);
    
    aluop(OP_XOR,16#0000#,16#0000#,0,16#0000#,1,0,0,0);
    aluop(OP_XOR,16#aaaa#,16#5555#,0,16#ffff#,0,1,0,0);
    aluop(OP_XOR,16#5a5a#,16#a5a5#,0,16#ffff#,0,1,0,0);
    aluop(OP_XOR,16#ffff#,16#ffff#,0,16#0000#,1,0,0,0);
    
    aluop(OP_NOT,16#0000#,16#0000#,0,16#ffff#,0,1,0,0);
    aluop(OP_NOT,16#aaaa#,16#5555#,0,16#5555#,0,0,0,0);
    aluop(OP_NOT,16#5a5a#,16#a5a5#,0,16#a5a5#,0,1,0,0);
    aluop(OP_NOT,16#ffff#,16#0000#,0,16#0000#,1,0,0,0);

    aluop(OP_SHL,16#0001#,16#0000#,0,16#0002#,0,0,0,0);
    aluop(OP_SHL,16#4000#,16#0000#,0,16#8000#,0,1,0,1);
    aluop(OP_SHL,16#8001#,16#0000#,0,16#0002#,0,0,1,1);

    aluop(OP_SHR,16#0001#,16#0000#,0,16#0000#,1,0,1,0);
    aluop(OP_SHR,16#4000#,16#0000#,0,16#2000#,0,0,0,0);
    aluop(OP_SHR,16#8001#,16#0000#,0,16#4000#,0,0,1,1);

    aluop(OP_ASR,16#0001#,16#0000#,0,16#0000#,1,0,1,0);
    aluop(OP_ASR,16#4000#,16#0000#,0,16#2000#,0,0,0,0);
    aluop(OP_ASR,16#8001#,16#0000#,0,16#C000#,0,1,1,0);
    aluop(OP_ASR,16#ffff#,16#0000#,0,       0,1,0,1,0);

    aluop(OP_RLC,16#0001#,16#0000#,0,16#0002#,0,0,0,0);
    aluop(OP_RLC,16#0001#,16#0000#,1,16#0003#,0,0,0,0);
    aluop(OP_RLC,16#4000#,16#0000#,0,16#8000#,0,1,0,1);
    aluop(OP_RLC,16#8001#,16#0000#,0,16#0002#,0,0,1,1);
    aluop(OP_RLC,16#8001#,16#0000#,1,16#0003#,0,0,1,1);

    aluop(OP_RRC,16#0001#,16#0000#,0,16#0000#,1,0,1,0);
    aluop(OP_RRC,16#0001#,16#0000#,1,16#8000#,0,1,1,1);
    aluop(OP_RRC,16#4000#,16#0000#,0,16#2000#,0,0,0,0);
    aluop(OP_RRC,16#8001#,16#0000#,0,16#4000#,0,0,1,1);
    aluop(OP_RRC,16#8001#,16#0000#,1,16#C000#,0,1,1,0);

    aluop(OP_REVS,16#1234#,16#0000#,0,16#3412#,0,0,0,0);
    aluop(OP_REVS,16#01FA#,16#0000#,1,16#FA01#,0,1,0,0);
    aluop(OP_REVS,16#0000#,16#0000#,0,16#0000#,1,0,0,0);
    
    report "Number of passed Test cases:" & integer'image(Passes);
    if (Failures /= 0) then
      report "FAIL: " & integer'image(Failures) & " Test cases failed";
    else
      report "PASS: all test cases passed";
    end if;
    
    assert false report "end of Simulation" severity failure;
  end process;
  
end RTL;
