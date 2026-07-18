import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles

import numpy as np
import numpy.typing as npt

import logging

class ProcessingElement():

	def __init__(self, dut, row_idx:int, col_idx:int):
		self.position 		= (row_idx, col_idx)
		self._dut     		= dut
		self._stored_weight = 0

		# logger
		self.logger = logging.getLogger(f"PE{self.position}")
		self.logger.setLevel(logging.DEBUG)

		cocotb.start_soon( self._monitor_latch() )

	##### PRINTING

	def __repr__(self):
		return f"PE{self.position} :: w={self.weight}"

	##### PIN ACCESS

	@property
	def clock(self):
		return self._dut.clk_i

	@property
	def reset(self):
		return self._dut.rstn_i

	@property
	def latch(self):
		return self._dut.latch_i

	@property
	def clear(self):
		return self._dut.clear_i

	@property
	def activation_in(self):
		return self._dut.A_i

	@property
	def activation_out(self):
		return self._dut.A_o

	@property
	def sum_in(self):
		return self._dut.P_i

	@property
	def sum_out(self):
		return self._dut.P_o

	@property
	def weight(self):
		return self._stored_weight

	#### HELPERS ####
	def validate(self, weight_value:int=None):
		actual = self._dut.B_r.value.to_signed()
		desired = self.weight if weight_value is None else weight_value
		cond = (actual == desired)
		if not (cond):
			self.logger.error(f"weights do not match! :: {actual} vs {desired}")
		assert cond

	#### MONITORS ####

	async def _monitor_latch(self):
		while True:
			await RisingEdge(self.clock)

			if self.clear.value == 1:
				self._stored_weight = 0
			elif self.latch.value == 1:
				self._stored_weight = self.activation_in.value.to_signed()


