library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ball_rom is
    port(
        addr: in std_logic_vector(2 downto 0);
        data: out std_logic_vector(7 downto 0)
    );
end ball_rom;

architecture content of ball_rom is
    type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant BALL: rom_type :=
    (
        "00111100", --   ####
        "01000010", --  #    #
        "10000101", -- #    # #
        "10000011", -- #     ##
        "10000101", -- #    # #
        "10101011", -- # # # ##
        "01010110", --  # # ##
        "00111100"  --   ####
    );
begin
    data <= BALL(conv_integer(addr));
end content;

