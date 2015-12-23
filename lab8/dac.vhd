--VHDL implementation of XAPP154 Verilog, translated by JWH

--//
--// Design: 	DAC
--//
--// Fonction:	Delta-Sigma Digital to Analog Converter
--//		Reference Design XAPP154 & XAPP155
--//
--// Device: 	VIRTEX Families
--//
--// Created by: John Logue
--//
--//   Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
--//                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY 
--//                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--//                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--//
--//  Copyright (c) 2000 Xilinx, Inc.  All rights reserved.
--//------------------------------------------------------------------------

   --`timescale  100 ps / 10 ps
   --`define MSBI  7    // Most Significant Bit of DAC input
   --
   --// This is a Delta-Sigma Digital to Analog Converter
   --
   --module dac(DACout, DACin, Clk, Reset);
   --
   --output DACout;  // This is the average output that feeds low pass filter
   --reg    DACout;  // for optimum performance, ensure that this ff is in IOB
   --input [`MSBI:0] DACin; // DAC input (excess 2**MSBI)
   --input Clk;
   --input Reset;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.all;

entity dac is
   generic (
      MSBI : integer := 9
   );
   port (
      clk : in std_logic;
      rst : in std_logic;
      DACin : in std_logic_vector(MSBI downto 0);
      DACout : out std_logic
   );
end entity;

architecture rtl of dac is

   --reg [`MSBI+2:0] DeltaAdder;  // output of Delta adder
   --reg [`MSBI+2:0] SigmaAdder;  // output of Sigma adder
   --reg [`MSBI+2:0] SigmaLatch;  // Latches output of Sigma adder
   --reg [`MSBI+2:0] DeltaB;      // B input of Delta adder
   signal deltaAdder, sigmaAdder, deltaB, sigmaLatch : unsigned(MSBI+2 downto 0);

begin

   --always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
   --always @(DACin or DeltaB) DeltaAdder = DACin + DeltaB;
   --always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;

   deltaB(MSBI+2) <= SigmaLatch(MSBI+2);
   deltaB(MSBI+1) <= SigmaLatch(MSBI+2);
   deltaB(MSBI downto 0) <= (others => '0');
   DeltaAdder <= unsigned(DACin) + deltaB;
   sigmaAdder <= deltaAdder + sigmaLatch;

   --always @(posedge Clk or posedge Reset)
   --begin
   --  if(Reset)
   --  begin
   --    SigmaLatch <= #1 1'b1 << (`MSBI+1);
   --    DACout     <= #1 1'b0;
   --  end
   --  else
   --  begin
   --    SigmaLatch <= #1 SigmaAdder;
   --    DACout     <= #1 SigmaLatch[`MSBI+2];
   --  end
   --end
   
   dffs : process(clk, rst)
   begin
      if rst = '1' then
         sigmaLatch(MSBI + 2) <= '0';
         sigmaLatch(MSBI + 1) <= '1';
         sigmaLatch(MSBI downto 0) <= (others => '0');
         DACout <= '0';
      elsif rising_edge(clk) then
         sigmaLatch <= sigmaAdder;
         DACout <= sigmaLatch(MSBI+2);
      end if;
   end process;

end architecture rtl;