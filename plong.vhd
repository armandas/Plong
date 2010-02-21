library ieee;
use ieee.std_logic_1164.all;

entity plong is
    port (
        clk, not_reset: in std_logic;
        nes_data_1: in std_logic;
        nes_data_2: in std_logic;
        hsync, vsync: out  std_logic;
        rgb: out std_logic_vector(2 downto 0);
        speaker: out std_logic;
        nes_clk_out: out std_logic;
        nes_ps_control: out std_logic
    );
end plong;

architecture arch of plong is
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal video_on: std_logic;
    signal px_x, px_y: std_logic_vector(9 downto 0);

    signal ball_bounced, ball_missed: std_logic;

    signal nes_start: std_logic;
    signal nes1_start, nes1_up, nes1_down,
           nes2_start, nes2_up, nes2_down: std_logic;

begin
    process (clk, not_reset)
    begin
        if clk'event and clk = '0' then
            rgb_reg <= rgb_next;
        end if;
    end process;

    -- instantiate VGA Synchronization circuit
    vga_sync_unit:
        entity work.vga(sync)
        port map(
            clk => clk, not_reset => not_reset,
            hsync => hsync, vsync => vsync,
            video_on => video_on,
            pixel_x => px_x, pixel_y => px_y
        );

    graphics_unit:
        entity work.graphics(dispatcher)
        port map(
            clk => clk, not_reset => not_reset,
            nes1_up => nes1_up, nes1_down => nes1_down,
            nes2_up => nes2_up, nes2_down => nes2_down,
            nes_start => nes_start,
            px_x => px_x, px_y => px_y,
            video_on => video_on,
            rgb_stream => rgb_next,
            ball_bounced => ball_bounced,
            ball_missed => ball_missed
        );
    nes_start <= (nes1_start or nes2_start);

    sound:
        entity work.player(behaviour)
        port map(
            clk => clk, not_reset => not_reset,
            bump_sound => ball_bounced, miss_sound => ball_missed,
            speaker => speaker
        );

    NES_controller1:
        entity work.controller(arch)
        port map(
            clk => clk, not_reset => not_reset,
            data_in => nes_data_1,
            clk_out => nes_clk_out,
            ps_control => nes_ps_control,
            gamepad(0) => open,    gamepad(1) => open,
            gamepad(2) => open,    gamepad(3) => nes1_start,
            gamepad(4) => nes1_up, gamepad(5) => nes1_down,
            gamepad(6) => open,    gamepad(7) => open
        );

    NES_controller2:
        entity work.controller(arch)
        port map(
            clk => clk, not_reset => not_reset,
            data_in => nes_data_2,
            clk_out => open,
            ps_control => open,
            gamepad(0) => open,    gamepad(1) => open,
            gamepad(2) => open,    gamepad(3) => nes2_start,
            gamepad(4) => nes2_up, gamepad(5) => nes2_down,
            gamepad(6) => open,    gamepad(7) => open
        );

    rgb <= rgb_reg;
end arch;
