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
    array = SystolicArray(dut)
    await array.start_clock()
    await array.reset_dut()


@cocotb.test()
async def sysarray_load_weights_test(dut):
    array = SystolicArray(dut)
    await array.start_clock()
    await array.reset_dut()
    weights = await array.load_random_weights()

@cocotb.test()
async def sysarray_clear_weights_test(dut):
    array = SystolicArray(dut)
    await array.start_clock()
    await array.reset_dut()
    weights = await array.load_random_weights(clear_after=True)


