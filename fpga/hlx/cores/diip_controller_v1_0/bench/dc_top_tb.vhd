-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_top_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Thu Jul 26 11:44:31 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: 
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

entity dc_top_tb is

end entity dc_top_tb;

-----------------------------------------------------------

architecture testbench of dc_top_tb is

    -- wallis filter window size
    constant WIN_SIZE : natural := 3;
    -- image width, must be matching test file
    constant IMG_WIDTH : natural := 5;
    -- image height, must be matching test file
    constant IMG_HEIGHT : natural := 5;
    

    constant WAL_C_GVAR : natural := 10;
    constant WAL_C : natural := 2;
    constant WAL_CI_GVAR : natural := 1;
    constant WAL_B_GMEAN : natural := 1;
    constant WAL_BI : natural := 3;

	-- Testbench DUT generics as constants
    -- Wallis output to UFT Tx Fifo size. Should hold at least one wallis
    -- output line
    constant FIFO_DEPTH : positive := IMG_WIDTH;
    -- number of elements in a  line buffer
    constant BRAM_SIZE : natural := IMG_WIDTH; -- 1024 for simulation
    -- number of lines in cache: minimum is window size + 1
    constant CACHE_N_LINES : natural := WIN_SIZE+1;

    -- Clocks to delay after txstart to accept data
    constant UFT_TX_DELAY : natural := 42;

	-- Testbench DUT ports as signals
    -- clk and reset
    ------------------------------------------------------------------------
    signal clk     :     std_logic;
    signal rst_n   :     std_logic;
    -- UFT RX user interface
    -- ---------------------------------------------------------------------
    signal uft_i_axis_tvalid   :    std_logic;
    signal uft_i_axis_tdata    :    std_logic_vector(7 downto 0);
    signal uft_i_axis_tlast    :    std_logic;
    signal uft_i_axis_tready   :     std_logic;

    signal uft_rx_done            :   std_logic; 
    signal uft_rx_row_num         :  std_logic_vector(31 downto 0);
    signal uft_rx_row_num_valid   :  std_logic;
    signal uft_rx_row_size        :  std_logic_vector(31 downto 0);
    signal uft_rx_row_size_valid  :  std_logic;

    -- User registers
    signal uft_user_reg0           :   std_logic_vector(31 downto 0);
    signal uft_user_reg1           :   std_logic_vector(31 downto 0);
    signal uft_user_reg2           :   std_logic_vector(31 downto 0);
    signal uft_user_reg3           :   std_logic_vector(31 downto 0);
    signal uft_user_reg4           :   std_logic_vector(31 downto 0);
    signal uft_user_reg5           :   std_logic_vector(31 downto 0);
    signal uft_user_reg6           :   std_logic_vector(31 downto 0);
    signal uft_user_reg7           :   std_logic_vector(31 downto 0);

    -- UFT TX user interface
    -- ---------------------------------------------------------------------
    signal uft_o_axis_tvalid              :   std_logic;
    signal uft_o_axis_tlast               :   std_logic;
    signal uft_o_axis_tdata               :   std_logic_vector (7 downto 0);
    signal uft_o_axis_tready              :  std_logic;

    signal uft_tx_start                   :   std_logic;
    signal uft_tx_ready                   :  std_logic;
    signal uft_tx_row_num                 :   std_logic_vector (31 downto 0);
    signal uft_tx_data_size               :   std_logic_vector (31 downto 0);

    -- ---------------------------------------------------------------------
    -- Wallis interface
    -- ---------------------------------------------------------------------
    -- control
    ------------------------------------------------------------------------
    signal wa_par_c_gvar           :  std_logic_vector (19 downto 0);
    signal wa_par_c                :  std_logic_vector (5  downto 0);
    signal wa_par_ci_gvar          :  std_logic_vector (19 downto 0);
    signal wa_par_b_gmean          :  std_logic_vector (13 downto 0);
    signal wa_par_bi               :  std_logic_vector (5  downto 0);

    -- input stream
    ------------------------------------------------------------------------
    signal wa_o_axis_tlast            :  std_logic;
    signal wa_o_axis_tready           :  std_logic;
    signal wa_o_axis_tvalid           :  std_logic;
    signal wa_o_axis_tdata            :  std_logic_vector(7 downto 0);

    -- output stream
    ------------------------------------------------------------------------
    signal wa_i_axis_tlast            :  std_logic;
    signal wa_i_axis_tready           :  std_logic;
    signal wa_i_axis_tvalid           :  std_logic;
    signal wa_i_axis_tdata            :  std_logic_vector(7 downto 0);

	-- Other constants
    constant clk_period : time := 8 ns;
	signal stop_sim : std_logic := '0';

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
                 '1' after 5.0*clk_period;
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
            uft_i_axis_tlast <= '0';
            -- output the bytes to the axi stream
            for i in 0 to (num-1) loop
                if uft_i_axis_tready = '0' then
                    wait until uft_i_axis_tready = '1';
                end if;
                uft_i_axis_tvalid <= '1';
                if nbytes = 1 then uft_i_axis_tlast <= '1'; end if;
                readline (fd, iline);
                hread(iline,byte);
                uft_i_axis_tdata <= byte;
                nbytes := nbytes - 1;
                waitfor(1);
                if i = 1024-1 then
                    uft_i_axis_tvalid <= '0';
                    waitfor(10);
                end if;
            end loop;
            uft_i_axis_tvalid <= '0';
            uft_i_axis_tlast <= '0';
            waitfor(1);
        end procedure file2axistream;
    begin
        uft_i_axis_tvalid    <= '0';
        uft_i_axis_tdata     <= (others => '0');
        uft_i_axis_tlast     <= '0';
        uft_rx_done             <= '0'; 
        uft_rx_row_num          <= (others => '0');
        uft_rx_row_num_valid    <= '0';
        uft_rx_row_size         <= (others => '0');
        uft_rx_row_size_valid   <= '0';
        uft_user_reg0            <= (others => '0');
        uft_user_reg1            <= (others => '0');
        uft_user_reg2            <= (others => '0');
        uft_user_reg3            <= (others => '0');
        uft_user_reg4            <= (others => '0');
        uft_user_reg5            <= (others => '0');
        uft_user_reg6            <= (others => '0');
        uft_user_reg7            <= (others => '0');


        waitfor(10);

        -- Set values on uft user regs
        uft_user_reg1 <= std_logic_vector(to_unsigned(WIN_SIZE,32)); -- win size
        uft_user_reg2 <= std_logic_vector(to_unsigned(IMG_WIDTH,32)); -- img width
        uft_user_reg3 <= std_logic_vector(to_unsigned(WAL_C_GVAR,32)); -- c*gvar
        uft_user_reg4 <= std_logic_vector(to_unsigned(WAL_C,32)); -- c
        uft_user_reg5 <= std_logic_vector(to_unsigned(WAL_CI_GVAR,32)); -- (1-c)*gvar
        uft_user_reg6 <= std_logic_vector(to_unsigned(WAL_B_GMEAN,32)); -- b*g_mean
        uft_user_reg7 <= std_logic_vector(to_unsigned(WAL_BI,32)); -- (1-b)
        waitfor(3);
        
        -- Signal new image
        uft_user_reg0(0) <= '1';
        waitfor(1);
        uft_user_reg0(0) <= '0';

        -- send line after line and be ready for result
        for i in 0 to IMG_HEIGHT-1 loop 
            report "i=" & integer'image(i);
            file2axistream("../../cores/diip_controller_v1_0/bench/mountain.tif.txt", i*IMG_WIDTH, IMG_WIDTH);
            report "i=" & integer'image(i) & " done";
            waitfor(100);
        end loop;

        waitfor(500);

        -- Signal new image
        uft_user_reg0(0) <= '1';
        waitfor(1);
        uft_user_reg0(0) <= '0';

        -- send line after line and be ready for result
        for i in 0 to IMG_HEIGHT-1 loop 
            report "i=" & integer'image(i);
            file2axistream("../../cores/diip_controller_v1_0/bench/mountain.tif.txt", i*IMG_WIDTH, IMG_WIDTH);
            report "i=" & integer'image(i) & " done";
            waitfor(100);
        end loop;

        waitfor(500);


        -- Change img width
        uft_user_reg2 <= std_logic_vector(to_unsigned(IMG_WIDTH-1,32)); -- img width
        -- Signal new image
        uft_user_reg0(0) <= '1';
        waitfor(1);
        uft_user_reg0(0) <= '0';

        -- send line after line and be ready for result
        for i in 0 to IMG_HEIGHT-1 loop 
            report "i=" & integer'image(i);
            file2axistream("../../cores/diip_controller_v1_0/bench/mountain.tif.txt", i*IMG_WIDTH, IMG_WIDTH);
            report "i=" & integer'image(i) & " done";
            waitfor(100);
        end loop;

        waitfor(500);


        -- Change img width
        uft_user_reg2 <= std_logic_vector(to_unsigned(IMG_WIDTH+1,32)); -- img width
        -- Signal new image
        uft_user_reg0(0) <= '1';
        waitfor(1);
        uft_user_reg0(0) <= '0';

        -- send line after line and be ready for result
        for i in 0 to IMG_HEIGHT-1 loop 
            report "i=" & integer'image(i);
            file2axistream("../../cores/diip_controller_v1_0/bench/mountain.tif.txt", i*IMG_WIDTH, IMG_WIDTH);
            report "i=" & integer'image(i) & " done";
            waitfor(100);
        end loop;

        waitfor(500);

        -- Change img width
        uft_user_reg2 <= std_logic_vector(to_unsigned(IMG_WIDTH,32)); -- img width
        -- Signal new image
        uft_user_reg0(0) <= '1';
        waitfor(1);
        uft_user_reg0(0) <= '0';

        -- send line after line and be ready for result
        for i in 0 to IMG_HEIGHT-1 loop 
            report "i=" & integer'image(i);
            file2axistream("../../cores/diip_controller_v1_0/bench/mountain.tif.txt", i*IMG_WIDTH, IMG_WIDTH);
            report "i=" & integer'image(i) & " done";
            waitfor(100);
        end loop;


        waitfor(200);
    	stop_sim <= '1';
    end process;
    
    -----------------------------------------------------------
    p_tx_rdy : process( clk )
    -----------------------------------------------------------
        variable transmitting : boolean := false;
        variable transmittingHeader : boolean := false;
        variable ctr : natural range 0 to UFT_TX_DELAY := 0;
        variable init : boolean := true;
    begin
        if rising_edge(clk) then
            if init then
                uft_tx_ready <= '1';
                uft_o_axis_tready               <= '0';
                init := false;
                ctr := 0;
            end if;

            if uft_tx_start = '1' then
                uft_tx_ready <= '0';
                transmitting := false;
                transmittingHeader := true;
            end if;

            if transmittingHeader then
                ctr := ctr + 1;
                if ctr = UFT_TX_DELAY then
                    transmittingHeader := false;
                    uft_o_axis_tready               <= '1';
                    ctr := 0;
                    transmitting := true;
                end if;
            end if;

            if transmitting and uft_o_axis_tlast = '1' then
                transmitting:=false;
                uft_tx_ready <= '1';
                uft_o_axis_tready               <= '0';
            end if;
        end if;
    end process ; -- p_tx_rdy
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- Testbench Validation
    -- 
    -- Stores the axi stream data into an output file
    -----------------------------------------------------------
    p_axi_stream_check : process( clk, rst_n )
        type buf is array (0 to 32000) of std_logic_vector (7 downto 0);
        variable axi_buf : buf;
        variable ctr : natural range 0 to 32000 := 0;
        variable i : natural range 0 to 32000 := 0;
        variable fi : natural range 0 to 32000 := 0;

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
            if uft_o_axis_tvalid = '1' then
                if uft_o_axis_tvalid = '1' and uft_o_axis_tready = '1' then
                    axi_buf(ctr) := uft_o_axis_tdata;
                    ctr := ctr + 1;
                end if;
                if uft_o_axis_tlast = '1' then
                    file_open(file_axi_s, "axi_stream_res_" & format(fi, 4, '0') & ".log", write_mode);
                    report "writing " & integer'image(ctr) & "bytes axi_stream_res_" & format(fi, 4, '0') & ".log";
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

    p_tx_size_valid : process( clk )
    begin
        if rising_edge(clk) then
            if uft_tx_start = '1' and uft_tx_ready = '1' then
                report "Starting " & integer'image(to_integer(unsigned(uft_tx_data_size))) & " byte tx";
            end if;
        end if;
    end process ; -- p_tx_size_valid

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUV : entity work.dc_top
        generic map (
            FIFO_DEPTH    => FIFO_DEPTH,
            CACHE_N_LINES => CACHE_N_LINES
        )
        port map (
            clk                   => clk,
            rst_n                 => rst_n,
            uft_i_axis_tvalid     => uft_i_axis_tvalid,
            uft_i_axis_tdata      => uft_i_axis_tdata,
            uft_i_axis_tlast      => uft_i_axis_tlast,
            uft_i_axis_tready     => uft_i_axis_tready,
            uft_rx_done           => uft_rx_done,
            uft_rx_row_num        => uft_rx_row_num,
            uft_rx_row_num_valid  => uft_rx_row_num_valid,
            uft_rx_row_size       => uft_rx_row_size,
            uft_rx_row_size_valid => uft_rx_row_size_valid,
            uft_user_reg0         => uft_user_reg0,
            uft_user_reg1         => uft_user_reg1,
            uft_user_reg2         => uft_user_reg2,
            uft_user_reg3         => uft_user_reg3,
            uft_user_reg4         => uft_user_reg4,
            uft_user_reg5         => uft_user_reg5,
            uft_user_reg6         => uft_user_reg6,
            uft_user_reg7         => uft_user_reg7,
            uft_o_axis_tvalid     => uft_o_axis_tvalid,
            uft_o_axis_tlast      => uft_o_axis_tlast,
            uft_o_axis_tdata      => uft_o_axis_tdata,
            uft_o_axis_tready     => uft_o_axis_tready,
            uft_tx_start          => uft_tx_start,
            uft_tx_ready          => uft_tx_ready,
            uft_tx_row_num        => uft_tx_row_num,
            uft_tx_data_size      => uft_tx_data_size,
            wa_par_c_gvar         => wa_par_c_gvar,
            wa_par_c              => wa_par_c,
            wa_par_ci_gvar        => wa_par_ci_gvar,
            wa_par_b_gmean        => wa_par_b_gmean,
            wa_par_bi             => wa_par_bi,
            wa_o_axis_tlast       => wa_o_axis_tlast,
            wa_o_axis_tready      => wa_o_axis_tready,
            wa_o_axis_tvalid      => wa_o_axis_tvalid,
            wa_o_axis_tdata       => wa_o_axis_tdata,
            wa_i_axis_tlast       => wa_i_axis_tlast,
            wa_i_axis_tready      => wa_i_axis_tready,
            wa_i_axis_tvalid      => wa_i_axis_tvalid,
            wa_i_axis_tdata       => wa_i_axis_tdata
        );    

    wallis_model_1 : entity work.wallis_model
        generic map (
            WIN_SIZE => WIN_SIZE
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            wa_par_c_gvar  => wa_par_c_gvar,
            wa_par_c       => wa_par_c,
            wa_par_ci_gvar => wa_par_ci_gvar,
            wa_par_b_gmean => wa_par_b_gmean,
            wa_par_bi      => wa_par_bi,
            i_axis_tlast   => wa_o_axis_tlast,
            i_axis_tready  => wa_o_axis_tready,
            i_axis_tvalid  => wa_o_axis_tvalid,
            i_axis_tdata   => wa_o_axis_tdata,
            o_axis_tlast   => wa_i_axis_tlast,
            o_axis_tready  => wa_i_axis_tready,
            o_axis_tvalid  => wa_i_axis_tvalid,
            o_axis_tdata   => wa_i_axis_tdata
        );    
end architecture testbench;