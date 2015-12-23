LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;
ENTITY toplevel IS PORT (
	clk50MHz: IN STD_LOGIC; -- The main 50 MHz clock
	push_buttons : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- The buttons on the development board
	slider_switches : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- The logic values of the slider switches on the board
	seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- The select lines for the display
	leds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- The seven leds on the board
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
END toplevel;

ARCHITECTURE Behavioral OF toplevel IS
-- Intermediate signal for the reset signal
signal reset : STD_LOGIC;

-- Counter to determine which addresses have been written
signal cntr: UNSIGNED(10 downto 0);

-- Intermediate write enable signal
signal RAM_WEb_int: STD_LOGIC;

-- Clock pulse
signal clk: STD_LOGIC;

-- Signal to determine if we are going to write to RAM
signal write_to_ram: STD_LOGIC;

-- Signals that are sent to the 7 segment display
signal char0 : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal char1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal char2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal char3 : STD_LOGIC_VECTOR(3 DOWNTO 0);

-- Signal to determine if the switches should be displayed
signal switch_display_sel : STD_LOGIC;

-- Signal to determine if a new value should be read from RAM
signal read_ram_enable: STD_LOGIC;

-- The last address read from RAM
signal last_ram_read : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal temp : STD_LOGIC;
BEGIN
	-- Set the LED values to mimic the slider switches
	leds <= slider_switches;
	
	-- Setup the clock and reset mapping
	clk <= clk50MHz;
	reset <= push_buttons(0);
	
	-- Setup the enable for RAM read and display select
	switch_display_sel <= push_buttons(2);
	read_ram_enable <= push_buttons(1);
	
	-- Set the write to RAM signal high until we hit our max
	write_to_ram <= '1' WHEN (cntr < x"400" ) ELSE '0';
	
	-- Set the output enable to 1 when we are writing to ram
	RAM_OEb <= '1' WHEN (cntr < x"400" ) ELSE '0';
	
	-- Set all of the unused RAM signals to zero
	RAM_Adv <= '0';
	RAM_Cre <= '0';
	RAM_UB <= '0';
	RAM_LB <= '0';
	RAM_CE <= '0';
	RAM_Clk <= '0';
	
	-- When we are writing to RAM, add the AD prefix to the memory address
	-- Otherwise, we need to read from the value so set it to high impedence
	RAM_Data <= x"AD" & STD_LOGIC_VECTOR(cntr(9 DOWNTO 2)) WHEN write_to_ram = '1' ELSE (OTHERS => 'Z');
	
	--RAM_WEb_int <= write_to_ram NAND '0' when (cntr(1 downto 0) <= 2) else '1';
	temp <= '1' when (cntr(1 downto 0) <= 2) else '0';
	RAM_WEb_int <= write_to_ram NAND temp;
	
	-- Set the unused RAM address bits to zero
	RAM_Addr(23 downto 9) <= (others => '0');
	-- Set the address to the counter value if we are writing to RAM; otherwise, set it to the switch values
	RAM_Addr(8 downto 1) <= std_logic_vector(cntr(9 DOWNTO 2)) WHEN (write_to_ram = '1') ELSE slider_switches; 
	
	-- Instantiate the display entity
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk50MHz,
				char0 => char0,
				char1 => char1,
				char2 => char2,
				char3 => char3,
				reset => '0',
				encoded_char => seg7,
				anodes => anodes
				);

	-- Process used to calculate the address to write
	addr_cntr: PROCESS(reset, clk)
	BEGIN
		-- Reset the value to zero
		IF (reset = '1') THEN
			cntr <= (others => '0');
		ELSIF(RISING_EDGE(clk)) THEN
			-- Count up by one until we hit 1025
			IF(cntr < x"401") THEN
				cntr <= cntr + 1;
			END IF;
		END IF;
	END PROCESS addr_cntr;
	
	-- Process to update the RAM WEb signal
   ram_web: PROCESS(reset, clk)
	BEGIN
		IF (reset = '1') THEN
			RAM_WE <= '1';
		-- Delay the RAM WEb value by 1/2 a clock		
		ELSIF(FALLING_EDGE(clk)) THEN
			RAM_WE <= RAM_WEb_int;
		END IF;
	END PROCESS ram_web;

	-- Process to update the last read RAM value
	read_ram: PROCESS(reset, clk)
	BEGIN
		-- On a reset, set the value to zero
		IF (reset = '1') THEN
			last_ram_read <= (OTHERS => '0');
		ELSIF(rising_edge(clk)) THEN
			-- If the enable line is high, set the last read
			-- value to what we have received from the RAM
			IF(read_ram_enable = '1') THEN
					last_ram_read <= RAM_Data;
			END IF;
		END IF;
	END PROCESS read_ram;
	
	-- Process used to determine what values to display
	display: PROCESS(switch_display_sel, last_ram_read, slider_switches)
	BEGIN
		-- If the switch select line is high, we want to display the
		-- address on the slider switches without the 0xAD
		IF (switch_display_sel = '1') THEN
			char0 <= slider_switches(3 DOWNTO 0);
			char1 <= slider_switches(7 DOWNTO 4);
			char2 <= (OTHERS => '0');
			char3 <= (OTHERS => '0');
		ELSE
			-- When the switch select line is low, we want to display
			-- the last value read from RAM
			char0 <= last_ram_read(3 DOWNTO 0);
			char1 <= last_ram_read(7 DOWNTO 4);
			char2 <= last_ram_read(11 DOWNTO 8);
			char3 <= last_ram_read(15 DOWNTO 12);
		END IF;
	END PROCESS display;
	
END Behavioral;