library ieee;
use ieee.std_logic_1164.all;

entity semaforo_tb is
end entity semaforo_tb;

architecture Testbench of semaforo_tb is
    signal clk    : std_logic := '0';
    signal nreset : std_logic := '0';
    signal in7    : std_logic := '0'; -- Emergencia EO
    signal in6    : std_logic := '0'; -- Emergencia NS
    signal in5    : std_logic := '0'; -- Peatonal EO
    signal in4    : std_logic := '0'; -- Peatonal NS

    signal rj_1, am_1, vr_1 : std_logic;
    signal rj_2, am_2, vr_2 : std_logic;

    constant CLK_PERIOD : time := 83.333 ns; -- 12 MHz
begin
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    uut: entity work.semaforo_top
        generic map (
            CLK_FREQ => 12 -- Simulación rápida (12 ciclos = 1 seg)
        )
        port map (
            clk    => clk,
            nreset => nreset,
            in7    => in7,
            in6    => in6,
            in5    => in5,
            in4    => in4,
            rj_1   => rj_1, am_1 => am_1, vr_1 => vr_1,
            rj_2   => rj_2, am_2 => am_2, vr_2 => vr_2
        );

    stim_proc: process
    begin
        -- 1. Reset activo bajo
        nreset <= '0';
        wait for 200 ns;
        nreset <= '1';
        wait for 200 ns;

        -- 2. Secuencia Normal
        wait for 1500 * CLK_PERIOD;

        -- 3. Caso Cruce Peatonal (in5 = Peatonal EO)
        in5 <= '1';
        wait for 200 * CLK_PERIOD;
        in5 <= '0';
        wait for 1500 * CLK_PERIOD;

        -- 4. Caso Emergencia (in6 = Emergencia NS)
        in6 <= '1';
        wait for 500 * CLK_PERIOD;
        in6 <= '0';

        -- Finalización
        wait for 2000 * CLK_PERIOD;
        assert false report "Simulacion completada exitosamente." severity failure;
        wait;
    end process;

end architecture Testbench;