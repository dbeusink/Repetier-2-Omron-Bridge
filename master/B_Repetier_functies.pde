
//::::::::::::::::::::::::::::::::::2 Repetier functies::::::::::::::::::::::::::::::::::::::

//2.1 Interupt 1: wordt aangeroepen als de buffer een N aantreft.
void serialEvent(Serial repetierSerial){
    String leesBuffer = repetierSerial.readString(); 
    if (leesBuffer.length()>1){
    gdata[pos] = leesBuffer;
    println("Nieuwe data ontvangen: "+gdata[pos]+" Array positie: "+pos);
    if (pos < 1) bufferEmpty = false;
    pos++;
    return; 
    }
    else repetierSerial.write("ok\r\n");
}

//2.2 Update ringbuffer  
void updateBuffer(){
  if (bufferEmpty) return;
  tempbuf = new String[20]; 
  print("updateBuffer: positie[0]: '"+gdata[0]+"' is nu '");
  arrayCopy(gdata, 1, tempbuf, 0, 19);
  tempbuf[19] = "";
  arrayCopy(tempbuf, gdata, 19);
  println(gdata[0]+"'");
  pos--;
  if (gdata[0] == null) bufferEmpty = true;
}

//Vertaal string naar bruikbare gegevens
void readParseAscii()
{
  //Mnnn standaard M -> curM = parsedM
  //M
  if (bufferEmpty == true) return;
  int index = 0;
  int index2 = 0;
  
  //Results
  float parseResultX = 0.0;
  float parseResultY = 0.0;
  float parseResultZ = 0.0;
  float parseResultE = 0.0;
  float parseResultF = 0.0;
  if (int(findNumber('N',SPATIE)) != 0){
    line = int(findNumber('N',SPATIE));
    regel = line;
    println("Parsing regel: "+line+" RAW: "+findNumber('N',SPATIE));
    
    if (findNumber('M',SPATIE) != -1.0){
      curM = int(findNumber('M',SPATIE));
      println("readParseAscii: M = "+curM);
      doM(curM);
    }
    
    else if (findNumber('T',SPATIE) != -1.0){
      println("readParseAscii: Gebruik extruder 1(T0)");
    }
    
    else if (findNumber('G',SPATIE) != -1.0){
      curG = int(findNumber('G',SPATIE));
      println("readParseAscii: G = "+curG);
      doG(curG);
    }
    
    else {
      repetierSerial.write("RS "+line+"\r\n");
      println("Regel fout! Verstuur regel "+line+" nogmaals");
    }
    //Check alles
    if (!checkSum()&&line!=0){
      repetierSerial.write("RS "+line+"\r\n");
      println("Checksum fout! Verstuur regel "+line+" nogmaals");
     }
     else if(asok==false && line!=0){
       repetierSerial.write("ok\r\n");
       println("Parse succesvol, volgend regel graag");
     }
     else if(asok==true && line!=0){
       asok = false;
       println("Parse succesvol, volgend regel graag");
     }
     updateBuffer();
     finsSetBit(LATCH, FALSE);
  }
}

