-------------------------------------------------------------------------------
-- Title       : AXI Master Burst Model
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : axi_master_burst_model.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Nov  9 08:13:36 2017
-- Last update : Mon Apr 23 13:07:18 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Model the interface to the axi_master_burst controller
-- to use in simulation
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_master_burst_model is
    generic (
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "virtex7";

        -- Set to 1 to simulate a write interruption during AXI master write
        C_WRITE_INTERRUPTION    : std_logic := '1';
        C_WRITE_INTERRUPTION_N  : integer := 4;
        -- Number of clockcycles the AXI transaction takes
        C_AXI_WAIT_TIME         : integer := 10;
        -- Clocks to wait after a write request
        C_WR_WAIT_TIME         : integer := 3
    );
    port (
        m_axi_aclk             : in  std_logic;
        m_axi_aresetn          : in  std_logic;

        ip2bus_mstrd_req       : In     std_logic;
        ip2bus_mstwr_req       : In     std_logic;
        ip2bus_mst_addr        : in     std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
        ip2bus_mst_length      : in     std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
        ip2bus_mst_be          : in     std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mst_type        : in     std_logic;
        ip2bus_mst_lock        : In     std_logic;
        ip2bus_mst_reset       : In     std_logic;
        bus2ip_mst_cmdack      : Out    std_logic;
        bus2ip_mst_cmplt       : Out    std_logic;
        bus2ip_mst_error       : Out    std_logic;
        bus2ip_mst_rearbitrate : Out    std_logic;
        bus2ip_mst_cmd_timeout : out    std_logic;
        bus2ip_mstrd_d         : out    std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
        bus2ip_mstrd_rem       : out    std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        bus2ip_mstrd_sof_n     : Out    std_logic;
        bus2ip_mstrd_eof_n     : Out    std_logic;
        bus2ip_mstrd_src_rdy_n : Out    std_logic;
        bus2ip_mstrd_src_dsc_n : Out    std_logic;
        ip2bus_mstrd_dst_rdy_n : In     std_logic;
        ip2bus_mstrd_dst_dsc_n : In     std_logic;
        ip2bus_mstwr_d         : In     std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
        ip2bus_mstwr_rem       : In     std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mstwr_sof_n     : In     std_logic;
        ip2bus_mstwr_eof_n     : In     std_logic;
        ip2bus_mstwr_src_rdy_n : In     std_logic;
        ip2bus_mstwr_src_dsc_n : In     std_logic;
        bus2ip_mstwr_dst_rdy_n : Out    std_logic;
        bus2ip_mstwr_dst_dsc_n : Out    std_logic
    );
end entity axi_master_burst_model;

architecture behav of axi_master_burst_model is
    -- types
    type state_type is ( IDLE, 
        SGL_BEAT_RD_START, SGL_BEAT_RD_AXI, SGL_BEAT_RD_CPLT, 
        SGL_BEAT_WR_START, SGL_BEAT_WR_WAIT, SGL_BEAT_WR_DST_RDY, SGL_BEAT_WR_AXI, SGL_BEAT_WR_CPLT,
        BURST_RD_START, BURST_RD_AXI, BURST_RD_SOF, BURST_RD_T1, BURST_RD_INT, BURST_RD_T2,
            BURST_RD_EOF, BURST_RD_END, BURST_RD_CPLT,
        BURST_WR_START, BURST_WR_WAIT, BURST_WR_SOF, BURST_WR_T1, 
            BURST_WR_INT, BURST_WR_T2, BURST_WR_EOF, BURST_WR_END, BURST_WR_ERROR, BURST_WR_CPLT);
    type count_mode_type is (RST, INCR, HOLD);

    signal current_state : state_type;
    signal next_state : state_type;

    signal count_mode        : count_mode_type;
    signal ctr               : unsigned (15 downto 0);

    signal data_count_mode        : count_mode_type;
    signal data_ctr               : unsigned (15 downto 0);

    signal data_len : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
