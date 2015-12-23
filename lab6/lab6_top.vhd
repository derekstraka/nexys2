LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;

ENTITY lab6_top IS PORT (
	clk50MHz: IN STD_LOGIC; -- The main 50 MHz clock
	push_buttons : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- The buttons on the development board
	seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- The select lines for the display
	RAM_Addr : OUT STD_LOGIC_VECTOR(23 DOWNTO 1); -- The RAM Address lines
	RAM_OEb : OUT STD_LOGIC; -- The RAM output enable
	RAM_WE : OUT STD_LOGIC; -- The RAM write enable
	RAM_Adv : OUT STD_LOGIC; -- The RAM address valid
	RAM_Clk : OUT STD_LOGIC; -- The RAM clock
	RAM_Cre : OUT STD_LOGIC; --The RAM control register enable
	RAM_CE : OUT STD_LOGIC; -- The RAM chip enable
	RAM_UB : OUT STD_LOGIC; -- The RAM upper byte enable
	RAM_LB : OUT STD_LOGIC; -- The RAM lower byte enable
	RAM_Data : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)); -- The RAM data lines 
END lab6_top;

ARCHITECTURE Behavioral OF lab6_top IS

-- Set of states for the FSM
TYPE STATE_TYPE IS (S_INIT, S_WRITE_START, S_WRITE_WAIT, S_WRITE_COMPLETE, S_IDLE, S_READ_START, S_READ_WAIT, S_READ_COMPLETE);

-- Current state of the system
signal state : STATE_TYPE;

-- Signals for the debounced buttons
signal debounced_buttons : STD_LOGIC_VECTOR(1 DOWNTO 0);

-- Internal reset signal
signal reset : STD_LOGIC;

-- Signal for the last ram value that goes to the 7 segment display
signal last_ram_read : STD_LOGIC_VECTOR(15 DOWNTO 0);

-- Intermediate signal for the clock
signal clk : STD_LOGIC;

-- Intermediate signal for the RAM WE value
signal RAM_WEb_tmp : STD_LOGIC;

-- Signal for the enable signal delay
signal enable_cntr: UNSIGNED(2 downto 0);

-- Signal for the memory address
signal addr: UNSIGNED(8 downto 0);

-- Signal for the timer reset
signal timer_reset: STD_LOGIC;

-- Signal for the timer expire
signal timer_expire: STD_LOGIC;

-- The last button value for the read button
signal last_button: STD_LOGIC;

BEGIN

	-- Map the clock to the input clock
	clk <= clk50MHz;

	-- Set the reset to the debounced button 0
   reset <= debounced_buttons(0);

	-- Setup the button zero debouncer
	button_0 : ENTITY debouncer  PORT MAP (
		clk => clk,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(0),
		output => debounced_buttons(0)
	);
	
	-- Setup the button one debouncer
	button_1 : ENTITY debouncer  PORT MAP (
		clk => clk,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(1),
		output => debounced_buttons(1)
	);

	-- Instantiate the 7 segment display
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk,
				char0 => last_ram_read(3 DOWNTO 0),
				char1 => last_ram_read(7 DOWNTO 4),
				char2 => last_ram_read(11 DOWNTO 8),
				char3 => last_ram_read(15 DOWNTO 12),
				encoded_char => seg7,
				anodes => anodes
				);
				
	-- Instantiate the 4 Hz pulse generator (50000000/4) => 0xBEBC20
	one_khz_pulse_gen : ENTITY pulse_generator PORT MAP(
		clk => clk,
		reset => timer_reset,
		pulse_out => timer_expire,
		max_cnt => x"00BEBC20");

	-- Set all of the unused RAM signals to zero
	RAM_Adv <= '0';
	RAM_Cre <= '0';
	RAM_UB <= '0';
	RAM_LB <= '0';
	RAM_CE <= '0';
	RAM_Clk <= '0';

	-- Set the RAM address to the expected value
	RAM_Addr(23 downto 9) <= (others => '0');
	RAM_Addr(8 downto 1) <= std_logic_vector(addr(7 DOWNTO 0));
	
	process_state: PROCESS(clk, reset)
	BEGIN
		-- Reset everything back to the original state
		IF (reset = '1') THEN
			state <= S_INIT;
			addr <= (others => '0');
			enable_cntr <= (others => '0');
			RAM_WEb_tmp <= '0';
			last_ram_read <= (others => '0');
			timer_reset <= '1';
			
		ELSIF(rising_edge(clk)) THEN
			-- Set the last value to the debounced button output 
			last_button <= debounced_buttons(1);

			-- Determine the next state
			CASE (state) IS
			
				-- Fresh out of reset, so start writing things
				WHEN S_INIT =>
					state <= S_WRITE_START;
					timer_reset <= '1';
				
				-- Set up the data value and set RAM OE and move into the wait state
				WHEN S_WRITE_START =>
					RAM_Data <= x"AD" & STD_LOGIC_VECTOR(addr(7 DOWNTO 0));
					RAM_OEb <= '1';
					state <= S_WRITE_WAIT;
				
				-- Delay the WE signal and send it to write complete
				WHEN S_WRITE_WAIT =>
					enable_cntr <= enable_cntr + 1;
					-- Pulse the WE signal and move into write complete
					if (enable_cntr > x"1") THEN
						state <= S_WRITE_COMPLETE;
						RAM_WEb_tmp <= '1';
						enable_cntr <= (others => '0');
					ELSE
						state <= S_WRITE_WAIT;
						RAM_WEb_tmp <= '0';
					END IF;

				-- State to indicate a write ic complete
				WHEN S_WRITE_COMPLETE =>
					-- Increment the address and reset WE
					addr <= addr + 1;
					RAM_WEb_tmp <= '0';
					
					-- If we are done writing, move into the idle state; otherwise, write again
					if (addr > 254) THEN
						state <= S_IDLE;
					ELSE
						state <= S_WRITE_START;
					END IF;

				-- Hang out until we get a button press to read
				WHEN S_IDLE =>
					RAM_OEb <= '0';
					RAM_WEb_tmp <= '1';
					-- Ready to read values, so reset the current addr value and move into read start
					if debounced_buttons(1) = '1' and last_button ='0' THEN
						addr <= (OTHERS => '0');
						state <= S_READ_START;
					END IF;
				
				-- Set the data value to input and then wait for the timer to expire
				WHEN S_READ_START =>
					RAM_Data <= (OTHERS => 'Z');
					state <= S_READ_WAIT;
				
				WHEN S_READ_WAIT =>
					-- Activate the timer and wait for the expire pulse
					timer_reset <= '0';
					if (timer_expire = '1') THEN
						state <= S_READ_COMPLETE;
						timer_reset <= '1';
					ELSE
						state <= S_READ_WAIT;
					END IF;
					
				WHEN S_READ_COMPLETE =>
					-- Increment the address by one and save the value read to display
					addr <= addr + 1;
					last_ram_read <= RAM_Data;
					if (addr > 254) THEN
						state <= S_IDLE;
					ELSE
						state <= S_READ_START;
					END IF;
			END CASE;
		END IF;
	END PROCESS;

	-- Process to update the RAM WEb signal
   ram_web: PROCESS(reset, clk)
	BEGIN
		IF (reset = '1') THEN
			RAM_WE <= '0';
		-- Delay the RAM WEb value by 1/2 a clock		
		ELSIF(FALLING_EDGE(clk)) THEN
			RAM_WE <= RAM_WEb_tmp;
		END IF;
	END PROCESS ram_web;

END Behavioral;