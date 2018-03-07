-------------------------------------------------------------------------------
-- Title       : debounce
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : debounce.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Nov 30 08:58:18 2017
-- Last update : Wed Mar  7 11:25:35 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Simple debouncer
-- source: https://eewiki.net/pages/viewpage.action?pageId=4980758
-- DebounceTime = (2^n + 2)/f
--  n = C_COUNTER_SIZE
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debounce is
    generic(
        C_COUNTER_SIZE  :  INTEGER := 21
        ); --counter size (21 bits gives 16.8ms with 125MHz clock)
    port(
        clk     : IN  std_logic;  --input clock
        rst     : IN  std_logic;  --reset input
        button  : IN  std_logic;  --input signal to be debounced
        result  : OUT std_logic := '0'
    ); --debounced signal
end debounce;

architecture logic OF debounce is
        signal flipflops   : std_logic_vector(1 downto 0); --input flip flops
        signal counter_set : std_logic;                    --sync reset to zero
        signal counter_out : std_logic_vector(C_COUNTER_SIZE downto 0) := (others => '0'); --counter output
    begin

        counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter

        process(clk)
        begin
            if rising_edge(clk) then
                if (rst = '1') then
                    flipflops <= (others => '0');
                    result <= '0';
                    counter_out <= (others => '0');
                else
                    flipflops(0) <= button;
                    flipflops(1) <= flipflops(0);
                    if(counter_set = '1') then                  --reset counter because input is changing
                            counter_out <= (others => '0');
                    elsif(counter_out(C_COUNTER_SIZE) = '0') then --stable input time is not yet met
                        counter_out <= counter_out + 1;
                    else                                        --stable input time is met
                        result <= flipflops(1);
                    end if;    
                end if;
            end if;
        end process;
end architecture logic;
