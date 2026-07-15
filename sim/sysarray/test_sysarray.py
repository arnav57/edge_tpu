import os, sys
from pathlib import Path
import cocotb
import numpy as np
import logging
from pprint import pprint


# import common library on disk
common_pkgs_path = Path(__file__).resolve().parent.parent
sys.path.append(str(common_pkgs_path))

from common.sysarray import SystolicArray


############# TESTCASES #############

NUM_ROWS = 20
NUM_COLS = 20

@cocotb.test()
async def sysarray_base_test(dut):
    array = SystolicArray(dut, num_rows=NUM_ROWS, num_cols=NUM_COLS)
    await array.start_clock()
    await array.reset_dut(cycles=10)


@cocotb.test()
async def sysarray_load_weights_test(dut):
    array = SystolicArray(dut, num_rows=NUM_ROWS, num_cols=NUM_COLS)
    await array.start_clock()
    await array.reset_dut(cycles=10)
    weights = await array.load_weights()



