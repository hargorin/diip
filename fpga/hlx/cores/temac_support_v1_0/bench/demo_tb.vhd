--------------------------------------------------------------------------------
-- Title      : Demo testbench
-- Project    : Tri-Mode Ethernet MAC
--------------------------------------------------------------------------------
-- File       : demo_tb.vhd
-- -----------------------------------------------------------------------------
-- (c) Copyright 2004-2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- -----------------------------------------------------------------------------
-- Description: This testbench will exercise the ports of the MAC core
--              to demonstrate the functionality.
--------------------------------------------------------------------------------
--
-- This testbench performs the following operations on the MAC core
-- and its design example:

--  - The MDIO interface will respond to a read request with data to prevent the
--    example design thinking it is real hardware

--  - Four frames are then pushed into the receiver from the PHY
--    interface (GMII or RGMII):
--    The first is of minimum length (Length/Type = Length = 46 bytes).
--    The second frame sets Length/Type to Type = 0x8000.
--    The third frame has an error inserted.
--    The fourth frame only sends 4 bytes of data: the remainder of the
--    data field is padded up to the minimum frame length i.e. 46 bytes.

--  - These frames are then parsed from the MAC into the MAC's design
--    example.  The design example provides a MAC client loopback
--    function so that frames which are received without error will be
--    looped back to the MAC transmitter and transmitted back to the
--    testbench.  The testbench verifies that this data matches that
--    previously injected into the receiver.

--  - The four frames are then re-sent at 100Mb/s, 10Mb/s and finally 1Gb/s again.


------------------------------------------------------------------------
--                         DEMONSTRATION TESTBENCH                     |
--                                                                     |
--                                                                     |
--     ----------------------------------------------                  |
--     |           TOP LEVEL WRAPPER (DUT)          |                  |
--     |  -------------------    ----------------   |                  |
--     |  | USER LOOPBACK   |    | TRI-MODE     |   |                  |
--     |  | DESIGN EXAMPLE  |    | ETHERNET MAC |   |                  |
--     |  |                 |    | CORE         |   |                  |
--     |  |                 |    |              |   |       Monitor    |
--     |  |         ------->|--->|          Tx  |-------->  Frames     |
--     |  |         |       |    |          PHY |   |                  |
--     |  |         |       |    |          I/F |   |                  |
--     |  |         |       |    |              |   |                  |
--     |  |         |       |    |              |   |                  |
--     |  |         |       |    |              |   |                  |
--     |  |         |       |    |          Rx  |   |                  |
--     |  |         |       |    |          PHY |   |                  |
--     |  |         --------|<---|          I/F |<-------- Generate    |
--     |  |                 |    |              |   |      Frames      |
--     |  -------------------    ----------------   |                  |
--     --------------------------------^-------------                  |
--                                     |                               |
--                                     |                               |
--                                 Stimulate                           |
--                               Management I/F                        |
--                               (if present)                          |
--                                                                     |
------------------------------------------------------------------------


