-------------------------------------------------------------------------------
-- Title       : diip control
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_control.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Jul 18 11:44:02 2018
-- Last update : Thu Jul 19 14:24:09 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: Control of mmu and wallis core
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dc_control is
    --generic (
    --);
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- control to mmu
        ------------------------------------------------------------------------
        mmu_restart         : out std_logic;
        mmu_win_size     	: out std_logic_vector(17 downto 0);
        mmu_img_width    	: out std_logic_vector(24 downto 0);

        -- control UFT
        ------------------------------------------------------------------------
        -- rx line
        uft_rx_done            : in std_logic;
        uft_rx_row_num         : in std_logic_vector(31 downto 0);
        uft_rx_row_num_valid   : in std_logic;
        uft_rx_row_size        : in std_logic_vector(31 downto 0);
        uft_rx_row_size_valid  : in std_logic;
        -- User registers
        uft_user_reg0          : in  std_logic_vector(31 downto 0);
        uft_user_reg1          : in  std_logic_vector(31 downto 0);
        uft_user_reg2          : in  std_logic_vector(31 downto 0);
        uft_user_reg3          : in  std_logic_vector(31 downto 0);
        uft_user_reg4          : in  std_logic_vector(31 downto 0);
        uft_user_reg5          : in  std_logic_vector(31 downto 0);
        uft_user_reg6          : in  std_logic_vector(31 downto 0);
        uft_user_reg7          : in  std_logic_vector(31 downto 0);
        -- tx line
        uft_tx_start           : out  std_logic;
        uft_tx_ready           : in   std_logic;
        uft_tx_row_num         : out  std_logic_vector (31 downto 0);
        uft_tx_data_size       : out  std_logic_vector (31 downto 0);

        -- control wallis
        ------------------------------------------------------------------------
        wa_tlast 				: in std_logic; -- used for end of line detect
        wa_par_c_gvar 			: out std_logic_vector (21 downto 0);
        wa_par_c 				: out std_logic_vector (5  downto 0);
        wa_par_ci_gvar 			: out std_logic_vector (19 downto 0);
        wa_par_b_gmean 			: out std_logic_vector (13 downto 0);
        wa_par_bi	 			: out std_logic_vector (5  downto 0)
    ) ;
end entity ; -- dc_control

architecture behav of dc_control is
    component simple_fifo is
        generic (
            constant DATA_WIDTH : positive := 8;
            constant FIFO_DEPTH : positive := 256
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

	signal img_width : std_logic_vector(24 downto 0);
	signal win_size : std_logic_vector(17 downto 0);

    -- Fifo connections
    signal WriteEn : std_logic;
    signal DataIn : std_logic_vector(31 downto 0);
    signal ReadEn : std_logic;
    signal DataOut : std_logic_vector(31 downto 0);
    signal Empty : std_logic;
    signal Full : std_logic;
begin

	-- ---------------------------------------------------------------------
    -- Map user registers to mmu/wallis control inputs on rising edge of
	-- user register image start
    -- ---------------------------------------------------------------------
	p_new_image : process( clk )
        variable running : boolean := false;
	begin
		if rising_edge(clk) then
			if rst_n = '0' then
                running := false;
		        mmu_restart <= '0';
				wa_par_c_gvar <= (others => '0');
		        wa_par_c <= (others => '0');
		        wa_par_ci_gvar <= (others => '0');
		        wa_par_b_gmean <= (others => '0');
		        wa_par_bi <= (others => '0');
                win_size <= (others => '0');
                img_width <= (others => '0');
			else
                mmu_restart         <= '0';
				if uft_user_reg0(0)='1' and not running then
                    running := true;
			        win_size 		<= uft_user_reg1(17 downto 0);
			        img_width 		<= uft_user_reg2(24 downto 0);
			        mmu_restart 		<= '1';
					wa_par_c_gvar 		<= uft_user_reg3(21 downto 0);
			        wa_par_c 			<= uft_user_reg4(5 downto 0);
			        wa_par_ci_gvar 		<= uft_user_reg5(19 downto 0);
			        wa_par_b_gmean 		<= uft_user_reg6(13 downto 0);
			        wa_par_bi 			<= uft_user_reg7(5 downto 0);
			    elsif uft_user_reg0(0)='0' then
			        running := false;
				end if;
			end if;
		end if;
	end process ; -- p_new_image
    -- ---------------------------------------------------------------------
    mmu_img_width <= img_width;
    mmu_win_size <= win_size;

    -- ---------------------------------------------------------------------
    -- Inits a UFT tx if wallis end line is complete
    -- ---------------------------------------------------------------------
    p_init_tx : process( clk )
    -- ---------------------------------------------------------------------
    	variable tx_req : boolean := false;
    begin
		if rising_edge(clk) then
			if rst_n = '0' then
    			tx_req := false;
		        uft_tx_start <= '0';
		        uft_tx_row_num <= (others => '0');
    		else
                uft_tx_start <= '0';
    			if Empty = '0' and uft_tx_ready = '1' then
                    uft_tx_start <= '1';
    			end if;
			end if;
		end if;
    end process ; -- p_init_tx
    -- ---------------------------------------------------------------------


    -- always write tx size into fifo
    DataIn <= std_logic_vector(resize(unsigned(img_width) - resize(unsigned(win_size),25) + 1,32));
    -- write if wallis tlast
    WriteEn <= wa_tlast when Full = '0' else '0';
    -- Read data goes to uft tx data size
    uft_tx_data_size <= DataOut;
    -- read if fifo is not empty and uft is read
    ReadEn <= '1' when Empty = '0' and uft_tx_ready = '1' else '0';

    -- could insert custom tcid here if UFT was implemented
    uft_tx_row_num <= (others => '0'); 

    -- ---------------------------------------------------------------------
    -- Stores the UFT tx transactions to be made
    -- ---------------------------------------------------------------------
    tx_transaction_fifo : simple_fifo
    -- ---------------------------------------------------------------------
        generic map (
            DATA_WIDTH => 32,
            FIFO_DEPTH => 32
            )
        port map (
            CLK     => clk,
            RST_N   => rst_n,
            WriteEn => WriteEn,
            DataIn  => DataIn,
            ReadEn  => ReadEn,
            DataOut => DataOut,
            Empty   => Empty,
            Full    => Full
        );    
    -- ---------------------------------------------------------------------


end architecture ; -- behav