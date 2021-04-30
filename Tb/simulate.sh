#//////////////////////////////////////////////////
#// Title:   simualte
#// Author:  
#// Date:    
#//////////////////////////////////////////////////

rm -rf work
vlib work

echo ""
echo "Compiling hdlc"
vlog -sv ../rtl/hdlc.sv ../rtl/AddressIF.sv ../rtl/RxController.sv ../rtl/RxChannel.sv ../rtl/RxBuff.sv ../rtl/RxFCS.sv ../rtl/TxController.sv ../rtl/TxChannel.sv ../rtl/TxBuff.sv ../rtl/TxFCS.sv +acc
vlog -sv in_hdlc.sv test_hdlc.sv testPr_hdlc.sv bind_hdlc.sv assertions_hdlc.sv +acc

echo ""
echo "Simulating hdlc"
vsim -assertdebug -c -voptargs="+acc" test_hdlc bind_hdlc -do "
log -r *
run -all; exit"
