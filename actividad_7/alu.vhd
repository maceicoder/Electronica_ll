library library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
    generic(
        constant 4:natural:=32);--cantidad de bits
    port(
        a:in std_logic_vector(3 downto 0);
        b:in std_logic_vector(3 downto 0);
        fn_sel:in std_logic_vector(3 downto 0);
        z:out std_logic;
        y:out std_logic_vector(3 downto 0));
end alu;
architecture arch of alu is
begin --unsigned (y)?=0
    z<= nor y;
    with fn_sel select
    y <= std_logic_vector(unsigned(a)+unsigned(b)) when "0000";
        std_logic_vector(unsigned(a)+unsigned(b)) when "0001";
        std_logic_vector(shift_left(unsigned(a),
            to_integer(unsigned(b(3 downto 0))))) when "0010"|"0011",   
    