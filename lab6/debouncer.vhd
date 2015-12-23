LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY debouncer IS -- Entity used to debounce an I/O signal
    PORT ( clk : IN  STD_LOGIC; -- The clock associated with the debouncer
           reset : IN  STD_LOGIC; -- The reset line for the debouncer
			  max_cnt : IN UNSIGNED (23 DOWNTO 0); -- The number of clock cycles used for the debouncer
           input : IN  STD_LOGIC; -- The I/O to be debounced
           output : OUT  STD_LOGIC -- The debounced I/O
			  );
END debouncer;

ARCHITECTURE Behavioral OF debouncer IS
SIGNAL count : UNSIGNED(23 DOWNTO 0) := (OTHERS => '0'); -- Internal clock counter
SIGNAL last : STD_LOGIC := '0'; -- The last signal value of the button

BEGIN
	debounce_timer : PROCESS(clk, reset, input)
	BEGIN
		-- In reset, pass the input value directly to the output
		IF reset = '1' THEN
				output <= input;
				last <= input;
				count <= (OTHERS => '0');
		ELSIF RISING_EDGE(clk) THEN
			-- If the input value has not changed and the count is greater than the
			-- maximum number of clocks, assign the output; otherwise, increment the counter
			IF input = last THEN
				IF count > max_cnt then
					output <= input;
				ELSE
					count <= count + 1;
				END IF;
			ELSE
				-- Value has changed so set the last and reset the counter
				last <= input;
				count <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS debounce_timer;
END Behavioral;

