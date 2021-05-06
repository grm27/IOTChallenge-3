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
        dbg("RadioLedSwitch", "RadioLedSwitch: timer fired, counter is %hu.\n", counter);
        if (locked) {
            return;
        } else {
            radio_switch_message_t * rcm = (radio_switch_message_t * ) call Packet.getPayload( & packet, sizeof(radio_switch_message_t));
            if (rcm == NULL) {
                return;
            }

            rcm -> counter = counter;
            rcm -> sender_id = TOS_NODE_ID;
            if (call AMSend.send(AM_BROADCAST_ADDR, & packet, sizeof(radio_switch_message_t)) == SUCCESS) {
                dbg("RadioLedSwitch", "RadioLedSwitch: packet sent.\n", counter);
                locked = TRUE;
            }
        }
    }

    event message_t * Receive.receive(message_t * bufPtr,
        void * payload, uint8_t len) {
        counter++;
        dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
        if (len != sizeof(radio_switch_message_t)) {
            return bufPtr;
        } else {
            radio_switch_message_t * rcm = (radio_switch_message_t * ) payload;
            if (rcm -> counter % 10 == 0) {
                call Leds.led0Off();
                call Leds.led1Off();
                call Leds.led2Off();
            } else {
                call Leds.led0Off();
            }

            switch (TOS_NODE_ID) {
            case 1:
                call Leds.led0Toggle();
                break;
            case 2:
                call Leds.led1Toggle();
                break;
            case 3:
                call Leds.led2Toggle();
                break;
            }
            
            //TODO print led values
            
            return bufPtr;
        }
    }

    event void AMSend.sendDone(message_t * bufPtr, error_t error) {
        if ( & packet == bufPtr) {
            locked = FALSE;
        }
    }

}
