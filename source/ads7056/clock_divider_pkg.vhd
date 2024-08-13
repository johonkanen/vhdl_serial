library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package clock_divider_pkg is

    type clock_divider_record is record
        is_ready : boolean;
        clock_counter    : natural range 0 to 7;
        number_of_clocks : natural range 0 to 63;
        requested_number_of_clock_pulses : natural range 0 to 1023;
    end record;

    constant init_clock_divider : clock_divider_record := (false,0,8,7);

----------------------------------------------------
    procedure create_clock_divider (
        signal self : inout clock_divider_record);
----------------------------------------------------
    procedure request_number_of_clock_pulses (
        signal self : inout clock_divider_record;
        number_of_clock_pulses : natural);
----------------------------------------------------
    function get_clock_from_divider ( self : clock_divider_record)
        return std_logic ;
----------------------------------------------------
    function clock_divider_is_ready ( self : clock_divider_record)
        return boolean;
----------------------------------------------------
    function get_clock_counter ( self : clock_divider_record)
        return natural;
----------------------------------------------------

end package clock_divider_pkg;

package body clock_divider_pkg is

----------------------------------------------------
    function get_clock_from_divider
    (
        self : clock_divider_record
    )
    return std_logic 
    is
        variable retval : std_logic := '0';
    begin

        retval := '0';
        if self.number_of_clocks <= self.requested_number_of_clock_pulses then
            if self.clock_counter < 2 then
                retval := '1';
            end if;
        end if;

        return retval;
        
    end get_clock_from_divider;

----------------------------------------------------
    procedure create_clock_divider
    (
        signal self : inout clock_divider_record
    ) is
    begin

        if self.number_of_clocks <= self.requested_number_of_clock_pulses then
            if self.clock_counter < 3 then
                self.clock_counter <= self.clock_counter + 1;
            else
                self.number_of_clocks <= self.number_of_clocks + 1;
                self.clock_counter <= 0;
            end if;
        end if;
        self.is_ready <= (self.clock_counter = 2) and (self.number_of_clocks = self.requested_number_of_clock_pulses);
        
    end create_clock_divider;

----------------------------------------------------
    procedure request_number_of_clock_pulses
    (
        signal self : inout clock_divider_record;
        number_of_clock_pulses : natural
    ) is
    begin
        self.requested_number_of_clock_pulses <= number_of_clock_pulses-1;
        self.number_of_clocks <= 0;
    end request_number_of_clock_pulses;
----------------------------------------------------
    function clock_divider_is_ready
    (
        self : clock_divider_record
    )
    return boolean
    is
    begin
        
        return self.is_ready;

    end clock_divider_is_ready;
----------------------------------------------------
    function get_clock_counter
    (
        self : clock_divider_record
    )
    return natural
    is
    begin
        return self.clock_counter;
    end get_clock_counter;
----------------------------------------------------

end package body clock_divider_pkg;
