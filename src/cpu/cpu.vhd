library ieee;
use ieee.std_logic_1164.all;

entity cpu is
  port (
    clock      : in  std_logic;
    reset      : in  std_logic;
    from_memory : in  std_logic_vector(7 downto 0);
    IR         : out std_logic_vector(7 downto 0);
    CCR_Result : out std_logic_vector(3 downto 0);
    address    : out std_logic_vector(7 downto 0);
    to_memory  : out std_logic_vector(7 downto 0);
    write      : out std_logic
  );
end entity cpu;

architecture structural of cpu is
  signal IR_sig        : std_logic_vector(7 downto 0);
  signal CCR_sig       : std_logic_vector(3 downto 0);
  signal IR_Load       : std_logic;
  signal MAR_Load      : std_logic;
  signal PC_Load       : std_logic;
  signal PC_Inc        : std_logic;
  signal A_Load        : std_logic;
  signal B_Load        : std_logic;
  signal CCR_Load      : std_logic;
  signal ALU_Sel       : std_logic_vector(3 downto 0);
  signal Bus1_Sel      : std_logic_vector(1 downto 0);
  signal Bus2_Sel      : std_logic_vector(1 downto 0);
begin

  CU : entity work.control_unit
    port map (
      clock      => clock,
      reset      => reset,
      IR         => IR_sig,
      CCR_Result => CCR_sig,
      IR_Load    => IR_Load,
      MAR_Load   => MAR_Load,
      PC_Load    => PC_Load,
      PC_Inc     => PC_Inc,
      A_Load     => A_Load,
      B_Load     => B_Load,
      CCR_Load   => CCR_Load,
      ALU_Sel    => ALU_Sel,
      Bus1_Sel   => Bus1_Sel,
      Bus2_Sel   => Bus2_Sel,
      write      => write
    );

  DP : entity work.data_path
    port map (
      clock       => clock,
      reset       => reset,
      IR_Load     => IR_Load,
      MAR_Load    => MAR_Load,
      PC_Load     => PC_Load,
      PC_Inc      => PC_Inc,
      A_Load      => A_Load,
      B_Load      => B_Load,
      CCR_Load    => CCR_Load,
      ALU_Sel     => ALU_Sel,
      Bus1_Sel    => Bus1_Sel,
      Bus2_Sel    => Bus2_Sel,
      address     => address,
      to_memory   => to_memory,
      from_memory => from_memory,
      IR          => IR_sig,
      CCR_Result  => CCR_sig
    );

  IR <= IR_sig;
  CCR_Result <= CCR_sig;

end architecture structural;
