library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.finish;

entity contador_4bit_tb is
    end entity contador_4bit_tb;

architecture arch of contador_4bit_tb is
    component contador_4bit
     port(
        clk : in std_logic;
        enable : in std_logic;
        load : in std_logic;
        reset : in std_logic;
        val_carga : in std_logic_vector(3 downto 0);
        cuenta : out std_logic_vector(3 downto 0)
    );
    end component;

    signal clk_tb : std_logic := '0';
    signal enable_tb : std_logic := '0';
    signal reset_tb : std_logic := '0';
    signal load_tb : std_logic := '0';
    signal val_carga_tb : std_logic_vector(3 downto 0) := "0000"; 
    signal cuenta_tb : std_logic_vector(3 downto 0);

    constant periodo : time := 10 ns;
    begin
        union : contador_4bit
        port map(
            clk => clk_tb,
            enable => enable_tb,
            reset => reset_tb,
            load => load_tb,
            val_carga => val_carga_tb,
            cuenta => cuenta_tb
        );

        reloj : process
    begin
        clk_tb <= '0';
        wait for periodo / 2;
        clk_tb <= '1';
        wait for periodo / 2;
    end process;
        
        estimulo : process
    begin
        reset_tb     <= '1';
        load_tb      <= '0';
        enable_tb    <= '0';
        val_carga_tb <= "0000";
        wait for periodo * 2;

        reset_tb     <= '0';
        load_tb      <= '1';
        val_carga_tb <= "0001";
        wait for periodo;

        load_tb   <= '0';
        enable_tb <= '1';
        wait for periodo * 5;

        reset_tb <= '1';
        wait for periodo * 2;

        reset_tb <= '0';
        wait for periodo * 5;

        finish;
    end process;
end architecture arch;