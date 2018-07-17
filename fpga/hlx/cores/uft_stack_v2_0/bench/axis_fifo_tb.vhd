-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : axis_fifo_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Tue Jul 17 08:51:20 2018
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

entity axis_fifo_tb is

end entity axis_fifo_tb;

-----------------------------------------------------------

architecture testbench of axis_fifo_tb is

	-- Testbench DUT generics as constants
    constant DATA_WIDTH : positive := 8;
    constant FIFO_DEPTH : positive := 4;

	-- Testbench DUT ports as signals
    signal CLK           : STD_LOGIC;
    signal RST_N         : STD_LOGIC;
    signal M_AXIS_TVALID : std_logic;
    signal M_AXIS_TDATA  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal M_AXIS_TREADY : std_logic;
    signal M_AXIS_TLAST  : std_logic;
    signal S_AXIS_TVALID : std_logic;
    signal S_AXIS_TDATA  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal S_AXIS_TREADY : std_logic;
    signal S_AXIS_TLAST  : std_logic;

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

    p_sim : process	
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;
    begin
        M_AXIS_TREADY <= '0';
        S_AXIS_TVALID <= '0';
        S_AXIS_TLAST <= '0';
		S_AXIS_TDATA <= (others => '0');

        waitfor(10);

        -- write full
        S_AXIS_TVALID <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(1,8));
        waitfor(1);
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(2,8));
        waitfor(1);
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(3,8));
        waitfor(1);
        S_AXIS_TLAST <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(4,8));
        waitfor(1);
        S_AXIS_TLAST <= '0';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(5,8));
        waitfor(1);
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(6,8));
        waitfor(1);
        S_AXIS_TVALID <= '0';

        waitfor(2);

        -- read empty
        M_AXIS_TREADY <= '1';
        waitfor(6);
        M_AXIS_TREADY <= '0';


        -- write one
        S_AXIS_TVALID <= '1';
        S_AXIS_TLAST <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(1,8));
        waitfor(1);
        S_AXIS_TLAST <= '0';
        S_AXIS_TVALID <= '0';
        -- read one
        M_AXIS_TREADY <= '1';
        waitfor(1);
        M_AXIS_TREADY <= '0';

        -- write two
        S_AXIS_TVALID <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(15,8));
        waitfor(1);
        S_AXIS_TLAST <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(16,8));
        waitfor(1);
        S_AXIS_TLAST <= '0';
        S_AXIS_TVALID <= '0';
        -- read two
        M_AXIS_TREADY <= '1';
        waitfor(2);
        M_AXIS_TREADY <= '0';

        -- write two
        S_AXIS_TVALID <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(17,8));
        waitfor(1);
        S_AXIS_TLAST <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(18,8));
        waitfor(1);
        S_AXIS_TLAST <= '0';
        S_AXIS_TVALID <= '0';
        -- read two
        M_AXIS_TREADY <= '1';
        waitfor(3);
        M_AXIS_TREADY <= '0';


        waitfor(5);


        -- write three
        S_AXIS_TVALID <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(5,8));
        waitfor(1);
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(6,8));
        waitfor(1);
        S_AXIS_TLAST <= '1';
        S_AXIS_TDATA <= std_logic_vector(to_unsigned(7,8));
        waitfor(1);
        S_AXIS_TLAST <= '0';
        S_AXIS_TVALID <= '0';
        -- read three
        waitfor(3);
        M_AXIS_TREADY <= '1';
        waitfor(5);
        M_AXIS_TREADY <= '0';


    	stop_sim <= '1';
    end process;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            FIFO_DEPTH => FIFO_DEPTH
            )
        port map (
            CLK           => CLK,
            RST_N         => RST_N,
            M_AXIS_TVALID => M_AXIS_TVALID,
            M_AXIS_TDATA  => M_AXIS_TDATA,
            M_AXIS_TREADY => M_AXIS_TREADY,
            M_AXIS_TLAST  => M_AXIS_TLAST,
            S_AXIS_TVALID => S_AXIS_TVALID,
            S_AXIS_TDATA  => S_AXIS_TDATA,
            S_AXIS_TREADY => S_AXIS_TREADY,
            S_AXIS_TLAST  => S_AXIS_TLAST
        );
end architecture testbench;