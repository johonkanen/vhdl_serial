library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package spi_adc_type_generic_pkg is
    generic(package spi_adc_clk_div_pkg is new work.clock_divider_generic_pkg generic map(<>));
    use spi_adc_clk_div_pkg.all;

    type spiadc_record is record
        clock_divider        : spi_adc_clk_div_pkg.clock_divider_record;
        data_capture_counter : spi_adc_clk_div_pkg.clock_divider_record;
        data_capture_delay   : natural range 0 to 7;
        state                : natural range 0 to 7;
        conversion_requested : boolean;
        shift_register       : std_logic_vector(17 downto 0);
        ad_conversion        : std_logic_vector(15 downto 0);
        is_ready             : boolean;
    end record;

    procedure create_adc_state_machine (
        signal self : inout spiadc_record);

end spi_adc_type_generic_pkg;

package body spi_adc_type_generic_pkg is

    procedure create_adc_state_machine
    (
        signal self : inout spiadc_record
    ) 
    is
        constant wait_for_init : natural := 0;
        constant initializing  : natural := 1;
        constant ready         : natural := 2;
        constant converting    : natural := 3;
    begin
        CASE self.state is 
            WHEN wait_for_init =>
                if self.conversion_requested then
                    request_number_of_clock_pulses(self.clock_divider, 24);
                    self.state <= 1;
                end if;
            WHEN initializing  =>
                if clock_divider_is_ready(self.clock_divider) then
                    self.state <= 2;
                end if;
            WHEN ready =>
                if self.conversion_requested then
                    self.data_capture_delay <= 3;
                    request_number_of_clock_pulses(self.clock_divider, 18);
                    request_number_of_clock_pulses(self.data_capture_counter, 18);
                    self.state <= 3;
                end if;
            WHEN converting =>
                if clock_divider_is_ready(self.data_capture_counter) then
                    self.state <= 2;
                end if;
            WHEN others =>
        end CASE;
    end create_adc_state_machine;

end package body spi_adc_type_generic_pkg;

-----------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package ads7056_generic_pkg is
    generic(
            idle_state_number : natural := 0;
            package ads7056_clock_divider_pkg is new work.clock_divider_generic_pkg generic map(<>);
            package ads7056_type_pkg is new work.spi_adc_type_generic_pkg generic map(<>)
        );
    use ads7056_clock_divider_pkg.all;
    use ads7056_type_pkg.all;

-------------------------------------------------------------------
    alias ads7056_record is ads7056_type_pkg.spiadc_record;
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
package test_ads7056_type_pkg is new work.spi_adc_type_generic_pkg generic map(work.test_clock_divider_pkg);

package ads7056_pkg is new work.ads7056_generic_pkg 
    generic map(
            ads7056_clock_divider_pkg => work.test_clock_divider_pkg,
            ads7056_type_pkg          => work.test_ads7056_type_pkg);
