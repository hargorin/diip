-------------------------------------------------------------------------------
-- Title       : UFT Tx Data packet assembler
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_data_assembler.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 15:13:40 2017
-- Last update : Tue Jul 24 13:57:32 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Creates UFT Data packets
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------
library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity uft_tx_data_assembler is
    port (
        -- clk and reset
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Transaction ID 
        tcid        : in  std_logic_vector (6 downto 0);
        -- packet sequence number
        seq         : in std_logic_vector (23 downto 0);
        -- number of bytes to send ( Max 1464 bytes per packet)
        size        : in std_logic_vector (10 downto 0);

        -- Controll
        -- ---------------------------------------------------------------------
        -- Assert high for 1 clk to start generation
        start       : in  std_logic;
        done           : out std_logic; -- asserted if packet is sent

        -- TX input AXI stream
        -- ---------------------------------------------------------------------
        s_axis_tvalid               : in   std_logic;
        s_axis_tlast                : in   std_logic;
        s_axis_tdata                : in   std_logic_vector (7 downto 0);
        s_axis_tready               : out  std_logic;

        -- Output AXI stream
        -- ---------------------------------------------------------------------
        tx_tvalid               : out std_logic;
        tx_tlast                : out std_logic;
        tx_tdata                : out std_logic_vector (7 downto 0);
        tx_tready               : in  std_logic
    );
end entity uft_tx_data_assembler;   

architecture rtl of uft_tx_data_assembler is
    -- counts from 0 to 1464 indicating the data packet byte
    signal ctr               : unsigned (10 downto 0);
    -- holds the number of bytes to be transmitted
    signal n_bytes              : unsigned (10 downto 0);

    signal running              : std_logic := '0';

    -- Fifo connection
    signal fifo_rst_n       : std_logic;
    signal fifo_write_en    : std_logic;
    signal fifo_data_in     : std_logic_vector (31 downto 0);
    signal fifo_read_en     : std_logic;
    signal fifo_data_out    : std_logic_vector(7 downto 0);
    signal fifo_empty       : std_logic;
    signal fifo_full        : std_logic;
    signal fifo_data_valid  : std_logic;

    -- data in process
    type data_in_state is (IDLE, FRAME, CPLT);
    signal din_cur_state : data_in_state;
    signal din_nex_state : data_in_state;    

begin
    ----------------------------------------------------------------------------
    -- Stores the required data at start
    -- -------------------------------------------------------------------------
    p_init : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                n_bytes  <= (others => '0');
            else
                if start = '1' and running = '0' then
                    n_bytes <= unsigned(size) + 4; -- 4 bytes header + data
                else
                    n_bytes <= n_bytes;
                end if;
            end if;
        end if;
    end process ; -- p_init

    ----------------------------------------------------------------------------
    -- Controlls the counter
    -- 
    -- Increment if AXI stream is ready and data packet generator is running
    -- -------------------------------------------------------------------------
    p_ctr : process ( clk )
    ----------------------------------------------------------------------------
    begin    
        if rising_edge(clk) then
            if rst_n = '0' then
                ctr <= (others => '0');
            else
                ctr <= ctr;
                if running = '1' then
                    if ctr < 4 then
                        -- if sending header, we can increment if dst is ready
                        if  tx_tready = '1' then
                            ctr <= ctr + 1;
                        end if;
                    else
                        -- if sending data, we can only increment if the fifo has data
                        if s_axis_tvalid = '1' then
                            ctr <= ctr + 1;
                        end if;
                    end if;
                else
                    -- clear counter if not running
                    ctr <= (others => '0');
                end if;
            end if;
        end if;
    end process p_ctr;
    
    
    ----------------------------------------------------------------------------
    -- Next state
    -- -------------------------------------------------------------------------
    p_next_state : process ( clk )
    ----------------------------------------------------------------------------
    begin
        -- nex state set
        if rising_edge(clk) then
            if rst_n = '0' then
                din_cur_state <= IDLE;
            else
                 din_cur_state <= din_nex_state;
            end if;
        end if; 
    end process p_next_state;

    -- -------------------------------------------------------------------------
    p_in_next_state : process ( ctr, running,  din_cur_state, n_bytes, 
        s_axis_tlast, start)
    ----------------------------------------------------------------------------
    begin
        din_nex_state <= din_cur_state;
        case (din_cur_state) is
            when IDLE =>
                if start = '1' then
                    din_nex_state <= FRAME;
                end if;
            when FRAME =>
                if (ctr = (n_bytes-1)) or (s_axis_tlast = '1') then
                    din_nex_state <= CPLT;
                end if;
            when CPLT =>
                din_nex_state <= IDLE;
        end case;
    end process p_in_next_state;

    ----------------------------------------------------------------------------
    p_outputs : process( din_cur_state, ctr, size )
    ----------------------------------------------------------------------------
    begin
        s_axis_tready <= '0';
        done  <= '0';
        running <= '0';

        case (din_cur_state) is
            when IDLE =>
            when FRAME =>
                if (ctr-4) < unsigned(size) then
                    s_axis_tready <= '1';
                end if;
                running <= '1';
            when CPLT =>
                done  <= '1';
        end case;
    end process ; -- p_outputs

    ----------------------------------------------------------------------------
    -- Controls the AXI stream output
    -- -------------------------------------------------------------------------
    p_out : process (ctr, running, n_bytes, seq, tcid, size, s_axis_tlast, 
        s_axis_tvalid, s_axis_tdata)
    ----------------------------------------------------------------------------
    begin
        tx_tvalid <= '0';
        tx_tlast <= '0';
        tx_tdata <= (others => '0');

        -- tlast only at last byte
        if (running = '1' and ctr = (n_bytes-1)) or (s_axis_tlast = '1') then
            tx_tlast <= '1';
        end if;

        -- tx_tvalid if sending first 4 bytes or if fifo data is valid
        if running = '1' and ctr < 4 then
            tx_tvalid <= '1';
        elsif running = '1' and ctr < n_bytes then
            tx_tvalid <= s_axis_tvalid;
        end if;

        -- Output data mux
        if ctr = to_unsigned(0, ctr'length) then
            -- tcid
            tx_tdata(7) <= '1';
            tx_tdata(6 downto 0) <= tcid;
        elsif ctr = to_unsigned(1, ctr'length) then
            -- sequence number
            tx_tdata <= seq(23 downto 16);
        elsif ctr = to_unsigned(2, ctr'length) then
            -- sequence number
            tx_tdata <= seq(15 downto 8);
        elsif ctr = to_unsigned(3, ctr'length) then
            -- sequence number
            tx_tdata <= seq(7 downto 0);
        elsif (ctr-4) < unsigned(size) then
            -- actual data output
            tx_tdata <= s_axis_tdata;
        end if;
    end process p_out;

end architecture rtl;