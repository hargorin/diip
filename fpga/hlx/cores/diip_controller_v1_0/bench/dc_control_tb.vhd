-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_control_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Thu Jul 19 14:25:35 2018
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

entity dc_control_tb is

end entity dc_control_tb;

-----------------------------------------------------------

architecture testbench of dc_control_tb is

	-- Testbench DUT generics as constants

	-- Testbench DUT ports as signals
    -- clk and reset
    ------------------------------------------------------------------------
    signal clk :    std_logic;
    signal rst_n :    std_logic;

    -- control to mmu
    ------------------------------------------------------------------------
    signal mmu_restart : std_logic;
    signal mmu_win_size : std_logic_vector(17 downto 0);
    signal mmu_img_width : std_logic_vector(24 downto 0);

    -- control UFT
    ------------------------------------------------------------------------
    -- rx line
    signal uft_rx_done : std_logic;
    signal uft_rx_row_num : std_logic_vector(31 downto 0);
    signal uft_rx_row_num_valid : std_logic;
    signal uft_rx_row_size : std_logic_vector(31 downto 0);
    signal uft_rx_row_size_valid : std_logic;
    -- User registers
    signal uft_user_reg0 :  std_logic_vector(31 downto 0);
    signal uft_user_reg1 :  std_logic_vector(31 downto 0);
    signal uft_user_reg2 :  std_logic_vector(31 downto 0);
    signal uft_user_reg3 :  std_logic_vector(31 downto 0);
    signal uft_user_reg4 :  std_logic_vector(31 downto 0);
    signal uft_user_reg5 :  std_logic_vector(31 downto 0);
    signal uft_user_reg6 :  std_logic_vector(31 downto 0);
    signal uft_user_reg7 :  std_logic_vector(31 downto 0);
    -- tx line
    signal uft_tx_start :  std_logic;
    signal uft_tx_ready :   std_logic;
    signal uft_tx_row_num :  std_logic_vector (31 downto 0);
    signal uft_tx_data_size :  std_logic_vector (31 downto 0);

    -- control wallis
    ------------------------------------------------------------------------
    signal wa_tlast : std_logic; -- used for end of line detect
    signal wa_par_c_gvar : std_logic_vector (21 downto 0);
    signal wa_par_c : std_logic_vector (5  downto 0);
    signal wa_par_ci_gvar : std_logic_vector (19 downto 0);
    signal wa_par_b_gmean : std_logic_vector (13 downto 0);
    signal wa_par_bi : std_logic_vector (5  downto 0);

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
    begin
        uft_rx_done <= '0';
        uft_rx_row_num <= (others => '0');
        uft_rx_row_num_valid <= '0';
        uft_rx_row_size <= (others => '0');
        uft_rx_row_size_valid <= '0';
        uft_user_reg0 <= (others => '0');
        uft_user_reg1 <= (others => '0');
        uft_user_reg2 <= (others => '0');
        uft_user_reg3 <= (others => '0');
        uft_user_reg4 <= (others => '0');
        uft_user_reg5 <= (others => '0');
        uft_user_reg6 <= (others => '0');
        uft_user_reg7 <= (others => '0');
        uft_tx_ready <= '0';
        wa_tlast <= '0';

        waitfor(10);

        -- start stim
        -----------------------------------------------------------
        -- fill user registers and init a new image
        -----------------------------------------------------------
        uft_user_reg0 <= std_logic_vector(to_unsigned(1,32));
        uft_user_reg1 <= std_logic_vector(to_unsigned(21,32));
        uft_user_reg2 <= std_logic_vector(to_unsigned(128,32));
        uft_user_reg3 <= std_logic_vector(to_unsigned(30,32));
        uft_user_reg4 <= std_logic_vector(to_unsigned(40,32));
        uft_user_reg5 <= std_logic_vector(to_unsigned(50,32));
        uft_user_reg6 <= std_logic_vector(to_unsigned(60,32));
        uft_user_reg7 <= std_logic_vector(to_unsigned(7,32));

        assert (mmu_restart='0') report "MMU was restarted too early" severity error;
        waitfor(2);
        assert (mmu_restart='1') report "MMU not restarted" severity error;
        assert mmu_img_width=std_logic_vector(to_unsigned(128,25)) report "wrong mmu img width" severity error;
        assert mmu_win_size=std_logic_vector(to_unsigned(21,18)) report "wrong mmu win size" severity error;
        
        assert wa_par_c_gvar=std_logic_vector(to_unsigned(30,22)) report "wrong wa_par_c_gvar" severity error;
        assert wa_par_c=std_logic_vector(to_unsigned(40,6)) report "wrong wa_par_c" severity error;
        assert wa_par_ci_gvar=std_logic_vector(to_unsigned(50,20)) report "wrong wa_par_ci_gvar" severity error;
        assert wa_par_b_gmean=std_logic_vector(to_unsigned(60,14)) report "wrong wa_par_b_gmean" severity error;
        assert wa_par_bi=std_logic_vector(to_unsigned(7,6)) report "wrong wa_par_bi" severity error;

        waitfor(1);
        assert (mmu_restart='0') report "MMU restarted not released" severity error;
        assert mmu_img_width=std_logic_vector(to_unsigned(128,25)) report "wrong mmu img width" severity error;
        assert mmu_win_size=std_logic_vector(to_unsigned(21,18)) report "wrong mmu win size" severity error;
        
        assert wa_par_c_gvar=std_logic_vector(to_unsigned(30,22)) report "wrong wa_par_c_gvar" severity error;
        assert wa_par_c=std_logic_vector(to_unsigned(40,6)) report "wrong wa_par_c" severity error;
        assert wa_par_ci_gvar=std_logic_vector(to_unsigned(50,20)) report "wrong wa_par_ci_gvar" severity error;
        assert wa_par_b_gmean=std_logic_vector(to_unsigned(60,14)) report "wrong wa_par_b_gmean" severity error;
        assert wa_par_bi=std_logic_vector(to_unsigned(7,6)) report "wrong wa_par_bi" severity error;


        -----------------------------------------------------------
        -- indicate end of line from wallis
        -----------------------------------------------------------
        waitfor(10);
        wa_tlast <= '1';
        waitfor(1);
        wa_tlast <= '0';

        -- indicate tx_ready
        waitfor(3);
        uft_tx_ready <= '1';
        waitfor(1);
        uft_tx_ready <= '0';
        waitfor(1);
        assert (uft_tx_start='1') report "UFT tx not started" severity error;
        assert (uft_tx_data_size=std_logic_vector(to_unsigned(128-21+1,32))) report "Wrong UFT tx data size" severity error;
        waitfor(1);
        assert (uft_tx_start='0') report "UFT tx not deasserted" severity error;


        -----------------------------------------------------------
        -- indicate multiple end of line from wallis
        -----------------------------------------------------------
        waitfor(10);
        wa_tlast <= '1';
        waitfor(1);
        wa_tlast <= '0';
        waitfor(1);
        wa_tlast <= '1';
        waitfor(1);
        wa_tlast <= '0';
        waitfor(1);
        wa_tlast <= '1';
        waitfor(1);
        wa_tlast <= '0';

        -- indicate tx_ready
        waitfor(3);
        uft_tx_ready <= '1';
        waitfor(1);
        uft_tx_ready <= '0';
        waitfor(1);
        assert (uft_tx_start='1') report "UFT tx not started" severity error;
        assert (uft_tx_data_size=std_logic_vector(to_unsigned(128-21+1,32))) report "Wrong UFT tx data size" severity error;
        waitfor(1);
        assert (uft_tx_start='0') report "UFT tx not deasserted" severity error;

        waitfor(3);
        uft_tx_ready <= '1';
        waitfor(1);
        uft_tx_ready <= '0';
        waitfor(1);
        assert (uft_tx_start='1') report "UFT tx not started" severity error;
        assert (uft_tx_data_size=std_logic_vector(to_unsigned(128-21+1,32))) report "Wrong UFT tx data size" severity error;
        waitfor(1);
        assert (uft_tx_start='0') report "UFT tx not deasserted" severity error;

        waitfor(3);
        uft_tx_ready <= '1';
        waitfor(1);
        uft_tx_ready <= '0';
        waitfor(1);
        assert (uft_tx_start='1') report "UFT tx not started" severity error;
        assert (uft_tx_data_size=std_logic_vector(to_unsigned(128-21+1,32))) report "Wrong UFT tx data size" severity error;
        waitfor(1);
        assert (uft_tx_start='0') report "UFT tx not deasserted" severity error;



        -----------------------------------------------------------
        -- end of sim
        -----------------------------------------------------------
        waitfor(10);
        stop_sim <= '1';
    end process;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    dc_control_1 : entity work.dc_control
        port map (
            clk                   => clk,
            rst_n                 => rst_n,
            mmu_restart           => mmu_restart,
            mmu_win_size          => mmu_win_size,
            mmu_img_width         => mmu_img_width,
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
            uft_tx_start          => uft_tx_start,
            uft_tx_ready          => uft_tx_ready,
            uft_tx_row_num        => uft_tx_row_num,
            uft_tx_data_size      => uft_tx_data_size,
            wa_tlast              => wa_tlast,
            wa_par_c_gvar         => wa_par_c_gvar,
            wa_par_c              => wa_par_c,
            wa_par_ci_gvar        => wa_par_ci_gvar,
            wa_par_b_gmean        => wa_par_b_gmean,
            wa_par_bi             => wa_par_bi
        );    
end architecture testbench;