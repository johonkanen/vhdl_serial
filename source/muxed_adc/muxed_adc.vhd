LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package muxed_adc_pkg is
    ----------------------------------
    -- TODO move to own package
    type adbus_record is record
        mux_pos_of_measurement : natural range 0 to 7;
        ad_measurement         : std_logic_vector(15 downto 0);
        measurement_is_ready   : boolean;
    end record adbus_record;

    type muxed_adc_in_record is record
        measurement_requested  : boolean;
        requested_next_mux_pos : natural;
    end record;

    type muxed_adc_out_record is record
        adbus : adbus_record;
        sample_and_hold_ready : boolean;
    end record;

    constant init_adbus : adbus_record := (0, (others => '0'), false);

    ----------------------------------
    function measurement_is_ready(adbus : adbus_record) return boolean;
    ----------------------------------
    function get_measurement(adbus : adbus_record) return 
        std_logic_vector;
    -----
    function get_measurement(adbus : adbus_record) return 
        natural;
    ----------------------------------
    function get_mux_pos_of_measurement(adbus : adbus_record) return natural;
    ----------------------------------

end package muxed_adc_pkg ;

----------------------------------
package body muxed_adc_pkg is

    ----------------------------------
    function measurement_is_ready(adbus : adbus_record) return boolean is
    begin
        return adbus.measurement_is_ready;
    end measurement_is_ready;
    ----------------------------------
    function get_measurement(adbus : adbus_record) return std_logic_vector is
    begin
        return adbus.ad_measurement;
    end get_measurement;
    ----------
    function get_measurement(adbus : adbus_record) return natural is
    begin
        return to_integer(unsigned(adbus.ad_measurement));
    end get_measurement;
    ----------------------------------
    function get_mux_pos_of_measurement(adbus : adbus_record) return natural is
    begin
        return adbus.mux_pos_of_measurement;
    end get_mux_pos_of_measurement;
    ----------------------------------


end package body muxed_adc_pkg ;
----------------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.muxed_adc_pkg.all;

entity muxed_adc is
    generic(g_sample_and_hold_delay_in_clocks : natural := 100);
    port(
            clock      : in std_logic
            ; ad_clock : out std_logic 
            ; ad_data  : in std_logic
            ; cs       : out std_logic
            ; mux_io   : out std_logic_vector(2 downto 0)

            ; muxed_adc_in  : in muxed_adc_in_record
            ; muxed_adc_out : out muxed_adc_out_record
        );
end;

architecture rtl of muxed_adc is

    package max11115_pkg is new work.max11115_generic_pkg;
        use max11115_pkg.all;

    signal self : max11115_record := init_max11115;

    signal current_mux_state : natural range 0 to 7 := 0;
    signal converted_mux_state    : natural range 0 to 7 := 0;

    signal sample_and_hold_counter : natural range 0 to g_sample_and_hold_delay_in_clocks := g_sample_and_hold_delay_in_clocks;

    --------------------------
    function to_std_vector(vector_length : positive ; number : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(number, vector_length));
    end to_std_vector;
    --------------------------

begin

    muxed_adc_out.sample_and_hold_ready <= sample_and_hold_counter = (g_sample_and_hold_delay_in_clocks-1);

    process(clock) is
    begin
        if rising_edge(clock) then
            --------------------
            create_max11115(self , ad_data , cs , ad_clock);
            --------------------
            if muxed_adc_in.measurement_requested then
                request_conversion(self);
                sample_and_hold_counter <= 0;
            end if;
            --------------------
            if sample_and_hold_counter < g_sample_and_hold_delay_in_clocks then
                sample_and_hold_counter <= sample_and_hold_counter + 1;
            end if;

            if sample_and_hold_counter = (g_sample_and_hold_delay_in_clocks-1) then
                mux_io              <= to_std_vector(3, muxed_adc_in.requested_next_mux_pos);
                current_mux_state   <= muxed_adc_in.requested_next_mux_pos;
                converted_mux_state <= current_mux_state;
            end if;
            --------------------
            muxed_adc_out.adbus.measurement_is_ready <= false;
            if ad_conversion_is_ready(self) then
                muxed_adc_out.adbus.measurement_is_ready   <= true;
                muxed_adc_out.adbus.ad_measurement         <= get_converted_measurement(self);
                muxed_adc_out.adbus.mux_pos_of_measurement <= converted_mux_state;
            end if;
            --------------------

        end if;
    end process;


end rtl;
----------------------------------
