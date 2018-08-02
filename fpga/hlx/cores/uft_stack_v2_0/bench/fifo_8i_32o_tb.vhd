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
            full     : out std_logic;
            data_out_valid : out std_logic
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
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;

        variable i : integer := 0;
    begin
        
        write_en <= '0';
        data_in <= (others => '0');
        read_en <= '0';

        stop_sim <= '0';

        rst_n <= '0';
        waitfor(5);
        rst_n <= '1';
        waitfor(5);

        assert empty = '1' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;

        ------------
        -- TEST 1: Store 1 data words
        ------------
        report "-- TEST 1: Store 1 data word";
        i := 0;
        write_en <= '1';
        data_in  <= X"00";
        waitfor(1);
        data_in  <= X"01";
        waitfor(1);

        assert empty = '0' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;

        data_in  <= X"02";
        waitfor(1);
        data_in  <= X"03";
        waitfor(1);
        write_en <= '0';
        waitfor(3);


        ------------
        -- TEST 2: Read 1 data word
        ------------
        report " -- TEST 2: Read 1 data word";
        read_en <= '1';
        waitfor(1);
        read_en <= '0';
        waitfor(1);
        assert data_out = x"03020100" report "wrong output data" severity error;

        assert empty = '1' report "empty output error" severity error;
        assert full = '0' report "full output error" severity error;

        waitfor(3);
        



        --
        --for j in 0 to (5*4)-1 loop
        --    data_in  <= std_logic_vector(to_unsigned(i, 8));
        --    waitfor(1);
        --    assert empty = '0' report "empty output error" severity error;
        --    assert full = '0' report "full output error" severity error;
        --    i := i + 1;
        --end loop;

        ------------
        -- TEST 3: Store 5 data words
        ------------
        report "-- TEST 3: Store 5 data words";
        i := 0;
        write_en <= '1';
        for j in 0 to (5*4)-1 loop
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            i := i + 1;
        end loop;
        write_en <= '0';
        data_in  <= std_logic_vector(to_unsigned(i, 8));
        waitfor(1);

        ------------
        -- TEST 4: Read 5 data words
        ------------
        report "-- TEST 4: Read 5 data words";
        read_en <= '1';
        waitfor(1);
        --read_en <= '0';
        waitfor(1);
        assert data_out = x"03020100" report "wrong output data" severity error;
        waitfor(1);
        assert data_out = x"07060504" report "wrong output data" severity error;
        waitfor(1);
        assert data_out = x"0b0a0908" report "wrong output data" severity error;
        waitfor(1);
        assert data_out = x"0f0e0d0c" report "wrong output data" severity error;
        waitfor(1);
        read_en <= '0';
        assert data_out = x"13121110" report "wrong output data" severity error;

        waitfor(3);

        ------------
        -- TEST 5: Fill Fifo
        ------------
        report "-- TEST 5: Fill Fifo";
        waitfor(2);
        
        write_en <= '1';
        i := 0;
        l_fill : loop
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            exit when full = '1';
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            exit when full = '1';
            i := i + 1;
            exit when full = '1';
        end loop l_fill;
        write_en <= '0';
        data_in <= x"00";
        waitfor(1);

        ------------
        -- TEST6: Empty Fifo
        ------------
        report "-- TEST6: Empty Fifo";
        waitfor(2);
        i := 0;
        read_en <= '1';
        waitfor(1);
        l_empty : loop
            waitfor(1);
            assert data_out(7 downto  0) = std_logic_vector(to_unsigned(i, 8)) report "wrong output data" severity error;
            assert data_out(15 downto 8) = std_logic_vector(to_unsigned(i, 8)) report "wrong output data" severity error;
            assert data_out(23 downto 16) = std_logic_vector(to_unsigned(i, 8)) report "wrong output data" severity error;
            assert data_out(31 downto 24) = std_logic_vector(to_unsigned(i, 8)) report "wrong output data" severity error;
            i := i + 1;
            exit when empty = '1';
        end loop l_empty;
        read_en <= '0';
        waitfor(1);


        ------------
        -- TEST 5: Store 2.5 data words
        ------------
        report "-- TEST 5: Store 2.5 data words";

        waitfor(5);
        i := 0;
        write_en <= '1';
        for j in 0 to (3*4)-(1+0) loop
            data_in  <= std_logic_vector(to_unsigned(i, 8));
            waitfor(1);
            i := i + 1;
        end loop;
        write_en <= '0';
        data_in  <= std_logic_vector(to_unsigned(i, 8));
        waitfor(1);

        ------------
        -- TEST 6: Read all data words
        ------------
        report "-- TEST4: Empty Fifo";
        read_en <= '1';
        waitfor(1);
        waitfor(1);
        assert data_out = x"03020100" report "wrong output data" severity error;
        waitfor(1);
        assert data_out = x"07060504" report "wrong output data" severity error;
        waitfor(1);
        assert data_out = x"0b0a0908" report "wrong output data" severity error;
        read_en <= '0';

        waitfor(3);

        --waitfor(2);
        --read_en <= '1';
        --waitfor(1);
        --l_empty2 : loop
        --    waitfor(1);
        --    exit when empty = '1';
        --end loop l_empty2;
        --read_en <= '0';
        --waitfor(1);

        ------------
        -- End of sim
        ------------
        waitfor(5);
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
