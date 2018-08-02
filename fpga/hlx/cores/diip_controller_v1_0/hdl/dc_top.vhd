-------------------------------------------------------------------------------
-- Title       : diip controller top
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Jul 19 09:27:06 2018
-- Last update : Thu Jul 26 10:38:59 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: connects mmu, controller and fifo instance
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uft_pkg.all;

entity dc_top is
    generic (
        -- Wallis output to UFT Tx Fifo size. Should hold at least one wallis
        -- output line
        FIFO_DEPTH : positive := 256;
        -- number of elements in a  line buffer
        BRAM_SIZE : natural := 4608; -- 1024 for simulation
        -- number of lines in cache: minimum is window size + 1
        CACHE_N_LINES : natural := 2
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- UFT RX user interface
        -- ---------------------------------------------------------------------
        uft_i_axis_tvalid   : in   std_logic;
        uft_i_axis_tdata    : in   std_logic_vector(7 downto 0);
        uft_i_axis_tlast    : in   std_logic;
        uft_i_axis_tready   : out    std_logic;

        uft_rx_done            : in  std_logic; 
        uft_rx_row_num         : in std_logic_vector(31 downto 0);
        uft_rx_row_num_valid   : in std_logic;
        uft_rx_row_size        : in std_logic_vector(31 downto 0);
        uft_rx_row_size_valid  : in std_logic;
        
        -- User registers
        uft_user_reg0           : in  std_logic_vector(31 downto 0);
        uft_user_reg1           : in  std_logic_vector(31 downto 0);
        uft_user_reg2           : in  std_logic_vector(31 downto 0);
        uft_user_reg3           : in  std_logic_vector(31 downto 0);
        uft_user_reg4           : in  std_logic_vector(31 downto 0);
        uft_user_reg5           : in  std_logic_vector(31 downto 0);
        uft_user_reg6           : in  std_logic_vector(31 downto 0);
        uft_user_reg7           : in  std_logic_vector(31 downto 0);

        -- UFT TX user interface
        -- ---------------------------------------------------------------------
        uft_o_axis_tvalid              : out  std_logic;
        uft_o_axis_tlast               : out  std_logic;
        uft_o_axis_tdata               : out  std_logic_vector (7 downto 0);
        uft_o_axis_tready              : in std_logic;
        
        uft_tx_start                   : out  std_logic;
        uft_tx_ready                   : in std_logic;
        uft_tx_row_num                 : out  std_logic_vector (31 downto 0);
        uft_tx_data_size               : out  std_logic_vector (31 downto 0);

        -- ---------------------------------------------------------------------
        -- Wallis interface
        -- ---------------------------------------------------------------------
        -- control
        ------------------------------------------------------------------------
        wa_par_c_gvar           : out std_logic_vector (19 downto 0);
        wa_par_c                : out std_logic_vector (5  downto 0);
        wa_par_ci_gvar          : out std_logic_vector (19 downto 0);
        wa_par_b_gmean          : out std_logic_vector (13 downto 0);
        wa_par_bi               : out std_logic_vector (5  downto 0);

        -- input stream
        ------------------------------------------------------------------------
        wa_o_axis_tlast            : out std_logic;
        wa_o_axis_tready           : in std_logic;
        wa_o_axis_tvalid           : out std_logic;
        wa_o_axis_tdata            : out std_logic_vector(7 downto 0);
        
        -- output stream
        ------------------------------------------------------------------------
        wa_i_axis_tlast            : in std_logic;
        wa_i_axis_tready           : out std_logic;
        wa_i_axis_tvalid           : in std_logic;
        wa_i_axis_tdata            : in std_logic_vector(7 downto 0)


    );
end entity dc_top;

