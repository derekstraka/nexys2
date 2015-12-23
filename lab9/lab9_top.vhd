LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;

ENTITY lab9_top IS PORT (
	clk50MHz: IN STD_LOGIC; -- 50 MHz Clock
	clk32Mhz: IN STD_LOGIC; -- 32 MHz Clock
	push_buttons: IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- The set of push buttons
	slider_switches: IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- The set of slider switches
	seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- The 7 segment display
	leds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- The set of LEDs
	anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)); -- The anodes for the 7 segment display
END lab9_top;


ARCHITECTURE Behavioral OF lab9_top IS
signal one_pps_duration: UNSIGNED(25 DOWNTO 0); -- Signal used to hold the number of 50 MHz pulses per second
signal clk_cntr: UNSIGNED(25 DOWNTO 0); -- Counter of the number of 50 MHz clocks
signal offset: UNSIGNED(15 DOWNTO 0); -- The unsigned difference between the actual and theoretical
signal abs_min_offset: UNSIGNED(15 DOWNTO 0); -- The min difference between the actual and theoretical
signal abs_max_offset: UNSIGNED(15 DOWNTO 0); -- The max difference between the actual and theoretical
signal one_pps_cntr: UNSIGNED(15 DOWNTO 0); -- The number of one second pulses
signal reset: STD_LOGIC; -- The reset signal for the system
signal onePPS_32: STD_LOGIC; -- The number of PPS signals from the 32 MHz clock
signal prev_pps: STD_LOGIC := '1'; -- The previous PPS signal value
signal pps: STD_LOGIC := '1'; -- The current PPS signal value
signal sync_reg : STD_LOGIC_VECTOR(3 DOWNTO 0); -- The register used for synchronization
signal display: STD_LOGIC_VECTOR(15 DOWNTO 0); -- The set of values to display
signal diff: SIGNED(15 DOWNTO 0); -- The signed difference between the actual and theoretical
signal sign: std_logic; -- The sign bit for the signed difference
BEGIN

	-- The debouncer for the reset button
	btn0 : ENTITY debouncer  PORT MAP (
		clk => clk50Mhz,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(0),
		output => reset
	);

	-- The PPS generator that uses the 32 MHz clock
	pps_generator : ENTITY OnePPSgenerator PORT MAP (
		clk_32MHz => clk32Mhz,
		reset => reset,
		onePPS => onePPS_32
	);

	-- By default shut the leds off
	leds(7 DOWNTO 1) <= (OTHERS => '0');
	
	-- Process used to synchronize the clocks whose output is the current pps value
	PROCESS(clk50Mhz, reset)
	BEGIN
		IF ( reset = '1' ) THEN
			sync_reg <= (OTHERS => '0');
			pps <= '1';
		ELSIF( rising_edge(clk50Mhz) ) THEN
			if (sync_reg = "1111") THEN
				pps <= '1';
			elsif ( sync_reg = "0000" ) THEN
				pps <= '0';
			END IF;
			sync_reg <= sync_reg(2 DOWNTO 0) & onePPS_32;			
		END IF;
	END PROCESS;
	
	-- Process used to calculate all of the statistics
	calc_stats: process(clk50Mhz, reset)
	BEGIN
		-- Reset all of the values back to default
		IF ( reset = '1' ) THEN
			diff  <= (OTHERS => '0');
			offset <= (OTHERS => '0');
			abs_max_offset <= (OTHERS => '0');
			abs_min_offset <= (OTHERS => '1');
			sign <= '0';
		ELSIF(rising_edge(clk50Mhz)) THEN
			-- Calculate the differences as long as the pps durection is greater than one
			if (one_pps_duration > 0) THEN
				diff <= resize(SIGNED(x"2FAF080" - one_pps_duration), 16);
				sign <= diff(15);
				offset <= UNSIGNED(abs(resize(SIGNED(x"2FAF080" - one_pps_duration), 16)));
				if ( one_pps_cntr > 3 ) THEN
					IF offset < abs_min_offset THEN
							abs_min_offset <= offset;
					END IF;
					IF offset > abs_max_offset THEN
							abs_max_offset <= offset;						
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS calc_stats;

	-- Process used to determine the number of clocks
	process(clk50Mhz, reset)
	BEGIN
		IF ( reset = '1' ) THEN
			clk_cntr <= (OTHERS => '0');
			one_pps_cntr <= (OTHERS => '0');
			one_pps_duration <= (OTHERS => '0');
			prev_pps <= '1';
		ELSIF(rising_edge(clk50Mhz)) THEN
			-- Clock pulse has changed, so reset the counter and save the duration
			IF (prev_pps /= pps and pps = '0') THEN
				one_pps_cntr <= one_pps_cntr + 1;
				clk_cntr <= (OTHERS => '0');
				if ( one_pps_cntr > 1 ) THEN
					one_pps_duration <= clk_cntr;
				END IF;
			ELSE
				clk_cntr <= clk_cntr + 1;
			END IF;
			prev_pps <= pps;
		END IF;
	END PROCESS;

	-- Instance used for the display of the characters
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk50Mhz,
				char0 => display(3 DOWNTO 0),
				char1 => display(7 DOWNTO 4),
				char2 => display(11 DOWNTO 8),
				char3 => display(15 DOWNTO 12),
				encoded_char => seg7,
				anodes => anodes
				);	
	
	display_out: PROCESS(clk50Mhz)
	BEGIN
		IF( rising_edge(clk50Mhz) ) THEN
		-- Select the appropriate bit pattern to display the digit
			CASE slider_switches IS
					WHEN "00000000" => display <= STD_LOGIC_VECTOR(one_pps_duration(15 DOWNTO 0));
					WHEN "00000001" => display <= "000000" & STD_LOGIC_VECTOR(one_pps_duration(25 DOWNTO 16));
					WHEN "00000010" => display <= STD_LOGIC_VECTOR(offset);
					WHEN "00000011" => display <= STD_LOGIC_VECTOR(offset);
					WHEN "00000100" => display <= STD_LOGIC_VECTOR(abs_min_offset);
					WHEN "00000101" => display <= STD_LOGIC_VECTOR(abs_max_offset);
					WHEN "00000110" => display <= STD_LOGIC_VECTOR(one_pps_cntr);
					WHEN OTHERS => display <= x"AAAA";
			END CASE;
		END IF;
	END PROCESS display_out;
	
	-- Set the led value based on the sign bit
	leds(0) <= sign when (slider_switches = "00000010") ELSE '0';
	
END Behavioral;