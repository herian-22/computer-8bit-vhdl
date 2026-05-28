library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_path is
  port (
    clock      : in  std_logic;
    reset      : in  std_logic;
    -- Control signals
    IR_Load    : in  std_logic;
    MAR_Load   : in  std_logic;
    PC_Load    : in  std_logic;
    PC_Inc     : in  std_logic;
    A_Load     : in  std_logic;
    B_Load     : in  std_logic;
    CCR_Load   : in  std_logic;
    ALU_Sel    : in  std_logic_vector(3 downto 0);
    Bus1_Sel   : in  std_logic_vector(1 downto 0);
    Bus2_Sel   : in  std_logic_vector(1 downto 0);
    -- Memory interface
    address    : out std_logic_vector(7 downto 0);
    to_memory  : out std_logic_vector(7 downto 0);
    from_memory : in std_logic_vector(7 downto 0);
    -- Status outputs
    IR         : out std_logic_vector(7 downto 0);
    CCR_Result : out std_logic_vector(3 downto 0)
  );
end entity data_path;

architecture rtl of data_path is

  signal PC       : std_logic_vector(7 downto 0);
  signal A        : std_logic_vector(7 downto 0);
  signal B        : std_logic_vector(7 downto 0);
  signal MAR      : std_logic_vector(7 downto 0);
  signal IR_reg   : std_logic_vector(7 downto 0);
  signal CCR      : std_logic_vector(3 downto 0);
  
  signal Bus1     : std_logic_vector(7 downto 0);
  signal Bus2     : std_logic_vector(7 downto 0);
  signal ALU_Result : std_logic_vector(7 downto 0);
  signal NZVC     : std_logic_vector(3 downto 0);
  
  signal PC_uns   : unsigned(7 downto 0);

begin

  -- ALU instantiation
  ALU_INST : entity work.alu
    port map (
      A       => A,
      B       => B,
      ALU_Sel => ALU_Sel,
      Result  => ALU_Result,
      NZVC    => NZVC
    );

  -- Bus1 Multiplexer (outputs from registers)
  MUX_BUS1 : process (Bus1_Sel, PC, A, B)
  begin
    case Bus1_Sel is
      when "00" => Bus1 <= PC;
      when "01" => Bus1 <= A;
      when "10" => Bus1 <= B;
      when others => Bus1 <= x"00";
    end case;
  end process;

  -- Bus2 Multiplexer (inputs to registers)
  MUX_BUS2 : process (Bus2_Sel, ALU_Result, Bus1, from_memory)
  begin
    case Bus2_Sel is
      when "00" => Bus2 <= ALU_Result;
      when "01" => Bus2 <= Bus1;
      when "10" => Bus2 <= from_memory;
      when others => Bus2 <= x"00";
    end case;
  end process;

  -- Connect MAR to address bus
  address <= MAR;
  to_memory <= Bus1;

  -- Instruction Register
  INSTRUCTION_REGISTER : process (clock, reset)
  begin
    if (reset = '0') then
      IR_reg <= x"00";
    elsif (clock'event and clock = '1') then
      if (IR_Load = '1') then
        IR_reg <= Bus2;
      end if;
    end if;
  end process;
  IR <= IR_reg;

  -- Memory Address Register
  MEMORY_ADDRESS_REGISTER : process (clock, reset)
  begin
    if (reset = '0') then
      MAR <= x"00";
    elsif (clock'event and clock = '1') then
      if (MAR_Load = '1') then
        MAR <= Bus2;
      end if;
    end if;
  end process;

  -- Program Counter
  PROGRAM_COUNTER : process (clock, reset)
  begin
    if (reset = '0') then
      PC_uns <= (others => '0');
    elsif (clock'event and clock = '1') then
      if (PC_Load = '1') then
        PC_uns <= unsigned(Bus2);
      elsif (PC_Inc = '1') then
        PC_uns <= PC_uns + 1;
      end if;
    end if;
  end process;
  PC <= std_logic_vector(PC_uns);

  -- Register A
  A_REGISTER : process (clock, reset)
  begin
    if (reset = '0') then
      A <= x"00";
    elsif (clock'event and clock = '1') then
      if (A_Load = '1') then
        A <= Bus2;
      end if;
    end if;
  end process;

  -- Register B
  B_REGISTER : process (clock, reset)
  begin
    if (reset = '0') then
      B <= x"00";
    elsif (clock'event and clock = '1') then
      if (B_Load = '1') then
        B <= Bus2;
      end if;
    end if;
  end process;

  -- Condition Code Register
  CONDITION_CODE_REGISTER : process (clock, reset)
  begin
    if (reset = '0') then
      CCR <= x"0";
    elsif (clock'event and clock = '1') then
      if (CCR_Load = '1') then
        CCR <= NZVC;
      end if;
    end if;
  end process;
  CCR_Result <= CCR;

end architecture rtl;
