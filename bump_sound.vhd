library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bump_sound is
    generic(
        ADDR_WIDTH: integer := 2
    );
    port(
        addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data: out std_logic_vector(8 downto 0)
    );
end bump_sound;

architecture content of bump_sound is
    type tune is array(0 to 2 ** ADDR_WIDTH - 1)
        of std_logic_vector(8 downto 0);
    constant BUMP: tune :=
    (
        "100001001",
        "011001011",
        "001001010",
        "000000000"
    );
begin
    data <= BUMP(conv_integer(addr));
end content;

