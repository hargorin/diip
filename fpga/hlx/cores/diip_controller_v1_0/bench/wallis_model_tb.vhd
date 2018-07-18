-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : wallis_model_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Wed Jul 18 15:48:54 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity wallis_model_tb is

end entity wallis_model_tb;

-----------------------------------------------------------

architecture testbench of wallis_model_tb is

	-- Testbench DUT generics as constants
    -- clk and reset
    ------------------------------------------------------------------------
    signal clk     :     std_logic;
    signal rst_n   :     std_logic;

    -- control
    ------------------------------------------------------------------------
    signal wa_par_c_gvar           :  std_logic_vector (21 downto 0);
    signal wa_par_c                :  std_logic_vector (5  downto 0);
    signal wa_par_ci_gvar          :  std_logic_vector (19 downto 0);
    signal wa_par_b_gmean          :  std_logic_vector (13 downto 0);
    signal wa_par_bi               :  std_logic_vector (5  downto 0);

    -- input stream
    ------------------------------------------------------------------------
    signal i_axis_tlast            :  std_logic;
    signal i_axis_tready           :  std_logic;
    signal i_axis_tvalid           :  std_logic;
    signal i_axis_tdata            :  std_logic_vector(7 downto 0);
    
    -- output stream
    ------------------------------------------------------------------------
    signal o_axis_tlast            :  std_logic;
    signal o_axis_tready           :  std_logic;
    signal o_axis_tvalid           :  std_logic;
    signal o_axis_tdata            :  std_logic_vector(7 downto 0);

	-- Testbench DUT ports as signals

	-- Other constants
    constant win_size : natural := 3;
    constant clk_period : time := 8 ns;
	signal stop_sim : std_logic := '0';

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for clk_period / 2.0;
        clk <= '0';
        wait for clk_period / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 5.0*clk_period;
        wait;
    end process RESET_GEN;


	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

    p_sim : process	
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;
    begin
        wa_par_c_gvar <= (others => '0');
        wa_par_c <= (others => '0');
        wa_par_ci_gvar <= (others => '0');
        wa_par_b_gmean <= (others => '0');
        wa_par_bi <= (others => '0');
        i_axis_tlast <= '0';
        i_axis_tvalid <= '0';
        i_axis_tdata <= (others => '0');
        o_axis_tready <= '0';

        waitfor(10);

        -- start stim
        o_axis_tready <= '1';

        i_axis_tvalid <= '1';
        waitfor(win_size*(win_size+5)-1);
        i_axis_tlast <= '1';
        waitfor(1);
        i_axis_tlast <= '0';
        i_axis_tvalid <= '0';
        
        waitfor(10);
    	stop_sim <= '1';
    end process;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    wallis_model_1 : entity work.wallis_model
        generic map (
            WIN_SIZE => win_size
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            wa_par_c_gvar  => wa_par_c_gvar,
            wa_par_c       => wa_par_c,
            wa_par_ci_gvar => wa_par_ci_gvar,
            wa_par_b_gmean => wa_par_b_gmean,
            wa_par_bi      => wa_par_bi,
            i_axis_tlast   => i_axis_tlast,
            i_axis_tready  => i_axis_tready,
            i_axis_tvalid  => i_axis_tvalid,
            i_axis_tdata   => i_axis_tdata,
            o_axis_tlast   => o_axis_tlast,
            o_axis_tready  => o_axis_tready,
            o_axis_tvalid  => o_axis_tvalid,
            o_axis_tdata   => o_axis_tdata
        );    
end architecture testbench;