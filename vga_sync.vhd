library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity vga is
    port(
        clk, reset: in std_logic;
        hsync, vsync: out std_logic;
        video_on: out std_logic;
        pixel_x, pixel_y: out std_logic_vector (9 downto 0)
    );
end vga;

architecture sync of vga is
    -- VGA 640x480 sync parameters
    constant HD: integer := 640; -- horizontal display area
    constant HF: integer := 16;  -- h. front porch
    constant HB: integer := 48;  -- h. back porch
    constant HR: integer := 96;  -- h. retrace
    constant VD: integer := 480; -- vertical display area
    constant VF: integer := 11;  -- v. front porch
    constant VB: integer := 31;  -- v. back porch
    constant VR: integer := 2;   -- v. retrace

    -- mod-2 counter
    signal mod2, mod2_next: std_logic;

    -- sync counters
    signal v_count, v_count_next: std_logic_vector(9 downto 0);
    signal h_count, h_count_next: std_logic_vector(9 downto 0);

    -- output buffer
    signal v_sync, h_sync: std_logic;
    signal v_sync_next, h_sync_next: std_logic;

    -- status signal
    signal h_end, v_end, pixel_tick: std_logic;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            mod2 <= '0';
            v_count <= (others => '0');
            h_count <= (others => '0');
            v_sync <= '0';
            h_sync <= '0';
        elsif clk'event and clk = '0' then
            mod2 <= mod2_next;
            v_count <= v_count_next;
            h_count <= h_count_next;
            v_sync <= v_sync_next;
            h_sync <= h_sync_next;
        end if;
    end process;

    -- mod-2 circuit to generate 25 MHz enable tick
    mod2_next <= not mod2;

    -- 25 MHz pixel tick
    pixel_tick <= '1' when mod2 = '1' else '0';

    -- end of counters (799 and 524 pixels)
    h_end <= '1' when h_count = (HD + HF + HB + HR - 1) else '0';
    v_end <= '1' when v_count = (VD + VF + VB + VR - 1) else '0';

    -- mod-800 horizontal sync counter
    process(h_count, h_end, pixel_tick)
    begin
        if pixel_tick = '1' then
            if h_end = '1' then
                h_count_next <= (others => '0');
            else
                h_count_next <= h_count + 1;
            end if;
        else
            h_count_next <= h_count;
        end if;
    end process;

    -- mod-524 vertical sync counter
    process(v_count, h_end, v_end, pixel_tick)
    begin
        if pixel_tick = '1' and h_end = '1' then
            if v_end = '1' then
                v_count_next <= (others => '0');
            else
                v_count_next <= v_count + 1;
            end if;
        else
            v_count_next <= v_count;
        end if;
    end process;

    -- horizontal and vertical sync, buffered to avoid glitch
    h_sync_next <= '1' when (h_count >= (HD + HF)) and
                            (h_count <= (HD + HF + HR - 1)) else
                   '0';
    v_sync_next <= '1' when (v_count >= (VD + VF)) and
                            (v_count <= (VD + VF + VR - 1)) else
                   '0';

    -- video on/off
    video_on <= '1' when (h_count < HD) and (v_count < VD) else '0';

    -- output signal
    hsync <= h_sync;
    vsync <= v_sync;
    pixel_x <= h_count;
    pixel_y <= v_count;
end sync;
