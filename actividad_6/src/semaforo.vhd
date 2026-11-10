library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- 1. SUB-FSM CRUCE (MEMORIZADOR DE PEATÓN)
--------------------------------------------------------------------------------
entity cruce is
    port (
        clk   : in  std_logic;
        reset : in  std_logic; -- Reset activo alto interno
        P     : in  std_logic; -- Pulsador peatonal
        res   : in  std_logic; -- Limpieza desde FSM Control
        S     : out std_logic  -- Solicitud registrada
    );
end entity cruce;

architecture Behavioral of cruce is
    type state_type is (NPED, PED);
    signal state_reg, state_next : state_type;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= NPED;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    process(state_reg, P, res)
    begin
        state_next <= state_reg;
        case state_reg is
            when NPED =>
                if P = '1' then
                    state_next <= PED;
                end if;
            when PED =>
                if res = '1' then
                    state_next <= NPED;
                end if;
        end case;
    end process;

    S <= '1' when state_reg = PED else '0';
end architecture Behavioral;

--------------------------------------------------------------------------------
-- 2. PRESCALER (DIVISOR DE FRECUENCIA DE 12 MHz A 1 Hz)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prescaler is
    generic (
        CLK_FREQ : integer := 12_000_000 -- Reloj base EDU-CIAA-FPGA
    );
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        tick_1s : out std_logic
    );
end entity prescaler;

architecture Behavioral of prescaler is
    signal count : integer range 0 to CLK_FREQ - 1 := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count   <= 0;
            tick_1s <= '0';
        elsif rising_edge(clk) then
            if count = CLK_FREQ - 1 then
                count   <= 0;
                tick_1s <= '1';
            else
                count   <= count + 1;
                tick_1s <= '0';
            end if;
        end if;
    end process;
end architecture Behavioral;

--------------------------------------------------------------------------------
-- 3. TEMPORIZADOR DE SEGUNDOS
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temporizador is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        tick_1s : in  std_logic;
        C       : in  std_logic;                     -- Carga síncrona
        Q       : in  std_logic_vector(7 downto 0);  -- Tiempo a cargar
        Z       : out std_logic                      -- Fin de cuenta
    );
end entity temporizador;

architecture Behavioral of temporizador is
    signal timer_cnt : unsigned(7 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            timer_cnt <= (others => '0');
        elsif rising_edge(clk) then
            if C = '1' then
                timer_cnt <= unsigned(Q);
            elsif tick_1s = '1' then
                if timer_cnt > 0 then
                    timer_cnt <= timer_cnt - 1;
                end if;
            end if;
        end if;
    end process;

    Z <= '1' when (timer_cnt <= 1) else '0';
end architecture Behavioral;

--------------------------------------------------------------------------------
-- 4. FSM PRINCIPAL DE CONTROL
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsm_control is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        Z      : in  std_logic;
        S_NS   : in  std_logic;
        S_EO   : in  std_logic;
        E_NS   : in  std_logic;
        E_EO   : in  std_logic;
        L_NS   : out std_logic_vector(2 downto 0); -- [Rojo, Amarillo, Verde]
        L_EO   : out std_logic_vector(2 downto 0); -- [Rojo, Amarillo, Verde]
        C      : out std_logic;
        Q      : out std_logic_vector(7 downto 0);
        res_NS : out std_logic;
        res_EO : out std_logic
    );
end entity fsm_control;

architecture Behavioral of fsm_control is
    type mef_ctl_s is (RV, RVext, RA, VR, VRext, AR);
    signal est_mef, est_mef_sig : mef_ctl_s;

    constant RED    : std_logic_vector(2 downto 0) := "100";
    constant YELLOW : std_logic_vector(2 downto 0) := "010";
    constant GREEN  : std_logic_vector(2 downto 0) := "001";
