library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
  port (
    clock      : in  std_logic;
    reset      : in  std_logic;
    -- Inputs from data path
    IR         : in  std_logic_vector(7 downto 0);
    CCR_Result : in  std_logic_vector(3 downto 0);
    -- Outputs to data path
    IR_Load    : out std_logic;
    MAR_Load   : out std_logic;
    PC_Load    : out std_logic;
    PC_Inc     : out std_logic;
    A_Load     : out std_logic;
    B_Load     : out std_logic;
    CCR_Load   : out std_logic;
    ALU_Sel    : out std_logic_vector(3 downto 0);
    Bus1_Sel   : out std_logic_vector(1 downto 0);
    Bus2_Sel   : out std_logic_vector(1 downto 0);
    -- Memory write
    write      : out std_logic
  );
end entity control_unit;

architecture rtl of control_unit is

  -- Opcode constants (Chapter 13)
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

  type state_type is (
    S_FETCH_0, S_FETCH_1, S_FETCH_2,
    S_DECODE_3,
    -- LDA_IMM
    S_LDA_IMM_4, S_LDA_IMM_5, S_LDA_IMM_6,
    -- LDA_DIR
    S_LDA_DIR_4, S_LDA_DIR_5, S_LDA_DIR_6, S_LDA_DIR_7, S_LDA_DIR_8,
    -- LDB_IMM
    S_LDB_IMM_4, S_LDB_IMM_5, S_LDB_IMM_6,
    -- LDB_DIR
    S_LDB_DIR_4, S_LDB_DIR_5, S_LDB_DIR_6, S_LDB_DIR_7, S_LDB_DIR_8,
    -- STA_DIR
    S_STA_DIR_4, S_STA_DIR_5, S_STA_DIR_6, S_STA_DIR_7,
    -- STB_DIR
    S_STB_DIR_4, S_STB_DIR_5, S_STB_DIR_6, S_STB_DIR_7,
    -- Data manipulation (single state after decode)
    S_ADD_AB_4,
    S_SUB_AB_4,
    S_AND_AB_4,
    S_OR_AB_4,
    S_INCA_4,
    S_INCB_4,
    S_DECA_4,
    S_DECB_4,
    -- Branches taken
    S_BRA_4, S_BRA_5, S_BRA_6,
    -- Branch conditional taken / not taken (use generic 4-7 path)
    S_BR_TAKEN_4, S_BR_TAKEN_5, S_BR_TAKEN_6,
    S_BR_NOT_TAKEN_4
  );

  signal current_state, next_state : state_type;

