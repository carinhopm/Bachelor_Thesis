/*  
 *  TÍTULO: Red de Transferencia de Datos Configurable para Waspmotes
 *  
 *  AUTOR: Carlos Parra Marcelo
 *  
 *  EXPLICACIÓN BREVE: Este código realiza descarga de una base de datos los parámetros
 *                     necesarios para la configuración de una red de waspmotes en la que
 *                     los clientes enviarán los datos a un servidor que, a su vez,
 *                     se ocupará de registrarlos en la base de datos correspondiente.
 *    
 */


// BIBLIOTECAS INCLUÍDAS
#include <WaspWIFI.h>
#include <WaspRTC.h>
#include <string.h>
#include <stdio.h>

// CONSTANTES GLOBALES
#define ESSID "MOVISTAR_1155"
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ"
#define NETMASK   "255.255.255.0"
#define GATEWAY   "192.168.1.1"
#define SERVER_PORT 2000
#define CLIENT_PORT 3000
#define SERVER_TIMEOUT 90000
#define CLIENT_TIMEOUT 30000

// VARIABLES GLOBALES
uint8_t socket = SOCKET0;
uint8_t status;
unsigned long previous;
char HOST[] = "carlinhopm.esy.es";
char urlConfig[] = "GET$/config.php?";
char urlData[] = "GET$/dataServer.php?";
char name[] = "COM4";  //<-----------------INTRODUCIR NOMBRE
char clientName[6];
char myIP[15];
char myServerIP[15];
char myAlarm[4];
char alarm1[4];
char alarm2[4];
char receiver[513];
char message[507];
char oldMessage[507];
char body[600];
char config[513];
int numAlarms;
int numMessages;
boolean serverMode;
boolean messageReceived;


