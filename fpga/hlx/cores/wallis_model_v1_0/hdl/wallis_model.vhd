-------------------------------------------------------------------------------
-- Title       : Wallis filter model
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : wallis_model.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Jul 18 15:24:07 2018
-- Last update : Thu Jul 19 14:07:45 2018
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

entity wallis_model is
    generic (
        WIN_SIZE : natural := 21
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- control
        ------------------------------------------------------------------------
        wa_par_c_gvar 			: in std_logic_vector (19 downto 0);
        wa_par_c 				: in std_logic_vector (5  downto 0);
        wa_par_ci_gvar 			: in std_logic_vector (19 downto 0);
        wa_par_b_gmean 			: in std_logic_vector (13 downto 0);
        wa_par_bi	 			: in std_logic_vector (5  downto 0);

        -- input stream
        ------------------------------------------------------------------------
        i_axis_tlast            : in std_logic;
        i_axis_tready           : out std_logic;
        i_axis_tvalid           : in std_logic;
        i_axis_tdata            : in std_logic_vector(7 downto 0);
        
        -- output stream
        ------------------------------------------------------------------------
        o_axis_tlast            : out std_logic;
        o_axis_tready           : in std_logic;
        o_axis_tvalid           : out std_logic;
        o_axis_tdata            : out std_logic_vector(7 downto 0)
    ) ;
end entity ; -- wallis_model

architecture behav of wallis_model is
    signal ctr : natural range 0 to (WIN_SIZE*WIN_SIZE) := 0;
    signal first : boolean := true;
    signal odata : natural range 0 to 255 := 0;
begin

    -- be always ready
    i_axis_tready <= '1';
        
    p_behav : process( clk )
        variable genOut : boolean := false;
    begin
        if rising_edge(clk) then
            if (rst_n='0') then
                ctr <= 0;
                first <= true;
                genOut := false;
                o_axis_tdata <= (others => '0');
            else
                -- count up if input is valid
                if i_axis_tvalid = '1' then
                    -- wrap
                    if first and ctr = (WIN_SIZE*WIN_SIZE)-1 then
                        ctr <= 0;
                        genOut := true;
                        first <= false;
                    elsif not first and ctr = (WIN_SIZE)-1 then
                        ctr <= 0;
                        genOut := true;
                    else
                        ctr <= ctr + 1;
                    end if;
                end if;

                -- generate output
                if genOut and o_axis_tready = '1' then
                    o_axis_tvalid <= '1';
                    o_axis_tdata <= std_logic_vector(to_unsigned(odata,8));
                    odata <= (odata + 42) mod 255;
                    genOut := false;
                else
                    o_axis_tvalid <= '0';
                end if;

                -- check for restart
                if i_axis_tlast = '1' then
                    o_axis_tlast <= '1';
                    first <=true;
                    ctr  <= 0;
                    genOut:= false;
                else
                    o_axis_tlast <= '0';
                end if;
            end if;
        end if;
    end process ; -- p_behav


end architecture ; -- behav