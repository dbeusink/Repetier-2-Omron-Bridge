
//::::::::::::::::::::::::::::::::::::3 PLC functies:::::::::::::::::::::::::::::::::::::::

//3.1 Bit over Fins - 1 bit wegschrijven in 1 adres.bit
void finsSetBit(float adress, int stat){
  byte status = 0x00;
 if (stat==1) status = 0x01;
 String float2string = str(adress);
 String split[] = split(float2string, '.');
 int voorpunt = int(split[0]);
 int napunt = int(split[1]);
 byte adres = byte(voorpunt);
 byte bit = byte(napunt);
 FinsFrame[11]=0x02;   //Zet fins in "write" modus
 FinsFrame[13]=0x00;   //DM startadres a
 FinsFrame[14]=adres;  //DM startadres a adres
 FinsFrame[15]=0x00;    //DM bit
 FinsFrame[16]=0x00;   //Aantal adressen te schrijven vanaf het startadres a
 FinsFrame[17]=0x01;   //Aantal adressen te schrijven vanaf het startadres b 1 adres dus 0x01
 FinsFrame[18]=0x00;
 holdBits[adres] = byte(holdBits[adres]^(status<<bit));
 FinsFrame[19]=byte(holdBits[adres]); //bitshift << 
 arrayCopy(FinsFrame,FinsFrame20,20);
 String out = new String(FinsFrame20); //Genereer string van FinsFrame array
 FinsUDP.send(out, ControllerIP, UDPFinsPort); //Stuur data naar de PLC
}

//3.2 Float over Fins - Twee woorden wegschrijven in twee adressen (DM)
void finsSendFloat(int adress, float data){
 byte adres = byte(adress);
 String float2string = str(data);
 String split[] = split(float2string, '.');
 int voorpunt = int(split[0]);
 int napunt = int(split[1]);
 byte data1 = byte(voorpunt);
 byte data2 = byte(napunt);
 FinsFrame[11]= 0x02;   //Zet fins in "write" modus
 FinsFrame[13]=0x00;   //DM startadres a
 FinsFrame[14]=adres;  //DM startadres b
 FinsFrame[15]=0x00;   //Bit/word. 0x00 geeft aan dat het hier om een 'word' gaat
 FinsFrame[16]=0x00;   //Aantal adressen te schrijven vanaf het startadres a
 FinsFrame[17]=0x02;   //Aantal adressen te schrijven vanaf het startadres b 2 adressen(0x00 0x02)
 FinsFrame[18]=0x00;   //Waarde van eerste word a D100
 FinsFrame[19]=data1;  //Waarde van eerste word b D100
 FinsFrame[20]=0x00;   //Waarde van tweede word a D101
 FinsFrame[21]=data2;  //Waarde van tweede word b D101
 String out = new String(FinsFrame); //Genereer string van FinsFrame array
 FinsUDP.send(out, ControllerIP, UDPFinsPort); //Stuur data naar de PLC
}

//3.3 FloatList over Fins - Meerdere woorden wegschrijven in meerdere adressen (DM)
void finsSendFloatList(int adress, FloatList flolijst){
 byte adres = byte(adress);
 byte[] voorpunt = new byte[flolijst.size()];
 byte[] napunt = new byte[flolijst.size()];
 byte aantal = byte(flolijst.size()*2);
 for (int i=0; i<flolijst.size(); i++){
   String float2string = str(flolijst.get(i));
   String split[] = split(float2string, '.');
   int vp = int(split[0]);
   int np = int(split[1]);
   voorpunt[i] = byte(vp);
   napunt[i] = byte(np);
 };
 FinsFrame[11]=0x02;       //Zet fins in "write" modus
 FinsFrame[13]=0x00;       //DM startadres a
 FinsFrame[14]=adres;      //DM startadres b
 FinsFrame[15]=0x00;       //Bit/word. 0x00 geeft aan dat het hier om een 'word' gaat
 FinsFrame[16]=0x00;       //Aantal adressen te schrijven vanaf het startadres a
 FinsFrame[17]=aantal;     //Aantal adressen te schrijven vanaf het startadres b x adressen(0x00 0xaantal)
 FinsFrame[18]=0x00;       //Waarde van eerste word a D100
 FinsFrame[19]=voorpunt[1];//Waarde van eerste word b D100
 FinsFrame[20]=0x00;       //Waarde van tweede word a D101
 FinsFrame[21]=napunt[1];  //Waarde van tweede word b D101
 String out = new String(FinsFrame);
 for (int i=2; i<flolijst.size(); i++){
   out+=0x00+voorpunt[i];
   out+=0x00+napunt[i];
 };
 FinsUDP.send(out, ControllerIP, UDPFinsPort); //Stuur data naar de PLC
}

//3.6 Lezen van een bit uit het DM .:!!:.NOG NIET AF.:!!:.
void finsReadBit(float adres){
  return false;
}

