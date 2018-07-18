-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 09:21:20 2017
-- Last update : Wed Jul 18 12:06:14 2018
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

entity uft_top_tb is
    generic (
        -- Set to 1 to simulate a write interruption during AXI master write
        C_WRITE_INTERRUPTION    : std_logic := '1';
        C_WRITE_INTERRUPTION_N  : integer := 4;
        -- Number of clockcycles the AXI transaction takes
        C_AXI_WAIT_TIME         : integer := 10;
        -- Clocks to wait after a write request
        C_WR_WAIT_TIME         : integer := 3;

        CLOCK_FREQ          : integer := 125000000;                         -- freq of data_in_clk -- needed to timout cntr
        ARP_TIMEOUT         : integer := 60;                                    -- ARP response timeout (s)
        ARP_MAX_PKT_TMO : integer := 5;                                 -- # wrong nwk pkts received before set error
        MAX_ARP_ENTRIES     : integer := 255;
        
        -- only treat packages arriving at INCOMMING_PORT as UFT packages
        INCOMMING_PORT : natural := 42042;
        -- Parameters for ip interface to Axi master burst
        FIFO_DEPTH : positive := 366; -- (1464/4)

        C_S_AXI_DATA_WIDTH  : integer   := 32;
        -- Width of S_AXI address bus
        C_S_AXI_ADDR_WIDTH  : integer   := 6
    );
end entity uft_top_tb;

-----------------------------------------------------------

