
/*:::::::::::::::::Info:::::::::::::::::*\
 Repetier <-> PLC bridge
 
 >I1-PRO06, Hogeschool Utrecht
 >Onno Frankemolen
 >Fokko Visser
 >Tim Peperkamp
 >Khasayar Irani
 >Mark Klein Gebbink
 >Daan Beusink
 
 Datum:         08-05-2014
 Versie:        4.1
 Fucntie:       Verwerkt Gcode en Mcode commando's van Repetier en communiceerd met een PLC CNC achtige 3D printer
 Communicatie:  Omron Fins via Udp(object: FinsUDP
                Repetier ASCII via RS232 serial COM(boject: repetierSerial)
 
 Coords buffering MAC(idee):
      >Execute|ˆˆˆˆˆˆˆˆˆˆˆˆˆˆˆˆ|Busy*           +Execute|ˆˆˆˆˆˆˆˆˆˆˆˆˆˆˆˆ|Busy%
              |       FB1      |Done+                   |       FB2      |Done>
              |________________|                        |________________|
 
         %----++++++++++++++++++++                 *----++++++++++++++++++++
              + Inline ST code 1 +                      + Inline ST code 2 +
              ++++++++++++++++++++                      ++++++++++++++++++++
 
 Repetier:      Omron:               Beschrijving:
 Gnnn           x                    Gcommand
 Mnnn           x                    Mcommand
 Tnnn           x                    Tool command (standaard 1)
 Snnn           D10(S.)   D11(.S)    Command parameter
 Pnnn           D12(S.)   D13(.S)    Command parameter
 Xnnn           D100(X.)  D101(.X)   X coord    
 Ynnn           D102(Y.)  D103(.Y)   Y coord    
 Znnn           D104(Z.)  D105(.Z)   Z coord    
 Fnnn           D20(F.)   D21(.F)    Feedrate[mm/min]
 Rnnn           D22(R.)   D23(.R)    Temperatuur parameter[^C]
 Ennn           D30(E.)   D31(.E)    Lengte filament [mm]
 Nnnn           x                    Regelnummer
 *nnn           x                    Checksum
 
 Omron bits:  Beschrijving:
 D50.0        Servo power on
 D50.1        Fans on
 D50.2        Use Absolute coords
 D50.3
 D50.4
 D50.5
 D50.6
 D50.7
 D51.1
 D51.2

 Sectie 0: Setup
 Sectie 1: Hoofdloop
 Sectie 2: Repetier functies
 Sectie 3: PLC functies
 Sectie 4: Overige functies
 
*/
