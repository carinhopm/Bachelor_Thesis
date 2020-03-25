/*
 *  ------Waspmote WIFI_26 Example--------
 *
 *  Explanation: This example shows how to send a HTTP get request 
 *  message. 
 *
 *  Copyright (C) 2014 Libelium Comunicaciones Distribuidas S.L.
 *  http://www.libelium.com
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 2 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Version:                0.4
 *  Design:                 David Gascón
 *  Implementation:         Joaquin Ruiz, Yuri Carmona
 */

// Include WIFI library 
#include <WaspWIFI.h>

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket=SOCKET0;
///////////////////////////////////////

// WiFi AP settings (CHANGE TO USER'S AP)
/////////////////////////////////
#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define STATIC_IP "192.168.1.56"
#define NETMASK   "255.255.255.0"
#define GATEWAY   "192.168.1.1"
#define LOCAL_PORT 8050
#define TIMEOUT 30000
/////////////////////////////////

// WEB server settings 
/////////////////////////////////
//char HOST[] = "carlinhopm.esy.es";
//char URL[]  = "GET$/config.php?";
char HOST[] = "carlinhopm21.000webhostapp.com";
char URL[]  = "GET$/config.php?";
/////////////////////////////////


// define variable for communication status
char name[] = "COM6";
char config[513];
uint8_t status;
uint8_t counter=0;
char body[100];
unsigned long previous;


void setup()
{
  if( WIFI.ON(socket) == 1 )
  {    
    USB.println(F("WiFi switched ON"));
  }
  else
  {
    USB.println(F("WiFi did not initialize correctly"));
  }

  // reset to avoid previous configuration stored in the module
  //WIFI.resetValues();

  // 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...)
  WIFI.setConnectionOptions(HTTP|CLIENT_SERVER);
  // 2. Configure the way the modules will resolve the IP address.
  WIFI.setDHCPoptions(DHCP_OFF);
  WIFI.setIp(STATIC_IP);
  WIFI.setNetmask(NETMASK);
  WIFI.setGW(GATEWAY);
  // 3. Configure how to connect the AP 
  WIFI.setJoinMode(MANUAL);   
  // 4. Set the AP authentication key
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  // 5. Save Data to module's memory
  WIFI.storeData();
  
  
  USB.println(F("Set up done"));
}


void loop()
{ 
  // Switch ON the WiFi module on the desired socket
  if( WIFI.ON(socket) == 1 )
  {    
    USB.println(F("WiFi switched ON"));
  }
  else
  {
    USB.println(F("WiFi did not initialize correctly"));
  }

  // If it is manual, call join giving the name of the AP     
  if( WIFI.join(ESSID) )
  { 
    USB.println(F("Joined"));
    
    WIFI.getIP();

    /////////////////////////////////////////// 
    // Create the HTTP body with sensor data
    ///////////////////////////////////////////  
    RTC.ON();
    RTC.getTime();
    counter++;
    snprintf( body, sizeof(body), "nombre=%s", name);
    //"counter=%u&hour=%02u&minute=%02u&second=%02u", counter, RTC.hour,  RTC.minute,  RTC.second );

    USB.print(F("body:"));
    USB.println(body);

    /////////////////////////////////////////// 
    // Send the HTTP get/post query (specifying the WEB server so DNS is used)
    /////////////////////////////////////////// 
    status = WIFI.getURL(DNS, HOST, URL, body);

    if( status == 1)
    {
          USB.println(F("\nHTTP query OK."));
          
          strcpy(config, WIFI.answer);
          USB.print(F("WIFI.answer: "));
          USB.println(WIFI.answer);
          
          for( int k=0; k<513; k++) {
            if (config[k]=='&') {
              k = k + 7;
              if (config[k]=='s') {
                USB.println(F("\nSERVER MODE selected"));
                break;
              } else if (config[k]=='n') {
                USB.println(F("\nCLIENT MODE selected"));
                break;
              } else {
                USB.println(F("\nERROR READING THE ANSWER"));
                delay(300000);
              }
            }
          }
       
       // &admin=no&ipServ=11.111.11.111&puertoServ=4400&conexServ=2*CLOS*
       // &admin=si&minConex=2&minConex=32*CLOS*
    
    }
    else
    {
      USB.println(F("\nHTTP query ERROR"));
      counter--; 
    }
  } 
  else
  {
    USB.println(F("NOT joined"));
  }
  
  
  // switch off module 
  WIFI.OFF();  
  USB.println(F("***************************"));  
  delay(1000);
} 


