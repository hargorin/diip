-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_data_assembler_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 15:37:00 2017
-- Last update : Wed Nov 29 11:36:30 2017
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
end entity uft_tx_data_assembler_tb;

-----------------------------------------------------------

architecture testbench of uft_tx_data_assembler_tb is
    component axi_master_burst_model is
        generic (
            C_M_AXI_ADDR_WIDTH     : integer range 32 to 64  := 32;
            C_M_AXI_DATA_WIDTH     : integer range 32 to 256 := 32;
            C_MAX_BURST_LEN        : Integer range 16 to 256 := 16;
            C_ADDR_PIPE_DEPTH      : Integer range 1 to 14   := 1;
            C_NATIVE_DATA_WIDTH    : INTEGER range 32 to 128 := 32;
            C_LENGTH_WIDTH         : INTEGER range 12 to 20  := 12;
            C_FAMILY               : string                  := "virtex7";
            C_WRITE_INTERRUPTION   : std_logic               := '1';
            C_WRITE_INTERRUPTION_N : integer                 := 17;
            C_AXI_WAIT_TIME        : integer                 := 10;
            C_WR_WAIT_TIME         : integer                 := 3
        );
        port (
            m_axi_aclk             : in  std_logic;
            m_axi_aresetn          : in  std_logic;
            ip2bus_mstrd_req       :     In std_logic;
            ip2bus_mstwr_req       :     In std_logic;
            ip2bus_mst_addr        : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
            ip2bus_mst_length      : in  std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
            ip2bus_mst_be          : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mst_type        : in  std_logic;
            ip2bus_mst_lock        :     In std_logic;
            ip2bus_mst_reset       :     In std_logic;
            bus2ip_mst_cmdack      :     Out std_logic;
            bus2ip_mst_cmplt       :     Out std_logic;
            bus2ip_mst_error       :     Out std_logic;
            bus2ip_mst_rearbitrate :     Out std_logic;
            bus2ip_mst_cmd_timeout : out std_logic;
            bus2ip_mstrd_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
            bus2ip_mstrd_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            bus2ip_mstrd_sof_n     :     Out std_logic;
            bus2ip_mstrd_eof_n     :     Out std_logic;
            bus2ip_mstrd_src_rdy_n :     Out std_logic;
            bus2ip_mstrd_src_dsc_n :     Out std_logic;
            ip2bus_mstrd_dst_rdy_n :     In std_logic;
            ip2bus_mstrd_dst_dsc_n :     In std_logic;
            ip2bus_mstwr_d         :     In std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
            ip2bus_mstwr_rem       :     In std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mstwr_sof_n     :     In std_logic;
            ip2bus_mstwr_eof_n     :     In std_logic;
            ip2bus_mstwr_src_rdy_n :     In std_logic;
            ip2bus_mstwr_src_dsc_n :     In std_logic;
            bus2ip_mstwr_dst_rdy_n :     Out std_logic;
            bus2ip_mstwr_dst_dsc_n :     Out std_logic
        );
    end component axi_master_burst_model;    

    -- Testbench signals
    signal clk                    : std_logic;
    signal rst_n                  : std_logic;
    signal data_src_addr          : std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal tcid                   : std_logic_vector (6 downto 0);
    signal seq                    : std_logic_vector (23 downto 0);
    signal size                   : std_logic_vector (10 downto 0);
    signal start                  : std_logic;
    signal done                   : std_logic;
    signal ip2bus_mstrd_req       : std_logic;
    signal ip2bus_mstwr_req       : std_logic;
    signal ip2bus_mst_addr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal ip2bus_mst_length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
    signal ip2bus_mst_be          : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal ip2bus_mst_type        : std_logic;
    signal ip2bus_mst_lock        : std_logic;
    signal ip2bus_mst_reset       : std_logic;
    signal bus2ip_mst_cmdack      : std_logic;
    signal bus2ip_mst_cmplt       : std_logic;
    signal bus2ip_mst_error       : std_logic;
    signal bus2ip_mst_rearbitrate : std_logic;
    signal bus2ip_mst_cmd_timeout : std_logic;
    signal bus2ip_mstrd_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
    signal bus2ip_mstrd_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal bus2ip_mstrd_sof_n     : std_logic;
    signal bus2ip_mstrd_eof_n     : std_logic;
    signal bus2ip_mstrd_src_rdy_n : std_logic;
    signal bus2ip_mstrd_src_dsc_n : std_logic;
    signal ip2bus_mstrd_dst_rdy_n : std_logic;
    signal ip2bus_mstrd_dst_dsc_n : std_logic;
    signal ip2bus_mstwr_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
    signal ip2bus_mstwr_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal ip2bus_mstwr_sof_n     : std_logic;
    signal ip2bus_mstwr_eof_n     : std_logic;
    signal ip2bus_mstwr_src_rdy_n : std_logic;
    signal ip2bus_mstwr_src_dsc_n : std_logic;
    signal bus2ip_mstwr_dst_rdy_n : std_logic;
    signal bus2ip_mstwr_dst_dsc_n : std_logic;
    signal tx_tvalid              : std_logic;
    signal tx_tlast               : std_logic;
    signal tx_tdata               : std_logic_vector (7 downto 0);
    signal tx_tready              : std_logic;

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
        data_src_addr <= std_logic_vector(to_unsigned(0, data_src_addr'length));
        size <= std_logic_vector(to_unsigned(100, size'length));
        tcid <= std_logic_vector(to_unsigned(0, tcid'length));
        seq <= std_logic_vector(to_unsigned(0, seq'length));
        start <= '0';
        tx_tready <= '0';

        wait for 25*C_CLK_PERIOD;


        ------------------------------------------------------------------------
        -- TEST 1: 100 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 1: 100 byte data transfer";
        start <= '1';
        data_src_addr <= std_logic_vector(to_unsigned(0, data_src_addr'length));
        size <= std_logic_vector(to_unsigned(100, size'length));
        tcid <= std_logic_vector(to_unsigned(42, tcid'length));
        seq <= std_logic_vector(to_unsigned(1, seq'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        start <= '0';
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;


        ------------------------------------------------------------------------
        -- TEST 2: 99 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 2: 99 byte data transfer";
        start <= '1';
        data_src_addr <= x"08000000";
        size <= std_logic_vector(to_unsigned(99, size'length));
        tcid <= std_logic_vector(to_unsigned(13, tcid'length));
        seq <= std_logic_vector(to_unsigned(2, seq'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        start <= '0';
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;

        
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
                report integer'image(ctr);
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
    DUT : entity work.uft_tx_data_assembler
        generic map (
            C_M_AXI_ADDR_WIDTH  => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH  => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN     => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH   => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_FAMILY            => C_FAMILY
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            data_src_addr          => data_src_addr,
            tcid                   => tcid,
            seq                    => seq,
            size                   => size,
            start                  => start,
            done                   => done,
            ip2bus_mstrd_req       => ip2bus_mstrd_req,
            ip2bus_mstwr_req       => ip2bus_mstwr_req,
            ip2bus_mst_addr        => ip2bus_mst_addr,
            ip2bus_mst_length      => ip2bus_mst_length,
            ip2bus_mst_be          => ip2bus_mst_be,
            ip2bus_mst_type        => ip2bus_mst_type,
            ip2bus_mst_lock        => ip2bus_mst_lock,
            ip2bus_mst_reset       => ip2bus_mst_reset,
            bus2ip_mst_cmdack      => bus2ip_mst_cmdack,
            bus2ip_mst_cmplt       => bus2ip_mst_cmplt,
            bus2ip_mst_error       => bus2ip_mst_error,
            bus2ip_mst_rearbitrate => bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d         => bus2ip_mstrd_d,
            bus2ip_mstrd_rem       => bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n     => bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => ip2bus_mstwr_d,
            ip2bus_mstwr_rem       => ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n     => ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_mstwr_dst_dsc_n,
            tx_tvalid              => tx_tvalid,
            tx_tlast               => tx_tlast,
            tx_tdata               => tx_tdata,
            tx_tready              => tx_tready
        );
    axi_master_burst_model_1 : axi_master_burst_model
        generic map (
            C_M_AXI_ADDR_WIDTH     => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH     => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN        => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH      => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH    => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_FAMILY               => C_FAMILY
        )
        port map (
            m_axi_aclk             => clk,
            m_axi_aresetn          => rst_n,
            ip2bus_mstrd_req       => ip2bus_mstrd_req,
            ip2bus_mstwr_req       => ip2bus_mstwr_req,
            ip2bus_mst_addr        => ip2bus_mst_addr,
            ip2bus_mst_length      => ip2bus_mst_length,
            ip2bus_mst_be          => ip2bus_mst_be,
            ip2bus_mst_type        => ip2bus_mst_type,
            ip2bus_mst_lock        => ip2bus_mst_lock,
            ip2bus_mst_reset       => ip2bus_mst_reset,
            bus2ip_mst_cmdack      => bus2ip_mst_cmdack,
            bus2ip_mst_cmplt       => bus2ip_mst_cmplt,
            bus2ip_mst_error       => bus2ip_mst_error,
            bus2ip_mst_rearbitrate => bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d         => bus2ip_mstrd_d,
            bus2ip_mstrd_rem       => bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n     => bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => ip2bus_mstwr_d,
            ip2bus_mstwr_rem       => ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n     => ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_mstwr_dst_dsc_n
        );    

end architecture testbench;