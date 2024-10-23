
`timescale 1 ns / 100 ps

module ee457_lab7_P3 (CLK,RSTB);
input CLK,RSTB;


// signals -- listed stagewise
// Signals such as PC_OUT were wires in ee457_lab7_P3.v.
// Here they are changed to "reg".

// IF stage signals
reg [7:0] PC_OUT;
reg [31:0] memory [0:63]; // instruction memory 64x32
wire [31:0] IF_INSTR_combinational;
reg [31:0] IF_INSTR;

// ID stage signals
// reg ID_XMEX1, ID_XMEX2; // Outputs of the comparison station in ID-stage. 
// The above line is commented out and the above two signals are declared 
// with in the named procedural block, "Main_Clocked_Block" later to show how to curtail visibility of local signals.

// Notice that we declared below two signals: a wire signal called STALL_combinational and a reg signal called STALL.
// We explained later why we have declared these two signals. 
reg STALL; // STALL_B, the opposite of STALL, is neither explicitly declared, nor produced explicitly. 
wire STALL_combinational; // Declared as wire, as we intend to produce it using a continuous assign statement (outside the procedural block). 
reg ID_MOV,ID_SUB3,ID_ADD4,ID_ADD1; // We did not declare ID_MOV_OUT,ID_SUB3_OUT,ID_ADD4_OUT,ID_ADD1_OUT as it is considered as "too much detailing".
reg [3:0] ID_XA,ID_RA; // 4-bit source register and write register IDs
reg [15:0] reg_file [0:15] ; // register file 16x16
reg [15:0] ID_XD; // Data at ID_XA
reg [31:0] ID_INSTR;

// EX1 stage signals
reg EX1_MOV,EX1_SUB3,EX1_ADD4,EX1_ADD1,EX1_XMEX1,EX1_XMEX2; 
wire PRIORITY_combinational; // This is used in a question in your lab.
reg PRIORITY,FORW1,SKIP1; // intermediate signals in EX1
reg [3:0] EX1_RA; // 4-bit write register ID
reg [15:0] EX1_XD,EX1_PRIO_XD,EX1_ADDER_IN,EX1_ADDER_OUT;
reg [31:0] EX1_INSTR;

// EX2 stage signals
reg EX2_MOV,EX2_SUB3,EX2_ADD4,EX2_ADD1,EX2_XMEX1; // These are registered signals (and or not intermediate signals).
reg FORW2,SKIP2; // intermediate signals in EX2
reg [3:0] EX2_RA; // 4-bit write register ID
reg [15:0] EX2_XD,EX2_ADDER_IN,EX2_ADDER_OUT,EX2_XD_OUT;
reg [31:0] EX2_INSTR;

// WB stage signals
reg WB_WRITE;
reg [3:0] WB_RA; // 4-bit write register ID
reg [15:0] WB_RD;
reg [31:0] WB_INSTR;

// additional WB stage signals we added
reg WB_SKIP2;
reg [15:0] WB_EX2_ADDER_IN;
reg [15:0] WB_EX2_ADDER_OUT;

assign IF_INSTR_combinational = memory[PC_OUT[5:0]]; // instruction is read from the instruction memory;
// The IF_INSTR_combinational is produced because Modelsim displays the IF_INSTR produced 
// by the blocking assignment in the clocked-always block 1-clock late in the waveform.

// usage of blocking and non-blocking assignments
// It is important to note where to use blocking assignments and where to use non-blocking
// assignments in coding in RTL style.
// Simple Golden Rule is that all registers should be updated/assigned using non-blocking
// assignments. However intermediate signals (note the word "intermediate") in the upstream 
// combinational logic (note the word "upstream") shall be assigned using blocking assignment
// because (i) you do not want to infer a register for these intermediate signals and
// (ii) you want these intermediate signals (or variables) to be updated immediately without
// any delta-T delay as you produced these with the intent of immediately consuming them.
// The STALL signal is one such signal here. We could avoid producing FORW1, FORW2, SKIP1 and SKIP2,
// explicitly and write long RHS (right-hand side) expressions. But we produced them for clarity 
// and they are produced using blocking assignments.
// The 16-bit data in EX2 stage goes through several intermediate steps:
// 		(i) 	Forwarding mux, X2_Mux
//		(ii)	Adder ADD4
//		(iii)	Skip mux, R2_Mux
// Please note that all the intermediate values of the 16-bit data are assigned using blocking assignments.

// Also notice that several signals in the declarative area starting from PC_OUT are changed from the 
// previous "wire" type (in structural coding in earlier part) to "reg" type now. 
// Previously they were outputs of register-components instantiated and they were driven continuously  
// by the instantiated components. Hence they were wires. 
// Now they are generated in an "always procedural block". Hence they are declared as "reg".

assign STALL_combinational = 	(ID_XA == EX1_RA) // if the ID stage instruction's source register matches with the EX1 stage instruction's destination register
								& // and further
								(ID_SUB3 | ID_ADD1) // if the instruction in ID is a kind of instruction who will insist on receiving help at the beginning of the clock in EX1 itself when he reaches EX1
								& // and further
								(EX1_ADD4 | EX1_ADD1) // if the instruction in EX1 is a kind of instruction who will can't help at the beginning of the clock when he is in EX2 as he is still producing his result
								; // then we need to stall the dependent instruction in ID stage.
								

assign PRIORITY_combinational = EX1_XMEX1 & (EX2_SUB3 | EX2_MOV); // This is used in a question in your lab.


always @(posedge CLK, negedge RSTB)

  begin : Main_Clocked_Block 	// Name the sequential block as in this example. Any name (an unique identifier) may be chosen.
								// Once you name a block as shown above, you can declare variables visible to this block only.
								// This is inline with the "variables declaration with in a process in VHDL". Those variables
								// are visible only inside that process.
 reg ID_XMEX1, ID_XMEX2; 
  
	if (RSTB == 1'b0)
	
	  begin
	  
		// IF stage
		PC_OUT <= 8'h00;
		
		// ID Stage
		// Notice: ID_XD is not a physical register. So do not initalize it (no need to write "ID_XD <= 16'hXXXX;")
		//          and later do not assign to it using a non-blocking assignment.	
		// 			Similarly ID_XMEX1, ID_XMEX2, and STALL are not physical registers.	So no initialization for these also.	
		ID_XA <= 4'hX; 
		ID_RA <= 4'hX;
		ID_INSTR <= 32'h00000000; // we could put 32'hXXXXXXXX but, we want to report a NOP in TimeSpace.txt
		ID_MOV  <= 1'b0;
		ID_SUB3 <= 1'b0; 
		ID_ADD4 <= 1'b0; 
		ID_ADD1 <= 1'b0; 
		// please notice that the control signals (ID_MOV, etc.) are inactivated to make sure
		// that a BUBBLE occupies the stage during reset. When control signals
		// are turned to zero, data can be don't care. See "EX1_XD <= 16'hXXXX;" below.
		
		// EX1 Stage
		EX1_XD <= 16'hXXXX;
		EX1_RA <= 4'hX;
		EX1_INSTR <= 32'h00000000; // we could put 32'hXXXXXXXX but, we want to report a NOP in TimeSpace.txt
		EX1_MOV  <= 1'b0;
		EX1_SUB3 <= 1'b0; 
		EX1_ADD4 <= 1'b0; 
		EX1_ADD1 <= 1'b0; 
		EX1_XMEX1 <= 1'bX;
		EX1_XMEX2 <= 1'bX;
		
		// EX2 Stage
		EX2_XD <= 16'hXXXX;
		EX2_RA <= 4'hX;
		EX2_INSTR <= 32'h00000000; // we could put 32'hXXXXXXXX but, we want to report a NOP in TimeSpace.txt
		EX2_MOV  <= 1'b0;
		EX2_SUB3 <= 1'b0; 
		EX2_ADD4 <= 1'b0; 
		EX2_ADD1 <= 1'b0; 
		EX2_XMEX1 <= 1'bX;

		// WB Stage
		// WB_RD <= 16'hXXXX; commenting out
		WB_INSTR <= 32'h00000000; // we could put 32'hXXXXXXXX but, we want to report a NOP in TimeSpace.txt
		WB_RA <= 4'hX;
		WB_WRITE <= 1'b0; // to see that a BUBBLE occupies the WB stage initially

	  end	
	  
	else // else if posedge CLK
	
	  begin
		
		ID_XMEX1 = (ID_XA == EX1_RA);
		ID_XMEX2 = (ID_XA == EX2_RA); // This line can be shifted down (a little above the line producing EX1_XMEX2)
		STALL	 = 	(ID_XMEX1) // if the ID stage instruction's source register matches with the EX1 stage instruction's destination register
					& // and further
					(ID_SUB3 | ID_ADD1) // if the instruction in ID is a kind of instruction who will insist on receiving help at the beginning of the clock in EX1 itself when he reaches EX1
					& // and further
					(EX1_ADD4 | EX1_ADD1) // if the instruction in EX1 is a kind of instruction who will can't help at the beginning of the clock when he is in EX2 as he is still producing his result
					; // then we need to stall the dependent instruction in ID stage.
					// notice that we used the blocking assignment operator "=", and not the non-blocking assignment operator "<="
				
		if (WB_SKIP2)
		
			WB_RD = WB_EX2_ADDER_IN;
		else			
			WB_RD = WB_EX2_ADDER_OUT;		
			
			
	
		
		// EX2 stage logic and EX2_WB stage register
			// EX2 stage logic
			FORW2 = EX2_XMEX1 & (EX2_ADD4 | EX2_MOV) & WB_WRITE;
			if (FORW2)
				EX2_ADDER_IN = WB_RD;
			else
				EX2_ADDER_IN = EX2_XD;
			EX2_ADDER_OUT = EX2_ADDER_IN + (+4); 
			SKIP2 = ~(EX2_ADD1 | EX2_ADD4);
			
			// EX2_WB stage register
			WB_SKIP2 <= SKIP2;
			WB_EX2_ADDER_IN <= EX2_ADDER_IN;
			WB_EX2_ADDER_OUT <= EX2_ADDER_OUT;
			
			// WB_RD <= EX2_XD_OUT;
			WB_RA <= EX2_RA;
			WB_WRITE <= EX2_MOV | EX2_SUB3 | EX2_ADD4 | EX2_ADD1;	
			WB_INSTR <= EX2_INSTR; // carry the instruction for reverse assembling and displaying in Time-Space diagram

		// EX1 stage logic and EX1_EX2 stage register
			// EX1 stage logic
			PRIORITY = EX1_XMEX1 & (EX2_SUB3 | EX2_MOV); // Note the blocking assignment operator "="
			FORW1 =  ((EX1_XMEX1 & (EX2_SUB3 | EX2_MOV)) | (EX1_XMEX2 & WB_WRITE) ); // Note the blocking assignment operator "="
			
			EX1_PRIO_XD = PRIORITY ? EX2_ADDER_IN : WB_RD;  // to support MOV instruction, it is EX2_ADDER_IN (and not EX2_XD)
			if (FORW1 == 1)
			
				EX1_ADDER_IN = EX1_PRIO_XD; // notice the blocking assignment
			else
				EX1_ADDER_IN = EX1_XD; // notice the blocking assignment
			EX1_ADDER_OUT = EX1_ADDER_IN + (-3); // Subtract 3 // notice the blocking assignment
			
			SKIP1 = (~(EX1_SUB3 | EX1_ADD1)); // notice the blocking assignment
			if (SKIP1 == 1)
				EX2_XD <= EX1_ADDER_IN; // notice the non-blocking assignment
			else
				EX2_XD <= EX1_ADDER_OUT; // notice the non-blocking assignment
				
			EX2_MOV <=  EX1_MOV;
			EX2_SUB3 <= EX1_SUB3; 
			EX2_ADD4 <= EX1_ADD4;
			EX2_ADD1 <= EX1_ADD1;
			
			EX2_RA   <= EX1_RA;
			EX2_XMEX1 <= EX1_XMEX1;
			
			EX2_INSTR <= EX1_INSTR; // carry the instruction for reverse assembling and displaying in Time-Space diagram

			
		// WB stage logic 
			// There isn't any logic here.
			// Not even a mux! 
			// In the 5-stage MIPS CPU, we have a mux controlled by Mem_to_Reg.
			
			ID_XD = (WB_WRITE && (ID_XA == WB_RA)) ? WB_RD : reg_file[ID_XA];
			
			
			EX1_XD <= ID_XD;
			EX1_RA <= ID_RA;
			
			EX1_MOV <=  (~STALL) & ID_MOV;
			EX1_SUB3 <= (~STALL) & ID_SUB3; 
			EX1_ADD4 <= (~STALL) & ID_ADD4;
			EX1_ADD1 <= (~STALL) & ID_ADD1;
			EX1_XMEX1 <= ID_XMEX1;
			EX1_XMEX2 <= ID_XMEX2;
			
			
			
			if (~STALL) 
				begin

				// PC
			
					PC_OUT <= PC_OUT + 1;

				// IF stage logic and IF_ID stage register
					// IF stage logic
					IF_INSTR = memory[PC_OUT[5:0]]; // instruction is read from the instruction memory using blocking assignment
					// IF_ID stage register
					ID_XA <= IF_INSTR[3:0]; 
					ID_RA <= IF_INSTR[7:4];
					ID_MOV  <= IF_INSTR[31];
					ID_SUB3 <= IF_INSTR[30]; 
					ID_ADD4 <= IF_INSTR[29]; 
					ID_ADD1 <= IF_INSTR[28]; 
					ID_INSTR <= IF_INSTR; // carry the instruction for reverse assembling and displaying in Time-Space diagram
				
				end

		
			if (STALL)
				EX1_INSTR <= {24'h0FFFFF,ID_INSTR[7:0]}; // carry a bubble into EX1 for reverse assembling and displaying in Time-Space diagram
				// Notice that, if the EX1_INSTR[31:8] is loaded with 24'h0FFFFF, the reverse assembler reports a "BUBBLE" (to distinguish from a NOP)
			else
				EX1_INSTR <= ID_INSTR; // carry the instruction for reverse assembling and displaying in Time-Space diagram
			
			
			// END CODE FROM ABOVE
			
				
			
			
			if (WB_WRITE)
				begin
					reg_file[WB_RA] <= WB_RD;
				end
			// END REGISTER FILE CODE
				
				

	  end
  
  end

//--------------------------------------------------
endmodule