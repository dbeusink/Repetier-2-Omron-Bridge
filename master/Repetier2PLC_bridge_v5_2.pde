import processing.serial.*;  //Serial bibliotheek
import hypermedia.net.*;     //UDP Netwerk bibliotheek

//Configuratie: ----------------------------------------------------------------------------//
boolean debugging = false;                  //Wel of niet debuggen

//>>Mac DM mapping<<
//    Functie:        Bit/word:
int   _X            = 100; //X coord
int   _Y            = 102; //Y coord
int   _Z            = 104; //Z coord
int   _F            = 20;  //Feedrate [mm/min]
int   _E            = 30;  //Hoeveelheid filament in [mm]
float LATCH         = 90.1; //Latch om te kopeieren, nog niet gimplementeerd
float SERVO_POWER   = 50.0; //Zet power op de servo's
float FANS          = 50.1; //Zet ventilatoren aan
float USE_ABSOLUTE  = 50.2; //True: Gebruik absoluut coord stelsel, False: gebruik relatief coord stelsel
float GO_ORIGIN     = 50.3; //Ga naar oorsprong
float NOODSTOP      = 50.4; //Noodstop

//>>Repetier<<
int repetierPort = 1;                   //Seriele poort waar repetier mee verbonden is
int baud = 115200;                      //Seriele baud rate

//>>MAC<<
String ControllerIP = "192.168.1.102";  //IP adres van de MAC
int UDPFinsPort = 9600;                 //UDP port standaard: 9600

//0.3 >>FINS pakket<<
int FinsSize = 22;                      //Grootte FinsPakket
int SID = 5;                            //ID voor eigen data handling, gewoon random op 3 gezet
int TRUE = 1;
int FALSE = 0;

//>>Gcode<<
int curM = 666;
int curG = 666;
//Endmarks voor findNumber()
boolean SPATIE = true;
boolean EIND = false;
boolean asok = false;
float extruderTemp = 0.0;
boolean moveAbsolute = true;

//--------------------------------------------------------------------------------------//

Serial repetierSerial; //Maak een Serial object aan
UDP FinsUDP; //Maak UDP object aan
FloatList coords; //Floatlist voor coordinaten
PImage logo; //Logo object voor de GUI
String comment = ""; //Status informatie voor de GUI
byte[] FinsFrame; //Fins write frame
byte[] FinsFrame18; //Fins read frame
byte[] FinsFrameRecv; //Ontvangen fins frame buffer
byte[] FinsFrameOK;
byte[] FinsFrame20;
byte[] FinsFrameData;
byte[] holdBits;
String finsRecvWord;
String[] gdata, tempbuf; //Gdata buffer en temp buffer
int pos = 0; //Huide buffer pos
int line = 0; //Huidige regel
int regel = 0; //Huidige regel met ofset
//Mischien weggooien:
boolean parseDone = false;
boolean bufferEmpty = true;

//::::::::::::::::::::::::::::::::::::0 Setup:::::::::::::::::::::::::::::::::::::::::::::::
void setup() {
  //0.1 GUI venster
  size(450, 240); //Venster
  logo = loadImage("logo.png"); //Delta3D logo
  
  //0.2 Serieele communicatie init:
  println(Serial.list()); //Geef een overzicht van seriele aparaten
  println(" Op dit moment verbonden met -> " + Serial.list()[repetierPort]);
  repetierSerial = new Serial(this,Serial.list()[repetierPort], baud); //Init serial object
  repetierSerial.bufferUntil('\n'); //Buffer tot een 'N' character is gevonden

  //0.3 UDP init
  FinsUDP = new UDP(this, UDPFinsPort); //Objecten aanmaken
  FinsFrame = new byte[FinsSize];
  FinsFrame20 = new byte[20];
  FinsFrame18 = new byte[18];
  FinsFrameRecv = new byte[60];
  FinsFrameOK = new byte[14];
  gdata = new String[20];
  holdBits = new byte[150];
  FinsUDP.log(debugging);
  FinsUDP.listen(true);
  
  //0.4 Fins init
  fillFinsFrame(); //Fins frame vullen
  
  //0.5 Data handler init
  gdata[0]="";
  coords = new FloatList();
  coords.append(0.0); //X
  coords.append(0.0); //Y
  coords.append(0.0); //Z
  coords.append(0.0); //F
  coords.append(0.0); //E
  repetierSerial.write("//    Repetier2Fins bridge V4.1\r\n");
  repetierSerial.write("//    I1-PRO06, 2014\r\n");
  repetierSerial.write("//    Vergeet niet eerst schoon te maken! ^^\r\n");
  repetierSerial.write("ok\r\n");
}

//::::::::::::::::::::::::::::::::::::1 Hoofdloop:::::::::::::::::::::::::::::::::::::::::::::
void draw() {
  //1.1 GUI framework tekenen
  background(255);
  fill(0);
  image(logo,5,0);
  
  //1.2 Text voor debugging
  textSize(15);
  if (FinsUDP.port()==-1) text("FINS stopped:( - check MAC", 15, 160);
  else text("FINS ready: IP: "+ControllerIP+" UDP poort: " + FinsUDP.port(), 15, 160);
  textSize(18);
  text(comment,15, 200);
  readParseAscii();
}




