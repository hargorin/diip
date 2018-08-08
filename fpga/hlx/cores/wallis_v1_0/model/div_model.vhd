-------------------------------------------------------------------------------
-- Title       : Wallis filter model
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : div_model.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Jul 18 15:24:07 2018
-- Last update : Wed Aug  8 12:17:30 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: Takes inputs and generates random outputs
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity div_model is
    generic (
        DELAYTIME : natural := 5
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;
 
        -- input 1 stream
        ------------------------------------------------------------------------
        i1_axis_tready           : out std_logic;
        i1_axis_tvalid           : in std_logic;
        i1_axis_tdata            : in std_logic_vector(23 downto 0);
 
        -- input 2 stream
        ------------------------------------------------------------------------
        i2_axis_tready           : out std_logic;
        i2_axis_tvalid           : in std_logic;
        i2_axis_tdata            : in std_logic_vector(15 downto 0);
       
        -- output stream
        ------------------------------------------------------------------------
        o_axis_tready           : in std_logic;
        o_axis_tvalid           : out std_logic;
        o_axis_tdata            : out std_logic_vector(31 downto 0)
    ) ;
end entity ; -- div_model
 
architecture behav of div_model is
    signal ctr : natural range 0 to 20 := 0;
    signal odata : natural range 0 to 255 := 0;
 
    signal num : signed (23 downto 0);
    signal den : signed (15 downto 0);
    signal div : signed (31 downto 0);
    signal quo : signed (31 downto 0);
begin
    -- division
    num <= signed(i1_axis_tdata);
    den <= signed(i2_axis_tdata);
 
    quo(31 downto 8) <= num / den when den /= X"0000"
        else (others => '0');  
    div <= (shift_left(resize(num, quo'length), 8) / den) when den /= X"0000"
        else (others => '0');  
    quo( 7 downto 0) <= div(7 downto 0) when den /= X"0000"
        else (others => '0');

    --r_num <= shift_left(resize(num, quo'length), 4);
    --r_den <= shift_left(resize(den, quo'length), 4);
    --quo <= r_num / r_den when r_den /= X"00000000"
    --    else (others => '0');
 
    -- be always ready
    i1_axis_tready <= '1';
    i2_axis_tready <= '1';
       
    p_behav : process( clk )
        variable delay_run : boolean := false;
    begin
        if rising_edge(clk) then
            if (rst_n='0') then
                ctr <= 0;
                delay_run := false;
            else
                -- start delay if both inputs are valid
                if i1_axis_tvalid = '1' and i2_axis_tvalid = '1' then
                    -- wrap
                    delay_run := true;
                end if;
 
                -- count delay and generate output
                o_axis_tvalid <= '0';
                if delay_run then
                    if ctr = DELAYTIME then
                        o_axis_tdata <= std_logic_vector(quo);
                        o_axis_tvalid <= '1';
                        ctr <= 0;
                        delay_run := false;
                    else
                        ctr <= ctr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_behav
 
 
end architecture ; -- behav