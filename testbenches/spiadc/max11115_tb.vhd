LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package max11115_pkg is

    package clkdiv_pkg is new work.clock_divider_generic_pkg generic map(g_count_max => 3);
    use clkdiv_pkg.all;

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

    procedure create_max11115 (
        signal self : inout max11115_record;
        serial_io   : in std_logic;
        signal cs   : out std_logic;
        signal spi_clock_out : out std_logic);

    procedure request_conversion (
        signal self : inout max11115_record);

end package max11115_pkg;
-------------------------------------------------------

package body max11115_pkg is

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

    procedure request_conversion
    (
        signal self : inout max11115_record
    ) is
    begin
        self.conversion_requested <= true;
        
    end request_conversion;
end package body max11115_pkg;

----------------------------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.max11115_pkg.all;

entity max11115_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of max11115_tb is


    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----



    signal self     : max11115_record := init_max11115;
    signal spiclock : std_logic := '1';
    signal spics    : std_logic := '1';

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_max11115(self,'1', spics, spiclock);

            if simulation_counter = 15 or simulation_counter = 135 then
                request_conversion(self);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
