package tpu_pkg;
	

////////////////////////// COMPUTE CORE CONFIGURATION /////////////////////////////////
	
	//////// Processing Elements

	// maximum supported matrix width 'M', this determines partial sum bus size
	// i.e for C = A * B
	// 	dim(A) = k, M
	// 	dim(B) = M, l
	// 	dim(C) = k, l
	// This parameter controls the 'M' from above
	localparam int MATRIX_INNER_DIM_MAX = 256;

	// main data bus widths
	parameter int ACTV_WIDTH = 8; // INT8
	parameter int PSUM_WIDTH = (2 * ACTV_WIDTH) + $clog2(MATRIX_INNER_DIM_MAX); // see 'MATRIX_INNER_DIM_MAX'

	//////// Systolic Array
	parameter int ARRAY_NUM_ROWS = 2;
	parameter int ARRAY_NUM_COLS = 2;


endpackage : tpu_pkg