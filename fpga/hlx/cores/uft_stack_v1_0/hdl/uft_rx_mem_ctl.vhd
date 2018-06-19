-------------------------------------------------------------------------------
-- Title       : UFT Rx memory controller
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : utf_rx_mem_ctl.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov  8 15:09:23 2017
-- Last update : Tue Jun 19 15:07:28 2018
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
        FIFO_DEPTH : positive := 366; -- (1464/4)
        
        -- AXI Master burst Configuration
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "artix7"
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

        rx_base_adr      : in std_logic_vector (31 downto 0);
        rx_src_ip      : in std_logic_vector (31 downto 0);
        rx_src_port    : in std_logic_vector (15 downto 0);

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

        -- User registers
        user_reg0           : out  std_logic_vector(31 downto 0);
        user_reg1           : out  std_logic_vector(31 downto 0);
        user_reg2           : out  std_logic_vector(31 downto 0);
        user_reg3           : out  std_logic_vector(31 downto 0);
        user_reg4           : out  std_logic_vector(31 downto 0);
        user_reg5           : out  std_logic_vector(31 downto 0);
        user_reg6           : out  std_logic_vector(31 downto 0);
        user_reg7           : out  std_logic_vector(31 downto 0);

        -- RX Memory IP Interface
        -- ---------------------------------------------------------------------
        ip2bus_mstrd_req       : out std_logic;
        ip2bus_mstwr_req       : out std_logic;
        ip2bus_mst_addr        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
        ip2bus_mst_length      : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
        ip2bus_mst_be          : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mst_type        : out std_logic;
        ip2bus_mst_lock        : out std_logic;
        ip2bus_mst_reset       : out std_logic;
        bus2ip_mst_cmdack      : in  std_logic;
        bus2ip_mst_cmplt       : in  std_logic;
        bus2ip_mst_error       : in  std_logic;
        bus2ip_mst_rearbitrate : in  std_logic;
        bus2ip_mst_cmd_timeout : in  std_logic;
        bus2ip_mstrd_d         : in  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
        bus2ip_mstrd_rem       : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        bus2ip_mstrd_sof_n     : in  std_logic;
        bus2ip_mstrd_eof_n     : in  std_logic;
        bus2ip_mstrd_src_rdy_n : in  std_logic;
        bus2ip_mstrd_src_dsc_n : in  std_logic;
        ip2bus_mstrd_dst_rdy_n : out std_logic;
        ip2bus_mstrd_dst_dsc_n : out std_logic;
        ip2bus_mstwr_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
        ip2bus_mstwr_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        ip2bus_mstwr_sof_n     : out std_logic;
        ip2bus_mstwr_eof_n     : out std_logic;
        ip2bus_mstwr_src_rdy_n : out std_logic;
        ip2bus_mstwr_src_dsc_n : out std_logic;
        bus2ip_mstwr_dst_rdy_n : in  std_logic;
        bus2ip_mstwr_dst_dsc_n : in  std_logic  
    );
end entity utf_rx_mem_ctl;

