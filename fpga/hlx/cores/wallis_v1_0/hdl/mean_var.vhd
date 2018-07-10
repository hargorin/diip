-------------------------------------------------------------------------------
-- Title       : Mean and Varince
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : mean_var.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Tue Jul 10 16:30:40 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Calculate the mean and variance from a neighborhood
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity mean_var is
    generic (
    	constant WIN_LENGTH : positive := 21;
    	constant WIN_SIZE	: positive := (WIN_LENGTH * WIN_LENGTH);
    	constant WIN_DEN	: positive := (1/WIN_SIZE)
    );

    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- inputs
        ------------------------------------------------------------------------
        inData 	: in 	std_logic_vector(7 downto 0);

        -- outputs
        ------------------------------------------------------------------------
        outMean : out	std_logic_vector(7 downto 0);
        outVar	: out	std_logic_vector(13 downto 0);

        -- controls
        ------------------------------------------------------------------------
        valid	: out	std_logic;
        en 		: in 	std_logic;
        clear	: in 	std_logic

    );
end entity mean_var;

architecture rtl of mean_var is

    component dir_shift_reg is
        generic (
            constant delay : positive := 4
        );
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            datain   : in  std_logic_vector(7 downto 0);
            dataoutp : out std_logic_vector(7 downto 0);
            dataoutm : out std_logic_vector(7 downto 0);
            valid    : out std_logic;
            en       : in  std_logic;
            clear    : in  std_logic
        );
    end component dir_shift_reg;	

    component sum_diff is
        port (
            clk   : in  std_logic;
            rst_n : in  std_logic;
            inp   : in  std_logic_vector(7 downto 0);
            inm   : in  std_logic_vector(7 downto 0);
            sum   : out std_logic_vector(17 downto 0);
            en    : in  std_logic;
            clear : in  std_logic
        );
    end component sum_diff;            


	signal mean : unsigned(7 downto 0);
	signal mean2 : unsigned(13 downto 0);
	signal var : unsigned(13 downto 0);

begin

	outMean <= mean;
	outVar <= var;

	p_in : process(clk) is	
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				outMean <= (others => '0');
				outVar <= (others => '0');
			else
				if (clear = '1') then
					shift_Clear  <= '1';
					diffM_Clear <= '1';
					diffV_Clear <= '1';
				else
					if (en = '1') then
						shift_DataIn  <= inData;
					else
						shift_DataIn  <= shift_DataIn;
					end if;
				end if;
			end if;
		end if;		
	end process; -- p_in


	p_out_mean : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				mean := (others => '0');
			else
				if (clear = '1') then
					mean := (others => '0');
				else
					if (en = '1') then
						mean := diffM_Sum * WIN_DEN;
					else
						mean := mean;
					end if;
				end if;
			end if;
		end if;	
	end process; -- p_out_mean


	p_mean2 : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				mean2 := (others => '0');
			else
				if (clear = '1') then
					mean2 := (others => '0');
				else
					if (en = '1') then
						mean2 := mean * mean;
					else
						mean2 := mean2;
					end if;
				end if;
			end if;
		end if;		
	end process; -- p_mean2


	p_out_var : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				var := (others => '0');
			else
				if (clear = '1') then
					var := (others => '0');
				else
					if (en = '1') then
						var := (diffV_Sum * WIN_DEN - mean2);
					else
						var := var;
					end if;
				end if;
			end if;
		end if;	
	end process; -- p_out_var


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


    c_dir_shift_reg : dir_shift_reg
        generic map (
            delay => delay
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            datain   => shift_DataIn,
            dataoutp => shift_DataOutp,
            dataoutm => shift_DataOutm,
            valid    => shift_Valid,
            en       => shift_En,
            clear    => shift_Clear
        );


    c_sum_diff_m : sum_diff
        port map (
            clk   => clk,
            rst_n => rst_n,
            inp   => diffM_Inp,
            inm   => diffM_Inm,
            sum   => diffM_Sum,
            en    => diffM_En,
            clear => diffM_Clear
        ); 

    diffM_Inp <= shift_DataOutp;
    diffM_Inm <= shift_DataOutm;
    diffM_En <= shift_Valid;


    c_sum_diff_v : sum_diff
        port map (
            clk   => clk,
            rst_n => rst_n,
            inp   => diffV_Inp,
            inm   => diffV_Inm,
            sum   => diffV_Sum,
            en    => diffV_En,
            clear => diffV_Clear
        );   

    diffV_Inp <= (shift_DataOutp * shift_DataOutp);
    diffV_Inm <= (shift_DataOutm * shift_DataOutm);   
    diffV_En <= shift_Valid;         

end architecture rtl;
