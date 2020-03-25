#include <WaspWIFI.h>
#include <WaspRTC.h>
#include <WaspSD.h>
#include <string.h>
#include <stdio.h>

#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define LOCAL_PORT 8050
#define TIMEOUT 90000
uint8_t socket = SOCKET0;
unsigned long previous;
char filename[] = "FILE3.TXT";
char message[513];
char waspmote1[5];
char waspmote2[5];
int num_waspmote1;
int num_waspmote2;
boolean checking;
boolean newMessage;


void setup() {

  // Configuración del RTC
  RTC.ON();
  RTC.setTime("27:05:17:07:12:00:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime()); 
  USB.println();

  // Configuración de variables
  delay(5000);
  memset(message, '\0', 23);
  strcpy(message, "_______________________");
  num_waspmote1 = 0;
  num_waspmote2 = 0;
  checking = false;
  newMessage = false;

  // Configuración tarjeta SD
  USB.ON();
  SD.ON();
  USB.println(F("USB & SD -> ON")); 
  USB.println();

  // Listado de archivos en tarjeta SD
  USB.println(F("List Root directory:"));
  USB.println(F("---------------------------"));
  SD.ls(LS_R|LS_DATE|LS_SIZE);  
  USB.println(F("---------------------------\n")); 
  USB.println();

  // Creación archivo registro de conexiones
  //sprintf(filename,"%02u%02u%02u.TXT", RTC.hour, RTC.minute, RTC.second);
  if (SD.create(filename)) {
    USB.print(F("File created with name: "));
    USB.println(filename); 
    USB.println();
    if (SD.appendln(filename, "Registro de conexiones establecidas:")) {
      USB.print(F("Showing file:"));
      SD.showFile(filename); 
      USB.println();
    } 
    else {
      USB.println(F("Write failed!!")); 
      USB.println();
      notifyByLEDS(true,0);
    }
  } 
  else {
    USB.println(F("File NOT created!!")); 
    USB.println();
    notifyByLEDS(true,0);
    USB.println(F("Showing existing file:"));
    SD.showFile(filename); 
    USB.println();
    USB.println(F("PROGRAM PAUSED FOR 5 MINUTES"));
    delay(300000);
  }

  // Configuración del módulo Wifi
  if( WIFI.ON(socket) == 1 ) {    
    USB.println(F("Wifi switched ON")); 
    USB.println();
  } 
  else {
    USB.println(F("Wifi did not initialize correctly"));
    USB.println();
  }
  WIFI.setConnectionOptions(CLIENT);
  WIFI.setConnectionOptions(CLIENT_SERVER); 
  WIFI.setDHCPoptions(DHCP_ON);
  WIFI.setJoinMode(MANUAL); 
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

  USB.println(F("SETUP COMPLETED")); 
  USB.println();

}


void loop() {

  // Configuración de la alarma 1
  RTC.setAlarm1("00:00:00:30",RTC_ABSOLUTE,RTC_ALM1_MODE4);
  USB.println();
  USB.print(F("Alarm1: "));
  USB.println(RTC.getAlarm1()); 
  USB.println();

  // Configuración de la alarma 2
  RTC.setAlarm2("00:00:30",RTC_ABSOLUTE,RTC_ALM2_MODE4);
  USB.println();
  USB.print(F("Alarm2: "));
  USB.println(RTC.getAlarm2()); 
  USB.println();

  // Interrupción 
  USB.println(F("Waspmote goes to sleep...")); 
  USB.println();
  PWR.sleep(ALL_OFF);  
  // ---------->WASPMOTE DORMIDO<----------
  RTC.ON();
  USB.ON();
  SD.ON();
  USB.println(F("Waspmote wakes up!")); 
  USB.println();

  if( intFlag & RTC_INT ) {

    //    if (RTC.alarmTriggered == 1) {
    //    } else if (RTC.alarmTriggered == 2) { }

    // Configuración de la interrupción
    intFlag &= ~(RTC_INT); // Limpiar flag
    USB.println(F("-------------------------"));
    USB.println(F("RTC INT Captured"));
    USB.println(F("-------------------------"));

    if( WIFI.ON(socket) == 1 ) {

      // Activación del servidor TCP
      USB.println(F("Wifi switched ON")); 
      USB.println();
      server_TCP();

    } 
    else {
      USB.println(F("Wifi did not initialize correctly"));
      USB.println();
    }

  }

}


void server_TCP() {

  WIFI.ON(socket);

  if (WIFI.join(ESSID)) {   
    USB.println(F("-----------------------"));    
    USB.println(F("get IP"));
    USB.println(F("-----------------------"));
    WIFI.getIP(); 
    USB.println();

    if (WIFI.setTCPserver(LOCAL_PORT)) { 
      USB.println(F("TCP server set"));
      USB.print(F("Listening for incoming data during "));
      USB.print(TIMEOUT);
      USB.println(F(" milliseconds"));

      previous=millis();
      while( millis()-previous<TIMEOUT ) { 

        // Lee mensajes de la conexión TCP
        WIFI.read(NOBLO); 
        if(WIFI.length>0 && WIFI.answer[2]=='M') {

          USB.println();
          USB.print(F("RX printed: "));
          for( int k=0; k<(WIFI.length); k++)
          {
            USB.print(WIFI.answer[k],BYTE);
            if (WIFI.answer[k]!=message[k]) {
              newMessage = true;
            }
          }
          if (newMessage==true) {
            memset(message, '\0', 31);
            strcpy(message, WIFI.answer);
            checking = true; 
            USB.println();
            break;
          }

        }
        // Condición para evitar un 'overflow' (NO BORRAR)
        if (millis() < previous) {
          previous = millis();	
        }
      }

      USB.println(F("Close the TCP connection")); 
      WIFI.close(); 
      USB.println();

      // Registro de la conexión en el archivo .TXT
      USB.print(F("Message: "));
      USB.println(message); 
      USB.println();
      if(checking==true && SD.append(filename,message)) {
        SD.append(filename, " - Conexion numero: ");
        if (message[3]=='4') {
          num_waspmote1++;
          Utils.long2array(num_waspmote1,waspmote1);
          SD.appendln(filename,waspmote1);
        } 
        else if (message[3]=='3') {
          num_waspmote2++;
          Utils.long2array(num_waspmote2,waspmote2);
          SD.appendln(filename,waspmote2);
        }
        USB.print(F("Data registered: "));
        USB.println(message); 
        USB.println();
        notifyByLEDS(false,10);
        USB.print(F("Showing file:"));
        SD.showFile(filename); 
        USB.println();
      } 
      else {
        USB.println(F("ERROR: Data NOT registered!!")); 
        USB.println();
        notifyByLEDS(true,0);
      }

    } 
    else {
      USB.println(F("TCP server NOT set"));
      notifyByLEDS(true,0);
    }
  } 
  else {
    USB.println(F("NOT Connected to AP"));
  }

  WIFI.OFF();
  USB.println(F("*************************"));
  checking = false;
  newMessage = false;
  delay(3000);

}


void notifyByLEDS(boolean error, int times) {
  if (error) {
    Utils.blinkRedLED(250, 5);
  } 
  else {
    Utils.blinkGreenLED(500, times);
  }
}



