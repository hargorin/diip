-------------------------------------------------------------------------------
-- Title       : TEMAC Support Top Module
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : temac_support_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 13:28:23 2017
-- Last update : Fri Nov 24 13:36:00 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Provides Clocking, Reset, FiFo and Initialization state machine
-- For the Xilinx Tri Mode Ethernet MAC
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;   

library ieee;
use ieee.std_logic_1164.all;

entity temac_support_top is
    port (
        --------------------------------------------------------
        -- Connection to the MAC
        --------------------------------------------------------
        gtx_clk                    : out  std_logic;
        gtx_clk90                  : out  std_logic;

        -- asynchronous reset
        glbl_rstn                  : out  std_logic;
        rx_axi_rstn                : out  std_logic;
        tx_axi_rstn                : out  std_logic;
        phy_resetn                 : out  std_logic;

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
        tx_axis_mac_tready         : in std_logic;
        -- MAC Control Interface
        ------------------------
        pause_req                  : out  std_logic;
        pause_val                  : out  std_logic_vector(15 downto 0);

        speedis100                 : in std_logic;
        speedis10100               : in std_logic;

        -- AXI-Lite Interface
        -----------------
        s_axi_aclk                 : out  std_logic;
        s_axi_resetn               : out  std_logic;

        s_axi_awaddr               : out  std_logic_vector(11 downto 0);
        s_axi_awvalid              : out  std_logic;
        s_axi_awready              : in std_logic;

        s_axi_wdata                : out  std_logic_vector(31 downto 0);
        s_axi_wvalid               : out  std_logic;
        s_axi_wready               : in std_logic;

        s_axi_bresp                : in std_logic_vector(1 downto 0);
        s_axi_bvalid               : in std_logic;
        s_axi_bready               : out  std_logic;

        s_axi_araddr               : out  std_logic_vector(11 downto 0);
        s_axi_arvalid              : out  std_logic;
        s_axi_arready              : in std_logic;

        s_axi_rdata                : in std_logic_vector(31 downto 0);
        s_axi_rresp                : in std_logic_vector(1 downto 0);
        s_axi_rvalid               : in std_logic;
        s_axi_rready               : out  std_logic;

        mac_irq                    : in std_logic;

        --------------------------------------------------------
        -- Connection to the user logic
        --------------------------------------------------------
        -- clocks
        clk_in_p                   : in std_logic;
        clk_in_n                   : in std_logic;

        -- 125 MHz clock output from MMCM
        gtx_clk_bufg_out              : out std_logic;

        -- asynchronous resets
        glbl_rst                   : in std_logic;

        -- axi clock
        axi_tclk                : in  std_logic;
        axi_tresetn             : in  std_logic;

        speed                   : in  std_logic_vector(1 downto 0);
        update_speed            : in std_logic;

        -- AXI transmit interface
        tx_axis_tdata                   : in  std_logic_vector(7 downto 0);
        tx_axis_tvalid                  : in  std_logic;
        tx_axis_tlast                   : in  std_logic;
        tx_axis_tready                  : out std_logic;

        -- AXI receive interface
        rx_axis_tdata                   : out std_logic_vector(7 downto 0);
        rx_axis_tvalid                  : out std_logic;
        rx_axis_tlast                   : out std_logic;
        rx_axis_tready                  : in  std_logic;

        irq                             : out std_logic
    );

end entity temac_support_top;


