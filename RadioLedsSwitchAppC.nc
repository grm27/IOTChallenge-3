#include "RadioLedsSwitch.h"
#include "printf.h"
#define NEW_PRINTF_SEMANTIC

configuration RadioLedsSwitchAppC {}
implementation {
  components MainC, RadioLedsSwitchC as App, LedsC;
  components new AMSenderC(AM_SWITCH);
  components new AMReceiverC(AM_SWITCH);
  components new TimerMilliC();
  components ActiveMessageC;
  components SerialStartC;
  components PrintfC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
}


