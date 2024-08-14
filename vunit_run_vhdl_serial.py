#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv(compile_builtins=True, vhdl_standard="2008")

lib = VU.add_library("lib")
lib.add_source_files(ROOT / "source/clock_divider/clock_divider_generic_pkg.vhd")
lib.add_source_files(ROOT / "source/spi_master/spi_master_generic_pkg.vhd")
lib.add_source_files(ROOT / "source/ads7056/clock_divider_pkg.vhd")
lib.add_source_files(ROOT / "source/ads7056/ads7056_pkg.vhd")

lib.add_source_files(ROOT / "testbenches/iic/iic_dac_tb.vhd")
lib.add_source_files(ROOT / "testbenches/spiadc/clock_divider_tb.vhd")
lib.add_source_files(ROOT / "testbenches/spiadc/ads7056_tb.vhd")

lib.add_source_files(ROOT / "testbenches/spi_communication/spi_master_tb.vhd")

VU.set_sim_option("nvc.sim_flags", ["-w"])
VU.main()