architecture structural of dc_top is
    component dc_control is
        port (
            clk                   : in  std_logic;
            rst_n                 : in  std_logic;
            mmu_restart           : out std_logic;
            mmu_win_size          : out std_logic_vector(17 downto 0);
            mmu_img_width         : out std_logic_vector(24 downto 0);
            uft_rx_done           : in  std_logic;
            uft_rx_row_num        : in  std_logic_vector(31 downto 0);
            uft_rx_row_num_valid  : in  std_logic;
            uft_rx_row_size       : in  std_logic_vector(31 downto 0);
            uft_rx_row_size_valid : in  std_logic;
            uft_user_reg0         : in  std_logic_vector(31 downto 0);
            uft_user_reg1         : in  std_logic_vector(31 downto 0);
            uft_user_reg2         : in  std_logic_vector(31 downto 0);
            uft_user_reg3         : in  std_logic_vector(31 downto 0);
            uft_user_reg4         : in  std_logic_vector(31 downto 0);
            uft_user_reg5         : in  std_logic_vector(31 downto 0);
            uft_user_reg6         : in  std_logic_vector(31 downto 0);
            uft_user_reg7         : in  std_logic_vector(31 downto 0);
            uft_tx_start          : out std_logic;
            uft_tx_ready          : in  std_logic;
            uft_tx_row_num        : out std_logic_vector (31 downto 0);
            uft_tx_data_size      : out std_logic_vector (31 downto 0);
            wa_tlast              : in  std_logic;
            wa_tvalid             : in  std_logic;
            wa_par_c_gvar         : out std_logic_vector (19 downto 0);
            wa_par_c              : out std_logic_vector (5 downto 0);
            wa_par_ci_gvar        : out std_logic_vector (19 downto 0);
            wa_par_b_gmean        : out std_logic_vector (13 downto 0);
            wa_par_bi             : out std_logic_vector (5 downto 0)
        );
    end component dc_control;
    component dc_mmu is
        generic (
            BRAM_SIZE     : natural := 4608;
            CACHE_N_LINES : natural := 2
        );
        port (
            clk           : in  std_logic;
            rst_n         : in  std_logic;
            restart       : in  std_logic;
            win_size      : in  std_logic_vector(17 downto 0);
            img_width     : in  std_logic_vector(24 downto 0);
            o_axis_tvalid : out std_logic;
            o_axis_tdata  : out std_logic_vector(7 downto 0);
            o_axis_tready : in  std_logic;
            o_axis_tlast  : out std_logic;
            i_axis_tvalid : in  std_logic;
            i_axis_tdata  : in  std_logic_vector(7 downto 0);
            i_axis_tready : out std_logic;
            i_axis_tlast  : in  std_logic
        );
    end component dc_mmu;
    component axis_fifo is
        generic (
            constant DATA_WIDTH : positive := 8;
            constant FIFO_DEPTH : positive := 256
                );
            port (
                CLK           : in  STD_LOGIC;
                RST_N         : in  STD_LOGIC;
                M_AXIS_TVALID : out std_logic;
                M_AXIS_TDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
                M_AXIS_TREADY : in  std_logic;
                M_AXIS_TLAST  : out std_logic;
                S_AXIS_TVALID : in  std_logic;
                S_AXIS_TDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
                S_AXIS_TREADY : out std_logic;
                S_AXIS_TLAST  : in  std_logic
            );
            end component axis_fifo;    

    -- connection between control and mmu
    ------------------------------------------------------------------------
    signal mmu_restart : std_logic;
    signal mmu_win_size : std_logic_vector(17 downto 0);
    signal mmu_img_width : std_logic_vector(24 downto 0);

    -- used to reset stuff
    signal restartn : std_logic;

    -- connection between control and wallis
    ------------------------------------------------------------------------
    signal wa_tlast                : std_logic;
    signal wa_tvalid               : std_logic;

begin
    wa_tlast <= wa_i_axis_tlast;
    wa_tvalid <= wa_i_axis_tvalid;
    -- reset if rst_n or mmu_restart active
    restartn <= '0' when mmu_restart = '1' or rst_n = '0' else '1';

    ------------------------------------------------------------------------
    control : dc_control
    ------------------------------------------------------------------------
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
            wa_tvalid             => wa_tvalid,
            wa_par_c_gvar         => wa_par_c_gvar,
            wa_par_c              => wa_par_c,
            wa_par_ci_gvar        => wa_par_ci_gvar,
            wa_par_b_gmean        => wa_par_b_gmean,
            wa_par_bi             => wa_par_bi
        ); 
    ------------------------------------------------------------------------

    ------------------------------------------------------------------------
    mmu : dc_mmu
    ------------------------------------------------------------------------
        generic map (
            BRAM_SIZE     => BRAM_SIZE,
            CACHE_N_LINES => CACHE_N_LINES
        )
        port map (
            clk           => clk,
            rst_n         => rst_n,
            restart       => mmu_restart,
            win_size      => mmu_win_size,
            img_width     => mmu_img_width,
            o_axis_tvalid => wa_o_axis_tvalid,
            o_axis_tdata  => wa_o_axis_tdata,
            o_axis_tready => wa_o_axis_tready,
            o_axis_tlast  => wa_o_axis_tlast,
            i_axis_tvalid => uft_i_axis_tvalid,
            i_axis_tdata  => uft_i_axis_tdata,
            i_axis_tready => uft_i_axis_tready,
            i_axis_tlast  => uft_i_axis_tlast
        );  
    ------------------------------------------------------------------------  

    ------------------------------------------------------------------------  
    fifo : axis_fifo
    ------------------------------------------------------------------------  
        generic map (
            DATA_WIDTH => 8,
            FIFO_DEPTH => FIFO_DEPTH
            )
        port map (
            clk           => clk,
            rst_n         => restartn,
            m_axis_tvalid => uft_o_axis_tvalid,
            m_axis_tdata  => uft_o_axis_tdata,
            m_axis_tready => uft_o_axis_tready,
            m_axis_tlast  => uft_o_axis_tlast,
            s_axis_tvalid => wa_tvalid,
            s_axis_tdata  => wa_i_axis_tdata,
            s_axis_tready => wa_i_axis_tready,
            s_axis_tlast  => wa_tlast
        );    
    ------------------------------------------------------------------------  


end architecture ; -- structural