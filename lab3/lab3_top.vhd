LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;
ENTITY toplevel IS PORT (
	clk50MHz: IN std_logic; -- The main 50 MHz clock
	slider_switches : IN std_logic_vector(7 DOWNTO 0); -- The logic values of the slider switches on the board
	btn0 : IN std_logic; -- The button used for asynchronous reset
	seg7 : OUT std_logic_vector(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT std_logic_vector(3 DOWNTO 0); -- The select lines for the display
	leds : OUT std_logic_vector(7 DOWNTO 0)); -- The seven leds on the board
END toplevel;
ARCHITECTURE Behavioral OF toplevel IS
-- Intermediate signal for the reset signal
signal reset : std_logic;
BEGIN
	-- Set the LED values to mimic the slider switches
	leds <= slider_switches;
	reset <= btn0;
	
	-- Instantiate the display entity
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk50MHz,
				char_in => slider_switches(3 DOWNTO 0),
				reset => reset,
				encoded_char => seg7,
				anodes => anodes
				);
END Behavioral;