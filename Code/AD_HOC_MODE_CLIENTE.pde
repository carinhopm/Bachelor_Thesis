
// Include WIFI library 
#include <WaspWIFI.h>

#define ADHOC_ESSID "ANDROID"
#define NETMASK   "255.255.255.0"
#define GATEWAY   "192.168.1.1"
#define SERVER_IP "192.168.1.2"
#define CLIENT_IP "192.168.1.3"
#define SERVER_PORT 2000
#define CLIENT_PORT 3000
#define SERVER_TIMEOUT 90000
#define CLIENT_TIMEOUT 30000

uint8_t socket=SOCKET0;

// Specifies the message that is sent to the WiFi module. 
char tosend[128] = "PROBANDO PROBANDO...\0"; 

void setup()
{ 
  USB.println(F("turning WiFi module on...."));
  if (WIFI.ON(socket)) {
    USB.println(F("Turned on successfully ...."));
  } 
  else {
    USB.println(F("Not turned on successfully ...."));
  } 
  WIFI.resetValues();
  USB.println(F("setting max baud rate...."));
  WIFI.setBaudRate(115200);
  USB.println(F("setting tx rate of 54 Mbits/s...."));
  WIFI.setTXRate(15);
  USB.println(F("setting tx power...."));
  WIFI.setTXPower(0);
  USB.println(F("setting channel 6 for operations....")); 
  WIFI.setChannel(6); 
  USB.println(F("turning DHCP off...."));
  WIFI.setDHCPoptions(AUTO_IP);
//  USB.println(F("setting Gateway IP....")); 
//  WIFI.setGW(GATEWAY);
//  USB.println(F("setting netmask IP...."));
//  WIFI.setNetmask(NETMASK);
//  USB.println(F("setting node IP...."));
//  WIFI.setIp(CLIENT_IP);
  USB.println(F("setting Local port...."));
  WIFI.setLocalPort(CLIENT_PORT);
  USB.println(F("setting ESSID....")); 
  WIFI.setESSID(ADHOC_ESSID);
  USB.println(F("setting connection options...."));
  WIFI.setConnectionOptions(UDP);
  USB.println(F("setting authentication mode...."));
  WIFI.setAutojoinAuth(ADHOC);  
  USB.println(F("storing data in memory....")); 
  WIFI.storeData();
} 

void loop()
{ 
  USB.println(F("setting this node "));
  if(WIFI.setJoinMode(CREATE_ADHOC))
  {
    USB.println(F("joining successful...."));
    Utils.setLED(LED1, LED_ON);
    delay(1000);
    Utils.setLED(LED1, LED_OFF);

    WIFI.getConnectionInfo();
    USB.println(F("-------------------------------"));
    WIFI.getIP();
    USB.println(F("-------------------------------"));
    WIFI.getOptionSettings();
    USB.println(F("-------------------------------"));
    WIFI.getAdhocSettings();
    if(WIFI.isConnected())
      USB.println(F("CONNECTED!!"));
    else
      USB.println(F("NOT CONNECTED!!"));
    WIFI.sendPing(SERVER_IP);
    delay(5000);
  }
  else
    USB.println(F("joining unsuccessful....")); 
} 





      //    if (WIFI.setTCPclient("192.168.2.2",2000,2000))
      //    { 
      //      Utils.setLED(LED1, LED_ON);
      //      USB.println(F("sending data to module....")); 
      //      while(1)
      //      { 
      //        WIFI.send(tosend); 
      //        delay(80);
      //      } 
      //    }
      //    else
      //    {
      //      USB.println(F("TCP server NOT set"));
      //    }
