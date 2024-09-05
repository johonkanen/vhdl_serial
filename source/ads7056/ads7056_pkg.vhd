library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package spi_adc_type_pkg is

    type spiadc_record is record
        clock_divider        : clock_divider_record;
        data_capture_counter : clock_divider_record;
        data_capture_delay   : natural range 0 to 7;
        state                : natural range 0 to 7;
        conversion_requested : boolean;
        shift_register       : std_logic_vector(17 downto 0);
        ad_conversion        : std_logic_vector(15 downto 0);
        is_ready             : boolean;
    end record;

end spi_adc_type_pkg;

-----------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.spi_adc_type_pkg.all;

package ads7056_generic_pkg is
    generic(
            idle_state_number : natural := 0;
            g_count_max : natural range 0 to 127 := 3);

    package ads7056_clock_divider_pkg is new work.clock_divider_generic_pkg generic map(g_count_max => g_count_max);
    use ads7056_clock_divider_pkg.all;

    alias ads7056_record is spi_adc_type_pkg.spiadc_record;

    /* type ads7056_states is (wait_for_init, initializing, ready, converting); */
    /* signal state : ads7056_states := wait_for_init; */


    constant init_ads7056 : ads7056_record := (init_clock_divider,init_clock_divider,4, idle_state_number, false, (others => '0'), (others => '0'), false);

-------------------------------------------------------------------
    procedure create_ads7056_driver (
        signal self          : inout ads7056_record;
        serial_io            : in std_logic;
        signal cs            : out std_logic;
        signal spi_clock_out : out std_logic);

-------------------------------------------------------------------
    procedure request_conversion (
        signal self : inout ads7056_record);

-------------------------------------------------------------------
    function ad_conversion_is_ready ( self : ads7056_record)
        return boolean;

-------------------------------------------------------------------
    function get_converted_measurement ( self : ads7056_record)
        return std_logic_vector;
-------------------------------------------------------------------

end package ads7056_generic_pkg;
-------------------------------------------------------------------

package body ads7056_generic_pkg is

    procedure create_adc_state_machine
    (
        signal self : inout ads7056_record
    ) is
    begin
        CASE self.state is 
            WHEN 0 =>
                if self.conversion_requested then
                    request_number_of_clock_pulses(self.clock_divider, 24);
                    self.state <= 1;
                end if;
            WHEN 1  =>
                if clock_divider_is_ready(self.clock_divider) then
                    self.state <= 2;
                end if;
            WHEN 2 =>
                if self.conversion_requested then
                    self.data_capture_delay <= 3;
                    request_number_of_clock_pulses(self.clock_divider, 18);
                    request_number_of_clock_pulses(self.data_capture_counter, 18);
                    self.state <= 3;
                end if;
            WHEN 3 =>
                if clock_divider_is_ready(self.data_capture_counter) then
                    self.state <= 2;
                end if;
            WHEN others =>
        end CASE;
    end create_adc_state_machine;

-------------------------------------------------------------------
    procedure create_ads7056_driver
    (
        signal self          : inout ads7056_record;
        serial_io            : in std_logic;
        signal cs            : out std_logic;
        signal spi_clock_out : out std_logic
    ) is
    begin
        spi_clock_out <= get_clock_from_divider(self.clock_divider);
        create_clock_divider(self.clock_divider);
        create_clock_divider(self.data_capture_counter);

        self.conversion_requested <= false;
        self.is_ready <= false;

        create_adc_state_machine(self);

        if self.data_capture_delay < 4 then
            self.data_capture_delay <= self.data_capture_delay + 1;
        end if;

        if self.conversion_requested then
            cs <= '0';
            self.shift_register <= (others => '0');
        end if;

        if clock_divider_is_ready(self.clock_divider) then
            cs <= '1';
        end if;
        if clock_divider_is_ready(self.data_capture_counter) then
            self.is_ready <= true;
        end if;

        if self.is_ready then
            self.ad_conversion <= '0' & self.shift_register(17 downto 3);
        end if;

        if get_clock_counter(self.data_capture_counter) = 3 then
            self.shift_register <= self.shift_register(self.shift_register'left-1 downto 0) & serial_io;
        end if;

    end create_ads7056_driver;

-------------------------------------------------------------------
    procedure request_conversion
    (
        signal self : inout ads7056_record
    ) is
    begin
        self.conversion_requested <= true;
    end request_conversion;

-------------------------------------------------------------------
    function ad_conversion_is_ready
    (
        self : ads7056_record
    )
    return boolean
    is
    begin

        return clock_divider_is_ready(self.data_capture_counter);
        
    end ad_conversion_is_ready;
-------------------------------------------------------------------
    function get_converted_measurement
    (
        self : ads7056_record
    )
    return std_logic_vector
    is
    begin
        return self.ad_conversion;
        
    end get_converted_measurement;

end package body ads7056_generic_pkg;

-------------------------------------------------------------------
-------------------------------------------------------------------
-- default instantiation, TODO : remove 

package ads7056_pkg is new work.ads7056_generic_pkg;
