library ieee;
use ieee.std_logic_1164.all;

entity plong is
    port (
        clk, reset: in std_logic;
        gamepad: in std_logic_vector(3 downto 0);
        hsync, vsync: out  std_logic;
        rgb: out std_logic_vector(2 downto 0);
        led: out std_logic_vector(7 downto 0);
        speaker: out std_logic
    );
end plong;

architecture arch of plong is
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal video_on: std_logic;
    signal px_x, px_y: std_logic_vector(9 downto 0);
    signal ball_bounced, ball_missed: std_logic;
    signal pitch: std_logic_vector(3 downto 0);
begin
    process (clk, reset)
    begin
        if clk'event and clk = '0' then
            rgb_reg <= rgb_next;
        end if;
    end process;

    -- instantiate VGA Synchronization circuit
    vga_sync_unit:
        entity work.vga(sync)
        port map(
            clk => clk, reset => reset,
            hsync => hsync, vsync => vsync,
            video_on => video_on,
            pixel_x => px_x, pixel_y => px_y
        );

    graphics_unit:
        entity work.graphics(dispatcher)
        port map(
            clk => clk, reset => reset,
            gamepad => gamepad,
            px_x => px_x, px_y => px_y,
            video_on => video_on,
            rgb_stream => rgb_next,
            ball_bounced => ball_bounced,
            ball_missed => ball_missed
        );

    sound_unit:
        entity work.plong_sounds(arch)
        port map(
            clk => clk, reset => reset,
            ball_bounced => ball_bounced,
            ball_missed => ball_missed,
            speaker => speaker
        );

    rgb <= rgb_reg;
end arch;
