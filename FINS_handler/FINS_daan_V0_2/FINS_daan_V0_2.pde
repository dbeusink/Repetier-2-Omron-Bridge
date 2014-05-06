
import processing.serial.*;  //Serial bibliotheek
import hypermedia.net.*;     //UDP Netwerk bibliotheek

//0 CONFIG: ------------------------------------------------------------------------------//
boolean debugging = false;                  //Wel of niet debuggen

//0.1 >>Repetier<<
int repetierPort = 0;                   //Seriele poort waar repetier mee verbonden is

//0.2 >>MAC<<
String ControllerIP = "192.168.1.102";  //IP adres van de MAC
int UDPFinsPort = 9600;                 //UDP port standaard: 9600

//0.3 >>FINS pakket<<
int FinsSize = 22;                      //Grootte FinsPakket
int SID = 3;                            //ID voor eigen data handling, gewoon random op 3 gezet

//0.4 >>Gcode<<


//--------------------------------------------------------------------------------------//

Serial repetierSerial; // Maak een Serial object aan
UDP FinsUDP;
FloatList coords;
PImage logo;
byte[] FinsFrame;
byte[] FinsFrame18;
byte[] FinsFrameRecv;
byte[] FinsFrameBig;
String[] gdata, tempbuf;
int pos = 0;
String line = "";
String curM = "";
boolean parseDone = false;
boolean bufferEmpty = false;



//1 Setup voorwaarden:
void setup() {
  //1.1 GUI venster
  size(450, 550); //Venster
  logo = loadImage("logo.png"); //Ons logootje
  
  //1.2 Serieele communicatie init:
  println(Serial.list()); //Geef een overzicht van seriele aparaten
  println(" Op dit moment verbonden met -> " + Serial.list()[repetierPort]);
  repetierSerial = new Serial(this,Serial.list()[repetierPort], 115200); //Init serial object in het dynamisch geheugen @115200 baud rate
  
  //1.3 UDP init
  FinsUDP = new UDP(this, UDPFinsPort); //Open de UDP port
  FinsFrame = new byte[FinsSize];
  FinsFrame18 = new byte[17];
  FinsFrameRecv = new byte[25];
  FinsFrameBig = new byte[38];
  gdata = new String[20];
  FinsUDP.log(debugging);
  FinsUDP.listen(false);
  
  //1.4 Fins init
  fillFinsFrame(); //Fins frame vullen
  
  //1.5 Data handler init
  gdata[0]="";
  coords = new FloatList();
  
  //Test----->
  coords.append(11.12);
  coords.append(11.12);
  coords.append(11.12);
  coords.append(11.12);
  coords.append(11.12);
  gdata[0] = "N1 Nico de koning en M100 de koning";
  gdata[1] = "N2 Nico de koning en M200 de koning";
  gdata[2] = "N3 Nico de koning en M102 de koning";
  gdata[3] = "N4 Nico de koning en M109 de koning";
  //Test<------
}

//2 Begin hoofdloop:
void draw() {
  //2.1 GUI framework tekenen
  background(255);
  fill(0);
  image(logo,5,0);
  
  //2.2 Text voor debugging
  text("System running: @" + FinsUDP.port(), 15, 145);
  text("Pakket: ", 15, 160);
  
  for (int i=0; i<FinsSize; i++){
    text("0x"+hex(FinsFrame[i]), 15, 175+(i*15));
  };
 
 //2.3 Repetier serieel
 repetierSerieel();
 readParseAscii();
  //2.4 Schrijven naar het DM geheugen van de MAC
  //writeFinsDM(100, 30.33); //Schrijf op adres D100 en D101 met de waarde 30.33(30 en 33)
  //writeFinsDMlist(100, coords);
  //readFinsDM(100);
  
  delay(800);
}

//3 Delay functie
void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

