library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.all;

entity lab04_tb is
end lab04_tb;

architecture Behavioral of lab04_tb is

	signal push_buttons	  : std_logic_vector(3 downto 0) := "0000";
   signal clk_50         : std_logic := '0';           
   signal slider_switches : std_logic_vector(7 downto 0);
   signal seg7           : std_logic_vector(6 downto 0);
	signal an             : std_logic_vector(3 downto 0);
   signal leds : std_logic_vector(7 downto 0);
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
   leds <= slider_switches;
	-- Asynchronous reset:
	process
	begin

		-- Reset
		push_buttons(3 downto 0) <= "0000"; wait for 0 ns;
		push_buttons(3 downto 0) <= "0001"; wait for 200 ns;
		push_buttons(3 downto 0) <= "0000";
		
		-- Make sure enough time has ellapsed to load data values into first 256 locations of SRAM
		wait for 240000 ns;
		slider_switches <= "00000000";
		
		-- read address 0x00
		slider_switches <= "00000000"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;
	
		-- read address 0x01
		slider_switches <= "00000001";
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;
		
		-- read address 0x02
		slider_switches <= "00000010"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;
		
		-- read address 0x80
		slider_switches <= "10000000"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;

		-- read address 0x81
		slider_switches <= "10000001"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;		
		
		-- read address 0x82
		slider_switches <= "10000010"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;		

		slider_switches <= "11111101"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;
		
		-- read address 0xFE
		slider_switches <= "11111110"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait for 1000 ns;
		
		-- read address 0xFF
		slider_switches <= "11111111"; 
		push_buttons(3 downto 0) <= "0010"; wait for 504 ns;
		push_buttons(3 downto 0) <= "0000"; wait;

	end process;
	
	-- Instantiate the top level design
	lab4_top_0: entity toplevel port map(
		clk50MHz =>clk_50, 
		push_buttons => push_buttons, 
		slider_switches => slider_switches, 
		seg7 => seg7, 
		anodes => an,
		leds => leds,
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