begin

  -- State memory
  STATE_MEMORY : process (clock, reset)
  begin
    if (reset = '0') then
      current_state <= S_FETCH_0;
    elsif (clock'event and clock = '1') then
      current_state <= next_state;
    end if;
  end process;

  -- Next state logic
  NEXT_STATE_LOGIC : process (current_state, IR, CCR_Result)
  begin
    case current_state is

      when S_FETCH_0 =>
        next_state <= S_FETCH_1;
      when S_FETCH_1 =>
        next_state <= S_FETCH_2;
      when S_FETCH_2 =>
        next_state <= S_DECODE_3;

      when S_DECODE_3 =>
        if    (IR = LDA_IMM) then next_state <= S_LDA_IMM_4;
        elsif (IR = LDA_DIR) then next_state <= S_LDA_DIR_4;
        elsif (IR = LDB_IMM) then next_state <= S_LDB_IMM_4;
        elsif (IR = LDB_DIR) then next_state <= S_LDB_DIR_4;
        elsif (IR = STA_DIR) then next_state <= S_STA_DIR_4;
        elsif (IR = STB_DIR) then next_state <= S_STB_DIR_4;
        elsif (IR = ADD_AB) then  next_state <= S_ADD_AB_4;
        elsif (IR = SUB_AB) then  next_state <= S_SUB_AB_4;
        elsif (IR = AND_AB) then  next_state <= S_AND_AB_4;
        elsif (IR = OR_AB)  then  next_state <= S_OR_AB_4;
        elsif (IR = INCA)   then  next_state <= S_INCA_4;
        elsif (IR = INCB)   then  next_state <= S_INCB_4;
        elsif (IR = DECA)   then  next_state <= S_DECA_4;
        elsif (IR = DECB)   then  next_state <= S_DECB_4;
        elsif (IR = BRA)    then  next_state <= S_BRA_4;
        -- BMI: branch if N=1
        elsif (IR = BMI and CCR_Result(3) = '1') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BMI and CCR_Result(3) = '0') then next_state <= S_BR_NOT_TAKEN_4;
        -- BPL: branch if N=0
        elsif (IR = BPL and CCR_Result(3) = '0') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BPL and CCR_Result(3) = '1') then next_state <= S_BR_NOT_TAKEN_4;
        -- BEQ: branch if Z=1
        elsif (IR = BEQ and CCR_Result(2) = '1') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BEQ and CCR_Result(2) = '0') then next_state <= S_BR_NOT_TAKEN_4;
        -- BNE: branch if Z=0
        elsif (IR = BNE and CCR_Result(2) = '0') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BNE and CCR_Result(2) = '1') then next_state <= S_BR_NOT_TAKEN_4;
        -- BVS: branch if V=1
        elsif (IR = BVS and CCR_Result(1) = '1') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BVS and CCR_Result(1) = '0') then next_state <= S_BR_NOT_TAKEN_4;
        -- BVC: branch if V=0
        elsif (IR = BVC and CCR_Result(1) = '0') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BVC and CCR_Result(1) = '1') then next_state <= S_BR_NOT_TAKEN_4;
        -- BCS: branch if C=1
        elsif (IR = BCS and CCR_Result(0) = '1') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BCS and CCR_Result(0) = '0') then next_state <= S_BR_NOT_TAKEN_4;
        -- BCC: branch if C=0
        elsif (IR = BCC and CCR_Result(0) = '0') then next_state <= S_BR_TAKEN_4;
        elsif (IR = BCC and CCR_Result(0) = '1') then next_state <= S_BR_NOT_TAKEN_4;
        else
          next_state <= S_FETCH_0;
        end if;

      -- LDA_IMM
      when S_LDA_IMM_4 => next_state <= S_LDA_IMM_5;
      when S_LDA_IMM_5 => next_state <= S_LDA_IMM_6;
      when S_LDA_IMM_6 => next_state <= S_FETCH_0;

      -- LDA_DIR
      when S_LDA_DIR_4 => next_state <= S_LDA_DIR_5;
      when S_LDA_DIR_5 => next_state <= S_LDA_DIR_6;
      when S_LDA_DIR_6 => next_state <= S_LDA_DIR_7;
      when S_LDA_DIR_7 => next_state <= S_LDA_DIR_8;
      when S_LDA_DIR_8 => next_state <= S_FETCH_0;

      -- LDB_IMM
      when S_LDB_IMM_4 => next_state <= S_LDB_IMM_5;
      when S_LDB_IMM_5 => next_state <= S_LDB_IMM_6;
      when S_LDB_IMM_6 => next_state <= S_FETCH_0;

      -- LDB_DIR
      when S_LDB_DIR_4 => next_state <= S_LDB_DIR_5;
      when S_LDB_DIR_5 => next_state <= S_LDB_DIR_6;
      when S_LDB_DIR_6 => next_state <= S_LDB_DIR_7;
      when S_LDB_DIR_7 => next_state <= S_LDB_DIR_8;
      when S_LDB_DIR_8 => next_state <= S_FETCH_0;

      -- STA_DIR
      when S_STA_DIR_4 => next_state <= S_STA_DIR_5;
      when S_STA_DIR_5 => next_state <= S_STA_DIR_6;
      when S_STA_DIR_6 => next_state <= S_STA_DIR_7;
      when S_STA_DIR_7 => next_state <= S_FETCH_0;

      -- STB_DIR
      when S_STB_DIR_4 => next_state <= S_STB_DIR_5;
      when S_STB_DIR_5 => next_state <= S_STB_DIR_6;
      when S_STB_DIR_6 => next_state <= S_STB_DIR_7;
      when S_STB_DIR_7 => next_state <= S_FETCH_0;

      -- Data manipulation
      when S_ADD_AB_4 => next_state <= S_FETCH_0;
      when S_SUB_AB_4 => next_state <= S_FETCH_0;
      when S_AND_AB_4 => next_state <= S_FETCH_0;
      when S_OR_AB_4  => next_state <= S_FETCH_0;
      when S_INCA_4   => next_state <= S_FETCH_0;
      when S_INCB_4   => next_state <= S_FETCH_0;
      when S_DECA_4   => next_state <= S_FETCH_0;
      when S_DECB_4   => next_state <= S_FETCH_0;

      -- BRA
      when S_BRA_4 => next_state <= S_BRA_5;
      when S_BRA_5 => next_state <= S_BRA_6;
      when S_BRA_6 => next_state <= S_FETCH_0;

      -- Conditional branch (taken)
      when S_BR_TAKEN_4 => next_state <= S_BR_TAKEN_5;
      when S_BR_TAKEN_5 => next_state <= S_BR_TAKEN_6;
      when S_BR_TAKEN_6 => next_state <= S_FETCH_0;

      -- Conditional branch (not taken)
      when S_BR_NOT_TAKEN_4 => next_state <= S_FETCH_0;

      when others => next_state <= S_FETCH_0;

    end case;
  end process;

  -- Output logic (Moore)
  OUTPUT_LOGIC : process (current_state)
  begin
    -- Defaults
    IR_Load  <= '0';
    MAR_Load <= '0';
    PC_Load  <= '0';
    PC_Inc   <= '0';
    A_Load   <= '0';
    B_Load   <= '0';
    CCR_Load <= '0';
    ALU_Sel  <= "0000";
    Bus1_Sel <= "00";
    Bus2_Sel <= "00";
    write    <= '0';

    case current_state is

      -- ====================== FETCH ======================
      when S_FETCH_0 =>
        -- Put PC onto MAR to address opcode
        MAR_Load <= '1';
        Bus1_Sel <= "00"; -- PC
        Bus2_Sel <= "01"; -- Bus1

      when S_FETCH_1 =>
        -- Increment PC
        PC_Inc <= '1';

      when S_FETCH_2 =>
        -- Latch from_memory into IR
        IR_Load  <= '1';
        Bus2_Sel <= "10"; -- from_memory

      when S_DECODE_3 =>
        null;

      -- ====================== LDA_IMM ======================
      when S_LDA_IMM_4 =>
        -- Put PC onto MAR to address operand
        MAR_Load <= '1';
        Bus1_Sel <= "00"; -- PC
        Bus2_Sel <= "01";

      when S_LDA_IMM_5 =>
        PC_Inc <= '1';

      when S_LDA_IMM_6 =>
        -- Latch from_memory into A
        A_Load   <= '1';
        Bus2_Sel <= "10"; -- from_memory

      -- ====================== LDA_DIR ======================
      when S_LDA_DIR_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_LDA_DIR_5 =>
        PC_Inc <= '1';

      when S_LDA_DIR_6 =>
        -- Latch operand (which is address) into MAR
        MAR_Load <= '1';
        Bus2_Sel <= "10"; -- from_memory

      when S_LDA_DIR_7 =>
        -- Wait for memory
        null;

      when S_LDA_DIR_8 =>
        A_Load   <= '1';
        Bus2_Sel <= "10";

      -- ====================== LDB_IMM ======================
      when S_LDB_IMM_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_LDB_IMM_5 =>
        PC_Inc <= '1';

      when S_LDB_IMM_6 =>
        B_Load   <= '1';
        Bus2_Sel <= "10";

      -- ====================== LDB_DIR ======================
      when S_LDB_DIR_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_LDB_DIR_5 =>
        PC_Inc <= '1';

      when S_LDB_DIR_6 =>
        MAR_Load <= '1';
        Bus2_Sel <= "10";

      when S_LDB_DIR_7 =>
        null;

      when S_LDB_DIR_8 =>
        B_Load   <= '1';
        Bus2_Sel <= "10";

      -- ====================== STA_DIR ======================
      when S_STA_DIR_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_STA_DIR_5 =>
        PC_Inc <= '1';

      when S_STA_DIR_6 =>
        -- Operand (address) into MAR
        MAR_Load <= '1';
        Bus2_Sel <= "10";

      when S_STA_DIR_7 =>
        -- Write A onto Bus1 -> to_memory at MAR
        Bus1_Sel <= "01"; -- A
        write    <= '1';

      -- ====================== STB_DIR ======================
      when S_STB_DIR_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_STB_DIR_5 =>
        PC_Inc <= '1';

      when S_STB_DIR_6 =>
        MAR_Load <= '1';
        Bus2_Sel <= "10";

      when S_STB_DIR_7 =>
        Bus1_Sel <= "10"; -- B
        write    <= '1';

      -- ====================== Data manipulation ======================
      when S_ADD_AB_4 =>
        ALU_Sel  <= "0000";
        Bus1_Sel <= "01"; -- A onto Bus1 (so ALU sees A)
        Bus2_Sel <= "00"; -- ALU_Result onto Bus2
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_SUB_AB_4 =>
        ALU_Sel  <= "0001";
        Bus1_Sel <= "01";
        Bus2_Sel <= "00";
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_AND_AB_4 =>
        ALU_Sel  <= "0010";
        Bus1_Sel <= "01";
        Bus2_Sel <= "00";
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_OR_AB_4 =>
        ALU_Sel  <= "0011";
        Bus1_Sel <= "01";
        Bus2_Sel <= "00";
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_INCA_4 =>
        ALU_Sel  <= "0100";
        Bus2_Sel <= "00";
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_INCB_4 =>
        ALU_Sel  <= "0101";
        Bus2_Sel <= "00";
        B_Load   <= '1';
        CCR_Load <= '1';

      when S_DECA_4 =>
        ALU_Sel  <= "0110";
        Bus2_Sel <= "00";
        A_Load   <= '1';
        CCR_Load <= '1';

      when S_DECB_4 =>
        ALU_Sel  <= "0111";
        Bus2_Sel <= "00";
        B_Load   <= '1';
        CCR_Load <= '1';

      -- ====================== BRA ======================
      when S_BRA_4 =>
        -- PC onto MAR to address operand (target addr)
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_BRA_5 =>
        -- Wait for memory
        null;

      when S_BRA_6 =>
        -- Latch operand into PC
        PC_Load  <= '1';
        Bus2_Sel <= "10";

      -- ====================== Conditional branch taken ======================
      when S_BR_TAKEN_4 =>
        MAR_Load <= '1';
        Bus1_Sel <= "00";
        Bus2_Sel <= "01";

      when S_BR_TAKEN_5 =>
        null;

      when S_BR_TAKEN_6 =>
        PC_Load  <= '1';
        Bus2_Sel <= "10";

      -- ====================== Conditional branch not taken ======================
      when S_BR_NOT_TAKEN_4 =>
        -- Skip operand by incrementing PC once
        PC_Inc <= '1';

      when others =>
        null;

    end case;
  end process;

end architecture rtl;
