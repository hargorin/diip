-------------------------------------------------------------------------------
-- Title       : UFT TX Arbiter
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_arbiter.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 29 11:43:40 2017
-- Last update : Wed Nov 29 17:39:26 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Has two AXI stream inputs and 1 output. The input is chosen by
-- a control bit. So its really more a simple MUX than an arbiter...
-- Altough the MUX only switches if the ongoing transaction is complete by
-- reading the tvalid bit
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uft_tx_arbiter is
    port (
        -- Control
        -- ---------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;
        sel     : in    std_logic;
        
        -- Input AXI stream
        -- ---------------------------------------------------------------------
        tvalid_0               : in  std_logic;
        tlast_0                : in  std_logic;
        tdata_0                : in  std_logic_vector (7 downto 0);
        tready_0               : out std_logic;
        
        -- Input AXI stream
        -- ---------------------------------------------------------------------
        tvalid_1               : in  std_logic;
        tlast_1                : in  std_logic;
        tdata_1                : in  std_logic_vector (7 downto 0);
        tready_1               : out std_logic;
        
        -- Output AXI stream
        -- ---------------------------------------------------------------------
        tvalid               : out std_logic;
        tlast                : out std_logic;
        tdata                : out std_logic_vector (7 downto 0);
        tready               : in  std_logic
    );
end entity uft_tx_arbiter;

architecture structural of uft_tx_arbiter is
    signal tvalid_int : std_logic;
    signal sel_int : std_logic := '0';
begin
    ----------------------------------------------------------------------------
    -- Controll process
    -- -------------------------------------------------------------------------
    p_ctl : process( clk, rst_n )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                sel_int <= '0';
            else
                -- only switch if no transaction is running
                if tvalid_int = '0' then
                    sel_int <= sel;
                else
                    sel_int <= sel_int;
                end if;
            end if;
        end if;
    end process ; -- p_ctl

    -- Select logic
    -- -------------------------------------------------------------------------
    tvalid_int <= tvalid_0 when sel_int = '0' else tvalid_1;
    tvalid <= tvalid_int;

    tlast <= tlast_0 when sel_int = '0' else tlast_1;
    tdata <= tdata_0 when sel_int = '0' else tdata_1;

    tready_0 <= tready when sel_int = '0' else '0';
    tready_1 <= tready when sel_int = '1' else '0';

end architecture structural;