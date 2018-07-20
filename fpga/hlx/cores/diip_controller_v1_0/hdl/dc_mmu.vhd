-------------------------------------------------------------------------------
-- Title       : diip controll memory management unit
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : dc_mmu.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Tue Jul 17 13:27:54 2018
-- Last update : Fri Jul 20 09:19:15 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: Takes the image data pixel stream, caches the necessary data
-- and creates the stream for the wallis core
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity dc_mmu is
    generic (
        -- number of elements in a  line buffer
        BRAM_SIZE : natural := 2304; -- 1024 for simulation
        -- number of lines in cache: minimum is window size + 1
        CACHE_N_LINES : natural := 2
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- control
        ------------------------------------------------------------------------
        restart         : in std_logic;
        win_size        : in std_logic_vector(17 downto 0);
        img_width       : in std_logic_vector(24 downto 0);

        -- output axi stream
        ------------------------------------------------------------------------
        o_axis_tvalid   : out   std_logic;
        o_axis_tdata    : out   std_logic_vector(7 downto 0);
        o_axis_tready   : in    std_logic;
        o_axis_tlast    : out   std_logic;

        -- input axi stream
        ------------------------------------------------------------------------
        i_axis_tvalid   : in   std_logic;
        i_axis_tdata    : in   std_logic_vector(7 downto 0);
        i_axis_tready   : out  std_logic;
        i_axis_tlast    : in   std_logic
    ) ;
end entity ; -- dc_mmu

architecture behav of dc_mmu is

    -- ---------------------------------------------------------------------
    -- Calculates the absolute difference between two naturals
    -- a must be smaller than b
    -- ---------------------------------------------------------------------
    function distance (
        a : natural; b : natural; modulus : natural
    ) return natural is
        variable diff : natural range 0 to CACHE_N_LINES;
    begin
        --report "distance a,b,modulus" & natural'image(a) & natural'image(b) & natural'image(modulus);
        if a = b then 
            diff := 0;
        elsif a < b then
            if b < modulus then
                diff := b - a;
            else
                diff := b + modulus - a;
            end if;
        else
            if a < modulus then
                diff := a - b;
            else
                diff := a + modulus - b;
            end if;
        end if;
        return diff;    
    end function distance;
    -- ---------------------------------------------------------------------

    --
    -- V1
    -- 
    -- Declaration of type of a 32768 element BRAM
    -- with each element being 8 bit wide.
    --type bram_t is array (0 to BRAM_SIZE-1) of std_logic_vector(7 downto 0);
    -- Declaration of type of cache containing of block memories
    --type cache_t is array (0 to CACHE_N_LINES-1) of bram_t;
    -- the cache signal with all elements set to 0
    --signal cache : cache_t := (others => (others => (others => '0')));

    --
    -- V2
    -- 
    type cache_t is array (0 to (BRAM_SIZE)*(CACHE_N_LINES)-1) of std_logic_vector(7 downto 0);
    signal cache : cache_t := (others => (others => '0'));

    -- tracks which cache is currently written
    signal cache_w_ptr : natural range 0 to CACHE_N_LINES-1 := 0;
    -- tracks current write position in row memory
    signal row_w_ptr : natural range 0 to BRAM_SIZE-1 := 0;

    -- points to the base cache of read operations
    signal cache_r_base : natural range 0 to CACHE_N_LINES-1 := 0;
    -- points to the tip cache of read operations
    signal cache_r_tip : integer range 0 to CACHE_N_LINES-1 := 0;
    -- tracks which cache is currently read
    signal cache_r_ptr : natural range 0 to CACHE_N_LINES-1 := 0;
    -- distance between read base and read pointer
    signal cache_r_distance : natural range 0 to CACHE_N_LINES-1 := 0;
    -- tracks current read position in row memory
    signal row_r_ptr : natural range 0 to BRAM_SIZE-1 := 0;
    -- countes number of pixels sent to the output
    signal out_pix_ctr : natural range 0 to (CACHE_N_LINES-1)*BRAM_SIZE := 0;
    -- countes number of pixels to be sent to the output
    signal n_out_pix : natural range 0 to (CACHE_N_LINES-1)*BRAM_SIZE := 0;

    -- set if cache_w_ptr wrapped to 0 and cleared if cache_r_ptr wrapped to 0
    signal looped : boolean := false;
    -- distance between read base and write pointer
    signal cache_rw_distance : natural range 0 to CACHE_N_LINES-1 := 0;

    signal i_axis_tready_i : std_logic;
    signal o_axis_tvalid_i : std_logic;
    signal o_axis_tvalid_ilatched : std_logic;
    signal o_axis_tlast_i : std_logic;

