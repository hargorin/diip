-------------------------------------------------------------------------------
-- Title       : Simple FIFO
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : simple_fifo.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov  8 15:04:30 2017
-- Last update : Wed Mar  7 13:08:09 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity simple_fifo is
    Generic (
        constant DATA_WIDTH  : positive := 8;
        constant FIFO_DEPTH : positive := 256
    );
    Port ( 
        CLK     : in  STD_LOGIC;
        RST_N     : in  STD_LOGIC;
        WriteEn : in  STD_LOGIC;
        DataIn  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        ReadEn  : in  STD_LOGIC;
        DataOut : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        Empty   : out STD_LOGIC;
        Full    : out STD_LOGIC
    );
end simple_fifo;

architecture Behavioral of simple_fifo is

begin
    -- Memory Pointer Process
    fifo_proc : process (CLK)
        type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        variable Memory : FIFO_Memory;
        
        variable Head : natural range 0 to FIFO_DEPTH - 1;
        variable Tail : natural range 0 to FIFO_DEPTH - 1;
        
        variable Looped : boolean;
    begin
        if rising_edge(CLK) then
            if RST_N = '0' then
                Head := 0;
                Tail := 0;
                
                Looped := false;
                
                Full  <= '0';
                Empty <= '1';

                DataOut <= (others => '0');
            else
                if (ReadEn = '1') then
                    if ((Looped = true) or (Head /= Tail)) then
                        -- Update data output
                        DataOut <= Memory(Tail);
                        
                        -- Update Tail pointer as needed
                        if (Tail = FIFO_DEPTH - 1) then
                            Tail := 0;
                            
                            Looped := false;
                        else
                            Tail := Tail + 1;
                        end if;
                        
                        
                    end if;
                end if;
                
                if (WriteEn = '1') then
                    if ((Looped = false) or (Head /= Tail)) then
                        -- Write Data to Memory
                        Memory(Head) := DataIn;
                        
                        -- Increment Head pointer as needed
                        if (Head = FIFO_DEPTH - 1) then
                            Head := 0;
                            
                            Looped := true;
                        else
                            Head := Head + 1;
                        end if;
                    end if;
                end if;
                
                -- Update Empty and Full flags
                if (Head = Tail) then
                    if Looped then
                        Full <= '1';
                    else
                        Empty <= '1';
                    end if;
                else
                    Empty   <= '0';
                    Full    <= '0';
                end if;
            end if;
        end if;
    end process;
        
end Behavioral;