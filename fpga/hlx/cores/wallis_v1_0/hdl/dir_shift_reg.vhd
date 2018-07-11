-------------------------------------------------------------------------------
-- Title       : Direct Shift Register
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dir_shift_reg.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Wed Jul 11 11:11:19 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
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
    	constant delay	: positive := 4
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
	type shift_reg is array (0 to delay) of std_logic_vector(7 downto 0);

begin

	p_in : process(clk) is	
		variable byte_shift_reg : shift_reg;

	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				byte_shift_reg := (others => (others => '0'));
				dataoutm <= (others => '0');
			else
				if (clear = '1') then
					byte_shift_reg := (others => (others => '0'));
				else
					if (en = '1') then
						byte_shift_reg(1 to delay) := byte_shift_reg(0 to delay - 1);
						byte_shift_reg(0) := datain;
						dataoutm <= byte_shift_reg(delay);
					else
						byte_shift_reg := byte_shift_reg;
					end if;
				end if;
			end if;
		end if;		
	end process; -- p_in


	p_out : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				dataoutp <= (others => '0');
			else
				if (en = '1') then
					dataoutp <= datain;
				else 
					--dataoutp  <= dataoutp;
				end if;
			end if;
		end if;			
	end process; -- p_out


	p_valid : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				valid  <= '0';
			else
				if (en = '1') then
					valid  <= '1';
				else
					valid  <= '0';
				end if;
			end if;
		end if;	
	end process; -- p_valid

end architecture rtl;