begin
    
    -- accept data as long as write pointer is ahead of read pointer
    i_axis_tready_i <= '0' when looped and cache_w_ptr = cache_r_base
                        else '1';
    i_axis_tready <= i_axis_tready_i;

    -- ---------------------------------------------------------------------
    -- Increments row_w_ptr if input stream is valid and ready and wraps it
    -- at BRAM_SIZE or tlast on input
    -- ---------------------------------------------------------------------
    p_row_w_ptr : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                row_w_ptr <= 0;
            else
                if i_axis_tvalid = '1' and i_axis_tready_i = '1' then
                    if row_w_ptr = BRAM_SIZE-1 or i_axis_tlast = '1' then
                        row_w_ptr <= 0;
                    else
                        row_w_ptr <= row_w_ptr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_row_w_ptr

    -- ---------------------------------------------------------------------
    -- Increments p_row_ptr if input stream is indicating end of line (tlast)
    -- ---------------------------------------------------------------------
    p_cache_w_ptr : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                cache_w_ptr <= 0;
                looped <= false;
            else
                if i_axis_tvalid = '1' and i_axis_tready_i = '1' and i_axis_tlast = '1' then
                    if cache_w_ptr = CACHE_N_LINES-1  then
                        cache_w_ptr <= 0;
                        looped <= true;
                    else
                        cache_w_ptr <= cache_w_ptr + 1;
                    end if;
                end if;
                if o_axis_tready = '1' and o_axis_tvalid_i = '1' and o_axis_tlast_i = '1' then
                    if cache_r_base /= CACHE_N_LINES-1 then
                        if cache_r_base + unsigned(win_size) >= CACHE_N_LINES then
                            looped <= false;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_cache_w_ptr
    -- ---------------------------------------------------------------------

    -- ---------------------------------------------------------------------
    -- Cache write process. Writes to the current cache location on input
    -- valid
    -- ---------------------------------------------------------------------
    p_cache_write : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') then
            else
                if i_axis_tvalid = '1' and i_axis_tready_i = '1' then
                    --
                    -- V1
                    -- 
                    --cache(cache_w_ptr)(row_w_ptr) <= i_axis_tdata;
                    --
                    -- V2
                    -- 
                    cache(BRAM_SIZE*cache_w_ptr+row_w_ptr) <= i_axis_tdata;
                end if;
            end if;
        end if;
    end process ; -- p_cache_write
    -- ---------------------------------------------------------------------

    cache_rw_distance <= distance(cache_r_base, cache_w_ptr, CACHE_N_LINES);
    cache_r_distance <= distance(cache_r_base, cache_r_ptr, CACHE_N_LINES);

    -- ---------------------------------------------------------------------
    -- Calculates the following operation without modulus
    -- cache_r_tip <= (integer(cache_r_base) + to_integer(unsigned(win_size))-1) mod CACHE_N_LINES;
    -- ---------------------------------------------------------------------
    p_cache_r_tip : process( cache_r_base, win_size )
    -- ---------------------------------------------------------------------
        variable sum : integer range -2 to 2**(win_size'length+1);
    begin
        --report "cache_r_base =" & natural'image(cache_r_base);
        --report "win_size =" & integer'image(to_integer(unsigned(win_size)));
        sum := (integer(cache_r_base) + to_integer(unsigned(win_size))-1);
        --report "sum = " & integer'image(sum);
        --report "CACHE_N_LINES = " & integer'image(CACHE_N_LINES);
        if sum >= CACHE_N_LINES then
            cache_r_tip <= sum - CACHE_N_LINES;
        elsif sum < 0 then
            cache_r_tip <= sum + CACHE_N_LINES;
        else
            cache_r_tip <= sum;
        end if;
    end process ; -- p_cache_r_tip
    -- ---------------------------------------------------------------------

    -- write data as long as write pointer is ahead of read pointer
    o_axis_tvalid_i <= '1' when looped or cache_w_ptr > cache_r_tip
                        else '0';

    n_out_pix <= to_integer(unsigned(img_width)*unsigned(win_size));

    -- ---------------------------------------------------------------------
    -- Count the number of pixels sent
    -- ---------------------------------------------------------------------
    p_out_pix_ctr : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                out_pix_ctr <= 0;
            else
                if o_axis_tready = '1' and o_axis_tvalid_ilatched = '1' then
                    if out_pix_ctr = n_out_pix-1 then
                        out_pix_ctr <= 0;
                    else
                        out_pix_ctr <= out_pix_ctr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_out_pix_ctr
    -- ---------------------------------------------------------------------

    o_axis_tlast_i <= '1' when out_pix_ctr = (n_out_pix-1) else '0';


    -- ---------------------------------------------------------------------
    -- Increments cache_r_base if output stream is complete
    -- ---------------------------------------------------------------------
    p_cache_r_base : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                cache_r_base <= 0;
            else
                if o_axis_tready = '1' and o_axis_tvalid_i = '1' and o_axis_tlast_i = '1' then
                    if cache_r_base = CACHE_N_LINES-1 then
                        cache_r_base <= 0;
                    else
                        cache_r_base <= cache_r_base + 1;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_cache_r_base
    -- ---------------------------------------------------------------------

    -- ---------------------------------------------------------------------
    -- Increments cache_r_ptr if output stream is read
    -- ---------------------------------------------------------------------
    p_cache_r_ptr : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                cache_r_ptr <= 0;
            else
                if o_axis_tready = '1' and o_axis_tvalid_i = '1' then
                    if cache_r_distance =  to_integer(unsigned(win_size))-1 then
                        cache_r_ptr <= cache_r_base;
                    else
                        if cache_r_ptr = CACHE_N_LINES-1 then
                            cache_r_ptr <= 0;
                        else
                            cache_r_ptr <= cache_r_ptr + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_cache_r_ptr
    -- ---------------------------------------------------------------------

    -- ---------------------------------------------------------------------
    -- Increments row_r_ptr if output stream is read
    -- ---------------------------------------------------------------------
    p_row_r_ptr : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') or (restart = '1') then
                row_r_ptr <= 0;
            else
                if o_axis_tready = '1' and o_axis_tvalid_i = '1' then
                    if cache_r_distance =  to_integer(unsigned(win_size)) then
                        row_r_ptr <= row_r_ptr + 1;
                    elsif o_axis_tlast_i = '1' then
                        row_r_ptr <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_row_r_ptr

    -- ---------------------------------------------------------------------
    -- Reads from memory
    -- ---------------------------------------------------------------------
    p_read : process( clk )
    -- ---------------------------------------------------------------------
    begin
        if (rising_edge(clk)) then
            if (rst_n = '0') then
                o_axis_tdata <= (others => '0');
                o_axis_tvalid_ilatched <= '0';
            else
                if o_axis_tready = '1' then
                    -- take a break if last pixel was sent for the counters to
                    -- reset
                    if o_axis_tlast_i = '1' then
                        o_axis_tvalid_ilatched <= '0';
                    else
                        o_axis_tvalid_ilatched <= o_axis_tvalid_i;
                        --
                        -- V1
                        -- 
                        --o_axis_tdata <= cache(cache_r_ptr)(row_r_ptr);
                        -- 
                        -- V2
                        -- 
                        o_axis_tdata <= cache(BRAM_SIZE*cache_r_ptr+row_r_ptr);
                    end if;
                end if;
            end if;
        end if;
    end process ; -- p_read
    o_axis_tvalid <= o_axis_tvalid_ilatched;
    o_axis_tlast <= o_axis_tlast_i;


end architecture ; -- behav