-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : div_model_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Wed Aug  8 10:59:20 2018
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

entity div_model_tb is

end entity div_model_tb;

-----------------------------------------------------------

architecture testbench of div_model_tb is

	-- Testbench DUT generics as constants
    constant DELAYTIME : natural := 5;

	-- Testbench DUT ports as signal
    -- clk and reset
    ------------------------------------------------------------------------
    signal clk     :     std_logic;
    signal rst_n   :     std_logic;
    -- input 1 stream
    ------------------------------------------------------------------------
    signal i1_axis_tready           :  std_logic;
    signal i1_axis_tvalid           :  std_logic;
    signal i1_axis_tdata            :  std_logic_vector(23 downto 0);

    -- input 2 stream
    ------------------------------------------------------------------------
    signal i2_axis_tready           :  std_logic;
    signal i2_axis_tvalid           :  std_logic;
    signal i2_axis_tdata            :  std_logic_vector(15 downto 0);
    
    -- output stream
    ------------------------------------------------------------------------
    signal o_axis_tready           :  std_logic;
    signal o_axis_tvalid           :  std_logic;
    signal o_axis_tdata            :  std_logic_vector(31 downto 0);

    signal o_ganz : std_logic_vector(23 downto 0);
    signal o_frac : std_logic_vector(7 downto 0);

	-- Other constants
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

    o_ganz <= o_axis_tdata(31 downto 8);
    o_frac <= o_axis_tdata( 7 downto 0);

    p_sim : process	
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;
    begin
        i1_axis_tvalid            <= '0';
        i2_axis_tvalid            <= '0';
        o_axis_tready            <= '0';   
        waitfor(6);
        i1_axis_tdata             <= (others => '0');
        i2_axis_tdata             <= (others => '0');     
        waitfor(10);


        
        -- start stim
        i1_axis_tdata <= std_logic_vector(to_unsigned(20,24));
        i2_axis_tdata <= std_logic_vector(to_unsigned(5,16));
        
        i1_axis_tvalid <= '1';
        i2_axis_tvalid <= '1';
        waitfor(1);
        i1_axis_tvalid <= '0';
        i2_axis_tvalid <= '0';
        waitfor(10);


        i1_axis_tdata <= std_logic_vector(to_unsigned(21,24));
        i2_axis_tdata <= std_logic_vector(to_unsigned(6,16));
        
        i1_axis_tvalid <= '1';
        i2_axis_tvalid <= '1';
        waitfor(1);
        i1_axis_tvalid <= '0';
        i2_axis_tvalid <= '0';

        waitfor(10);
    	stop_sim <= '1';
    end process;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    div_model_1 : entity work.div_model
        generic map (
            DELAYTIME => DELAYTIME
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            i1_axis_tready => i1_axis_tready,
            i1_axis_tvalid => i1_axis_tvalid,
            i1_axis_tdata  => i1_axis_tdata,
            i2_axis_tready => i2_axis_tready,
            i2_axis_tvalid => i2_axis_tvalid,
            i2_axis_tdata  => i2_axis_tdata,
            o_axis_tready  => o_axis_tready,
            o_axis_tvalid  => o_axis_tvalid,
            o_axis_tdata   => o_axis_tdata
        );    

end architecture testbench;