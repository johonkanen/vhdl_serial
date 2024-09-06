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
