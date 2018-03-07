-------------------------------------------------------------------------------
-- Title       : UFT Tx Data packet assembler
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_data_assembler.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 15:13:40 2017
-- Last update : Sat Dec  2 11:26:09 2017
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
    generic (
        -- AXI Master burst Configuration
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "artix7"
    );
    port (
        -- clk and reset
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Data source address
        data_src_addr   : in  std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
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

        -- TX Memory IP Interface
        -- ---------------------------------------------------------------------
        ip2bus_mstrd_req       : out std_logic;
        ip2bus_mstwr_req       : out std_logic;
        ip2bus_mst_addr        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
        ip2bus_mst_length      : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
        ip2bus_mst_be          : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mst_type        : out std_logic;
        ip2bus_mst_lock        : out std_logic;
        ip2bus_mst_reset       : out std_logic;
        bus2ip_mst_cmdack      : in  std_logic;
        bus2ip_mst_cmplt       : in  std_logic;
        bus2ip_mst_error       : in  std_logic;
        bus2ip_mst_rearbitrate : in  std_logic;
        bus2ip_mst_cmd_timeout : in  std_logic;
        bus2ip_mstrd_d         : in  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
        bus2ip_mstrd_rem       : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        bus2ip_mstrd_sof_n     : in  std_logic;
        bus2ip_mstrd_eof_n     : in  std_logic;
        bus2ip_mstrd_src_rdy_n : in  std_logic;
        bus2ip_mstrd_src_dsc_n : in  std_logic;
        ip2bus_mstrd_dst_rdy_n : out std_logic;
        ip2bus_mstrd_dst_dsc_n : out std_logic;
        ip2bus_mstwr_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
        ip2bus_mstwr_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mstwr_sof_n     : out std_logic;
        ip2bus_mstwr_eof_n     : out std_logic;
        ip2bus_mstwr_src_rdy_n : out std_logic;
        ip2bus_mstwr_src_dsc_n : out std_logic;
        bus2ip_mstwr_dst_rdy_n : in  std_logic;
        bus2ip_mstwr_dst_dsc_n : in  std_logic;

        -- Output AXI stream
        -- ---------------------------------------------------------------------
        tx_tvalid               : out std_logic;
        tx_tlast                : out std_logic;
        tx_tdata                : out std_logic_vector (7 downto 0);
        tx_tready               : in  std_logic
    );
end entity uft_tx_data_assembler;   

architecture rtl of uft_tx_data_assembler is
    component fifo_32i_8o is
        generic (
        constant FIFO_DEPTH : positive := 256
            );
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            write_en : in  std_logic;
            data_in  : in  std_logic_vector (31 downto 0);
            read_en  : in  std_logic;
            data_out : out std_logic_vector(7 downto 0);
            empty    : out std_logic;
            full     : out std_logic
        );
    end component fifo_32i_8o;    

    -- counts from 0 to 1464 indicating the data packet byte
    signal ctr               : unsigned (10 downto 0);
    -- holds the last read data from the memory
    signal data_int             : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
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
    type data_in_state is (IDLE, RD_REQ, SOF, FRAME, EOF, CPLT);
    signal din_cur_state : data_in_state;
    signal din_nex_state : data_in_state;    

