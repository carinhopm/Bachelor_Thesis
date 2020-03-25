/*  
 *  TÍTULO: Red de Transferencia de Datos Configurable para Waspmotes
 *  
 *  AUTOR: Carlos Parra Marcelo
 *  
 *  EXPLICACIÓN BREVE: Este código realiza la configuración y la puesta en marcha de
 *                     una red de sensores inalámbrica, descargando primero algunos
 *                     ajustes básicos desde un servidor HTTP, después sincronizando
 *                     los nodos y, por último, subiendo los datos recopilados a una
 *                     base de datos localizada en el servidor HTTP.
 */


// BIBLIOTECAS INCLUÍDAS
#include <WaspWIFI.h>
#include <WaspRTC.h>
#include <string.h>
#include <stdio.h>

//-----------------------> AJUSTES <------------------------
// Para ambos modos
char name[] = "COM6"; //Nombre del nodo
#define SERVER_MODE true //Servidor(true)/cliente(false)
// Para modo Servidor:
#define MAX_NUM_CLIENTS 5 //Núm. máx de nodos cliente
// Para modo Cliente:
#define CLIENT_IP "192.168.1.58" //IP nodo cliente (predet.)
//----------------------------------------------------------

// CONSTANTES Y VARIABLES GLOBALES
#define ESSID "MOVISTAR_1155" // Nombre de la red WiFi
#define AUTHKEY "ksto4TRR3zzTcMPEyXPZ" // Contraseña de la red WiFi
#define NETMASK   "255.255.255.0" // Máscara de red
#define GATEWAY   "192.168.1.1" // Puerta de enlace
#define SERVER_IP "192.168.1.56" //IP del nodo servidor (predeterminada)
#define SERVER_PORT 2000 // Puerto del nodo servidor
#define CLIENT_PORT 3000 // Puerto del nodo cliente
#define SERVER_SHORT_TIMEOUT 45000 // Tiempo de espera corto (servidor)
#define SERVER_TIMEOUT 90000 // Tiempo de espera (servidor)
#define CLIENT_SHORT_TIMEOUT 10000 // Tiempo de espera corto (cliente)
#define CLIENT_TIMEOUT 30000 // Tiempo de espera (cliente)

uint8_t socket = SOCKET0; // Socket del módulo WiFi
uint8_t status; // Variable de comprobación
unsigned long previous; // Variable de tiempo
char HOST[] = "carlinhopm.esy.es"; // Dirección del servidor HTTP
char urlConfig[] = "GET$/config.php?"; // Para descargar los datos de configuración
char urlData[] = "GET$/dataServer.php?"; // Para subir mediciones a la base de datos
char clientName[6]; // Nombre del nodo cliente actual (modo servidor)
char clientsName[MAX_NUM_CLIENTS][6]; // Registro de nombres de los nodos cliente
char myAlarm[4]; // Alarma del nodo cliente
char alarms[MAX_NUM_CLIENTS][4]; // Registro de alarmas de los nodos cliente
char receiver[513]; // Buffer de recepción
char message[507]; // Último mensaje enviado o recibido
char oldMessage[507]; // Penúltimo mensaje enviado o recibido
                      // (recuperación de mensaje perdido)
char body[513]; // Buffer de envío
char config[513]; // Mensaje de configuración (modo servidor)
int numAlarms; // Número de alarmas (número de nodos clientes de la red)
int configuredAlarm; // Posición en el registro de la alarma configurada
int numMessages; // Número de mediciones recibidas (servidor) o a enviar (cliente)
boolean messageReceived; // Comprobación de mensaje recibido

char checkMinute[30]; // <------------ VARIABLE GLOBAL EXTRA!!
boolean alarmChecked; // <------------ VARIABLE GLOBAL EXTRA!!


