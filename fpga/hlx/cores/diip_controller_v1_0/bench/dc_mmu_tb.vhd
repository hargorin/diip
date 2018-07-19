
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity dc_mmu_tb is
generic (
    
    -- number of elements in a  line buffer
    BRAM_SIZE : positive := 128;
    -- Testbench DUT generics as constants
    CACHE_N_LINES : positive := 4;

    IMAGE_WIDTH : positive := 5;
    WINDOW_SIZE : positive := 3
);

end entity dc_mmu_tb;

-----------------------------------------------------------

architecture testbench of dc_mmu_tb is
    component dc_mmu is
        generic (
            BRAM_SIZE     : natural := 2304;
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

	-- Testbench DUT ports as signals
    signal clk           : std_logic;
    signal rst_n         : std_logic;
    signal restart       : std_logic;
    signal win_size      : std_logic_vector(17 downto 0);
    signal img_width      : std_logic_vector(24 downto 0);
    signal o_axis_tvalid : std_logic;
    signal o_axis_tdata  : std_logic_vector(8-1 downto 0);
    signal o_axis_tready : std_logic;
    signal o_axis_tlast  : std_logic;
    signal i_axis_tvalid : std_logic;
    signal i_axis_tdata  : std_logic_vector(8-1 downto 0);
    signal i_axis_tready : std_logic;
    signal i_axis_tlast  : std_logic;

	-- Other constants
    constant clk_period : time := 8 ns;
	signal stop_sim : std_logic := '0';

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
    clk_gen : process
    begin
        clk <= '1';
        wait for clk_period / 2.0;
        clk <= '0';
        wait for clk_period / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process clk_gen;

    reset_gen : process
    begin
        rst_n <= '0',
                 '1' after 5.0*clk_period;
        wait;
    end process reset_gen;


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
        o_axis_tready <= '1';
        i_axis_tvalid <= '0';
        i_axis_tlast <= '0';
        restart <= '0';
        i_axis_tdata <= (others => '1');
        win_size <= std_logic_vector(to_unsigned(WINDOW_SIZE,18));
        img_width <= std_logic_vector(to_unsigned(IMAGE_WIDTH,25));
        waitfor(10);


        -- fill the buffer
        lp_fill : for i in 1 to CACHE_N_LINES loop
            i_axis_tdata <= std_logic_vector(to_unsigned(i,8));
            i_axis_tvalid <= '1';
            waitfor(IMAGE_WIDTH-1);
            i_axis_tlast <= '1';
            waitfor(1);
            i_axis_tlast <= '0';
            i_axis_tvalid <= '0';
        end loop ; -- lp_fill
        waitfor(1);
        assert (i_axis_tready = '0') report "tready high even tough cache is full" severity error;

        -- empty two lines
        for i in 1 to 2 loop
            --o_axis_tready <= '1';
            if o_axis_tvalid = '0' then
                wait until o_axis_tvalid = '1';
            end if;
            if o_axis_tlast = '0' then
                wait until o_axis_tlast = '1';
            end if;
            wait until o_axis_tlast = '0';
        end loop ; -- lp_empty
        waitfor(1);
        assert (o_axis_tvalid = '0') report "1 tvalid high even tough cache has not enough data" severity error;

        -- fill one buffer line
        i_axis_tdata <= std_logic_vector(to_unsigned(5,8));
        i_axis_tvalid <= '1';
        waitfor(IMAGE_WIDTH-1);
        i_axis_tlast <= '1';
        waitfor(1);
        i_axis_tlast <= '0';
        i_axis_tvalid <= '0';

        -- empty one line
        lp_empty : for i in 1 to 1 loop
            --o_axis_tready <= '1';
            if o_axis_tvalid = '0' then
                wait until o_axis_tvalid = '1';
            end if;
            if o_axis_tlast = '0' then
                wait until o_axis_tlast = '1';
            end if;
            wait until o_axis_tlast = '0';
        end loop ; -- lp_empty
        waitfor(1);
        assert (o_axis_tvalid = '0') report "2 tvalid high even tough cache has not enough data" severity error;

        -- restart by sending a new line
        restart <= '1';
        waitfor(1);
        restart <= '0';

        -- fill the buffer
        for i in 1 to CACHE_N_LINES loop
            i_axis_tdata <= std_logic_vector(to_unsigned(i,8));
            i_axis_tvalid <= '1';
            waitfor(IMAGE_WIDTH-1);
            i_axis_tlast <= '1';
            waitfor(1);
            i_axis_tlast <= '0';
            i_axis_tvalid <= '0';
        end loop ; --       
        waitfor(1);
        assert (i_axis_tready = '0') report "tready high even tough cache is full" severity error;

        -- empty two lines
        for i in 1 to 2 loop
            --o_axis_tready <= '1';
            if o_axis_tvalid = '0' then
                wait until o_axis_tvalid = '1';
            end if;
            if o_axis_tlast = '0' then
                wait until o_axis_tlast = '1';
            end if;
            wait until o_axis_tlast = '0';
        end loop ; -- lp_empty
        waitfor(1);
        assert (o_axis_tvalid = '0') report "1 tvalid high even tough cache has not enough data" severity error;

        waitfor(10);
    	stop_sim <= '1';
    end process;

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
                    file_open(file_axi_s, "axi_stream_res_" & INTEGER'IMAGE(fi) & ".log", write_mode);
                    report "Start writing file: " & "axi_stream_res_" & INTEGER'IMAGE(fi) & ".log";
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
    dc_mmu_1 : dc_mmu
        port map (
            clk           => clk,
            rst_n         => rst_n,
            restart       => restart,
            win_size      => win_size,
            img_width     => img_width,
            o_axis_tvalid => o_axis_tvalid,
            o_axis_tdata  => o_axis_tdata,
            o_axis_tready => o_axis_tready,
            o_axis_tlast  => o_axis_tlast,
            i_axis_tvalid => i_axis_tvalid,
            i_axis_tdata  => i_axis_tdata,
            i_axis_tready => i_axis_tready,
            i_axis_tlast  => i_axis_tlast
        );    
end architecture testbench;