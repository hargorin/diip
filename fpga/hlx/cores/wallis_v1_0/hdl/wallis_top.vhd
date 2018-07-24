-------------------------------------------------------------------------------
-- Title       : Wallis Filter Top
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_top.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Thu Jul 19 13:57:22 2018
-- Last update : Tue Jul 24 08:25:55 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Top for the wallis filter
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity wallis_top is
    generic (
    	WIN_LENGTH	  : positive 			  := 21;
    	WIN_SIZE 	  : positive 			  := 21*21;
        M_IN_WIDTH    : positive              := 8;
        M_OUT_WIDTH   : positive              := 17;
        V_IN_WIDTH    : positive              := 16;
        V_OUT_WIDTH   : positive              := 25;
        REC_WIN_SIZE  : unsigned(14 downto 0) := "100101001001101";
        DATA_WIDTH 	  : positive := 8;
		FIFO_DEPTH    : positive := 16
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     				: in    std_logic;
        rst_n   				: in    std_logic;

        -- control
        ------------------------------------------------------------------------
        wa_par_c_gvar 			: in std_logic_vector (19 downto 0);
        wa_par_c 				: in std_logic_vector (5  downto 0);
        wa_par_ci_gvar 			: in std_logic_vector (19 downto 0);
        wa_par_b_gmean 			: in std_logic_vector (13 downto 0);
        wa_par_bi	 			: in std_logic_vector (5  downto 0);

        -- input stream
        ------------------------------------------------------------------------
        i_axis_tlast            : in std_logic;
        i_axis_tready           : out std_logic;
        i_axis_tvalid           : in std_logic;
        i_axis_tdata            : in std_logic_vector(7 downto 0);
        
        -- output stream
        ------------------------------------------------------------------------
        o_axis_tlast            : out std_logic;
        o_axis_tready           : in std_logic;
        o_axis_tvalid           : out std_logic;
        o_axis_tdata            : out std_logic_vector(7 downto 0);

        -- divisor core
        ------------------------------------------------------------------------
        m_axis_dividend_tvalid : out	std_logic;
        m_axis_dividend_tready : in 	std_logic;
        m_axis_dividend_tdata  : out	std_logic_vector(23 downto 0);
        m_axis_divisor_tvalid  : out	std_logic;
        m_axis_divisor_tready  : in 	std_logic;
        m_axis_divisor_tdata   : out	std_logic_vector(15 downto 0);
        s_axis_dout_tvalid 	   : in 	std_logic;
        s_axis_dout_tready 	   : out 	std_logic;
        s_axis_dout_tdata 	   : in 	std_logic_vector(31 downto 0)
    );
end entity wallis_top;

