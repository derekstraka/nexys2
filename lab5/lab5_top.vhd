LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;

ENTITY lab5_top IS PORT (
	clk50MHz: IN STD_LOGIC; -- The main 50 MHz clock
	push_buttons : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- The buttons on the development board
	slider_switch : IN STD_LOGIC; -- Slider switch zero which is used for reset
	seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- The select lines for the display
	leds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- The seven leds on the board
	red : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- The red values for the VGA video
	green : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- The green values for the VGA video
	blue : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- The blue values for the VGA video
	h_sync : OUT STD_LOGIC; -- The horizontal sync signal for the VGA video
	v_sync : OUT  STD_LOGIC -- The vertical sync signal for the VGA video
	); 
END lab5_top;

ARCHITECTURE Behavioral OF lab5_top IS

-- Signals to hold the previous button values
signal last_buttons: STD_LOGIC_VECTOR(3 DOWNTO 0);

-- Signals for the debounced buttons
signal debounced_buttons : STD_LOGIC_VECTOR(3 DOWNTO 0);

-- Signal to determine whether or not video is displayed
signal video_enable : STD_LOGIC;

-- Signal for the x and y coordinates for the current pixel
signal v_coord : UNSIGNED(10 DOWNTO 0);
signal h_coord : UNSIGNED(10 DOWNTO 0);

-- Signal for the 25 MHz clock
signal clk25MHz : STD_LOGIC;

-- Signal to hold the coordinates of the red box in terms of row and column of boxes
signal red_box_h : UNSIGNED(7 DOWNTO 0);
signal red_box_v : UNSIGNED(7 DOWNTO 0);

-- Internal reset signal
signal reset : STD_LOGIC;

-- Signal that pulses each time a frame is displayed
signal frame_sync : STD_LOGIC;

-- Counter for the number of frames displayed
signal frame_counter : UNSIGNED(7 DOWNTO 0);
BEGIN
	
	-- Map the reset button to the slider
	reset <= slider_switch;

	-- Set the led values to be the frame counter
	leds <= STD_LOGIC_VECTOR(frame_counter);

	-- Setup the button zero debouncer
	button_0 : ENTITY debouncer  PORT MAP (
		clk => clk50MHz,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(0),
		output => debounced_buttons(0)
	);
	
	-- Setup the button one debouncer
	button_1 : ENTITY debouncer  PORT MAP (
		clk => clk50MHz,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(1),
		output => debounced_buttons(1)
	);

	-- Setup the button two debouncer
	button_2 : ENTITY debouncer  PORT MAP (
		clk => clk50MHz,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(2),
		output => debounced_buttons(2)
	);

	-- Setup the button three debouncer
	button_3 : ENTITY debouncer  PORT MAP (
		clk => clk50MHz,
		reset => '0',
		max_cnt => x"2625A0",
		input => push_buttons(3),
		output => debounced_buttons(3)
	);

	-- Set up the instance of the 7 segment display with the
	-- coordinates of the red box
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk50MHz,
				char0 => STD_LOGIC_VECTOR(red_box_v(3 DOWNTO 0)),
				char1 => STD_LOGIC_VECTOR(red_box_v(7 DOWNTO 4)),
				char2 => STD_LOGIC_VECTOR(red_box_h(3 DOWNTO 0)),
				char3 => STD_LOGIC_VECTOR(red_box_h(7 DOWNTO 4)),
				encoded_char => seg7,
				anodes => anodes
				);

	-- Setup the instance of the VGA driver
	vga : ENTITY vga_driver PORT MAP (
				pclk => clk25MHz,
				frame_sync => frame_sync,
				h_sync => h_sync,
				v_sync => v_sync,
				video_enable => video_enable,
				v_coord => v_coord,
				h_coord => h_coord
	);

	-- Setup the instance of the image generator
	image : ENTITY image_driver PORT MAP (
				video_enable => video_enable,
				clk => clk50MHz,				
				reset => reset,
				v_coord => v_coord,
				h_coord => h_coord,
				red_box_h => red_box_h,
				red_box_v => red_box_v,
				red => red,
				green => green,
				blue => blue
				);

	-- Process used to handle the button presses
	handle_buttons: PROCESS(clk50MHz, reset)
	BEGIN
		-- Reset the position of the box
		IF (reset = '1') THEN
			red_box_h <= (OTHERS => '0');
			red_box_v <= (OTHERS => '0');
		ELSIF(RISING_EDGE(clk50MHz)) THEN
			-- Indicated a button depress event
			IF (last_buttons(0) = '0' and debounced_buttons(0) = '1') THEN
				-- Perform the screen wrap logic if needed otherwise just decrement
			   if red_box_v = x"00" THEN
					red_box_v <= x"0E";
				ELSE
					red_box_v <= red_box_v - 1;
				END IF;
			END IF;
			IF (last_buttons(1) = '0' and debounced_buttons(1) = '1') THEN
				-- Perform the screen wrap logic if needed otherwise just increment
			   if red_box_v = x"0E" THEN
					red_box_v <= x"00";
				ELSE
					red_box_v <= red_box_v + 1;
				END IF;
			END IF;
			IF (last_buttons(2) = '0' and debounced_buttons(2) = '1') THEN
				-- Perform the screen wrap logic if needed otherwise just increment
			   IF red_box_h = x"13" THEN
					red_box_h <= x"00";
				ELSE
					red_box_h <= red_box_h + 1;
				END IF;
			END IF;
			IF (last_buttons(3) = '0' and debounced_buttons(3) = '1') THEN
				-- Perform the screen wrap logic if needed otherwise just decrement
				IF red_box_h = x"00" THEN
					red_box_h <= x"13";
				ELSE
					red_box_h <= red_box_h - 1;
				END IF;
			END IF;
			last_buttons <= debounced_buttons;
		END IF;
	END PROCESS handle_buttons;
	
	-- Process used to handle the frame counter
	frame_cnt: PROCESS(clk50MHz, reset)
	BEGIN
		-- Reset the frame counter on reset
		if reset = '1' THEN
			frame_counter <= (OTHERS => '0');
		elsif(RISING_EDGE(clk50MHz)) THEN
			-- Check to see if the frame sync from the VGA driver is high
			if(frame_sync = '1') THEN
				-- Increment the frame counter when the frame sync is high
				frame_counter <= frame_counter + 1;
			END IF;
		END IF;
	END PROCESS frame_cnt;
	
	-- Process used to generate a 25 MHz clock from the 50 MHz clock
	gen_25MHz_clk: PROCESS(clk50MHz)
	BEGIN
		-- Cycle half as fast as the input clock
		if RISING_EDGE(clk50MHz) THEN
			clk25MHz <= not clk25MHz;
		END IF;
	END PROCESS gen_25MHz_clk;
	
END Behavioral;