LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity spi_communication_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of spi_communication_tb is

    package spi_transmitter_pkg is new work.spi_transmitter_generic_pkg generic map(g_clock_divider => 5);
    use spi_transmitter_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal spi_data_out : std_logic;

    signal self : spi_transmitter_record := init_spi_transmitter;

    signal capture_buffer : std_logic_vector(15 downto 0);
    signal packet_counter : natural := 0;

    function int_to_bytearray
    (
        unsigned_input : integer_vector
    )
    return bytearray
    is
        variable retval : bytearray(unsigned_input'range);
    begin
        for i in unsigned_input'range loop
            retval(i) := std_logic_vector(to_unsigned(unsigned_input(i),8));
        end loop;

        return retval;
        
    end int_to_bytearray;

    signal test_frame : bytearray(0 to 1) := (( 0 => x"ac", 1 => x"dc"));

    /* constant wtf : std_logic_vector := x"ac"; */
    /* signal dingdong : wtf'subtype := wtf; */

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(capture_buffer = x"acdc", "did not get what expected");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_spi_transmitter(self, spi_data_out);

            CASE simulation_counter is
                WHEN 50 => 
                    transmit_number_of_bytes(self,1);
                    load_transmit_register(self, test_frame(0));
                WHEN others => --do nothing
            end CASE;

            if ready_to_receive_packet(self) and packet_counter < test_frame'high  then
                transmit_number_of_bytes(self,1);
                load_transmit_register(self, test_frame(1));
                /* load_transmit_register(self, test_frame(packet_counter+1)); */
                packet_counter <= packet_counter + 1;
            end if;

        end if; -- rising_edge
    end process stimulus;	

--------------------------------------------------------
    catch_spi : process(self.spi_clock)
    begin
        if rising_edge(self.spi_clock) then
            capture_buffer <= capture_buffer(capture_buffer'left-1 downto 0) & self.spi_data_from_master;
        end if; --rising_edge
    end process catch_spi;	
--------------------------------------------------------
end vunit_simulation;
