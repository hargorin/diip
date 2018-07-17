-------------------------------------------------------------------------------
-- Title       : Mean and Variance Testbench
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : mean_var_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : FHNW
-- Created     : Tue Jul 10 16:22:03 2018
-- Last update : Tue Jul 17 15:56:55 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Testbench to calculate the mean and variance
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity mean_var_tb is

end entity mean_var_tb;

-----------------------------------------------------------

architecture testbench of mean_var_tb is

	-- Testbench DUT generics as constants
    constant WIN_SIZE    : positive                  := 21*21;
    constant M_IN_WIDTH  : positive                  := 8;
    constant M_OUT_WIDTH : positive                  := 17;
    constant V_IN_WIDTH  : positive                  := 16;
    constant V_OUT_WIDTH : positive                  := 25;
	constant FIX_N		 : unsigned(14 downto 0) := "100101001001101";

	-- Testbench DUT ports as signals
    signal clk     : std_logic;
    signal rst_n   : std_logic;
    signal inData  : std_logic_vector(7 downto 0);
    signal outMean : std_logic_vector(7 downto 0);
    signal outVar  : std_logic_vector(13 downto 0);
    signal valid   : std_logic :='0';
    signal en      : std_logic :='0';
    signal clear   : std_logic :='0';

	-- Other constants
    constant clk_period : time := 10 ns;
    signal stop_sim  : std_logic := '0';

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for clk_period / 2.0;
        clk <= '0';
        wait for clk_period / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 20.0*clk_period;
        wait;
    end process RESET_GEN;


p_valid : process(clk) is
begin
	if rising_edge(clk) then
		if valid = '1' then
	    	report "mean = " & integer'image(to_integer(unsigned(outMean)));
	    	report "Var  = " & integer'image(to_integer(unsigned(outVar)));
		end if;
	end if;
		
end process; -- p_valid
	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;

        ------------------------------------------------------------------------
        -- Sends a file via axi stream
        -- Data in file must be 1 byte per line, hex without 0x
        -- ---------------------------------------------------------------------
        procedure file2axistream ( fname : in string ) is
        ------------------------------------------------------------------------
            file fd             : text;
            variable iline      : line;
            variable byte       : std_logic_vector(7 downto 0);
            variable nbytes     : integer := 0;
        begin
            file_open(fd, fname, read_mode);
            -- Count numbers of bytes in file
            while not endfile(fd) loop
                readline (fd, iline);
                nbytes := nbytes + 1;
            end loop;
            file_close(fd);
            file_open(fd, fname, read_mode);
            --mac_rx_tlast <= '0';
            -- output the bytes to the axi stream
            while not endfile(fd) loop
                --if mac_rx_tready = '1' then
                    en <= '1';
                    --if nbytes = 1 then mac_rx_tlast <= '1'; end if;
                    readline (fd, iline);
                    hread(iline,byte);
                    inData <= byte;
                    nbytes := nbytes - 1;
                --end if;
                waitfor(1);
            end loop;
            en <= '0';
            --mac_rx_tlast <= '0';
            waitfor(1);
        end procedure file2axistream;


    begin
    	waitfor(25);

    	-- randi([0,255],441,1)

    	file2axistream("../../cores/wallis_v1_0/bench/rand.txt");

    	-- Output:
    	-- mean: 134.0
    	-- var:  5485.7
    	-- mean: 138.0
    	-- var:  5639.6
    	-- mean: 144.0
    	-- var:  5883.5
    	-- mean: 137.1
    	-- var:  6524.8 
    	-- mean: 132
    	-- var:  6758.9
    	
    	-- Clear
    	clear <= '1';
    	waitfor(3);
    	clear <= '0';
    	report "**************** Clear ****************";
    	waitfor(3);


    	file2axistream("../../cores/wallis_v1_0/bench/rand.txt");


		--en <= '1';
		--inData <= x"FF";
		--waitfor(500);
		--en <= '0';
		--assert (outMean = x"FF") report "Mean is not 2" severity error;

		waitfor(20);
        stop_sim <= '1';
        wait;
	end process; -- p_sim
	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.mean_var
        generic map (
            WIN_SIZE    => WIN_SIZE,
            M_IN_WIDTH  => M_IN_WIDTH,
            M_OUT_WIDTH => M_OUT_WIDTH,
            V_IN_WIDTH  => V_IN_WIDTH,
            V_OUT_WIDTH => V_OUT_WIDTH,
            FIX_N		=> FIX_N
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            inData  => inData,
            outMean => outMean,
            outVar  => outVar,
            valid   => valid,
            en      => en,
            clear   => clear
        );

end architecture testbench;