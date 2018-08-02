-------------------------------------------------------------------------------
-- Title       : Direct Shift Register
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : dir_shift_reg.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : FHNW
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Tue Jul 24 10:23:25 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: A shift register output and a direct output
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity dir_shift_reg is
    generic (
    	WIN_SIZE	: positive := 21*21;
    	DATA_WIDTH  : positive := 8;
    	FIFO_DEPTH  : positive := 21*21 + 3
    );

    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- inputs
        ------------------------------------------------------------------------
        datain 	: in 	std_logic_vector(7 downto 0);

        -- outputs
        ------------------------------------------------------------------------
        dataoutp 	: out	std_logic_vector(7 downto 0);
        dataoutm 	: out	std_logic_vector(7 downto 0);

        -- controls
        ------------------------------------------------------------------------
        valid	: out	std_logic;
        en 		: in 	std_logic;
        clear	: in 	std_logic

    );
end entity dir_shift_reg;

architecture rtl of dir_shift_reg is
    component simple_fifo is
		generic (
		    constant DATA_WIDTH : positive := 8;
		    constant FIFO_DEPTH : positive := WIN_SIZE + 3
        );
	    port (
	        CLK     : in  STD_LOGIC;
	        RST_N   : in  STD_LOGIC;
	        WriteEn : in  STD_LOGIC;
	        DataIn  : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
	        ReadEn  : in  STD_LOGIC;
	        DataOut : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
	        Empty   : out STD_LOGIC;
	        Full    : out STD_LOGIC
	    );
    end component simple_fifo;  

    signal fifo_writeEn		: std_logic;
    signal fifo_dataIn      : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal fifo_readEn      : std_logic;
    signal fifo_dataOut     : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal fifo_rst_n		: std_logic;
    signal ctr				: natural range 0 to WIN_SIZE;
    signal fifo_init		: boolean := true;
begin

	fifo_WriteEn <= en;
	fifo_dataIn <= datain;


    fifo_readEn <=  en when (not fifo_init) else 
                   '1' when (ctr = WIN_SIZE - 1) else
                   '0';

    -- ---------------------------------------------------------------------
    -- Force a latch on all outputs to minimize critical path from
    -- diip controller BRAM to next DSP in sum block
    -- ---------------------------------------------------------------------
    p_out : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                dataoutp <= (others => '0');
                dataoutm <= (others => '0');
                valid <= '0';
                --fifo_readEn <= '0';
            else
                --if (not fifo_init) then
                --    fifo_readEn <=  en;
                --elsif (ctr = WIN_SIZE - 1)  then
                --    fifo_readEn <=  '1';
                --else
                --    fifo_readEn <=  '0';
                --end if;
                    
                dataoutp <= datain;
                dataoutm <= fifo_dataOut;
                valid  <= en;
            end if;
        end if;
    end process ; -- p_out
    -- ---------------------------------------------------------------------

	p_fifo_ctr : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				ctr <= 0;	
                fifo_init <= true;
				fifo_rst_n <= '0';	
			else
				if (clear = '1') then
					ctr <= 0;
                    fifo_init <= true;
					fifo_rst_n <= '0';
				else
					fifo_rst_n <= '1';
					if (en = '1') then
						if (ctr = WIN_SIZE - 2) then
							fifo_init <= false;
						elsif (fifo_init) then
							ctr <= ctr + 1;
						end if;	
					else
						ctr <= ctr;	
						fifo_init <= fifo_init;
				    end if;
				end if;	
			end if;
		end if;
	end process; -- p_fifo_ctr

    c_simple_fifo : simple_fifo
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            CLK     => clk,
            RST_N   => fifo_rst_n,
            WriteEn => fifo_WriteEn,
            DataIn  => fifo_dataIn,
            ReadEn  => fifo_readEn,
            DataOut => fifo_dataOut,
            Empty   => open,
            Full    => open
        ); 
end architecture rtl;