//4 schrijven naar het DM van de MAC
void writeFinsDM(int adres, float num){
 //4.1 Datatypen conversies
 byte Dadd = byte(adres);
 String dat = str(num);
 String split[] = split(dat, '.');
 int conv1 = int(split[0]);
 int conv2 = int(split[1]);
 byte data1 = byte(conv1);
 byte data2 = byte(conv2);
 //4.2 Making da diferance betwien duh schrijfie doen en leesie doen
 FinsFrame[11] = 0x02;
 //4.3 aanvullen rest van het FinsFrame
 FinsFrame[13]=0x00; //DM nr in 2 bytes:
 FinsFrame[14]=Dadd;   //Startadres(word) In ons geval D100 dus 0x64
 FinsFrame[15]=0x00; //Bit adres, heel word dus op 0x00 houden
 FinsFrame[16]=0x00; //Aantal adressen om te vullen, doe maar per 2 aangezien we bijvoorbeeld x.x y.y en z.z etc krijgen. IN DE TEST MAAR EVEN OP 1 houden
 FinsFrame[17]=0x02; //Aantal adressen
 FinsFrame[18]=0x00; //Data1 0x00, Data2 0x01 geeft dus #0001 op D100
 FinsFrame[19]=data1; //Data1 0x00, Data2 0x01 geeft dus #0001 op D100
 FinsFrame[20]=0x00; //Data1 0x00, Data2 0x01 geeft dus #0001 op D100
 FinsFrame[21]=data2; //Data1 0x00, Data2 0x01 geeft dus #0001 op D100
 
 //4.4 Stuur de data over UDP
 String out = new String(FinsFrame);
 FinsUDP.send(out, ControllerIP, UDPFinsPort);
}

//X schrijven van coordinaten lijst naar het DM van de MAC
void writeFinsDMlist(int adres, FloatList coords){
 //4.1 Datatypen conversies
 byte Dadd = byte(adres);
 byte[] data1 = new byte[coords.size()];
 byte[] data2 = new byte[coords.size()];
 for (int i=0; i<coords.size(); i++){
   String dat = str(coords.get(i));
   String split[] = split(dat, '.');
   int conv1 = int(split[0]);
   int conv2 = int(split[1]);
   data1[i] = byte(conv1);
   data2[i] = byte(conv2);
 };
 //X.2 Making da diferance betwien duh schrijfie doen en leesie doen
 FinsFrameBig[11] = 0x02;
 //X.3 aanvullen rest van het FinsFrame
 FinsFrameBig[13]=0x00; //DM nr in 2 bytes:
 FinsFrameBig[14]=Dadd;   //Startadres(word) In ons geval D100 dus 0x64
 FinsFrameBig[15]=0x00; //Bit adres, heel word dus op 0x00 houden
 FinsFrameBig[16]=0x00; //Aantal adressen om te vullen, doe maar per 2 aangezien we bijvoorbeeld x.x y.y en z.z etc krijgen. IN DE TEST MAAR EVEN OP 1 houden
 FinsFrameBig[17]=0x05; //Aantal adressen (5)
 FinsFrameBig[18]=0x00; //Data1 0x00, Data2 0x01 geeft dus #0001 op D100
 FinsFrameBig[19]=data1[0];//X.X
 FinsFrameBig[20]=0x00;
 FinsFrameBig[21]=data2[0];
 FinsFrameBig[22]=0x00;
 FinsFrameBig[23]=data1[1];//Y.Y
 FinsFrameBig[24]=0x00;
 FinsFrameBig[25]=data2[1];
 FinsFrameBig[26]=0x00;
 FinsFrameBig[27]=data1[2];//Z.Z
 FinsFrameBig[28]=0x00;
 FinsFrameBig[29]=data2[2];
 FinsFrameBig[30]=0x00;
 FinsFrameBig[31]=data1[3];//E.E
 FinsFrameBig[32]=0x00;
 FinsFrameBig[33]=data2[3];
 FinsFrameBig[34]=0x00;
 FinsFrameBig[35]=data1[4];//F.F
 FinsFrameBig[36]=0x00;
 FinsFrameBig[37]=data2[4];

 //X.4 Stuur de data over UDP
 String out = new String(FinsFrameBig);
 FinsUDP.send(out, ControllerIP, UDPFinsPort);
}

//5 lezen naar het DM van de MAC
void readFinsDM(int adres){
 //5.1 Datatypen conversies
 byte Dadd = byte(adres);
 //5.2 Making da diferance betwien duh schrijfie doen en leesie doen
 FinsFrame[11] = 0x01;
 //5.3 aanvullen rest van het FinsFrame
 FinsFrame[13]=0x00; //DM nr in 2 bytes:
 FinsFrame[14]=Dadd; //Startadres(word) In ons geval D100 dus 0x64
 FinsFrame[15]=0x00; //Bit adres, heel word dus op 0x00 houden
 FinsFrame[16]=0x00; //Aantal adressen om te vullen, doe maar per 2 aangezien we bijvoorbeeld x.x y.y en z.z etc krijgen. IN DE TEST MAAR EVEN OP 1 houden
 FinsFrame[17]=0x02; //Aantal adressen
 arrayCopy(FinsFrame, FinsFrame18, 17);
 
 //5.4 Stuur de data over UDP
 String out = new String(FinsFrame18);
 FinsUDP.send(out, ControllerIP, UDPFinsPort);
 FinsUDP.listen(true);
}