// AJUSTES INICIALES
void setup() {

  USB.println(F("STARTING PROGRAM ---> Setup:"));

  // Configuración del RTC
  RTC.ON();
  RTC.setTime("04:07:17:03:12:00:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime());
  
  // Encendido del módulo WiFi
  if (WIFI.ON(socket)==1) {
    USB.println(F("\nWiFi switched ON\n"));
    
    // Modo Servidor (sink node)
    if (SERVER_MODE) {    
  
      // Configuración del módulo WiFi (conexión HTTP)
      WIFI.resetValues();
      WIFI.setConnectionOptions(HTTP); 
      WIFI.setDHCPoptions(DHCP_ON);
      WIFI.setJoinMode(MANUAL); 
      WIFI.setAuthKey(WPA2,AUTHKEY);
      WIFI.storeData();
      
      // Descarga de los datos de configuración de la red y valores iniciales
      downloadConfig();
      messageReceived = false;
      configuredAlarm = 0;

    }
    
    numMessages = 1; // Valor inicial
    
    // Configuración del módulo WiFi (conexión TCP)
    WIFI.resetValues();
    if(SERVER_MODE)
      WIFI.setConnectionOptions(CLIENT_SERVER);
    else
      WIFI.setConnectionOptions(CLIENT);
    WIFI.setDHCPoptions(DHCP_OFF);
    if(SERVER_MODE)
      WIFI.setIp(SERVER_IP);
    else
      WIFI.setIp(CLIENT_IP);
    WIFI.setNetmask(NETMASK);
    WIFI.setGW(GATEWAY);
    WIFI.setJoinMode(MANUAL);   
    WIFI.setAuthKey(WPA2,AUTHKEY); 
    WIFI.storeData();
    
    // Conexión a la red WiFi
    if (WIFI.join(ESSID)) {
      USB.println(F("\nJoined AP"));
      USB.println(F("-----------------------"));    
      USB.println(F("get IP"));
      USB.println(F("-----------------------\n"));
      WIFI.getIP();
      notifyByLEDS(false,3);
    
      // Modo Servidor (sink node)
      if (SERVER_MODE) {
        
//        if (numAlarms>MAX_NUM_CLIENTS) {
//          USB.println(F("ERROR -> The number of client nodes is greater than allowed"));
//          notifyByLEDS(true,0); 
//          USB.println(F("\nPROGRAM STOPPED -> Restart waspmote and try again!!"));
//          USB.println(F("***************************"));
//          delay(300000);
//        }
//        else {
//        
//          // Se van descartando los nodos cliente según van recibiendo su configuración
//          for (int clients = 0; clients<numAlarms; clients++) {
//            while (!messageReceived) {
//              sendConfig();
//            }
//            WIFI.leave(); // Cuando un nodo cliente recibe su configuración, el servidor
//                          // se desconecta de la red y luego repite todo el proceso
//            while (messageReceived) {
//              if (WIFI.join(ESSID)) {
//                notifyByLEDS(false,3);
//                messageReceived = false;
//              }
//            }
//          }
//        }
      }
      
      // Modo Cliente
      else {
//        USB.println(F("\nWaiting for the configuration turn...\n"));
//        delay(60000); // Espera al servidor: 60 segundos
//        while (!messageReceived) {;
//          receiveConfig();
//          delay(8000); // Mejora la probabilidad de conexión con el sink node
//        }

        myAlarm[0] = '3';
        myAlarm[1] = '4';
        messageReceived = false;
      }
      
      // Desconexión de la red WiFi
      WIFI.leave();
    }
    else {
      USB.println(F("NOT Connected to AP"));
      notifyByLEDS(true,0);
    }
        
    USB.println(F("\nSETUP COMPLETED\n"));

  }
  else {
    USB.println(F("ERROR -> WiFi did not initialize correctly"));
    notifyByLEDS(true,0); 
    USB.println(F("\nPROGRAM STOPPED -> Restart waspmote and try again!!"));
    USB.println(F("***************************"));
    delay(300000);
  }
}


// RUTINA PRINCIPAL DE EJECUCIÓN
void loop() {

  // Modo Servidor
  if (SERVER_MODE && numAlarms>0) {

//    // Configuración de la alarma (asignadas de forma consecutiva)
//    char settingAlarm1[11];
//    strcpy(settingAlarm1,"00:00:");
//    strcat(settingAlarm1,alarms[configuredAlarm]);
//    strcat(settingAlarm1,":00");
//    RTC.setAlarm1(settingAlarm1,RTC_ABSOLUTE,RTC_ALM1_MODE4);
//    USB.printf("\nAlarm1: %s\n", RTC.getAlarm1());
    
    alarmChecked = false;
    while (!alarmChecked) {
      strcpy(checkMinute, RTC.getTime());
      for (int i = 0; i<30; i++) {
        if (checkMinute[i]==':') {
          if (checkMinute[i+1]==alarms[configuredAlarm][0] && checkMinute[i+2]==alarms[configuredAlarm][1]) {
            USB.println(F("ALARM!!"));
            notifyByLEDS(false,2);
            alarmChecked = true;
            delay(60000);
          }
          i = i+5;
        }
      }
    }
    
    configuredAlarm++;
    if(configuredAlarm>=numAlarms)
      configuredAlarm = 0;

  }

  // Modo Cliente
  else if (!SERVER_MODE) {

//    // Configuración de la alarma
//    char settingAlarm1[11];
//    strcpy(settingAlarm1,"00:00:");
//    strcat(settingAlarm1,myAlarm);
//    strcat(settingAlarm1,":00");
//    RTC.setAlarm1(settingAlarm1,RTC_ABSOLUTE,RTC_ALM1_MODE4);
//    USB.printf("\nAlarm1: %s\n", RTC.getAlarm1());

    alarmChecked = false;
    while (!alarmChecked) {
      strcpy(checkMinute, RTC.getTime());
      for (int i = 0; i<30; i++) {
        if (checkMinute[i]==':') {
          if (checkMinute[i+1]==myAlarm[0] && checkMinute[i+2]==myAlarm[1]) {
            USB.println(F("ALARM!!"));
            notifyByLEDS(false,2);
            alarmChecked = true;
            delay(60000);
          }
          i = i+5;
        }
      }
    }

  } 
  else {
    USB.println(F("No function expected"));
  }

    // Modo Servidor
    if (SERVER_MODE && numAlarms>0) {
      
      // Recepción de datos del nodo cliente + envío de datos al servidor HTTP
      server();
      if (messageReceived) {
        sendMessageToServer();
        messageReceived = false;
      }
    }

    // Modo Cliente
    else if (!SERVER_MODE) {
      
      // Envío de datos recopilados al nodo servidor
      delay(15000);  // Espera para la configuración del servidor TCP
      client();
      messageReceived = false;
    }
}


// DESCARGA Y GUARDADO DE LA CONFIGURACIÓN DE LA RED
void downloadConfig() {

  // Conexión a la red WiFi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined\n"));
    notifyByLEDS(false,3);

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

      USB.println(F("HTTP query OK."));
      notifyByLEDS(false,6);

      // Respuesta del host
      strcpy(config, WIFI.answer);
      USB.println(F("\nHOST ANSWER:"));
      USB.println(WIFI.answer);
      USB.println();
      numAlarms = 0;
      int actualAlarm;

      // Procesamiento y guardado de los datos recibidos
      // Ejemplo de mensaje de configuración:
      // "&nombre=COM4&minConex=2&nombre=COM3&minConex=32&"
      for (int k=0; k<(WIFI.length); k++) {
        while (config[k]=='&' && config[k+1]=='n' && config[k+2]=='o') {
          
          // Nombre del nodo cliente
          k = k + 8;
          int numCaract = 0;
          while (config[k]!='&') {
            clientsName[numAlarms][numCaract] = config[k];
            numCaract++;
            k++;
          }
          
          // Alarma del nodo cliente
          k = k + 10;
          if (config[k+1]=='&') {
            alarms[numAlarms][0] = '0';
            alarms[numAlarms][1] = config[k];
            k = k + 1;
          } 
          else {
            alarms[numAlarms][0] = config[k];
            alarms[numAlarms][1] = config[k+1];
            k = k + 2;
          }
          actualAlarm = numAlarms;
          numAlarms++;
          USB.printf("Alarm %d: at %s minutes every hour\n", numAlarms, alarms[actualAlarm]);
        }
      }
      
      USB.printf("Number of alarms to set: %d\n", numAlarms);
    }

    else {
      USB.println(F("\nHTTP query ERROR"));
      notifyByLEDS(true,0); 
    }
    
    // Desconexión de la red WiFi
    WIFI.leave();
  }

  else {
    USB.println(F("NOT joined"));
    notifyByLEDS(true,0);
  }
}


