-------------------------------------------------------------------------------
-- Title       : Simple FIFO
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : axis_fifo.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov  8 15:04:30 2017
-- Last update : Thu Jul 19 12:24:02 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: axi stram fifo
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity axis_fifo is
    Generic (
        constant DATA_WIDTH  : positive := 8;
        constant FIFO_DEPTH : positive := 256
    );
    Port ( 
        CLK     : in  STD_LOGIC;
        RST_N     : in  STD_LOGIC;

        -- out
        M_AXIS_TVALID   : out   std_logic;
        M_AXIS_TDATA    : out   std_logic_vector(DATA_WIDTH-1 downto 0);
        M_AXIS_TREADY   : in    std_logic;
        M_AXIS_TLAST    : out   std_logic;

        -- in
        S_AXIS_TVALID   : in   std_logic;
        S_AXIS_TDATA    : in   std_logic_vector(DATA_WIDTH-1 downto 0);
        S_AXIS_TREADY   : out  std_logic;
        S_AXIS_TLAST    : in   std_logic
    );
end axis_fifo;

architecture Behavioral of axis_fifo is

    signal Head_i : natural range 0 to FIFO_DEPTH - 1;
    signal Tail_i : natural range 0 to FIFO_DEPTH - 1;
    signal Looped_i : std_logic;
    signal S_AXIS_TREADY_i : std_logic;
        

begin
    p_in_ready : process( Head_i, Tail_i, Looped_i )
    begin
        -- tready on input
        if ((Looped_i = '1') and (Head_i = Tail_i)) then
            S_AXIS_TREADY_i <= '0'; -- fifo is ready
            S_AXIS_TREADY <= '0';
        else
            S_AXIS_TREADY_i <= '1'; -- fifo is full
            S_AXIS_TREADY <= '1';
        end if;
    end process ; -- p_in_ready

    -- Memory Pointer Process
    fifo_proc : process (CLK)
        -- high bit stores tlast
        type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of std_logic_vector (DATA_WIDTH downto 0);
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
                M_AXIS_TDATA <= (others => '0');
                M_AXIS_TVALID <= '0';
                m_axis_tlast <= '0';
            else
                
                -- read process
                if (S_AXIS_TREADY_i = '1' and S_AXIS_TVALID = '1') then
                    -- Write Data to Memory
                    Memory(Head)(7 downto 0) := S_AXIS_TDATA;
                    Memory(Head)(8) := S_AXIS_TLAST;
                    
                    -- Increment Head pointer as needed
                    if (Head = FIFO_DEPTH - 1) then
                        Head := 0;
                        Looped := true;
                    else
                        Head := Head + 1;
                    end if;
                end if;

                -- Output
                -- make sure output tlast is reset if new data is written
                -- without M_AXIS_TREADY to be '1' 
                if ((Looped = true) or (Head /= Tail)) then
                    M_AXIS_TLAST <= '0';
                end if;
                if (M_AXIS_TREADY = '1') then
                    if ((Looped = true) or (Head /= Tail)) then
                        -- Update data output
                        M_AXIS_TDATA <= Memory(Tail)(7 downto 0);
                        M_AXIS_TLAST <= Memory(Tail)(8);
                        M_AXIS_TVALID <= '1';
                        
                        -- Update Tail pointer as needed
                        if (Tail = FIFO_DEPTH - 1) then
                            Tail := 0;
                            
                            Looped := false;
                        else
                            Tail := Tail + 1;
                        end if;
                        
                        
                    else
                        M_AXIS_TVALID <= '0';
                    end if;
                end if;


                Head_i <= Head;
                Tail_i <= Tail;
                if Looped then
                    Looped_i <= '1';
                else
                    Looped_i <= '0';
                end if;
            end if;
        end if;
    end process;
        
end Behavioral;