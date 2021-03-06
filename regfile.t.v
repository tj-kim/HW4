//------------------------------------------------------------------------------
// Test harness validates hw4testbench by connecting it to various functional 
// or broken register files, and verifying that it correctly identifies each
//------------------------------------------------------------------------------

`include "decoders.v"
`include "register.v"
`include "multiplexers.v"
`include "regfile.v"
// `include "regfile_testers.v" // this one holds the test regs with failed ones

module hw4testbenchharness();

  wire[31:0]	ReadData1;	// Data from first register read
  wire[31:0]	ReadData2;	// Data from second register read
  wire[31:0]	WriteData;	// Data to write to register
  wire[4:0]	ReadRegister1;	// Address of first register to read
  wire[4:0]	ReadRegister2;	// Address of second register to read
  wire[4:0]	WriteRegister;  // Address of register to write
  wire		RegWrite;	// Enable writing of register when High
  wire		Clk;		// Clock (Positive Edge Triggered)

  reg		begintest;	// Set High to begin testing register file
  wire		dutpassed;	// Indicates whether register file passed tests

  // Instantiate the register file being tested.  DUT = Device Under Test
  regfile DUT
  (
    .ReadData1(ReadData1),
    .ReadData2(ReadData2),
    .WriteData(WriteData),
    .ReadRegister1(ReadRegister1),
    .ReadRegister2(ReadRegister2),
    .WriteRegister(WriteRegister),
    .RegWrite(RegWrite),
    .Clk(Clk)
  );

  // Instantiate test bench to test the DUT
  hw4testbench tester
  (
    .begintest(begintest),
    .endtest(endtest), 
    .dutpassed(dutpassed),
    .ReadData1(ReadData1),
    .ReadData2(ReadData2),
    .WriteData(WriteData), 
    .ReadRegister1(ReadRegister1), 
    .ReadRegister2(ReadRegister2),
    .WriteRegister(WriteRegister),
    .RegWrite(RegWrite), 
    .Clk(Clk)
  );

  // Test harness asserts 'begintest' for 1000 time steps, starting at time 10
  initial begin
    begintest=0;
    #10;
    begintest=1;
    #1000;
  end

  // Display test results ('dutpassed' signal) once 'endtest' goes high
  always @(posedge endtest) begin
    $display("DUT passed?: %b", dutpassed);
  end

endmodule


//------------------------------------------------------------------------------
// Your HW4 test bench
//   Generates signals to drive register file and passes them back up one
//   layer to the test harness. This lets us plug in various working and
//   broken register files to test.
//
//   Once 'begintest' is asserted, begin testing the register file.
//   Once your test is conclusive, set 'dutpassed' appropriately and then
//   raise 'endtest'.
//------------------------------------------------------------------------------