begin
    ----------------------------------------------------------------------------
    p_tx_proc_clocked : process( m_axi_aclk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(m_axi_aclk) then
            if m_axi_aresetn = '0' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process ; -- p_tx_proc


    p_nex_state : process ( ip2bus_mstrd_req, ip2bus_mstwr_req, ip2bus_mst_addr, ip2bus_mst_length, 
        ip2bus_mst_be, ip2bus_mst_type, ip2bus_mst_lock, ip2bus_mst_reset, 
        ip2bus_mstrd_dst_rdy_n, ip2bus_mstrd_dst_dsc_n, ip2bus_mstwr_d, 
        ip2bus_mstwr_rem, ip2bus_mstwr_sof_n, ip2bus_mstwr_eof_n, 
        ip2bus_mstwr_src_rdy_n, ip2bus_mstwr_src_dsc_n,
        current_state, ctr, data_ctr )
    begin
        case current_state is
            when IDLE =>
                if (ip2bus_mstrd_req = '1') AND 
                    (ip2bus_mst_type = '0') AND 
                    (ip2bus_mstrd_dst_rdy_n = '0') then
                    next_state <= SGL_BEAT_RD_START;
                elsif   (ip2bus_mstwr_req = '1') AND 
                        (ip2bus_mst_type = '0') AND 
                        (ip2bus_mstwr_sof_n = '0') AND 
                        (ip2bus_mstwr_eof_n = '0') AND 
                        (ip2bus_mstwr_src_rdy_n = '0') then
                    next_state <= SGL_BEAT_WR_START;
                elsif   (ip2bus_mstrd_req = '1') AND 
                        (ip2bus_mst_type = '1') AND 
                        (ip2bus_mstrd_dst_rdy_n = '0') then
                    next_state <= BURST_RD_START;
                elsif   (ip2bus_mstwr_req = '1') AND 
                        (ip2bus_mst_type = '1') AND 
                        (ip2bus_mstwr_sof_n = '0') AND 
                        (ip2bus_mstwr_src_rdy_n = '0') then
                    next_state <= BURST_WR_START;
                else
                    next_state <= current_state;
                end if;
            -- Single Beat Read
            when SGL_BEAT_RD_START =>
                next_state <= SGL_BEAT_RD_AXI;
            when SGL_BEAT_RD_AXI =>
                if ctr = to_unsigned(C_AXI_WAIT_TIME, ctr'length) then
                    next_state <= SGL_BEAT_RD_CPLT;
                else
                    next_state <= SGL_BEAT_RD_AXI;
                end if;
            when SGL_BEAT_RD_CPLT =>
                next_state <= IDLE;
            -- Single Beat write
            when SGL_BEAT_WR_START =>
                next_state <= SGL_BEAT_WR_WAIT;
            when SGL_BEAT_WR_WAIT =>
                if ctr = to_unsigned(C_WR_WAIT_TIME, ctr'length) then
                    next_state <= SGL_BEAT_WR_DST_RDY;
                else
                    next_state <= SGL_BEAT_WR_WAIT;
                end if;
            when SGL_BEAT_WR_DST_RDY =>
                next_state <= SGL_BEAT_WR_AXI;
            when SGL_BEAT_WR_AXI =>
                if ctr = to_unsigned(C_AXI_WAIT_TIME, ctr'length) then
                    next_state <= SGL_BEAT_WR_CPLT;
                else
                    next_state <= SGL_BEAT_WR_AXI;
                end if;
            when SGL_BEAT_WR_CPLT =>
                next_state <= IDLE;
            -- Burst Read
            when BURST_RD_START => 
                next_state <= BURST_RD_AXI;
            when BURST_RD_AXI =>
                if unsigned(data_len) < 2 then
                    next_state <= SGL_BEAT_RD_AXI;
                elsif ctr = to_unsigned(C_AXI_WAIT_TIME, ctr'length) then
                    next_state <= BURST_RD_SOF;
                else
                    next_state <= BURST_RD_AXI;
                end if;
            when BURST_RD_SOF =>
                if unsigned(data_len) = 2 then
                    next_state <= BURST_RD_EOF;
                else
                    next_state <= BURST_RD_T1;
                end if;
            when BURST_RD_T1 =>
                next_state <= BURST_RD_INT;
            when BURST_RD_INT =>
                if ctr = (to_unsigned(C_WRITE_INTERRUPTION_N, ctr'length)-1) then
                    next_state <= BURST_RD_T2;
                else
                    next_state <= BURST_RD_INT;
                end if;
            when BURST_RD_T2 =>
                if data_ctr = (unsigned(data_len)-2) then
                    next_state <= BURST_RD_EOF;
                else
                    next_state <= BURST_RD_T2;
                end if;
            when BURST_RD_EOF =>
                next_state <= BURST_RD_END;
            when BURST_RD_END =>
                next_state <= BURST_RD_CPLT;
            when BURST_RD_CPLT =>
                next_state <= IDLE;
            -- Burst Write
            when BURST_WR_START =>
                next_state <= BURST_WR_WAIT;
            when BURST_WR_WAIT =>
                if unsigned(data_len) < 2 then
                    next_state <= SGL_BEAT_WR_WAIT;
                else
                    next_state <= BURST_WR_SOF;
                end if;
            when BURST_WR_SOF =>
                if unsigned(data_len) = 2 then
                    next_state <= BURST_WR_EOF;
                else
                    next_state <= BURST_WR_T1;
                end if;
            when BURST_WR_T1 =>
                next_state <= BURST_WR_INT;
            when BURST_WR_INT =>
                if ctr = (to_unsigned(C_WRITE_INTERRUPTION_N, ctr'length)-1) then
                    next_state <= BURST_WR_T2;
                else
                    next_state <= BURST_WR_INT;
                end if;
            when BURST_WR_T2 =>
                if data_ctr = (unsigned(data_len)-1) then
                    next_state <= BURST_WR_EOF;
                else
                    next_state <= BURST_WR_T2;
                end if;
            when BURST_WR_EOF =>
                if ip2bus_mstwr_eof_n = '0' then
                    next_state <= BURST_WR_END;
                else
                    next_state <= BURST_WR_ERROR;
                end if;
            when BURST_WR_END =>
                next_state <= BURST_WR_CPLT;
            when BURST_WR_CPLT =>
                next_state <= IDLE;
            when BURST_WR_ERROR => 
                next_state <= BURST_WR_ERROR;
        end case;
    end process;

    p_out : process ( current_state )
    begin
        case current_state is
            when burst_wr_error => 
            when IDLE =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                data_count_mode <= RST;
                count_mode <= RST;
            -- Single Beat Read
            when SGL_BEAT_RD_START =>
                bus2ip_mst_cmdack <= '1';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when SGL_BEAT_RD_AXI =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= RST;
            when SGL_BEAT_RD_CPLT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '1';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '0';
                bus2ip_mstrd_eof_n <= '0';
                bus2ip_mstrd_src_rdy_n <= '0';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            -- Single Beat write
            when SGL_BEAT_WR_START =>
                bus2ip_mst_cmdack <= '1';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when SGL_BEAT_WR_WAIT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= RST;
            when SGL_BEAT_WR_DST_RDY =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '0';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when SGL_BEAT_WR_AXI =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= RST;
            when SGL_BEAT_WR_CPLT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '1';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            -- Burst Read
            when BURST_RD_START => 
                bus2ip_mst_cmdack <= '1';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= HOLD;
            when BURST_RD_AXI =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= HOLD;
            when BURST_RD_SOF =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
                --bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '0';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '0';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_RD_T1 =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
                --bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '0';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_RD_INT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
                --bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= HOLD;
            when BURST_RD_T2 =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
                --bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '0';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_RD_EOF =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
                --bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '0';
                bus2ip_mstrd_src_rdy_n <= '0';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= HOLD;
            when BURST_RD_END =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when BURST_RD_CPLT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '1';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            -- Burst Write
            when BURST_WR_START =>
                bus2ip_mst_cmdack <= '1';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when BURST_WR_WAIT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= RST;
            when BURST_WR_SOF =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '0';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_WR_T1 =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '0';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_WR_INT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= INCR;
                data_count_mode <= HOLD;
            when BURST_WR_T2 =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '0';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= INCR;
            when BURST_WR_EOF =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '0';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= HOLD;
            when BURST_WR_END =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '0';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
            when BURST_WR_CPLT =>
                bus2ip_mst_cmdack <= '0';
                bus2ip_mst_cmplt <= '1';
                bus2ip_mst_error <= '0';
                bus2ip_mst_rearbitrate <= '0';
                bus2ip_mst_cmd_timeout <= '0';
                --bus2ip_mstrd_d <= (others => '0');
                bus2ip_mstrd_rem <= (others => '0');
                bus2ip_mstrd_sof_n <= '1';
                bus2ip_mstrd_eof_n <= '1';
                bus2ip_mstrd_src_rdy_n <= '1';
                bus2ip_mstrd_src_dsc_n <= '1';
                bus2ip_mstwr_dst_rdy_n <= '1';
                bus2ip_mstwr_dst_dsc_n <= '1';
                count_mode <= RST;
                data_count_mode <= RST;
        end case;
    end process;

    -- output some fake data
    bus2ip_mstrd_d(data_ctr'length-1 downto 0) <= std_logic_vector(data_ctr);
    bus2ip_mstrd_d(bus2ip_mstrd_d'length-1 downto data_ctr'length) <= (others => '0');

    -- store data len
    p_data_len : process (m_axi_aclk, m_axi_aresetn, current_state, ip2bus_mst_length)
    begin
        if m_axi_aresetn = '0' then
            data_len <= (others  => '0');
        elsif rising_edge(m_axi_aclk) then
            -- tx_count processing
            case current_state is
                when BURST_RD_START  =>    
                    if ip2bus_mst_length(1 downto 0) = "00" then
                        data_len <= std_logic_vector(shift_right(unsigned(ip2bus_mst_length) , 2));
                    else
                        data_len <= std_logic_vector(shift_right(unsigned(ip2bus_mst_length) , 2) + 1);
                    end if;
                when BURST_WR_START  =>
                    if ip2bus_mst_length(1 downto 0) = "00" then
                        data_len <= std_logic_vector(shift_right(unsigned(ip2bus_mst_length) , 2));
                    else
                        data_len <= std_logic_vector(shift_right(unsigned(ip2bus_mst_length) , 2) + 1);
                    end if;
                when others  => data_len <= data_len;
            end case;
        end if;
    end process p_data_len;

    p_ctr : process ( m_axi_aclk )
    begin
        if rising_edge(m_axi_aclk) then
            -- tx_count processing
            case count_mode is
                when RST  =>    ctr <= x"0000";
                when INCR =>    ctr <= ctr + 1;
                when HOLD =>    ctr <= ctr;
            end case;
        end if;
    end process p_ctr;

    p_data_ctr : process ( m_axi_aclk )
    begin
        if rising_edge(m_axi_aclk) then
            -- tx_count processing
            case data_count_mode is
                when RST  =>    data_ctr <= x"0000";
                when INCR =>    data_ctr <= data_ctr + 1;
                when HOLD =>    data_ctr <= data_ctr;
            end case;
        end if;
    end process p_data_ctr;
    
end architecture behav;