begin
    ----------------------------------------------------------------------------
    -- Stores the required data at start
    -- -------------------------------------------------------------------------
    p_init : process( clk, rst_n )
    ----------------------------------------------------------------------------
    begin
        if rst_n = '0' then
            n_bytes  <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' and running = '0' then
                n_bytes <= unsigned(size) + 4; -- 4 bytes header + data
            else
                n_bytes <= n_bytes;
            end if;
        end if;
    end process ; -- p_init

    ----------------------------------------------------------------------------
    -- Enable process
    p_en : process (clk, rst_n)
    ----------------------------------------------------------------------------
    begin    
        if rst_n = '0' then
            running <= '0';
            done <= '0';
        elsif rising_edge(clk) then
            done <= '0';

            if start = '1' and running = '0' then
                running <= '1';
            elsif ctr = (n_bytes-1) then
                running <= '0';
                done <= '1';
            else
                running <= running;
            end if;
        end if;
                
    end process p_en;

    ----------------------------------------------------------------------------
    -- Controlls the counter
    -- 
    -- Increment if AXI stream is ready and data packet generator is running
    -- -------------------------------------------------------------------------
    p_ctr : process (clk, rst_n)
    ----------------------------------------------------------------------------
    begin    
        if rst_n = '0' then
            ctr <= (others => '0');
        elsif rising_edge(clk) then
            ctr <= ctr;
            if running = '1' then
                if ctr < 4 then
                    -- if sending header, we can increment if dst is ready
                    if  tx_tready = '1' then
                        ctr <= ctr + 1;
                    end if;
                else
                    -- if sending data, we can only increment if the fifo has data
                    if fifo_empty = '0' then
                        ctr <= ctr + 1;
                        end if;
                end if;
            else
                -- clear counter if not running
                ctr <= (others => '0');
            end if;
        end if;
    end process p_ctr;
    
    
    ----------------------------------------------------------------------------
    -- Controls the AXI Master burst data read
    -- 
    -- Reads the required number of bytes into the FIFO
    -- -------------------------------------------------------------------------
    p_in_nex : process (clk, rst_n)
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
    end process p_in_nex;
    -- -------------------------------------------------------------------------
    p_in_next_state : process ( running, bus2ip_mst_cmdack,
        bus2ip_mstrd_sof_n, bus2ip_mstrd_eof_n, bus2ip_mst_cmplt, din_cur_state)
    ----------------------------------------------------------------------------
    begin
        din_nex_state <= din_cur_state;
        case (din_cur_state) is
            when IDLE =>
                if running = '1' then
                    din_nex_state <= RD_REQ;
                end if;
            when RD_REQ =>
                if bus2ip_mst_cmdack = '1' then
                    din_nex_state <= SOF;
                end if;
            when SOF =>
                if bus2ip_mstrd_sof_n = '0' and bus2ip_mstrd_eof_n = '0' and bus2ip_mst_cmplt = '1' then
                    din_nex_state <= CPLT;
                elsif bus2ip_mstrd_sof_n = '0' and bus2ip_mstrd_eof_n = '0' then
                    din_nex_state <= EOF;
                elsif bus2ip_mstrd_sof_n = '0' then
                    din_nex_state <= FRAME;
                end if;
            when FRAME =>
                if bus2ip_mstrd_eof_n = '0' then
                    din_nex_state <= EOF;
                end if;
            when EOF =>
                if bus2ip_mst_cmplt = '1' then
                    din_nex_state <= CPLT;
                end if;
            when CPLT =>
                if running = '0' then
                    din_nex_state <= IDLE;
                end if;
        end case;
    end process p_in_next_state;
    ----------------------------------------------------------------------------
    p_in_outs : process( din_cur_state )
    ----------------------------------------------------------------------------
    begin
        ip2bus_mstrd_req        <= '0';
        ip2bus_mstwr_req        <= '0';
        ip2bus_mst_addr         <= data_src_addr;
        ip2bus_mst_length       <= (others => '0');
        ip2bus_mst_length(size'length-1 downto 0) <= size;
        ip2bus_mst_be           <= (others => '1');
        ip2bus_mst_type         <= '1';
        ip2bus_mst_lock         <= '0';
        ip2bus_mst_reset        <= '0';

        ip2bus_mstrd_dst_rdy_n  <= '1';
        ip2bus_mstrd_dst_dsc_n  <= '1';
        ip2bus_mstwr_d          <= (others => '0');
        ip2bus_mstwr_rem        <= (others => '0');
        ip2bus_mstwr_sof_n      <= '1';
        ip2bus_mstwr_eof_n      <= '1';
        ip2bus_mstwr_src_rdy_n  <= '1';
        ip2bus_mstwr_src_dsc_n  <= '1';
        case (din_cur_state) is
            when IDLE =>
            when RD_REQ =>
                ip2bus_mstrd_dst_rdy_n <= '0';
                ip2bus_mstrd_req <= '1';
            when SOF =>
                ip2bus_mstrd_dst_rdy_n <= '0';
            when FRAME =>
                ip2bus_mstrd_dst_rdy_n <= '0';
            when EOF =>
                ip2bus_mstrd_dst_rdy_n <= '0';
            when CPLT =>
        end case;
    end process ; -- p_in_outs

    ----------------------------------------------------------------------------
    -- Connect the FIFO to the AXI data input
    -- -------------------------------------------------------------------------
    fifo_data_in <= bus2ip_mstrd_d;
    -- reset fifo if not running to start from scratch after a data packet is sent
    fifo_rst_n <= '1' when running = '1' else '0';
    -- write if running and axi data is valid
    fifo_write_en <= '1' when running = '1' and bus2ip_mstrd_src_rdy_n = '0' else '0';
    -- enable read if running, output is data and tx is ready
    fifo_read_en <= '1' when running = '1' and ctr >= 3 and tx_tready = '1' else '0';

    p_fifo_data_valid : process( clk, rst_n )
    begin
        if rst_n = '0' then
            fifo_data_valid <= '0';
        elsif rising_edge(clk) then
            if fifo_empty = '0' then
                fifo_data_valid <= '1';
            else
                fifo_data_valid <= '0';
            end if;
        end if;
    end process ; -- p_fifo_data_valid

    ----------------------------------------------------------------------------
    -- Controls the AXI stream output
    -- -------------------------------------------------------------------------
    --p_out : process (clk, rst_n)
    p_out : process (ctr, running, fifo_data_valid, n_bytes, fifo_data_out, seq,
        tcid, size)
    ----------------------------------------------------------------------------
    begin
        tx_tvalid <= '0';
        tx_tlast <= '0';
        tx_tdata <= (others => '0');

        -- tlast only at last byte
        if running = '1' and ctr = (n_bytes-1) then
            tx_tlast <= '1';
        end if;

        -- tx_tvalid if sending first 4 bytes or if fifo data is valid
        if running = '1' and ctr < 4 then
            tx_tvalid <= '1';
        elsif running = '1' and fifo_data_valid = '1' and ctr < n_bytes then
            tx_tvalid <= '1';
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
            tx_tdata <= fifo_data_out;
        end if;



        --if rst_n = '0' then
        --    tx_tvalid <= '0';
        --    tx_tlast <= '0';
        --    tx_tdata <= (others => '0');
        --elsif rising_edge(clk) then
        --    -- tlast only at last byte
        --    if running = '1' and ctr = (n_bytes-1) then
        --        tx_tlast <= '1';
        --    else
        --        tx_tlast <= '0';
        --    end if;

        --    -- tx_tvalid if sending first 4 bytes or if fifo data is valid
        --    if running = '1' and ctr < 4 then
        --        tx_tvalid <= '1';
        --    elsif running = '1' and fifo_data_valid = '1' and ctr < n_bytes then
        --        tx_tvalid <= '1';
        --    else
        --        tx_tvalid <= '0';
        --    end if;

        --    -- Output data mux
        --    if ctr = to_unsigned(0, ctr'length) then
        --        -- tcid
        --        tx_tdata(7) <= '1';
        --        tx_tdata(6 downto 0) <= tcid;
        --    elsif ctr = to_unsigned(1, ctr'length) then
        --        -- sequence number
        --        tx_tdata <= seq(23 downto 16);
        --    elsif ctr = to_unsigned(2, ctr'length) then
        --        -- sequence number
        --        tx_tdata <= seq(15 downto 8);
        --    elsif ctr = to_unsigned(3, ctr'length) then
        --        -- sequence number
        --        tx_tdata <= seq(7 downto 0);
        --    elsif (ctr-4) < unsigned(size) then
        --        -- actual data output
        --        tx_tdata <= fifo_data_out;
        --    else
        --        tx_tdata <= (others => '0');
        --    end if;
        --end if; 
    end process p_out;

    ----------------------------------------------------------------------------
    -- 32bit in 8bit out fifo declaration
    -- Can store up to 1500 data bytes = 375 data words
    fifo_32i_8o_1 : fifo_32i_8o
    ----------------------------------------------------------------------------
        generic map (
            FIFO_DEPTH => 375
            )
        port map (
            clk      => clk,
            rst_n    => fifo_rst_n,
            write_en => fifo_write_en,
            data_in  => fifo_data_in,
            read_en  => fifo_read_en,
            data_out => fifo_data_out,
            empty    => fifo_empty,
            full     => fifo_full
        );    




end architecture rtl;