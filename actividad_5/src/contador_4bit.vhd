library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity contador_4bit is
    port(
        clk : in std_logic;
        enable : in std_logic;
        load : in std_logic;
        reset : in std_logic;
        val_carga : in std_logic_vector(3 downto 0);
        cuenta : out std_logic_vector(3 downto 0)
    );
end entity contador_4bit;

architecture arch of contador_4bit is
    signal est_act : std_logic_vector(3 downto 0);
begin
    process(clk)
    begin
    if rising_edge(clk) then
            if reset = '1' then
                est_act <= "0000";
            elsif load = '1' then
                est_act <= val_carga;
            elsif enable = '1' then
                est_act <= std_logic_vector(unsigned(est_act) + 1);
            else
                est_act <= est_act;
            end if;
        end if;
    end process;
    cuenta <= est_act;

end architecture arch;