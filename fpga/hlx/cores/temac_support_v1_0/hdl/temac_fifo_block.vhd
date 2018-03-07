-------------------------------------------------------------------------------
-- Title       : teamac fifo block
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : temac_fifo_block.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 11:13:53 2017
-- Last update : Wed Nov 22 13:28:03 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Connects the MAC Tx and Rx AXI-S interface to the temac fifo
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity temac_fifo_block is
    port (
        -------------------------------
        -- TO USER
        -------------------------------
        -- Receiver (AXI-S) Interface
        ------------------------------------------
        rx_fifo_clock              : in  std_logic;
        rx_fifo_resetn             : in  std_logic;
        rx_axis_fifo_tready        : in  std_logic;
        rx_axis_fifo_tvalid        : out std_logic;

        rx_axis_fifo_tdata         : out std_logic_vector(7 downto 0);

        rx_axis_fifo_tlast         : out std_logic;

        -- Transmitter (AXI-S) Interface
        ---------------------------------------------
        tx_fifo_clock              : in  std_logic;
        tx_fifo_resetn             : in  std_logic;
        tx_axis_fifo_tready        : out std_logic;
        tx_axis_fifo_tvalid        : in  std_logic;

        tx_axis_fifo_tdata         : in  std_logic_vector(7 downto 0);

        tx_axis_fifo_tlast         : in  std_logic;

        -------------------------------
        -- TO MAC
        -------------------------------
        -- Receiver Interface
        ----------------------------
        rx_enable                  : in std_logic;

        rx_statistics_vector       : in std_logic_vector(27 downto 0);
        rx_statistics_valid        : in std_logic;

        rx_mac_aclk                : in std_logic;
        rx_reset                   : in std_logic;
        rx_axis_mac_tdata          : in std_logic_vector(7 downto 0);
        rx_axis_mac_tvalid         : in std_logic;
        rx_axis_mac_tlast          : in std_logic;
        rx_axis_mac_tuser          : in std_logic;

        -- Transmitter Interface
        -------------------------------
        tx_enable                  : in std_logic;

        tx_ifg_delay               : out  std_logic_vector(7 downto 0);
        tx_statistics_vector       : in std_logic_vector(31 downto 0);
        tx_statistics_valid        : in std_logic;

        tx_mac_aclk                : in std_logic;
        tx_reset                   : in std_logic;
        tx_axis_mac_tdata          : out  std_logic_vector(7 downto 0);
        tx_axis_mac_tvalid         : out  std_logic;
        tx_axis_mac_tlast          : out  std_logic;
        tx_axis_mac_tuser          : out  std_logic_vector(0 downto 0);
        tx_axis_mac_tready         : in std_logic
    );
end entity temac_fifo_block;

architecture structural of temac_fifo_block is
    component temac_ten_100_1g_eth_fifo is
        generic (
            FULL_DUPLEX_ONLY : boolean := true
        );
        port (
            tx_fifo_aclk        : in  std_logic;
            tx_fifo_resetn      : in  std_logic;
            tx_axis_fifo_tdata  : in  std_logic_vector(7 downto 0);
            tx_axis_fifo_tvalid : in  std_logic;
            tx_axis_fifo_tlast  : in  std_logic;
            tx_axis_fifo_tready : out std_logic;
            tx_mac_aclk         : in  std_logic;
            tx_mac_resetn       : in  std_logic;
            tx_axis_mac_tdata   : out std_logic_vector(7 downto 0);
            tx_axis_mac_tvalid  : out std_logic;
            tx_axis_mac_tlast   : out std_logic;
            tx_axis_mac_tready  : in  std_logic;
            tx_axis_mac_tuser   : out std_logic;
            tx_fifo_overflow    : out std_logic;
            tx_fifo_status      : out std_logic_vector(3 downto 0);
            tx_collision        : in  std_logic;
            tx_retransmit       : in  std_logic;
            rx_fifo_aclk        : in  std_logic;
            rx_fifo_resetn      : in  std_logic;
            rx_axis_fifo_tdata  : out std_logic_vector(7 downto 0);
            rx_axis_fifo_tvalid : out std_logic;
            rx_axis_fifo_tlast  : out std_logic;
            rx_axis_fifo_tready : in  std_logic;
            rx_mac_aclk         : in  std_logic;
            rx_mac_resetn       : in  std_logic;
            rx_axis_mac_tdata   : in  std_logic_vector(7 downto 0);
            rx_axis_mac_tvalid  : in  std_logic;
            rx_axis_mac_tlast   : in  std_logic;
            rx_axis_mac_tuser   : in  std_logic;
            rx_fifo_status      : out std_logic_vector(3 downto 0);
            rx_fifo_overflow    : out std_logic
        );
    end component temac_ten_100_1g_eth_fifo;    

    component temac_reset_sync is
        port (
            reset_in  : in  std_logic;
            enable    : in  std_logic;
            clk       : in  std_logic;
            reset_out : out std_logic
        );
    end component temac_reset_sync;

    signal rx_mac_aclk_int         : std_logic;   -- MAC Rx clock
    signal tx_mac_aclk_int         : std_logic;   -- MAC Tx clock

    signal rx_reset_int            : std_logic;   -- MAC Rx reset
    signal tx_reset_int            : std_logic;   -- MAC Tx reset
    signal tx_mac_resetn           : std_logic;
    signal rx_mac_resetn           : std_logic;
    signal tx_mac_reset            : std_logic;
    signal rx_mac_reset            : std_logic;

