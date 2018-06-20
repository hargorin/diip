-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 09:21:20 2017
-- Last update : Wed Jun 20 12:04:22 2018
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
        
        -- AXI Master burst Configuration
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "artix7";

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
    signal rx_done : std_logic;

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

    -- RX Memory IP Interface
    -- ---------------------------------------------------------------------
    signal ip2bus_mstrd_req       : std_logic;
    signal ip2bus_mstwr_req       : std_logic;
    signal ip2bus_mst_addr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal ip2bus_mst_length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
    signal ip2bus_mst_be          : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal ip2bus_mst_type        : std_logic;
    signal ip2bus_mst_lock        : std_logic;
    signal ip2bus_mst_reset       : std_logic;
    signal bus2ip_mst_cmdack      :  std_logic;
    signal bus2ip_mst_cmplt       :  std_logic;
    signal bus2ip_mst_error       :  std_logic;
    signal bus2ip_mst_rearbitrate :  std_logic;
    signal bus2ip_mst_cmd_timeout :  std_logic;
    signal bus2ip_mstrd_d         :  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
    signal bus2ip_mstrd_rem       :  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal bus2ip_mstrd_sof_n     :  std_logic;
    signal bus2ip_mstrd_eof_n     :  std_logic;
    signal bus2ip_mstrd_src_rdy_n :  std_logic;
    signal bus2ip_mstrd_src_dsc_n :  std_logic;
    signal ip2bus_mstrd_dst_rdy_n : std_logic;
    signal ip2bus_mstrd_dst_dsc_n : std_logic;
    signal ip2bus_mstwr_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
    signal ip2bus_mstwr_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal ip2bus_mstwr_sof_n     : std_logic;
    signal ip2bus_mstwr_eof_n     : std_logic;
    signal ip2bus_mstwr_src_rdy_n : std_logic;
    signal ip2bus_mstwr_src_dsc_n : std_logic;
    signal bus2ip_mstwr_dst_rdy_n :  std_logic;
    signal bus2ip_mstwr_dst_dsc_n :  std_logic;
    -- TX Memory IP Interface
    -- ---------------------------------------------------------------------
    signal tx_ip2bus_mstrd_req       : std_logic;
    signal tx_ip2bus_mstwr_req       : std_logic;
    signal tx_ip2bus_mst_addr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal tx_ip2bus_mst_length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
    signal tx_ip2bus_mst_be          : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal tx_ip2bus_mst_type        : std_logic;
    signal tx_ip2bus_mst_lock        : std_logic;
    signal tx_ip2bus_mst_reset       : std_logic;
    signal tx_bus2ip_mst_cmdack      :  std_logic;
    signal tx_bus2ip_mst_cmplt       :  std_logic;
    signal tx_bus2ip_mst_error       :  std_logic;
    signal tx_bus2ip_mst_rearbitrate :  std_logic;
    signal tx_bus2ip_mst_cmd_timeout :  std_logic;
    signal tx_bus2ip_mstrd_d         :  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
    signal tx_bus2ip_mstrd_rem       :  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal tx_bus2ip_mstrd_sof_n     :  std_logic;
    signal tx_bus2ip_mstrd_eof_n     :  std_logic;
    signal tx_bus2ip_mstrd_src_rdy_n :  std_logic;
    signal tx_bus2ip_mstrd_src_dsc_n :  std_logic;
    signal tx_ip2bus_mstrd_dst_rdy_n : std_logic;
    signal tx_ip2bus_mstrd_dst_dsc_n : std_logic;
    signal tx_ip2bus_mstwr_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
    signal tx_ip2bus_mstwr_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
    signal tx_ip2bus_mstwr_sof_n     : std_logic;
    signal tx_ip2bus_mstwr_eof_n     : std_logic;
    signal tx_ip2bus_mstwr_src_rdy_n : std_logic;
    signal tx_ip2bus_mstwr_src_dsc_n : std_logic;
    signal tx_bus2ip_mstwr_dst_rdy_n :  std_logic;
    signal tx_bus2ip_mstwr_dst_dsc_n :  std_logic;


    -- UFT Tx
    -- -------------------------------------------------------------------------
    signal tx_data_size    : std_logic_vector(31 downto 0) := (others => '0');
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

    -- AXI lite
    -- -------------------------------------------------------------------------    
    signal S_AXI_AWADDR    : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_AWPROT    : std_logic_vector(2 downto 0);
    signal S_AXI_AWVALID   : std_logic;
    signal S_AXI_AWREADY   : std_logic;
    signal S_AXI_WDATA : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_WSTRB : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    signal S_AXI_WVALID    : std_logic;
    signal S_AXI_WREADY    : std_logic;
    signal S_AXI_BRESP : std_logic_vector(1 downto 0);
    signal S_AXI_BVALID    : std_logic;
    signal S_AXI_BREADY    : std_logic;
    signal S_AXI_ARADDR    : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_ARPROT    : std_logic_vector(2 downto 0);
    signal S_AXI_ARVALID   : std_logic;
    signal S_AXI_ARREADY   : std_logic;
    signal S_AXI_RDATA : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_RRESP : std_logic_vector(1 downto 0);
    signal S_AXI_RVALID    : std_logic;
    signal S_AXI_RREADY    : std_logic;

    -- debug
    signal rx : std_logic_vector(31 downto 0) := (others => '0');

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
        -- Initiate process which simulates a master wanting to write.
        -------------------------------------------------------------------
        procedure write (
            adr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            dat : std_logic_vector(31 downto 0)
        ) is
        -------------------------------------------------------------------
        begin
            S_AXI_AWADDR <= adr;
            S_AXI_WDATA <= dat;
            S_AXI_AWVALID<='0';
            S_AXI_WVALID<='0';
            S_AXI_BREADY<='0';
            S_AXI_WSTRB <= "1111";
            
            waitfor(1);

            S_AXI_AWVALID<='1';
            S_AXI_WVALID<='1';
            wait until (S_AXI_AWREADY and S_AXI_WREADY) = '1';  --Client ready to read address/data        
            
            S_AXI_BREADY<='1';
            wait until S_AXI_BVALID = '1';  -- Write result valid
            
            assert S_AXI_BRESP = "00" report "AXI data not written" severity failure;
            S_AXI_AWVALID<='0';
            S_AXI_WVALID<='0';
            S_AXI_BREADY<='1';
            
            wait until S_AXI_BVALID = '0';  -- All finished
            S_AXI_BREADY<='0';
            
            S_AXI_AWVALID<='0';
            S_AXI_WVALID<='0';
            S_AXI_BREADY<='0';
        end procedure write;
        -------------------------------------------------------------------

        -------------------------------------------------------------------
        -- Initiate process which simulates a master wanting to read.
        -------------------------------------------------------------------
        procedure read (
            adr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0)
        ) is
        -------------------------------------------------------------------
        begin
            S_AXI_ARADDR <= adr;
            S_AXI_ARVALID<='0';
            S_AXI_RREADY<='0';
            
            waitfor(1);
            
            S_AXI_ARVALID<='1';
            S_AXI_RREADY<='1';
            wait until (S_AXI_ARREADY) = '1';  --Client provided data
            wait until (S_AXI_RVALID) = '1';  --Client provided data
            rx <= S_AXI_RDATA;
            
            assert S_AXI_RRESP = "00" report "AXI data not read" severity failure;
            S_AXI_ARVALID<='0';
            S_AXI_RREADY<='0';

        end procedure read;
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
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_0c_nseq_1.txt");

            waitfor(10);
        end procedure t1;

        -------------------------------------------------------------------
        procedure t2 is
        -------------------------------------------------------------------
        begin
            cur_test <= 2;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 2 -- UFT Data Packet reception";
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_0c_nseq_1.txt");
            
            waitfor(1500);
        end procedure t2;

        -------------------------------------------------------------------
        procedure t3 is
        -------------------------------------------------------------------
        begin
            cur_test <= 3;
            waitfor(10);

            -- register 2: UFT_REG_RX_BASE
            write("001000", x"98752222");

            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 3 -- NSEQ=2 UFT Data Packet reception";
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_09_nseq_2.txt");
            wait for 5 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_09_nseq_2_0.txt");
            
            wait until ip2bus_mstwr_src_rdy_n = '0';
            assert (ip2bus_mst_addr = x"98752222") report "ERROR: UFT rx wrong base adr" severity error;

            wait for 5 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_09_nseq_2_1.txt");
            
            waitfor(1500);
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
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_0c_nseq_1_v2.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_0c_nseq_1_v2.txt");

            waitfor(1500);
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
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_0c_nseq_1_31bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_0c_nseq_1_31bytes.txt");

            waitfor(1500);
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
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_0c_nseq_1_30bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_0c_nseq_1_30bytes.txt");

            waitfor(1500);
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
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_tcid_0c_nseq_1_29bytes.txt");
            wait for 2 us;
            --waitfor(1);
            mac_tx_tready <= '1';
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_data_tcid_0c_nseq_1_29bytes.txt");

            waitfor(1500);
        end procedure t7;
        -------------------------------------------------------------------
        procedure t10 is
        -------------------------------------------------------------------
        begin
            cur_test <= 10;
            waitfor(10);
            report "-- TEST 10 -- UFT Data Packet transmission with ARP reply";

            -- get tx_ready
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000001") report "ERROR: tx_ready not received" severity error;

            --if tx_ready = '0' then
            --    wait until tx_ready = '1';
            --end if;
            --tx_data_size <= std_logic_vector(to_unsigned(1025, tx_data_size'length));

            -- register 5: UFT_REG_TX_SIZE
            write("010100", std_logic_vector(to_unsigned(1025, tx_data_size'length)));

            --tx_start <= '1';
            write("000100", x"00000001");

            mac_tx_tready <= '1';
            waitfor(1);
            tx_start <= '0';

            -- get tx_ready
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000000") report "ERROR: tx_ready not cleared" severity error;

            -- Reply ARP request
            wait until mac_tx_tlast = '1';
            waitfor(5);
            file2axistream("../../cores/uft_stack_v1_0/bench/arp_reply.txt");

            read("000000");
            wait until rising_edge(clk);
            while (rx /= x"00000001") loop
               read("000000");
               wait until rising_edge(clk);
            end loop;
        
            --wait until tx_ready = '1';

        end procedure t10;
        -------------------------------------------------------------------
        procedure t11 is
        -------------------------------------------------------------------
        begin
            cur_test <= 11;
            waitfor(10);
            report "-- TEST 11 -- Multi Sequence UFT Data Packet transmission";
            
            --if tx_ready = '0' then
            --    wait until tx_ready = '1';
            --end if;

            -- get tx_ready
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000001") report "ERROR: tx_ready not received" severity error;

            --tx_data_size <= std_logic_vector(to_unsigned(3000, tx_data_size'length));

            -- register 5: UFT_REG_TX_SIZE
            write("010100", std_logic_vector(to_unsigned(3000, tx_data_size'length)));

            --tx_start <= '1';
            write("000100", x"00000001");

            mac_tx_tready <= '1';
            waitfor(1);
            tx_start <= '0';

            -- Reply ARP request NOT required, should be in cache
            --wait until mac_tx_tlast = '1';
            --waitfor(5);
            --file2axistream("../../cores/uft_stack_v1_0/bench/arp_reply.txt");

            --wait until tx_ready = '1';
            read("000000");
            wait until rising_edge(clk);
            while (rx /= x"00000001") loop
               read("000000");
               wait until rising_edge(clk);
            end loop;

        end procedure t11;

        -------------------------------------------------------------------
        procedure t12 is
        -------------------------------------------------------------------
        begin
            cur_test <= 12;
            waitfor(10);
            report "-- TEST 12 -- Single packet 108 byte size send";

            -- get tx_ready
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000001") report "ERROR: tx_ready not received" severity error;
            
            -- register : UFT_REG_TX_BASE
            write("001100", x"00000000");
            -- register 5: UFT_REG_TX_SIZE
            write("010100", std_logic_vector(to_unsigned(108, tx_data_size'length)));

            --tx_start <= '1';
            write("000100", x"00000001");

            mac_tx_tready <= '1';
            waitfor(1);
            tx_start <= '0';
            
            --wait until tx_ready = '1';
            read("000000");
            wait until rising_edge(clk);
            while (rx /= x"00000001") loop
               read("000000");
               wait until rising_edge(clk);
            end loop;

        end procedure t12;


        -------------------------------------------------------------------
        procedure t20 is
        -------------------------------------------------------------------
        begin
            cur_test <= 1;
            waitfor(10);
            if mac_rx_tready = '0' then
                wait until mac_rx_tready = '1';
            end if;

            report "-- TEST 20 -- UFT Command Packet reception with user data";
            file2axistream("../../cores/uft_stack_v1_0/bench/uft_cmd_user_0_0xeeeeeeee.txt");

            read("100000");
            wait until rising_edge(clk);
            assert (rx = x"eeeeeeee") report "ERROR: user reg 0 not written" severity error;
            waitfor(10);
        end procedure t20;

    begin
        waitfor(30);

        ------------
        -- IMPORTANT: t10 has to be run first because an ARP request/response
        -- is made in this test. If any other is executed first, no ack packets
        -- can be sent.
        ------------

        ------------
        -- UFT packet send: TEST 10 and 11
        ------------
        t10; -- UFT Data Packet transmission with ARP reply
        --t11; -- Multi Sequence UFT Data Packet transmission
        t12; -- Single packet 108 byte size send

        ------------
        -- UFT packet receive:
        ------------
        --t1; -- UFT Command Packet reception
        --t2; -- UFT Data Packet reception
        --t3; -- NSEQ=2 UFT Data Packet reception
        --t4; -- NSEQ=1 32byte UFT Data Packet reception
        --t5; -- NSEQ=1 31byte UFT Data Packet reception
        --t6; -- NSEQ=1 30byte UFT Data Packet reception
        --t7; -- NSEQ=1 29byte UFT Data Packet reception
        
        ------------
        -- UFT user command packet send
        ------------
        --t20;
        --t11;


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
    end process ; -- p_axi_stream_check

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------

    DUV : entity work.uft_top
        generic map (
            INCOMMING_PORT          => INCOMMING_PORT,
            FIFO_DEPTH              => FIFO_DEPTH,
            C_M_AXI_ADDR_WIDTH      => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH      => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN         => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH       => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH     => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH          => C_LENGTH_WIDTH,
            C_FAMILY                => C_FAMILY,
            C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH
        )
        port map (
            clk                       => clk,
            rst_n                     => rst_n,
            our_ip_address            => our_ip_address,
            our_mac_address           => our_mac_address,
            rx_done                   => rx_done,
            udp_rx_start              => udp_rx_start,
            udp_rx_hdr_is_valid       => udp_rx_hdr_is_valid,
            udp_rx_hdr_src_ip_addr    => udp_rx_hdr_src_ip_addr,
            udp_rx_hdr_src_port       => udp_rx_hdr_src_port,
            udp_rx_hdr_dst_port       => udp_rx_hdr_dst_port,
            udp_rx_hdr_data_length    => udp_rx_hdr_data_length,
            udp_rx_tdata              => udp_rx_tdata,
            udp_rx_tvalid             => udp_rx_tvalid,
            udp_rx_tlast              => udp_rx_tlast,
            udp_tx_start              => udp_tx_start,
            udp_tx_result             => udp_tx_result,
            udp_tx_hdr_dst_ip_addr    => udp_tx_hdr_dst_ip_addr,
            udp_tx_hdr_dst_port       => udp_tx_hdr_dst_port,
            udp_tx_hdr_src_port       => udp_tx_hdr_src_port,
            udp_tx_hdr_data_length    => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum       => udp_tx_hdr_checksum,
            udp_tx_tvalid             => udp_tx_tvalid,
            udp_tx_tlast              => udp_tx_tlast,
            udp_tx_tdata              => udp_tx_tdata,
            udp_tx_tready             => udp_tx_tready,
            ip2bus_mstrd_req          => ip2bus_mstrd_req,
            ip2bus_mstwr_req          => ip2bus_mstwr_req,
            ip2bus_mst_addr           => ip2bus_mst_addr,
            ip2bus_mst_length         => ip2bus_mst_length,
            ip2bus_mst_be             => ip2bus_mst_be,
            ip2bus_mst_type           => ip2bus_mst_type,
            ip2bus_mst_lock           => ip2bus_mst_lock,
            ip2bus_mst_reset          => ip2bus_mst_reset,
            bus2ip_mst_cmdack         => bus2ip_mst_cmdack,
            bus2ip_mst_cmplt          => bus2ip_mst_cmplt,
            bus2ip_mst_error          => bus2ip_mst_error,
            bus2ip_mst_rearbitrate    => bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout    => bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d            => bus2ip_mstrd_d,
            bus2ip_mstrd_rem          => bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n        => bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n        => bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n    => bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n    => bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n    => ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n    => ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d            => ip2bus_mstwr_d,
            ip2bus_mstwr_rem          => ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n        => ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n        => ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n    => ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n    => ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n    => bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n    => bus2ip_mstwr_dst_dsc_n,
            tx_ip2bus_mstrd_req       => tx_ip2bus_mstrd_req,
            tx_ip2bus_mstwr_req       => tx_ip2bus_mstwr_req,
            tx_ip2bus_mst_addr        => tx_ip2bus_mst_addr,
            tx_ip2bus_mst_length      => tx_ip2bus_mst_length,
            tx_ip2bus_mst_be          => tx_ip2bus_mst_be,
            tx_ip2bus_mst_type        => tx_ip2bus_mst_type,
            tx_ip2bus_mst_lock        => tx_ip2bus_mst_lock,
            tx_ip2bus_mst_reset       => tx_ip2bus_mst_reset,
            tx_bus2ip_mst_cmdack      => tx_bus2ip_mst_cmdack,
            tx_bus2ip_mst_cmplt       => tx_bus2ip_mst_cmplt,
            tx_bus2ip_mst_error       => tx_bus2ip_mst_error,
            tx_bus2ip_mst_rearbitrate => tx_bus2ip_mst_rearbitrate,
            tx_bus2ip_mst_cmd_timeout => tx_bus2ip_mst_cmd_timeout,
            tx_bus2ip_mstrd_d         => tx_bus2ip_mstrd_d,
            tx_bus2ip_mstrd_rem       => tx_bus2ip_mstrd_rem,
            tx_bus2ip_mstrd_sof_n     => tx_bus2ip_mstrd_sof_n,
            tx_bus2ip_mstrd_eof_n     => tx_bus2ip_mstrd_eof_n,
            tx_bus2ip_mstrd_src_rdy_n => tx_bus2ip_mstrd_src_rdy_n,
            tx_bus2ip_mstrd_src_dsc_n => tx_bus2ip_mstrd_src_dsc_n,
            tx_ip2bus_mstrd_dst_rdy_n => tx_ip2bus_mstrd_dst_rdy_n,
            tx_ip2bus_mstrd_dst_dsc_n => tx_ip2bus_mstrd_dst_dsc_n,
            tx_ip2bus_mstwr_d         => tx_ip2bus_mstwr_d,
            tx_ip2bus_mstwr_rem       => tx_ip2bus_mstwr_rem,
            tx_ip2bus_mstwr_sof_n     => tx_ip2bus_mstwr_sof_n,
            tx_ip2bus_mstwr_eof_n     => tx_ip2bus_mstwr_eof_n,
            tx_ip2bus_mstwr_src_rdy_n => tx_ip2bus_mstwr_src_rdy_n,
            tx_ip2bus_mstwr_src_dsc_n => tx_ip2bus_mstwr_src_dsc_n,
            tx_bus2ip_mstwr_dst_rdy_n => tx_bus2ip_mstwr_dst_rdy_n,
            tx_bus2ip_mstwr_dst_dsc_n => tx_bus2ip_mstwr_dst_dsc_n,
            s_axi_ctrl_aclk           => clk,
            s_axi_ctrl_aresetn        => rst_n,
            s_axi_ctrl_awaddr         => s_axi_awaddr,
            s_axi_ctrl_awprot         => s_axi_awprot,
            s_axi_ctrl_awvalid        => s_axi_awvalid,
            s_axi_ctrl_awready        => s_axi_awready,
            s_axi_ctrl_wdata          => s_axi_wdata,
            s_axi_ctrl_wstrb          => s_axi_wstrb,
            s_axi_ctrl_wvalid         => s_axi_wvalid,
            s_axi_ctrl_wready         => s_axi_wready,
            s_axi_ctrl_bresp          => s_axi_bresp,
            s_axi_ctrl_bvalid         => s_axi_bvalid,
            s_axi_ctrl_bready         => s_axi_bready,
            s_axi_ctrl_araddr         => s_axi_araddr,
            s_axi_ctrl_arprot         => s_axi_arprot,
            s_axi_ctrl_arvalid        => s_axi_arvalid,
            s_axi_ctrl_arready        => s_axi_arready,
            s_axi_ctrl_rdata          => s_axi_rdata,
            s_axi_ctrl_rresp          => s_axi_rresp,
            s_axi_ctrl_rvalid         => s_axi_rvalid,
            s_axi_ctrl_rready         => s_axi_rready
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

    axi_master_burst_model_1 : entity work.axi_master_burst_model
        generic map (
            C_M_AXI_ADDR_WIDTH     => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH     => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN        => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH      => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH    => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_FAMILY               => C_FAMILY,
            C_WRITE_INTERRUPTION   => C_WRITE_INTERRUPTION,
            C_WRITE_INTERRUPTION_N => C_WRITE_INTERRUPTION_N,
            C_AXI_WAIT_TIME        => C_AXI_WAIT_TIME,
            C_WR_WAIT_TIME         => C_WR_WAIT_TIME
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
    axi_master_burst_model_tx : entity work.axi_master_burst_model
        generic map (
            C_M_AXI_ADDR_WIDTH     => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH     => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN        => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH      => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH    => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_FAMILY               => C_FAMILY,
            C_WRITE_INTERRUPTION   => C_WRITE_INTERRUPTION,
            C_WRITE_INTERRUPTION_N => C_WRITE_INTERRUPTION_N,
            C_AXI_WAIT_TIME        => C_AXI_WAIT_TIME,
            C_WR_WAIT_TIME         => C_WR_WAIT_TIME
        )
        port map (
            m_axi_aclk             => clk,
            m_axi_aresetn          => rst_n,
            ip2bus_mstrd_req       => tx_ip2bus_mstrd_req,
            ip2bus_mstwr_req       => tx_ip2bus_mstwr_req,
            ip2bus_mst_addr        => tx_ip2bus_mst_addr,
            ip2bus_mst_length      => tx_ip2bus_mst_length,
            ip2bus_mst_be          => tx_ip2bus_mst_be,
            ip2bus_mst_type        => tx_ip2bus_mst_type,
            ip2bus_mst_lock        => tx_ip2bus_mst_lock,
            ip2bus_mst_reset       => tx_ip2bus_mst_reset,
            bus2ip_mst_cmdack      => tx_bus2ip_mst_cmdack,
            bus2ip_mst_cmplt       => tx_bus2ip_mst_cmplt,
            bus2ip_mst_error       => tx_bus2ip_mst_error,
            bus2ip_mst_rearbitrate => tx_bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => tx_bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d         => tx_bus2ip_mstrd_d,
            bus2ip_mstrd_rem       => tx_bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n     => tx_bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => tx_bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => tx_bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => tx_bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => tx_ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => tx_ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => tx_ip2bus_mstwr_d,
            ip2bus_mstwr_rem       => tx_ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n     => tx_ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => tx_ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => tx_ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => tx_ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => tx_bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => tx_bus2ip_mstwr_dst_dsc_n
        );    

end architecture testbench;