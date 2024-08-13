LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.clock_divider_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity clock_divider_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of clock_divider_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal self : clock_divider_record := init_clock_divider;

    signal clock_counter    : natural range 0 to 7;
    signal number_of_clocks : natural range 0 to 63;

    signal ad_clock : std_logic := '1';

    signal number_of_rising_edges : natural := 0;

begin

    clock_counter <= self.clock_counter;

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(number_of_rising_edges = 7, "expected 7, got " & integer'image(number_of_rising_edges));
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_clock_divider(self);
            ad_clock <= get_clock_from_divider(self);

            if simulation_counter = 15 then
                request_number_of_clock_pulses(self,7);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------

    check_clocks : process(ad_clock)
        
    begin
        if rising_edge(ad_clock) then
            number_of_rising_edges <= number_of_rising_edges + 1;
        end if; --rising_edge
    end process check_clocks;	
end vunit_simulation;