begin
    -- Memoria de Estado (ME)
    process(clk, reset)
    begin
        if reset = '1' then
            est_mef <= RV;
        elsif rising_edge(clk) then
            est_mef <= est_mef_sig;
        end if;
    end process;

    -- Lógica de Estado Siguiente (LES) y Salidas (LS)
    process(all)
    begin
        est_mef_sig <= est_mef;
        C           <= '0';
        Q           <= x"32"; -- 50 s
        res_NS      <= '0';
        res_EO      <= '0';
        L_NS        <= RED;
        L_EO        <= GREEN;

        case est_mef is
            when RV =>
                L_NS <= RED;
                L_EO <= GREEN;
                if (Z = '1' or E_NS = '1') and E_EO = '0' then
                    if S_EO = '1' then
                        est_mef_sig <= RVext;
                        C           <= '1';
                        Q           <= x"32";
                    else
                        est_mef_sig <= RA;
                        C           <= '1';
                        Q           <= x"0A";
                    end if;
                end if;

            when RVext =>
                L_NS <= RED;
                L_EO <= GREEN;
                if Z = '1' and E_EO = '0' then
                    est_mef_sig <= RA;
                    C           <= '1';
                    Q           <= x"0A";
                    res_EO      <= '1';
                end if;

            when RA =>
                L_NS <= RED;
                L_EO <= YELLOW;
                if Z = '1' then
                    est_mef_sig <= VR;
                    C           <= '1';
                    Q           <= x"32";
                end if;

            when VR =>
                L_NS <= GREEN;
                L_EO <= RED;
                if (Z = '1' or E_EO = '1') and E_NS = '0' then
                    if S_NS = '1' then
                        est_mef_sig <= VRext;
                        C           <= '1';
                        Q           <= x"32";
                    else
                        est_mef_sig <= AR;
                        C           <= '1';
                        Q           <= x"0A";
                    end if;
                end if;

            when VRext =>
                L_NS <= GREEN;
                L_EO <= RED;
                if Z = '1' and E_NS = '0' then
                    est_mef_sig <= AR;
                    C           <= '1';
                    Q           <= x"0A";
                    res_NS      <= '1';
                end if;

            when AR =>
                L_NS <= YELLOW;
                L_EO <= RED;
                if Z = '1' then
                    est_mef_sig <= RV;
                    C           <= '1';
                    Q           <= x"32";
                end if;

            when others =>
                est_mef_sig <= RV;
        end case;
    end process;
end architecture Behavioral;

--------------------------------------------------------------------------------
-- 5. MÓDULO TOP-LEVEL INTEGRADOR
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity semaforo_top is
    generic (
        CLK_FREQ : integer := 12_000_000
    );
    port (
        clk    : in  std_logic;
        nreset : in  std_logic;
        in7    : in  std_logic; -- Emergencia 1 (EO)
        in6    : in  std_logic; -- Emergencia 2 (NS)
        in5    : in  std_logic; -- Peatonal 1 (EO)
        in4    : in  std_logic; -- Peatonal 2 (NS)
        rj_1   : out std_logic;
        am_1   : out std_logic;
        vr_1   : out std_logic;
        rj_2   : out std_logic;
        am_2   : out std_logic;
        vr_2   : out std_logic
    );
end entity semaforo_top;

architecture Structural of semaforo_top is
    signal reset_sys      : std_logic;
    signal tick_1s        : std_logic;
    signal Z              : std_logic;
    signal C              : std_logic;
    signal Q              : std_logic_vector(7 downto 0);
    signal S_NS, S_EO     : std_logic;
    signal res_NS, res_EO : std_logic;
    signal L_NS, L_EO     : std_logic_vector(2 downto 0);
begin
    reset_sys <= not nreset;

    inst_cruce_NS: entity work.cruce
        port map (
            clk   => clk,
            reset => reset_sys,
            P     => in4,
            res   => res_NS,
            S     => S_NS
        );

    inst_cruce_EO: entity work.cruce
        port map (
            clk   => clk,
            reset => reset_sys,
            P     => in5,
            res   => res_EO,
            S     => S_EO
        );

    inst_prescaler: entity work.prescaler
        generic map (
            CLK_FREQ => CLK_FREQ
        )
        port map (
            clk     => clk,
            reset   => reset_sys,
            tick_1s => tick_1s
        );

    inst_temporizador: entity work.temporizador
        port map (
            clk     => clk,
            reset   => reset_sys,
            tick_1s => tick_1s,
            C       => C,
            Q       => Q,
            Z       => Z
        );

    inst_control: entity work.fsm_control
        port map (
            clk    => clk,
            reset  => reset_sys,
            Z      => Z,
            S_NS   => S_NS,
            S_EO   => S_EO,
            E_NS   => in6,
            E_EO   => in7,
            L_NS   => L_NS,
            L_EO   => L_EO,
            C      => C,
            Q      => Q,
            res_NS => res_NS,
            res_EO => res_EO
        );

    rj_2 <= L_NS(2); am_2 <= L_NS(1); vr_2 <= L_NS(0);
    rj_1 <= L_EO(2); am_1 <= L_EO(1); vr_1 <= L_EO(0);

end architecture Structural;