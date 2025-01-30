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

    use work.muxed_adc_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal clock_counter    : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63;

    signal ad_clock : std_logic;
    signal ad_data : std_logic := '1';
    signal cs : std_logic;
    signal mux_io : std_logic_vector(2 downto 0);

    signal adbus : adbus_record := init_adbus;
    signal measurement_requested : boolean := false;

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

            measurement_requested <= false;
            CASE simulation_counter is
                WHEN others => --do nothing
                    if simulation_counter mod 150 = 0 then 
                        measurement_requested <= true;
                    end if;
            end CASE; --simulation_counter

        end if; -- rising_edge
    end process stimulus;	

    ad_data <= '1';

    u_muxed_adc : entity work.muxed_adc
    port map(
             simulator_clock
             , ad_clock
             , ad_data
             , cs
             , mux_io => mux_io
             , adbus => adbus
             , measurement_requested => measurement_requested
        );
------------------------------------------------------------------------
end vunit_simulation;
