-------------------------------------------------------------------------------
-- Title       : Impulse generator
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : impulse_generator.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Nov 30 08:58:18 2017
-- Last update : Wed Mar  7 11:39:38 2018
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
        rst      : IN  std_logic;
        enable   : IN  std_logic;
        impulse  : OUT std_logic
    );
end impulse_generator;

architecture logic OF impulse_generator is
        type state_type is (IDLE, IMP, DONE);   
        signal state : state_type := IDLE;
    begin
        --impulse <= out_int;
        impulse <= '1' when state = IMP else '0';
        process(clk)
            variable counter : integer range 0 to C_IMPULSE_DURATION := 0;
        begin
            if rising_edge(clk) then
                if (rst = '1') then
                    state <= IDLE;
                    counter := 0;
                else
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
            end if;
        end process;
end architecture logic;