architecture rtl of utf_rx_mem_ctl is

    component fifo_8i_32o is
        generic (
            constant FIFO_DEPTH : positive := 256
        );
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            write_en : in  std_logic;
            data_in  : in  std_logic_vector (7 downto 0);
            read_en  : in  std_logic;
            data_out : out std_logic_vector(31 downto 0);
            empty    : out std_logic;
            full     : out std_logic
        );
    end component fifo_8i_32o;    

    -- type defs
    type state_type is ( IDLE, STORE, STORE_DONE, INIT_TRANSFER, TRANSFER_FIRST, TRANSFER, 
        TRANSFER_LAST, TRANSFER_DONE, ACK_SEQ, PARSE_CMD );
    type count_mode_type is (RST, INCR, HOLD);

    signal count_mode        : count_mode_type;
    signal ctr               : unsigned (15 downto 0);

    -- signals
    signal current_state    : state_type;
    signal next_state       : state_type;

    -- FIFO connection
    signal FIFO_rst_n : std_logic;
    signal FIFO_WriteEn : std_logic;
    signal FIFO_DataIn : std_logic_vector(7 downto 0);
    signal FIFO_ReadEn : std_logic;
    signal FIFO_DataOut : std_logic_vector(31 downto 0);
    signal FIFO_Empty : std_logic;
    signal FIFO_Full : std_logic;

    -- stores the number of BYTE transactions to be executed
    signal mem_length : unsigned (C_LENGTH_WIDTH-1 downto 0);
    -- stores the number of WORD transactions to be executed
    signal amb_word_cnt : unsigned (C_LENGTH_WIDTH-1 downto 0);
    -- packet destination address in the memory
    signal axi_addr : unsigned(C_M_AXI_ADDR_WIDTH-1 downto 0);

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
begin

    ----------------------------------------------------------------------------
    -- Unused outputs
    -- -------------------------------------------------------------------------
    ip2bus_mstrd_req <= '0';
    ip2bus_mstrd_dst_rdy_n <= '1';
    ip2bus_mstrd_dst_dsc_n <= '1';
    ip2bus_mstwr_rem <= (others => '0');

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
    p_next_state : process ( is_data, is_command, clk, current_state, FIFO_Empty, ctr, 
        bus2ip_mst_cmdack, bus2ip_mstwr_dst_rdy_n, bus2ip_mst_cmplt, mem_length,
        data_tlast, amb_word_cnt )
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
                next_state <= INIT_TRANSFER;
            when INIT_TRANSFER =>
                if bus2ip_mst_cmdack = '1' then
                    next_state <= TRANSFER_FIRST;
                end if;
            when TRANSFER_FIRST =>
                if bus2ip_mstwr_dst_rdy_n = '0' then
                    if amb_word_cnt = 2 then
                        next_state <= TRANSFER_LAST;
                    else
                        next_state <= TRANSFER;
                    end if;
                end if;
            when TRANSFER =>
                if (ctr = (amb_word_cnt-2)) and (bus2ip_mstwr_dst_rdy_n = '0') then
                    next_state <= TRANSFER_LAST;
                end if;
            when TRANSFER_LAST =>
                if bus2ip_mstwr_dst_rdy_n = '0' then
                    next_state <= TRANSFER_DONE;
                end if;
            when TRANSFER_DONE =>
                if bus2ip_mst_cmplt = '1' then
                    next_state <= ACK_SEQ;
                end if;
            when ACK_SEQ => 
                    next_state <= IDLE;
            when PARSE_CMD => 
                    next_state <= IDLE;
        end case;
    end process p_next_state;

    ----------------------------------------------------------------------------
    -- Tracks the input data counter and holds if all data is received
    -- -------------------------------------------------------------------------
    p_mem_len : process( ctr, current_state )
        variable ctrp1 : unsigned (15 downto 0);
    ----------------------------------------------------------------------------
    begin
        ctrp1 := ctr + 1;
        if current_state = STORE_DONE then
            -- amb_word_cnt in WORDS is ceil((ctr+1) / 4 )
            if ctrp1(1 downto 0) /= "00" then
                amb_word_cnt <= shift_right(ctrp1, 2)(C_LENGTH_WIDTH-1 downto 0) + 1;
            else
                amb_word_cnt <= shift_right(ctrp1, 2)(C_LENGTH_WIDTH-1 downto 0);
            end if;        
            mem_length <= ctr(C_LENGTH_WIDTH-1 downto 0) + 1;
            axi_addr <= unsigned(rx_base_adr) + to_unsigned((to_integer(c_pkg_uft_rx_pack_size) * to_integer(unsigned(data_seq))),axi_addr'length);
        else
            amb_word_cnt <= amb_word_cnt;
            mem_length <= mem_length;
        end if;
    end process ; -- p_mem_len
    ----------------------------------------------------------------------------
    p_ctr : process ( clk, current_state )
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
            when INIT_TRANSFER =>
                count_mode <= RST;
            when TRANSFER_FIRST =>
                if FIFO_ReadEn = '1' then
                    count_mode <= INCR;
                else
                    count_mode <= HOLD;
                end if;
            when TRANSFER =>
                if FIFO_ReadEn = '1' then
                    count_mode <= INCR;
                else
                    count_mode <= HOLD;
                end if;
            when TRANSFER_LAST =>
                if FIFO_ReadEn = '1' then
                    count_mode <= INCR;
                else
                    count_mode <= HOLD;
                end if;
            when TRANSFER_DONE =>
                count_mode <= HOLD;
            when ACK_SEQ => 
                count_mode <= HOLD;
            when PARSE_CMD => 
                count_mode <= HOLD;
        end case;
        

    end process p_ctr;


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

    --p_axi_adr : process( current_state )
    --begin
    --    if current_state = INIT_TRANSFER then
    --        axi_addr <= unsigned(rx_base_adr) + to_unsigned((to_integer(c_pkg_uft_rx_pack_size) * to_integer(unsigned(data_seq))),axi_addr'length);
    --    end if;
    --end process ; -- p_axi_adr

    ----------------------------------------------------------------------------
    -- Handles the ip2bus signals during write transaction
    ----------------------------------------------------------------------------
    p_bus_write : process ( current_state, clk )
    ----------------------------------------------------------------------------
        variable get_word : boolean := false;
    begin
        if true then
            case (current_state) is
                when INIT_TRANSFER =>
                    ip2bus_mstwr_req <= '1';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= std_logic_vector(axi_addr);
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= std_logic_vector(mem_length);
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';

                    
                    ip2bus_mstwr_sof_n <= '0';
                    ip2bus_mstwr_eof_n <= '1';
                    ip2bus_mstwr_src_rdy_n <= '0';
                    ip2bus_mstwr_src_dsc_n <= '1';
                    get_word := true;  
                when TRANSFER_FIRST =>
                    ip2bus_mstwr_req <= '0';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= std_logic_vector(axi_addr);
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= std_logic_vector(mem_length);
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';
                    
                    
                    ip2bus_mstwr_sof_n <= '0';
                    ip2bus_mstwr_eof_n <= '1';
                    ip2bus_mstwr_src_rdy_n <= '0';
                    ip2bus_mstwr_src_dsc_n <= '1';
                    if bus2ip_mstwr_dst_rdy_n = '0' then
                        get_word := true;
                    end if;
                when TRANSFER =>
                    ip2bus_mstwr_req <= '0';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= std_logic_vector(axi_addr);
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= std_logic_vector(mem_length);
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';
                    
                    
                    ip2bus_mstwr_sof_n <= '1';
                    ip2bus_mstwr_eof_n <= '1';
                    ip2bus_mstwr_src_rdy_n <= '0';
                    ip2bus_mstwr_src_dsc_n <= '1';
                    if bus2ip_mstwr_dst_rdy_n = '0' then
                        get_word := true;
                    end if;
                when TRANSFER_LAST =>
                    ip2bus_mstwr_req <= '0';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= std_logic_vector(axi_addr);
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= std_logic_vector(mem_length);
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';
                    
                    
                    ip2bus_mstwr_sof_n <= '1';
                    ip2bus_mstwr_eof_n <= '0';
                    ip2bus_mstwr_src_rdy_n <= '0';
                    ip2bus_mstwr_src_dsc_n <= '1';
                    if bus2ip_mstwr_dst_rdy_n = '0' then
                        get_word := true;
                    end if;
                when TRANSFER_DONE =>
                    ip2bus_mstwr_req <= '0';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= std_logic_vector(axi_addr);
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= (others => '0');
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';
                    
                    ip2bus_mstwr_sof_n <= '1';
                    ip2bus_mstwr_eof_n <= '1';
                    ip2bus_mstwr_src_rdy_n <= '1';
                    ip2bus_mstwr_src_dsc_n <= '1';
                when others =>
                    ip2bus_mstwr_req <= '0';
                    ip2bus_mst_type <= '1';
                    ip2bus_mst_addr <= (others  => '0');
                    ip2bus_mst_be <= (others => '1');
                    ip2bus_mst_length <= (others => '0');
                    ip2bus_mst_lock <= '0';
                    ip2bus_mst_reset <= '0';
                    
                    ip2bus_mstwr_sof_n <= '1';
                    ip2bus_mstwr_eof_n <= '1';
                    ip2bus_mstwr_src_rdy_n <= '1';
                    ip2bus_mstwr_src_dsc_n <= '1';
                    null;
            end case;

            ---- if get word is set, get one word from the fifo
            --if( get_word = true) then
            --    FIFO_ReadEn <= '1';
            --    get_word := false;
            --else
            --    FIFO_ReadEn <= '0';
            --end if;

        end if;
    end process p_bus_write;

    

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

    FIFO_ReadEn <= '1' when (bus2ip_mstwr_dst_rdy_n = '0') or 
        ((current_state = INIT_TRANSFER) AND (bus2ip_mst_cmdack = '1')) else '0';
    ip2bus_mstwr_d  <= FIFO_DataOut; 
    ----------------------------------------------------------------------------
    -- FIFO control
    ----------------------------------------------------------------------------
    c_rx_fifo : fifo_8i_32o
        generic map (
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            clk      => clk,
            rst_n    => FIFO_rst_n,
            write_en => FIFO_WriteEn,
            data_in  => FIFO_DataIn,
            read_en  => FIFO_ReadEn,
            data_out => FIFO_DataOut,
            empty    => FIFO_Empty,
            full     => FIFO_Full
        );
    FIFO_rst_n <= '0' when current_state = IDLE else '1';
    FIFO_WriteEn  <= data_tvalid;
    FIFO_DataIn <= data_tdata;

    --FIFO_ReadEn <= '1' when current_state = TRANSFER else '0';



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
    -- Creates a one clock duration impulse on rx_done after rx_done_int
    -- goes high
    ----------------------------------------------------------------------------
    p_ft_imp : process(clk)
        variable rx_done_int_old : std_logic := '0';
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                rx_done <= '0';
                rx_done_int_old := '0';        
            else
                if (rx_done_int_old /= rx_done_int) and (rx_done_int = '1') then
                    rx_done <= '1';
                else
                    rx_done <= '0';
                end if;
                rx_done_int_old := rx_done_int;
            end if;   
        end if;
    end process p_ft_imp;


end architecture rtl;