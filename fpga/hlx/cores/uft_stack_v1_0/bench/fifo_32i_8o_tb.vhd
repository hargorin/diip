-------------------------------------------------------------------------------
-- Title       : FIF 32i 8o TB
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : fifo_32i_8o_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 16:27:20 2017
-- Last update : Wed Mar  7 13:37:39 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: TB
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

entity fifo_32i_8o_tb is
    generic (
        constant FIFO_DEPTH : positive := 10
    );
end entity fifo_32i_8o_tb;

-----------------------------------------------------------

architecture testbench of fifo_32i_8o_tb is

    -- Testbench signals
    signal clk      : std_logic;
    signal rst_n    : std_logic;
    signal write_en : std_logic;
    signal data_in  : std_logic_vector (31 downto 0);
    signal read_en  : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
    signal empty    : std_logic;
    signal full     : std_logic;

    constant C_CLK_PERIOD : time := 8 ns; -- NS
    signal stop_sim : std_logic := '0';

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for C_CLK_PERIOD / 2;
        clk <= '0';
        wait for C_CLK_PERIOD / 2;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 5*C_CLK_PERIOD;
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*C_CLK_PERIOD;
            wait until rising_edge(clk);
        end procedure waitfor;
    begin
        stop_sim <= '0';
        write_en <= '0';
        read_en <= '0';
        data_in <= (others => '0');
        waitfor(7);

        ------------------------------------------------------------------------
        -- TEST 1: Fill 4
        -- ---------------------------------------------------------------------
        assert empty = '1' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;

        write_en <= '1';
        data_in <= X"11223344";
        waitfor(1);
        write_en <= '0';
        waitfor(1);

        assert empty = '0' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;
        
        waitfor(2);

        ------------------------------------------------------------------------
        -- TEST 2: Read 4
        -- ---------------------------------------------------------------------
        waitfor(1);
        read_en <= '1';
        waitfor(2);
        assert data_out = X"44" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"33" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"22" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"11" report "wrong output data" severity error;
        assert empty = '1' report "empty output error" severity error;
        read_en <= '0';
        waitfor(3);


        ------------------------------------------------------------------------
        -- TEST 3: Fill 8
        -- ---------------------------------------------------------------------
        waitfor(1);
        write_en <= '1';
        data_in <= X"11223344";
        waitfor(1);
        data_in <= X"55667788";
        waitfor(1);
        assert empty = '0' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;
        write_en <= '0';
        waitfor(3);

        ------------------------------------------------------------------------
        -- TEST 4: Read 8
        -- ---------------------------------------------------------------------
        waitfor(1);
        read_en <= '1';
        waitfor(2);
        assert data_out = X"44" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"33" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"22" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"11" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"88" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"77" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"66" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"55" report "wrong output data" severity error;
        assert empty = '1' report "empty output error" severity error;
        read_en <= '0';
        waitfor(3);

        ------------------------------------------------------------------------
        -- TEST 5: Fill 4, read 3, fill 4, read 5
        -- ---------------------------------------------------------------------
        write_en <= '1';
        data_in <= X"11223344";
        waitfor(1);
        write_en <= '0';
        waitfor(2);
        
        waitfor(1);
        read_en <= '1';
        waitfor(2);
        assert data_out = X"44" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"33" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"22" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        read_en <= '0';

        write_en <= '1';
        data_in <= X"55667788";
        waitfor(1);
        write_en <= '0';
        waitfor(2);
        
        read_en <= '1';
        waitfor(1);
        assert data_out = X"11" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"88" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"77" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"66" report "wrong output data" severity error;
        assert empty = '0' report "empty output error" severity error;
        waitfor(1);
        assert data_out = X"55" report "wrong output data" severity error;
        assert empty = '1' report "empty output error" severity error;
        read_en <= '0';
        waitfor(3);
        read_en <= '0';

        
        waitfor(2);
        assert false report "All test successful" severity note;
        stop_sim <= '1';
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.fifo_32i_8o
        generic map (
            FIFO_DEPTH => FIFO_DEPTH
                )
                port map (
                    clk      => clk,
                    rst_n    => rst_n,
                    write_en => write_en,
                    data_in  => data_in,
                    read_en  => read_en,
                    data_out => data_out,
                    empty    => empty,
                    full     => full
                );

end architecture testbench;