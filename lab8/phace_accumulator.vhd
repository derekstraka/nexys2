LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY phase_accumulator IS port(
	clk : IN STD_LOGIC;
	reset : IN STD_LOGIC;
	max_cnt : IN UNSIGNED(15 downto 0);
	phase_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
END phase_accumulator;

ARCHITECTURE Behavioral OF phase_accumulator IS
signal cntr : UNSIGNED(15 downto 0); -- Internal clock counter
signal clear : STD_LOGIC; -- Internal clear signal
signal phase_cnt : UNSIGNED(3 DOWNTO 0);
BEGIN

	phase_accum: PROCESS(clk, reset)
		BEGIN
			-- Reset the counter when reset goes active
			IF(reset = '1') THEN
				cntr <= (OTHERS => '0');
				phase_cnt <= (OTHERS => '0');
			ELSIF(rising_edge(clk)) THEN
				IF(clear = '1') THEN -- Clear the internal counter
					cntr <= (OTHERS => '0');
					phase_cnt <= phase_cnt + 1;
				ELSE
					cntr <= cntr + 1; -- Increment the counter
				END IF;
			END IF;
		END PROCESS phase_accum;

	clear <= '1' WHEN (cntr >= max_cnt) ELSE '0'; -- Signal the clear the counter when max is reached
	phase_out <= std_logic_vector(phase_cnt);
	
END Behavioral;