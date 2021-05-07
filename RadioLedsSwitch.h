#ifndef RADIO_LEDS_SWITCH_H
#define RADIO_LEDS_SWITCH_H
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

typedef nx_struct radio_switch_message {
  nx_uint16_t counter;
  nx_uint8_t sender_id;
} radio_switch_message_t;

enum {
  AM_SWITCH	  = 6,
  MOTE_1_PERIOD = 1000, //ms
  MOTE_2_PERIOD = 333, //ms
  MOTE_3_PERIOD = 200, //ms
  COUNTER_MOD = 10
};

#endif
