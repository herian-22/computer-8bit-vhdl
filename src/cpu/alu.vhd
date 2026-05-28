-- ALU for 8-bit Computer (Chapter 13)
-- Performs arithmetic and logic operations
-- Outputs: Result (8-bit), NZVC flags (4-bit)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    A       : in  std_logic_vector(7 downto 0);
    B       : in  std_logic_vector(7 downto 0);
    ALU_Sel : in  std_logic_vector(3 downto 0);
    Result  : out std_logic_vector(7 downto 0);
    NZVC    : out std_logic_vector(3 downto 0)
  );
end entity alu;

architecture rtl of alu is
begin

  ALU_PROCESS : process (A, B, ALU_Sel)
    variable Sum_uns  : unsigned(8 downto 0);
    variable Res_v    : std_logic_vector(7 downto 0);
  begin

    case ALU_Sel is

      -- Addition (ADD_AB)
      when "0000" =>
        Sum_uns := unsigned('0' & A) + unsigned('0' & B);
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        -- N
        NZVC(3) <= Res_v(7);
        -- Z
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        -- V
        if ((A(7)='0' and B(7)='0' and Res_v(7)='1') or
            (A(7)='1' and B(7)='1' and Res_v(7)='0')) then
          NZVC(1) <= '1';
        else
          NZVC(1) <= '0';
        end if;
        -- C
        NZVC(0) <= Sum_uns(8);

      -- Subtraction (SUB_AB): A - B
      when "0001" =>
        Sum_uns := unsigned('0' & A) - unsigned('0' & B);
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        if ((A(7)='0' and B(7)='1' and Res_v(7)='1') or
            (A(7)='1' and B(7)='0' and Res_v(7)='0')) then
          NZVC(1) <= '1';
        else
          NZVC(1) <= '0';
        end if;
        NZVC(0) <= Sum_uns(8);

      -- AND (AND_AB)
      when "0010" =>
        Res_v  := A and B;
        Result <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        NZVC(1) <= '0';
        NZVC(0) <= '0';

      -- OR (OR_AB)
      when "0011" =>
        Res_v  := A or B;
        Result <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        NZVC(1) <= '0';
        NZVC(0) <= '0';

      -- Increment A (INCA)
      when "0100" =>
        Sum_uns := unsigned('0' & A) + 1;
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        if (A(7)='0' and Res_v(7)='1') then NZVC(1) <= '1'; else NZVC(1) <= '0'; end if;
        NZVC(0) <= Sum_uns(8);

      -- Increment B (INCB)
      when "0101" =>
        Sum_uns := unsigned('0' & B) + 1;
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        if (B(7)='0' and Res_v(7)='1') then NZVC(1) <= '1'; else NZVC(1) <= '0'; end if;
        NZVC(0) <= Sum_uns(8);

      -- Decrement A (DECA)
      when "0110" =>
        Sum_uns := unsigned('0' & A) - 1;
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        if (A(7)='1' and Res_v(7)='0') then NZVC(1) <= '1'; else NZVC(1) <= '0'; end if;
        NZVC(0) <= Sum_uns(8);

      -- Decrement B (DECB)
      when "0111" =>
        Sum_uns := unsigned('0' & B) - 1;
        Res_v   := std_logic_vector(Sum_uns(7 downto 0));
        Result  <= Res_v;
        NZVC(3) <= Res_v(7);
        if (Res_v = x"00") then NZVC(2) <= '1'; else NZVC(2) <= '0'; end if;
        if (B(7)='1' and Res_v(7)='0') then NZVC(1) <= '1'; else NZVC(1) <= '0'; end if;
        NZVC(0) <= Sum_uns(8);

      -- Default
      when others =>
        Result <= A;
        NZVC   <= "0000";

    end case;
  end process;

end architecture rtl;
