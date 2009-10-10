library ieee;
use ieee.std_logic_1164.all;

entity vga_test is
    port (
        clk, reset: in std_logic;
        hsync, vsync: out  std_logic;
        rgb: out std_logic_vector(2 downto 0)
    );
end vga_test;

architecture arch of vga_test is
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal video_on: std_logic;
    signal px_x, px_y: std_logic_vector(9 downto 0);

    constant BAR_X: integer := 5;
    constant BAR_Y: integer := 21;

    constant BALL_X: integer := 8;
    constant BALL_Y: integer := 8;

begin


    process (clk, reset)
    begin
        if video_on = '0' then
            rgb_reg
    end process;

    -- instantiate bar object
    bar_unit: entity work.bar_object(content)
        port map(
            addr => px_y(
        );

    -- instantiate VGA Synchronization circuit
    vga_sync_unit: entity work.vga(sync)
        port map(
            clk => clk, reset => reset,
            hsync => hsync, vsync => vsync,
            video_on => video_on, p_tick=>open,
            pixel_x => px_x, pixel_y => px_y
        );

    rgb <= rgb_reg when video_on = '1' else "000";
end arch;