//3.5 Lezen van een woor uit het DM
void finsReadWord(int adress){
 byte adres = byte(adress);
 FinsFrame[11]=0x01;   //Zet fins in "read" modus
 FinsFrame[13]=0x00;   //DM startadres a
 FinsFrame[14]=adres;  //DM startadres b
 FinsFrame[15]=0x00;   //Bit adres, heel word dus op 0x00 houden
 FinsFrame[16]=0x00;   //Aantal adressen om te vullen? waarschijnlijk 1
 FinsFrame[17]=0x01;   //Aantal adressen
 arrayCopy(FinsFrame, FinsFrame18, 18);
 String out = new String(FinsFrame18);
 FinsUDP.send(out, ControllerIP, UDPFinsPort);
}

//3.6 Initialiseer het standaard Fins frame
void fillFinsFrame(){
 //Normaal fins frame
 FinsFrame[0]=byte(128); //ICF = 10000001. Kies 0x80(128) als een reactie vereist is, kies 0x81(129) als een response niet vereist is.
 FinsFrame[1]=0x00;      //RSV = 0x00. Gereserveerd.
 FinsFrame[2]=0x02;      //GCT = Gateways zet op 2 std.
 FinsFrame[3]=0x00;      //DNA = 0x01 voor netwerk 1(xxx.xxx.1.x)
 FinsFrame[4]=0x00;      //DA1 = ip node nr (xxx.xxx.DNA.DA1). Wij kiezen voor 192.168.1.100 dus 0x64
 FinsFrame[5]=0x00;      //DA2 = Aparte ethernet kaart of direct op de CPU. In ons geval 0x00(direct op de MAC)
 FinsFrame[6]=0x00;      //SNA = Netwerk nummer van de PC (xxx.xxx.SNA.xxx) in ons geval 1 dus 0x01.
 FinsFrame[7]=0x01;      //SA1 = Node nummer van de PC (xxx.xxx.SNA.SA1) in ons geval 10 dus 0x0A
 FinsFrame[8]=0x00;      //SA2 = 0x00 want we hebben hier te maken met een vaste pc en geen mac.
 FinsFrame[9]= byte(SID);//SID = Procesnummer wordt teruggestuurd in responsie zo kunnen we matchen
 FinsFrame[10]=0x01;     //MRC = Request code laat maar op 1
 FinsFrame[11]=0x02;     //RC = subRequest code 0x01= lezen. 0x02= schrijven.
 FinsFrame[12]=byte(130);//IO Type: DM 0x82(130)
 
 //Fins frame ok
 FinsFrameOK[0]=byte(192); //ICF = 10000001. Kies 0x80(128) als een reactie vereist is, kies 0x81(129) als een response niet vereist is.
 FinsFrameOK[1]=0x00;      //RSV = 0x00. Gereserveerd.
 FinsFrameOK[2]=0x02;      //GCT = Gateways zet op 2 std.
 FinsFrameOK[3]=0x00;      //DNA = 0x01 voor netwerk 1(xxx.xxx.1.x)
 FinsFrameOK[4]=0x00;      //DA1 = ip node nr (xxx.xxx.DNA.DA1). Wij kiezen voor 192.168.1.100 dus 0x64
 FinsFrameOK[5]=0x00;      //DA2 = Aparte ethernet kaart of direct op de CPU. In ons geval 0x00(direct op de MAC)
 FinsFrameOK[6]=0x00;      //SNA = Netwerk nummer van de PC (xxx.xxx.SNA.xxx) in ons geval 1 dus 0x01.
 FinsFrameOK[7]=0x01;      //SA1 = Node nummer van de PC (xxx.xxx.SNA.SA1) in ons geval 10 dus 0x0A
 FinsFrameOK[8]=0x00;      //SA2 = 0x00 want we hebben hier te maken met een vaste pc en geen mac.
 FinsFrameOK[9]= byte(SID);//SID = Procesnummer wordt teruggestuurd in responsie zo kunnen we matchen
 FinsFrameOK[10]=0x01;     //MRC = Request code laat maar op 1
 FinsFrameOK[11]=0x02;     //RC = subRequest code 0x01= lezen. 0x02= schrijven.
 FinsFrameOK[12]=0x00; 
 FinsFrameOK[13]=0x00; 
 
}

//3.7 Ontvangen data van PLC
void receive(byte[] data, String IP, int PORT){
  if (!IP.equals(ControllerIP)) {
    println("ongelijk");
    return;
  };
  //println("Data ontvangen: MAC - "+str(data));
  arrayCopy(data, FinsFrameRecv);
  if (retrieveFins() != ""){
    finsRecvWord = retrieveFins();
    //println("Pakket is data: "+finsRecvWord);
  }
  else if (checkFinsFrame()) println("Fins frame goed ontvangen");
  //else println("Oef er is iets niet goed gegaan met het fins protocol!!");
}

boolean checkFinsFrame(){
  if (FinsFrameRecv.equals(FinsFrameOK)){
    return true;
  }
  else return false;
}

String retrieveFins(){
  String ret = "";
  if (FinsFrameRecv[9]==FinsFrameOK[9] && FinsFrameRecv[12]==0x00 && FinsFrameRecv[13]==0x00){
     //ret += FinsFrameRecv[14];
     ret += FinsFrameRecv[15]&0xFF; //Van signed byte naar unsigned byte
  }
  return ret;
}
