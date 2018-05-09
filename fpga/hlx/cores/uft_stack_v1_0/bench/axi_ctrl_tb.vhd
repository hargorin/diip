-------------------------------------------------------------------------------
-- Title       : axi_ctr_tb
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : axi_ctr_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 09:21:20 2017
-- Last update : Wed May  9 13:37:00 2018
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

entity axi_ctr_tb is
    generic (
        C_S_AXI_DATA_WIDTH  : integer   := 32;
        -- Width of S_AXI address bus
        C_S_AXI_ADDR_WIDTH  : integer   := 6
    );
end entity axi_ctr_tb;

-----------------------------------------------------------

architecture testbench of axi_ctr_tb is

    -- Testbench signals
    signal clk     :    std_logic;
    signal rst_n   :    std_logic;

    signal tx_data_size       : std_logic_vector(31 downto 0);
    signal tx_data_src_addr   :  std_logic_vector(31 downto 0);
    signal tx_ready        : std_logic := '0';
    signal tx_start        :  std_logic;
    signal rx_data_dst_addr   :  std_logic_vector(31 downto 0);
    signal rx_data_transaction_ctr   :  std_logic_vector(31 downto 0) := x"00000000";
    
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

    -- validation
    signal tx_start_set : std_logic := '0';
    signal rx : std_logic_vector(31 downto 0) := (others => '0');

    constant clk_period : time := 8 ns;
    signal stop_sim  : std_logic := '0';

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
                 '1' after 10.0*clk_period;
        wait;
    end process RESET_GEN;

    -- Settings
    -- -------------------------------------------------------------------------


    -----------------------------------------------------------
    -- Testbench validation
    -----------------------------------------------------------
    p_validate : process (clk)
    -----------------------------------------------------------
    begin
        if tx_start = '1' then
            tx_start_set <= '1';
        end if;
    end process p_validate;
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;
       
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
            waitfor(2);
            -- write registers 1,2,3,5
            -- register 1: bit0: tx_start
            write("000100", x"00000001");
            assert (tx_start_set = '1') report "ERROR: tx_start not set" severity error;
            
            -- register 2: UFT_REG_RX_BASE
            write("001000", x"98752222");
            assert (rx_data_dst_addr = x"98752222") report "ERROR: UFT_REG_RX_BASE not set" severity error;

            -- register 3: UFT_REG_TX_BASE
            write("001100", x"12343333");
            assert (tx_data_src_addr = x"12343333") report "ERROR: UFT_REG_TX_BASE not set" severity error;

            -- register 5: UFT_REG_TX_SIZE
            write("010100", x"11115555");
            assert (tx_data_size = x"11115555") report "ERROR: UFT_REG_TX_SIZE not set" severity error;

            -- read status register
            tx_ready  <= '1';
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000001") report "ERROR: tx_ready not received" severity error;
            tx_ready  <= '0';
            read("000000");
            wait until rising_edge(clk);
            assert (rx = x"00000000") report "ERROR: tx_ready not received" severity error;
            
            -- read rx cnt register
            rx_data_transaction_ctr  <= x"42421001";
            read("010000");
            wait until rising_edge(clk);
            assert (rx = x"42421001") report "ERROR: rx_data_transaction_ctr not received" severity error;
           
            
        end procedure t1;
        -------------------------------------------------------------------
    begin
        report "Start TB";
        waitfor(2);

        ------------
        -- TEST 1 -- UFT Command Packet reception
        ------------
        t1;



        waitfor(5);
        stop_sim <= '1';
        report "Stop TB";
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    duv : entity work.axi_ctrl
        generic map (
            C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
        )
        port map (
            tx_data_size            => tx_data_size,
            tx_data_src_addr        => tx_data_src_addr,
            tx_ready                => tx_ready,
            tx_start                => tx_start,
            rx_data_dst_addr        => rx_data_dst_addr,
            rx_data_transaction_ctr => rx_data_transaction_ctr,
            S_AXI_ACLK              => clk,
            S_AXI_ARESETN           => rst_n,
            S_AXI_AWADDR            => S_AXI_AWADDR,
            S_AXI_AWPROT            => S_AXI_AWPROT,
            S_AXI_AWVALID           => S_AXI_AWVALID,
            S_AXI_AWREADY           => S_AXI_AWREADY,
            S_AXI_WDATA             => S_AXI_WDATA,
            S_AXI_WSTRB             => S_AXI_WSTRB,
            S_AXI_WVALID            => S_AXI_WVALID,
            S_AXI_WREADY            => S_AXI_WREADY,
            S_AXI_BRESP             => S_AXI_BRESP,
            S_AXI_BVALID            => S_AXI_BVALID,
            S_AXI_BREADY            => S_AXI_BREADY,
            S_AXI_ARADDR            => S_AXI_ARADDR,
            S_AXI_ARPROT            => S_AXI_ARPROT,
            S_AXI_ARVALID           => S_AXI_ARVALID,
            S_AXI_ARREADY           => S_AXI_ARREADY,
            S_AXI_RDATA             => S_AXI_RDATA,
            S_AXI_RRESP             => S_AXI_RRESP,
            S_AXI_RVALID            => S_AXI_RVALID,
            S_AXI_RREADY            => S_AXI_RREADY
        );    


end architecture testbench;