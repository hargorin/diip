-------------------------------------------------------------------------------
-- Title       : UFT Rx memory controller
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : utf_rx_mem_ctl.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov  8 15:09:23 2017
-- Last update : Tue Jul 17 09:01:03 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Description: Shifts Data from the Rx block into a FiFo to then burst write
-- into a BLOCK RAM
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity utf_rx_mem_ctl is
    generic (
        FIFO_DEPTH : positive := 366 -- (1464/4)
    );
    port (
        -- clk and reset
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- status
        rx_done     : out std_logic := '0';

        -- connection to uft rx block
        is_data                 : in std_logic;
        data_tcid               : in std_logic_vector( 6 downto 0);
        data_seq                : in std_logic_vector(23 downto 0);
        data_meta_valid         : in std_logic;
        data_tvalid             : in std_logic;
        data_tlast              : in std_logic;
        data_tdata              : in std_logic_vector( 7 downto 0);

        is_command             : in std_logic;
        command_code           : in std_logic_vector(6 downto 0);
        command_data1          : in std_logic_vector(23 downto 0);
        command_data2          : in std_logic_vector(31 downto 0);
        command_data_valid     : in std_logic;

        rx_src_ip      : in std_logic_vector (31 downto 0);
        rx_src_port    : in std_logic_vector (15 downto 0);

        -- Outputs for ack
        -- ---------------------------------------------------------------------
        -- Commands for acknowledgment
        ack_cmd_nseq    : out std_logic; -- acknowledge a sequence
        ack_cmd_ft      : out std_logic; -- acknowledge a file transfer
        ack_cmd_nseq_done    : in std_logic;
        ack_cmd_ft_done      : in std_logic;
        -- data for commands
        ack_seqnbr              : out std_logic_vector (23 downto 0);
        ack_tcid                : out std_logic_vector ( 6 downto 0);
        ack_dst_port            : out std_logic_vector (15 downto 0);
        ack_dst_ip              : out std_logic_vector (31 downto 0);

        -- Outputs
        -- ---------------------------------------------------------------------
        m_axis_tvalid   : out   std_logic;
        m_axis_tdata    : out   std_logic_vector(7 downto 0);
        m_axis_tlast    : out   std_logic;
        m_axis_tready   : in    std_logic;

        rx_row_num         : out std_logic_vector(31 downto 0);
        rx_row_num_valid   : out std_logic;
        rx_row_size        : out std_logic_vector(31 downto 0);
        rx_row_size_valid  : out std_logic;

        -- User registers
        user_reg0           : out  std_logic_vector(31 downto 0);
        user_reg1           : out  std_logic_vector(31 downto 0);
        user_reg2           : out  std_logic_vector(31 downto 0);
        user_reg3           : out  std_logic_vector(31 downto 0);
        user_reg4           : out  std_logic_vector(31 downto 0);
        user_reg5           : out  std_logic_vector(31 downto 0);
        user_reg6           : out  std_logic_vector(31 downto 0);
        user_reg7           : out  std_logic_vector(31 downto 0)

    );
end entity utf_rx_mem_ctl;

architecture rtl of utf_rx_mem_ctl is
    
    component axis_fifo is
        generic (
            constant DATA_WIDTH : positive := 8;
            constant FIFO_DEPTH : positive := 256
        );
        port (
            CLK           : in  STD_LOGIC;
            RST_N         : in  STD_LOGIC;
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(data_width-1 downto 0);
            m_axis_tready : in  std_logic;
            m_axis_tlast  : out  std_logic;
            S_AXIS_TVALID : in  std_logic;
            S_AXIS_TDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            S_AXIS_TLAST  : in  std_logic;
            S_AXIS_TREADY : out std_logic
        );
    end component axis_fifo;    

    -- type defs
    type state_type is ( IDLE, STORE, STORE_DONE, ACK_SEQ, PARSE_CMD );
    type count_mode_type is (RST, INCR, HOLD);

    signal count_mode        : count_mode_type;
    signal ctr               : unsigned (15 downto 0);

    -- signals
    signal current_state    : state_type;
    signal next_state       : state_type;

    -- FIFO connection
    signal m_axis_tvalid_i : std_logic;
    signal axis_fifo_tlast : std_logic;

    -- ACK latches
    signal ack_seqnbr_int              : std_logic_vector (23 downto 0);
    signal ack_tcid_int                : std_logic_vector ( 6 downto 0);
    signal ack_dst_port_int            : std_logic_vector (15 downto 0);
    signal ack_dst_ip_int              : std_logic_vector (31 downto 0);

    -- File transfer stats
    signal ft_cur_tcid : std_logic_vector(6 downto 0);
    signal ft_nseq : std_logic_vector(23 downto 0);
    signal ft_nseq_received : unsigned(23 downto 0);
    signal rx_done_int : std_logic;
    type rx_done_imp_state is (SRXI_IDLE, SRXI_IMP, SRXI_DONE);   
    signal rx_done_state : rx_done_imp_state := SRXI_IDLE;
