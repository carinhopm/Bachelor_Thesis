/*  
 *  ------ Waspmote Pro Code Example -------- 
 *  
 *  Explanation: This is the basic Code for Waspmote Pro
 *  
 *  Copyright (C) 2013 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify  
 *  it under the terms of the GNU General Public License as published by  
 *  the Free Software Foundation, either version 3 of the License, or  
 *  (at your option) any later version.  
 *   
 *  This program is distributed in the hope that it will be useful,  
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of  
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
 *  GNU General Public License for more details.  
 *   
 *  You should have received a copy of the GNU General Public License  
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  
 */
     
// Put your libraries here (#include ...)
#include <WaspWIFI.h>
#include <WaspRTC.h>
#include <string.h>
#include <stdio.h>

#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define SERVER_PORT 2000
#define CLIENT_PORT 3000
#define SERVER_TIMEOUT 90000
#define CLIENT_TIMEOUT 30000
//#define SERVER_IP "192.168.1.57"
//#define STATIC_IP "192.168.1.56"
//#define NETMASK   "255.255.255.0"
//#define GATEWAY   "192.168.1.1"

uint8_t socket = SOCKET0;
uint8_t status;
uint16_t myPort;
uint16_t myServerPort;
unsigned long previous;
char HOST[] = "carlinhopm.esy.es";
char urlConfig[] = "GET$/config.php?";
char urlData[] = "GET$/dataServer.php?";
char name[] = "COM4";
char clientName[6];
char myIP[15];
char myServerIP[15];
char myAlarm[4];
char alarm1[4];
char alarm2[4];
char receiver[513];
char message[507];
char body[600];
char config[513];
int numAlarms;
int numMessages;
boolean serverMode;
boolean messageReceived;


void setup() {
  
  messageReceived = false;
  
//  //SERVER
////  strcpy(myIP, "192.168.1.56");
////  myPort = 8050;
//  serverMode = true;
//  numAlarms = 1;
  
  //CLIENT
//  strcpy(myIP, "192.168.1.52");
//  myPort = 3000;
  strcpy(myServerIP, "192.168.1.56");
//  myServerPort = 8050;
  serverMode = false;

  if (WIFI.ON(socket)==1) {    
    USB.println(F("WiFi switched ON"));
  } 
  else {
    USB.println(F("WiFi did not initialize correctly"));
    notifyByLEDS(true,0);
  }

  WIFI.resetValues();
  if (serverMode==true) {
    WIFI.setConnectionOptions(CLIENT_SERVER);
  } else {
    WIFI.setConnectionOptions(CLIENT);
  }
  WIFI.setDHCPoptions(DHCP_ON);
//  WIFI.setIp(myIP);
//  WIFI.setNetmask(NETMASK);
//  WIFI.setGW(GATEWAY);
//  WIFI.setLocalPort(myPort);
//  if (serverMode==false) {
//    WIFI.setRemoteHost(myServerIP,myServerPort);
//  }
  WIFI.setJoinMode(MANUAL);   
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

  USB.println(F("\nSETUP COMPLETED\n"));

}


void loop() {
  
  if( WIFI.ON(socket) == 1 ) {

    // Activación del servidor TCP
    USB.println(F("Wifi switched ON\n")); 

    if (serverMode==true && numAlarms>0) {
      server();
      if (messageReceived) {
        sendMessageToServer();
        messageReceived = false;
      }
    } 
    else if (serverMode==false) {
      delay(18000);
      client();
    }

  } 
  else {
    USB.println(F("Wifi did not initialize correctly\n"));
    notifyByLEDS(true,0);
  }

}