// AJUSTES INICIALES
void setup() {

  USB.println(F("STARTING PROGRAM ---> Setup:"));

  // Configuración del RTC
  RTC.ON();
  RTC.setTime("04:07:17:03:12:00:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime());

  // Configuración del módulo Wifi (conexión HTTP)
  if (WIFI.ON(socket)==1) {    
    USB.println(F("\nWifi switched ON\n"));

    WIFI.resetValues();
    WIFI.setConnectionOptions(HTTP); 
    WIFI.setDHCPoptions(DHCP_ON);
    WIFI.setJoinMode(MANUAL); 
    WIFI.setAuthKey(WPA2,AUTHKEY);
    WIFI.storeData();

    // Descarga de datos actualizados
    connectionConfig();
    messageReceived = false;
    numMessages = 1;

    // Configuración del módulo Wifi (conexión TCP)
    WIFI.resetValues();
    if (serverMode==true) {
      WIFI.setConnectionOptions(CLIENT_SERVER); 
    } 
    else {
      WIFI.setConnectionOptions(CLIENT);
    }
    WIFI.setDHCPoptions(DHCP_OFF);
    WIFI.setIp(myIP);
    WIFI.setNetmask(NETMASK);
    WIFI.setGW(GATEWAY);
    WIFI.setJoinMode(MANUAL);   
    WIFI.setAuthKey(WPA2,AUTHKEY); 
    WIFI.storeData();

    USB.println(F("\nSETUP COMPLETED\n"));
  } 
  else {
    USB.println(F("ERROR -> Wifi did not initialize correctly"));
    notifyByLEDS(true,0); 
    USB.println();
    USB.println(F("PROGRAM STOPPED -> Restart waspmote and try again!!"));
    USB.println(F("***************************"));
    while(1){
    };
  }
}


// RUTINA PRINCIPAL
void loop() {

  // Modo Servidor
  if (serverMode==true && numAlarms>0) {

    // Configuración de la alarma 1
    char settingAlarm1[11];
    strcpy(settingAlarm1,"00:00:");
    strcat(settingAlarm1,alarm1);
    strcat(settingAlarm1,":00");
    RTC.setAlarm1(settingAlarm1,RTC_ABSOLUTE,RTC_ALM1_MODE4);
    USB.printf("\nAlarm1: %s\n", RTC.getAlarm1());

    if (numAlarms>1) {

      // Configuración de la alarma 2
      char settingAlarm2[8];
      strcpy(settingAlarm2,"00:00:");
      strcat(settingAlarm2,alarm2);
      RTC.setAlarm2(settingAlarm2,RTC_ABSOLUTE,RTC_ALM2_MODE4);
      USB.printf("\nAlarm2: %s\n", RTC.getAlarm2());

    }
  }

  // Modo Cliente
  else if (serverMode==false) {

    // Configuración de la alarma 1
    char settingAlarm1[11];
    strcpy(settingAlarm1,"00:00:");
    strcat(settingAlarm1,myAlarm);
    strcat(settingAlarm1,":00");
    RTC.setAlarm1(settingAlarm1,RTC_ABSOLUTE,RTC_ALM1_MODE4);
    USB.printf("\nAlarm1: %s\n", RTC.getAlarm1());

  } 
  else {
    USB.println(F("No function expected"));
  }

  // Waspmote en Modo Sleep
  USB.println(F("Waspmote goes to sleep...\n"));
  notifyByLEDS(false,2); 
  PWR.sleep(ALL_OFF);

  // ---------->SLEEP MODE<-----------

  // Configuración de módulos tras Modo Sleep
  RTC.ON();
  USB.ON();
  USB.println(F("Waspmote wakes up!!\n")); 

  // Configuración post-interrupción
  if( intFlag & RTC_INT ) {

    intFlag &= ~(RTC_INT); // Limpiar flag
    USB.println(F("-------------------------"));
    USB.println(F("RTC INT Captured"));
    USB.println(F("-------------------------"));

    // Módulo Wifi ON
    if( WIFI.ON(socket) == 1 ) {

      USB.println(F("Wifi switched ON\n")); 

      // Modo Servidor
      if (serverMode==true && numAlarms>0) {
        server();
        if (messageReceived) {
          sendMessageToServer();
          messageReceived = false;
        }
      }

      // Modo Cliente
      else if (serverMode==false) {
        delay(15000);  // Espera para la configuración del servidor TCP
        client();
        messageReceived = false;
      }

    } 
    else {
      USB.println(F("Wifi did not initialize correctly\n"));
      notifyByLEDS(true,0);
    }

  }
}


// DESCARGA Y GUARDADO DE LOS DATOS PROCEDENTES DEL HOST
void connectionConfig() {

  // Conexión a la red Wifi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined\n"));
    notifyByLEDS(false,4);
    WIFI.getIP();

    // Configuración de la consulta al host
    snprintf(body, sizeof(body), "nombre=%s", name);
    USB.println(F("Conecting to server..."));
    USB.print(F("GET: "));
    USB.println(body);

    // Consulta al host
    do {
      status = WIFI.getURL(DNS, HOST, urlConfig, body);
    } 
    while (status!=1);

    if (status==1) {

      USB.println(F("\nHTTP query OK."));
      notifyByLEDS(false,6);

      // Respuesta del host
      strcpy(config, WIFI.answer);
      USB.println(F("\nHOST ANSWER:"));
      USB.println(WIFI.answer);

      // Procesamiento de datos recibidos
      for (int k=0; k<(WIFI.length); k++) {
        if (config[k]=='&') {
          k = k + 7;

          // Modo Servidor -> Ejemplo: "&admin=si&ip=192.168.1.56&minConex=02&minConex=32&"
          if (config[k]=='s') {

            USB.println(F("\nSERVER MODE selected"));
            serverMode = true;

            // Nueva dirección IP
            k = IPConfig(k);
            numAlarms = 0;

            // Alarma 1
            if (config[k+1]=='m' && config[k+4]=='C') {
              k = k + 10;
              numAlarms++;
              if (config[k+1]=='&') {
                alarm1[0] = '0';
                alarm1[1] = config[k];
                k = k + 1;
              } 
              else {
                alarm1[0] = config[k];
                alarm1[1] = config[k+1];
                k = k + 2;
              }
              USB.printf("Alarm 1: at %s minutes every hour\n", alarm1);

              // Alarma 2
              if (config[k+1]=='m' && config[k+4]=='C') {
                k = k + 10;
                numAlarms++;
                if (config[k+1]=='&') {
                  alarm2[0] = '0';
                  alarm2[1] = config[k];
                } 
                else {
                  alarm2[0] = config[k];
                  alarm2[1] = config[k+1];
                }
                USB.printf("Alarm 2: at %s minutes every hour\n", alarm2);

              }
              USB.printf("\nNumber of alarms to set: %d\n", numAlarms);
            }

            else {
              USB.println(F("There aren't other waspmotes in the database"));
            }

            break;
          }

          // Modo Cliente -> Ejemplo: "&admin=no&ip=192.168.1.56&ipServ=192.168.1.58&conexServ=02&"
          else if (config[k]=='n') {

            USB.println(F("\nCLIENT MODE selected"));
            serverMode = false;

            // Nueva dirección IP
            k = IPConfig(k);

            // Dirección IP del servidor
            if (config[k+1]=='i' && config[k+3]=='S') {
              k = k + 8;
              int prov3 = 0;
              while (config[k]!='&') {
                myServerIP[prov3] = config[k];
                k++; 
                prov3++;
              }
              USB.print(F("Server IP: "));
              USB.println(myServerIP);
              k = k + 11;

              // Alarma para la conexión con el servidor
              if (config[k+1]=='&') {
                myAlarm[0] = '0';
                myAlarm[1] = config[k];
              } 
              else {
                myAlarm[0] = config[k];
                myAlarm[1] = config[k+1];
              }
              USB.printf("Alarm time: at %s minutes every hour\n", myAlarm);

            } 
            else {
              USB.println(F("No server setted"));
            }
            break;
          }

          else {
            USB.println(F("\nERROR READING THE ANSWER"));
            notifyByLEDS(true,0);
            break;
          }
        }
      }
    }

    else {
      USB.println(F("\nHTTP query ERROR"));
      notifyByLEDS(true,0); 
    }
  }

  else {
    USB.println(F("NOT joined"));
    notifyByLEDS(true,0);
  }

}


