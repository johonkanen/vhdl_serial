library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package ads7056_generic_pkg is
    generic(
            idle_state_number : natural := 0;
            package ads7056_clock_divider_pkg is new work.clock_divider_generic_pkg         generic map (<>);
            package ads7056_type_pkg          is new work.spi_adc_type_generic_pkg          generic map (<>);
            package ads7056_state_machine_pkg is new work.spi_adc_state_machine_generic_pkg generic map (<>)
        );
    use ads7056_clock_divider_pkg.all;
    use ads7056_type_pkg.all;
    use ads7056_state_machine_pkg.all;

-------------------------------------------------------------------
    alias ads7056_record is ads7056_type_pkg.spiadc_record;

    constant init_ads7056 : ads7056_record := init_spiadc;

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

package test_clock_divider_pkg is new work.clock_divider_generic_pkg generic map(g_count_max => 3);
package test_ads7056_type_pkg  is new work.spi_adc_type_generic_pkg generic map(work.test_clock_divider_pkg);
package spi_adc_state_machine_pkg is new work.spi_adc_state_machine_generic_pkg generic map(
    work.test_clock_divider_pkg,
    work.test_ads7056_type_pkg );

package ads7056_pkg is new work.ads7056_generic_pkg 
    generic map(
            ads7056_clock_divider_pkg => work.test_clock_divider_pkg ,
            ads7056_type_pkg          => work.test_ads7056_type_pkg  ,
            ads7056_state_machine_pkg => work.spi_adc_state_machine_pkg
        );
-------------------------------------------------------------------
