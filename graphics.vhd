library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity graphics is
    port(
        clk, reset: in std_logic;
        gamepad: in std_logic_vector(3 downto 0);
        px_x, px_y: in std_logic_vector(9 downto 0);
        video_on: in std_logic;
        rgb_stream: out std_logic_vector(2  downto 0)
    );
end graphics;

architecture dispatcher of graphics is
    constant SCREEN_WIDTH: integer := 640;
    constant SCREEN_HEIGHT: integer := 480;

    constant BALL_SIZE: integer := 16; -- ball is square
    signal ball_addr: std_logic_vector(3 downto 0);
    signal ball_px_addr: std_logic_vector(3 downto 0);
    signal ball_data: std_logic_vector(0 to BALL_SIZE - 1);
    signal ball_pixel: std_logic;
    signal ball_rgb: std_logic_vector(2 downto 0);
    signal ball_x, ball_x_next: std_logic_vector(9 downto 0);
    signal ball_y, ball_y_next: std_logic_vector(9 downto 0);

    constant BAR_1_POS: integer := 20;
    constant BAR_2_POS: integer := 600;

    constant BAR_WIDTH: integer := 20;
    constant BAR_HEIGHT: integer := 128;
    
    signal bar_pos: integer;
    signal bar_addr: std_logic_vector(6 downto 0);
    signal bar_data: std_logic_vector(0 to BAR_WIDTH - 1);
    signal bar_pixel: std_logic;
    signal bar_rgb: std_logic_vector(2 downto 0);
    signal bar_1_y, bar_1_y_next,
           bar_2_y, bar_2_y_next: std_logic_vector(9 downto 0);

    signal ball_on, bar_on: std_logic;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            ball_x <= (others => '0');
            ball_y <= (others => '0');
            bar_1_y <= (others => '0');
            bar_2_y <= (others => '0');
        elsif clk'event and clk = '0' then
            ball_x <= ball_x_next;
            ball_y <= ball_y_next;
            bar_1_y <= bar_1_y_next;
            bar_2_y <= bar_2_y_next;
        end if;
    end process;
    
    ball_x_next <= ball_x;
    ball_y_next <= ball_y;
    
    process(bar_1_y, bar_2_y, px_x, px_y, gamepad)
    begin
        bar_1_y_next <= bar_1_y;
        bar_2_y_next <= bar_2_y;

        if px_x = 0 and px_y = 0 then
            if gamepad(0) = '1' and bar_1_y > 0 then
                bar_1_y_next <= bar_1_y - 1;
            elsif gamepad(1) = '1' and bar_1_y < SCREEN_HEIGHT - BAR_HEIGHT then
                bar_1_y_next <= bar_1_y + 1;
            end if;

            if gamepad(2) = '1' and bar_2_y > 0 then
                bar_2_y_next <= bar_2_y - 1;
            elsif gamepad(3) = '1' and bar_2_y < SCREEN_HEIGHT - BAR_HEIGHT then
                bar_2_y_next <= bar_2_y + 1;
            end if;
        end if;
    end process;

    ball_on <= '1' when px_x >= ball_x and
                        px_x < (ball_x + BALL_SIZE) and
                        px_y >= ball_y and
                        px_y < (ball_y + BALL_SIZE) else
               '0';

    bar_on <= '1' when (px_x >= BAR_1_POS and
                        px_x < BAR_1_POS + BAR_WIDTH and
                        px_y >= bar_1_y and
                        px_y < bar_1_y + BAR_HEIGHT) or
                       (px_x >= BAR_2_POS and
                        px_x < BAR_2_POS + BAR_WIDTH and 
                        px_y >= bar_2_y and
                        px_y < bar_2_y + BAR_HEIGHT) else
              '0';

    ball_addr <= px_y(3 downto 0) - ball_y(3 downto 0);
    ball_px_addr <= px_x(3 downto 0) - ball_x(3 downto 0);
    ball_pixel <= ball_data(conv_integer(ball_px_addr));
    ball_rgb <= "000" when ball_pixel = '1' else "111";

    bar_pos <= BAR_1_POS when px_x < 320 else BAR_2_POS;

    bar_addr <= (px_y(6 downto 0) - bar_1_y(6 downto 0)) when px_x < 320 else
                (px_y(6 downto 0) - bar_2_y(6 downto 0));
    bar_pixel <= bar_data(conv_integer(px_x - bar_pos));
    bar_rgb <= "000" when bar_pixel = '1' else "111";

    process(ball_on, bar_on, video_on, ball_rgb, bar_rgb)
    begin
        if video_on = '1' then
            if ball_on = '1' then
                rgb_stream <= ball_rgb;
            elsif bar_on = '1' then
                rgb_stream <= bar_rgb;
            else
                -- background is white
                rgb_stream <= "111";
            end if;
        else
            -- blank screen
            rgb_stream <= "000";
        end if;
    end process;

    ball_unit:
        entity work.ball_rom(content)
        port map(addr => ball_addr, data => ball_data);
        
    bar_unit:
        entity work.bar_rom(content)
        port map(clk => clk, addr => bar_addr, data => bar_data);

end dispatcher;