architecture testbench of uft_top_tb is

    function str_to_stdvec(inp: string) return std_logic_vector is
        variable temp: std_logic_vector(inp'range) := (others => 'X');
    begin
        for i in inp'range loop
            if (inp(i) = '1') then
                temp(i) := '1';
            elsif (inp(i) = '0') then
                temp(i) := '0';
            end if;
        end loop;
        return temp;
    end function str_to_stdvec;

    -- Testbench signals
    signal clk     :    std_logic;
    signal rst_n   :    std_logic;

    -- Controll
    -- ---------------------------------------------------------------------
    signal our_ip_address      : STD_LOGIC_VECTOR (31 downto 0);
    signal our_mac_address         : std_logic_vector (47 downto 0);

    -- Receiver
    -- ---------------------------------------------------------------------
    -- Control
    signal udp_rx_start                : std_logic;
    -- Header
    signal udp_rx_hdr_is_valid         : std_logic;
    signal udp_rx_hdr_src_ip_addr      : std_logic_vector (31 downto 0);
    signal udp_rx_hdr_src_port         : std_logic_vector (15 downto 0);
    signal udp_rx_hdr_dst_port         : std_logic_vector (15 downto 0);
    signal udp_rx_hdr_data_length      : std_logic_vector (15 downto 0);
    -- Data
    signal udp_rx_tdata                : std_logic_vector (7 downto 0);
    signal udp_rx_tvalid               : std_logic;
    signal udp_rx_tlast                : std_logic;

    -- Transmitter
    -- ---------------------------------------------------------------------
    -- Control
    signal udp_tx_start                : std_logic;
    signal udp_tx_result               : std_logic_vector (1 downto 0);
    -- Header
    signal udp_tx_hdr_dst_ip_addr      : std_logic_vector (31 downto 0);
    signal udp_tx_hdr_dst_port         : std_logic_vector (15 downto 0);
    signal udp_tx_hdr_src_port         : std_logic_vector (15 downto 0);
    signal udp_tx_hdr_data_length      : std_logic_vector (15 downto 0);
    signal udp_tx_hdr_checksum         : std_logic_vector (15 downto 0);
    -- Data
    signal udp_tx_tvalid               : std_logic;
    signal udp_tx_tlast                : std_logic;
    signal udp_tx_tdata                : std_logic_vector (7 downto 0);
    signal udp_tx_tready               :  std_logic;

    -- RX ports
    -- ---------------------------------------------------------------------
    signal m_axis_tvalid   :    std_logic;
    signal m_axis_tdata    :    std_logic_vector(7 downto 0);
    signal m_axis_tlast    :    std_logic;
    signal m_axis_tready   :    std_logic := '0';

    signal rx_done            :    std_logic;
    signal rx_row_num         :  std_logic_vector(31 downto 0);
    signal rx_row_num_valid   :  std_logic;
    signal rx_row_size        :  std_logic_vector(31 downto 0);
    signal rx_row_size_valid  :  std_logic;

    -- User registers
    signal user_reg0           :   std_logic_vector(31 downto 0);
    signal user_reg1           :   std_logic_vector(31 downto 0);
    signal user_reg2           :   std_logic_vector(31 downto 0);
    signal user_reg3           :   std_logic_vector(31 downto 0);
    signal user_reg4           :   std_logic_vector(31 downto 0);
    signal user_reg5           :   std_logic_vector(31 downto 0);
    signal user_reg6           :   std_logic_vector(31 downto 0);
    signal user_reg7           :   std_logic_vector(31 downto 0);

    -- UFT Tx
    -- -------------------------------------------------------------------------
    signal s_axis_tvalid   :    std_logic;
    signal s_axis_tdata    :    std_logic_vector(7 downto 0);
    signal s_axis_tlast    :    std_logic := '0';
    signal s_axis_tready   :    std_logic := '0';

    signal tx_data_size    : std_logic_vector(31 downto 0) := (others => '0');
    signal tx_row_num      : std_logic_vector (31 downto 0) := (others => '0');
    signal tx_ready        : std_logic;
    signal tx_start        : std_logic := '0';

    -- UDP IP Stack
    -- -------------------------------------------------------------------------
    signal ip_rx_hdr_is_valid         : std_logic;
    signal ip_rx_hdr_protocol         : std_logic_vector (7 downto 0);
    signal ip_rx_hdr_data_length      : STD_LOGIC_VECTOR (15 downto 0);
    signal ip_rx_hdr_src_ip_addr      : STD_LOGIC_VECTOR (31 downto 0);
    signal ip_rx_hdr_num_frame_errors : std_logic_vector (7 downto 0);
    signal ip_rx_hdr_last_error_code  : std_logic_vector (3 downto 0);
    signal ip_rx_hdr_is_broadcast     : std_logic;
    signal reset                      : STD_LOGIC;
    signal clear_arp_cache            : std_logic;
    signal arp_pkt_count              : STD_LOGIC_VECTOR(7 downto 0);
    signal ip_pkt_count               : STD_LOGIC_VECTOR(7 downto 0);
    
    signal mac_tx_tdata               : std_logic_vector(7 downto 0);
    signal mac_tx_tvalid              : std_logic;
    signal mac_tx_tready              : std_logic := '0';
    signal mac_tx_tfirst              : std_logic;
    signal mac_tx_tlast               : std_logic;
    signal mac_rx_tdata               : std_logic_vector(7 downto 0);
    signal mac_rx_tvalid              : std_logic;
    signal mac_rx_tready              : std_logic;
    signal mac_rx_tlast               : std_logic;

    -- debug
    constant clk_period : time := 8 ns;
    signal stop_sim  : std_logic := '0';
    signal cur_test : natural := 0;

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

    RESET_GEN_UDP : process
    begin
        reset <= '1',
                 '0' after 20.0*clk_period;
        wait;
    end process RESET_GEN_UDP;

    -- Settings
    -- -------------------------------------------------------------------------
    our_ip_address <= x"c0a80509";      -- 192.168.5.9
    our_mac_address <= x"002320212223"; 

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;
        ------------------------------------------------------------------------
        -- Sends a file via axi stream
        -- Data in file must be 1 byte per line, hex without 0x
        -- ---------------------------------------------------------------------
        procedure file2axistream ( fname : in string ) is
        ------------------------------------------------------------------------
            file fd             : text;
            variable iline      : line;
            variable byte       : std_logic_vector(7 downto 0);
            variable nbytes     : integer := 0;
        begin
            file_open(fd, fname, read_mode);
            -- Count numbers of bytes in file
            while not endfile(fd) loop
                readline (fd, iline);
                nbytes := nbytes + 1;
            end loop;
            file_close(fd);
            file_open(fd, fname, read_mode);
            mac_rx_tlast <= '0';
            -- output the bytes to the axi stream
            while not endfile(fd) loop
                if mac_rx_tready = '1' then
                    mac_rx_tvalid <= '1';
                    if nbytes = 1 then mac_rx_tlast <= '1'; end if;
                    readline (fd, iline);
                    hread(iline,byte);
                    mac_rx_tdata <= byte;
                    nbytes := nbytes - 1;
                end if;
                waitfor(1);
            end loop;
            mac_rx_tvalid <= '0';
            mac_rx_tlast <= '0';
            waitfor(1);
        end procedure file2axistream;
        -------------------------------------------------------------------

        -------------------------------------------------------------------
        procedure t1 is
        -------------------------------------------------------------------
        begin
            cur_test <= 1;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 1 -- UFT Command Packet reception";
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_0c_nseq_1.txt");

            waitfor(10);
        end procedure t1;

        -------------------------------------------------------------------
        procedure t2 is
        -------------------------------------------------------------------
        begin
            cur_test <= 2;
            waitfor(10);
            m_axis_tready <= '1';

            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 2 -- UFT Data Packet reception";
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_0c_nseq_1.txt");
            
            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t2;

        -------------------------------------------------------------------
        procedure t3 is
        -------------------------------------------------------------------
        begin
            cur_test <= 3;
            waitfor(10);

            -- register 2: UFT_REG_RX_BASE

            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 3 -- NSEQ=2 UFT Data Packet reception";
            mac_tx_tready <= '1';
            m_axis_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_09_nseq_2.txt");
            wait for 5 us;
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_09_nseq_2_0.txt");

            wait for 5 us;
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_09_nseq_2_1.txt");
            
            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t3;
        -------------------------------------------------------------------
        -- 32 byte packet
        procedure t4 is
        -------------------------------------------------------------------
        begin
            cur_test <= 4;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 4 -- NSEQ=1 32byte UFT Data Packet reception";
            mac_tx_tready <= '1';
            m_axis_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_0c_nseq_1_v2.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_0c_nseq_1_v2.txt");

            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t4;
        -------------------------------------------------------------------
        -- 31 byte packet
        procedure t5 is
        -------------------------------------------------------------------
        begin
            cur_test <= 5;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 5 -- NSEQ=1 31byte UFT Data Packet reception";
            mac_tx_tready <= '1';
            m_axis_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_0c_nseq_1_31bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_0c_nseq_1_31bytes.txt");

            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t5;
        -------------------------------------------------------------------
        -- 30 byte packet
        procedure t6 is
        -------------------------------------------------------------------
        begin
            cur_test <= 6;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 6 -- NSEQ=1 30byte UFT Data Packet reception";
            mac_tx_tready <= '1';
            m_axis_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_0c_nseq_1_30bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_0c_nseq_1_30bytes.txt");

            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t6;
        -------------------------------------------------------------------
        -- 29 byte packet
        procedure t7 is
        -------------------------------------------------------------------
        begin
            cur_test <= 7;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 7 -- NSEQ=1 29byte UFT Data Packet reception";
            mac_tx_tready <= '1';
            m_axis_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_0c_nseq_1_29bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_0c_nseq_1_29bytes.txt");

            wait until rx_done = '1';
            m_axis_tready <= '0';
        end procedure t7;
        -------------------------------------------------------------------
        procedure t10 is
        -------------------------------------------------------------------
        begin
            cur_test <= 10;
            waitfor(10);
            report "-- TEST 10 -- UFT Data Packet transmission with ARP reply";

            -- get tx_ready
            wait until rising_edge(clk);
            assert tx_ready = '1' report "ERROR: tx_ready not received" severity error;

            tx_data_size <= std_logic_vector(to_unsigned(1025, tx_data_size'length));

            tx_start <= '1';
            mac_tx_tready <= '1';
            s_axis_tvalid <= '1';
            waitfor(1);
            tx_start <= '0';

            -- get tx_ready
            wait until rising_edge(clk);
            assert (tx_ready = '0') report "ERROR: tx_ready not cleared" severity error;

            -- Reply ARP request
            wait until mac_tx_tlast = '1';
            waitfor(5);
            file2axistream("../../cores/uft_stack_v2_0/bench/arp_reply.txt");

            wait until tx_ready = '1';
            s_axis_tvalid <= '0';
        end procedure t10;
        -------------------------------------------------------------------
        procedure t11 is
            variable ctr : natural := 0;
            variable npixels : natural := 0;
        -------------------------------------------------------------------
        begin
            cur_test <= 11;
            waitfor(10);
            report "-- TEST 11 -- Multi Sequence UFT Data Packet transmission";
            
            -- get tx_ready
            wait until rising_edge(clk);
            assert tx_ready = '1' report "ERROR: tx_ready not received" severity error;

            npixels:=3000;
            tx_data_size <= std_logic_vector(to_unsigned(npixels, tx_data_size'length));
            tx_start <= '1';
            mac_tx_tready <= '1';
            waitfor(1);
            tx_start <= '0';

            -- validate tx_ready
            wait until rising_edge(clk);
            assert (tx_ready = '0') report "ERROR: tx_ready not cleared" severity error;

            -- send 971-21+1 bytes
            s_axis_tvalid <= '1';
            lp_send : while ctr /= (npixels-1) loop
                waitfor(1);
                if s_axis_tready = '1' then
                    ctr:=ctr+1;
                end if;
            end loop ; -- lp_send

            s_axis_tlast <= '1';
            waitfor(1);
            s_axis_tlast <= '0';
            s_axis_tvalid <= '0';

            wait until tx_ready = '1';
            s_axis_tvalid <= '0';

        end procedure t11;

        -------------------------------------------------------------------
        procedure t12 is
        -------------------------------------------------------------------
        begin
            cur_test <= 12;
            waitfor(10);
            report "-- TEST 12 -- Single packet 108 byte size send";

            -- get tx_ready
            wait until rising_edge(clk);
            assert tx_ready = '1' report "ERROR: tx_ready not received" severity error;
            
            tx_start <= '1';
            mac_tx_tready <= '1';
            s_axis_tvalid <= '1';
            waitfor(1);
            tx_start <= '0';
            
            wait until tx_ready = '1';
            s_axis_tvalid <= '0';

        end procedure t12;


        -------------------------------------------------------------------
        procedure t20 is
        -------------------------------------------------------------------
        begin
            cur_test <= 20;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 20 -- UFT Command Packet reception with user data";
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_user_0_0xeeeeeeee.txt");

            wait until rising_edge(clk);
            assert (user_reg0 = x"eeeeeeee") report "ERROR: user reg 0 not written" severity error;
            waitfor(10);
        end procedure t20;


        -------------------------------------------------------------------
        procedure t30 is
            variable ctr : natural := 0;
            variable npixels : natural := 0;
        -------------------------------------------------------------------
        begin
            cur_test <= 30;
            waitfor(10);
            report "-- TEST 30 -- Wallis example data exchange with one return packet";
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            -- Send image data to FPGA          
            report "  Send image data to FPGA";  
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_cmd_tcid_09_nseq_2.txt");
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_09_nseq_2_0.txt");
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;
            file2axistream("../../cores/uft_stack_v2_0/bench/uft_data_tcid_09_nseq_2_1.txt");

            -- Send lower count wallis data to PC
            report "  Send lower count wallis data to PC";  
            wait until tx_ready = '1';

            npixels:=971-21+1;
            tx_data_size <= std_logic_vector(to_unsigned(npixels, tx_data_size'length));
            tx_start <= '1';
            mac_tx_tready <= '1';
            waitfor(1);
            tx_start <= '0';

            -- validate tx_ready
            wait until rising_edge(clk);
            assert (tx_ready = '0') report "ERROR: tx_ready not cleared" severity error;

            -- send 971-21+1 bytes
            s_axis_tvalid <= '1';
            lp_send : while ctr /= (npixels-1) loop
                waitfor(1);
                if s_axis_tready = '1' then
                    ctr:=ctr+1;
                end if;
            end loop ; -- lp_send

            s_axis_tlast <= '1';
            waitfor(1);
            s_axis_tlast <= '0';
            s_axis_tvalid <= '0';

            wait until tx_ready = '1';
            
        end procedure t30;

    begin
        waitfor(30);

        ------------
        -- Init
        ------------
        s_axis_tvalid <= '1';
        s_axis_tdata <= "10000001";

        ------------
        -- IMPORTANT: t10 has to be run first because an ARP request/response
        -- is made in this test. If any other is executed first, no ack packets
        -- can be sent.
        ------------

        ------------
        -- UFT packet send: TEST 10 and 11
        ------------
        t10; -- UFT Data Packet transmission with ARP reply
        t11; -- Multi Sequence UFT Data Packet transmission
        t12; -- Single packet 108 byte size send

        ------------
        -- UFT packet receive:
        ------------
        t1; -- UFT Command Packet reception
        t2; -- UFT Data Packet reception
        t3; -- NSEQ=2 UFT Data Packet reception
        t4; -- NSEQ=1 32byte UFT Data Packet reception
        t5; -- NSEQ=1 31byte UFT Data Packet reception
        t6; -- NSEQ=1 30byte UFT Data Packet reception
        t7; -- NSEQ=1 29byte UFT Data Packet reception
        
        ------------
        -- UFT user command packet send
        ------------
        t20;
        
        ------------
        -- Wallis example data exchange
        ------------
        t30;


        waitfor(5);
        stop_sim <= '1';
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Testbench Validation
    -- 
    -- Stores the axi stream data into an output file
    -----------------------------------------------------------
    p_axi_stream_check : process( clk, rst_n )
        type buf is array (0 to 1800) of std_logic_vector (7 downto 0);
        variable axi_buf : buf;
        variable ctr : natural range 0 to 1800 := 0;
        variable i : natural range 0 to 1800 := 0;
        variable fi : natural range 0 to 1800 := 0;

        file file_axi_s     : text;
        variable oline      : line;
    begin
        if rst_n = '0' then
            ctr := 0;
        elsif rising_edge(clk) then
            if mac_tx_tvalid = '1' then
                if mac_tx_tvalid = '1' and mac_tx_tready = '1' then
                    axi_buf(ctr) := mac_tx_tdata;
                    ctr := ctr + 1;
                end if;
                if mac_tx_tlast = '1' then
                    file_open(file_axi_s, "axi_stream_res_" & INTEGER'IMAGE(fi) & ".log", write_mode);
                    report "Start writing file: " & "axi_stream_res_" & INTEGER'IMAGE(fi) & ".log";
                    for i in 0 to (ctr-1) loop
                        hwrite(oline, axi_buf(i), left, 8);
                        writeline(file_axi_s, oline);
                    end loop;
                    file_close(file_axi_s);
                    ctr := 0;
                    fi := fi + 1;
                end if;
            end if;
        end if;
    end process ; -- p_axi_stream_check

    p_axi_rx_stream_check : process( clk, rst_n )
        type buf is array (0 to 1800) of std_logic_vector (7 downto 0);
        variable axi_buf : buf;
        variable ctr : natural range 0 to 1800 := 0;
        variable i : natural range 0 to 1800 := 0;
        variable fi : natural range 0 to 1800 := 0;

        file file_axi_s     : text;
        variable oline      : line;
    begin
        if rst_n = '0' then
            ctr := 0;
        elsif rising_edge(clk) then
            if m_axis_tvalid = '1' then
                if  m_axis_tready = '1' then
                    axi_buf(ctr) := m_axis_tdata;
                    ctr := ctr + 1;
                end if;
                if m_axis_tlast = '1' then
                    file_open(file_axi_s, "axi_rx_stream_res_" & INTEGER'IMAGE(fi) & ".log", write_mode);
                    report "Start writing file: " & "axi_rx_stream_res_" & INTEGER'IMAGE(fi) & ".log";
                    for i in 0 to (ctr-1) loop
                        hwrite(oline, axi_buf(i), left, 8);
                        writeline(file_axi_s, oline);
                    end loop;
                    file_close(file_axi_s);
                    ctr := 0;
                    fi := fi + 1;
                end if;
            end if;
        end if;
    end process ; -- p_axi_stream_check

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    
    DUV : entity work.uft_top
        generic map (
            INCOMMING_PORT     => INCOMMING_PORT,
            FIFO_DEPTH         => FIFO_DEPTH,
            C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            m_axis_tvalid          => m_axis_tvalid,
            m_axis_tdata           => m_axis_tdata,
            m_axis_tlast           => m_axis_tlast,
            m_axis_tready          => m_axis_tready,
            rx_done                => rx_done,
            rx_row_num             => rx_row_num,
            rx_row_num_valid       => rx_row_num_valid,
            rx_row_size            => rx_row_size,
            rx_row_size_valid      => rx_row_size_valid,
            user_reg0              => user_reg0,
            user_reg1              => user_reg1,
            user_reg2              => user_reg2,
            user_reg3              => user_reg3,
            user_reg4              => user_reg4,
            user_reg5              => user_reg5,
            user_reg6              => user_reg6,
            user_reg7              => user_reg7,
            s_axis_tvalid          => s_axis_tvalid,
            s_axis_tlast           => s_axis_tlast,
            s_axis_tdata           => s_axis_tdata,
            s_axis_tready          => s_axis_tready,

            tx_start               => tx_start,
            tx_ready               => tx_ready,
            tx_row_num             => tx_row_num,
            tx_data_size           => tx_data_size,

            udp_rx_start           => udp_rx_start,
            udp_rx_hdr_is_valid    => udp_rx_hdr_is_valid,
            udp_rx_hdr_src_ip_addr => udp_rx_hdr_src_ip_addr,
            udp_rx_hdr_src_port    => udp_rx_hdr_src_port,
            udp_rx_hdr_dst_port    => udp_rx_hdr_dst_port,
            udp_rx_hdr_data_length => udp_rx_hdr_data_length,
            udp_rx_tdata           => udp_rx_tdata,
            udp_rx_tvalid          => udp_rx_tvalid,
            udp_rx_tlast           => udp_rx_tlast,
            udp_tx_start           => udp_tx_start,
            udp_tx_result          => udp_tx_result,
            udp_tx_hdr_dst_ip_addr => udp_tx_hdr_dst_ip_addr,
            udp_tx_hdr_dst_port    => udp_tx_hdr_dst_port,
            udp_tx_hdr_src_port    => udp_tx_hdr_src_port,
            udp_tx_hdr_data_length => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum    => udp_tx_hdr_checksum,
            udp_tx_tvalid          => udp_tx_tvalid,
            udp_tx_tlast           => udp_tx_tlast,
            udp_tx_tdata           => udp_tx_tdata,
            udp_tx_tready          => udp_tx_tready,

            our_ip_address         => our_ip_address,
            our_mac_address        => our_mac_address
        ); 

    UDP_Complete_nomac_1 : entity work.UDP_Complete_nomac
        generic map (
            CLOCK_FREQ      => CLOCK_FREQ,
            ARP_TIMEOUT     => ARP_TIMEOUT,
            ARP_MAX_PKT_TMO => ARP_MAX_PKT_TMO,
            MAX_ARP_ENTRIES => MAX_ARP_ENTRIES
        )
        port map (
            udp_tx_start               => udp_tx_start,
            udp_txi_hdr_dst_ip_addr    => udp_tx_hdr_dst_ip_addr,
            udp_txi_hdr_dst_port       => udp_tx_hdr_dst_port,
            udp_txi_hdr_src_port       => udp_tx_hdr_src_port,
            udp_txi_hdr_data_length    => udp_tx_hdr_data_length,
            udp_txi_hdr_checksum       => udp_tx_hdr_checksum,
            udp_txi_data_out_valid     => udp_tx_tvalid,
            udp_txi_data_out_last      => udp_tx_tlast,
            udp_txi_data_out           => udp_tx_tdata,
            udp_tx_result              => udp_tx_result,
            udp_tx_data_out_ready      => udp_tx_tready,
            udp_rx_start               => udp_rx_start,
            udp_rxo_hdr_is_valid       => udp_rx_hdr_is_valid,
            udp_rxo_hdr_src_ip_addr    => udp_rx_hdr_src_ip_addr,
            udp_rxo_hdr_src_port       => udp_rx_hdr_src_port,
            udp_rxo_hdr_dst_port       => udp_rx_hdr_dst_port,
            udp_rxo_hdr_data_length    => udp_rx_hdr_data_length,
            udp_rxo_data_in            => udp_rx_tdata,
            udp_rxo_data_in_valid      => udp_rx_tvalid,
            udp_rxo_data_in_last       => udp_rx_tlast,
            ip_rx_hdr_is_valid         => ip_rx_hdr_is_valid,
            ip_rx_hdr_protocol         => ip_rx_hdr_protocol,
            ip_rx_hdr_data_length      => ip_rx_hdr_data_length,
            ip_rx_hdr_src_ip_addr      => ip_rx_hdr_src_ip_addr,
            ip_rx_hdr_num_frame_errors => ip_rx_hdr_num_frame_errors,
            ip_rx_hdr_last_error_code  => ip_rx_hdr_last_error_code,
            ip_rx_hdr_is_broadcast     => ip_rx_hdr_is_broadcast,
            rx_clk                     => clk,
            tx_clk                     => clk,
            reset                      => reset,
            our_ip_address             => our_ip_address,
            our_mac_address            => our_mac_address,
            clear_arp_cache            => clear_arp_cache,
            arp_pkt_count              => arp_pkt_count,
            ip_pkt_count               => ip_pkt_count,
            mac_tx_tdata               => mac_tx_tdata,
            mac_tx_tvalid              => mac_tx_tvalid,
            mac_tx_tready              => mac_tx_tready,
            mac_tx_tfirst              => mac_tx_tfirst,
            mac_tx_tlast               => mac_tx_tlast,
            mac_rx_tdata               => mac_rx_tdata,
            mac_rx_tvalid              => mac_rx_tvalid,
            mac_rx_tready              => mac_rx_tready,
            mac_rx_tlast               => mac_rx_tlast
        );    
end architecture testbench;