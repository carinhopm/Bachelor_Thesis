#include <WaspWIFI.h>
#include <WaspRTC.h>
#include <string.h>
#include <stdio.h>

#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define IP_ADDRESS "192.168.1.56"
#define REMOTE_PORT 8050
#define LOCAL_PORT 3000
#define TIMEOUT 10000
uint8_t socket=SOCKET0;
unsigned long previous;
char data[31];


void setup() {
  
  // Configuración del RTC
  RTC.ON();
  RTC.setTime("27:05:17:07:12:00:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime()); USB.println();

  // Configuración del módulo Wifi
  if( WIFI.ON(socket) == 1 ) {
    USB.println(F("Wifi switched ON")); USB.println();
  } 
  else {
    USB.println(F("Wifi did not initialize correctly")); USB.println();
  }
  WIFI.setConnectionOptions(CLIENT); 
  WIFI.setDHCPoptions(DHCP_ON);    
  WIFI.setJoinMode(MANUAL); 
  WIFI.setAuthKey(WPA2,AUTHKEY);
  WIFI.storeData();  

  USB.println(F("SETUP COMPLETED"));
}


void loop() {

//  // Configuración de la alarma (versión 1)
//  RTC.setAlarm1("00:00:00:50",RTC_ABSOLUTE,RTC_ALM1_MODE4);
//  USB.println(); USB.print(F("Alarm1: "));
//  USB.println(RTC.getAlarm1());
  
  // Configuración de la alarma (versión 2)
  RTC.setAlarm1("00:00:30:10",RTC_ABSOLUTE,RTC_ALM1_MODE4);
  USB.println(); USB.print(F("Alarm1: "));
  USB.println(RTC.getAlarm1());

  // Interrupción 
  USB.println(F("Waspmote goes to sleep...")); USB.println();
  PWR.sleep(ALL_OFF);
  // ---------->WASPMOTE DORMIDO<----------
  RTC.ON();
  USB.ON();
  USB.println(F("Waspmote wakes up!")); USB.println();

  if( intFlag & RTC_INT ) {

    // Configuración de la interrupción
    intFlag &= ~(RTC_INT); // Limpiar flag
    USB.println(F("-------------------------"));
    USB.println(F("RTC INT Captured"));
    USB.println(F("-------------------------")); USB.println();

    if( WIFI.ON(socket) == 1 ) {
      USB.println(F("Wifi switched ON")); USB.println();
    } 
    else {
      USB.println(F("Wifi did not initialize correctly")); USB.println();
    }

    // Activación del servidor TCP
    client_TCP();

  }  

}


void client_TCP() {

  WIFI.ON(socket);

  if (WIFI.join(ESSID)) {
    USB.println(F("Joined AP"));
    WIFI.getIP();

    if (WIFI.setTCPclient(IP_ADDRESS, REMOTE_PORT, LOCAL_PORT)) { 
      USB.println(F("TCP client set"));
      notifyByLEDS(false,3);
      USB.print(F("Sending data: "));
      memset(data, '\0', 31);
      strcpy(data, "COM3 -> ");
      strcat(data, RTC.getTime());
      USB.println(data);
      WIFI.send(data);

      USB.println(F("Listen to TCP socket:"));
      previous=millis();
      while(millis()-previous<TIMEOUT) {
        if(WIFI.read(NOBLO)>0) {
          for(int j=0; j<WIFI.length; j++) {
            USB.print(WIFI.answer[j],BYTE);
          }
          USB.println();
        }

        // Condición para evitar un 'overflow' (NO BORRAR)
        if (millis() < previous) {
          previous = millis();	
        }
      }

      USB.println(F("Close TCP socket"));
      WIFI.close(); 
    } 
    else {
      USB.println(F("TCP client NOT set"));
      notifyByLEDS(true,0);
    }
    WIFI.leave();
  } 
  else {
    USB.println(F("NOT Connected to AP"));
  }

  WIFI.OFF();  
  USB.println(F("****************************"));
  delay(3000);

}


void notifyByLEDS(boolean error, int times) {
  if (error) {
    Utils.blinkRedLED(250, 5);
  } else {
    Utils.blinkGreenLED(500, times);
  }
}