void server() {

  if (WIFI.join(ESSID)) {
    notifyByLEDS(false,3);   
    USB.println(F("-----------------------"));    
    USB.println(F("get IP"));
    USB.println(F("-----------------------\n"));
    WIFI.getIP();

    if (WIFI.setTCPserver(SERVER_PORT)) { 
      notifyByLEDS(false,4);
      USB.println(F("TCP server set"));
      USB.print(F("Listening for incoming data during "));
      USB.print(TIMEOUT);
      USB.println(F(" milliseconds"));

      previous=millis();
      while( millis()-previous<TIMEOUT ) { 

        // Lee mensajes de la conexión TCP
        WIFI.read(NOBLO); 
        if(WIFI.length>0 && WIFI.answer[2]=='M') {

          notifyByLEDS(false,6);
          messageReceived = true;
          strcpy(receiver, WIFI.answer);
          WIFI.send("&OK");

          USB.print(F("\nIncoming message from "));
          for (int k=0; k<3; k++) {
            USB.print(receiver[k]);
            clientName[k] = receiver[k];
          }

          numMessages = receiver[5] - '0';
          int prov5 = 0;

          //for (int x = 0; x<numMessages; x++) {
          USB.print(F("\nMessage received: "));
          for (int k=8; k<513; k++) {
            if (receiver[k]=='/' && receiver[k+1]=='0') {
              memset(message, '\0', prov5);
              break;
            }
            USB.print(receiver[k]);
            message[prov5] = receiver[k];
            prov5++;
          }
          //}

        }
        // Condición para evitar un 'overflow' (NO BORRAR)
        if (millis() < previous) {
          previous = millis();	
        }
      }

      USB.println(F("Close the TCP connection (WiFi switched OFF)\n")); 
      WIFI.close();

    } 
    else {
      USB.println(F("TCP server NOT set\n"));
      notifyByLEDS(true,0);
    }
    WIFI.leave();

  } 
  else {
    USB.println(F("NOT Connected to AP\n"));
    notifyByLEDS(true,0);
  }

  WIFI.OFF();
  USB.println(F("*************************"));
  delay(60000);

}


void client() {

  if (WIFI.join(ESSID)) {
    USB.println(F("Joined AP"));
    notifyByLEDS(false,3);
    WIFI.getIP();

    if (WIFI.setTCPclient(myServerIP, SERVER_PORT, CLIENT_PORT)) { 
      notifyByLEDS(false,4);
      USB.println(F("TCP client set"));
      notifyByLEDS(false,3);
      USB.print(F("Sending data: "));
      snprintf(body, sizeof(body), "%s&1->Datos recopilados a las %s/0", name, RTC.getTime());
      USB.println(body);
      WIFI.send(body);

      USB.println(F("Listen to TCP socket:"));
      previous=millis();
      while(millis()-previous<TIMEOUT) {
        if(WIFI.read(NOBLO)>0) {
          for (int k = 0; k<(WIFI.length); k++) {
            if (WIFI.answer[k]=='&' && WIFI.answer[k+1]=='O' && WIFI.answer[k+2]=='K') {
              USB.println(F("OK -> Data sent correctly!!\n"));
              notifyByLEDS(false,6);
              break;
            }
          }
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
    notifyByLEDS(true,0);
  }

  WIFI.OFF();  
  USB.println(F("****************************"));

}


void sendMessageToServer() {

  if (WIFI.ON(socket)==1) {    
    USB.println(F("WiFi switched ON"));
  } 
  else {
    USB.println(F("ERROR -> WiFi did not initialize correctly"));
    notifyByLEDS(true,0); 
    USB.println();
  }

  if (WIFI.join(ESSID)) {

    USB.println(F("Joined"));
    notifyByLEDS(false,3);
    snprintf(body, sizeof(body), "nombre=%s&datos=%s", name, message);

    USB.println(F("Conecting to server..."));
    USB.print(F("GET: "));
    USB.println(body);
    status = WIFI.getURL(DNS, HOST, urlData, body);

    if (status==1) {
      USB.println(F("\nHTTP query OK\n"));
      notifyByLEDS(false,6);
      for (int k = 0; k<(WIFI.length); k++) {
        if (WIFI.answer[k]=='&') {
          USB.println(WIFI.answer);
          break;
        }
      }
    } 
    else {
      USB.println(F("\nHTTP query ERROR"));
      notifyByLEDS(true,0); 
    }

  } 
  else {
    USB.println(F("NOT Connected to AP\n"));
    notifyByLEDS(true,0);
  }

  WIFI.OFF();
  USB.println(F("WiFi switched OFF"));

}


void notifyByLEDS(boolean error, int times) {
  if (error) {
    Utils.blinkRedLED(250, 5);
  } 
  else {
    Utils.blinkGreenLED(500, times);
  }
}

