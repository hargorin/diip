-------------------------------------------------------------------------------
-- Title       : UFT CMD Packet assembler
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_cmd_assembler.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 13:20:19 2017
-- Last update : Wed Mar  7 16:38:47 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Assembles a UFT command packet and sends it to the UDP IP Stack
-- 
-- Input data must be valid between start signal and done signal
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity uft_tx_cmd_assembler is
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Data size in number of sequences to be sent
        data_size   : in  std_logic_vector (31 downto 0);
        -- Transaction ID 
        tcid        : in  std_logic_vector (6 downto 0);

        -- Controll
        -- ---------------------------------------------------------------------
        -- Assert high for 1 clk to start generation
        en_start       : in  std_logic; -- generate start packet
        done           : out std_logic; -- asserted if packet is sent

        -- Output AXI stream
        -- ---------------------------------------------------------------------
        tx_tvalid               : out std_logic;
        tx_tlast                : out std_logic;
        tx_tdata                : out std_logic_vector (7 downto 0);
        tx_tready               : in  std_logic
    );
end entity uft_tx_cmd_assembler;

architecture rtl of uft_tx_cmd_assembler is
    -- counts from 0 to 33 indicateing the cmd packet bytes
    signal ctr               : unsigned (5 downto 0);
    
    signal running              : std_logic := '0';
    -- stores the command code
    signal command              : std_logic_vector (6 downto 0);
    signal command_d1              : std_logic_vector (23 downto 0);
    signal command_d2              : std_logic_vector (31 downto 0);
begin
    ----------------------------------------------------------------------------
    -- Stores the required command data at start
    -- -------------------------------------------------------------------------
    p_comd : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                command  <= (others => '0');
                command_d1  <= (others => '0');
                command_d2  <= (others => '0');
            else
                if en_start = '1' and running = '0' then
                    command <= "0000000";
                    command_d1(6 downto 0) <= tcid;
                    command_d1(23 downto 7) <= (others => '0');
                    command_d2 <= data_size;
                else
                    command <= command;
                    command_d1 <= command_d1;
                    command_d2 <= command_d2;
                end if;
            end if;
        end if;        
    end process ; -- p_comd

    ----------------------------------------------------------------------------
    -- Enable process
    p_en : process ( clk )
    ----------------------------------------------------------------------------
    begin    
        if rising_edge(clk) then
            if rst_n = '0' then
                running <= '0';
                done <= '0';
            else
                done <= '0';

                if en_start = '1' and running = '0' then
                    running <= '1';
                elsif ctr = to_unsigned(34, ctr'length) then
                    running <= '0';
                    done <= '1';
                else
                    running <= running;
                end if;
            end if;
        end if;                
    end process p_en;

    ----------------------------------------------------------------------------
    -- Controlls the counter
    -- 
    -- Increment if AXI stream is ready and packet generator is running
    -- -------------------------------------------------------------------------
    p_ctr : process ( clk )
    ----------------------------------------------------------------------------
    begin    
        if rising_edge(clk) then
            if rst_n = '0' then
                ctr <= (others => '0');
            else
                if running = '1' and tx_tready = '1' then
                    ctr <= ctr + 1;
                elsif running = '1' then
                    ctr <= ctr;
                else
                    ctr <= (others => '0');
                end if;
            end if;
        end if;
    end process p_ctr;
    
    ----------------------------------------------------------------------------
    -- Controls the AXI stream output
    -- -------------------------------------------------------------------------
    p_out : process (ctr, running)
    ----------------------------------------------------------------------------
    begin
        tx_tvalid <= '0';
        tx_tlast <= '0';
        tx_tdata <= (others => '0');

        if running = '1' and ctr < to_unsigned(33, ctr'length) then
            tx_tvalid <= '1';
            tx_tlast <= '0';
        elsif running = '1' and ctr = to_unsigned(33, ctr'length) then
            tx_tvalid <= '1';
            tx_tlast <= '1';
        else
            tx_tvalid <= '0';
            tx_tlast <= '0';
        end if;

        -- Output data mux
        if ctr = to_unsigned(0, ctr'length) then
            tx_tdata(7) <= '0';
            tx_tdata(6 downto 0) <= command;
        elsif ctr = to_unsigned(1, ctr'length) then
            tx_tdata <= command_d1(23 downto 16);
        elsif ctr = to_unsigned(2, ctr'length) then
            tx_tdata <= command_d1(15 downto 8);
        elsif ctr = to_unsigned(3, ctr'length) then
            tx_tdata <= command_d1(7 downto 0);
        elsif ctr = to_unsigned(4, ctr'length) then
            tx_tdata <= command_d2(31 downto 24);
        elsif ctr = to_unsigned(5, ctr'length) then
            tx_tdata <= command_d2(23 downto 16);
        elsif ctr = to_unsigned(6, ctr'length) then
            tx_tdata <= command_d2(15 downto 8);
        elsif ctr = to_unsigned(7, ctr'length) then
            tx_tdata <= command_d2(7 downto 0);
        else
            tx_tdata <= (others => '0');
        end if;
    end process p_out;
end architecture rtl;