architecture structural of temac_support_top is

    ----------------------------------------------------------------------------
    -- Component Declaration for the support layer
    ----------------------------------------------------------------------------
    component temac_support is
        port (
            gtx_clk       : in  std_logic;
            gtx_clk_out   : out std_logic;
            gtx_clk90_out : out std_logic;
            refclk        : in  std_logic;
            glbl_rstn     : in  std_logic
        );
    end component temac_support;    

    ----------------------------------------------------------------------------
    -- Component Declaration for the FiFo Block
    ----------------------------------------------------------------------------
    component temac_fifo_block is
        port (
            rx_fifo_clock        : in  std_logic;
            rx_fifo_resetn       : in  std_logic;
            rx_axis_fifo_tready  : in  std_logic;
            rx_axis_fifo_tvalid  : out std_logic;
            rx_axis_fifo_tdata   : out std_logic_vector(7 downto 0);
            rx_axis_fifo_tlast   : out std_logic;
            tx_fifo_clock        : in  std_logic;
            tx_fifo_resetn       : in  std_logic;
            tx_axis_fifo_tready  : out std_logic;
            tx_axis_fifo_tvalid  : in  std_logic;
            tx_axis_fifo_tdata   : in  std_logic_vector(7 downto 0);
            tx_axis_fifo_tlast   : in  std_logic;
            rx_enable            : in  std_logic;
            rx_statistics_vector : in  std_logic_vector(27 downto 0);
            rx_statistics_valid  : in  std_logic;
            rx_mac_aclk          : in  std_logic;
            rx_reset             : in  std_logic;
            rx_axis_mac_tdata    : in  std_logic_vector(7 downto 0);
            rx_axis_mac_tvalid   : in  std_logic;
            rx_axis_mac_tlast    : in  std_logic;
            rx_axis_mac_tuser    : in  std_logic;
            tx_enable            : in  std_logic;
            tx_ifg_delay         : out std_logic_vector(7 downto 0);
            tx_statistics_vector : in  std_logic_vector(31 downto 0);
            tx_statistics_valid  : in  std_logic;
            tx_mac_aclk          : in  std_logic;
            tx_reset             : in  std_logic;
            tx_axis_mac_tdata    : out std_logic_vector(7 downto 0);
            tx_axis_mac_tvalid   : out std_logic;
            tx_axis_mac_tlast    : out std_logic;
            tx_axis_mac_tuser    : out std_logic_vector(0 downto 0);
            tx_axis_mac_tready   : in  std_logic
        );
    end component temac_fifo_block;       

    ------------------------------------------------------------------------------
    -- Component Declaration for the AXI-Lite State machine
    ------------------------------------------------------------------------------
    component temac_axi_lite_sm is
        port (
            s_axi_aclk      : in  std_logic;
            s_axi_resetn    : in  std_logic;
            mac_speed       : in  std_logic_vector(1 downto 0);
            update_speed    : in  std_logic;
            serial_command  : in  std_logic;
            serial_response : out std_logic;
            phy_loopback    : in  std_logic;
            s_axi_awaddr    : out std_logic_vector(11 downto 0) := (others => '0');
            s_axi_awvalid   : out std_logic                     := '0';
            s_axi_awready   : in  std_logic;
            s_axi_wdata     : out std_logic_vector(31 downto 0) := (others => '0');
            s_axi_wvalid    : out std_logic                     := '0';
            s_axi_wready    : in  std_logic;
            s_axi_bresp     : in  std_logic_vector(1 downto 0);
            s_axi_bvalid    : in  std_logic;
            s_axi_bready    : out std_logic;
            s_axi_araddr    : out std_logic_vector(11 downto 0) := (others => '0');
            s_axi_arvalid   : out std_logic                     := '0';
            s_axi_arready   : in  std_logic;
            s_axi_rdata     : in  std_logic_vector(31 downto 0);
            s_axi_rresp     : in  std_logic_vector(1 downto 0);
            s_axi_rvalid    : in  std_logic;
            s_axi_rready    : out std_logic := '0'
        );
    end component temac_axi_lite_sm;    

    ------------------------------------------------------------------------------
    -- Component declaration for the clocking logic
    ------------------------------------------------------------------------------
    component temac_clocks is
        port (
            -- clocks
            clk_in_p                   : in std_logic;
            clk_in_n                   : in std_logic;

            -- asynchronous resets
            glbl_rst                   : in std_logic;
            dcm_locked                 : out std_logic;

            -- clock outputs
            gtx_clk_bufg               : out std_logic;

            refclk_bufg                : out std_logic;
            s_axi_aclk                 : out std_logic
        );
    end component;

    ------------------------------------------------------------------------------
    -- Component declaration for the reset logic
    ------------------------------------------------------------------------------
    component temac_resets is
        port (
            -- clocks
            s_axi_aclk                 : in std_logic;
            gtx_clk                    : in std_logic;


            -- asynchronous resets
            glbl_rst                   : in std_logic;
            reset_error                : in std_logic;
            rx_reset                   : in std_logic;
            tx_reset                   : in std_logic;

            dcm_locked                 : in std_logic;

            -- synchronous reset outputs

            glbl_rst_intn              : out std_logic;

            gtx_resetn                 : out std_logic := '0';

            s_axi_resetn               : out std_logic := '0';
            phy_resetn                 : out std_logic;
            chk_resetn                 : out std_logic := '0'
        );
    end component;

    -- clocks
    signal dcm_locked                         : std_logic;
    signal glbl_rst_int                       : std_logic;
    signal refclk_bufg                        : std_logic;
    signal s_axi_aclk_int                     : std_logic;
    signal gtx_clk_bufg_int                   : std_logic;

    -- resets
    signal glbl_rst_intn                      : std_logic;
    signal gtx_resetn                         : std_logic;
    signal s_axi_resetn_int                       : std_logic;
    signal chk_resetn                       : std_logic;
    signal tx_fifo_resetn                       : std_logic;
    signal rx_fifo_resetn                       : std_logic;
    signal tx_fifo_clock            : std_logic;
    signal rx_fifo_clock            : std_logic;

    -- axi lite sm
