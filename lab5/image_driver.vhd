library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entity used to create the RGB value for a given pixel
entity image_driver is PORT (
	clk : in STD_LOGIC; -- The pixel clock
	reset : IN STD_LOGIC; -- The reset line
   video_enable : IN STD_LOGIC; -- Whether or not the video is enabled
	h_coord : IN UNSIGNED(10 DOWNTO 0); -- Horizontal coordinate of the pixel
   v_coord : IN UNSIGNED(10 DOWNTO 0); -- Vertical coordinate of the pixel
	red_box_h : IN UNSIGNED(7 DOWNTO 0); -- Horizontal coordinate of the red box
	red_box_v : IN UNSIGNED (7 DOWNTO 0); -- Vertical coordinate of the red box
	red : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- Red value for the VGA
	green : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- Green value for the VGA
	blue : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)); -- Blue value for the VGA
end image_driver;

architecture Behavioral of image_driver is
signal h_box: UNSIGNED(10 DOWNTO 0); -- The horizontal box calculated based on the pixel location
signal v_box: UNSIGNED(10 DOWNTO 0); -- The horizontal box calculated based on the pixel location
signal red_pixel_start_h: UNSIGNED(15 DOWNTO 0); -- The horizontal start pixel for the red box
signal red_pixel_start_v: UNSIGNED(15 DOWNTO 0); -- The vertical start pixel for the red box
begin

	-- Calculate the horizontal and vertical box the pixel is located in
	h_box <= (h_coord mod x"40")/x"20";
	v_box <= (v_coord mod x"40")/x"20";
	
	-- Calculate the red start locations
	red_pixel_start_h <= (red_box_h * x"20");
	red_pixel_start_v <= (red_box_v * x"20");

	display_colors: PROCESS(clk, reset)
	BEGIN
		if ( reset = '1' ) THEN
			-- In reset, just output black for everything since we want to keep video sync'd
			red <= (OTHERS => '0');
			green <= (OTHERS => '0');
			blue <= (OTHERS => '0');	
		elsif RISING_EDGE(clk) THEN
			IF(video_enable = '1') THEN
				-- If the pixel is in the red box, paint it red
				if ((h_coord >= red_pixel_start_h and h_coord < red_pixel_start_h + x"20") 
							and (v_coord >= red_pixel_start_v and v_coord < red_pixel_start_v + x"20")) THEN
					red <= (OTHERS => '1');
					green  <= (OTHERS => '0');
					blue <= (OTHERS => '0');
				-- Otherwise, check if it should be green
				ELSIF ((v_box = x"0" and h_box = x"0") or (v_box = x"1" and h_box = x"1")) THEN
					red <= (OTHERS => '0');
					green  <= (OTHERS => '1');
					blue <= (OTHERS => '0');			
				ELSE
					-- Finally, just paint it blue
					red <= (OTHERS => '0');
					green  <= (OTHERS => '0');
					blue <= (OTHERS => '1');
				END IF;
			ELSE
				-- Video not enabled, the RGB should be black
				red <= (OTHERS => '0');
				green <= (OTHERS => '0');
				blue <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS display_colors;

end Behavioral;

