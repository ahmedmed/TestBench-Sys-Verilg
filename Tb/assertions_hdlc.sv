//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

module assertions_hdlc (
  output int  ErrCntAssertions,
  input logic Clk,
  input logic Rst,
  input logic Rx,
  input logic Tx,
  input logic Tx_AbortedTrans,
  input logic Tx_ValidFrame,
  input logic Tx_Full,
  input logic Tx_Done, 
  input logic Rx_FlagDetect,
  input logic Rx_AbortSignal,
  input logic Rx_Overflow,
  input logic Rx_EoF,
  input logic Rx_FrameError,
  input logic Rx_Drop,
  input logic Rx_Ready
  );

  initial begin
    ErrCntAssertions = 0;
  end

  
  //**************************************
  //
  //      RECEIVE ASSERTIONS
  //
  //**************************************
  
  sequence Rx_flag;
    !Rx ##1 Rx [*6] ##1 !Rx;
  endsequence

  // Check if flag sequence is detected
  property Receive_FlagDetect;
    @(posedge Clk) Rx_flag |-> ##2 Rx_FlagDetect;
  endproperty

  Receive_FlagDetect_Assert    :  assert property (Receive_FlagDetect) $display("PASS: Receive_FlagDetect");
                                  else begin $error("Flag sequence did not generate FlagDetect"); ErrCntAssertions++; end

  // (15) Rx_Ready when frame is ready to be written
  property Receive_Ready;
    @(posedge Clk) Rx_EoF ##0 !Rx_AbortSignal ##0 !Rx_FrameError ##0 !Rx_Drop |-> Rx_Ready;
  endproperty

  Receive_Ready_Assert: assert property (Receive_Ready)
                        begin
                          $display("PASS: Receive_Ready");
                        end else begin
                          $error("%t: Rx_Ready is not high when frame is ready to be read", $time);
                          ErrCntAssertions++;
                        end

  //**************************************
  //
  //      TRANSMIT ASSERTIONS
  //
  //**************************************

  // (7) Check that Tx transmit only 1's when not transmitting anything
  property Transmit_Idle;
    @(posedge Clk) !Tx_ValidFrame [*10] |=> Tx; //  Validframe goes low two cycles before transmitting end frame
  endproperty

  as_Transmit_Idle: assert property (Transmit_Idle)
                    else begin
                      $error("%t: HALLAIdle pattern not transmitted from Tx when idle", $time);
                      ErrCntAssertions++;
                    end

endmodule
