-------------------------------------------------------------------------------
-- Title       : Impulse generator
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : impulse_generator.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Nov 30 08:58:18 2017
-- Last update : Thu Nov 30 09:40:05 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Simple impulse generator
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity impulse_generator is
    generic(
        C_IMPULSE_DURATION  :  INTEGER := 21
    );
    port(
        clk      : IN  std_logic;
        enable   : IN  std_logic;
        impulse  : OUT std_logic
    );
end impulse_generator;

architecture logic OF impulse_generator is
        type state_type is (IDLE, IMP, DONE);   
        signal state : state_type := IDLE;


        signal out_int : std_logic := '0';
        signal waitforlow : std_logic := '0';
    begin
        --impulse <= out_int;
        impulse <= '1' when state = IMP else '0';
        process(clk)
            variable counter : integer range 0 to C_IMPULSE_DURATION := 0;
        begin
            if rising_edge(clk) then
                case (state) is
                    when IDLE =>
                        counter := 0;
                        --impulse <= '0';
                        if enable = '1' then
                            state <= IMP;
                        end if;
                    when IMP =>
                        counter := counter + 1;
                        --impulse <= '1';
                        if counter = C_IMPULSE_DURATION then
                            state <= DONE;
                        end if;
                    when DONE =>
                        --impulse <= '0';
                        if enable = '0' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
            --if rising_edge(clk) then
            --    if enable = '1' and waitforlow = '0' then
            --        if out_int = '0' then
            --            out_int <= '1';
            --            counter := 0;
            --        else
            --            counter := counter + 1;
            --            if counter = C_IMPULSE_DURATION then
            --                out_int <= '0';
            --            end if;
            --        end if;
            --    elsif enable = '0' then
            --        waitforlow <= '0';
            --        out_int <= '0';
            --    end if;
            --end if;
        end process;
end architecture logic;
