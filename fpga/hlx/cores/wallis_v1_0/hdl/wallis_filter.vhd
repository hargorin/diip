-------------------------------------------------------------------------------
-- Title       : Wallis Filter
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_filter.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Tue Jul 17 09:19:14 2018
-- Last update : Tue Jul 24 14:41:52 2018
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
        
        -- constant inputs
        par_c_gvar	: in 	std_logic_vector(19 downto 0);
        par_ci_gvar	: in 	std_logic_vector(19 downto 0);
        par_c 		: in 	std_logic_vector(5 downto 0);
        par_b_gmean : in 	std_logic_vector(13 downto 0);
        par_bi		: in 	std_logic_vector(5 downto 0);

        -- outputs
        ------------------------------------------------------------------------
        wallis 		: out	std_logic_vector(7 downto 0);

        -- divider core
        ------------------------------------------------------------------------
        -- dividend
        m_axis_dividend_tvalid : out	std_logic;
        m_axis_dividend_tready : in 	std_logic;
        m_axis_dividend_tdata  : out	std_logic_vector(23 downto 0);

        -- divisor
        m_axis_divisor_tvalid  : out	std_logic;
        m_axis_divisor_tready  : in 	std_logic;
        m_axis_divisor_tdata   : out	std_logic_vector(15 downto 0);

        -- quotient
        s_axis_dout_tvalid 	   : in 	std_logic;
        s_axis_dout_tready 	   : out 	std_logic;
        s_axis_dout_tdata 	   : in 	std_logic_vector(31 downto 0);

        -- controls
        ------------------------------------------------------------------------
        valid		: out	std_logic;
        en 			: in 	std_logic;
        clear		: in 	std_logic

    );
end entity wallis_filter;

architecture rtl of wallis_filter is
	signal pi_nmean : signed(8 downto 0);
	signal num 		: signed(29 downto 0);
	signal den 		: signed(20 downto 0);
	signal add 		: unsigned(13 downto 0);
	signal quo 		: signed(31 downto 0);
	signal wal 		: signed(29 downto 0);


begin
	pi_nmean <= signed(resize(unsigned(pixel), pi_nmean'length)) - signed(resize(unsigned(n_mean), pi_nmean'length));
	den <= signed(resize((unsigned(n_var) * unsigned(par_c)) + unsigned(par_ci_gvar), den'length)); 
	num <= pi_nmean * signed(resize(unsigned(par_c_gvar), par_c_gvar'length+1));

    -----------------------------------------------------------
    -- Clocked addition and multiplication for relaxed timing
    -----------------------------------------------------------
	p_add : process(clk) is
    -----------------------------------------------------------
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				add <= (others => '0');
			else
				add <= unsigned(n_mean) * unsigned(par_bi) + unsigned(par_b_gmean);
			end if;
		end if;
	end process; -- p_add
    -----------------------------------------------------------

	s_axis_dout_tready <= '1';
	quo <= signed(s_axis_dout_tdata);

	wal <= quo(31 downto 2) + signed(resize(add, wal'length));


	m_axis_dividend_tdata <= std_logic_vector(num(29 downto 6));
	m_axis_divisor_tdata <= std_logic_vector((15 downto 15 => '0') & den(20 downto 6));

    -----------------------------------------------------------
    -- Set valid on input enable and clear valid on divider
    -- ready to start a single division
    -----------------------------------------------------------
	p_division : process(clk) is
    -----------------------------------------------------------
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				m_axis_dividend_tvalid <= '0';
				m_axis_divisor_tvalid <= '0';
			else
				if (clear = '1') then
					m_axis_dividend_tvalid <= '0';
					m_axis_divisor_tvalid <= '0';
				else
					if en = '1' then
						m_axis_dividend_tvalid <= '1';
						m_axis_divisor_tvalid <= '1';
					else
						if m_axis_dividend_tready = '1' then
							m_axis_dividend_tvalid <= '0';
						end if;
						if m_axis_divisor_tready = '1' then
							m_axis_divisor_tvalid <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process; -- p_division
    -----------------------------------------------------------

	p_wallis_out : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				wallis <= (others => '0');
				valid <= '0';
			else
				if (clear = '1') then
					wallis <= (others => '0');
				else
					valid <= '0';
					if (s_axis_dout_tvalid = '1') then
						valid <= '1';
						if (wal(wal'length -1 downto 6) > to_signed(255,24)) then
							wallis <= std_logic_vector(to_unsigned(255, wallis'length));
						elsif (wal(wal'length -1 downto 6) < to_signed(0,24)) then
							wallis <= (others => '0');
						else
							wallis <= std_logic_vector(wal(13 downto 6));
						end if;
					end if;
				end if;
			end if;
		end if;
	end process; -- p_wallis_out
end architecture rtl;
