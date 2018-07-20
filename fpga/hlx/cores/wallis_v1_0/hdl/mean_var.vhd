-------------------------------------------------------------------------------
-- Title       : Mean and Varince
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : mean_var.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : FHNW
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Tue Jul 17 15:51:07 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Calculate the mean and variance from a neighborhood
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity mean_var is
    generic (
    	WIN_SIZE	: positive := 21;
		M_IN_WIDTH 	: positive := 8;
		M_OUT_WIDTH : positive := 17;
		V_IN_WIDTH 	: positive := 16;
		V_OUT_WIDTH : positive := 25;	

    	FIX_N		: unsigned(14 downto 0) := "100101001001101" -- "1001010010011011100100101"
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
        valid 	: out 	std_logic;
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
        generic (
        	constant IN_WIDTH : positive := 8;
    		constant OUT_WIDTH : positive := 17
        );
        port (
            clk   : in  std_logic;
            rst_n : in  std_logic;
            inp   : in  std_logic_vector(IN_WIDTH - 1  downto 0);
            inm   : in  std_logic_vector(IN_WIDTH - 1  downto 0);
            sum   : out std_logic_vector(OUT_WIDTH - 1 downto 0);
            en    : in  std_logic;
            clear : in  std_logic
        );
    end component sum_diff;            

    -- Shift Register Connections
    signal shift_DataIn 	: std_logic_vector(7 downto 0);
    signal shift_DataOutp	: std_logic_vector(7 downto 0);
    signal shift_DataOutm 	: std_logic_vector(7 downto 0);
    signal shift_Valid 		: std_logic;
    signal shift_En 		: std_logic;
    signal shift_Clear 		: std_logic;

    -- Difference Connections
    signal diffM_Inp	: std_logic_vector(M_IN_WIDTH - 1 downto 0);
    signal diffM_Inm	: std_logic_vector(M_IN_WIDTH - 1 downto 0);
    signal diffM_Sum	: std_logic_vector(M_OUT_WIDTH - 1 downto 0);
    signal diffM_En		: std_logic;
    signal diffM_Clear	: std_logic;

   	signal diffV_Inp	: std_logic_vector(V_IN_WIDTH - 1 downto 0);
    signal diffV_Inm	: std_logic_vector(V_IN_WIDTH - 1 downto 0);
    signal diffV_Sum	: std_logic_vector(V_OUT_WIDTH - 1 downto 0);
    signal diffV_En		: std_logic;
    signal diffV_Clear	: std_logic;

    -- signals
	signal mean 	: unsigned(M_OUT_WIDTH + FIX_N'length - 1 downto 0);
	signal mean2 	: unsigned(35 downto 0);
	signal var_tmp 	: unsigned(V_OUT_WIDTH + FIX_N'length - 1 downto 0);
	signal var 		: unsigned(mean2'length - 1 downto 0);

	signal inCtr 	: natural range 0 to 441;
	signal init 	: boolean := false;

begin
	-- Pixel Input and Enable
	shift_DataIn  <= inData;
	shift_En <= en;

	-- Difference Calculation from Input Pixels
    diffM_Inp <= shift_DataOutp;
    diffM_Inm <= shift_DataOutm;
    diffM_En <= shift_Valid;

	diffV_Inp <= std_logic_vector(unsigned(shift_DataOutp) * unsigned(shift_DataOutp));
    diffV_Inm <= std_logic_vector(unsigned(shift_DataOutm) * unsigned(shift_DataOutm)); 
    diffV_En <= shift_Valid;  

    -- Output Mean and Variance
    mean <= unsigned(diffM_Sum) * FIX_N;
    mean2 <= mean(30 downto 13) * mean(30 downto 13);
    var_tmp <= unsigned(diffV_Sum) * FIX_N;
    var <= var_tmp(38 downto 3) - mean2(35 downto 0);

    -- Output FlipFlops
	p_out_mean : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				outMean <= (others => '0');
			else
				outMean <= std_logic_vector(mean(30 downto 23));
			end if;
		end if;	
	end process; -- p_out_mean

	p_out_var : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				outVar <= (others => '0');
			else
				outVar <= std_logic_vector(var(33 downto 20));
			end if;
		end if;	
	end process; -- p_out_var

	p_inCtr : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				inCtr <= 0;
				init <= false;
			else
				if (clear = '1') then
					inCtr <= 0;
					init <= false;
				else
					if (en = '1') then
						if init = false then
							if inCtr = WIN_SIZE - 1 then
								inCtr <= 0;
								init <= true;
							else
								inCtr <= inCtr + 1;
							end if;
						else
							if inCtr = 20 then
								inCtr <= 0;
							else
								inCtr <= inCtr + 1;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process; -- p_inCtr

	p_valid : process(clk) is
		variable valid_count_en : boolean := false;
		variable counter	 : natural range 0 to 3;
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				valid_count_en := false;
				valid <= '0';
			else
				-- start counter at last input value
				if init = false then
					if inCtr = WIN_SIZE - 1 then
						valid_count_en := true;
					end if;
				else
					if inCtr = 20 then
						valid_count_en := true;
					end if;
				end if;

				-- run counter and output
				valid <= '0';
				if valid_count_en then
					if counter = 2 then
						counter := 0;
						valid_count_en := false;
						valid <= '1';
					else
						counter := counter + 1;	
					end if;
				end if;
			end if;
		end if;	
	end process; -- p_valid

	p_clear : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then		
			else
				if(clear = '1') then
					shift_Clear <= clear;
					diffM_Clear <= clear;
					diffV_Clear <= clear;
				else
					shift_Clear <= clear;
					diffM_Clear <= clear;
					diffV_Clear <= clear;
				end if;				
			end if;
			
		end if;
		
	end process; -- p_clear


    c_dir_shift_reg : dir_shift_reg
        generic map (
            delay => WIN_SIZE
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
        generic map (
            IN_WIDTH => M_IN_WIDTH,
            OUT_WIDTH => M_OUT_WIDTH
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            inp   => diffM_Inp,
            inm   => diffM_Inm,
            sum   => diffM_Sum,
            en    => diffM_En,
            clear => diffM_Clear
        ); 

    c_sum_diff_v : sum_diff
        generic map (
            IN_WIDTH => V_IN_WIDTH,
            OUT_WIDTH => V_OUT_WIDTH
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            inp   => diffV_Inp,
            inm   => diffV_Inm,
            sum   => diffV_Sum,
            en    => diffV_En,
            clear => diffV_Clear
        );   
end architecture rtl;
