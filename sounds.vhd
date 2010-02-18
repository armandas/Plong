library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sounds is
    port(
        clk, not_reset: in std_logic;
        enable: in std_logic;
        period: in std_logic_vector(18 downto 0);
        volume: in std_logic_vector(2 downto 0);
        speaker: out std_logic
    );
end sounds;

architecture generator of sounds is
    signal counter, counter_next: std_logic_vector(18 downto 0);
    signal pulse_width: std_logic_vector(18 downto 0);
begin
    process(clk, not_reset)
    begin
        if not_reset = '0' then
            counter <= (others => '0');
        elsif clk'event and clk = '0' then
            counter <= counter_next;
        end if;
    end process;

    -- duty cycle:
    --    max:   50% (18 downto 1)
    --    min: 0.78% (18 downto 7)
    --    off when given 0 (18 downto 0)!
    pulse_width <= period(18 downto conv_integer(volume));

    counter_next <= (others => '0') when counter = period else
                    counter + 1;
    speaker <= '1' when (enable = '1' and counter < pulse_width) else '0';
end generator;