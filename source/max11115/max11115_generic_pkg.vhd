LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package max11115_generic_pkg is
    generic(g_count_max : natural range 0 to 127 := 3);

    package max11115_clkdiv_pkg is new work.clock_divider_generic_pkg generic map(g_count_max => g_count_max);
    use max11115_clkdiv_pkg.all;

    type spiadc_states is (idle, converting);

    type max11115_record is record
        clock_divider        : clock_divider_record;
        data_capture_counter : clock_divider_record;
        data_capture_delay   : natural range 0 to 7;
        state                : spiadc_states;
        conversion_requested : boolean;
        shift_register       : std_logic_vector(17 downto 0);
        ad_conversion        : std_logic_vector(15 downto 0);
        is_ready             : boolean;
    end record;

    constant init_max11115 : max11115_record := (init_clock_divider , init_clock_divider , 3 , idle , false , (others => '0') , (others => '0') , false);

    ----------------------------------------------
    procedure create_max11115 (
        signal self : inout max11115_record;
        serial_io   : in std_logic;
        signal cs   : out std_logic;
        signal spi_clock_out : out std_logic);

    ----------------------------------------------
    procedure request_conversion (
        signal self : inout max11115_record);

    function ad_conversion_is_ready ( self : max11115_record)
        return boolean;

    function get_converted_measurement ( self : max11115_record)
        return std_logic_vector;

end package max11115_generic_pkg;
-------------------------------------------------------

package body max11115_generic_pkg is

    ----------------------------------------------
    procedure create_max11115
    (
        signal self : inout max11115_record;
        serial_io   : in std_logic;
        signal cs   : out std_logic;
        signal spi_clock_out : out std_logic
    ) is
    begin
        
        spi_clock_out <= not get_clock_from_divider(self.clock_divider);
        create_clock_divider(self.clock_divider);
        create_clock_divider(self.data_capture_counter);

        self.conversion_requested <= false;
        self.is_ready             <= false;

        CASE self.state is 
            WHEN idle =>
                if self.conversion_requested then
                    self.data_capture_delay <= 3;
                    request_number_of_clock_pulses(self.clock_divider, 16);
                    request_number_of_clock_pulses(self.data_capture_counter, 16);
                    self.state <= converting;
                end if;
            WHEN converting =>
                if clock_divider_is_ready(self.data_capture_counter) then
                    self.state <= idle;
                end if;
        end CASE;

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

        if get_clock_counter(self.data_capture_counter) = 0 and self.state = converting then
            self.shift_register <= self.shift_register(self.shift_register'left-1 downto 0) & serial_io;
        end if;

    end create_max11115;

    ----------------------------------------------
    procedure request_conversion
    (
        signal self : inout max11115_record
    ) is
    begin
        self.conversion_requested <= true;
        
    end request_conversion;
    
    ----------------------------------------------
    function ad_conversion_is_ready
    (
        self : max11115_record
    )
    return boolean
    is
    begin
        return clock_divider_is_ready(self.data_capture_counter);
    end ad_conversion_is_ready;

    ----------------------------------------------
    function get_converted_measurement
    (
        self : max11115_record
    )
    return std_logic_vector
    is
    begin
        return self.ad_conversion;
        
    end get_converted_measurement;
    ----------------------------------------------
end package body max11115_generic_pkg;