// CONEXIÓN TCP PARA EL MODO SERVIDOR
void server() {

  // Conexión a la red Wifi
  if (WIFI.join(ESSID)) {

    notifyByLEDS(false,3);   
    USB.println(F("-----------------------"));    
    USB.println(F("get IP"));
    USB.println(F("-----------------------\n"));
    WIFI.getIP();

    // Establecimiento del servidor TCP
    if (WIFI.setTCPserver(SERVER_PORT)) {

      notifyByLEDS(false,4);
      USB.println(F("TCP server set"));
      USB.print(F("Listening for incoming data during "));
      USB.print(SERVER_TIMEOUT);
      USB.println(F(" milliseconds"));

      // Tiempo de espera para la recepción de datos
      previous=millis();
      while( millis()-previous<SERVER_TIMEOUT ) { 

        // Lectura de mensajes de la conexión TCP
        WIFI.read(NOBLO);

        // Procesamiento de los mensajes recibidos
        if(WIFI.length>0 && WIFI.answer[2]=='M') {

          notifyByLEDS(false,6);
          messageReceived = true;

          // Envío de confirmación de la recepción de los datos al cliente TCP
          strcpy(receiver, WIFI.answer);
          WIFI.send("&OK");

          // Nombre del cliente TCP
          USB.print(F("\nIncoming message from "));
          for (int k=0; (receiver[k]!='&'); k++) {
            USB.print(receiver[k]);
            clientName[k] = receiver[k];
          }

          // Número de mensajes recibidos
          numMessages = receiver[5] - '0';
          int prov5 = 0;
          USB.printf("\nNumber of messages received: %d\n", numMessages);

          // Guardado de los mensajes recibidos
          USB.print(F("\nMessage received: "));
          for (int k=8; k<(sizeof(receiver)); k++) {
            if (receiver[k]=='/' && receiver[k+1]=='0' && receiver[k+2]=='0') {
              if (numMessages>1) {
                USB.print(F("\n\nOld message received: "));
                k = k + 5;
                prov5 = 0;
                for (int j=k; j<(sizeof(receiver)-k); j++) {
                  if (receiver[j]=='/' && receiver[j+1]=='0' && receiver[j+2]=='0') {
                    break;
                  } 
                  else {
                    USB.print(receiver[j]);
                    oldMessage[prov5] = receiver[j];
                    prov5++;
                  }
                }
              }
              break;
            } 
            else {
              USB.print(receiver[k]);
              message[prov5] = receiver[k];
              prov5++;
            }
          }
          break;
        }

        // Condición para evitar un 'overflow'
        if (millis() < previous) {
          previous = millis();	
        }

      }

      // Fin de la conexión TCP
      USB.println(F("\nClose the TCP connection (WiFi switched OFF)\n")); 
      WIFI.close();

    } 
    else {
      USB.println(F("TCP server NOT set\n"));
      notifyByLEDS(true,0);
    }

    // Desconexión de la red Wifi
    WIFI.leave();
  } 

  else {
    USB.println(F("NOT Connected to AP\n"));
    notifyByLEDS(true,0);
  }

  USB.println(F("*************************"));

}


