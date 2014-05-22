
//::::::::::::::::::::::::::::::::::4 Overige functies:::::::::::::::::::::::::::::::::::::::

//4.1 Delay
void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
