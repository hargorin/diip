-------------------------------------------------------------------------------
-- Title       : Wallis Filter Testbench
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_filter_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Wed Jul 18 09:16:39 2018
-- Last update : Thu Jul 19 16:07:21 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Testbench for the Wallis algorithm
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

entity wallis_filter_tb is

end entity wallis_filter_tb;

-----------------------------------------------------------

architecture testbench of wallis_filter_tb is

	-- Testbench DUT generics as constants
	constant DELAYTIME 			  : natural := 5;

	-- Testbench DUT ports as signals
    signal clk                    : std_logic;
    signal rst_n                  : std_logic;
    signal pixel                  : std_logic_vector(7 downto 0);
    signal n_mean                 : std_logic_vector(7 downto 0);
    signal n_var                  : std_logic_vector(13 downto 0);
   	signal par_c_gvar			  : std_logic_vector(19 downto 0) := "00101101101101000000"; --2925
   	signal par_ci_gvar			  : std_logic_vector(19 downto 0) := "00001010100011000000"; --675
   	signal par_c 				  : std_logic_vector(5 downto 0) := "110100"; --0.8125
   	signal par_b_gmean 			  : std_logic_vector(13 downto 0) := "00111101100001"; --61.515625
   	signal par_bi				  : std_logic_vector(5 downto 0) := "100001"; --0.515625
    signal wallis                 : std_logic_vector(7 downto 0);
    signal m_axis_dividend_tvalid : std_logic;
    signal m_axis_dividend_tready : std_logic;
    signal m_axis_dividend_tdata  : std_logic_vector(23 downto 0);
    signal m_axis_divisor_tvalid  : std_logic;
    signal m_axis_divisor_tready  : std_logic;
    signal m_axis_divisor_tdata   : std_logic_vector(15 downto 0);
    signal s_axis_dout_tvalid     : std_logic;
    signal s_axis_dout_tready     : std_logic;
    signal s_axis_dout_tdata      : std_logic_vector(31 downto 0);
    signal valid                  : std_logic;
    signal en                     : std_logic;
    signal clear                  : std_logic;

    signal o_ganz : std_logic_vector(23 downto 0);
    signal o_frac : std_logic_vector(7 downto 0);

	-- Other constants
    constant clk_period : time := 10 ns;
    signal stop_sim  : std_logic := '0';

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
                 '1' after 20.0*clk_period;
        wait;
    end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
    o_ganz <= s_axis_dout_tdata(31 downto 8);
    o_frac <= s_axis_dout_tdata( 7 downto 0);

	p_sim : process
	    procedure waitfor ( t : in natural ) is
	    begin
	        wait for t*clk_period;
	        wait until rising_edge(clk);
	    end procedure waitfor;

    begin
    	waitfor(25);

    	en <= '1';
    	pixel <= x"FF"; --255
    	n_mean <= x"64"; --100
    	n_var <= "00000000001010"; --10
    	waitfor(1);
    	en <= '0';
  	
    	waitfor(5);

    	en <= '1';
    	pixel <= x"0A"; --10
    	n_mean <= x"FF"; --255
    	n_var <= "00101110111000"; --3000
    	waitfor(1);
    	en <= '0';
		
		waitfor(5);

    	en <= '1';
    	pixel <= x"C8"; --200
    	n_mean <= x"80"; --128
    	n_var <= "00101110111000"; --3000
    	waitfor(1);
    	en <= '0';
    	


		waitfor(15);
        stop_sim <= '1';
        wait;
	end process; -- p_sim

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.wallis_filter
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            pixel                  => pixel,
            n_mean                 => n_mean,
            n_var                  => n_var,
            par_c_gvar             => par_c_gvar,
            par_ci_gvar            => par_ci_gvar,
            par_c                  => par_c,
            par_b_gmean            => par_b_gmean,
            par_bi                 => par_bi,
            wallis                 => wallis,
            m_axis_dividend_tvalid => m_axis_dividend_tvalid,
            m_axis_dividend_tready => m_axis_dividend_tready,
            m_axis_dividend_tdata  => m_axis_dividend_tdata,
            m_axis_divisor_tvalid  => m_axis_divisor_tvalid,
            m_axis_divisor_tready  => m_axis_divisor_tready,
            m_axis_divisor_tdata   => m_axis_divisor_tdata,
            s_axis_dout_tvalid     => s_axis_dout_tvalid,
            s_axis_dout_tready     => s_axis_dout_tready,
            s_axis_dout_tdata      => s_axis_dout_tdata,
            valid                  => valid,
            en                     => en,
            clear                  => clear
        );    

    div_model_1 : entity work.div_model
        generic map (
            DELAYTIME => DELAYTIME
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            i1_axis_tready => m_axis_dividend_tready,
            i1_axis_tvalid => m_axis_dividend_tvalid,
            i1_axis_tdata  => m_axis_dividend_tdata,
            i2_axis_tready => m_axis_divisor_tready,
            i2_axis_tvalid => m_axis_divisor_tvalid,
            i2_axis_tdata  => m_axis_divisor_tdata,
            o_axis_tready  => s_axis_dout_tready,
            o_axis_tvalid  => s_axis_dout_tvalid,
            o_axis_tdata   => s_axis_dout_tdata
        );          
end architecture testbench;