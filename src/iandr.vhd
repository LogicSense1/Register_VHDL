-- execute I and R type instructions

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.common.all;

entity iandr is
    port (reset : in  std_logic;
          clk   : in  std_logic;
             y : out word);
end iandr;

architecture behavioral of iandr is

signal alu_func : alu_func_t := ALU_NONE;
signal alu_A : word := x"00000000";
signal alu_B : word := x"00000000";
signal alu_out : word := x"00000000";
signal reg_B : word := x"00000000";
signal imm : word := x"00000000";
signal ir : word := x"00000000";



-- instruction fields
signal opcode : opcode_t;
signal funct3 : std_logic_vector(2 downto 0);
signal funct7 : std_logic_vector(6 downto 0);
signal rs1 : std_logic_vector(4 downto 0);
signal rs2 : std_logic_vector(4 downto 0);
signal rd : std_logic_vector(4 downto 0);
signal pc : unsigned(word'range) := x"00000000";

-- control signals
signal regwrite : std_logic;
signal op2sel : std_logic;
     
component alu is
port (alu_func : in  alu_func_t;
        op1      : in  word;
        op2      : in  word;
        result   : out word);
end component alu;

component imem is 
port(    
    addr : in std_logic_vector(3 downto 0);
    dout : out word);
end component imem;

component regfile is
port (reset : in  std_logic;
      clk   : in  std_logic;
      addra : in  std_logic_vector(4 downto 0);
      addrb : in  std_logic_vector(4 downto 0);
      rega  : out word;
      regb  : out word;
      addrw : in  std_logic_vector(4 downto 0);
      dataw : in  word;
      we    : in  std_logic);
end component regfile;

begin
	 -- datapath
    alu0: alu port map(
        alu_func => alu_func,
            op1 => alu_A,
            op2 => alu_B,
            result => alu_out);
          
    imem0: imem port map(    
        addr => std_logic_vector(pc(3 downto 0)),
        dout => ir);
		  
	 reg0: regfile port map(
	       reset => reset,
          clk => clk,
          addra => rs1,
          addrb => rs2,
          rega  => alu_A,
          regb  => reg_B,
          addrw => rd,
          dataw => alu_out,
          we  => regwrite);
    
	 -- instruction fields
    imm(31 downto 12) <= (others => ir(31));
    imm(11 downto 0) <= ir(31 downto 20);
    rs1 <= ir(19 downto 15);
    rs2 <= ir(24 downto 20);
    rd <= ir(11 downto 7);
    funct3 <= ir(14 downto 12);
    funct7 <= ir(31 downto 25);
    opcode <= ir(6 downto 0);
	 
	 -- instantiate regfile here

	 
    read_proc : process(rs2,clk) is
   begin 
	if falling_edge(clk) then
	case (opcode(5)) is
	when '0' => alu_B <= imm;
	when '1' => alu_B <= reg_B;
	when others => null;
	end case;
	end if;
	end process; 

    -- control signals
    op2sel <= '1';
    regwrite <= '1' when ir /= NOP;

    decode_proc : process (funct7, funct3) is
    begin
           case (funct3) is
               when "000" => 
                   if (funct7(5) = '1') then
                       alu_func <= ALU_SUB;
                   else
                       alu_func <= ALU_ADD;
                   end if;
	       when "010" => alu_func <= ALU_SLT;
			 when "001" => alu_func <= ALU_SLL;
			 when others => alu_func <= ALU_NONE;
           end case;
    end process;

    y <= alu_out;
	 
	 
    
    acc: process(reset, clk) 
    begin 
        if (reset = '1') then 
            pc <= (others => '0');
        elsif rising_edge(clk) then 
            pc <= pc + 1;
        end if; 
    end process; 
	 

		
end architecture;