begin

    ----------------------------------------------------------------------------
    -- Unused outputs
    -- -------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    p_state_proc_clocked : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process ; -- p_state_proc_clocked

    ----------------------------------------------------------------------------
    p_next_state : process ( is_data, is_command, data_tlast, current_state)
    ----------------------------------------------------------------------------
    begin
        next_state <= current_state;

        case (current_state) is
            when IDLE =>
                if is_data = '1' then
                    next_state <= STORE;
                elsif is_command = '1' then
                    next_state <= PARSE_CMD;
                end if;
            when STORE =>
                if data_tlast = '1' then
                    next_state <= STORE_DONE;
                end if;
            when STORE_DONE => 
                next_state <= ACK_SEQ;
            when ACK_SEQ => 
                    next_state <= IDLE;
            when PARSE_CMD => 
                    next_state <= IDLE;
        end case;
    end process p_next_state;

    ------------------------------------------------------------------------------
    ---- Tracks the input data counter and holds if all data is received
    ---- -------------------------------------------------------------------------
    --p_mem_len : process( ctr, current_state )
    --    variable ctrp1 : unsigned (15 downto 0);
    ------------------------------------------------------------------------------
    --begin
    --    ctrp1 := ctr + 1;
    --    if current_state = STORE_DONE then
    --        -- amb_word_cnt in WORDS is ceil((ctr+1) / 4 )
    --        if ctr(1 downto 0) /= "00" then
    --            amb_word_cnt <= shift_right(ctr, 2)(C_LENGTH_WIDTH-1 downto 0) + 1;
    --        else
    --            amb_word_cnt <= shift_right(ctr, 2)(C_LENGTH_WIDTH-1 downto 0);
    --        end if;        
    --        mem_length <= ctr(C_LENGTH_WIDTH-1 downto 0);
    --        axi_addr <= unsigned(rx_base_adr) + to_unsigned((to_integer(c_pkg_uft_rx_pack_size) * to_integer(unsigned(data_seq))),axi_addr'length);
    --    else
    --        amb_word_cnt <= amb_word_cnt;
    --        mem_length <= mem_length;
    --    end if;
    --end process ; -- p_mem_len
    ----------------------------------------------------------------------------
    p_ctr : process ( clk, current_state, data_tvalid )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            -- ctr processing
            -- Counts received btyes
            case count_mode is
                when RST  =>    ctr <= x"0000";
                when INCR =>    ctr <= ctr + 1;
                when HOLD =>    ctr <= ctr;
            end case;    
        end if;

        -- Cout mode setting
        case (current_state) is
            when IDLE =>
                count_mode <= RST;
            when STORE =>
                if data_tvalid = '1' then
                    count_mode <= INCR;
                else
                    count_mode <= HOLD;
                end if;
            when STORE_DONE => 
                count_mode <= HOLD;
            when ACK_SEQ => 
                count_mode <= HOLD;
            when PARSE_CMD => 
                count_mode <= HOLD;
        end case;
    end process p_ctr;

    rx_row_num          <= std_logic_vector(resize(unsigned(data_tcid),32));
    rx_row_num_valid    <= data_meta_valid;
    --rx_row_size         <= std_logic_vector(resize(unsigned(ft_nseq),32));
    -- row size is not known apriori
    rx_row_size         <= (others => '0');
    rx_row_size_valid   <= '0';

    ----------------------------------------------------------------------------
    -- Parses the input commands
    -- - Set user registers
    ----------------------------------------------------------------------------
    p_ccmd_parser : process ( clk, current_state )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                user_reg0 <= (others => '0');
                user_reg1 <= (others => '0');
                user_reg2 <= (others => '0');
                user_reg3 <= (others => '0');
                user_reg4 <= (others => '0');
                user_reg5 <= (others => '0');
                user_reg6 <= (others => '0');
                user_reg7 <= (others => '0');
            else
                if current_state = PARSE_CMD and command_data_valid = '1' then
                    -- switch by command code
                    case (command_code) is
                        when "0000000" => -- file transfer start
                        when "0000001" => -- file transfer stop
                        when "0000010" => -- acknowledge data packet
                        when "0000011" => -- acknowledge file transfer
                        when "0000100" => -- set user registers
                            if    command_data1 = x"000000" then user_reg0 <= command_data2;
                            elsif command_data1 = x"000001" then user_reg1 <= command_data2;
                            elsif command_data1 = x"000002" then user_reg2 <= command_data2;
                            elsif command_data1 = x"000003" then user_reg3 <= command_data2;
                            elsif command_data1 = x"000004" then user_reg4 <= command_data2;
                            elsif command_data1 = x"000005" then user_reg5 <= command_data2;
                            elsif command_data1 = x"000006" then user_reg6 <= command_data2;
                            elsif command_data1 = x"000007" then user_reg7 <= command_data2;
                            end if;
                        when others => 
                    end case;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Handles ack signals
    -- some outputs are latched, dont panic!
    ----------------------------------------------------------------------------
    p_ack : process ( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            ack_cmd_nseq <= '0';
            ack_cmd_ft <= '0';

            -- latch
            ack_seqnbr_int <= ack_seqnbr_int;
            ack_tcid_int <= ack_tcid_int;
            ack_dst_port_int <= ack_dst_port_int;
            ack_dst_ip_int <= ack_dst_ip_int;
            
            if rst_n = '0' then
                ack_cmd_nseq <= '0';
                ack_cmd_ft <= '0';
                -- data for commands
                ack_seqnbr_int <= (others => '0');
                ack_tcid_int <= (others => '0');
                ack_dst_port_int <= (others => '0');
                ack_dst_ip_int <= (others => '0');
            else
                if current_state = ACK_SEQ then
                    ack_cmd_nseq <= '1';
                    -- latch data from input
                    ack_seqnbr_int <= data_seq;
                    ack_tcid_int <= data_tcid;
                    -- send data to sender
                    ack_dst_port_int <= rx_src_port;
                    ack_dst_ip_int <= rx_src_ip;
                end if;
            end if;

            -- output
            ack_seqnbr <= ack_seqnbr_int;
            ack_tcid <= ack_tcid_int;
            ack_dst_port <= ack_dst_port_int;
            ack_dst_ip <= ack_dst_ip_int;
        end if;

    end process; -- p_ack

    ----------------------------------------------------------------------------
    -- FIFO control
    ----------------------------------------------------------------------------
    --p_fifo_gauge : process( clk )
    --begin
    --    if rising_edge(clk) then
    --        if rst_n = '0' then
    --            axis_fifo_tlast <= '0';
    --        else
    --            if data_tlast = '1' and (to_integer(unsigned(ft_nseq)) = to_integer(ft_nseq_received)+1) then
    --                axis_fifo_tlast <= '1';
    --            else
    --                axis_fifo_tlast <= '0';
    --            end if;
    --        end if;
    --    end if;
    --end process ; -- p_fifo_gauge

    axis_fifo_tlast <= '1' when data_tlast = '1' and (to_integer(unsigned(ft_nseq)) = to_integer(ft_nseq_received)+1)
                       else '0';

    c_axis_fifo : axis_fifo
        generic map (
            DATA_WIDTH => 8,
            FIFO_DEPTH => FIFO_DEPTH
            )
        port map (
            clk           => clk,
            rst_n         => rst_n,
            m_axis_tvalid => m_axis_tvalid_i,
            m_axis_tdata  => m_axis_tdata,
            m_axis_tready => m_axis_tready,
            m_axis_tlast => m_axis_tlast,
            s_axis_tvalid => data_tvalid,
            s_axis_tdata  => data_tdata,
            s_axis_tready => open,
            s_axis_tlast => axis_fifo_tlast
        );    
    m_axis_tvalid <= m_axis_tvalid_i;

    ----------------------------------------------------------------------------
    -- File transfer control
    -- Asserts rx_done_int after a file transfer is complete
    ----------------------------------------------------------------------------
    p_ft : process(clk)
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                ft_cur_tcid <= (others => '0');
                ft_nseq <= (others => '1');
                ft_nseq_received <= (others => '0');
                rx_done_int <= '0';
            else
                rx_done_int <= '0';
                -- latch tcid and nseq if command received is FTS
                if is_command = '1' and command_data_valid = '1' and command_code = "0000000" then
                    ft_nseq <= command_data2(23 downto 0);
                    ft_cur_tcid <= command_data1(6 downto 0);
                    ft_nseq_received <= (others => '0');
                    rx_done_int <= '0';
                end if;
                -- increment nseq counter if state is done
                if current_state = ACK_SEQ then
                    ft_nseq_received <= ft_nseq_received + 1;
                end if;
                -- if all packets received
                if to_integer(unsigned(ft_nseq)) = to_integer(ft_nseq_received) then
                    rx_done_int <= '1';
                end if;
            end if;                
        end if;
    end process p_ft;
    ----------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------
    -- Creates a 10 clock duration impulse on rx_done after rx_done_int
    -- goes high
    ----------------------------------------------------------------------------
    rx_done <= '1' when rx_done_state = SRXI_IMP else '0';
    p_ft_imp : process(clk)
        variable counter : integer range 0 to 10 := 0;
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
                if (rst_n = '0') then
                    rx_done_state <= SRXI_IDLE;
                    counter := 0;
                else
                    case (rx_done_state) is
                        when SRXI_IDLE =>
                            counter := 0;
                            --impulse <= '0';
                            if rx_done_int = '1' then
                                rx_done_state <= SRXI_IMP;
                            end if;
                        when SRXI_IMP =>
                            counter := counter + 1;
                            --impulse <= '1';
                            if counter = 10 then
                                rx_done_state <= SRXI_DONE;
                            end if;
                        when SRXI_DONE =>
                            --impulse <= '0';
                            if rx_done_int = '0' then
                                rx_done_state <= SRXI_IDLE;
                            end if;
                    end case;
                end if;
            end if;
    end process p_ft_imp;


end architecture rtl;