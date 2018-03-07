-------------------------------------------------------------------------------
-- Title       : TEMAC Support layer
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : temac_support.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 13:30:54 2017
-- Last update : Wed Nov 22 13:31:06 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: This module holds the support level for the Tri-Mode
--              Ethernet MAC IP.  It contains potentially shareable FPGA
--              resources such as clocking, reset and IDELAYCTRL logic.
--              This can be used as-is in a single core design, or adapted
--              for use with multi-core implementations.
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity temac_support is
    port (
        gtx_clk                    : in  std_logic;

        gtx_clk_out                : out  std_logic;
        gtx_clk90_out              : out  std_logic;

        -- Reference clock for IDELAYCTRL's
        refclk                     : in  std_logic;
        -- asynchronous reset
        glbl_rstn                  : in  std_logic
    );
end entity temac_support;

architecture structural of temac_support is
    component temac_support_clocking is
        port (
            clk_in1  : in  std_logic;
            clk_out1 : out std_logic;
            clk_out2 : out std_logic;
            reset    : in  std_logic;
            locked   : out std_logic
        );
    end component temac_support_clocking;    

    component temac_support_resets is
        port (
            glbl_rstn            : in  std_logic;
            refclk               : in  std_logic;
            idelayctrl_ready     : in  std_logic;
            idelayctrl_reset_out : out std_logic;
            gtx_clk              : in  std_logic;
            gtx_dcm_locked       : in  std_logic;
            gtx_mmcm_rst_out     : out std_logic
        );
    end component temac_support_resets;    

    -- Internal signals
    signal mmcm_out_gtx_clk      : std_logic;
    signal mmcm_out_gtx_clk90    : std_logic;
    signal gtx_mmcm_rst          : std_logic;
    signal gtx_mmcm_locked       : std_logic;
    signal idelayctrl_reset      : std_logic;
    signal idelayctrl_ready      : std_logic;
begin
    
    ----------------------------------------------------------------------------
    -- Clocking
    ----------------------------------------------------------------------------
    clocking : temac_support_clocking
        port map (
            clk_in1  => gtx_clk,
            clk_out1 => mmcm_out_gtx_clk,
            clk_out2 => mmcm_out_gtx_clk90,
            reset    => gtx_mmcm_rst,
            locked   => gtx_mmcm_locked
        );    

    gtx_clk_out                <= mmcm_out_gtx_clk;
    gtx_clk90_out              <= mmcm_out_gtx_clk90;

    ----------------------------------------------------------------------------
    -- Reset
    -- -------------------------------------------------------------------------
    resets : temac_support_resets
        port map (
            glbl_rstn            => glbl_rstn,
            refclk               => refclk,
            idelayctrl_ready     => idelayctrl_ready,
            idelayctrl_reset_out => idelayctrl_reset,
            gtx_clk              => gtx_clk,
            gtx_dcm_locked       => gtx_mmcm_locked,
            gtx_mmcm_rst_out     => gtx_mmcm_rst
        );    

    -- An IDELAYCTRL primitive needs to be instantiated for the Fixed Tap Delay
    -- mode of the IDELAY.
    idelayctrl_common : IDELAYCTRL
        generic map (
            SIM_DEVICE => "7SERIES"
        )
        port map (
            RDY                    => idelayctrl_ready,
            REFCLK                 => refclk,
            RST                    => idelayctrl_reset
        );

end architecture structural;