entity demo_tb is
end demo_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture behav of demo_tb is

  

  ------------------------------------------------------------------------------
  -- Component Declaration for Device Under Test (DUT).
  ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_example_design
    port (
      -- asynchronous reset
      glbl_rst                      : in  std_logic;

      -- 200MHz clock input from board
      clk_in_p                      : in  std_logic;
      clk_in_n                      : in  std_logic;
      -- 125 MHZ clock output from MMCM
      gtx_clk_bufg_out              : out std_logic;
      
      phy_resetn                    : out std_logic;


      -- RGMII Interface
      ------------------
      rgmii_txd                     : out std_logic_vector(3 downto 0);
      rgmii_tx_ctl                  : out std_logic;
      rgmii_txc                     : out std_logic;
      rgmii_rxd                     : in  std_logic_vector(3 downto 0);
      rgmii_rx_ctl                  : in  std_logic;
      rgmii_rxc                     : in  std_logic;

      -- MDIO Interface
      -----------------
      mdio                          : inout std_logic;
      mdc                           : out std_logic;



      -- Serialised statistics vectors
      --------------------------------
      tx_statistics_s               : out std_logic;
      rx_statistics_s               : out std_logic;

      -- Serialised Pause interface controls
      --------------------------------------
      pause_req_s                   : in  std_logic;

      -- Main example design controls
      -------------------------------
      mac_speed                     : in  std_logic_vector(1 downto 0);
      update_speed                  : in  std_logic;
      config_board                  : in  std_logic;
      --serial_command                : in  std_logic;
      serial_response               : out std_logic;
      gen_tx_data                   : in  std_logic;
      chk_tx_data                   : in  std_logic;
      reset_error                   : in  std_logic;
      frame_error                   : out std_logic;
      frame_errorn                  : out std_logic;
      activity_flash                : out std_logic;
      activity_flashn               : out std_logic

    );
  end component;


  ------------------------------------------------------------------------------
  -- types to support frame data
  ------------------------------------------------------------------------------
  -- Tx Data and Data_valid record
  type data_typ is record
      data : bit_vector(7 downto 0);        -- data
      valid : bit;                          -- data_valid
      error : bit;                          -- data_error
  end record;
  type frame_of_data_typ is array (natural range <>) of data_typ;

  -- Tx Data, Data_valid and underrun record
  type tri_mode_ethernet_mac_0_frame_typ is record
      columns   : frame_of_data_typ(0 to 65);-- data field
      bad_frame : boolean;                   -- does this frame contain an error?
  end record;
  type frame_typ_ary is array (natural range <>) of tri_mode_ethernet_mac_0_frame_typ;

  -----------------------------------
  -- testbench mode selection
  -----------------------------------
  -- the testbench has two modes of operation:
  --  - DEMO :=   In this mode frames are generated and checked by the testbench
  --              and looped back at the user side of the MAC.
  --  - BIST :=   In this mode the built in pattern generators and patttern
  --              checkers a/re used with the data looped back in the PHY domain.
  
  constant TB_MODE                  : string := "BIST";

  ------------------------------------------------------------------------------
  -- Stimulus - Frame data
  ------------------------------------------------------------------------------
  -- The following constant holds the stimulus for the testbench. It is
  -- an ordered array of frames, with frame 0 the first to be injected
  -- into the core transmit interface by the testbench.
  ------------------------------------------------------------------------------
  constant frame_data : frame_typ_ary := (
   -------------
   -- Frame 0
   -------------
    0          => (
      columns  => (
        0      => ( DATA => X"DA", VALID => '1', ERROR => '0'), -- Destination Address (DA)
        1      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        2      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        3      => ( DATA => X"04", VALID => '1', ERROR => '0'),
        4      => ( DATA => X"05", VALID => '1', ERROR => '0'),
        5      => ( DATA => X"06", VALID => '1', ERROR => '0'),
        6      => ( DATA => X"5A", VALID => '1', ERROR => '0'), -- Source Address (5A)
        7      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        8      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        9      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       10      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       11      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       12      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       13      => ( DATA => X"2E", VALID => '1', ERROR => '0'), -- Length/Type = Length = 46
       14      => ( DATA => X"01", VALID => '1', ERROR => '0'),
       15      => ( DATA => X"02", VALID => '1', ERROR => '0'),
       16      => ( DATA => X"03", VALID => '1', ERROR => '0'),
       17      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       18      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       19      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       20      => ( DATA => X"07", VALID => '1', ERROR => '0'),
       21      => ( DATA => X"08", VALID => '1', ERROR => '0'),
       22      => ( DATA => X"09", VALID => '1', ERROR => '0'),
       23      => ( DATA => X"0A", VALID => '1', ERROR => '0'),
       24      => ( DATA => X"0B", VALID => '1', ERROR => '0'),
       25      => ( DATA => X"0C", VALID => '1', ERROR => '0'),
       26      => ( DATA => X"0D", VALID => '1', ERROR => '0'),
       27      => ( DATA => X"0E", VALID => '1', ERROR => '0'),
       28      => ( DATA => X"0F", VALID => '1', ERROR => '0'),
       29      => ( DATA => X"10", VALID => '1', ERROR => '0'),
       30      => ( DATA => X"11", VALID => '1', ERROR => '0'),
       31      => ( DATA => X"12", VALID => '1', ERROR => '0'),
       32      => ( DATA => X"13", VALID => '1', ERROR => '0'),
       33      => ( DATA => X"14", VALID => '1', ERROR => '0'),
       34      => ( DATA => X"15", VALID => '1', ERROR => '0'),
       35      => ( DATA => X"16", VALID => '1', ERROR => '0'),
       36      => ( DATA => X"17", VALID => '1', ERROR => '0'),
       37      => ( DATA => X"18", VALID => '1', ERROR => '0'),
       38      => ( DATA => X"19", VALID => '1', ERROR => '0'),
       39      => ( DATA => X"1A", VALID => '1', ERROR => '0'),
       40      => ( DATA => X"1B", VALID => '1', ERROR => '0'),
       41      => ( DATA => X"1C", VALID => '1', ERROR => '0'),
       42      => ( DATA => X"1D", VALID => '1', ERROR => '0'),
       43      => ( DATA => X"1E", VALID => '1', ERROR => '0'),
       44      => ( DATA => X"1F", VALID => '1', ERROR => '0'),
       45      => ( DATA => X"20", VALID => '1', ERROR => '0'),
       46      => ( DATA => X"21", VALID => '1', ERROR => '0'),
       47      => ( DATA => X"22", VALID => '1', ERROR => '0'),
       48      => ( DATA => X"23", VALID => '1', ERROR => '0'),
       49      => ( DATA => X"24", VALID => '1', ERROR => '0'),
       50      => ( DATA => X"25", VALID => '1', ERROR => '0'),
       51      => ( DATA => X"26", VALID => '1', ERROR => '0'),
       52      => ( DATA => X"27", VALID => '1', ERROR => '0'),
       53      => ( DATA => X"28", VALID => '1', ERROR => '0'),
       54      => ( DATA => X"29", VALID => '1', ERROR => '0'),
       55      => ( DATA => X"2A", VALID => '1', ERROR => '0'),
       56      => ( DATA => X"2B", VALID => '1', ERROR => '0'),
       57      => ( DATA => X"2C", VALID => '1', ERROR => '0'),
       58      => ( DATA => X"2D", VALID => '1', ERROR => '0'),
       59      => ( DATA => X"2E", VALID => '1', ERROR => '0'), -- 46th Byte of Data
       others  => ( DATA => X"00", VALID => '0', ERROR => '0')),

      -- No error in this frame
      bad_frame => false),


   -------------
   -- Frame 1
   -------------
    1          => (
      columns  => (
        0      => ( DATA => X"DA", VALID => '1', ERROR => '0'), -- Destination Address (DA)
        1      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        2      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        3      => ( DATA => X"04", VALID => '1', ERROR => '0'),
        4      => ( DATA => X"05", VALID => '1', ERROR => '0'),
        5      => ( DATA => X"06", VALID => '1', ERROR => '0'),
        6      => ( DATA => X"5A", VALID => '1', ERROR => '0'), -- Source Address (5A)
        7      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        8      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        9      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       10      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       11      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       12      => ( DATA => X"80", VALID => '1', ERROR => '0'), -- Length/Type = Type = 8000
       13      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       14      => ( DATA => X"01", VALID => '1', ERROR => '0'),
       15      => ( DATA => X"02", VALID => '1', ERROR => '0'),
       16      => ( DATA => X"03", VALID => '1', ERROR => '0'),
       17      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       18      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       19      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       20      => ( DATA => X"07", VALID => '1', ERROR => '0'),
       21      => ( DATA => X"08", VALID => '1', ERROR => '0'),
       22      => ( DATA => X"09", VALID => '1', ERROR => '0'),
       23      => ( DATA => X"0A", VALID => '1', ERROR => '0'),
       24      => ( DATA => X"0B", VALID => '1', ERROR => '0'),
       25      => ( DATA => X"0C", VALID => '1', ERROR => '0'),
       26      => ( DATA => X"0D", VALID => '1', ERROR => '0'),
       27      => ( DATA => X"0E", VALID => '1', ERROR => '0'),
       28      => ( DATA => X"0F", VALID => '1', ERROR => '0'),
       29      => ( DATA => X"10", VALID => '1', ERROR => '0'),
       30      => ( DATA => X"11", VALID => '1', ERROR => '0'),
       31      => ( DATA => X"12", VALID => '1', ERROR => '0'),
       32      => ( DATA => X"13", VALID => '1', ERROR => '0'),
       33      => ( DATA => X"14", VALID => '1', ERROR => '0'),
       34      => ( DATA => X"15", VALID => '1', ERROR => '0'),
       35      => ( DATA => X"16", VALID => '1', ERROR => '0'),
       36      => ( DATA => X"17", VALID => '1', ERROR => '0'),
       37      => ( DATA => X"18", VALID => '1', ERROR => '0'),
       38      => ( DATA => X"19", VALID => '1', ERROR => '0'),
       39      => ( DATA => X"1A", VALID => '1', ERROR => '0'),
       40      => ( DATA => X"1B", VALID => '1', ERROR => '0'),
       41      => ( DATA => X"1C", VALID => '1', ERROR => '0'),
       42      => ( DATA => X"1D", VALID => '1', ERROR => '0'),
       43      => ( DATA => X"1E", VALID => '1', ERROR => '0'),
       44      => ( DATA => X"1F", VALID => '1', ERROR => '0'),
       45      => ( DATA => X"20", VALID => '1', ERROR => '0'),
       46      => ( DATA => X"21", VALID => '1', ERROR => '0'),
       47      => ( DATA => X"22", VALID => '1', ERROR => '0'),
       48      => ( DATA => X"23", VALID => '1', ERROR => '0'),
       49      => ( DATA => X"24", VALID => '1', ERROR => '0'),
       50      => ( DATA => X"25", VALID => '1', ERROR => '0'),
       51      => ( DATA => X"26", VALID => '1', ERROR => '0'),
       52      => ( DATA => X"27", VALID => '1', ERROR => '0'),
       53      => ( DATA => X"28", VALID => '1', ERROR => '0'),
       54      => ( DATA => X"29", VALID => '1', ERROR => '0'),
       55      => ( DATA => X"2A", VALID => '1', ERROR => '0'),
       56      => ( DATA => X"2B", VALID => '1', ERROR => '0'),
       57      => ( DATA => X"2C", VALID => '1', ERROR => '0'),
       58      => ( DATA => X"2D", VALID => '1', ERROR => '0'),
       59      => ( DATA => X"2E", VALID => '1', ERROR => '0'),
       60      => ( DATA => X"2F", VALID => '1', ERROR => '0'), -- 47th Data byte
       others  => ( DATA => X"00", VALID => '0', ERROR => '0')),

      -- No error in this frame
      bad_frame => false),


   -------------
   -- Frame 2
   -------------
    2          => (
      columns  => (
        0      => ( DATA => X"DA", VALID => '1', ERROR => '0'), -- Destination Address (DA)
        1      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        2      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        3      => ( DATA => X"04", VALID => '1', ERROR => '0'),
        4      => ( DATA => X"05", VALID => '1', ERROR => '0'),
        5      => ( DATA => X"06", VALID => '1', ERROR => '0'),
        6      => ( DATA => X"5A", VALID => '1', ERROR => '0'), -- Source Address (5A)
        7      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        8      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        9      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       10      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       11      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       12      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       13      => ( DATA => X"2E", VALID => '1', ERROR => '0'), -- Length/Type = Length = 46
       14      => ( DATA => X"01", VALID => '1', ERROR => '0'),
       15      => ( DATA => X"02", VALID => '1', ERROR => '0'),
       16      => ( DATA => X"03", VALID => '1', ERROR => '0'),
       17      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       18      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       19      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       20      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       21      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       22      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       23      => ( DATA => X"00", VALID => '1', ERROR => '1'), -- Error asserted
       24      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       25      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       26      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       27      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       28      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       29      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       30      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       31      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       32      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       33      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       34      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       35      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       36      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       37      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       38      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       39      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       40      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       41      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       42      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       43      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       44      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       45      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       46      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       47      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       48      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       49      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       50      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       51      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       52      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       53      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       54      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       55      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       56      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       57      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       58      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       59      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       others  => ( DATA => X"00", VALID => '0', ERROR => '0')),

       -- Error this frame
      bad_frame => true),


   -------------
   -- Frame 3
   -------------
   3          => (
      columns  => (
        0      => ( DATA => X"DA", VALID => '1', ERROR => '0'), -- Destination Address (DA)
        1      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        2      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        3      => ( DATA => X"04", VALID => '1', ERROR => '0'),
        4      => ( DATA => X"05", VALID => '1', ERROR => '0'),
        5      => ( DATA => X"06", VALID => '1', ERROR => '0'),
        6      => ( DATA => X"5A", VALID => '1', ERROR => '0'), -- Source Address (5A)
        7      => ( DATA => X"02", VALID => '1', ERROR => '0'),
        8      => ( DATA => X"03", VALID => '1', ERROR => '0'),
        9      => ( DATA => X"04", VALID => '1', ERROR => '0'),
       10      => ( DATA => X"05", VALID => '1', ERROR => '0'),
       11      => ( DATA => X"06", VALID => '1', ERROR => '0'),
       12      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       13      => ( DATA => X"03", VALID => '1', ERROR => '0'), -- Length/Type = Length = 03
       14      => ( DATA => X"01", VALID => '1', ERROR => '0'), -- Therefore padding is required
       15      => ( DATA => X"02", VALID => '1', ERROR => '0'),
       16      => ( DATA => X"03", VALID => '1', ERROR => '0'),
       17      => ( DATA => X"00", VALID => '1', ERROR => '0'), -- Padding starts here
       18      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       19      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       20      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       21      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       22      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       23      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       24      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       25      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       26      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       27      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       28      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       29      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       30      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       31      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       32      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       33      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       34      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       35      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       36      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       37      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       38      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       39      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       40      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       41      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       42      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       43      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       44      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       45      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       46      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       47      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       48      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       49      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       50      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       51      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       52      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       53      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       54      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       55      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       56      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       57      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       58      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       59      => ( DATA => X"00", VALID => '1', ERROR => '0'),
       others  => ( DATA => X"00", VALID => '0', ERROR => '0')),

      -- No error in this frame
      bad_frame => false));


  ------------------------------------------------------------------------------
  -- CRC engine
  ------------------------------------------------------------------------------
  function calc_crc (data : in std_logic_vector;
                     fcs  : in std_logic_vector)
  return std_logic_vector is

    variable crc          : std_logic_vector(31 downto 0);
    variable crc_feedback : std_logic;
  begin

    crc := not fcs;

    for I in 0 to 7 loop
      crc_feedback      := crc(0) xor data(I);

      crc(4 downto 0)   := crc(5 downto 1);
      crc(5)            := crc(6)  xor crc_feedback;
      crc(7 downto 6)   := crc(8 downto 7);
      crc(8)            := crc(9)  xor crc_feedback;
      crc(9)            := crc(10) xor crc_feedback;
      crc(14 downto 10) := crc(15 downto 11);
      crc(15)           := crc(16) xor crc_feedback;
      crc(18 downto 16) := crc(19 downto 17);
      crc(19)           := crc(20) xor crc_feedback;
      crc(20)           := crc(21) xor crc_feedback;
      crc(21)           := crc(22) xor crc_feedback;
      crc(22)           := crc(23);
      crc(23)           := crc(24) xor crc_feedback;
      crc(24)           := crc(25) xor crc_feedback;
      crc(25)           := crc(26);
      crc(26)           := crc(27) xor crc_feedback;
      crc(27)           := crc(28) xor crc_feedback;
      crc(28)           := crc(29);
      crc(29)           := crc(30) xor crc_feedback;
      crc(30)           := crc(31) xor crc_feedback;
      crc(31)           :=             crc_feedback;
    end loop;

    -- return the CRC result
    return not crc;
  end calc_crc;


  ------------------------------------------------------------------------------
  -- Test Bench signals and constants
  ------------------------------------------------------------------------------

  -- Delay to provide setup and hold timing at the GMII/RGMII.
  constant dly : time := 2 ns;

  constant gtx_period : time := 2.5 ns;

  -- testbench signals
  signal gtx_clk              : std_logic;
      

  
  signal mmcm_clk_in_p        : std_logic;
  signal mmcm_clk_in_n        : std_logic;
  signal reset                : std_logic := '0';
  signal demo_mode_error      : std_logic := '0';

  signal mdc                  : std_logic;
  signal mdio                 : std_logic;
  signal mdio_count           : unsigned(5 downto 0) := (others => '0');
  signal last_mdio            : std_logic;
  signal mdio_read            : std_logic;
  signal mdio_addr            : std_logic;
  signal mdio_fail            : std_logic;
  signal rgmii_txc            : std_logic := '0';
  signal rgmii_tx_ctl         : std_logic := '0';
  signal rgmii_txd            : std_logic_vector(3 downto 0) := (others => '0');
  signal rgmii_rxc            : std_logic := '0';
  signal rgmii_rx_ctl         : std_logic := '0';
  signal rgmii_rxd            : std_logic_vector(3 downto 0) := (others => '0');
  signal rgmii_rxc_1000       : std_logic;
  signal rgmii_rxc_100        : std_logic;
  signal rgmii_rxc_10         : std_logic;
  signal inband_link_status   : std_logic;
  signal inband_clock_speed   : std_logic_vector(1 downto 0);
  signal inband_duplex_status : std_logic;

  -- testbench control signals
  signal tx_monitor_finished_1G     : boolean := false;
  signal tx_monitor_finished_10M    : boolean := false;
  signal tx_monitor_finished_100M   : boolean := false;
  signal management_config_finished : boolean := false;
  signal rx_stimulus_finished       : boolean := false;



  signal phy_speed                  : std_logic_vector(1 downto 0) := "10";
  signal mac_speed                  : std_logic_vector(1 downto 0) := "10";
  signal update_speed               : std_logic := '0';

  signal delay_rxc                  : std_logic;
  signal delay_rxc_lcl              : std_logic;

  signal rgmii_rxd_dut              : std_logic_vector(3 downto 0);
  signal rgmii_rx_ctl_dut           : std_logic;

  signal gen_tx_data                : std_logic;
  signal check_tx_data              : std_logic;
  signal config_bist                : std_logic;
  
  signal frame_error                : std_logic;
  signal bist_mode_error            : std_logic;
  signal serial_response            : std_logic;




