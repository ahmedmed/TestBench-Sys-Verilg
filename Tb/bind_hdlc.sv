//////////////////////////////////////////////////
// Title:   bind_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

module bind_hdlc ();

  bind test_hdlc assertions_hdlc u_assertion_bind(
    .ErrCntAssertions(uin_hdlc.ErrCntAssertions),
    .Clk(uin_hdlc.Clk),
    .Rst(uin_hdlc.Rst),
    .Rx(uin_hdlc.Rx),
    .Tx(uin_hdlc.Tx),
    .Tx_AbortedTrans(uin_hdlc.Tx_AbortedTrans),
    .Tx_ValidFrame(uin_hdlc.Tx_ValidFrame),
    .Tx_Full(uin_hdlc.Tx_Full),
    .Tx_Done(uin_hdlc.Tx_Done),
    .Rx_FlagDetect(uin_hdlc.Rx_FlagDetect),
    .Rx_AbortSignal(uin_hdlc.Rx_AbortSignal),
    .Rx_Overflow(uin_hdlc.Rx_Overflow),
    .Rx_EoF(uin_hdlc.Rx_EoF),
    .Rx_FrameError(uin_hdlc.Rx_FrameError),
    .Rx_Drop(uin_hdlc.Rx_Drop),
    .Rx_Ready(uin_hdlc.Rx_Ready)
  );

endmodule
