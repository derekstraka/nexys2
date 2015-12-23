LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entity element for a 7 segment display contoller
ENTITY seg7_hex IS
    PORT ( digit : IN  std_logic_vector(3 DOWNTO 0); -- The base 10 digit to display on the display
           seg7_out : OUT  std_logic_vector(6 DOWNTO 0) -- The seven bit parallel bus to the display
			 );
END seg7_hex;

ARCHITECTURE Behavioral OF seg7_hex IS

BEGIN

   display_out: PROCESS(digit)
	BEGIN
		-- Select the appropriate bit pattern to display the digit
		CASE digit IS
				WHEN x"0" => seg7_out <= "1000000";
				WHEN x"1" => seg7_out <= "1111001";
				WHEN x"2" => seg7_out <= "0100100";
				WHEN x"3" => seg7_out <= "0110000";
				WHEN x"4" => seg7_out <= "0011001";
				WHEN x"5" => seg7_out <= "0010010";
				WHEN x"6" => seg7_out <= "0000010";
				WHEN x"7" => seg7_out <= "1111000";
				WHEN x"8" => seg7_out <= "0000000";
				WHEN x"9" => seg7_out <= "0010000";
				WHEN x"A" => seg7_out <= "0001000";
				WHEN x"B" => seg7_out <= "0000011";
				WHEN x"C" => seg7_out <= "1000110";
				WHEN x"D" => seg7_out <= "0100001";
				WHEN x"E" => seg7_out <= "0000110";
				WHEN OTHERS => seg7_out <= "0001110";
		END CASE;
	END PROCESS display_out;
END Behavioral;

