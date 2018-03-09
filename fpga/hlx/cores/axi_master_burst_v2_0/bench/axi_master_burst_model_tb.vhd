-------------------------------------------------------------------------------
-- Title       : UDP Packet generator top testbench
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : axi_master_burst_model_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Oct 18 09:36:54 2017
-- Last update : Fri Mar  9 10:40:45 2018
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

entity axi_master_burst_model_tb is
    generic (
            C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
            C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
            C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
            C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
            C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
            C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
            C_FAMILY            : string                  := "virtex7";

            -- Burst length in bytes for read and write burst operations
            C_BURST_LEN         : integer := 80
        );
end entity axi_master_burst_model_tb;

-----------------------------------------------------------

architecture testbench of axi_master_burst_model_tb is
    component axi_master_burst_model is
        generic (
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "virtex7"
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
    signal m_axi_aclk             : std_logic;
    signal m_axi_aresetn          : std_logic;
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

    -- simulation signals
    signal stop_sim  : std_logic;
    constant clk_period : time := 8 ns;

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        m_axi_aclk <= '1';
        wait for clk_period / 2.0;
        m_axi_aclk <= '0';
        wait for clk_period / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;
        
    RESET_GEN : process
    begin
        m_axi_aresetn <= '0',
                         '1' after 5*clk_period;
        wait;
    end process RESET_GEN;
    
    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_stim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(m_axi_aclk);
        end procedure waitfor;

        variable i : integer := 0;
    begin
        -- Init
        ip2bus_mstrd_req <= '0';
        ip2bus_mstwr_req <= '0';
        ip2bus_mst_addr <= (others => '0');
        ip2bus_mst_length <= (others => '0');
        ip2bus_mst_be <= (others => '0');
        ip2bus_mst_type <= '0';
        ip2bus_mst_lock <= '0';
        ip2bus_mst_reset <= '0';
        ip2bus_mstrd_dst_rdy_n <= '1';
        ip2bus_mstrd_dst_dsc_n <= '1';
        ip2bus_mstwr_d <= (others => '0');
        ip2bus_mstwr_rem <= (others => '0');
        ip2bus_mstwr_sof_n <= '1';
        ip2bus_mstwr_eof_n <= '1';
        ip2bus_mstwr_src_rdy_n <= '1';
        ip2bus_mstwr_src_dsc_n <= '1';

        stop_sim <= '0';
        waitfor(10);

        ------------
        -- TEST 1 -- single beat read transaction
        ------------
        report "-- TEST 1 -- single beat read transaction";
        ip2bus_mstrd_req <= '1';
        ip2bus_mstrd_dst_rdy_n <= '0';
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity error;
        ip2bus_mstrd_req <= '0';
        wait until bus2ip_mst_cmplt= '1';
        assert bus2ip_mstrd_sof_n = '0' report "bus2ip_mstrd_sof_n error" severity error;
        assert bus2ip_mstrd_eof_n = '0' report "bus2ip_mstrd_eof_n error" severity error;
        waitfor(1);
        ip2bus_mstrd_dst_rdy_n <= '1';

        ------------
        -- TEST 2 -- single beat write transaction
        ------------
        waitfor(2);
        report "-- TEST 2 -- single beat write transaction";
        ip2bus_mstwr_req <= '1';
        ip2bus_mstwr_sof_n <= '0';
        ip2bus_mstwr_eof_n <= '0';
        ip2bus_mstwr_src_rdy_n <= '0';
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity error;
        ip2bus_mstwr_req <= '0';
        wait until bus2ip_mstwr_dst_rdy_n = '0';
        waitfor(1);
        ip2bus_mstwr_sof_n <= '1';
        ip2bus_mstwr_eof_n <= '1';
        ip2bus_mstwr_src_rdy_n <= '1';
        wait until bus2ip_mst_cmplt = '1';

        ------------
        -- TEST 3 -- burst read transaction
        ------------
        waitfor(2);
        report "-- TEST 3 -- burst read transaction";
        ip2bus_mstrd_req <= '1';
        ip2bus_mst_type <= '1';
        ip2bus_mstrd_dst_rdy_n <= '0';
        ip2bus_mst_length <= std_logic_vector(to_unsigned(C_BURST_LEN, ip2bus_mst_length'length));
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity error;
        ip2bus_mstrd_req <= '0';
        
        -- get first byte
        loop
            waitfor(1);
            exit when bus2ip_mstrd_sof_n = '0' AND bus2ip_mstrd_src_rdy_n = '0';    
        end loop ;

        -- get inner bytes
        i := 0;
        --while i < C_BURST_LEN-2 loop
        while bus2ip_mstrd_eof_n = '1' loop
            waitfor(1);
            if (bus2ip_mstrd_src_rdy_n = '0') then
                i := i + 1;
            end if;
        end loop;
        
        -- get last byte
        loop
            waitfor(1);
            exit when bus2ip_mstrd_src_rdy_n = '1';    
        end loop ;
        ip2bus_mstrd_dst_rdy_n <= '1';

        --wait until bus2ip_mstrd_sof_n = '0';
        --assert bus2ip_mstrd_src_rdy_n = '0' report "bus2ip_mstrd_src_rdy_n error" severity error;
        --wait until bus2ip_mstrd_eof_n = '0';
        --waitfor(1);

        ------------
        -- TEST 4 -- burst write transaction
        ------------
        waitfor(2);
        report "-- TEST 4 -- burst write transaction";
        ip2bus_mstwr_sof_n <= '0';
        ip2bus_mstwr_src_rdy_n <= '0';
        ip2bus_mstwr_req <= '1';
        ip2bus_mst_length <= std_logic_vector(to_unsigned(C_BURST_LEN, ip2bus_mst_length'length));
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity error;
        ip2bus_mstwr_req <= '0';
            
        i := C_BURST_LEN/4;
        -- send first byte
        wait until bus2ip_mstwr_dst_rdy_n = '0';
        waitfor(1);
        ip2bus_mstwr_sof_n <= '1';
        i := i - 1;
        
        -- send inner bytes
        while i > 1 loop
            waitfor(1);
            if (bus2ip_mstwr_dst_rdy_n = '0') then
                i := i - 1;
            end if;
        end loop;

        -- send last byte
        ip2bus_mstwr_eof_n <= '0';
        loop
            waitfor(1);
            exit when bus2ip_mstwr_dst_rdy_n = '0';
        end loop;

        ip2bus_mstwr_src_rdy_n <= '1';
        ip2bus_mstwr_eof_n <= '1';    

        ------------
        -- TEST 5 -- single byte burst read transaction
        ------------
        waitfor(2);
        report "-- TEST 5 -- single byte burst read transaction";
        ip2bus_mstrd_req <= '1';
        ip2bus_mst_type <= '1';
        ip2bus_mstrd_dst_rdy_n <= '0';
        ip2bus_mst_length <= std_logic_vector(to_unsigned(1, ip2bus_mst_length'length));
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity warning;
        ip2bus_mstrd_req <= '0';
        
        ---- get first byte
        loop
            waitfor(1);
            exit when bus2ip_mstrd_sof_n = '0' AND bus2ip_mstrd_src_rdy_n = '0';    
        end loop ;
        assert bus2ip_mstrd_eof_n = '0' report "bus2ip_mstrd_eof_n error" severity error;


        ------------
        -- TEST 6 -- single byte burst write transaction
        ------------
        waitfor(2);
        report "-- TEST 6 -- single byte burst write transaction";
        ip2bus_mstwr_req <= '1';
        ip2bus_mst_type <= '1';
        ip2bus_mstwr_src_rdy_n <= '0';
        ip2bus_mstwr_sof_n <= '0';
        ip2bus_mstwr_eof_n <= '0';
        ip2bus_mst_length <= std_logic_vector(to_unsigned(1, ip2bus_mst_length'length));
        waitfor(2);
        assert bus2ip_mst_cmdack = '1' report "bus2ip_mst_cmdack error" severity warning;
        ip2bus_mstwr_req <= '0';

        
        ---- send first byte
        loop
            waitfor(1);
            exit when bus2ip_mstwr_dst_rdy_n = '0';    
        end loop ;

        ------------
        -- End of sim
        ------------
        waitfor(5);
        report "---- Test Complete ----";
        stop_sim <= '1';
        wait;

    end process ; -- p_stim 

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    axi_master_burst_model_1 : axi_master_burst_model
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
            m_axi_aclk             => m_axi_aclk,
            m_axi_aresetn          => m_axi_aresetn,
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