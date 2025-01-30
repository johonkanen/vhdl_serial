LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package muxed_adc_pkg is
    type adbus_record is record
        mux_pos_of_measurement : natural range 0 to 7;
        ad_measurement : std_logic_vector(15 downto 0);
        measurement_is_ready : boolean;
    end record adbus_record;

    constant init_adbus : adbus_record := (0, (others => '0'), false);

end package muxed_adc_pkg ;

----------------------------------

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.muxed_adc_pkg.all;

entity muxed_adc is
    port(
            clock   : in std_logic
             ; mux_io : out std_logic_vector(2 downto 0)
             ; adbus  : out adbus_record
             ; measurement_requested : in  boolean
        );
end;

architecture rtl of muxed_adc is

    use work.ads7056_pkg.all;

begin

end rtl;
----------------------------------


LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;


library vunit_lib;
context vunit_lib.vunit_context;

entity muxed_adc_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of muxed_adc_tb is

    use work.ads7056_pkg.all;
    use work.muxed_adc_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal clock_counter    : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63;

    signal self : ads7056_record := init_ads7056;

    signal ad_clock : std_logic;
    signal ad_data : std_logic := '1';
    signal cs : std_logic;

    signal mux_io         : std_logic_vector(2 downto 0);
    signal mux_state      : natural range 0 to 7 := 0;
    signal next_mux_state : natural range 0 to 7 := 0;


    signal adbus : adbus_record := init_adbus;
    signal measurement_requested : boolean := false;

    --------------------------
    function to_std_vector(vector_ref : std_logic_vector ; number : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(number, vector_ref'length));
    end to_std_vector;
    --------------------------

begin

    mux_io <= to_std_vector(mux_io, mux_state);

    clock_counter    <= self.clock_divider.clock_counter;
    number_of_clocks <= self.clock_divider.number_of_transmitted_clocks;

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

            measurement_requested <= false;
            CASE simulation_counter is
                WHEN others => --do nothing
                    if simulation_counter mod 150 = 0 then 
                        measurement_requested <= true;
                    end if;
            end CASE; --simulation_counter

            --------------------
            create_ads7056_driver(self , ad_data , cs , ad_clock);
            if measurement_requested then
                request_conversion(self);
            end if;
            --------------------

            --------------------
            if ad_conversion_is_ready(self) then
                if mux_state < 7 then
                    mux_state <= mux_state + 1;
                else
                    mux_state <= 0;
                end if;
            end if;
            --------------------

            --------------------
            adbus.measurement_is_ready <= false;
            if ad_conversion_is_ready(self) then
                adbus.measurement_is_ready   <= true;
                adbus.ad_measurement         <= get_converted_measurement(self);
                adbus.mux_pos_of_measurement <= mux_state;
            end if;
            --------------------

        end if; -- rising_edge
    end process stimulus;	

    u_muxed_adc : entity work.muxed_adc
    port map(
            clock => simulator_clock
            , mux_io => open
            , adbus => open
            , measurement_requested => measurement_requested
        );
------------------------------------------------------------------------
end vunit_simulation;
