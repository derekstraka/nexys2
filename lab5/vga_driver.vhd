library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY vga_driver IS port(
	pclk : IN STD_LOGIC; -- Pixel clock for the vga signal
	frame_sync : OUT STD_LOGIC; -- Frame sync pulse that goes high once per frame
	h_sync : OUT STD_LOGIC; -- Horizontal sync pulse
	v_sync : OUT STD_LOGIC; -- Vertical sync pulse
	video_enable : OUT STD_LOGIC; -- Whether or not 
	h_coord : OUT UNSIGNED(10 DOWNTO 0); -- The horizontal coordinate of the displayed pixel
	v_coord : OUT UNSIGNED(10 DOWNTO 0) -- The vertical coordinate of the displayed pixel
	);
END vga_driver;

architecture Behavioral of vga_driver is
SIGNAL horizontal_counter: UNSIGNED(10 DOWNTO 0) := "00000000000";
SIGNAL vertical_counter: UNSIGNED(10 DOWNTO 0) := "00000000000";
BEGIN

	-- Enable valid video only when the counter is less than the valid resolution
	video_enable <= '1' when (horizontal_counter < "01010000000" and vertical_counter < "00111100000") else '0';

	-- Send the hsync pulse between 656 and 752
	h_sync <= '0' when ("1010010000" <= horizontal_counter and horizontal_counter < "1011110000") else '1';
	
	-- Send the vsync pulse between 490 and 492
	v_sync <= '0' when ("0111101010" <= vertical_counter and vertical_counter < "0111101100") else '1';
	
	-- Set the coordinates of the pixel to be the counter values
	h_coord <= horizontal_counter;
	v_coord <= vertical_counter;

	-- Send the frame sync and the start of frame
	frame_sync <= '1' when (horizontal_counter = "00000000000" and vertical_counter = "00000000000") else '0';

	-- Process to perform the counter logic
	counter_logic: PROCESS(pclk)
	BEGIN
		IF( RISING_EDGE(pclk)) THEN
			-- Reset the horizontal counter after 800 
			IF (horizontal_counter < "1100011111" ) THEN
				horizontal_counter <= horizontal_counter + 1;
			ELSE
				horizontal_counter <= (OTHERS => '0');
				-- Reset the horizontal counter after 524
				IF (vertical_counter < "01000001101") THEN
					vertical_counter <= vertical_counter + 1;
				ELSE
					vertical_counter <= (OTHERS => '0');
				END IF;
			END IF;
		END IF;
	END PROCESS counter_logic;

end Behavioral;

