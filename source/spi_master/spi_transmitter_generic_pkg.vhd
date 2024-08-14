library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package spi_transmitter_generic_pkg is
    generic(g_clock_divider : natural);

    package clock_divider_pkg is new work.clock_divider_generic_pkg 
        generic map(g_count_max => g_clock_divider);
    use clock_divider_pkg.all;

    subtype byte is std_logic_vector(7 downto 0);
    type bytearray is array (natural range <>) of byte;

    type spi_transmitter_record is record
        clock_divider           : clock_divider_record;
        number_of_bytes_to_send : natural;
        spi_clock               : std_logic;
        spi_cs_in               : std_logic;
        spi_data_from_master    : std_logic;
        output_shift_register   : std_logic_vector(7 downto 0);
    end record;

    constant init_spi_transmitter : spi_transmitter_record := (init_clock_divider, 0, '0', '1', '1', (others => '0'));

-------------------------------------------------
    procedure create_spi_transmitter (
        signal self : inout spi_transmitter_record;
        spi_data_slave_to_master : in std_logic);
-------------------------------------------------
    procedure transmit_number_of_bytes (
        signal self : inout spi_transmitter_record;
        number_of_bytes_to_send : natural);
-------------------------------------------------
    procedure load_transmit_register (
        signal self : inout spi_transmitter_record;
        word_to_be_sent : std_logic_vector);
-------------------------------------------------
    function ready_to_receive_packet ( self : spi_transmitter_record)
        return boolean;
-------------------------------------------------
    function spi_is_ready ( self : spi_transmitter_record)
        return boolean;
-------------------------------------------------
    procedure transmit_byte (
        signal self : inout spi_transmitter_record;
        byte_to_send : byte);

end package spi_transmitter_generic_pkg;

package body spi_transmitter_generic_pkg is

-------------------------------------------------
    procedure create_spi_transmitter
    (
        signal self : inout spi_transmitter_record;
        spi_data_slave_to_master : in std_logic
    ) is
    begin
        create_clock_divider(self.clock_divider);
        if clock_divider_is_ready(self.clock_divider) then
            self.spi_cs_in <= '1';
        end if;

        self.spi_clock <= get_clock_from_divider(self.clock_divider);
        if get_clock_counter(self.clock_divider) = 0 then
            self.spi_data_from_master <= self.output_shift_register(self.output_shift_register'left);
            self.output_shift_register <= self.output_shift_register(self.output_shift_register'left-1 downto 0) & '0';
        end if;
        
    end create_spi_transmitter;

-------------------------------------------------
    procedure transmit_number_of_bytes
    (
        signal self : inout spi_transmitter_record;
        number_of_bytes_to_send : natural
    ) is
    begin
        request_number_of_clock_pulses(self.clock_divider, number_of_bytes_to_send*8);
        self.number_of_bytes_to_send <= number_of_bytes_to_send;
        self.spi_cs_in <= '0';
        
    end transmit_number_of_bytes;

-------------------------------------------------
    procedure load_transmit_register
    (
        signal self : inout spi_transmitter_record;
        word_to_be_sent : std_logic_vector
    ) is
    begin
        self.output_shift_register <= word_to_be_sent;
    end load_transmit_register;

-------------------------------------------------
    function ready_to_receive_packet
    (
        self : spi_transmitter_record
    )
    return boolean
    is
    begin
        return self.clock_divider.clock_counter = count_max and
                self.clock_divider.number_of_transmitted_clocks = self.clock_divider.requested_number_of_clock_pulses-1;
    end ready_to_receive_packet;
-------------------------------------------------
    function spi_is_ready
    (
        self : spi_transmitter_record
    )
    return boolean
    is
    begin

        return clock_divider_is_ready(self.clock_divider);
        
    end spi_is_ready;
-------------------------------------------------
    function byte_is_ready
    (
        self : spi_transmitter_record
    )
    return boolean
    is
    begin
        
        return false;
        
    end byte_is_ready;
-------------------------------------------------
    procedure transmit_byte
    (
        signal self : inout spi_transmitter_record;
        byte_to_send : byte
    ) is
    begin
        request_number_of_clock_pulses(self.clock_divider, 8);
        self.spi_cs_in <= '0';
        self.output_shift_register <= byte_to_send;
        
    end transmit_byte;
-------------------------------------------------
end package body spi_transmitter_generic_pkg;
