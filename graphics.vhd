library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity graphics is
    port(
        clk, not_reset: in  std_logic;
        nes1_up, nes1_down: in  std_logic;
        nes2_up, nes2_down: in  std_logic;
        nes_start: in  std_logic;
        px_x, px_y: in  std_logic_vector(9 downto 0);
        video_on: in  std_logic;
        rgb_stream: out std_logic_vector(2  downto 0);
        ball_bounced: out std_logic;
        ball_missed: out std_logic
    );
end graphics;

architecture dispatcher of graphics is
    constant SCREEN_WIDTH: integer := 640;
    constant SCREEN_HEIGHT: integer := 480;

    type game_states is (start, waiting, playing, game_over);
    signal state, state_next: game_states;

    type counter_storage is array(0 to 3) of std_logic_vector(17 downto 0);
    constant COUNTER_VALUES: counter_storage :=
    (
        "110010110111001101", -- 208333
        "101000101100001011", -- 166667
        "100001111010001001", -- 138889
        "011101000100001000"  -- 119048
    );

    -- counters to determine ball control frequency
    signal ball_control_counter,
           ball_control_counter_next: std_logic_vector(17 downto 0);
    signal ball_control_value: integer;

    -- counts how many times the ball hits the bar
    -- used to determine ball speed
    signal bounce_counter, bounce_counter_next: std_logic_vector(7 downto 0);

    constant MIDDLE_LINE_POS: integer := SCREEN_WIDTH / 2;
    signal middle_line_on: std_logic;
    signal middle_line_rgb: std_logic_vector(2 downto 0);

    signal score_1, score_1_next: std_logic_vector(5 downto 0);
    signal score_2, score_2_next: std_logic_vector(5 downto 0);

    signal score_on: std_logic;
    signal current_score: std_logic_vector(5 downto 0);
    signal score_font_addr: std_logic_vector(8 downto 0);

    -- message format is "PLAYER p WINS!"
    -- where p is replaced by player_id
    signal message_on, player_id_on: std_logic;
    signal message_font_addr, player_id_font_addr: std_logic_vector(8 downto 0);

    signal font_addr: std_logic_vector(8 downto 0);
    signal font_data: std_logic_vector(0 to 7);
    signal font_pixel: std_logic;
    signal font_rgb: std_logic_vector(2 downto 0);

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

    signal ball_bounce, ball_miss: std_logic;

    constant BAR_1_POS: integer := 20;
    constant BAR_2_POS: integer := 600;

    constant BAR_WIDTH: integer := 20;
    constant BAR_HEIGHT: integer := 64;

    signal bar_pos: integer;
    signal bar_addr: std_logic_vector(5 downto 0);
    signal bar_data: std_logic_vector(0 to BAR_WIDTH - 1);
    signal bar_pixel: std_logic;
    signal bar_rgb: std_logic_vector(2 downto 0);
    signal bar_1_y, bar_1_y_next,
           bar_2_y, bar_2_y_next: std_logic_vector(9 downto 0);

    signal ball_on, bar_on: std_logic;
