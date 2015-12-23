LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pulse_generator IS port(
	clk : IN STD_LOGIC; -- Input clock into the pulse generator
	reset : IN STD_LOGIC; -- Asynchronous reset signal
	max_cnt : IN UNSIGNED(31 downto 0); -- The maximum value the counter should take
	pulse_out : OUT STD_LOGIC); -- The output signal for the pulse
END pulse_generator;

ARCHITECTURE Behavioral OF pulse_generator IS
signal cntr : UNSIGNED(31 downto 0); -- Internal clock counter
signal clear : STD_LOGIC; -- Internal clear signal
BEGIN

	pulse_gen: PROCESS(clk, reset)
		BEGIN
			-- Reset the counter when reset goes active
			IF(reset = '1') THEN
				cntr <= (OTHERS => '0');
			ELSIF(rising_edge(clk)) THEN
				IF(clear = '1') THEN -- Clear the internal counter
					cntr <= (OTHERS => '0');
				ELSE
					cntr <= cntr + 1; -- Increment the counter
				END IF;
			END IF;
		END PROCESS pulse_gen;

	clear <= '1' WHEN (cntr = max_cnt) ELSE '0'; -- Signal the clear the counter when max is reached
	pulse_out <= clear; -- Pulse when the max value is reached and low otherwise

END Behavioral;

