LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;
ENTITY toplevel IS PORT (
	slider_switches : IN std_logic_vector(7 DOWNTO 0); -- The logic values of the slider switches on the board
	push_buttons : IN std_logic_vector(3 DOWNTO 0); -- The logic values of the push buttons
	seg7 : OUT std_logic_vector(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT std_logic_vector(3 DOWNTO 0); -- The select lines for the display
	leds : OUT std_logic_vector(7 DOWNTO 0)); -- The seven leds on the board
END toplevel;
ARCHITECTURE Behavioral OF toplevel IS
-- Intermediate signal for the display output
signal seg7_disp_out: std_logic_vector(6 DOWNTO 0);
BEGIN
	-- Set the LED values to mimic the slider switches
	leds <= slider_switches;
	
	-- Instantiate the display entity
	seg7_display : ENTITY seg7_hex PORT MAP (
				seg7_out => seg7_disp_out, -- Map the output to the internal signal that will be run through a mux
				digit => slider_switches(3 DOWNTO 0) -- Map the first four switches to the display digit
				);

	-- Simple mux to display the switch values unless both buttons are pressed
	-- In that case, display a zero
	display_mux: PROCESS(push_buttons, seg7_disp_out)
	BEGIN
		CASE push_buttons IS
					WHEN "0011" => seg7 <= "1000000";
					WHEN OTHERS => seg7 <= seg7_disp_out;
		END CASE;
	END PROCESS display_mux;

	-- Select the position of the displayed values
	-- No buttons pushed is right most
	-- Button 0 pressed shift the digit to the second from the right
	-- Button 1 pressed display on the two right most displays
	-- Both buttons has the value of '0' on all four displays
	anode_mux: PROCESS (push_buttons)
	BEGIN
		CASE push_buttons IS
			WHEN "0001" => anodes <= "1101";
			WHEN "0010" => anodes <= "1100";
			WHEN "0011" => anodes <= "0000";
			WHEN OTHERS => anodes <= "1110";
		END CASE;
	END PROCESS anode_mux;
	
END Behavioral;