begin
    rx_mac_aclk_int <= rx_mac_aclk;
    tx_mac_aclk_int <= tx_mac_aclk;
    -- locally reset sync the mac generated resets - the resets are already fully sync
    -- so adding a reset sync shouldn't change that
    rx_mac_reset_gen : temac_reset_sync
        port map (
            clk                  => rx_mac_aclk_int,
            enable               => '1',
            reset_in             => rx_reset_int,
            reset_out            => rx_mac_reset
        );

    tx_mac_reset_gen : temac_reset_sync
        port map (
            clk                  => tx_mac_aclk_int,
            enable               => '1',
            reset_in             => tx_reset_int,
            reset_out            => tx_mac_reset
        );

    -- create inverted mac resets as the FIFO expects AXI compliant resets
    tx_mac_resetn <= not tx_mac_reset;
    rx_mac_resetn <= not rx_mac_reset;
    
    user_side_FIFO : temac_ten_100_1g_eth_fifo
        generic map(
            FULL_DUPLEX_ONLY        => true
        )

        port map(
            -- Transmit FIFO MAC TX Interface
            tx_fifo_aclk          => tx_fifo_clock,
            tx_fifo_resetn        => tx_fifo_resetn,
            tx_axis_fifo_tready   => tx_axis_fifo_tready,
            tx_axis_fifo_tvalid   => tx_axis_fifo_tvalid,
            tx_axis_fifo_tdata    => tx_axis_fifo_tdata,
            tx_axis_fifo_tlast    => tx_axis_fifo_tlast,


            tx_mac_aclk           => tx_mac_aclk_int,
            tx_mac_resetn         => tx_mac_resetn,
            tx_axis_mac_tready    => tx_axis_mac_tready,
            tx_axis_mac_tvalid    => tx_axis_mac_tvalid,
            tx_axis_mac_tdata     => tx_axis_mac_tdata,
            tx_axis_mac_tlast     => tx_axis_mac_tlast,
            tx_axis_mac_tuser     => tx_axis_mac_tuser(0),
            tx_fifo_overflow      => open,
            tx_fifo_status        => open,
            tx_collision          => '0',
            tx_retransmit         => '0',

            rx_fifo_aclk          => rx_fifo_clock,
            rx_fifo_resetn        => rx_fifo_resetn,
            rx_axis_fifo_tready   => rx_axis_fifo_tready,
            rx_axis_fifo_tvalid   => rx_axis_fifo_tvalid,
            rx_axis_fifo_tdata    => rx_axis_fifo_tdata,
            rx_axis_fifo_tlast    => rx_axis_fifo_tlast,


            rx_mac_aclk           => rx_mac_aclk_int,
            rx_mac_resetn         => rx_mac_resetn,
            rx_axis_mac_tvalid    => rx_axis_mac_tvalid,
            rx_axis_mac_tdata     => rx_axis_mac_tdata,
            rx_axis_mac_tlast     => rx_axis_mac_tlast,
            rx_axis_mac_tuser     => rx_axis_mac_tuser,

            rx_fifo_status        => open,
            rx_fifo_overflow      => open
        );


end architecture structural;