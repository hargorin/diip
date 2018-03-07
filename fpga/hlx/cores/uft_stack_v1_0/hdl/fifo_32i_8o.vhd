-------------------------------------------------------------------------------
-- Title       : 32 Input 8 Output Fifo
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : fifo_32i_8o.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 15 08:45:14 2017
-- Last update : Wed Mar  7 13:39:46 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: 32 bit parallel FiFo in, 8 bit serial FiFo Output. Output is 
-- LSB first (little-endian)
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity fifo_32i_8o is
    generic (
        -- depth in bytes
        constant FIFO_DEPTH : positive := 256
    );
    Port ( 
        clk     : in std_logic;
        rst_n   : in std_logic;

        write_en    : in std_logic;
        data_in     : in std_logic_vector (31 downto 0);

        read_en     : in std_logic;
        data_out    : out std_logic_vector(7 downto 0);

        empty   : out std_logic;
        full    : out std_logic
    );
end fifo_32i_8o;

architecture Behavioral of fifo_32i_8o is
    component simple_fifo is
    generic (
        constant DATA_WIDTH : positive := 8;
        constant FIFO_DEPTH : positive := 1500
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

    -- toggles the write enable of the correct input
    signal read_en_vec : std_logic_vector (3 downto 0) := "0000";
    signal read_en_vec_rot : unsigned (3 downto 0) := "0001";
    signal read_en_vec_rot_out : unsigned (3 downto 0) := "1000";

    signal empty_vec : std_logic_vector (3 downto 0);
    signal full_vec : std_logic_vector (3 downto 0);
    
    signal data_out_int : std_logic_vector (31 downto 0);

    signal write_en_int : std_logic;
begin
    
    -------------------------------------------------------------------
    p_control : process ( clk )
    -------------------------------------------------------------------
        variable next_index : natural range 0 to 3 :=0 ;
        variable index : natural range 0 to 3 := 0;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                read_en_vec_rot <= "0001";
                read_en_vec_rot_out <= "1000";
            else
                -- Control input signals
                if read_en = '1' then
                    if index = 3 then
                        next_index := 0;
                    else
                        next_index := index + 1;
                    end if;
                    -- rotate read and out vectors
                    -- as long as fifo is not empty
                    if empty_vec /= "1111" then
                        read_en_vec_rot <= rotate_left( read_en_vec_rot, 1);
                        index := next_index;
                        read_en_vec_rot_out <= rotate_left( read_en_vec_rot_out, 1);
                    end if;
                end if;
            end if;
        end if;
    end process p_control;
    
    -------------------------------------------------------------------
    -- Comb outputs
    -------------------------------------------------------------------    
    read_en_vec <= std_logic_vector(read_en_vec_rot) when read_en = '1'
        else "0000";

    write_en_int <= write_en;

    data_out  <=    data_out_int(7 downto 0)   when read_en_vec_rot_out = "0001" else
                    data_out_int(15 downto 8)  when read_en_vec_rot_out = "0010" else
                    data_out_int(23 downto 16) when read_en_vec_rot_out = "0100" else
                    data_out_int(31 downto 24) when read_en_vec_rot_out = "1000" else
                    (others => '0');

    empty  <= '1' when empty_vec = "1111" else '0';
    full   <= '1' when full_vec  = "1111" else '0';

    -------------------------------------------------------------------
    -- Generate 4 FiFos
    -------------------------------------------------------------------
    gen_fifo : for i in 0 to 3 generate
        fifo_x : simple_fifo
        generic map (
            DATA_WIDTH => 8,
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            CLK     => clk,
            RST_N   => rst_n,
            WriteEn => write_en_int,
            DataIn  => data_in( ( ((i)*8) +7) downto ((i)*8) ),
            ReadEn  => read_en_vec(i),
            DataOut => data_out_int( ( ((i)*8) +7) downto ((i)*8) ),
            Empty   => empty_vec(i),
            Full    => full_vec(i)
        );  
    end generate gen_fifo;

        
end Behavioral;