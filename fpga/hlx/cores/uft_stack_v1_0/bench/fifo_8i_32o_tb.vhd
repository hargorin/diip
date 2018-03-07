library ieee;
use ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

entity fifo_8i_32o_tb is
end entity ; -- fifo_8i_32o_tb

architecture tb of fifo_8i_32o_tb is

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


    signal clk      : std_logic;
    signal rst_n    : std_logic;
    signal write_en : std_logic;
    signal data_in  : std_logic_vector (7 downto 0);
    signal read_en  : std_logic;
    signal data_out : std_logic_vector(31 downto 0);
    signal empty    : std_logic;
    signal full     : std_logic;


    -- simulation signals
    signal stop_sim  : std_logic;
    constant clk_period : time := 8 ns;
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
    
    
    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_stim : process
        variable i : integer := 0;
    begin
        
        write_en <= '0';
        data_in <= (others => '0');
        read_en <= '0';

        stop_sim <= '0';

        rst_n <= '0';
        wait for 5*clk_period;
        rst_n <= '1';
        wait for 5*clk_period;

        ------------
        -- TEST 1: Store 5 data words
        ------------
        report "-- TEST 1: Store 5 data words";
        i := 0;
        write_en <= '1';
        wait for clk_period;
        for j in 0 to (5*4)-2 loop
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            wait for clk_period;
            i := i + 1;
        end loop;
        write_en <= '0';
        data_in  <= std_logic_vector(to_unsigned(i, 8));
        wait for clk_period;

        ------------
        -- TEST 2: Read 5 data words
        ------------
        report "-- TEST 2: Read 5 data words";
        wait for 2*clk_period;
        read_en <= '1';
        wait for clk_period;
            wait for clk_period;
            assert data_out = x"00010203" report "T2: Data 1 Out Error" severity error;
            wait for clk_period;
            assert data_out = x"04050607" report "T2: Data 2 Out Error" severity error;
            wait for clk_period;
            assert data_out = x"08090a0b" report "T2: Data 3 Out Error" severity error;
            wait for clk_period;
            assert data_out = x"0c0d0e0f" report "T2: Data 4 Out Error" severity error;
        read_en <= '0';
            wait for clk_period;
            assert data_out = x"10111213" report "T2: Data 5 Out Error" severity error;

        ------------
        -- TEST3: Fill Fifo
        ------------
        report "-- TEST3: Fill Fifo";
        wait for 2*clk_period;
        write_en <= '1';
        i := 0;

        l_fill : loop
            wait for clk_period;
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            wait for clk_period;
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            wait for clk_period;
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            wait for clk_period;
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            i := i + 1;
            exit when full = '1';
        end loop l_fill;
        write_en <= '0';
        data_in <= x"00";
        wait for clk_period;

        ------------
        -- TEST4: Empty Fifo
        ------------
        report "-- TEST4: Empty Fifo";
        wait for 2*clk_period;
        read_en <= '1';
        wait for clk_period;
        l_empty : loop
            wait for clk_period;
            exit when empty = '1';
        end loop l_empty;
        read_en <= '0';
        wait for clk_period;


        ------------
        -- TEST 5: Store 2.5 data words
        ------------
        report "-- TEST 5: Store 2.5 data words";
        rst_n <= '0';
        wait for 5*clk_period;
        rst_n <= '1';
        wait for 5*clk_period;
        i := 0;
        write_en <= '1';
        wait for clk_period;
        for j in 0 to 8 loop
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            wait for clk_period;
            i := i + 1;
        end loop;
        write_en <= '0';
        data_in  <= std_logic_vector(to_unsigned(i, 8));
        wait for clk_period;

        ------------
        -- TEST 6: Read all data words
        ------------
        report "-- TEST4: Empty Fifo";
        wait for 2*clk_period;
        read_en <= '1';
        wait for clk_period;
        l_empty2 : loop
            wait for clk_period;
            exit when empty = '1';
        end loop l_empty2;
        read_en <= '0';
        wait for clk_period;

        ------------
        -- End of sim
        ------------
        wait for 5*clk_period;
        report "---- Test Complete ----";
        stop_sim <= '1';
        wait;

    end process ; -- p_stim 

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    duv : fifo_8i_32o
        generic map (
            FIFO_DEPTH => 8
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            write_en => write_en,
            data_in  => data_in,
            read_en  => read_en,
            data_out => data_out,
            empty    => empty,
            full     => full
        );    
   
end tb;
