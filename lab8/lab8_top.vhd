LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.all;

ENTITY lab8_top IS PORT (
	clk50MHz: IN STD_LOGIC; -- The main 50 MHz clock
	slider_switches : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
	seg7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- The output routed to the seven segment display
	anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- The select lines for the display
	dac_out : OUT STD_LOGIC);
END lab8_top;


ARCHITECTURE Behavioral OF lab8_top IS

-- Declaration for the clock manager
COMPONENT DCM50to100MHz
PORT(
	CLKIN_IN : IN std_logic;          
	CLKFX_OUT : OUT std_logic
	);
END COMPONENT;

-- Declaration for the LUT for the sine values
COMPONENT Sine_Lut
  PORT (
    clk : IN STD_LOGIC;
    phase_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    sine : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
  );
END COMPONENT;

signal clk100MHz: STD_LOGIC;
signal output_freq : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal sine_out : std_logic_vector(9 DOWNTO 0);
signal inv_sine_out : std_logic_vector(9 DOWNTO 0);
signal sine_out_shifted : std_logic_vector(9 DOWNTO 0);
signal phase : std_logic_vector(3 DOWNTO 0);
signal phase_cnt : UNSIGNED(15 DOWNTO 0);
signal neg_vol: INTEGER;
BEGIN

	-- Create the instance for the 100 MHz clock
	Inst_DCM50to100MHz: DCM50to100MHz PORT MAP(
		CLKIN_IN => clk50MHz,
		CLKFX_OUT => clk100MHz
	);

	-- Create the instance for the sine lookup table
	sine : Sine_Lut
	  PORT MAP (
		 clk => clk100MHz,
		 phase_in => phase,
		 sine => sine_out
	  );


	-- Create the instance for the phase accumulator
	phase_accum : ENTITY phase_accumulator PORT MAP(
		clk => clk100MHz,
		reset => '0',
		max_cnt => phase_cnt,
		phase_out => phase);


	-- Create the instance for the 7 segment display
	seg7_display : ENTITY seg7_driver PORT MAP (
				clk => clk50MHz,
				char0 => output_freq(3 DOWNTO 0),
				char1 => output_freq(7 DOWNTO 4),
				char2 => output_freq(11 DOWNTO 8),
				char3 => output_freq(15 DOWNTO 12),
				encoded_char => seg7,
				anodes => anodes
				);

	-- Create the instance fo rhte DAC
	dac_impl : ENTITY dac PORT MAP (
	   clk => clk100MHz,
      rst => '0',
      DACin => sine_out_shifted,
      DACout => dac_out
		);

	-- Implement the volume conversion using switches 3-5
	neg_vol <= to_integer(UNSIGNED(NOT slider_switches(5 DOWNTO 3)));
	inv_sine_out <= NOT sine_out(9) & sine_out(8 DOWNTO 0);
	
	-- Set the value to nothing when no frequency is selected otherwise use the shifted value
	sine_out_shifted <= (OTHERS => '0') WHEN (slider_switches(2 DOWNTO 0) = "000") ELSE STD_LOGIC_VECTOR(UNSIGNED(inv_sine_out) srl neg_vol) ;

	display_out: PROCESS(slider_switches)
	BEGIN
		-- Select the appropriate bit pattern to display the digit
		CASE slider_switches(2 DOWNTO 0) IS
				WHEN "001" => output_freq <= x"0500";
				WHEN "010" => output_freq <= x"1000";
				WHEN "011" => output_freq <= x"1500";
				WHEN "100" => output_freq <= x"2000";
				WHEN "101" => output_freq <= x"2500";
				WHEN "110" => output_freq <= x"3000";
				WHEN "111" => output_freq <= x"3500";
				WHEN OTHERS => output_freq <= x"0000";
		END CASE;
	END PROCESS display_out;
	
	phase_cnt_set: PROCESS(slider_switches)
	BEGIN
		-- Set the correct counter value based on the switches
		CASE slider_switches(2 DOWNTO 0) IS
				WHEN "001" => phase_cnt <= x"30D3";
				WHEN "010" => phase_cnt <= x"1869";
				WHEN "011" => phase_cnt <= x"1046";
				WHEN "100" => phase_cnt <= x"0C34";
				WHEN "101" => phase_cnt <= x"09C4";
				WHEN "110" => phase_cnt <= x"0823";
				WHEN "111" => phase_cnt <= x"06F9";
				WHEN OTHERS => phase_cnt <= x"0000";
		END CASE;
	END PROCESS phase_cnt_set;
	
END Behavioral;