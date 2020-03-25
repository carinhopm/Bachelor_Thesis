/*  
 *  ------ Conexión básica entre Waspmotes (Cliente) -------- 
 *  
 *  Explicación:
 *  
 *  Autor: Carlos Parra Marcelo
 */
 
#include <WaspWIFI.h>

uint8_t socket=SOCKET0;
#define IP_ADDRESS "192.168.1.52"
#define REMOTE_PORT 2000
#define LOCAL_PORT 3000
//#define ESSID "MundialRooms2"
//#define AUTHKEY "Mundial2"
#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define TIMEOUT 10000
unsigned long previous;


void setup() {
  
  // Configuración del módulo Wifi
  if( WIFI.ON(socket) == 1 ) {
    USB.println(F("Wifi switched ON"));
  } else {
    USB.println(F("Wifi did not initialize correctly"));
  }
  WIFI.setConnectionOptions(CLIENT); 
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
  RTC.setAlarm1("00:00:00:50",RTC_ABSOLUTE,RTC_ALM1_MODE4);
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
    client_TCP();
    
  }  
}


void client_TCP() {
  
  Utils.blinkLEDs(1000);
  delay(2000);
  Utils.blinkLEDs(1000);  

  WIFI.ON(socket);

  if (WIFI.join(ESSID)) {
      USB.println(F("Joined AP"));
      Utils.setLED(LED0, LED_ON);
      delay(1000);
      Utils.setLED(LED0, LED_OFF);
      WIFI.getIP();

      if (WIFI.setTCPclient(IP_ADDRESS, REMOTE_PORT, LOCAL_PORT)) { 
          USB.println(F("TCP client set"));
          Utils.setLED(LED1, LED_ON);
          delay(1000);
          Utils.setLED(LED1, LED_OFF);

          WIFI.send("TCP - Hi from Waspmote through Wifi!\r\n"); 

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
      } else {
          USB.println(F("TCP client NOT set"));
      }
      WIFI.leave();
  } else {
      USB.println(F("NOT Connected to AP"));
  }

  WIFI.OFF();  
  USB.println(F("****************************"));
  delay(3000);
  
}
