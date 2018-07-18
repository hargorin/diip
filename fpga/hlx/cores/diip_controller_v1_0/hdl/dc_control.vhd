-------------------------------------------------------------------------------
-- Title       : diip control
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_control.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Jul 18 11:44:02 2018
-- Last update : Wed Jul 18 14:51:21 2018
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
	signal img_width : std_logic_vector(24 downto 0);
	signal win_size : std_logic_vector(17 downto 0);
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
		        uft_tx_data_size <= (others => '0');
    		else
    			-- check if wallis end line
    			if wa_tlast = '1' then
    				tx_req := true;
    			end if;

    			-- start transmission if requested and ready
    			if tx_req and uft_tx_ready = '1' then
    				tx_req := false;
    				-- could insert custom tcid here if UFT was implemented
    				uft_tx_row_num <= (others => '0'); 
    				uft_tx_data_size <= std_logic_vector(resize(unsigned(img_width) - resize(unsigned(win_size),25) + 1,32));
    				uft_tx_start <= '1';
    			else
    				uft_tx_start <= '0';
    			end if;

			end if;
		end if;
    end process ; -- p_init_tx
    -- ---------------------------------------------------------------------


end architecture ; -- behav