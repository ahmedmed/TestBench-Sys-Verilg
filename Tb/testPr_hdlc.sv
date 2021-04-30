//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

program testPr_hdlc(
  in_hdlc uin_hdlc
);

  parameter TXSC   = 3'b000;
  parameter TXBUFF = 3'b001;
  parameter RXSC   = 3'b010;
  parameter RXBUFF = 3'b011;
  parameter RXLEN  = 3'b100;

  parameter TXDONE       = 8'b0000_0001;
  parameter TXENABLE     = 8'b0000_0010;
  parameter TXABORT      = 8'b0000_0100;
  parameter RXDROP       = 8'b0000_0010;
  parameter RXFCS        = 8'b0010_0000;
  parameter RXREADY      = 8'b0000_0001;
  parameter RXABORT      = 8'b0000_1000;
  parameter RXOVERFLOW   = 8'b0001_0000;
  parameter RXFRAMEERROR = 8'b0000_0100;

  parameter FLAG     = 8'b0111_1110;
  parameter ABORTFLAG = 8'b1111_1110;

  typedef enum int { RX_NORMAL,
                     RX_ABORT,
                     RX_OVERFLOW,
                     RX_NONALIGN,
                     RX_FCSERROR,
                     RX_DROP
                   } RX_TESTCASES;

  typedef enum int { TX_NORMAL,
                     TX_ABORT,
                     TX_FULL
                   } TX_TESTCASES;

  int TbErrorCnt;

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    init();

    //Tests:
    Receive(RX_NORMAL);
    Receive(RX_ABORT);
    Receive(RX_OVERFLOW);
    Receive(RX_NONALIGN);
    Receive(RX_FCSERROR);
    Receive(RX_DROP);
    Receive(RX_NORMAL);
    Receive(RX_ABORT);
    Receive(RX_OVERFLOW);
    Receive(RX_NONALIGN);
    Receive(RX_FCSERROR);
    Receive(RX_DROP);
    Receive(RX_DROP);
    Receive(RX_NONALIGN);
    Receive(RX_ABORT);
    Receive(RX_FCSERROR);
    Receive(RX_NORMAL);
    Transmit();
    Transmit();
    Transmit();

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %0d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  task init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;
    uin_hdlc.DataIn      =   8'h00;
    uin_hdlc.TxEN        =   1'b1;
    uin_hdlc.Address     =   3'b0;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address ,output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask


  //////////////////////////////////////////////////////////////////////////
  //
  //                 Receive tasks
  //
  //////////////////////////////////////////////////////////////////////////


  task Receive(input RX_TESTCASES mode);
    logic        [7:0]  ReadData;
    logic [127:0][7:0]  receiveData;
    logic        [15:0] FCSbytes;
    int                 size;

    $display("--- Starting RECEIVE test %s ---", RX_TESTCASES'(mode));

    // Generate random input data
    if (mode == RX_OVERFLOW) begin
      size = 126;
    end else if (mode == RX_NONALIGN) begin
      size = $urandom_range(2, 125); // make sure we have one byte for adding non-byte aligned data
    end else begin
      size = $urandom_range(2, 125);
    end
    $display("Receiving %0d bytes", size);

    for (int i = 0; i < size; i++) begin
      receiveData[i] = $urandom();
    end

    // FCS bytes
    receiveData[size]   = '0;
    receiveData[size+1] = '0;
    CalculateFCS(receiveData, size, FCSbytes);
    receiveData[size]   = FCSbytes[7:0];
    receiveData[size+1] = FCSbytes[15:8];
    if (mode == RX_FCSERROR) begin // create non-valid FCS
      receiveData[size]   = 8'hFF;
      receiveData[size+1] = 8'hFF;
    end

    if (mode == RX_OVERFLOW || mode == RX_NONALIGN) begin
      WriteAddress(RXSC, 8'b0); // disable CRC check
    end else begin
      WriteAddress(RXSC, RXFCS);
    end

    RxGenerateInput(receiveData, size+2, mode); // generate input, include the two FCS bytes


    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1; // Rx should be one when not receiving anything


    repeat(8)
      @(posedge uin_hdlc.Clk);

    VerifyReceiveOutput(receiveData, size, mode);

  endtask

  task RxGenerateInput(input logic [127:0][7:0] data,
                       input int                size,
                       input RX_TESTCASES       mode
                      );
    automatic logic      [4:0] zeroPadding  = '0;
    automatic logic [3:0][7:0] overflowData = '0;

    // Start flag
    for (int i = 0; i < 8; i++) begin
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = FLAG[i];
    end

    // Message
    for (int i = 0; i < size; i++) begin
      for (int j = 0; j < 8; j++) begin
        // Add 0 if there are five 1's in a row in data 
        if (&zeroPadding) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx      = 0;
          zeroPadding      = zeroPadding >> 1;
          zeroPadding[4]   = 0;
        end
        @(posedge uin_hdlc.Clk);
        zeroPadding      = zeroPadding >> 1;
        zeroPadding[4]   = data[i][j];
        uin_hdlc.Rx      = data[i][j];
      end
    end

    if (mode == RX_OVERFLOW) begin // Send four extra bytes
      for (int i = 0; i < 4; i++) begin
        overflowData = $urandom();
      end
      for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 8; j++) begin
          // Add 0 if there are five 1's in a row in data 
          if (&zeroPadding) begin
            @(posedge uin_hdlc.Clk);
            uin_hdlc.Rx      = 0;
            zeroPadding      = zeroPadding >> 1;
            zeroPadding[4]   = 0;
          end
          @(posedge uin_hdlc.Clk);
          zeroPadding      = zeroPadding >> 1;
          zeroPadding[4]   = overflowData[i][j];
          uin_hdlc.Rx      = overflowData[i][j];
        end
      end
    end

    if (mode == RX_NONALIGN) begin // Send three extra bits
      for (int i = 0; i < 3; i++) begin
        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = i[0];
      end
    end

    // End flag
    for (int i = 0; i < 8; i++) begin
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = (mode == RX_ABORT) ? ABORTFLAG[i] : FLAG[i];
    end
  endtask

  // (1)  Correct data in RX buffer
  // (3)  Correct bits in RX status register
  // (6)  Zero removal
  // (7)  CRC checking
  // (14) Frame size 
  // (15) Rx_Ready
  // (16) Non-byte aligned
  task VerifyReceiveOutput(input logic [127:0][7:0] data,
                           input int                size,
                           input RX_TESTCASES       mode
                          );
    automatic logic [7:0] readData     = '0;
    automatic logic [7:0] expectedData = '0;
    

    case (mode)
      RX_NORMAL:
        expectedData = RXFCS | RXREADY;
      RX_ABORT:
        expectedData = RXFCS | RXABORT;
      RX_OVERFLOW:
        expectedData = RXOVERFLOW | RXREADY;
      RX_NONALIGN:
        expectedData = RXFRAMEERROR;
      RX_FCSERROR:
        expectedData = RXFCS | RXFRAMEERROR;
      RX_DROP: begin
        expectedData = RXFCS;
        WriteAddress(RXSC, RXFCS | RXDROP);
      end
    endcase


    // Read status register
    ReadAddress(RXSC, readData);
    assert (readData === expectedData) else begin
      $error("%t: Error in status register, is %h but should be %h", $time, readData, expectedData);
      TbErrorCnt++;
    end

    if (mode == RX_NORMAL || mode == RX_OVERFLOW) begin
      // Read length
      ReadAddress(RXLEN, readData);
      assert (int'(readData) === size) else begin
        $error("%t: Size is wrong, is %0d but should be %0d", $time, int'(readData), size);
        TbErrorCnt++;
      end
    end else begin
      data = '0; // Data from RxBuffer should be 0 after drop, frameError or abortSignal
    end
    // Read from buffer
    for (int i = 0; i < size; i++) begin
      ReadAddress(RXBUFF, readData);
      assert (data[i] === readData) else begin
        $error("%t: Error in read data nr %0d, is %h but should be %h", $time, i, readData, data[i]);
        TbErrorCnt++;
      end
    end
  endtask



  task Transmit();
    logic [127:0][7:0] transmitData;  // holds random data to be transmitted
    logic        [7:0] readData;      // holds data read from registers
    logic       [15:0] FCSoutput;
    int                size;

    $display("--- Starting TRANSMIT test ---");


    // Be sure that hdlc is ready to transmit
    ReadAddress(TXSC, readData); 
    assert (readData === TXDONE)
    else begin
      $display("TX buffer not ready to be written");
      TbErrorCnt++;
    end

    // Fill data with random numbers
    size = $urandom_range(2, 125);
    $display("Transmitting %0d bytes", size);

    for (int i = 0; i < size; i++) begin
      transmitData[i] = $urandom;
      WriteAddress(TXBUFF, transmitData[i]);
    end


    // Add calculated FCS bits to data
    transmitData[size]   = '0;
    transmitData[size+1] = '0;
    CalculateFCS(transmitData, size, FCSoutput);
    transmitData[size]   = FCSoutput[7:0];
    transmitData[size+1] = FCSoutput[15:8];

    #1us;
    WriteAddress(TXSC,   TXENABLE);

    // Verify correct output from TX
    VerifyTxOutput(transmitData, size+2);


    #5us;
  endtask


  task CalculateFCS(input  logic [127:0][7:0]  data, 
                    input  int                 size, 
                    output logic        [15:0] FCSbytes );

    logic [23:0] tempStore;
    tempStore[7:0]  = data[0];  // store the first two bytes, to start the computation correctly
    tempStore[15:8] = data[1];

    for (int i = 2; i < size + 2; i++) begin
      tempStore[23:16] = data[i];  // grab the next byte
      for (int j = 0; j < 8; j++) begin
        // Perform xor operation
        tempStore[16] = tempStore[16] ^ tempStore[0];
        tempStore[14] = tempStore[14] ^ tempStore[0];
        tempStore[1]  = tempStore[1]  ^ tempStore[0];
        tempStore[0]  = tempStore[0]  ^ tempStore[0];
        tempStore = tempStore >> 1;
      end
    end
    FCSbytes = tempStore[15:0];
  endtask

  // (4)  Task to verify that TX output is correct according to TX buffer
  // (5)  Also checks start and end flag generation
  // (6)  Zero insertion
  // (11) CRC generation
  task VerifyTxOutput(input logic [127:0][7:0] transmittedData, input int size);
    automatic logic [4:0] zeroPadding = '0;
    automatic logic [7:0] TxByte      = '0;

    // Start flag generation
    @(negedge uin_hdlc.Tx)
    TxByte[0] = uin_hdlc.Tx;
    for (int i = 1; i < 8; i++) begin
      @(posedge uin_hdlc.Clk)
      TxByte[i] = uin_hdlc.Tx;
    end
    assert (TxByte == FLAG)
    begin
      $display("Start flag correct!");
    end else begin
      $error("%t: Start flag is wrong! Should be %h, but is %h.", $time, FLAG, TxByte);
      TbErrorCnt++;
    end

    // Correct data
    for (int i = 0; i < size; i++) begin
      for (int j = 0; j < 8; j++) begin
        // if there are transmitted 5 zeros in a row, the next bit should be 0 and is not added to TxByte
        if (&zeroPadding) begin
          @(posedge uin_hdlc.Clk);
          zeroPadding[3:0] = zeroPadding >> 1;
          zeroPadding[4]   = uin_hdlc.Tx;
        end
        @(posedge uin_hdlc.Clk);
        zeroPadding[3:0] = zeroPadding >> 1;
        zeroPadding[4]   = uin_hdlc.Tx;
        TxByte[j] = uin_hdlc.Tx;
      end
      // verify correct byte
      assert (TxByte == transmittedData[i]) else begin
        $error("%t: Tx %s byte %0d is wrong! Is %h, should be %h", $time, i < size-2 ? "" : "FCS", i < size-2 ? i : size - i, TxByte, transmittedData[i]);
        TbErrorCnt++;
      end
    end

    // check if the next bit is also a padded 0
    if (&zeroPadding) begin
      @(posedge uin_hdlc.Clk);
    end

    // check last byte, should be correct end flag
    for (int i = 0; i < 8; i++) begin
      @(posedge uin_hdlc.Clk)
      TxByte[i] = uin_hdlc.Tx;
    end
    assert (TxByte == FLAG)
    else begin
      $error("%t: End flag is wrong! Should be %h, but is %h.", $time, FLAG, TxByte);
      TbErrorCnt++;
    end
  endtask

endprogram
