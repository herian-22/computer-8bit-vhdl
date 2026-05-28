library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_128x8_sync is
  port (
    clock    : in  std_logic;
    address  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0)
  );
end entity rom_128x8_sync;

architecture rtl of rom_128x8_sync is

  constant LDA_IMM : std_logic_vector(7 downto 0) := x"86";
  constant LDA_DIR : std_logic_vector(7 downto 0) := x"87";
  constant LDB_IMM : std_logic_vector(7 downto 0) := x"88";
  constant LDB_DIR : std_logic_vector(7 downto 0) := x"89";
  constant STA_DIR : std_logic_vector(7 downto 0) := x"96";
  constant STB_DIR : std_logic_vector(7 downto 0) := x"97";
  constant ADD_AB  : std_logic_vector(7 downto 0) := x"42";
  constant SUB_AB  : std_logic_vector(7 downto 0) := x"43";
  constant AND_AB  : std_logic_vector(7 downto 0) := x"44";
  constant OR_AB   : std_logic_vector(7 downto 0) := x"45";
  constant INCA    : std_logic_vector(7 downto 0) := x"46";
  constant INCB    : std_logic_vector(7 downto 0) := x"47";
  constant DECA    : std_logic_vector(7 downto 0) := x"48";
  constant DECB    : std_logic_vector(7 downto 0) := x"49";
  constant BRA     : std_logic_vector(7 downto 0) := x"20";
  constant BMI     : std_logic_vector(7 downto 0) := x"21";
  constant BPL     : std_logic_vector(7 downto 0) := x"22";
  constant BEQ     : std_logic_vector(7 downto 0) := x"23";
  constant BNE     : std_logic_vector(7 downto 0) := x"24";
  constant BVS     : std_logic_vector(7 downto 0) := x"25";
  constant BVC     : std_logic_vector(7 downto 0) := x"26";
  constant BCS     : std_logic_vector(7 downto 0) := x"27";
  constant BCC     : std_logic_vector(7 downto 0) := x"28";

  type rom_type is array (0 to 127) of std_logic_vector(7 downto 0);

  -- Test program: comprehensive instruction test
  -- Addr  Instr   Operand  Description
  -- 0x00  LDA_IMM 0x05     Load A = 0x05
  -- 0x02  LDB_IMM 0x03     Load B = 0x03
  -- 0x04  ADD_AB          A = A + B = 0x08, store to port_out_00
  -- 0x05  STA_DIR 0xE0     Store A to port_out_00 (0xE0)
  -- 0x07  LDA_IMM 0xFF     Load A = 0xFF
  -- 0x09  LDB_IMM 0x01     Load B = 0x01
  -- 0x0B  ADD_AB          A = 0xFF + 0x01 = 0x00 (Z=1, C=1), store to port_out_01
  -- 0x0C  STA_DIR 0xE1     Store A to port_out_01
  -- 0x0E  BEQ     0x18     Branch if Z=1 (should branch to 0x18)
  -- 0x10  LDA_IMM 0xAA     (skipped by branch)
  -- 0x12  STA_DIR 0xE2     (skipped by branch)
  -- 0x14  BRA     0x1E     (skipped by branch)
  -- 0x16  (padding)
  -- 0x18  LDA_IMM 0x55     Load A = 0x55 (branch target)
  -- 0x1A  STA_DIR 0xE3     Store A to port_out_03
  -- 0x1C  BRA     0x00     Loop back to start

  constant ROM : rom_type := (
    -- Test 1: LDA_IMM + LDB_IMM + ADD_AB + STA_DIR
    0  => LDA_IMM,
    1  => x"05",
    2  => LDB_IMM,
    3  => x"03",
    4  => ADD_AB,
    5  => STA_DIR,
    6  => x"E0",
    
    -- Test 2: ADD with overflow (0xFF + 0x01 = 0x00, Z=1, C=1)
    7  => LDA_IMM,
    8  => x"FF",
    9  => LDB_IMM,
    10 => x"01",
    11 => ADD_AB,
    12 => STA_DIR,
    13 => x"E1",
    
    -- Test 3: BEQ (branch if Z=1, should take branch)
    14 => BEQ,
    15 => x"16",
    
    -- Skipped section (should not execute)
    16 => LDA_IMM,
    17 => x"AA",
    18 => STA_DIR,
    19 => x"E2",
    20 => BRA,
    21 => x"1E",
    
    -- Branch target: store 0x55 to port_out_03
    22 => LDA_IMM,
    23 => x"55",
    24 => STA_DIR,
    25 => x"E3",
    
    -- Test 4: SUB_AB
    26 => LDA_IMM,
    27 => x"0A",
    28 => LDB_IMM,
    29 => x"03",
    30 => SUB_AB,
    31 => STA_DIR,
    32 => x"E4",
    
    -- Test 5: AND_AB
    33 => LDA_IMM,
    34 => x"0F",
    35 => LDB_IMM,
    36 => x"F0",
    37 => AND_AB,
    38 => STA_DIR,
    39 => x"E5",
    
    -- Test 6: OR_AB
    40 => LDA_IMM,
    41 => x"0F",
    42 => LDB_IMM,
    43 => x"F0",
    44 => OR_AB,
    45 => STA_DIR,
    46 => x"E6",
    
    -- Test 7: INCA
    47 => LDA_IMM,
    48 => x"7F",
    49 => INCA,
    50 => STA_DIR,
    51 => x"E7",
    
    -- Test 8: DECA
    52 => LDA_IMM,
    53 => x"01",
    54 => DECA,
    55 => STA_DIR,
    56 => x"E8",
    
    -- Loop back
    57 => BRA,
    58 => x"00",
    
    others => x"00"
  );

  signal EN : std_logic;

begin

  enable : process (address)
  begin
    if ((to_integer(unsigned(address)) >= 0) and
        (to_integer(unsigned(address)) <= 127)) then
      EN <= '1';
    else
      EN <= '0';
    end if;
  end process;

  memory : process (clock)
  begin
    if (clock'event and clock = '1') then
      if (EN = '1') then
        data_out <= ROM(to_integer(unsigned(address)));
      end if;
    end if;
  end process;

end architecture rtl;
