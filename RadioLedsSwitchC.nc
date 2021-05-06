#include "Timer.h"

#include "RadioLedSwitch.h"


module RadioLedsSwitchC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer < TMilli > as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      switch (TOS_NODE_ID) {
      case 1:
        call MilliTimer.startPeriodic(MOTE_1_PERIOD);
        break;
      case 2:
        call MilliTimer.startPeriodic(MOTE_2_PERIOD);
        break;
      case 3:
        call MilliTimer.startPeriodic(MOTE_3_PERIOD);
        break;
      default:
        call MilliTimer.startPeriodic(MOTE_1_PERIOD);
      }
    } else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void MilliTimer.fired() {
    counter++;
    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    } else {
      radio_count_msg_t * rcm = (radio_count_msg_t * ) call Packet.getPayload( & packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
        return;
      }

      rcm -> counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, & packet, sizeof(radio_count_msg_t)) == SUCCESS) {
        dbg("RadioCountToLedsC", "RadioCountToLedsC: packet sent.\n", counter);
        locked = TRUE;
      }
    }
  }

  event message_t * Receive.receive(message_t * bufPtr,
    void * payload, uint8_t len) {
    dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
    if (len != sizeof(radio_count_msg_t)) {
      return bufPtr;
    } else {
      radio_count_msg_t * rcm = (radio_count_msg_t * ) payload;
      if (rcm -> counter & 0x1) {
        call Leds.led0On();
      } else {
        call Leds.led0Off();
      }
      if (rcm -> counter & 0x2) {
        call Leds.led1On();
      } else {
        call Leds.led1Off();
      }
      if (rcm -> counter & 0x4) {
        call Leds.led2On();
      } else {
        call Leds.led2Off();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t * bufPtr, error_t error) {
    if ( & packet == bufPtr) {
      locked = FALSE;
    }
  }

}
