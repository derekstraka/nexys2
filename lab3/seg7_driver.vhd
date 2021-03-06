LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.all;

ENTITY seg7_driver is
    Port ( clk : IN  STD_LOGIC; -- Input clock
           reset : IN  STD_LOGIC; -- Async reset line
			  char_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Character to display in the lowest segment
			  anodes: OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Anode selection for the display
			  encoded_char : OUT  STD_LOGIC_VECTOR(6 DOWNTO 0));-- Encoded character value
END seg7_driver;

ARCHITECTURE Behavioral OF seg7_driver IS
signal char_output : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Character value to output
signal one_khz_pulse : STD_LOGIC; -- Signal for the 1 KHz pulse
signal one_hz_pulse : STD_LOGIC; -- Signal for the one hz pulse
signal char_sel : UNSIGNED(1 DOWNTO 0); -- Select lines for the character mux
signal char0 : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Register for the right most character
signal char1 : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Register for the third from the left most character
signal char2 : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Register for the second from the left most character
signal char3 : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Register for the left most character
BEGIN

	-- Instantiate the one KHz pulse generator (50000000/1000) => 0xC350
	one_khz_pulse_gen : ENTITY pulse_generator PORT MAP(
		clk => clk,
		reset => '0',
		pulse_out => one_khz_pulse,
		max_cnt => x"0000C350");

	-- Instantiate the one Hz pulse generator (50000000/1) => 0xC2FAF080
	one_hhz_pulse_gen : ENTITY pulse_generator PORT MAP(
		clk => clk,
		reset => reset,
		pulse_out => one_hz_pulse,
		max_cnt => x"02FAF080");

	-- Process used to map the anode based on which character should be displayed
	anode_map : PROCESS(char_sel)
	BEGIN
		case char_sel IS
			when "01" => anodes <= "1101";
			when "10" => anodes <= "1011";
			when "11" => anodes <= "0111";
			when OTHERS => anodes <= "1110";
		END case;
	END PROCESS anode_map;

	-- Process used to map the output character based on which char should be displayed
	char_mux : PROCESS(char_sel, char0, char1, char2, char3)
	BEGIN
			case char_sel IS
				when "01" => char_output <= char1;
				when "10" => char_output <= char2;
				when "11" => char_output <= char3;
				when OTHERS => char_output <= char0;
			END CASE;
	END PROCESS char_mux;
	
	-- Process to map the hex character to the 7 segment display
	display_out: PROCESS(char_output)
	BEGIN
		-- Select the appropriate bit pattern to display the digit
		CASE char_output IS
				WHEN x"0" => encoded_char <= "1000000";
				WHEN x"1" => encoded_char <= "1111001";
				WHEN x"2" => encoded_char <= "0100100";
				WHEN x"3" => encoded_char <= "0110000";
				WHEN x"4" => encoded_char <= "0011001";
				WHEN x"5" => encoded_char <= "0010010";
				WHEN x"6" => encoded_char <= "0000010";
				WHEN x"7" => encoded_char <= "1111000";
				WHEN x"8" => encoded_char <= "0000000";
				WHEN x"9" => encoded_char <= "0010000";
				WHEN x"A" => encoded_char <= "0001000";
				WHEN x"B" => encoded_char <= "0000011";
				WHEN x"C" => encoded_char <= "1000110";
				WHEN x"D" => encoded_char <= "0100001";
				WHEN x"E" => encoded_char <= "0000110";
				WHEN OTHERS => encoded_char <= "0001110";
		END CASE;
	END PROCESS display_out;
	
	-- Process used to shift the characters 
	shift_char: PROCESS(clk, reset)
	BEGIN
		-- If in reset, reset all of the characters to 0
		IF (reset = '1') THEN
			char0 <= (OTHERS => '0');
			char1 <= (OTHERS => '0');
			char2 <= (OTHERS => '0');
			char3 <= (OTHERS => '0');
		-- Change the lowest register based on the current switch values
		ELSIF(rising_edge(clk)) THEN
			char0 <= char_in;
			-- Shift things down if the on hz pulse is active
			IF(one_hz_pulse = '1') THEN
				char3 <= char2;
				char2 <= char1;
				char1 <= char0;
			END IF;
		END IF;
	END PROCESS shift_char;
	
	-- Process used to time mux the 7 segment display
	time_mux: PROCESS(clk)
	BEGIN
		-- Change the character to display every 1 KHz pulse
		IF(rising_edge(clk)) THEN
			IF(one_khz_pulse = '1') THEN
				char_sel <= char_sel + 1;
			END IF;
		END IF;
	END PROCESS time_mux;
END Behavioral;