begin

  delay_rxc_lcl <= rgmii_rxc after 2 ns;
  -- only want the delay if the rgmii isn't looped back
  delay_rxc     <= rgmii_txc when (TB_MODE = "BIST") else delay_rxc_lcl;


  -- select between loopback or local data
  rgmii_rxd_dut    <= rgmii_txd when (TB_MODE = "BIST") else rgmii_rxd;
  rgmii_rx_ctl_dut <= rgmii_tx_ctl when (TB_MODE = "BIST") else rgmii_rx_ctl;


  ------------------------------------------------------------------------------
  -- Wire up Device Under Test
  ------------------------------------------------------------------------------
  dut: tri_mode_ethernet_mac_0_example_design
    port map (
      -- asynchronous reset
      --------------------------------
      glbl_rst             => reset,

      -- 200MHz clock input from board
      clk_in_p             => mmcm_clk_in_p,
      clk_in_n             => mmcm_clk_in_n,
      -- 125 MHz clock output from MMCM
      gtx_clk_bufg_out     => gtx_clk,

      phy_resetn           => open,


      -- RGMII Interface
      --------------------------------
      rgmii_txd            => rgmii_txd,
      rgmii_tx_ctl         => rgmii_tx_ctl,
      rgmii_txc            => rgmii_txc,
      rgmii_rxd            => rgmii_rxd_dut,
      rgmii_rx_ctl         => rgmii_rx_ctl_dut,
      rgmii_rxc            => delay_rxc,

      -- MDIO Interface
      mdc                  => mdc,
      mdio                 => mdio,


      -- Serialised statistics vectors
      --------------------------------
      tx_statistics_s      => open,
      rx_statistics_s      => open,

      -- Serialised Pause interface controls
      --------------------------------------
      pause_req_s          => '0',

      -- Main example design controls
      -------------------------------
      mac_speed            => mac_speed,
      update_speed         => update_speed,
      config_board         => config_bist,
      serial_response      => serial_response,
      gen_tx_data          => gen_tx_data,
      chk_tx_data          => check_tx_data,
      reset_error          => '0',
      frame_error          => frame_error,
      frame_errorn         => open,
      activity_flash       => open,
      activity_flashn      => open
    );


  ------------------------------------------------------------------------------
  -- If the simulation is still going after delay below
  -- then something has gone wrong: terminate with an error
  ------------------------------------------------------------------------------
  p_timebomb : process
  begin
    wait for 680 us;
    assert false
      report "ERROR - Simulation running forever!"
      severity failure;
  end process p_timebomb;


  ------------------------------------------------------------------------------
  -- Simulate the MDIO
  ------------------------------------------------------------------------------
  -- respond with sensible data to mdio reads and accept writes.
  -- expect mdio to try and read from reg addr 1 - return all 1's if we don't
  -- want any other mdio accesses
  -- if any other response then mdio will write to reg_addr 9 then 4 then 0
  -- (may check for expected write data?)
  -- finally mdio read from reg addr 1 until bit 5 is seen high
  -- NOTE - do not check any other bits so could drive all high again..

  p_mdio_count : process (mdc, reset)
  begin
     if (reset = '1') then
        mdio_count <= (others => '0');
        last_mdio <= '0';
     elsif mdc'event and mdc = '1' then
        last_mdio <= mdio;
        if mdio_count >= "100000" then
           mdio_count <= (others => '0');
        elsif (mdio_count /= "000000") then
           mdio_count <= mdio_count + "000001";
        else  -- only get here if mdio state is 0 - now look for a start
           if mdio = '1' and last_mdio = '0' then
              mdio_count <= "000001";
           end if;
        end if;
     end if;
  end process p_mdio_count;

  mdio <= '1' when (mdio_read = '1' and (mdio_count >= "001110") and (mdio_count <= "011111")) else 'Z';

  -- only respond to phy and reg address == 1 (PHY_STATUS)
  p_mdio_check : process (mdc, reset)
  begin
     if (reset = '1') then
        mdio_read <= '0';
        mdio_addr <= '1'; -- this will go low if the address doesn't match required
        mdio_fail <= '0';
     elsif mdc'event and mdc = '1' then
        if (mdio_count = "000010") then
           mdio_addr <= '1';  -- reset at the start of a new access to enable the address to be revalidated
           if last_mdio = '1' and mdio = '0' then
              mdio_read <= '1';
           else -- take a write as a default as won't drive at the wrong time
              mdio_read <= '0';
           end if;
        elsif mdio_count <= "001100" then
           -- check the phy_addr is 7 and the reg_addr is 0
           if mdio_count <= "000111" and mdio_count >= "000101" then
              if (mdio /= '1') then
                 mdio_addr <= '0';
              end if;
           else
              if (mdio /= '0') then
                 mdio_addr <= '0';
              end if;
           end if;
        elsif mdio_count = "001110" then
           if mdio_read = '0' and (mdio = '1' or last_mdio = '0') then
              assert false
                report "ERROR -  Write TA phase is incorrect" & cr
                severity failure;
           end if;
        elsif (mdio_count >= "001111") and (mdio_count <= "011110") and mdio_addr = '1' then
           if (mdio_read = '0') then
              if (mdio_count = "010100") then
                 if (mdio = '1') then
                    mdio_fail <= '1';
                    assert false
                      report "ERROR -  Expected bit 10 of mdio write data to be 0" & cr
                      severity failure;
                 end if;
              else
                 if (mdio = '0') then
                    mdio_fail <= '1';
                    assert false
                      report "ERROR -  Expected all except bit 10 of mdio write data to be 1" & cr
                      severity failure;
                 end if;
              end if;
           end if;
        end if;
     end if;
  end process p_mdio_check;


  ------------------------------------------------------------------------------
  -- Clock drivers
  ------------------------------------------------------------------------------

  -- drives input to an MMCM at 200MHz which creates gtx_clk at 125 MHz

  p_mmcm_clk : process
  
  begin
    mmcm_clk_in_p <= '0';
    mmcm_clk_in_n <= '1';
    
    wait for 80 ns;
    loop
      wait for gtx_period;
      mmcm_clk_in_p <= '1';
      mmcm_clk_in_n <= '0';
      wait for gtx_period;
      mmcm_clk_in_p <= '0';
      mmcm_clk_in_n <= '1';
    end loop;
  end process p_mmcm_clk;
  

      

  -- drives rgmii_rxc_1000 at 125 MHz
  p_rxc1000 : process
  begin
    rgmii_rxc_1000 <= '0';
    wait for 10 ns;
    loop
      wait for 4 ns;
      rgmii_rxc_1000 <= '1';
      wait for 4 ns;
      rgmii_rxc_1000 <= '0';
    end loop;
  end process p_rxc1000;


  -- drives rgmii_rxc_100 at 25 MHz
  p_rxc100 : process
  begin
    rgmii_rxc_100 <= '0';
    wait for 10 ns;
    loop
      wait for 20 ns;
      rgmii_rxc_100 <= '1';
      wait for 20 ns;
      rgmii_rxc_100 <= '0';
    end loop;
  end process p_rxc100;


  -- drives rgmii_rxc_10 at 2.5 MHz
  p_rxc10 : process
  begin
    rgmii_rxc_10 <= '0';
    wait for 10 ns;
    loop
      wait for 200 ns;
      rgmii_rxc_10 <= '1';
      wait for 200 ns;
      rgmii_rxc_10 <= '0';
    end loop;
  end process p_rxc10;


  -- Select between 10Mb/s, 100Mb/s and 1Gb/s RGMII Rx clock frequencies
  p_selrxc : process(phy_speed, rgmii_rxc_1000, rgmii_rxc_100, rgmii_rxc_10)
  begin
    if phy_speed = "11" then
      rgmii_rxc <= '0';
    elsif phy_speed = "10" then
      rgmii_rxc <= rgmii_rxc_1000;
    elsif phy_speed = "01" then
      rgmii_rxc <= rgmii_rxc_100;
    else
      rgmii_rxc <= rgmii_rxc_10;
    end if;
  end process p_selrxc;



  -- monitor frame error and output error when asserted
  bist_mode_error_p : process (gtx_clk,reset)
  begin
    if reset = '1' then
      bist_mode_error <= '0';
    elsif gtx_clk'event and gtx_clk = '1' then
      if frame_error = '1' and bist_mode_error = '0' then
        bist_mode_error <= '1';
        assert false
          report "Error: Frame mismatch seen" & cr
          severity error;
      end if;
    end if;
  end process bist_mode_error_p;


  -----------------------------------------------------------------------------
  -- Management process. This process sets up the configuration by
  -- turning off flow control, and checks gathered statistics at the
  -- end of transmission
  -----------------------------------------------------------------------------
  p_management : process

    -- Procedure to reset the MAC
    ------------------------------
    procedure mac_reset is
    begin
      assert false
        report "Resetting core..." & cr
        severity note;

      reset <= '1';
      wait for 400 ns;

      reset <= '0';

      assert false
        report "Timing checks are valid" & cr
        severity note;
    end procedure mac_reset;

  begin  -- process p_management

  assert false
      report "Timing checks are not valid" & cr
      severity note;
    mac_speed <= "10";
    phy_speed <= "10";
    update_speed <= '0';
    gen_tx_data <= '0';
    check_tx_data <= '0';
    config_bist <= '0';


    -- reset the core
    mac_reset;


    wait until mdio_count = "100000";
    wait until mdio_count = "000000";


    if TB_MODE = "BIST" then
       gen_tx_data <= '1';
       check_tx_data <= '1';
       -- run for a set time and then stop
       wait for 100 us;
       -- Our work here is done


         
       if frame_error = '1' then
         
         assert false
           report "ERROR: Frame mismatch seen" & cr
           severity failure;
            

       elsif serial_response = '1' then
          assert false
            report "ERROR: AXI4 Lite state Machine error.  Incorrect or non-existant PTP frame." & cr
            severity failure;
       else
          assert false
            report "Test completed successfully" & cr
            severity note;
          assert false
            report "Simulation Stopped" & cr
            severity failure;
       end if;
    else
       -- Signal that configuration is complete.  Other processes will now
       -- be allowed to run.
       management_config_finished <= true;

       -- The stimulus process will now send 4 frames at 1Gb/s.
       --------------------------------------------------------------------

       -- Wait for 1G monitor process to complete.
       wait until tx_monitor_finished_1G;
       management_config_finished <= false;


       -- Change the speed to 100Mb/s and send the 4 frames
       --------------------------------------------------------------------

       wait until gtx_clk'event and gtx_clk = '1';
       mac_speed <= "01";
       update_speed <= '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       update_speed <= '0';

       wait until mdio_count = "001000";
       phy_speed <= "01";
       wait until mdio_count = "100000";
       wait until mdio_count = "000000";

       -- Signal that configuration is complete.  Other processes will now
       -- be allowed to run.
       management_config_finished <= true;

       -- Wait for 100M monitor process to complete.
       wait until tx_monitor_finished_100M;
       management_config_finished <= false;
       -- Change the speed to 10Mb/s and send the 4 frames
       --------------------------------------------------------------------

       wait until gtx_clk'event and gtx_clk = '1';
       mac_speed <= "00";
       update_speed <= '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       update_speed <= '0';

       wait until mdio_count = "001000";
       phy_speed <= "00";
       wait until mdio_count = "100000";
       wait until mdio_count = "000000";

       -- Signal that configuration is complete.  Other processes will now
       -- be allowed to run.
       management_config_finished <= true;

       -- Wait for 100M monitor process to complete.
       wait until tx_monitor_finished_10M;
       management_config_finished <= false;

       -- Change the speed back to 1Gb/s and send the 4 frames
       --------------------------------------------------------------------

       wait until gtx_clk'event and gtx_clk = '1';
       mac_speed <= "10";
       phy_speed <= "10";
       update_speed <= '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       wait until gtx_clk'event and gtx_clk = '1';
       update_speed <= '0';

       wait until mdio_count = "001000";
       wait until mdio_count = "100000";
       wait until mdio_count = "000000";

       -- Signal that configuration is complete.  Other processes will now
       -- be allowed to run.
       management_config_finished <= true;


       wait;
    end if;
  end process p_management;



  ------------------------------------------------------------------------------
  -- Stimulus process. This process will inject frames of data into the
  -- PHY side of the receiver.
  ------------------------------------------------------------------------------
  p_stimulus : process

    ----------------------------------------------------------
    -- Procedure to inject a frame into the receiver at 1Gb/s
    ----------------------------------------------------------
    procedure send_frame_1g (current_frame : in natural) is
      variable current_col   : natural := 0;  -- Column counter within frame
      variable fcs           : std_logic_vector(31 downto 0);
    begin

      wait until rgmii_rxc'event and rgmii_rxc = '1';

      -- Reset the FCS calculation
      fcs         := (others => '0');

      -- Adding the preamble field
      for j in 0 to 13 loop
        rgmii_rxd   <= "0101";
        rgmii_rx_ctl <= '1';
        wait until rgmii_rxc'event;
      end loop;

      -- Adding the Start of Frame Delimiter (SFD)
      rgmii_rxd   <= "0101";
      rgmii_rx_ctl <= '1';
      wait until rgmii_rxc'event;
      rgmii_rxd   <= "1101";
      rgmii_rx_ctl <= '1';
      wait until rgmii_rxc'event;
      current_col := 0;
      rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(3 downto 0));
      rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
      wait until rgmii_rxc'event;
      rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 4));
      rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
      fcs          := calc_crc(to_stdlogicvector(frame_data(current_frame).columns(current_col).data), fcs);

      wait until rgmii_rxc'event;

      current_col := current_col + 1;
      -- loop over columns in frame.
      while frame_data(current_frame).columns(current_col).valid /= '0' loop
        -- send one column of data
        -- send rising edge data
        rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(3 downto 0));
        rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
        wait until rgmii_rxc'event;
        -- send falling edge data
        rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 4));
        rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid xor
                                     frame_data(current_frame).columns(current_col).error);
        fcs          := calc_crc(to_stdlogicvector(frame_data(current_frame).columns(current_col).data), fcs);
        current_col := current_col + 1;
        wait until rgmii_rxc'event;  -- wait for next clock tick
      end loop;

      -- Send the CRC.
      for j in 0 to 3 loop
         rgmii_rxd    <= fcs(((8*j)+3) downto (8*j));
         rgmii_rx_ctl <= '1';
         wait until rgmii_rxc'event;
         rgmii_rxd    <= fcs(((8*j)+7) downto ((8*j)+4));
         rgmii_rx_ctl <= '1';
         wait until rgmii_rxc'event;  -- wait for next clock tick
      end loop;

      -- Clear the data lines.
      rgmii_rxd   <= (others => '0');
      rgmii_rx_ctl <=  '0';

      -- Adding the minimum Interframe gap for a receiver (8 idles)
      for j in 0 to 7 loop
        wait until rgmii_rxc'event and rgmii_rxc = '1';
      end loop;

    end send_frame_1g;


    ---------------------------------------------------------------
    -- Procedure to inject a frame into the receiver at 10/100Mb/s
    ---------------------------------------------------------------
    procedure send_frame_10_100m (current_frame : in natural) is
      variable current_col   : natural := 0;  -- Column counter within frame
      variable fcs           : std_logic_vector(31 downto 0);
    begin

      wait until rgmii_rxc'event and rgmii_rxc = '1';

      -- Reset the FCS calculation
      fcs         := (others => '0');

      -- Adding the preamble field
      for j in 0 to 13 loop
        rgmii_rxd    <= "0101";
        rgmii_rx_ctl <= '1';
        wait until rgmii_rxc'event and rgmii_rxc = '1';
      end loop;

      -- Adding the Start of Frame Delimiter (SFD)
      rgmii_rxd    <= "0101";
      rgmii_rx_ctl <= '1';
      wait until rgmii_rxc'event and rgmii_rxc = '1';
      rgmii_rxd    <= "1101";
      rgmii_rx_ctl <= '1';
      wait until rgmii_rxc'event and rgmii_rxc = '1';
      current_col := 0;
      rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(3 downto 0));
      rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
      wait until rgmii_rxc'event and rgmii_rxc = '1';
      rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 4));
      rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
      fcs          := calc_crc(to_stdlogicvector(frame_data(current_frame).columns(current_col).data), fcs);
      wait until rgmii_rxc'event and rgmii_rxc = '1';

      current_col := current_col + 1;
      -- loop over columns in frame.
      while frame_data(current_frame).columns(current_col).valid /= '0' loop
        -- send one column of data
        -- send rising edge data
        rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(3 downto 0));
        rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid);
        wait until rgmii_rxc'event and rgmii_rxc = '1';
        -- send falling edge data
        rgmii_rxd    <= to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 4));
        rgmii_rx_ctl <= to_stdUlogic(frame_data(current_frame).columns(current_col).valid xor
                                       frame_data(current_frame).columns(current_col).error);
        fcs          := calc_crc(to_stdlogicvector(frame_data(current_frame).columns(current_col).data), fcs);
        current_col := current_col + 1;
        wait until rgmii_rxc'event and rgmii_rxc = '1';

      end loop;

      -- Send the CRC.
      for j in 0 to 3 loop
         rgmii_rxd    <= fcs(((8*j)+3) downto (8*j));
         rgmii_rx_ctl <= '1';
         wait until rgmii_rxc'event and rgmii_rxc = '1';
         rgmii_rxd    <= fcs(((8*j)+7) downto ((8*j)+4));
         rgmii_rx_ctl <= '1';
         wait until rgmii_rxc'event and rgmii_rxc = '1';
      end loop;

      -- Clear the data lines.
      rgmii_rxd    <= (others => '0');
      rgmii_rx_ctl <=  '0';

      -- Adding the minimum Interframe gap for a receiver (8 idles)
      for j in 0 to 14 loop
        wait until rgmii_rxc'event and rgmii_rxc = '1';
      end loop;

    end send_frame_10_100m;
  begin


    -- Send four frames through the MAC and Design Exampled
    -- at each state Ethernet speed
    --      -- frame 0 = minimum length frame
    --      -- frame 1 = type frame
    --      -- frame 2 = errored frame
    --      -- frame 3 = padded frame
    -------------------------------------------------------


    -- 1 Gb/s speed
    -------------------------------------------------------
    -- Wait for the Management MDIO transaction to finish.
    wait until management_config_finished;
    -- Wait for the internal resets to settle
    wait for 800 ns;

    assert false
      report "Sending four frames at 1Gb/s..." & cr
      severity note;

    for current_frame in frame_data'low to frame_data'high loop
      send_frame_1g(current_frame);
    end loop;

    -- Wait for 1G monitor process to complete.
    wait until tx_monitor_finished_1G;
    wait for 10 ns;

    -- 100 Mb/s speed
    -------------------------------------------------------
    -- Wait for the Management MDIO transaction to finish.
    wait until management_config_finished;
    assert false
      report "Sending four frames at 100Mb/s..." & cr
      severity note;

    for current_frame in frame_data'low to frame_data'high loop
      send_frame_10_100m(current_frame);
    end loop;

    -- Wait for 100M monitor process to complete.
    wait until tx_monitor_finished_100M;

    wait for 10 ns;

    -- 10 Mb/s speed
    -------------------------------------------------------
    -- Wait for the Management MDIO transaction to finish.
    wait until management_config_finished;
    assert false
      report "Sending four frames at 10Mb/s..." & cr
      severity note;

    for current_frame in frame_data'low to frame_data'high loop
      send_frame_10_100m(current_frame);
    end loop;

    -- Wait for 100M monitor process to complete.
    wait until tx_monitor_finished_10M;

    wait for 10 ns;

    -- 1 Gb/s speed
    -------------------------------------------------------
    -- Wait for the Management MDIO transaction to finish.
    wait until management_config_finished;
    assert false
      report "Sending four frames at 1Gb/s..." & cr
      severity note;

    for current_frame in frame_data'low to frame_data'high loop
      send_frame_1g(current_frame);
    end loop;

    -- Wait for 1G monitor process to complete.
    wait until tx_monitor_finished_1G;
    rx_stimulus_finished <= true;

    -- Our work here is done
    if (demo_mode_error = '0' and bist_mode_error = '0') then
      assert false
        report "Test completed successfully"
        severity note;
    end if;
    assert false
      report "Simulation stopped"
      severity failure;
  end process p_stimulus;



  ------------------------------------------------------------------------------
  -- Monitor process. This process checks the data coming out of the
  -- transmitter to make sure that it matches that inserted into the
  -- receiver.
  ------------------------------------------------------------------------------
  p_monitor : process

    ---------------------------------------------------
    -- Procedure to check a transmitted frame at 1Gb/s
    ---------------------------------------------------
    procedure check_frame_1g (current_frame : in natural) is
      variable current_col   : integer := 0;  -- Column counter within frame
      variable fcs           : std_logic_vector(31 downto 0);
      variable frame_type    : string(1 to 4) := (others => ' ');
      -- Holds rising and falling rgmii data set
      variable rgmii_column  : std_logic_vector(7 downto 0);
    begin

      -- Reset the FCS calculation
      fcs         := (others => '0');
      -- wait until the first real column of data to come out of RX client
      while rgmii_tx_ctl /= '1' loop
        wait until rgmii_txc'event;
      end loop;

      -- check tx_ctl has gone high at the correct edge (should be rising)
      if (rgmii_txc = '0') then
        demo_mode_error <= '1';
        assert false
          report "tx_ctl started on incorrect phase" & cr
          severity error;
      end if;

      -- Parse over the preamble field
      while rgmii_txd = "0101" loop
        wait until rgmii_txc'event and rgmii_txc = '0';
      end loop;

      -- Parse over the Start of Frame Delimiter (SFD)
      if (rgmii_txd /= "1101") then
        demo_mode_error <= '1';
        assert false
          report "SFD not present" & cr
          severity error;
      end if;
      wait until rgmii_txc'event and rgmii_txc = '1';

      if TB_MODE = "DEMO" then
         -- Start comparing transmitted data to received data
         assert false
           report "Comparing Transmitted Data Frames to Received Data Frames" & cr
           severity note;

         -- frame has started, loop over columns of frame
         while ((frame_data(current_frame).columns(current_col).valid)='1') loop

           rgmii_column(3 downto 0) := rgmii_txd;
           if rgmii_tx_ctl = '0' then
             demo_mode_error <= '1';
             assert false
               report "rgmii_tx_ctl indicates data not valid, prior to expected end of frame" & cr
               severity error;
           end if;
           wait until rgmii_txc'event and rgmii_txc = '0';
           rgmii_column(7 downto 4) := rgmii_txd;

           if rgmii_tx_ctl = '1' then

               -- The transmitted Destination Address was the Source Address of the injected frame
               if current_col < 6 then
                 if rgmii_column(7 downto 0) /=
                       to_stdlogicvector(frame_data(current_frame).columns(current_col+6).data(7 downto 0)) then
                   demo_mode_error <= '1';
                   assert false
                     report "rgmii_txd incorrect during Destination Address" & cr
                     severity error;
                 end if;

               -- The transmitted Source Address was the Destination Address of the injected frame
               elsif current_col >= 6 and current_col < 12 then
                 if rgmii_column(7 downto 0) /=
                       to_stdlogicvector(frame_data(current_frame).columns(current_col-6).data(7 downto 0)) then
                   demo_mode_error <= '1';
                   assert false
                     report "rgmii_txd incorrect during Source Address" & cr
                     severity error;
                 end if;

               -- for remainder of frame
               else
                 if rgmii_column(7 downto 0) /=
                       to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 0)) then
                   demo_mode_error <= '1';
                   assert false
                     report "rgmii_txd incorrec" & cr
                     severity error;
                 end if;
               end if;
           else
             demo_mode_error <= '1';
             assert false
               report "rgmii_tx_ctl indicates data not valid, prior to expected end of frame" & cr
               severity error;
           end if;

           -- calculate expected crc for the frame
           fcs        := calc_crc(rgmii_column, fcs);

           -- wait for next column of data
           current_col        := current_col + 1;
           wait until rgmii_txc'event and rgmii_txc = '1';
         end loop;  -- while data valid

         -- Check the FCS
         -- Having checked all data columns, txd must contain FCS.
         for j in 0 to 3 loop

           rgmii_column(3 downto 0) := rgmii_txd;
           if rgmii_tx_ctl = '0' then
             demo_mode_error <= '1';
             assert false
               report "rgmii_tx_ctl incorrect during FCS field" & cr
               severity error;
           end if;
           wait until rgmii_txc'event and rgmii_txc = '0';
           rgmii_column(7 downto 4) := rgmii_txd;

           if rgmii_tx_ctl = '0' then
             demo_mode_error <= '1';
             assert false
               report "rgmii_tx_ctl incorrect during FCS field" & cr
               severity error;
           end if;

           if rgmii_column /= fcs(((8*j)+7) downto (8*j)) then
             demo_mode_error <= '1';
             assert false
               report "rgmii_txd incorrect during FCS field" & cr
               severity error;
           end if;

           wait until rgmii_txc'event and rgmii_txc = '1';
         end loop;  -- j
      else
         frame_type        := (others => ' ');
         while (rgmii_tx_ctl='1') loop
           rgmii_column(3 downto 0) := rgmii_txd;
           wait until rgmii_txc'event and rgmii_txc = '0';
           rgmii_column(7 downto 4) := rgmii_txd;
           if current_col = 12 and rgmii_column = X"81" then
              frame_type := "VLAN";
           end if;
           -- wait for next column of data
           current_col        := current_col + 1;
           wait until rgmii_txc'event and rgmii_txc = '1';

         end loop;  -- while data valid
         assert false
           report frame_type & " Frame tramsmitted : Size " & integer'image(current_col) & cr
           severity note;
      end if;
    end check_frame_1g;


    --------------------------------------------------------
    -- Procedure to check a transmitted frame at 10/100Mb/s
    --------------------------------------------------------
    procedure check_frame_10_100m (current_frame : in natural) is
      variable current_col   : natural := 0;  -- Column counter within frame
      variable fcs           : std_logic_vector(31 downto 0);

      -- Holds rising and falling rgmii data set
      variable rgmii_column  : std_logic_vector(7 downto 0);
    begin

      -- Reset the FCS calculation
      fcs         := (others => '0');


      -- wait until the first real column of data to come out of RX client
      while rgmii_tx_ctl /= '1' loop
        wait until rgmii_txc'event;
      end loop;

      -- check tx_ctl has gone high at the correct edge (should be rising)
      if (rgmii_txc = '0') then
        demo_mode_error <= '1';
        assert false
          report "tx_ctl started on incorrect phase" & cr
          severity error;
      end if;

      -- Parse over the preamble field
      while rgmii_txd = "0101" loop
        wait until rgmii_txc'event and rgmii_txc = '1';
      end loop;

      -- Start comparing transmitted dat to received data
      assert false
        report "Comparing Transmitted Data Frames to Received Data Frames" & cr
        severity note;

      -- Parse over the Start of Frame Delimiter (SFD)
      if (rgmii_txd /= "1101") then
        demo_mode_error <= '1';
        assert false
          report "SFD not present" & cr
          severity error;
      end if;
      wait until rgmii_txc'event and rgmii_txc = '1';

      -- frame has started, loop over columns of frame
      while ((frame_data(current_frame).columns(current_col).valid)='1') loop

        rgmii_column(3 downto 0) := rgmii_txd;
        if rgmii_tx_ctl = '0' then
          demo_mode_error <= '1';
          assert false
            report "rgmii_tx_ctl indicates data not valid, prior to expected end of frame" & cr
            severity error;
        end if;

        wait until rgmii_txc'event and rgmii_txc = '1';
        rgmii_column(7 downto 4) := rgmii_txd;

        if rgmii_tx_ctl = '1' then

            -- The transmitted Destination Address was the Source Address of the injected frame
            if current_col < 6 then
              if rgmii_column(7 downto 0) /=
                  to_stdlogicvector(frame_data(current_frame).columns(current_col+6).data(7 downto 0)) then
                demo_mode_error <= '1';
                assert false
                  report "rgmii_txd incorrect during Destination Address" & cr
                  severity error;
              end if;

            -- The transmitted Source Address was the Destination Address of the injected frame
            elsif current_col >= 6 and current_col < 12 then
              if rgmii_column(7 downto 0) /=
                  to_stdlogicvector(frame_data(current_frame).columns(current_col-6).data(7 downto 0)) then
                demo_mode_error <= '1';
                assert false
                  report "rgmii_txd incorrect during Source Address" & cr
                  severity error;
              end if;


            -- for remainder of frame
            else
              if rgmii_column(7 downto 0) /=
                  to_stdlogicvector(frame_data(current_frame).columns(current_col).data(7 downto 0)) then
                demo_mode_error <= '1';
                assert false
                  report "rgmii_txd incorrect" & cr
                  severity error;
              end if;

            end if;
        else
          demo_mode_error <= '1';
          assert false
            report "rgmii_tx_ctl indicates data not valid, prior to expected end of frame" & cr
            severity error;
        end if;

        -- calculate expected crc for the frame
        fcs        := calc_crc(rgmii_column, fcs);

        -- wait for next column of data
        current_col        := current_col + 1;
        wait until rgmii_txc'event and rgmii_txc = '1';
      end loop;  -- while data valid

      -- Check the FCS
      -- Having checked all data columns, txd must contain FCS.
      for j in 0 to 3 loop

        rgmii_column(3 downto 0) := rgmii_txd;
        if rgmii_tx_ctl = '0' then
          demo_mode_error <= '1';
          assert false
            report "rgmii_tx_ctl incorrect during FCS field" & cr
            severity error;
        end if;
        wait until rgmii_txc'event and rgmii_txc = '1';
        rgmii_column(7 downto 4) := rgmii_txd;

        if rgmii_tx_ctl = '0' then
          demo_mode_error <= '1';
          assert false
            report "rgmii_tx_ctl incorrect during FCS field" & cr
            severity error;
        end if;

        if rgmii_column /= fcs(((8*j)+7) downto (8*j)) then
          demo_mode_error <= '1';
          assert false
            report "rgmii_txd incorrect during FCS field" & cr
            severity error;
        end if;

        wait until rgmii_txc'event and rgmii_txc = '0';
        -- check tx_ctl has gone low at the correct edge (should be rising)
        if rgmii_tx_ctl = '0' then
          demo_mode_error <= '1';
          assert false
            report "tx_ctl stopped on incorrect phase" & cr
            severity error;
        end if;

        wait until rgmii_txc'event and rgmii_txc = '1';
      end loop;  -- j
    end check_frame_10_100m;


    variable f                  : tri_mode_ethernet_mac_0_frame_typ;       -- temporary frame variable
    variable current_frame      : natural   := 0;  -- current frame pointer


  begin  -- process p_monitor


    -- Compare the transmitted frame to the received frames
    --      -- frame 0 = minimum length frame
    --      -- frame 1 = type frame
    --      -- frame 2 = errored frame
    --      -- frame 3 = padded frame
    -- Repeated for all stated speeds.
    -------------------------------------------------------

    -- wait for reset to complete before starting monitor to ignore false startup errors
    wait until reset'event and reset = '0';

    if TB_MODE = "DEMO" then

       -- 1 Gb/s speed
       -------------------------------------------------------

       current_frame      := 0;


       -- Look for 1Gb/s frames.
       -- loop over all the frames in the stimulus record
       loop

         -- If the current frame had an error inserted then it would have been
         -- dropped by the FIFO in the design example.  Therefore move immediately
         -- on to the next frame.
         while frame_data(current_frame).bad_frame loop
           current_frame := current_frame + 1;
         if current_frame = frame_data'high + 1 then
             exit;
           end if;
         end loop;

         -- There are only 4 frames in this test.
         if current_frame = frame_data'high + 1 then
           exit;
         end if;

         -- Check the current frame
         check_frame_1g(current_frame);

         -- move to the next frame
         if current_frame = frame_data'high then
           exit;
         else
           current_frame := current_frame + 1;
         end if;

       end loop;
       wait for 200 ns;
       tx_monitor_finished_1G <= true;

       -- 100 Mb/s speed
       -------------------------------------------------------

       current_frame      := 0;

       -- Look for 100Mb/s frames.
       -- loop over all the frames in the stimulus vector
       loop

         -- If the current frame had an error inserted then it would have been
         -- dropped by the FIFO in the design example.  Therefore move immediately
         -- on to the next frame.
         while frame_data(current_frame).bad_frame loop
           current_frame := current_frame + 1;
         if current_frame = frame_data'high + 1 then
             exit;
           end if;
         end loop;

         -- There are only 4 frames in this test.
         if current_frame = frame_data'high + 1 then
           exit;
         end if;

         -- Check the current frame
         check_frame_10_100m(current_frame);

         -- move to the next frame
         if current_frame = frame_data'high then
           exit;
         else
           current_frame := current_frame + 1;
         end if;

       end loop;
       wait for 200 ns;
       tx_monitor_finished_100M <= true;
       tx_monitor_finished_1G <= false;

       -- 10 Mb/s speed
       -------------------------------------------------------

       current_frame      := 0;

       -- Look for 10Mb/s frames.
       -- loop over all the frames in the stimulus vector
       loop

         -- If the current frame had an error inserted then it would have been
         -- dropped by the FIFO in the design example.  Therefore move immediately
         -- on to the next frame.
         while frame_data(current_frame).bad_frame loop
           current_frame := current_frame + 1;
           if current_frame = frame_data'high + 1 then
             exit;
           end if;
         end loop;

         -- There are only 4 frames in this test.
         if current_frame = frame_data'high + 1 then
           exit;
         end if;

         -- Check the current frame
         check_frame_10_100m(current_frame);

         -- move to the next frame
         if current_frame = frame_data'high then
           exit;
         else
           current_frame := current_frame + 1;
         end if;

       end loop;
       wait for 200 ns;
       tx_monitor_finished_10M <= true;

       -- 1 Gb/s speed
       -------------------------------------------------------

       current_frame      := 0;

       -- Look for 1Gb/s frames.
       -- loop over all the frames in the stimulus record
       loop

         -- If the current frame had an error inserted then it would have been
         -- dropped by the FIFO in the design example.  Therefore move immediately
         -- on to the next frame.
         while frame_data(current_frame).bad_frame loop
           current_frame := current_frame + 1;
           if current_frame = frame_data'high + 1 then
             exit;
           end if;
         end loop;

         -- There are only 4 frames in this test.
         if current_frame = frame_data'high + 1 then
           exit;
         end if;

         -- Check the current frame
         check_frame_1g(current_frame);

         -- move to the next frame
         if current_frame = frame_data'high then
           exit;
         else
           current_frame := current_frame + 1;
         end if;

       end loop;
       wait for 200 ns;
       tx_monitor_finished_1G <= true;


       wait;
    else
       loop
         check_frame_1g(current_frame);
       end loop;
    end if;
  end process p_monitor;




end behav;

