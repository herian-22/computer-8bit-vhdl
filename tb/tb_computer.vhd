library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_computer is
end entity tb_computer;

architecture sim of tb_computer is
  signal clock       : std_logic := '0';
  signal reset       : std_logic := '0';
  signal sim_done    : boolean   := false;

  signal port_in_00  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_01  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_02  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_03  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_04  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_05  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_06  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_07  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_08  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_09  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_10  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_11  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_12  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_13  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_14  : std_logic_vector(7 downto 0) := x"00";
  signal port_in_15  : std_logic_vector(7 downto 0) := x"00";

  signal port_out_00 : std_logic_vector(7 downto 0);
  signal port_out_01 : std_logic_vector(7 downto 0);
  signal port_out_02 : std_logic_vector(7 downto 0);
  signal port_out_03 : std_logic_vector(7 downto 0);
  signal port_out_04 : std_logic_vector(7 downto 0);
  signal port_out_05 : std_logic_vector(7 downto 0);
  signal port_out_06 : std_logic_vector(7 downto 0);
  signal port_out_07 : std_logic_vector(7 downto 0);
  signal port_out_08 : std_logic_vector(7 downto 0);
  signal port_out_09 : std_logic_vector(7 downto 0);
  signal port_out_10 : std_logic_vector(7 downto 0);
  signal port_out_11 : std_logic_vector(7 downto 0);
  signal port_out_12 : std_logic_vector(7 downto 0);
  signal port_out_13 : std_logic_vector(7 downto 0);
  signal port_out_14 : std_logic_vector(7 downto 0);
  signal port_out_15 : std_logic_vector(7 downto 0);
begin

  DUT : entity work.computer_top
    port map (
      clock       => clock,
      reset       => reset,
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

  -- 50 MHz clock (20 ns period)
  clk_gen : process
  begin
    while not sim_done loop
      clock <= '0';
      wait for 10 ns;
      clock <= '1';
      wait for 10 ns;
    end loop;
    wait;
  end process;

  -- Stimulus and checks
  stim : process
  begin
    -- Reset (active low in this design)
    reset <= '0';
    wait for 50 ns;
    reset <= '1';

    -- Run long enough for full program (~60 instructions, ~8 cycles each, 20 ns = ~10 us)
    wait for 12 us;

    report "===================================================" severity note;
    report "Test results (from output ports):" severity note;
    report "===================================================" severity note;

    -- Test 1: ADD 0x05 + 0x03 = 0x08 -> port_out_00
    assert port_out_00 = x"08"
      report "FAIL Test1 ADD_AB: expected 0x08 at port_out_00, got " &
             integer'image(to_integer(unsigned(port_out_00)))
      severity error;
    report "PASS Test1 LDA_IMM/LDB_IMM/ADD_AB -> port_out_00 = 0x08" severity note;

    -- Test 2: ADD 0xFF + 0x01 = 0x00 -> port_out_01
    assert port_out_01 = x"00"
      report "FAIL Test2 ADD_AB overflow: expected 0x00 at port_out_01"
      severity error;
    report "PASS Test2 ADD overflow -> port_out_01 = 0x00 (Z=1)" severity note;

    -- Test 3: BEQ branch taken -> port_out_02 should remain 0x00 (not written)
    assert port_out_02 = x"00"
      report "FAIL Test3 BEQ: branch should have been taken, port_out_02 should not have been written"
      severity error;
    report "PASS Test3 BEQ branch taken (port_out_02 untouched)" severity note;

    -- Test 3b: After branch taken, port_out_03 should be 0x55
    assert port_out_03 = x"55"
      report "FAIL Test3b BEQ target: expected 0x55 at port_out_03"
      severity error;
    report "PASS Test3b BEQ target reached -> port_out_03 = 0x55" severity note;

    -- Test 4: SUB 0x0A - 0x03 = 0x07 -> port_out_04
    assert port_out_04 = x"07"
      report "FAIL Test4 SUB_AB: expected 0x07 at port_out_04"
      severity error;
    report "PASS Test4 SUB_AB -> port_out_04 = 0x07" severity note;

    -- Test 5: AND 0x0F & 0xF0 = 0x00 -> port_out_05
    assert port_out_05 = x"00"
      report "FAIL Test5 AND_AB: expected 0x00 at port_out_05"
      severity error;
    report "PASS Test5 AND_AB -> port_out_05 = 0x00" severity note;

    -- Test 6: OR 0x0F | 0xF0 = 0xFF -> port_out_06
    assert port_out_06 = x"FF"
      report "FAIL Test6 OR_AB: expected 0xFF at port_out_06"
      severity error;
    report "PASS Test6 OR_AB -> port_out_06 = 0xFF" severity note;

    -- Test 7: INCA 0x7F + 1 = 0x80 -> port_out_07
    assert port_out_07 = x"80"
      report "FAIL Test7 INCA: expected 0x80 at port_out_07"
      severity error;
    report "PASS Test7 INCA -> port_out_07 = 0x80" severity note;

    -- Test 8: DECA 0x01 - 1 = 0x00 -> port_out_08
    assert port_out_08 = x"00"
      report "FAIL Test8 DECA: expected 0x00 at port_out_08"
      severity error;
    report "PASS Test8 DECA -> port_out_08 = 0x00" severity note;

    report "===================================================" severity note;
    report "ALL TESTS COMPLETE" severity note;
    report "===================================================" severity note;

    sim_done <= true;
    wait for 50 ns;
    assert false report "Simulation finished" severity failure;
  end process;

end architecture sim;