begin
    ----------------------------------------------------------------------------
    -- Clock logic to generate required clocks from the 200MHz on board
    -- if 125MHz is available directly this can be removed
    ----------------------------------------------------------------------------
    clocks : temac_clocks
        port map (
            clk_in_p     => clk_in_p,
            clk_in_n     => clk_in_n,
            glbl_rst     => glbl_rst,
            dcm_locked   => dcm_locked,
            gtx_clk_bufg => gtx_clk_bufg_int,   -- 125MHz
            refclk_bufg  => refclk_bufg,        -- 200MHz
            s_axi_aclk   => s_axi_aclk_int      -- 100MHz
        );    

    -- Pass the GTX clock to the User
    gtx_clk_bufg_out <= gtx_clk_bufg_int;
    -- generate the user side clocks for the axi fifos
    tx_fifo_clock <= gtx_clk_bufg_int;
    rx_fifo_clock <= gtx_clk_bufg_int;

    s_axi_aclk <= s_axi_aclk_int;

    ------------------------------------------------------------------------------
    -- Generate resets required for the fifo side signals etc
    ------------------------------------------------------------------------------
    resets : temac_resets
        port map (
            s_axi_aclk    => s_axi_aclk_int,
            gtx_clk       => gtx_clk_bufg_int,
            glbl_rst      => glbl_rst,
            reset_error   => '0',
            rx_reset      => rx_reset,
            tx_reset      => tx_reset,
            dcm_locked    => dcm_locked,
            glbl_rst_intn => glbl_rst_intn,
            gtx_resetn    => gtx_resetn,
            s_axi_resetn  => s_axi_resetn_int,
            phy_resetn    => phy_resetn,
            chk_resetn    => chk_resetn
        );    


    -- generate the user side resets for the axi fifos
    tx_fifo_resetn <= gtx_resetn;
    rx_fifo_resetn <= gtx_resetn;
    glbl_rstn <= glbl_rst_intn;
    s_axi_resetn <= s_axi_resetn_int;

    rx_axi_rstn <= '1';
    tx_axi_rstn <= '1';

    ----------------------------------------------------------------------------
    -- Support instance
    -- Generates the 90deg shifted clocks from gtx_clk
    ----------------------------------------------------------------------------
    support : temac_support
        port map (
            gtx_clk       => gtx_clk_bufg_int,
            gtx_clk_out   => gtx_clk,
            gtx_clk90_out => gtx_clk90,
            refclk        => refclk_bufg,
            glbl_rstn     => glbl_rst_intn
        );

    ------------------------------------------------------------------------------
    -- Instantiate the AXI-LITE Controller
    ------------------------------------------------------------------------------
    axi_lite_sm : temac_axi_lite_sm
        port map (
            s_axi_aclk      => s_axi_aclk_int,
            s_axi_resetn    => s_axi_resetn_int,
            mac_speed       => speed,
            update_speed    => update_speed,
            serial_command  => '0',
            serial_response => open,
            phy_loopback    => '0',
            s_axi_awaddr    => s_axi_awaddr,
            s_axi_awvalid   => s_axi_awvalid,
            s_axi_awready   => s_axi_awready,
            s_axi_wdata     => s_axi_wdata,
            s_axi_wvalid    => s_axi_wvalid,
            s_axi_wready    => s_axi_wready,
            s_axi_bresp     => s_axi_bresp,
            s_axi_bvalid    => s_axi_bvalid,
            s_axi_bready    => s_axi_bready,
            s_axi_araddr    => s_axi_araddr,
            s_axi_arvalid   => s_axi_arvalid,
            s_axi_arready   => s_axi_arready,
            s_axi_rdata     => s_axi_rdata,
            s_axi_rresp     => s_axi_rresp,
            s_axi_rvalid    => s_axi_rvalid,
            s_axi_rready    => s_axi_rready
        );    

    ------------------------------------------------------------------------------
    -- Instantiate the TRIMAC core FIFO Block wrapper
    ------------------------------------------------------------------------------
    fifo_block : temac_fifo_block
        port map (
            rx_fifo_clock        => rx_fifo_clock,
            rx_fifo_resetn       => rx_fifo_resetn,

            rx_axis_fifo_tready  => rx_axis_tready,
            rx_axis_fifo_tvalid  => rx_axis_tvalid,
            rx_axis_fifo_tdata   => rx_axis_tdata,
            rx_axis_fifo_tlast   => rx_axis_tlast,

            tx_fifo_clock        => tx_fifo_clock,
            tx_fifo_resetn       => tx_fifo_resetn,

            tx_axis_fifo_tready  => tx_axis_tready,
            tx_axis_fifo_tvalid  => tx_axis_tvalid,
            tx_axis_fifo_tdata   => tx_axis_tdata,
            tx_axis_fifo_tlast   => tx_axis_tlast,

            rx_enable            => rx_enable,
            rx_statistics_vector => rx_statistics_vector,
            rx_statistics_valid  => rx_statistics_valid,
            rx_mac_aclk          => rx_mac_aclk,
            rx_reset             => rx_reset,
            rx_axis_mac_tdata    => rx_axis_mac_tdata,
            rx_axis_mac_tvalid   => rx_axis_mac_tvalid,
            rx_axis_mac_tlast    => rx_axis_mac_tlast,
            rx_axis_mac_tuser    => rx_axis_mac_tuser,

            tx_enable            => tx_enable,
            tx_ifg_delay         => tx_ifg_delay,
            tx_statistics_vector => tx_statistics_vector,
            tx_statistics_valid  => tx_statistics_valid,
            tx_mac_aclk          => tx_mac_aclk,
            tx_reset             => tx_reset,
            tx_axis_mac_tdata    => tx_axis_mac_tdata,
            tx_axis_mac_tvalid   => tx_axis_mac_tvalid,
            tx_axis_mac_tlast    => tx_axis_mac_tlast,
            tx_axis_mac_tuser    => tx_axis_mac_tuser,
            tx_axis_mac_tready   => tx_axis_mac_tready
        );    

    ------------------------------------------------------------------------------
    -- Other TRIMAC signals
    ------------------------------------------------------------------------------  
    pause_req <= '0';
    pause_val <= (others => '0');

end architecture structural;
