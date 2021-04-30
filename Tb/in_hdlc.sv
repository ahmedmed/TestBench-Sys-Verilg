//////////////////////////////////////////////////
// Title:   in_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

interface in_hdlc ();
  //Tb
  int ErrCntAssertions;

  //Clock and reset
  logic              Clk;
  logic              Rst;

  // Address
  logic        [2:0] Address;
  logic              WriteEnable;
  logic              ReadEnable;
  logic        [7:0] DataIn;
  logic        [7:0] DataOut;

  // TX
  logic              Tx;
  logic              TxEN;
  logic              Tx_Done;

  // RX
  logic              Rx;
  logic              RxEN;
  logic              Rx_Ready;

  // Tx - internal
  logic       Tx_AbortedTrans; // ? Already in register
  logic       Tx_Full;         // ? Already in register
  logic       Tx_ValidFrame;
 
  // Rx - internal
  logic       Rx_FlagDetect;
  logic       Rx_AbortSignal; // ? Already in register
  logic       Rx_Overflow;    // ? Already in register
  logic [7:0] Rx_FrameSize;
  logic       Rx_EoF;
  logic       Rx_FrameError;
  logic       Rx_Drop;

endinterface
