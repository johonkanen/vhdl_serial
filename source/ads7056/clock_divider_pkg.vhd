library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package clock_divider_pkg is new work.clock_divider_generic_pkg 
    generic map(g_count_max => 3);