// CONEXIÓN TCP PARA EL MODO CLIENTE
void client() {

  // Preparación del nuevo mensaje (fecha y nivel de batería)
  snprintf(message, sizeof(message), "Datos recopilados a %s con un %d%s de bateria",
           RTC.getTime(), PWR.getBatteryLevel(), "%");
  
  // Conexión a la red Wifi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined AP"));
    notifyByLEDS(false,3);
    WIFI.getIP();

    // Conexión con el servidor TCP
    if (WIFI.setTCPclient(myServerIP, SERVER_PORT, CLIENT_PORT)) {

      notifyByLEDS(false,4);
      USB.println(F("TCP client set"));

      // Envío de mensajes al servidor
      USB.print(F("Sending data: "));
      if (numMessages>1) {
        snprintf(body, sizeof(body), "%s&%d->%s/00->%s/00",
        name, numMessages, message, oldMessage);
      } 
      else {
        snprintf(body, sizeof(body), "%s&%d->%s/00",
        name, numMessages, message);
      }
      USB.println(body);
      WIFI.send(body);

      // Espera para la confirmación del servidor
      USB.println(F("Listen to TCP socket:"));
      previous=millis();
      while(millis()-previous<CLIENT_TIMEOUT) {
        if(WIFI.read(NOBLO)>0) {

          // Chequeo de la respuesta recibida
          for (int k = 0; k<(WIFI.length); k++) {
            if (WIFI.answer[k]=='&' && WIFI.answer[k+1]=='O' && WIFI.answer[k+2]=='K') {
              USB.println(F("OK -> Data sent correctly!!\n"));
              messageReceived = true;
              notifyByLEDS(false,6);
              break;
            }
          }

        }

        // Condición para evitar un 'overflow'
        if (millis() < previous) {
          previous = millis();	
        }

      }

      // Fin de la conexión TCP
      USB.println(F("Close TCP socket"));
      WIFI.close();

    }

    else {
      USB.println(F("TCP client NOT set"));
      notifyByLEDS(true,0);
    }

    // Desconexión de la red Wifi
    WIFI.leave();
  }

  else {
    USB.println(F("NOT Connected to AP"));
    notifyByLEDS(true,0);
  }

  // Si el mensaje no ha sido recibido por el servidor se almacena
  if (!messageReceived) {
    numMessages = 2;
    USB.println(F("\nSaving last message -> Any answer received from TCP server"));
    for (int k=0; k<(sizeof(message)); k++) {
      oldMessage[k] = message[k];
    }
  } 
  else {
    numMessages = 1;
  }

  // Módulo Wifi OFF
  WIFI.OFF();
  USB.println(F("WiFi switched OFF"));  
  USB.println(F("****************************"));

}


