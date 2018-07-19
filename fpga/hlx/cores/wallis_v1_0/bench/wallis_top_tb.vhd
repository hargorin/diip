-------------------------------------------------------------------------------
-- Title       : Wallis Filter Top
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_top_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Thu Jul 19 16:06:12 2018
-- Last update : Thu Jul 19 16:13:34 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Testbench for the Wallis filter
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

entity wallis_top_tb is

end entity wallis_top_tb;

-----------------------------------------------------------

architecture testbench of wallis_top_tb is

	-- Testbench DUT generics as constants
    constant WIN_SIZE     : positive              := 21*21;
    constant M_IN_WIDTH   : positive              := 8;
    constant M_OUT_WIDTH  : positive              := 17;
    constant V_IN_WIDTH   : positive              := 16;
    constant V_OUT_WIDTH  : positive              := 25;
    constant REC_WIN_SIZE : unsigned(14 downto 0) := "100101001001101";

    constant DELAYTIME    : natural 			  := 10;

	-- Testbench DUT ports as signals
    signal clk                    : std_logic;
    signal rst_n                  : std_logic;
    signal wa_par_c_gvar          : std_logic_vector (19 downto 0);
    signal wa_par_c               : std_logic_vector (5 downto 0);
    signal wa_par_ci_gvar         : std_logic_vector (19 downto 0);
    signal wa_par_b_gmean         : std_logic_vector (13 downto 0);
    signal wa_par_bi              : std_logic_vector (5 downto 0);
    signal i_axis_tlast           : std_logic;
    signal i_axis_tready          : std_logic;
    signal i_axis_tvalid          : std_logic;
    signal i_axis_tdata           : std_logic_vector(7 downto 0);
    signal o_axis_tlast           : std_logic;
    signal o_axis_tready          : std_logic;
    signal o_axis_tvalid          : std_logic;
    signal o_axis_tdata           : std_logic_vector(7 downto 0);
    signal m_axis_dividend_tvalid : std_logic;
    signal m_axis_dividend_tready : std_logic;
    signal m_axis_dividend_tdata  : std_logic_vector(23 downto 0);
    signal m_axis_divisor_tvalid  : std_logic;
    signal m_axis_divisor_tready  : std_logic;
    signal m_axis_divisor_tdata   : std_logic_vector(15 downto 0);
    signal s_axis_dout_tvalid     : std_logic;
    signal s_axis_dout_tready     : std_logic;
    signal s_axis_dout_tdata      : std_logic_vector(31 downto 0);

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

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.wallis_top
        generic map (
            WIN_SIZE     => WIN_SIZE,
            M_IN_WIDTH   => M_IN_WIDTH,
            M_OUT_WIDTH  => M_OUT_WIDTH,
            V_IN_WIDTH   => V_IN_WIDTH,
            V_OUT_WIDTH  => V_OUT_WIDTH,
            REC_WIN_SIZE => REC_WIN_SIZE
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            wa_par_c_gvar          => wa_par_c_gvar,
            wa_par_c               => wa_par_c,
            wa_par_ci_gvar         => wa_par_ci_gvar,
            wa_par_b_gmean         => wa_par_b_gmean,
            wa_par_bi              => wa_par_bi,
            i_axis_tlast           => i_axis_tlast,
            i_axis_tready          => i_axis_tready,
            i_axis_tvalid          => i_axis_tvalid,
            i_axis_tdata           => i_axis_tdata,
            o_axis_tlast           => o_axis_tlast,
            o_axis_tready          => o_axis_tready,
            o_axis_tvalid          => o_axis_tvalid,
            o_axis_tdata           => o_axis_tdata,
            m_axis_dividend_tvalid => m_axis_dividend_tvalid,
            m_axis_dividend_tready => m_axis_dividend_tready,
            m_axis_dividend_tdata  => m_axis_dividend_tdata,
            m_axis_divisor_tvalid  => m_axis_divisor_tvalid,
            m_axis_divisor_tready  => m_axis_divisor_tready,
            m_axis_divisor_tdata   => m_axis_divisor_tdata,
            s_axis_dout_tvalid     => s_axis_dout_tvalid,
            s_axis_dout_tready     => s_axis_dout_tready,
            s_axis_dout_tdata      => s_axis_dout_tdata
        );

    div_model : entity work.div_model
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