module hw4testbench
// At the end, returns dutpassed = 1 if it is a perfect regfile.
(
// Test bench driver signal connections
input	   		begintest,	// Triggers start of testing
output reg 		endtest,	// Raise once test completes
output reg 		dutpassed,	// Signal test result

// Register File DUT connections
input[31:0]		ReadData1,
input[31:0]		ReadData2,
output reg[31:0]	WriteData,
output reg[4:0]		ReadRegister1,
output reg[4:0]		ReadRegister2,
output reg[4:0]		WriteRegister,
output reg		RegWrite,
output reg		Clk
);

  // Initialize register driver signals
  initial begin
    WriteData=32'd0;
    ReadRegister1=5'd0;
    ReadRegister2=5'd0;
    WriteRegister=5'd0;
    RegWrite=0;
    Clk=0;
  end

  // Once 'begintest' is asserted, start running test cases
  always @(posedge begintest) begin
    endtest = 0;
    dutpassed = 1;
    #10

  // Test Case 1: 
  //   Write '42' to register 2, verify with Read Ports 1 and 2
  //   (Passes because example register file is hardwired to return 42)
  WriteRegister = 5'd2;
  WriteData = 32'd42;
  RegWrite = 1;
  ReadRegister1 = 5'd2;
  ReadRegister2 = 5'd2;
  #5 Clk=1; #5 Clk=0;	// Generate single clock pulse

  // Verify expectations and report test result
  if((ReadData1 != 42) || (ReadData2 != 42)) begin
    dutpassed = 0;	// Set to 'false' on failure
    $display("Test Case 1 Failed: 42 written to reg 2 didn't read back correct");
  end
  else begin
    $display("Test Case 1 Passed");
  end

  // Test Case 2: 
  //   Write '15' to register 2, verify with Read Ports 1 and 2
  //   (Fails with example register file, but should pass with yours)
  WriteRegister = 5'd2;
  WriteData = 32'd15;
  RegWrite = 1;
  ReadRegister1 = 5'd2;
  ReadRegister2 = 5'd2;
  #5 Clk=1; #5 Clk=0;

  if((ReadData1 != 15) || (ReadData2 != 15)) begin
    dutpassed = 0;
    $display("Test Case 2 Failed: 15 written to reg 2 didn't read back correct");
  end
  else begin
    $display("Test Case 2 Passed");
  end

  // Test Case 3:
  //  Write Enable is broken/ignored - Register is always written to
  //  (Fails when register is not written to)
  WriteRegister = 5'd20;
  WriteData = 32'd0;
  RegWrite = 1; // We are initially writing a known value to this port
  #5 Clk=1; #5 Clk=0;

  WriteRegister = 5'd20;
  WriteData = 32'd1234;
  RegWrite = 0; // key that we are not writing
  ReadRegister1 = 5'd20;
  ReadRegister2 = 5'd20;
  #5 Clk=1; #5 Clk=0;

  // With a test 3 fail case, the port we wrote to shouldve 
  // been written over with another value
  if((ReadData1 != 0) || (ReadData2 != 0)) begin
    dutpassed = 0;
    $display("Test Case 3 Failed: Write enable broken, register always written to");
  end
  else begin
    $display("Test Case 3 Passed");
  end

  // Test Case 4:
  //  Decoder is broken - All registers are written to
  //  (Fails when register with known value stored is not written to)
  WriteRegister = 5'd2; // write to certain register 0
  WriteData = 32'd0;
  RegWrite = 1; 
  #5 Clk=1; #5 Clk=0;

  WriteRegister = 5'd20;  // write to another register not 0
  WriteData = 32'd3333;
  RegWrite = 1; 
  ReadRegister1 = 5'd2;   // check previous written register..
  ReadRegister2 = 5'd2;
  #5 Clk=1; #5 Clk=0;

  // With test case 4 fail, the first port we wrote to 
  // wouldve been rewritten even though we didnt write to it.
  if((ReadData1 != 0) || (ReadData2 != 0)) begin
    dutpassed = 0;
    $display("Test Case 4 Failed: Decoder broken, all registers written to");
  end
  else begin
    $display("Test Case 4 Passed");
  end

  // Test Case 5:
  //  Register Zero is actually a register instead of the constant value zero.
  //  (Fails when writing a nonzero value to reg 0 and reading reg 0 returns nonzero)

  WriteRegister = 5'd0;  // write to reg 0
  WriteData = 32'd1111;
  RegWrite = 1;
  ReadRegister1 = 5'd0;   // check previous written register..
  ReadRegister2 = 5'd0;
  #5 Clk=1; #5 Clk=0;

  // With test case 5 fail, the reg zero will return nonzero value
  if((ReadData1 != 0) || (ReadData2 != 0)) begin
    dutpassed = 0;
    $display("Test Case 5 Failed: Register zero is written to, instead of constant zero");
  end
  else begin
    $display("Test Case 5 Passed");
  end

  // Test Case 6:
  //  Port 2 is broken and always reads register 17.
  //  (Fails when writing a reg value to reg not17 and reading 2 reg not17 returns reg17)

  WriteRegister = 5'd17; // write to reg 17 for preset value
  WriteData = 32'd1111;
  RegWrite = 1; 
  #5 Clk=1; #5 Clk=0;


  WriteRegister = 5'd21;  // write to not reg 17 and read it 
  WriteData = 32'd2222;
  RegWrite = 1;
  ReadRegister1 = 5'd21;   
  ReadRegister2 = 5'd21;  // read reg 21, but reg 17 will show up
  #5 Clk=1; #5 Clk=0;

  // With test case 6 fail, we would not read value stored in reg 21
  if((ReadData2 != 2222)) begin
    dutpassed = 0;
    $display("Test Case 6 Failed: Port 2 broken, always reads reg 17");
  end
  else begin
    $display("Test Case 6 Passed");
  end

  // Test Case 7:
  //  Port 1 is broken and always reads register 10.
  //  (Fails when writing a reg value to reg not10 and reading reg 1 not10 returns reg10)
  WriteRegister = 5'd10; // write to reg 10 for preset value
  WriteData = 32'd1111;
  RegWrite = 1; 
  #5 Clk=1; #5 Clk=0;


  WriteRegister = 5'd21;  // write to not reg 10 and read it 
  WriteData = 32'd2222;
  RegWrite = 1;
  ReadRegister1 = 5'd21;   // read reg 21, but reg 10 will show up
  ReadRegister2 = 5'd21;
  #5 Clk=1; #5 Clk=0;

  // With test case 6 fail, we would not read value stored in reg 21
  if((ReadData1 != 2222)) begin
    dutpassed = 0;
    $display("Test Case 7 Failed: Port 1 broken, always reads reg 10");
  end
  else begin
    $display("Test Case 7 Passed");
  end

  // Test Case 8:
  //  Regwrite is flipped, command does opposite.
  //  (Fails when writing a reg value to reg not10 and reading reg 1 not10 returns reg10)
  WriteRegister = 5'd10;  // write to not reg 10 and read it 
  WriteData = 32'd2222;
  RegWrite = 0; 
  #5 Clk=1; #5 Clk=0;

  WriteRegister = 5'd10; // write to reg 10 for preset value
  WriteData = 32'd1111;
  RegWrite = 1; 
  ReadRegister1 = 5'd10;   // read reg 21, but reg 10 will show up
  ReadRegister2 = 5'd10;
  #5 Clk=1; #5 Clk=0;

  // With test case 6 fail, we would not read value stored in reg 21
  if((ReadData1 != 1111)) begin
    dutpassed = 0;
    $display("Test Case 8 Failed: Write enable is flipped, command does opposite");
  end
  else begin
    $display("Test Case 8 Passed");
  end

  // All done!  Wait a moment and signal test completion.
  #5
  endtest = 1;

end

endmodule