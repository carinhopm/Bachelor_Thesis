#include <WaspWIFI.h>
#include <string.h>
#include <stdio.h>

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket=SOCKET0;
///////////////////////////////////////

// WiFi AP settings (CHANGE TO USER'S AP)
/////////////////////////////////
#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
/////////////////////////////////

// TCP server settings
/////////////////////////////////
#define LOCAL_PORT 2000
/////////////////////////////////

// define time to be listening
#define TIMEOUT 60000
unsigned long previous;

char message[513];


void setup()
{
  wifi_setup();  
}

void loop()
{
  
  // switch Wifi module ON
  WIFI.ON(socket);

  // join Access Point
  if (WIFI.join(ESSID)) 
  {   
    USB.println(F("-----------------------"));    
    USB.println(F("get IP"));
    USB.println(F("-----------------------"));
    WIFI.getIP();
    USB.println();


    // Call the function to create a TCP connection on port 2000 
    if (WIFI.setTCPserver(LOCAL_PORT)) 
    { 
      USB.println(F("TCP server set"));

      // Listen for a while
      USB.print(F("Listening for incoming data during "));
      USB.print(TIMEOUT);
      USB.println(F(" milliseconds"));

      previous=millis();
      while( millis()-previous<TIMEOUT ) 
      {
        // Reads from the TCP connection 
        WIFI.read(NOBLO); 
        if(WIFI.length>0)
        {

          USB.println(F("RX printed: "));
          for( int k=0; k<(WIFI.length); k++)
          {
            USB.print(WIFI.answer[k],BYTE);
          }
          memset(message, '\0', sizeof(message));
          strcpy(message, WIFI.answer);
          
        }
        // Condition to avoid an overflow (DO NOT REMOVE)
        if (millis() < previous)
        {
          previous = millis();	
        }
      }
      // Closes the TCP connection.
      USB.println(F("Close the TCP connection")); 
      WIFI.close(); 
    } 
    else
    {
      USB.println(F("TCP server NOT set"));
    }
  }
  else
  {
    USB.println(F("NOT Connected to AP"));
  }

  // Switch Wifi module off
  WIFI.OFF();
  USB.println();
  USB.printf("Datos guardados en SD: %s\n", message);
  USB.println(F("*************************"));
  delay(3000);  
} 




/**********************************
 *
 *  wifi_setup - function used to 
 *  configure the WIFI parameters 
 *
 ************************************/
void wifi_setup()
{
  
  // Switch ON the WiFi module on the desired socket
  if( WIFI.ON(socket) == 1 )
  {    
    USB.println(F("Wifi switched ON"));
  }
  else
  {
    USB.println(F("Wifi did not initialize correctly"));
  }

  // 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...) 
  WIFI.setConnectionOptions(CLIENT_SERVER); 
  // 2. Configure the way the modules will resolve the IP address. 
  WIFI.setDHCPoptions(DHCP_ON);    

  // 3. Configure how to connect the AP 
  WIFI.setJoinMode(MANUAL); 

  // 4. Set Authentication key
  WIFI.setAuthKey(WPA2,AUTHKEY); 

  // 5. Store values
  WIFI.storeData();
  USB.println(F("Setup completed"));

}
