unit simulatorcommands;

{$mode objfpc}{$H+}

interface

const
  // Comandos implementados apenas pelo firmware simulador Arduino.
  SIM_CMD_TARE = 'T';
  SIM_CMD_CLEAR_TOTAL = 'P';
  SIM_CMD_ZERO_TARE = 'Z';
  SIM_CMD_TOGGLE_CONTINUOUS = 'C';
  SIM_CMD_NEXT_WEIGHT = 'N';
  SIM_CMD_TOGGLE_AUTO_CHANGE = 'M';

implementation

end.
