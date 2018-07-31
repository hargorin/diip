-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_data_assembler_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 15:37:00 2017
-- Last update : Mon Jul 16 16:09:23 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
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

entity uft_tx_data_assembler_tb is

end entity uft_tx_data_assembler_tb;

-----------------------------------------------------------

architecture testbench of uft_tx_data_assembler_tb is
    -- Testbench signals
    signal clk                    : std_logic;
    signal rst_n                  : std_logic;
    
    signal tcid                   : std_logic_vector (6 downto 0);
    signal seq                    : std_logic_vector (23 downto 0);
    signal size                   : std_logic_vector (10 downto 0);
    signal start                  : std_logic;
    signal done                   : std_logic;
    
    signal tx_tvalid              : std_logic;
    signal tx_tlast               : std_logic;
    signal tx_tdata               : std_logic_vector (7 downto 0);
    signal tx_tready              : std_logic;

    signal s_axis_tvalid              : std_logic;
    signal s_axis_tlast               : std_logic;
    signal s_axis_tdata               : std_logic_vector (7 downto 0);
    signal s_axis_tready              : std_logic;

    constant C_CLK_PERIOD : time := 8 ns; -- NS
    signal stop_sim : std_logic := '0';

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for C_CLK_PERIOD / 2.0;
        clk <= '0';
        wait for C_CLK_PERIOD / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 20.0*C_CLK_PERIOD;
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
    begin
        size <= std_logic_vector(to_unsigned(100, size'length));
        tcid <= std_logic_vector(to_unsigned(0, tcid'length));
        seq <= std_logic_vector(to_unsigned(0, seq'length));
        start <= '0';
        tx_tready <= '0';

        s_axis_tvalid <= '1';
        s_axis_tdata <= "10000001";
        s_axis_tlast <= '0';

        wait for 25*C_CLK_PERIOD;


        ------------------------------------------------------------------------
        -- TEST 1: 100 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 1: 100 byte data transfer";
        size <= std_logic_vector(to_unsigned(100, size'length));
        tcid <= std_logic_vector(to_unsigned(42, tcid'length));
        seq <= std_logic_vector(to_unsigned(1, seq'length));
        tx_tready <= '1';
        
        start <= '1';
        wait for 1*C_CLK_PERIOD;        
        start <= '0';
        
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;


        ------------------------------------------------------------------------
        -- TEST 2: 64 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 2: 64 byte data transfer";
        start <= '1';
        size <= std_logic_vector(to_unsigned(64, size'length));
        tcid <= std_logic_vector(to_unsigned(13, tcid'length));
        seq <= std_logic_vector(to_unsigned(1, seq'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        start <= '0';
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;

        --------------------------------------------------------------------------
        ---- TEST 2: 10 byte data transfer with tlast too early
        ---- ---------------------------------------------------------------------
        --report "-- TEST 2: 10 byte data transfer";
        --start <= '1';
        --size <= std_logic_vector(to_unsigned(10, size'length));
        --tcid <= std_logic_vector(to_unsigned(13, tcid'length));
        --seq <= std_logic_vector(to_unsigned(2, seq'length));
        --tx_tready <= '1';
        --wait for 1*C_CLK_PERIOD;        
        --start <= '0';
        --wait for 3*C_CLK_PERIOD;
        --s_axis_tlast <= '1';
        --wait until done = '1';
        --tx_tready <= '0';
        --wait for 3*C_CLK_PERIOD;

        
        stop_sim <= '1';
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Testbench Validation
    -- 
    -- Stores the axi stream data into an output file
    -----------------------------------------------------------
    p_axi_stream_check : process( clk, rst_n )
        type buf is array (0 to 1500) of std_logic_vector (7 downto 0);
        variable axi_buf : buf;
        variable ctr : natural range 0 to 1499 := 0;
        variable i : natural range 0 to 1499 := 0;
        variable fi : natural range 0 to 1499 := 0;

        file file_axi_s     : text;
        variable oline      : line;
    begin
        if rst_n = '0' then
            ctr := 0;
        elsif rising_edge(clk) then
            if tx_tvalid = '1' then
                axi_buf(ctr) := tx_tdata;
                ctr := ctr + 1;
            end if;
            if tx_tlast = '1' then
                file_open(file_axi_s, "axi_stream_res_" & INTEGER'IMAGE(fi) & ".log", write_mode);
                report "Start writing file";
                for i in 0 to ctr loop
                    hwrite(oline, axi_buf(i), left, 8);
                    writeline(file_axi_s, oline);
                end loop;
                file_close(file_axi_s);
                ctr := 0;
                fi := fi + 1;
            end if;
        end if;
    end process ; -- p_axi_stream_check


    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUV : entity work.uft_tx_data_assembler
        port map (
            clk           => clk,
            rst_n         => rst_n,
            tcid          => tcid,
            seq           => seq,
            size          => size,
            start         => start,
            done          => done,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tlast  => s_axis_tlast,
            s_axis_tdata  => s_axis_tdata,
            s_axis_tready => s_axis_tready,
            tx_tvalid     => tx_tvalid,
            tx_tlast      => tx_tlast,
            tx_tdata      => tx_tdata,
            tx_tready     => tx_tready
        );     

end architecture testbench;