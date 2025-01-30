

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.ads7056_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity muxed_adc_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of muxed_adc_tb is

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


    signal mux_io : std_logic_vector(2 downto 0);
    signal mux_state : natural range 0 to 7 := 0;

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

            create_ads7056_driver(self , ad_data , cs , ad_clock);

            CASE simulation_counter is
                WHEN 15  => request_conversion(self);
                WHEN 200 => request_conversion(self);
                WHEN 330 => request_conversion(self);
                            ad_data <= '0';
                WHEN others => --do nothing
            end CASE; --simulation_counter

            if sample_and_hold_ready(self) then
                if mux_state < 7 then
                    mux_state <= mux_state + 1;
                else
                    mux_state <= 0;
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