//Check M functies
void doM(int M){
  switch(M){
    case 0:   {  comment=regel+" Stop alles zodra de buffer leeg is"; curM = 666;                        break;} //M0
    
    case 17:  {  comment=regel+" Schakel alle servo's in"; curM = 666;                                   finsSetBit(SERVO_POWER, TRUE);  break;} //M17
    case 18:  {  comment=regel+" Schakel alle servo's uit"; curM = 666;                                  finsSetBit(SERVO_POWER, FALSE); break;} //M18
        
    case 40:  {  comment=regel+" Eject part (if possible)"; curM = 666;                                  break;} //Not used
    case 41:  {  comment=regel+" Loop Programm(Stop with reset button!)"; curM = 666;                    break;} //Not used
    case 42:  {  comment=regel+" Stop if out of material (if supported)"; curM = 666;                    break;} //Not used
    case 43:  {  comment=regel+" Like M42 but leave heated bed on (if supported)"; curM = 666;           break;} //Not used
    
    case 80:  {  comment=regel+" Turn on ATX Power (niet gebruikt) "; curM = 666;                        break;} //Not used          
    case 81:  {  comment=regel+" Turn off ATX Power (niet gebruikt)"; curM = 666;                        break;} //Not used
    
    case 84:  {  comment=regel+" Stop idle hold (DO NOT use while printing!)"; curM = 666;               break;} //M84
   
    case 104: {  comment=regel+" Temperature[S] Set extruder temperature (not waiting)"; curM = 666;     extruderTemp = findNumber('S',SPATIE); finsSendFloat(22,extruderTemp); break;} //M104
    case 105: {  comment=regel+" Get extruder Temperature"; curM = 666;                                  repetierSerial.write("ok T:"+random(199,202)+" B:-273\r\n"); asok = true; break;} //M105
    case 106: {  comment=regel+" Set Fan Speed to S and start"; curM = 666;                              finsSetBit(FANS, TRUE); break;}
    case 107: {  comment=regel+" Turn Fan off"; curM = 666;                                              finsSetBit(FANS, FALSE); break;}
    case 108: {  comment=regel+" Set extruder speed (outdated)"; curM = 666;                             break;} //Outdated
    case 109: {  comment=regel+" Set extruder Temperature (waits till reached)"; curM = 666;             break;} //M109
    case 110: {  comment=regel+" Set current line number to "; curM = 666;                         break;} //M110
    case 111: {  comment=regel+" Set Debug Level"; curM = 666;                                           break;} //M111
    case 112: {  comment=regel+" Emergency Stop (Stop immediately)"; curM = 666;                         finsSetBit(NOODSTOP, TRUE); break;} //M112 NOODSTOP.
    case 113: {  comment=regel+" Set Extruder PWM to S (or onboard potent. If not given)"; curM = 666;   break;} //Not used
    case 114: {  comment=regel+" Get Current Position"; curM = 666;                                      sendCurrentPosition(); break;} //M114
    case 115: {  comment=regel+" Get Firmeware Version and Capabilities"; curM = 666;                    
                 repetierSerial.write("ok PROTOCOL_VERSION:0.1.4.2 FIRMWARE_NAME:Barefoot FIRMWARE_URL:http://www.via.hu.nl MACHINE_TYPE:I1-PRO06::Delta3D EXTRUDER_COUNT:1\r\n"); asok = true; break;} //M115 stuur iets?
    case 116: {  comment=regel+" Wait for ALL temperatures"; curM = 666;                                 break;}
    case 117: {  comment=regel+" Get Zero Position in steps"; curM = 666;                                sendZeroPositon(); break;}//M117
    
    case 119: {  comment=regel+" Get Endstop Status"; curM = 666;                                        break;}
     
    case 126: {  comment=regel+" Open extruder valve (if available) and wait for P ms"; curM = 666;      break;}
    case 127: {  comment=regel+" Close extruder valve (if available) and wait for P ms"; curM = 666;     break;}
    case 128: {  comment=regel+" Set internal extruder pressure S255 eq max"; curM = 666;                break;}
    case 129: {  comment=regel+" Turn off extruder pressure and wait for P ms"; curM = 666;              break;}
    
    case 140: {  comment=regel+" Set heated bed temperature to S (not waiting)"; curM = 666;             break;}
    case 141: {  comment=regel+" Set chamber temperature to S (not waiting)"; curM = 666;                break;}
    case 142: {  comment=regel+" Set holding pressure to S bar"; curM = 666;                             break;}
    case 143: {  comment=regel+" Set maximum hot-end temperture"; curM = 666;                            break;}
     
    case 203: {  comment=regel+" Set Z offset (stays active even after power off)"; curM = 666;          break;}
    
    case 226: {  comment=regel+" Pauses printing (like pause button)"; curM = 666;                       break;}
    case 227: {  comment=regel+" Enables Automatic Reverse and Prime"; curM = 666;                       break;}
    case 228: {  comment=regel+" Disables Automatic Reverse and Prime"; curM = 666;                      break;}
    case 229: {  comment=regel+" Enables Automatic Reverse and Prime"; curM = 666;                       break;}
    case 230: {  comment=regel+" Enable / Disable wait for temp.(1 = Disable 0 = Enable)"; curM = 666;   break;}
    
    case 240: {  comment=regel+" Start conveyor belt motor"; curM = 666;                                 break;}
    case 241: {  comment=regel+" Stop conveyor belt motor"; curM = 666;                                  break;}
      
    case 245: {  comment=regel+" Start cooler fan"; curM = 666;                                          break;}
    case 246: {  comment=regel+" Stop cooler fan"; curM = 666;                                           break;}
    
    case 300: {  comment=regel+" Beep with S Hz for P ms"; curM = 666;                                   break;}
    
    case 666: break; //default
    default:  {  println("M-code Error - Wrong M number M="+curM); curM = 666; break;}
  };   
}

void sendCurrentPosition(){
  //Haal data op uit Omron
  repetierSerial.write("ok C: X:9.2 Y:125.4 Z:3.7 E:1902.5\r\n");
  asok = true;
}

void sendZeroPosition(){
  //Haal data op uit Omron
  repetierSerial.write("ok C: X:6.2 Y:100.4 Z:3.7\r\n");
  asok = true;
}

void  sendZeroPositon(){
}

