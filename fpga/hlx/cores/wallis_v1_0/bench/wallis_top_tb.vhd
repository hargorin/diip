-------------------------------------------------------------------------------
-- Title       : Wallis Filter Top
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_top_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Thu Jul 19 16:06:12 2018
-- Last update : Mon Jul 23 15:53:13 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Testbench for the Wallis filter
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

entity wallis_top_tb is

end entity wallis_top_tb;

-----------------------------------------------------------

architecture testbench of wallis_top_tb is

   -- image width, must be matching test file
    constant IMG_WIDTH : natural := 680;
    -- image height, must be matching test file
    constant IMG_HEIGHT : natural := 558;


	-- Testbench DUT generics as constants
	constant WIN_LENGTH   : positive 			  := 21;
    constant WIN_SIZE     : positive              := 21*21;
    constant M_IN_WIDTH   : positive              := 8;
    constant M_OUT_WIDTH  : positive              := 17;
    constant V_IN_WIDTH   : positive              := 16;
    constant V_OUT_WIDTH  : positive              := 25;
    constant REC_WIN_SIZE : unsigned(14 downto 0) := "100101001001101";

    constant DELAYTIME    : natural 			  := 10;

    constant DATA_WIDTH : positive := 8;
    constant FIFO_DEPTH : positive := 16;

	-- Testbench DUT ports as signals
    signal clk                    : std_logic;
    signal rst_n                  : std_logic;
    signal wa_par_c_gvar          : std_logic_vector (19 downto 0) := "00101101101101000000"; --2925
    signal wa_par_c               : std_logic_vector (5 downto 0) := "110100"; --0.8125
    signal wa_par_ci_gvar         : std_logic_vector (19 downto 0) := "00001010100011000000"; --675
    signal wa_par_b_gmean         : std_logic_vector (13 downto 0) := "00111101100001"; --61.515625
    signal wa_par_bi              : std_logic_vector (5 downto 0) := "100001"; --0.515625
    signal i_axis_tlast           : std_logic;
    signal i_axis_tready          : std_logic;
    signal i_axis_tvalid          : std_logic;
    signal i_axis_tdata           : std_logic_vector(7 downto 0);
    signal o_axis_tlast           : std_logic;
    signal o_axis_tready          : std_logic;
    signal o_axis_tvalid          : std_logic;
    signal o_axis_tdata           : std_logic_vector(7 downto 0);
    signal m_axis_dividend_tvalid : std_logic;
    signal m_axis_dividend_tready : std_logic;
    signal m_axis_dividend_tdata  : std_logic_vector(23 downto 0);
    signal m_axis_divisor_tvalid  : std_logic;
    signal m_axis_divisor_tready  : std_logic;
    signal m_axis_divisor_tdata   : std_logic_vector(15 downto 0);
    signal s_axis_dout_tvalid     : std_logic;
    signal s_axis_dout_tready     : std_logic;
    signal s_axis_dout_tdata      : std_logic_vector(31 downto 0);

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
        --  start: start line (0 is first line)
        --  num: number of lines to send
        -- ---------------------------------------------------------------------
        procedure file2axistream ( fname : in string; start : in natural; num : in natural ) is
        ------------------------------------------------------------------------
            file fd             : text;
            variable iline      : line;
            variable byte       : std_logic_vector(7 downto 0);
            variable nbytes     : integer := 0;
        begin
            file_open(fd, fname, read_mode);
            -- Count numbers of bytes in file
            nbytes := num;
            file_close(fd);
            file_open(fd, fname, read_mode);
            -- seek to first line
            if start > 0 then
                for i in 1 to start loop
                    readline (fd, iline);
                end loop;
            end if;
            i_axis_tlast <= '0';
            -- output the bytes to the axi stream
            for i in 0 to (num-1) loop
                if i_axis_tready = '0' then
                    wait until i_axis_tready = '1';
                end if;
                i_axis_tvalid <= '1';
                if nbytes = 1 then i_axis_tlast <= '1'; end if;
                readline (fd, iline);
                hread(iline,byte);
                i_axis_tdata <= byte;
                nbytes := nbytes - 1;
                waitfor(1);
            end loop;
            i_axis_tvalid <= '0';
            i_axis_tlast <= '0';
            waitfor(1);
        end procedure file2axistream;


    begin
    	waitfor(25);

    	o_axis_tready <= '1';

        --for i in 224 to 264 loop 
        for i in 0 to IMG_HEIGHT-WIN_LENGTH loop 
            file2axistream("../../cores/wallis_v1_0/bench/in_pixel.txt", i*IMG_WIDTH * WIN_LENGTH, IMG_WIDTH * WIN_LENGTH);
            waitfor(50);
        end loop;


		waitfor(100);
        stop_sim <= '1';
        wait;
	end process; -- p_sim

	-----------------------------------------------------------
    -- Testbench Validation
    -- 
    -- Stores the axi stream data into an output file
    -----------------------------------------------------------
        -----------------------------------------------------------
    -- Testbench Validation
    -- 
    -- Stores the axi stream data into an output file
    -----------------------------------------------------------
    p_axi_stream_check : process( clk, rst_n )
        type buf is array (0 to 1800) of std_logic_vector (7 downto 0);
        variable axi_buf : buf;
        variable ctr : natural range 0 to 1800 := 0;
        variable i : natural range 0 to 1800 := 0;
        variable fi : natural range 0 to 1800 := 0;

        file file_axi_s     : text;
        variable oline      : line;

        function format(
                value   : natural;    --- the numeric value
                width   : positive;   -- number of characters
                leading : character := ' ')
            return string --- guarantees to return "width" chars
        is
            constant img: string := integer'image(value);
            variable str: string(1 to width) := (others => leading);
        begin
            if img'length > width then
                report "Format width " & integer'image(width) & " is too narrow for value " & img severity warning;
                str := (others => '*');
            else
                str(width+1-img'length to width) := img;
            end if;
            return str;
        end;
    begin
        if rst_n = '0' then
            ctr := 0;
        elsif rising_edge(clk) then
            if o_axis_tvalid = '1' then
                if o_axis_tvalid = '1' and o_axis_tready = '1' then
                    axi_buf(ctr) := o_axis_tdata;
                    ctr := ctr + 1;
                end if;
                if o_axis_tlast = '1' then
                    file_open(file_axi_s, "axi_stream_res_" & format(fi, 4, '0') & ".log", write_mode);
                    report "Start writing file: " & "axi_stream_res_" & format(fi, 4, '0') & ".log";
                    for i in 0 to (ctr-1) loop
                        hwrite(oline, axi_buf(i), left, 8);
                        writeline(file_axi_s, oline);
                    end loop;
                    file_close(file_axi_s);
                    ctr := 0;
                    fi := fi + 1;
                end if;
            end if;
        end if;
    end process ; -- p_axi_stream_check




	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.wallis_top
        generic map (
        	WIN_LENGTH    => WIN_LENGTH, 
            WIN_SIZE     => WIN_SIZE,
            M_IN_WIDTH   => M_IN_WIDTH,
            M_OUT_WIDTH  => M_OUT_WIDTH,
            V_IN_WIDTH   => V_IN_WIDTH,
            V_OUT_WIDTH  => V_OUT_WIDTH,
            REC_WIN_SIZE => REC_WIN_SIZE
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            wa_par_c_gvar          => wa_par_c_gvar,
            wa_par_c               => wa_par_c,
            wa_par_ci_gvar         => wa_par_ci_gvar,
            wa_par_b_gmean         => wa_par_b_gmean,
            wa_par_bi              => wa_par_bi,
            i_axis_tlast           => i_axis_tlast,
            i_axis_tready          => i_axis_tready,
            i_axis_tvalid          => i_axis_tvalid,
            i_axis_tdata           => i_axis_tdata,
            o_axis_tlast           => o_axis_tlast,
            o_axis_tready          => o_axis_tready,
            o_axis_tvalid          => o_axis_tvalid,
            o_axis_tdata           => o_axis_tdata,
            m_axis_dividend_tvalid => m_axis_dividend_tvalid,
            m_axis_dividend_tready => m_axis_dividend_tready,
            m_axis_dividend_tdata  => m_axis_dividend_tdata,
            m_axis_divisor_tvalid  => m_axis_divisor_tvalid,
            m_axis_divisor_tready  => m_axis_divisor_tready,
            m_axis_divisor_tdata   => m_axis_divisor_tdata,
            s_axis_dout_tvalid     => s_axis_dout_tvalid,
            s_axis_dout_tready     => s_axis_dout_tready,
            s_axis_dout_tdata      => s_axis_dout_tdata
        );

    div_model : entity work.div_model
        generic map (
            DELAYTIME => DELAYTIME
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            i1_axis_tready => m_axis_dividend_tready,
            i1_axis_tvalid => m_axis_dividend_tvalid,
            i1_axis_tdata  => m_axis_dividend_tdata,
            i2_axis_tready => m_axis_divisor_tready,
            i2_axis_tvalid => m_axis_divisor_tvalid,
            i2_axis_tdata  => m_axis_divisor_tdata,
            o_axis_tready  => s_axis_dout_tready,
            o_axis_tvalid  => s_axis_dout_tvalid,
            o_axis_tdata   => s_axis_dout_tdata
        );        

end architecture testbench;