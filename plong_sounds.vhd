library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity plong_sounds is
    port(
        clk, reset: in std_logic;
        ball_bounced: in std_logic;
        ball_missed: in std_logic;
        speaker: out std_logic
    );
end plong_sounds;

architecture arch of plong_sounds is
    type sound_states is (off, playing);
    signal state, state_next: sound_states;

    signal enable: std_logic;
    signal pitch, pitch_next: std_logic_vector(3 downto 0);
    signal tone_length, tone_length_next: std_logic_vector(23 downto 0);
    signal counter, counter_next: std_logic_vector(23 downto 0);
begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            tone_length <= (others => '0');
            pitch <= (others => '0');
            state <= off;
        elsif clk'event and clk = '0' then
            counter <= counter_next;
            tone_length <= tone_length_next;
            state <= state_next;
            pitch <= pitch_next;
        end if;
    end process;

    process(state, counter, tone_length, ball_bounced, ball_missed, pitch)
    begin
        state_next <= state;
        counter_next <= counter;
        tone_length_next <= tone_length;
        pitch_next <= pitch;

        case state is
            when off =>
                if ball_bounced = '1' then
                    state_next <= playing;
                    -- short tone_length
                    tone_length_next <= conv_std_logic_vector(2000000, 24);
                    -- high pitch
                    pitch_next <= "0000";
                elsif ball_missed = '1' then
                    state_next <= playing;
                    -- long tone_length
                    tone_length_next <= (others => '1');
                    -- low pitch
                    pitch_next <= "1111";
                end if;
            when playing =>
                if counter < tone_length then
                    counter_next <= counter + 1;
                else
                    state_next <= off;
                    counter_next <= (others => '0');
                end if;
        end case;
    end process;

    enable <= '1' when state = playing else '0';

    sounds:
        entity work.sounds(generator)
        port map(
            clk => clk, reset => reset,
            pitch => pitch,
            speaker => speaker,
            enable => enable
        );
end arch;