// ENVÍO DE LOS DATOS DE CONFIGURACIÓN A LOS WASPMOTE-CLIENTES
void sendConfig() {

  // Establecimiento del servidor TCP
  if (WIFI.setTCPserver(SERVER_PORT)) {
    
    notifyByLEDS(false,4);
    USB.println(F("\nTCP server set"));
    USB.println(F("Listening for incoming data requests..."));
    
    // Tiempo de espera para la recepción de peticiones
    previous=millis();
    while( millis()-previous<SERVER_SHORT_TIMEOUT ) { 
      
      // Lectura de mensajes de la conexión TCP
      WIFI.read(NOBLO);
      USB.print(F("w")); // Esperando peticiones
  
      // Procesamiento de la petición recibida
      if (WIFI.length>0) {
        for (int k = 0; k<(WIFI.length); k++) {
          if (WIFI.answer[k]=='&' && WIFI.answer[k+1]=='n' && WIFI.answer[k+2]=='o') {
            notifyByLEDS(false,5);
            messageReceived = true;
            strcpy(receiver, WIFI.answer);
            
            // Nombre del cliente TCP
            USB.print(F("\n\nIncoming request from: "));
            k = k + 8;
            int numCaracter = 0; //Nombres de máximo 4 caracteres
            while (numCaracter<4) {
              USB.print(receiver[k]);
              clientName[numCaracter] = receiver[k];
              numCaracter++;
              k++;
            }
            
            // Búsqueda del cliente en el registro de nombres + consulta de su alarma
            int i;
            for (i=0; i<numAlarms; i++) {
              if ((clientsName[i][0]==clientName[0]) && (clientsName[i][1]==clientName[1]) &&
                  (clientsName[i][2]==clientName[2]) && (clientsName[i][3]==clientName[3])) {
                myAlarm[0] = alarms[i][0];
                myAlarm[1] = alarms[i][1];
              }
            }
            
            // Envío de la alarma correspondiente
            USB.print(F("\nSending configuration data: "));
            snprintf(body, sizeof(body), "&minConex=%s&/00", myAlarm);
            USB.println(body);
            WIFI.send(body);
            break;
          }
        }
      }
      
      // Cancelación de la espera con la recepción de un mensaje
      if (messageReceived) {
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
}


void receiveConfig() {

  // Conexión con el servidor TCP
  if (WIFI.setTCPclient(SERVER_IP, SERVER_PORT, CLIENT_PORT)) {
    notifyByLEDS(false,4);
    USB.println(F("\nTCP client set"));
    
    // Petición de datos de configuración al nodo servidor
    USB.print(F("\nRequesting configuration data from the server: "));
    snprintf(body, sizeof(body), "&nombre=%s/00", name);
    USB.println(body);
    WIFI.send(body);
    
    // Espera para la recepción de los datos
    USB.println(F("Listen to TCP socket:"));
    previous=millis();
    while(millis()-previous<CLIENT_SHORT_TIMEOUT) {
      if(WIFI.read(NOBLO)>0) {
        
        // Chequeo de la respuesta recibida
        for (int k = 0; k<(WIFI.length); k++) {
          if (WIFI.answer[k]=='&' && WIFI.answer[k+1]=='m' && WIFI.answer[k+2]=='i') {
            USB.println(F("Data configuration received!!\n"));
            messageReceived = true;
            notifyByLEDS(false,6);
            
            // Alarma para la conexión periódica con el servidor
            k = k + 10;
            if (WIFI.answer[k+1]=='&') {
              myAlarm[0] = '0';
              myAlarm[1] = WIFI.answer[k];
            } 
            else {
              myAlarm[0] = WIFI.answer[k];
              myAlarm[1] = WIFI.answer[k+1];
            }
            USB.printf("Alarm time: at %s minutes every hour\n", myAlarm);
            break;
          }
        }
      }
      
      // Cancelación de la espera con la recepción de un mensaje
      if (messageReceived) {
        break;
      }
      
      // Condición para evitar un 'overflow'
      if (millis() < previous) {
        previous = millis();	
      }
    }
    
    if (!messageReceived) {
      USB.println(F("Data configuration not received, trying again...\n"));
    }
    
    // Fin de la conexión TCP
    USB.println(F("Close TCP socket\n"));
    WIFI.close();
  }
  else {
    USB.println(F("TCP client NOT set"));
    notifyByLEDS(true,0);
  }
}


// CONEXIÓN TCP PARA EL MODO SERVIDOR
void server() {

  // Conexión a la red WiFi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined AP"));
    notifyByLEDS(false,3);   
    USB.println(F("-----------------------"));    
    USB.println(F("get IP"));
    USB.println(F("-----------------------\n"));
    WIFI.getIP();

    // Establecimiento del servidor TCP
    if (WIFI.setTCPserver(SERVER_PORT)) {

      notifyByLEDS(false,4);
      USB.println(F("\nTCP server set"));
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
      USB.println(F("\n\nClose the TCP connection (WiFi switched OFF)")); 
      WIFI.close();

    } 
    else {
      USB.println(F("TCP server NOT set"));
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
  
  // Conexión a la red WiFi
  if (WIFI.join(ESSID)) {

    USB.println(F("Joined AP"));
    notifyByLEDS(false,3);
    WIFI.getIP();

    // Conexión con el servidor TCP
    if (WIFI.setTCPclient(SERVER_IP, SERVER_PORT, CLIENT_PORT)) {

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
}


// ENVÍO DE DATOS A LA BASE DE DATOS DEL HOST
void sendMessageToServer() {

  // Configuración del módulo Wifi (conexión HTTP)
  WIFI.resetValues();
  WIFI.setConnectionOptions(HTTP);
  WIFI.setDHCPoptions(DHCP_OFF);
  WIFI.setIp(SERVER_IP);
  WIFI.setNetmask(NETMASK);
  WIFI.setGW(GATEWAY);
  WIFI.setJoinMode(MANUAL);   
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

  // Conexión a la red Wifi
  if (WIFI.join(ESSID)) {

    USB.println(F("\nJoined\n"));
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
        USB.println(F("HTTP query OK\n"));
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

  // Configuración del módulo WiFi (conexión TCP)
  WIFI.resetValues();
  WIFI.setConnectionOptions(CLIENT_SERVER);
  WIFI.setDHCPoptions(DHCP_OFF);
  WIFI.setIp(SERVER_IP);
  WIFI.setNetmask(NETMASK);
  WIFI.setGW(GATEWAY);
  WIFI.setJoinMode(MANUAL);   
  WIFI.setAuthKey(WPA2,AUTHKEY); 
  WIFI.storeData();

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