//6 Vullen van een Fins Frame met de standaard init
void fillFinsFrame(){
 FinsFrame[0]=byte(128);  //ICF = 10000001. Kies 0x80(128) als een reactie vereist is, kies 0x81(129) als een response niet vereist is.
 FinsFrame[1]=0x00;  //RSV = 0x00. Gereserveerd.
 FinsFrame[2]=0x02;  //GCT = Gateways zet op 2 std.
 FinsFrame[3]=0x01;  //DNA = 0x01 voor netwerk 1(xxx.xxx.1.x)
 FinsFrame[4]=0x64;  //DA1 = ip node nr (xxx.xxx.DNA.DA1). Wij kiezen voor 192.168.1.100 dus 0x64
 FinsFrame[5]=0x00;  //DA2 = Aparte ethernet kaart of direct op de CPU. In ons geval 0x00(direct op de MAC)
 FinsFrame[6]=0x01;  //SNA = Netwerk nummer van de PC (xxx.xxx.SNA.xxx) in ons geval 1 dus 0x01.
 FinsFrame[7]=0x0A;  //SA1 = Node nummer van de PC (xxx.xxx.SNA.SA1) in ons geval 10 dus 0x0A
 FinsFrame[8]=0x00;  //SA2 = 0x00 want we hebben hier te maken met een vaste pc en geen mac.
 FinsFrame[9]= byte(SID);  //SID = Procesnummer wordt teruggestuurd in responsie zo kunnen we matchen
 FinsFrame[10]=0x01; //MRC = Request code laat maar op 1
 FinsFrame[11]=0x02; //RC = subRequest code 0x01= lezen. 0x02= schrijven.
 FinsFrame[12]=byte(130); //IO Type: DM 0x82(130)
 //Copy naar andere frames
 arrayCopy(FinsFrame, FinsFrameBig,0);
}

//7 Receive functie voor tijdens het luisteren
void receive(byte[] data, String IP, int PORT){
  arrayCopy(data, FinsFrameRecv);
}

void repetierSerieel(){
   while (repetierSerial.available() > 0) {
    String inBuffer = repetierSerial.readString();   
    if (inBuffer != null) {
      gdata[pos] = inBuffer;
      println("Nieuwe buffer: "+inBuffer+" Array positie: "+pos);
      if (pos < 1) bufferEmpty = false;
      pos++;
    }
  }
}
  
void updateBuffer(){
  if (bufferEmpty) return;
  tempbuf = new String[20]; 
  print("updateBuffer=> positie[0]: '"+gdata[0]+"' is nu '");
  arrayCopy(gdata, 1, tempbuf, 0, 19);
  tempbuf[19] = "";
  arrayCopy(tempbuf, gdata, 19);
  println(gdata[0]+"'");
  pos--;
  if (gdata[0] == null) bufferEmpty = true;
}

void readParseAscii()
{
  if (bufferEmpty == true) 
    return;
  
  int index = 0;
  int index2 = 0;
  boolean succesRead = false;
  
  //Results
  float parseResultX = 0.0;
  float parseResultY = 0.0;
  float parseResultZ = 0.0;
  float parseResultE = 0.0;
  float parseResultF = 0.0;
  
  index = gdata[0].indexOf("N",0);
  if(index != -1){
     //Uitlezen tot de spatie
    index2 = gdata[0].indexOf(' ',index);
    line = "";
    for (int i=0; i<(index2-index-1);i++){
      line += gdata[0].charAt(index+(i+1));
    };
    println("Parsing regel: "+line);
    
    index = gdata[0].indexOf('M',0);
    if(index != 0)   // M commando
    {
      curM = "";
     //Uitlezen tot de spatie
    index2 = gdata[0].indexOf(' ',index);
    for (int i=0; i<(index2-index-1);i++){
      curM += gdata[0].charAt(index+(i+1));
    };
      println("M ontdekt=> curM = "+curM);
    };
    succesRead = true;   
  };
  
  if (succesRead) {
    updateBuffer();
  };
  //parseDone = true;
  
  //Nog te interplemteren:
  if (parseResultX != 0.0) coords.set(0, parseResultX);
  if (parseResultY != 0.0) coords.set(1, parseResultY);
  if (parseResultZ != 0.0) coords.set(2, parseResultZ);
  if (parseResultE != 0.0) coords.set(3, parseResultE);
  if (parseResultF != 0.0) coords.set(4, parseResultF);
  
  
}
    
   