begin

    process(state, ball_x, nes_start, score_1, score_2)
    begin
        state_next <= state;
        ball_enable <= '0';
        ball_miss <= '0';
        score_1_next <= score_1;
        score_2_next <= score_2;

        case state is
            when start =>
                score_1_next <= (others => '0');
                score_2_next <= (others => '0');
                state_next <= waiting;
            when waiting =>
                ball_enable <= '0';
                if score_1 = 7 or score_2 = 7 then
                    state_next <= game_over;
                elsif nes_start = '1' then
                    state_next <= playing;
                end if;
            when playing =>
                ball_enable <= '1';
                if ball_x = 0 then
                    -- player 2 wins
                    score_2_next <= score_2 + 1;
                    state_next <= waiting;
                    ball_miss <= '1';
                elsif ball_x = SCREEN_WIDTH - BALL_SIZE then
                    -- player 1 wins
                    score_1_next <= score_1 + 1;
                    state_next <= waiting;
                    ball_miss <= '1';
                end if;
            when game_over =>
                if nes_start = '1' then
                    state_next <= start;
                end if;
        end case;
    end process;

    process(clk, not_reset)
    begin
        if not_reset = '0' then
            state <= start;
            ball_x <= (others => '0');
            ball_y <= (others => '0');
            bar_1_y <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BAR_HEIGHT / 2, 10);
            bar_2_y <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BAR_HEIGHT / 2, 10);
            ball_h_dir <= '0';
            ball_v_dir <= '0';
            bounce_counter <= (others => '0');
            ball_control_counter <= (others => '0');
            score_1 <= (others => '0');
            score_2 <= (others => '0');
        elsif clk'event and clk = '0' then
            state <= state_next;
            ball_x <= ball_x_next;
            ball_y <= ball_y_next;
            bar_1_y <= bar_1_y_next;
            bar_2_y <= bar_2_y_next;
            ball_h_dir <= ball_h_dir_next;
            ball_v_dir <= ball_v_dir_next;
            bounce_counter <= bounce_counter_next;
            ball_control_counter <= ball_control_counter_next;
            score_1 <= score_1_next;
            score_2 <= score_2_next;
        end if;
    end process;

    score_on <= '1' when px_y(9 downto 3) = 1 and
                         (px_x(9 downto 3) = 42 or px_x(9 downto 3) = 37) else
                '0';
    current_score <= score_1 when px_x < 320 else score_2;
    -- numbers start at memory location 128
    -- '1' starts at 136, '2' at 144 and so on
    score_font_addr <= conv_std_logic_vector(128, 9) +
                       (current_score(2 downto 0) & current_score(5 downto 3));

    player_id_on <= '1' when state = game_over and px_y(9 downto 3) = 29 and
                             (px_x(9 downto 3) = 19 or px_x(9 downto 3) = 59) else
                    '0';
    -- player_id will display either 1 or 2
    player_id_font_addr <= "010001000" when px_x < 320 else "010010000";

    message_on <= '1' when state = game_over and
                           -- message on player_1's side
                           ((score_1 > score_2 and
                             px_x(9 downto 3) >= 12 and
                             px_x(9 downto 3) < 26 and
                             px_y(9 downto 3) = 29) or
                           -- message on player_2's side
                            (score_2 > score_1 and
                             px_x(9 downto 3) >= 52 and
                             px_x(9 downto 3) < 66 and
                             px_y(9 downto 3) = 29)) else
                  '0';
    with px_x(9 downto 3) select
        message_font_addr <= "110000000" when "0110100"|"0001100", -- P
                             "101100000" when "0110101"|"0001101", -- L
                             "100001000" when "0110110"|"0001110", -- A
                             "111001000" when "0110111"|"0001111", -- Y
                             "100101000" when "0111000"|"0010000", -- E
                             "110010000" when "0111001"|"0010001", -- R
                             "111100000" when "0111011"|"0010011", -- not visible
                             "110111000" when "0111101"|"0010101", -- W
                             "101111000" when "0111110"|"0010110", -- O
                             "101110000" when "0111111"|"0010111", -- N
                             "000001000" when "1000000"|"0011000", -- !
                             "000000000" when others;

    -- font address mutltiplexer
    font_addr <= px_y(2 downto 0) + score_font_addr when score_on = '1' else
                 px_y(2 downto 0) + player_id_font_addr when player_id_on = '1' else
                 px_y(2 downto 0) + message_font_addr when message_on = '1' else
                 (others => '0');
    font_pixel <= font_data(conv_integer(px_x(2 downto 0)));
    font_rgb <= "000" when font_pixel = '1' else "111";

    direction_control: process(
        ball_control_counter,
        ball_x, ball_y,
        ball_h_dir, ball_v_dir,
        ball_h_dir_next, ball_v_dir_next,
        bar_1_y, bar_2_y
    )
    begin
        ball_h_dir_next <= ball_h_dir;
        ball_v_dir_next <= ball_v_dir;
        ball_bounce <= '0';

        --
        -- BEWARE! Looks like ball_bounce signal is generated twice
        -- due to slower clock! Too lazy to fix now :D
        --

        if ball_control_counter = 0 then
            if ball_x = bar_1_pos + BAR_WIDTH and
               ball_y + BALL_SIZE > bar_1_y and
               ball_y < bar_1_y + BAR_HEIGHT then
                ball_h_dir_next <= '1';
                ball_bounce <= '1';
            elsif ball_x + BALL_SIZE = bar_2_pos and
                  ball_y + BALL_SIZE > bar_2_y and
                  ball_y < bar_2_y + BAR_HEIGHT then
                ball_h_dir_next <= '0';
                ball_bounce <= '1';
            elsif ball_x < bar_1_pos + BAR_WIDTH and
                  ball_x + BALL_SIZE > bar_1_pos then
                if ball_y + BALL_SIZE = bar_1_y then
                    ball_v_dir_next <= '0';
                elsif ball_y = bar_1_y + BAR_HEIGHT then
                    ball_v_dir_next <= '1';
                end if;
            elsif ball_x + BALL_SIZE > bar_2_pos and
                  ball_x < bar_2_pos + BAR_WIDTH then
                if ball_y + BALL_SIZE = bar_2_y then
                    ball_v_dir_next <= '0';
                elsif ball_y = bar_2_y + BAR_HEIGHT then
                    ball_v_dir_next <= '1';
                end if;
            end if;
            
            if ball_y = 0 then
                ball_v_dir_next <= '1';
            elsif ball_y = SCREEN_HEIGHT - BALL_SIZE then
                ball_v_dir_next <= '0';
            end if;
        end if;
    end process;

    bounce_counter_next <= bounce_counter + 1 when ball_bounce = '1' else
                           (others => '0') when ball_miss = '1' else
                           bounce_counter;

    ball_control_value <= 0 when bounce_counter < 4 else
                 1 when bounce_counter < 15 else
                 2 when bounce_counter < 25 else
                 3;

    ball_control_counter_next <= ball_control_counter + 1 when ball_control_counter < COUNTER_VALUES(ball_control_value) else
                        (others => '0');

    ball_control: process(
        ball_control_counter,
        ball_x, ball_y,
        ball_x_next, ball_y_next,
        ball_h_dir, ball_v_dir,
        ball_enable
    )
    begin
        ball_x_next <= ball_x;
        ball_y_next <= ball_y;

        if ball_enable = '1' then
            if ball_control_counter = 0 then
                if ball_h_dir = '1' then
                    ball_x_next <= ball_x + 1;
                else
                    ball_x_next <= ball_x - 1;
                end if;

                if ball_v_dir = '1' then
                    ball_y_next <= ball_y + 1;
                else
                    ball_y_next <= ball_y - 1;
                end if;
            end if;
        else
            ball_x_next <= conv_std_logic_vector(SCREEN_WIDTH / 2 - BALL_SIZE / 2, 10);
            ball_y_next <= conv_std_logic_vector(SCREEN_HEIGHT / 2 - BALL_SIZE / 2, 10);
        end if;
    end process;

    bar_control: process(
        bar_1_y, bar_2_y,
        nes1_up, nes1_down,
        nes2_up, nes2_down
    )
    begin
        bar_1_y_next <= bar_1_y;
        bar_2_y_next <= bar_2_y;
        
        if nes1_up = '1' then
            if bar_1_y > 0 then
                bar_1_y_next <= bar_1_y - 1;
            end if;
        elsif nes1_down = '1' then
            if bar_1_y < SCREEN_HEIGHT - BAR_HEIGHT - 1 then
                bar_1_y_next <= bar_1_y + 1;
            end if;
        end if;

        if nes2_up = '1' then
            if bar_2_y > 0 then
                bar_2_y_next <= bar_2_y - 1;
            end if;
        elsif nes2_down = '1' then
            if bar_2_y < SCREEN_HEIGHT - BAR_HEIGHT - 1 then
                bar_2_y_next <= bar_2_y + 1;
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


    bar_addr <= (px_y(5 downto 0) - bar_1_y(5 downto 0)) when px_x < 320 else
                (px_y(5 downto 0) - bar_2_y(5 downto 0));
    bar_pos <= BAR_1_POS when px_x < 320 else BAR_2_POS;
    bar_pixel <= bar_data(conv_integer(px_x - bar_pos));
    bar_rgb <= "000" when bar_pixel = '1' else "111";

    process(
        ball_on, bar_on,
        ball_rgb, bar_rgb,
        score_on, message_on, font_rgb,
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
            -- scores and messages share rgb stream
            elsif score_on = '1' or message_on = '1' then
                rgb_stream <= font_rgb;
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

    font_unit:
        entity work.codepage_rom(content)
        port map(addr => font_addr, data => font_data);

    ball_bounced <= ball_bounce;
    ball_missed <= ball_miss;

end dispatcher;