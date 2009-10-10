library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bar_object is
    port(
        addr: in std_logic_vector(20 downto 0);
        data: out std_logic_vector(4 downto 0)
    );
end bar_object;

architecture content of bar_object is
    type rom_type is array(0 to 20) of std_logic_vector(0 to 4);
    constant BAR: rom_type :=
    (
        "10101", -- # # #
        "10011", -- #  ##
        "10101", -- # # #
        "11011", -- ## ##
        "10001", -- #   #
        "11011", -- ## ##
        "10101", -- # # #
        "11001", -- ##  #
        "10101", -- # # #
        "11011", -- ## ##
        "10001", -- #   #
        "11011", -- ## ##
        "10101", -- # # #
        "10011", -- #  ##
        "10101", -- # # #
        "11011", -- ## ##
        "10001", -- #   #
        "11011", -- ## ##
        "10101", -- # # #
        "11001", -- ##  #
        "10101"  -- # # #
    );
begin
    data <= BAR(conv_integer(addr));
end content;

