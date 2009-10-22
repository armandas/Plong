library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity graphics is
    port(
        clk, reset: in std_logic;
        gamepad: in std_logic_vector(3 downto 0);
        px_x, px_y: in std_logic_vector(9 downto 0);
        video_on: in std_logic;
        rgb_stream: out std_logic_vector(2  downto 0);
        ball_bounced: out std_logic;
        ball_missed: out std_logic;
    );
end graphics;

architecture dispatcher of graphics is
    constant SCREEN_WIDTH: integer := 640;
    constant SCREEN_HEIGHT: integer := 480;

    type game_states is (start, waiting, playing, game_over);
    signal state, state_next: game_states;

    signal score_1, score_2: std_logic_vector(2 downto 0);

    constant MIDDLE_LINE_POS: integer := SCREEN_WIDTH / 2;
    signal middle_line_on: std_logic;
    signal middle_line_rgb: std_logic_vector(2 downto 0);

    constant BALL_SIZE: integer := 16; -- ball is square
    signal ball_enable: std_logic;
    signal ball_addr: std_logic_vector(3 downto 0);
    signal ball_px_addr: std_logic_vector(3 downto 0);
    signal ball_data: std_logic_vector(0 to BALL_SIZE - 1);
    signal ball_pixel: std_logic;
    signal ball_rgb: std_logic_vector(2 downto 0);
    signal ball_x, ball_x_next: std_logic_vector(9 downto 0);
    signal ball_y, ball_y_next: std_logic_vector(9 downto 0);

    signal ball_h_dir, ball_h_dir_next, ball_v_dir, ball_v_dir_next: std_logic;
    signal ball_speed, ball_speed_next: std_logic_vector(2 downto 0);

    signal ball_bounce, ball_miss: std_logic;

    -- counts how many times the ball hits the bar
    -- used to determine ball speed
    signal bounce_counter, bounce_counter_next: std_logic_vector(3 downto 0);

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

    process(state, ball_x, gamepad)
    begin
        state_next <= state;
        ball_enable <= '0';
        ball_miss <= '0';

        case state is
            when start =>
                score_1 <= (others => '0');
                score_2 <= (others => '0');
                state_next <= waiting;
            when waiting =>
                ball_enable <= '0';
                if (score_1 + score_2) = 5 then
                    state_next <= game_over;
                elsif gamepad > 0 then
                    state_next <= playing;
                end if;
            when playing =>
                ball_enable <= '1';
                if ball_x = 0 then
                    -- player 2 wins
                    score_2 <= score_2 + 1;
                    state_next <= waiting;
                    ball_miss <= '1';
                elsif ball_x = SCREEN_WIDTH - BALL_SIZE then
                    -- player 1 wins
                    score_1 <= score_1 + 1;
                    state_next <= waiting;
                    ball_miss <= '1';
                end if;
            when game_over =>
                if gamepad > 0 then
                    state_next <= waiting;
                end if;
        end case;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            state <= start;
            ball_x <= (others => '0');
            ball_y <= (others => '0');
            bar_1_y <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BAR_HEIGHT / 2, 10);
            bar_2_y <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BAR_HEIGHT / 2, 10);
            ball_h_dir <= '0';
            ball_v_dir <= '0';
            ball_speed <= "001";
            bounce_counter <= "0001";
        elsif clk'event and clk = '0' then
            state <= state_next;
            ball_x <= ball_x_next;
            ball_y <= ball_y_next;
            bar_1_y <= bar_1_y_next;
            bar_2_y <= bar_2_y_next;
            ball_h_dir <= ball_h_dir_next;
            ball_v_dir <= ball_v_dir_next;
            ball_speed <= ball_speed_next;
            bounce_counter <= bounce_counter_next;
        end if;
    end process;

    direction_control: process(
        px_x, px_y,
        ball_x, ball_y,
        ball_h_dir, ball_v_dir,
        ball_h_dir_next, ball_v_dir_next,
        bar_1_y, bar_2_y
    )
    begin
        ball_h_dir_next <= ball_h_dir;
        ball_v_dir_next <= ball_v_dir;
        ball_bounce <= '0';

        if px_x = 0 and px_y = 0 then
            if ball_x = BAR_1_POS + BAR_WIDTH and
               ball_y >= bar_1_y and ball_y < bar_1_y + BAR_HEIGHT then
                ball_h_dir_next <= '1';
                ball_bounce <= '1';
            elsif ball_x = BAR_2_POS - BALL_SIZE and
                  ball_y >= bar_2_y and ball_y < bar_2_y + BAR_HEIGHT then
                ball_h_dir_next <= '0';
                ball_bounce <= '1';
            end if;
            
            if ball_y = 0 then
                ball_v_dir_next <= '1';
            elsif ball_y = SCREEN_HEIGHT - BALL_SIZE - 1 then
                ball_v_dir_next <= '0';
            end if;
        end if;
    end process;

    bounce_counter_next <= bounce_counter + 1 when ball_bounce = '1' else
                           "0000" when ball_miss = '1' else
                           bounce_counter;

    ball_speed_next <= "001" when bounce_counter = 0 else
                       --"010" when bounce_counter = 3 else
                       --"011" when bounce_counter = 9 else
                       ball_speed;

    ball_control: process(
        px_x, px_y,
        ball_x, ball_y,
        ball_x_next, ball_y_next,
        ball_h_dir, ball_v_dir,
        ball_speed, ball_speed,
        ball_enable
    )
    begin
        ball_x_next <= ball_x;
        ball_y_next <= ball_y;

        if ball_enable = '1' then
            if px_x = 0 and px_y = 0 then
                if ball_h_dir = '1' then
                    ball_x_next <= ball_x + ball_speed;
                else
                    ball_x_next <= ball_x - ball_speed;
                end if;

                if ball_v_dir = '1' then
                    if ball_y + BALL_SIZE + ball_speed > SCREEN_HEIGHT then
                        ball_y_next <= conv_std_logic_vector(SCREEN_HEIGHT - BALL_SIZE, 10);
                    else
                        ball_y_next <= ball_y + ball_speed;
                    end if;
                else
                    ball_y_next <= ball_y - ball_speed;
                end if;
            end if;
        else
            ball_x_next <= conv_std_logic_vector(SCREEN_WIDTH / 2 - BALL_SIZE / 2, 10);
            ball_y_next <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BALL_SIZE / 2, 10);
        end if;
    end process;

    bar_control: process(bar_1_y, bar_2_y, px_x, px_y, gamepad)
    begin
        bar_1_y_next <= bar_1_y;
        bar_2_y_next <= bar_2_y;
        
        if px_x = 0 and px_y = 0 then
            if gamepad(0) = '1' then
                -- if there is enough space
                if bar_1_y > 2 then
                    -- just move by standard ammount
                    bar_1_y_next <= bar_1_y - 3;
                else
                    -- otherwise, move to the end
                    bar_1_y_next <= (others => '0');
                end if;
            elsif gamepad(1) = '1' then
                -- if there is enough space
                if bar_1_y < SCREEN_HEIGHT - BAR_HEIGHT - 2 then
                    -- just move by standard ammount
                    bar_1_y_next <= bar_1_y + 3;
                else
                    -- otherwise, move to the end
                    bar_1_y_next <= conv_std_logic_vector(SCREEN_HEIGHT - BAR_HEIGHT, 10);
                end if;
            end if;

            if gamepad(2) = '1' then
                -- if there is enough space
                if bar_2_y > 2 then
                    -- just move by standard ammount
                    bar_2_y_next <= bar_2_y - 3;
                else
                    -- otherwise, move to the end
                    bar_2_y_next <= (others => '0');
                end if;
            elsif gamepad(3) = '1' then
                -- if there is enough space
                if bar_2_y < SCREEN_HEIGHT - BAR_HEIGHT - 2 then
                    -- just move by standard ammount
                    bar_2_y_next <= bar_2_y + 3;
                else
                    -- otherwise, move to the end
                    bar_2_y_next <= conv_std_logic_vector(SCREEN_HEIGHT - BAR_HEIGHT, 10);
                end if;
            end if;
        end if;
    end process;

    middle_line_on <= '1' when px_x = MIDDLE_LINE_POS else '0';
    middle_line_rgb <= "000" when px_y(0) = '1' else "111";

    ball_on <= '1' when px_x >= ball_x and
                        px_x < (ball_x + BALL_SIZE) and
                        px_y >= ball_y and
                        px_y < (ball_y + BALL_SIZE) else
               '0';

    -- whether bar_1 or bar_2 is on
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


    bar_addr <= (px_y(6 downto 0) - bar_1_y(6 downto 0)) when px_x < 320 else
                (px_y(6 downto 0) - bar_2_y(6 downto 0));
    bar_pos <= BAR_1_POS when px_x < 320 else BAR_2_POS;
    bar_pixel <= bar_data(conv_integer(px_x - bar_pos));
    bar_rgb <= "000" when bar_pixel = '1' else "111";

    process(
        ball_on, bar_on,
        ball_rgb, bar_rgb,
        middle_line_on, middle_line_rgb,
        video_on
    )
    begin
        if video_on = '1' then
            if bar_on = '1' then
                rgb_stream <= bar_rgb;
            elsif ball_on = '1' then
                rgb_stream <= ball_rgb;
            elsif middle_line_on = '1' then
                rgb_stream <= middle_line_rgb;
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

    ball_bounced <= ball_bounce;
    ball_missed <= ball_miss;

end dispatcher;