-------------------------------------------------------------------------------
-- Title       : 8 Input 32 Output Fifo
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : fifo_8i_32o.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 15 08:45:14 2017
-- Last update : Fri Nov 17 11:14:53 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: 8 bit serial FiFo in, 32 bit parallel FiFo Output
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity fifo_8i_32o is
    generic (
        -- depth in bytes
        constant FIFO_DEPTH : positive := 256
    );
    Port ( 
        clk     : in std_logic;
        rst_n   : in std_logic;

        write_en    : in std_logic;
        data_in     : in std_logic_vector (7 downto 0);

        read_en     : in std_logic;
        data_out    : out std_logic_vector(31 downto 0);

        empty   : out std_logic;
        full    : out std_logic
    );
end fifo_8i_32o;

architecture Behavioral of fifo_8i_32o is
    component simple_fifo is
    generic (
        constant DATA_WIDTH : positive := 8;
        constant FIFO_DEPTH : positive := 256
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
    signal write_en_vec : std_logic_vector (3 downto 0);
    signal write_en_vec_rot : unsigned (3 downto 0);

    signal empty_vec : std_logic_vector (3 downto 0);
    signal full_vec : std_logic_vector (3 downto 0);
    
    signal data_out_int : std_logic_vector (31 downto 0);

    signal read_en_int : std_logic;
begin
    
    -------------------------------------------------------------------
    p_control : process ( clk )
    -------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                write_en_vec_rot <= "0001";
            else
                -- Control input signals
                if write_en = '1' then
                    write_en_vec_rot <= rotate_left( write_en_vec_rot, 1);
                end if;
            end if;
        end if;
    end process p_control;

    -------------------------------------------------------------------
    -- Comb outputs
    -------------------------------------------------------------------    
    write_en_vec <= std_logic_vector(write_en_vec_rot) when write_en = '1' else
                    "0000";

    read_en_int <= read_en;

    --data_out  <= data_out_int when read_en = '1' else
    --                (others => '0');
    data_out  <= data_out_int;

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
            WriteEn => write_en_vec(i),
            DataIn  => data_in,
            ReadEn  => read_en_int,
            DataOut => data_out_int( ( ((i)*8) +7) downto ((i)*8) ),
            Empty   => empty_vec(i),
            Full    => full_vec(i)
        );  
    end generate gen_fifo;

        
end Behavioral;