library ieee;
use ieee.std_logic_1164.all;

entity computer_top is
  port (
    clock       : in  std_logic;
    reset       : in  std_logic;
    -- Input ports
    port_in_00  : in  std_logic_vector(7 downto 0);
    port_in_01  : in  std_logic_vector(7 downto 0);
    port_in_02  : in  std_logic_vector(7 downto 0);
    port_in_03  : in  std_logic_vector(7 downto 0);
    port_in_04  : in  std_logic_vector(7 downto 0);
    port_in_05  : in  std_logic_vector(7 downto 0);
    port_in_06  : in  std_logic_vector(7 downto 0);
    port_in_07  : in  std_logic_vector(7 downto 0);
    port_in_08  : in  std_logic_vector(7 downto 0);
    port_in_09  : in  std_logic_vector(7 downto 0);
    port_in_10  : in  std_logic_vector(7 downto 0);
    port_in_11  : in  std_logic_vector(7 downto 0);
    port_in_12  : in  std_logic_vector(7 downto 0);
    port_in_13  : in  std_logic_vector(7 downto 0);
    port_in_14  : in  std_logic_vector(7 downto 0);
    port_in_15  : in  std_logic_vector(7 downto 0);
    -- Output ports
    port_out_00 : out std_logic_vector(7 downto 0);
    port_out_01 : out std_logic_vector(7 downto 0);
    port_out_02 : out std_logic_vector(7 downto 0);
    port_out_03 : out std_logic_vector(7 downto 0);
    port_out_04 : out std_logic_vector(7 downto 0);
    port_out_05 : out std_logic_vector(7 downto 0);
    port_out_06 : out std_logic_vector(7 downto 0);
    port_out_07 : out std_logic_vector(7 downto 0);
    port_out_08 : out std_logic_vector(7 downto 0);
    port_out_09 : out std_logic_vector(7 downto 0);
    port_out_10 : out std_logic_vector(7 downto 0);
    port_out_11 : out std_logic_vector(7 downto 0);
    port_out_12 : out std_logic_vector(7 downto 0);
    port_out_13 : out std_logic_vector(7 downto 0);
    port_out_14 : out std_logic_vector(7 downto 0);
    port_out_15 : out std_logic_vector(7 downto 0)
  );
end entity computer_top;

architecture structural of computer_top is
  signal address    : std_logic_vector(7 downto 0);
  signal to_memory  : std_logic_vector(7 downto 0);
  signal from_memory : std_logic_vector(7 downto 0);
  signal write_sig  : std_logic;
  signal IR         : std_logic_vector(7 downto 0);
  signal CCR_Result : std_logic_vector(3 downto 0);
begin

  CPU_INST : entity work.cpu
    port map (
      clock       => clock,
      reset       => reset,
      from_memory => from_memory,
      IR          => IR,
      CCR_Result  => CCR_Result,
      address     => address,
      to_memory   => to_memory,
      write       => write_sig
    );

  MEM_INST : entity work.memory_system
    port map (
      clock       => clock,
      reset       => reset,
      address     => address,
      write       => write_sig,
      data_in     => to_memory,
      data_out    => from_memory,
      port_in_00  => port_in_00,
      port_in_01  => port_in_01,
      port_in_02  => port_in_02,
      port_in_03  => port_in_03,
      port_in_04  => port_in_04,
      port_in_05  => port_in_05,
      port_in_06  => port_in_06,
      port_in_07  => port_in_07,
      port_in_08  => port_in_08,
      port_in_09  => port_in_09,
      port_in_10  => port_in_10,
      port_in_11  => port_in_11,
      port_in_12  => port_in_12,
      port_in_13  => port_in_13,
      port_in_14  => port_in_14,
      port_in_15  => port_in_15,
      port_out_00 => port_out_00,
      port_out_01 => port_out_01,
      port_out_02 => port_out_02,
      port_out_03 => port_out_03,
      port_out_04 => port_out_04,
      port_out_05 => port_out_05,
      port_out_06 => port_out_06,
      port_out_07 => port_out_07,
      port_out_08 => port_out_08,
      port_out_09 => port_out_09,
      port_out_10 => port_out_10,
      port_out_11 => port_out_11,
      port_out_12 => port_out_12,
      port_out_13 => port_out_13,
      port_out_14 => port_out_14,
      port_out_15 => port_out_15
    );

end architecture structural;
