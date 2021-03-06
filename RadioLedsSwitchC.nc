#include "Timer.h"

#include "RadioLedsSwitch.h"

#include "printf.h"

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
    bool led[3] = {
        FALSE,
        FALSE,
        FALSE
    };

    void resetMoteLeds() {
        call Leds.led0Off();
        led[0] = FALSE;
        call Leds.led1Off();
        led[1] = FALSE;
        call Leds.led2Off();
        led[2] = FALSE;
    }

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
                // dbg("RadioLedSwitch", "RadioLedSwitch: packet sent.\n", counter);
                locked = TRUE;
            }
        }
    }

    event message_t * Receive.receive(message_t * bufPtr,
        void * payload, uint8_t len) {

        counter++;

        dbg("RadioLedSwitch", "Received packet of length %hhu.\n", len);
        if (len != sizeof(radio_switch_message_t)) {
            return bufPtr;
        } else {

            radio_switch_message_t * rcm = (radio_switch_message_t * ) payload;

            if (rcm -> counter % 10 == 0) {
                resetMoteLeds();
            } else {
                switch (rcm -> sender_id) {
                case 1:
                    call Leds.led0Toggle();
                    led[0] = !led[0];
                    break;
                case 2:
                    call Leds.led1Toggle();
                    led[1] = !led[1];
                    break;
                case 3:
                    call Leds.led2Toggle();
                    led[2] = !led[2];
                    break;
                }
            }

            if (TOS_NODE_ID == 2) {
                printf("%d%d%d\n", led[2], led[1], led[0]);
            }

        }

        return bufPtr;
    }

    event void AMSend.sendDone(message_t * bufPtr, error_t error) {
        if ( & packet == bufPtr) {
            locked = FALSE;
        }
    }
}
