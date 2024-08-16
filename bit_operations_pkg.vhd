library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package bit_operations_pkg is
-----------------------------------------------
    procedure left_shift (
        signal shift_register : inout std_logic_vector; input : in std_logic);
-----------------------------------------------
    function get_first_bit ( input : std_logic_vector )
        return std_logic;
-----------------------------------------------

end package bit_operations_pkg;

package body bit_operations_pkg is

-----------------------------------------------
    procedure left_shift
    (
        signal shift_register : inout std_logic_vector; input : in std_logic
    ) is
    begin

        shift_register <= shift_register(shift_register'left-1 downto 0 ) & input;
        
    end left_shift;
-----------------------------------------------

    function get_first_bit
    (
        input : std_logic_vector 
    )
    return std_logic 
    is
    begin
        return input(input'left);
    end get_first_bit;
-----------------------------------------------

end package body bit_operations_pkg;
