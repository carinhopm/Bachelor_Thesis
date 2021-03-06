/*  
 *  ------ Conexión básica entre Waspmotes (Servidor) -------- 
 *  
 *  Explicación:
 *  
 *  Autor: Carlos Parra Marcelo
 */
 
#include <WaspWIFI.h>

uint8_t socket = SOCKET0;
//#define ESSID "MundialRooms2"
//#define AUTHKEY "Mundial2"
#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define LOCAL_PORT 2000
#define TIMEOUT 60000
unsigned long previous;

void setup() {
  
  // Configuración del módulo Wifi
  if( WIFI.ON(socket) == 1 ) {    
    USB.println(F("Wifi switched ON"));
  } else {
    USB.println(F("Wifi did not initialize correctly"));
  }
  WIFI.setConnectionOptions(CLIENT);
  WIFI.setConnectionOptions(CLIENT_SERVER); 
  WIFI.setDHCPoptions(DHCP_ON);
  WIFI.setJoinMode(MANUAL); 
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();
  
  // Configuración del RTC
  RTC.ON();
  RTC.setTime("17:04:10:01:20:00:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime());
  
  USB.println(F("Setup completed"));
  
}


void loop() {
  
  // Configuración de la alarma
  RTC.setAlarm1("00:00:00:30",RTC_ABSOLUTE,RTC_ALM1_MODE4);
  USB.print(F("Alarm1: "));
  USB.println(RTC.getAlarm1());
  
  // Interrupción 
  USB.println(F("Waspmote goes to sleep..."));
  PWR.sleep(ALL_OFF);  
  USB.println(F("Waspmote wakes up!"));
  
  USB.ON();
  
  if( intFlag & RTC_INT ) {
    
    // Configuración de la interrupción
    intFlag &= ~(RTC_INT); // Limpiar flag
    USB.println(F("-------------------------"));
    USB.println(F("RTC INT Captured"));
    USB.println(F("-------------------------"));
    Utils.setLED(LED0, LED_ON);
    delay(1000);
    Utils.setLED(LED0, LED_OFF);
    
    if( WIFI.ON(socket) == 1 ) {    
      USB.println(F("Wifi switched ON"));
    } else {
      USB.println(F("Wifi did not initialize correctly"));
    }
    
    // Activación del servidor TCP
    server_TCP();
    
  }  
}


void server_TCP() {
  
  Utils.blinkLEDs(1000);
  delay(1000);
  Utils.blinkLEDs(1000);
  
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
        WIFI.read(NOBLO); 
        if(WIFI.length>0) {
          USB.print(F("RX: "));
          for( int k=0; k<WIFI.length; k++) {
            USB.print(WIFI.answer[k],BYTE);
          }
          USB.println(); 
        }
        // Condición para evitar un 'overflow' (NO BORRAR)
        if (millis() < previous) {
          previous = millis();	
        }
      }

      USB.println(F("Close the TCP connection")); 
      WIFI.close(); 
    } else {
      USB.println(F("TCP server NOT set"));
    }
  } else {
    USB.println(F("NOT Connected to AP"));
  }

  WIFI.OFF();
  USB.println(F("*************************"));
  delay(3000);
  
}