// ENVÍO DE DATOS A LA BASE DE DATOS DEL HOST
void sendMessageToServer() {

  // Configuración del módulo Wifi (conexión HTTP)
  WIFI.resetValues();
  WIFI.setConnectionOptions(HTTP);
  WIFI.setDHCPoptions(DHCP_OFF);
  WIFI.setIp(myIP);
  WIFI.setNetmask(NETMASK);
  WIFI.setGW(GATEWAY);
  WIFI.setJoinMode(MANUAL);   
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

  // Conexión a la red Wifi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined"));
    notifyByLEDS(false,3);

    // Configuración y envío al host de mensajes antiguos
    if (numMessages>1) {

      for (int k = 0; k<(sizeof(oldMessage)); k++) {
        if (oldMessage[k]==' ') {
          oldMessage[k] = '_';
        }
      }

      snprintf(body, sizeof(body), "nombre=%s&datos=MENSAJE_RECUPERADO:_%s", clientName, oldMessage);
      USB.println(F("Conecting to server to update old messages..."));
      USB.print(F("GET: "));
      USB.println(body);

      previous=millis();
      do {
        status = WIFI.getURL(DNS, HOST, urlData, body);
      } 
      while (status!=1 && (millis()-previous<CLIENT_TIMEOUT));

      // Respuesta del host
      if (status==1) {
        USB.println(F("\nHTTP query OK\n"));
        notifyByLEDS(false,6);
        USB.println(F("HOST ANSWER:"));
        USB.println(WIFI.answer);
        numMessages = 1;
      }
      else {
        USB.println(F("\nHTTP query ERROR"));
        notifyByLEDS(true,0); 
      }
    }

    // Configuración y envío al host del último mensaje recibido
    for (int k = 0; k<(sizeof(message)); k++) {
      if (message[k]==' ') {
        message[k] = '_';
      }
    }

    snprintf(body, sizeof(body), "nombre=%s&datos=%s", clientName, message);
    USB.println(F("Conecting to server..."));
    USB.print(F("GET: "));
    USB.println(body);

    previous=millis();
    do {
      status = WIFI.getURL(DNS, HOST, urlData, body);
    } 
    while (status!=1 && (millis()-previous<CLIENT_TIMEOUT));

      // Respuesta del host
      if (status==1) {
        USB.println(F("\nHTTP query OK\n"));
        notifyByLEDS(false,6);
        USB.println(F("HOST ANSWER:"));
        USB.println(WIFI.answer);
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

  // Configuración del módulo Wifi (conexión TCP)
  WIFI.resetValues();
  WIFI.setConnectionOptions(CLIENT_SERVER);
  WIFI.setDHCPoptions(DHCP_OFF);
  WIFI.setIp(myIP);
  WIFI.setNetmask(NETMASK);
  WIFI.setGW(GATEWAY);
  WIFI.setJoinMode(MANUAL);   
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

  // Módulo Wifi OFF
  WIFI.OFF();
  USB.println(F("\nWiFi switched OFF"));

}


// PROCESAMIENTO DE LA NUEVA DIRECCIÓN IP RECIBIDA
int IPConfig(int position) {

  int prov1 = 0;
  position = position + 6;
  while (config[position]!='&') {
    myIP[prov1] = config[position];
    position++; 
    prov1++;
  }
  USB.print(F("New IP: "));
  USB.println(myIP);

  return position;
}


// NOTIFICACIONES LED
void notifyByLEDS(boolean error, int times) {
  if (error) {
    Utils.blinkRedLED(250, 5);
  } 
  else {
    Utils.blinkGreenLED(500, times);
  }
}



