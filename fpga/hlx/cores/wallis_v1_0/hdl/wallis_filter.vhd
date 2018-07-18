-------------------------------------------------------------------------------
-- Title       : Wallis Filter
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_filter.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Tue Jul 17 09:19:14 2018
-- Last update : Wed Jul 18 15:40:35 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Wallis algorithm
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity wallis_filter is
    --generic (

    --);

    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     	: in    std_logic;
        rst_n   	: in    std_logic;

        -- inputs
        ------------------------------------------------------------------------
        pixel 		: in 	std_logic_vector(7 downto 0);
        n_mean		: in 	std_logic_vector(7 downto 0);
        n_var		: in 	std_logic_vector(13 downto 0);
        i_den 		: in 	std_logic_vector(19 downto 0);
        
        -- constant inputs
        par_c_gvar	: in 	std_logic_vector(19 downto 0);
        par_ci_gvar	: in 	std_logic_vector(19 downto 0);
        par_c 		: in 	std_logic_vector(5 downto 0);
        par_b_gmean : in 	std_logic_vector(13 downto 0);
        par_bi		: in 	std_logic_vector(5 downto 0);

        -- outputs
        ------------------------------------------------------------------------
        o_den		: out	std_logic_vector(19 downto 0);
        wallis 		: out	std_logic_vector(7 downto 0);

        -- controls
        ------------------------------------------------------------------------
        valid		: out	std_logic;
        en 			: in 	std_logic;
        clear		: in 	std_logic

    );
end entity wallis_filter;

architecture rtl of wallis_filter is
	signal pi_nmean : signed(8 downto 0);
	signal num : signed(29 downto 0);
	signal den : unsigned(19 downto 0);
	signal add : unsigned(13 downto 0);


begin
	pi_nmean <= signed(resize(unsigned(pixel), pi_nmean'length)) - signed(resize(unsigned(n_mean), pi_nmean'length));
	den <= (unsigned(n_var) * unsigned(par_c)) + unsigned(par_ci_gvar); 

	p_numerator : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				num <= (others => '0');
			else
				if (clear = '1') then
					num <= (others => '0');
				else
					if (en = '1') then
						num <= pi_nmean * signed(resize(unsigned(par_c_gvar), par_c_gvar'length+1));
						else
						num <= num;	
					end if;	
				end if;
			end if;
		end if;	
	end process; -- p_numerator

	p_add : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				add <= (others => '0');
			else
				if (clear = '1') then
					add <= (others => '0');
				else
					if (en = '1') then
						add <= unsigned(n_mean) * unsigned(par_bi) + unsigned(par_b_gmean);
						else
						add <= add;	
					end if;	
				end if;
			end if;
		end if;	
	end process; -- p_add



end architecture rtl;