void doG(int G){
  switch(G){
    case 0:  { comment=regel+" G"+g+"Snelle beweging"; curG = 666;                                      rapidMove(); break;}
    case 1:  { comment=regel+" G"+g+"Gecontroleerde beweging"; curG = 666;                              controlledMove(); break;}
    case 2:  { comment=regel+" G"+g+"Gecontroleerde beweging boog(klokmee)"; curG = 666;                break;} //Niet ondersteund door MAC
    case 3:  { comment=regel+" G"+g+"Gecontroleerde beweging boog(kloktegen)"; curG = 666;              break;} //Niet ondersteund door MAC
    case 4:  { comment=regel+" G"+g+"Pauzeer voor "+findNumber('P',SPATIE)+" milliseconden)";curG = 666;delay(int(findNumber('P',SPATIE))); break;}
    case 28: { comment=regel+" G"+g+"Beweeg naar oorsprong"; curG = 666;                                finsSetBit(GO_ORIGIN, TRUE); break;}
    case 20: { comment=regel+" G"+g+"Set units to inches"; curG = 666;                                  break;} //Negeer wij doen mm
    case 21: { comment=regel+" G"+g+"Set units to Millimeters"; curG = 666;                             break;} //Negeer wij doen mm
    case 29: { comment=regel+" G"+g+"Detailed Z-Probe"; curG = 666;                                     break;} //Nog niet gimplementeerd
    case 30: { comment=regel+" G"+g+"Single Z Probe"; curG = 666;                                       break;} //Nog niet gimplementeerd
    case 31: { comment=regel+" G"+g+"Report Current Probe status"; curG = 666;                          break;} //Nog niet gimplementeerd
    case 32: { comment=regel+" G"+g+"Probe Z and calculate Z plane"; curG = 666;                        break;} //Nog niet gimplementeerd
    case 90: { comment=regel+" G"+g+"Set to Absolute Positioning"; curG = 666;                          moveAbsolute = true; finsSetBit(USE_ABSOLUTE, TRUE); break;}
    case 91: { comment=regel+" G"+g+"Set to Relative Positioning"; curG = 666;                          moveAbsolute = false; finsSetBit(USE_ABSOLUTE, FALSE); break;}
    case 92: { comment=regel+" G"+g+"Set Position"; curG = 666;                                         setPosition(); break;}
    
    case 666: break; //default
    default:  {  println("G Error - Wrong G number G="+curM); curM = 666; break;} 

  };
}

void rapidMove(){
  //X Y Z E
  String msg = "Rapid Move";
  if (findNumber('X',SPATIE)==-1){
    coords.set(0,findNumber('X',SPATIE));
    msg += " X:"+coords.get(0);
    finsSendFloat(100,coords.get(0));
  }
  
  if (findNumber('Y',SPATIE)!= -1){
    coords.set(1,findNumber('Y',SPATIE));
    msg += " Y:"+coords.get(1);
    finsSendFloat(102,coords.get(1));
  }
  
  if (findNumber('Z',SPATIE)!= -1){
    coords.set(2,findNumber('Z',SPATIE));
    msg += " Z:"+coords.get(2);
    finsSendFloat(104,coords.get(2));
  }
  
  if (findNumber('E',SPATIE)!= -1){
    coords.set(4,findNumber('E',SPATIE));
    msg += " E:"+coords.get(4);
    finsSendFloat(106,coords.get(4));
  }
  println(msg);
}

void controlledMove(){
  //X Y Z F E
  if (!moveAbsolute){
  String msg = "Controlled move - Relative";
  if (findNumber('X',SPATIE)!=-1){
    coords.set(0,findNumber('X',SPATIE));
    msg += " X:"+coords.get(0);
    finsSendFloat(_X, coords.get(0));
  }
  
  if (findNumber('Y',SPATIE)!= -1){
    coords.set(1,findNumber('Y',SPATIE));
    msg += " Y:"+coords.get(1);
    finsSendFloat(_Y,coords.get(1));
  }
  
  if (findNumber('Z',SPATIE)!= -1){
    coords.set(2,findNumber('Z',SPATIE));
    msg += " Z:"+coords.get(2);
    finsSendFloat(_Z,coords.get(2));
  }
  
  if (findNumber('F',SPATIE)!= -1){
    coords.set(3,findNumber('F',SPATIE));
    msg += " E:"+coords.get(3);
    finsSendFloat(_F,coords.get(3));
  }
  println(msg);
  finsSetBit(LATCH,TRUE);
}
}

void setPosition(){
}

boolean checkSum(){
  int chk = int(findNumber('*', EIND));
  int cs = 0;
  for (int i=0; gdata[0].charAt(i)!='*' && gdata[0].length()-1>i; i++){
  cs = cs ^ gdata[0].charAt(i);
  };
  cs &=0xff;
  if (chk == cs) {println("Checksum goed! cs="+cs+" chk="+chk); return true;}
  else {println("Checksum fout! cs="+cs+" chk="+chk); return false;}
};

//findNumber(karakter, SPATIE of EIND);
float findNumber(char c, boolean mod){
 String flo = "";
 float uit = -1.0;
 //Einde is een spatie
 if (mod == true){
 int idx1 = gdata[0].indexOf(c,0);
 int idx2 = 0;
  if(idx1 != -1){ 
    idx2 = gdata[0].indexOf(' ',idx1);
    for (int i=0; i<(idx2-idx1-1);i++){
      flo += gdata[0].charAt(idx1+(i+1));
    };
  uit = float(flo);
  //return uit;
  };
 }
 //Einde is het einde van een zin
 if (mod == false){
   int idx1 = gdata[0].indexOf(c,0);
    if(idx1 != -1){ 
        for (int i=0; i<gdata[0].length()-idx1-2;i++){
          flo += gdata[0].charAt(idx1+(i+1));
        };
        uit = float(flo);
        //return uit;
    };
 } 
  return uit;
}
