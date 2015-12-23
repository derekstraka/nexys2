library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.all;

entity lab06_tb is
end lab06_tb;

architecture Behavioral of lab06_tb is

	signal pushButtons	  : std_logic_vector(1 downto 0) := "00";
    signal clk_50         : std_logic := '0';           
    signal seg7           : std_logic_vector(6 downto 0);
	signal an             : std_logic_vector(3 downto 0);
	signal RAM_Adr : std_logic_vector (23 downto 1); 			-- Address
	signal RAM_OEb	: std_logic;								-- Output Enable
	signal RAM_WEb	: std_logic;								-- Write Enable
	signal RAMAdv   : std_logic; 								-- Address Valid
	signal RAMClk   : std_logic; 								-- RAM clock
	signal RAMCre   : std_logic; 								-- 
	signal RAM_CEb	: std_logic; 								-- Chep Enable
	signal RAM_LB	: std_logic; 								-- Lower Byte
	signal RAM_UB	: std_logic; 								-- Upper Byte
	signal RAM_data	: std_logic_vector (15 downto 0);			-- Bidirectional data
	
begin 
    
	clk_50 <= not clk_50 after 10 ns;
   
	-- Asynchronous reset:
	process
	begin
	
		-- Reset
		pushButtons(1 downto 0) <= "00"; wait for 0 ns;
		pushButtons(1 downto 0) <= "01"; wait for 200 ns;
		pushButtons(1 downto 0) <= "00";
		
		-- Make sure enough time has ellapsed to load data values into first 256 locations of SRAM
		wait for 100 us;
		
		-- Press BTN1 to begin reading
		pushButtons(1 downto 0) <= "10"; wait for 504 ns;
		pushButtons(1 downto 0) <= "00"; wait for 1000 ns;
		
		wait;

	end process;
	
	-- Instantiate the top level design
	lab6_top_0: entity lab6_top port map(
		clk50MHz =>clk_50, 
		push_buttons => pushButtons, 
		seg7 => seg7, 
		anodes => an,
		RAM_Addr => RAM_Adr,
		RAM_OEb => RAM_OEb,
		RAM_WE => RAM_WEb,
		RAM_Adv => RAMAdv,
		RAM_Clk => RAMClk,
		RAM_Cre => RAMCre,
		RAM_CE => RAM_CEb,
		RAM_LB => RAM_LB,
		RAM_UB => RAM_UB,
		RAM_Data => RAM_data);
	
	-- Instantiate the SRAM. For ModelSim simulation only. Do not synthesize
	sram_0: entity sram_d port map(
		RAM_CEb,
		RAM_OEb,
		RAM_WEb,
		RAM_Adr(8 downto 1),
		RAM_data,
		'1');

end architecture;
