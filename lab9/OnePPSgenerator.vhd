library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library unisim;
use unisim.vcomponents.all;
use work.all;

-- Designer: Ramsey Hourani
-- Component to generate an accurate one pulse per second output using a 32 MHz clock
-- inouts: asynchronous reset and 32 MHz clock. Output: continuous periodic one PPS signal at 50% duty cycle
entity OnePPSgenerator is port (
	clk_32MHz	: in std_logic;		-- 32 MHz clock from external oscillator
	reset			: in std_logic;	-- asynchronous reset
	onePPS		: out std_logic);	-- one PPS output at 50% duty cycle
end OnePPSgenerator;

architecture arch of OnePPSgenerator is

signal cntr32MHz : unsigned(24 downto 0); -- internal counter that counts to (32,000,000 - 1)

begin

	-- create a onePPS 50% duty cycle pulse using the 32MHz clock
	process(clk_32MHz)
	begin
		if(rising_edge(clk_32MHz)) then
			if(reset = '1') then
				cntr32MHz <= (others => '0');
			elsif(cntr32MHz < (32000000-1)) then -- count on every rising edge of the 32 MHz clock till you get to (32,000,000 -1)
				cntr32MHz <= cntr32MHz + 1;
			else
				cntr32MHz <= (others => '0'); -- then reset counter
			end if;
		end if;
	end process;
	
	-- create one PPS signal at 50% duty cycle
	onePPS <= '1' when (unsigned(cntr32MHz) < 16000000) else '0';
	
end arch;