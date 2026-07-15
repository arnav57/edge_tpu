import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles

import numpy as np
import numpy.typing as npt

import logging

class SystolicArray():

	#### CONSTRUCTOR ####

	def __init__(self, dut, num_rows=20, num_cols=20):
		self._dut  = dut
		self.nrows = num_rows
		self.ncols = num_cols

		# logger
		self.logger = logging.getLogger("SYSTOLIC-ARRAY")
		self.logger.setLevel(logging.DEBUG)

		# internal state (desired)
		self.weights = None

	#### DIRECT PIN ACCESS ####

	@property
	def clock(self):
		return self._dut.clk_i

	@property
	def reset(self):
		return self._dut.rstn_i

	@property
	def loading(self):
		return self._dut.loading_i

	@property
	def latch(self):
		return self._dut.latch_i

	@property
	def clear(self):
		return self._dut.clear_i

	#### INDEXED PIN ACCESS ####

	def activation_in(self, row):
		return self._dut.A_i[row]

	def activation_valid_in(self, row):
		return self._dut.Av_i[row]

	def activation_out(self, row):
		return self._dut.A_o[row]

	def activation_valid_out(self, row):
		return self._dut.Av_o[row]

	def sum_in(self, col):
		return self._dut.P_i[col]

	def sum_out(self, col):
		return self._dut.P_o[col]

	def sum_valid_out(self, col):
		return self._dut.Pv_o[col]

	#### HIDDEN HELPERS ####
	
	def _to_weights(self, in_matrix:npt.NDArray[np.int8]):
		# format as a list of cols
		cols_list = [in_matrix[:, i].tolist().reverse() for i in range(in_matrix.shape[1])]
		return cols_list


	#### PUBLIC HELPERS ####

	def get_pe(self, row_idx, col_idx):
		return self._dut.I_systolic_core.I_systolic.pe_row[row_idx].pe_col[col_idx].I_ws_pe

	async def start_clock(self):
		clock = Clock(self.clock, 6.75, unit="ns")
		cocotb.start_soon(clock.start())

	async def reset_dut(self, cycles=10):
		self.reset.value   = 0
		self.latch.value   = 0
		self.clear.value   = 0
		self.loading.value = 0

		for row in range(self.nrows):
			self.activation_in(row).value       = 0
			self.activation_valid_in(row).value = 0

		for col in range(self.ncols):
			self.sum_in(col).value = 0

		await ClockCycles(self.clock, cycles-2)

		self.reset.value = 1

		await ClockCycles(self.clock, 2)

	async def load_weights(self):
		weights = np.random.randint(-128, 128, size=(self.nrows, self.ncols), dtype=np.int8)
		activation_inputs = self._to_weights(weights)

		self.logger.info(f"Loading Weights:\n{weights}\n")
		self.logger.info(f"Toggled Loading Mode to 1")
		self.loading.value = 1

		await RisingEdge(self.clock)

		# load the matrix in col by col
		for col in range(self.ncols):
			for row in range(self.nrows):
				self.activation_in(row).value = activation_inputs[col][row]
			await RisingEdge(self.clock)
			self.logger.debug(f"Loaded Activation Inputs:\n{activation_inputs[col]}\n")

		# reset the inputs to 0 after
		for row in range(self.nrows):
			self.activation_in(row).value       = 0
			self.activation_valid_in(row).value = 0

		# wait for the signals to propagate
		await ClockCycles(self.clock, self.ncols * 2 - self.ncols)

		self.logger.info(f"Toggled Loading Mode to 0")
		self.loading.value = 0
		self.logger.info(f"Toggled Latch to 1")
		self.latch.value   = 1

		await ClockCycles(self.clock, 5)

		self.latch.value   = 0
		self.logger.info(f"Toggled Latch to 0")

		## ASSERTIONS
		for row in range(self.nrows):
			for col in range(self.ncols):
				desired_value = weights[row][col]
				actual_value  = self.get_pe(row, col).B_r.value.to_signed()
				self.logger.info(f"[{row}, {col}] Desired: {desired_value}, Actual: {actual_value}")

		return weights




	
