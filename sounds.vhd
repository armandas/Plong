library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sounds is
    port(
        clk, reset: in std_logic;
        pitch: in std_logic_vector(3 downto 0);
        speaker: out std_logic;
        enable: in std_logic
    );
end sounds;

architecture generator of sounds is
    signal counter, counter_next, limit: std_logic_vector(18 downto 0);
begin
    -- MSBs are used to determine the o/p frequency
    limit <= pitch & "111111111111111";

    process(clk)
    begin
        if reset = '1' then
            counter <= (others => '0');
        elsif clk'event and clk = '0' then
            counter <= counter_next;
        end if;
    end process;

    counter_next <= (others => '0') when counter = limit else
                    counter + 1;
    speaker <= '1' when (enable = '1' and counter < 8000) else '0';
end generator;