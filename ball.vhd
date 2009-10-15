library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ball_rom is
    port(
        addr: in std_logic_vector(3 downto 0);
        data: out std_logic_vector(0 to 15)
    );
end ball_rom;

architecture content of ball_rom is
    type rom_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant BALL: rom_type :=
    (
        "0000011111100000",
        "0001110101011000",
        "0010000010101100",
        "0110000000010110",
        "0100000001010110",
        "1000000000010011",
        "1000000000101111",
        "1000000000010101",
        "1000000001010011",
        "1010100001010111",
        "1010101010111011",
        "0101010101001010",
        "0111010111110110",
        "0011101101011100",
        "0001111011111000",
        "0000011111100000"
    );
begin
    data <= BALL(conv_integer(addr));
end content;