architecture structural of wallis_top is

    component mean_var is
        generic (
            WIN_SIZE    : positive              := 21*21;
            M_IN_WIDTH  : positive              := 8;
            M_OUT_WIDTH : positive              := 17;
            V_IN_WIDTH  : positive              := 16;
            V_OUT_WIDTH : positive              := 25;
            FIX_N       : unsigned(14 downto 0) := "100101001001101"
        );
        port (
            clk     : in  std_logic;
            rst_n   : in  std_logic;
            inData  : in  std_logic_vector(7 downto 0);
            outMean : out std_logic_vector(7 downto 0);
            outVar  : out std_logic_vector(13 downto 0);
            valid   : out std_logic;
            en      : in  std_logic;
            clear   : in  std_logic
        );
    end component mean_var;

    component wallis_filter is
        port (
            clk                    : in  std_logic;
            rst_n                  : in  std_logic;
            pixel                  : in  std_logic_vector(7 downto 0);
            n_mean                 : in  std_logic_vector(7 downto 0);
            n_var                  : in  std_logic_vector(13 downto 0);
            par_c_gvar             : in  std_logic_vector(19 downto 0);
            par_ci_gvar            : in  std_logic_vector(19 downto 0);
            par_c                  : in  std_logic_vector(5 downto 0);
            par_b_gmean            : in  std_logic_vector(13 downto 0);
            par_bi                 : in  std_logic_vector(5 downto 0);
            wallis                 : out std_logic_vector(7 downto 0);
            m_axis_dividend_tvalid : out std_logic;
            m_axis_dividend_tready : in  std_logic;
            m_axis_dividend_tdata  : out std_logic_vector(23 downto 0);
            m_axis_divisor_tvalid  : out std_logic;
            m_axis_divisor_tready  : in  std_logic;
            m_axis_divisor_tdata   : out std_logic_vector(15 downto 0);
            s_axis_dout_tvalid     : in  std_logic;
            s_axis_dout_tready     : out std_logic;
            s_axis_dout_tdata      : in  std_logic_vector(31 downto 0);
            valid                  : out std_logic;
            en                     : in  std_logic;
            clear                  : in  std_logic
        );
    end component wallis_filter;   

    component simple_fifo is
		generic (
		    constant DATA_WIDTH : positive := 8;
		    constant FIFO_DEPTH : positive := 16
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

    -- Signal Components
    signal n_mean 			: std_logic_vector(7 downto 0);
    signal n_var  			: std_logic_vector(13 downto 0);
    signal valid_mean_var 	: std_logic;
    signal clear  			: std_logic;
    signal m_pixel			: std_logic_vector(7 downto 0);
    signal o_axis_tvalid_i 	: std_logic;
    signal fifo_writeEn		: std_logic;
    signal fifo_dataIn      : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal fifo_readEn      : std_logic;
    signal fifo_dataOut     : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal fifo_rst_n       : std_logic;
    signal wallis_en : std_logic;

    -- Other Signals
    signal init 			: boolean := true;
    signal ctr				: natural range 0 to WIN_SIZE;
    signal o_axis_tlast_i 	: std_logic;

begin
	--i_axis_tready <= '1';
	o_axis_tvalid <= o_axis_tvalid_i;
	o_axis_tlast <= o_axis_tlast_i;

	fifo_dataIn <= i_axis_tdata;
	fifo_readEn <= valid_mean_var;
	m_pixel <= fifo_dataOut;

	-----------------------------------------------------------
	-- Counter to catch the pixel in the middle of the 
	-- neighborhood
	-----------------------------------------------------------
	p_fifo_ctr : process(clk) is
	-----------------------------------------------------------
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				init <= true;
				ctr <= 0;
			else
				if (i_axis_tlast = '1') and (i_axis_tvalid = '1') then
					init <= true;
					ctr <= 0;
				else
					fifo_writeEn <= '0';
					if (i_axis_tvalid = '1') then
						if (init) then
							if (ctr = ((WIN_SIZE - 1)/2) - 1) then
								init <= false;
								ctr <= 0;
								fifo_writeEn <= '1';
							else 	
								ctr <= ctr + 1;
							end if;
						else
							if (ctr = (WIN_LENGTH - 1)) then
								fifo_writeEn <= '1';
								ctr <= 0;
							else
								ctr <= ctr + 1;
							end if;	
						end if;	
					end if;
				end if;
			end if;
		end if;
	end process; -- p_fifo_ctr
	-----------------------------------------------------------

	-----------------------------------------------------------
	-- delay of wallis_en for 1 clock
	-----------------------------------------------------------
	p_wallis_en : process(clk) is
	-----------------------------------------------------------
	begin
		if rising_edge(clk) then
     		if rst_n = '0' then
     			wallis_en <= '0';
     		else
     			wallis_en <= '0';
     			if valid_mean_var = '1' then
     				wallis_en <= '1';
     			end if;
     		end if;
		end if;
	end process; -- p_wallis_en
	-----------------------------------------------------------

	-----------------------------------------------------------
	-- Sets tlast on output if last pixel on input was read
	-- and clears tlast if tlast was read
	-----------------------------------------------------------
	p_tlast : process(clk) is
	-----------------------------------------------------------
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				o_axis_tlast_i <= '0';
			else
				-- sets tlast
				if (i_axis_tlast = '1') and (i_axis_tvalid = '1') then
					o_axis_tlast_i <= '1';
				end if;

				-- clear tlast
				if (o_axis_tvalid_i = '1') and (o_axis_tready = '1') then
					o_axis_tlast_i <= '0';
				end if;
			end if;
		end if;
	end process; -- p_tlast
	-----------------------------------------------------------

    -----------------------------------------------------------
    -- Sets clear if tvalid from output and tlast and tready
    -- are set
    -----------------------------------------------------------
    p_clear : process(clk) is
    -----------------------------------------------------------
        variable clearDone : boolean := false;
    begin
        if rising_edge(clk) then
            if (rst_n = '0') then
                clear <= '0';
                clearDone := false;
                i_axis_tready <= '1';
                fifo_rst_n <= '0';
            else
                -- if input last, disable input ready
                if i_axis_tvalid = '1' and i_axis_tlast = '1' then
                    i_axis_tready <= '0';
                end if;
                -- if clear process is done, re enable inpu
                if clearDone then
                    clearDone := false;
                    i_axis_tready <= '1';
                end if;
                
                -- sets clear after complete computation
                if (o_axis_tvalid_i = '1') and (o_axis_tready = '1') and (o_axis_tlast_i = '1') then
                    clear <= '1';
                    clearDone := true;
                    fifo_rst_n <= '0';
                else
                    clear <= '0';
                    fifo_rst_n <= '1';
                end if;

            end if;
        end if;
    end process; -- p_clear
    -----------------------------------------------------------

	
    c_mean_var : mean_var
        generic map (
            WIN_SIZE    => WIN_SIZE,
            M_IN_WIDTH  => M_IN_WIDTH,
            M_OUT_WIDTH => M_OUT_WIDTH,
            V_IN_WIDTH  => V_IN_WIDTH,
            V_OUT_WIDTH => V_OUT_WIDTH,
            FIX_N       => REC_WIN_SIZE
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            inData  => i_axis_tdata,
            outMean => n_mean,
            outVar  => n_var,
            valid   => valid_mean_var,
            en      => i_axis_tvalid,
            clear   => clear
        );

    c_wallis_filter : wallis_filter
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            pixel                  => m_pixel,
            n_mean                 => n_mean,
            n_var                  => n_var,
            par_c_gvar             => wa_par_c_gvar,
            par_ci_gvar            => wa_par_ci_gvar,
            par_c                  => wa_par_c,
            par_b_gmean            => wa_par_b_gmean,
            par_bi                 => wa_par_bi,
            wallis                 => o_axis_tdata,
            m_axis_dividend_tvalid => m_axis_dividend_tvalid,
            m_axis_dividend_tready => m_axis_dividend_tready,
            m_axis_dividend_tdata  => m_axis_dividend_tdata,
            m_axis_divisor_tvalid  => m_axis_divisor_tvalid,
            m_axis_divisor_tready  => m_axis_divisor_tready,
            m_axis_divisor_tdata   => m_axis_divisor_tdata,
            s_axis_dout_tvalid     => s_axis_dout_tvalid,
            s_axis_dout_tready     => s_axis_dout_tready,
            s_axis_dout_tdata      => s_axis_dout_tdata,
            valid                  => o_axis_tvalid_i,
            en                     => wallis_en,
            clear                  => clear
        );  

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
end architecture structural;
