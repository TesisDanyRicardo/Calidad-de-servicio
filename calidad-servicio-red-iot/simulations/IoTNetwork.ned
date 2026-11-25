package prueba2.simulations;

import inet.networklayer.configurator.ipv4.Ipv4NetworkConfigurator;
import inet.node.inet.AdhocHost;
import inet.node.inet.Router;
import inet.node.inet.StandardHost;
import inet.node.inet.SensorNode;
import inet.physicallayer.wireless.ieee80211.packetlevel.Ieee80211ScalarRadioMedium;
import inet.physicallayer.wireless.ieee802154.packetlevel.Ieee802154NarrowbandScalarRadioMedium;

//
// Escenario de coexistencia de 4 clases de trafico IoT sobre un gateway comun.
// mMTC Wi-Fi (canal 1) + URLLC Wi-Fi (canal 6) + sensores 802.15.4 (2450 MHz)
// + trafico agregado cableado -> gateway -> troncal 2 Mb/s -> servidor.
//
// Poblaciones y tasas:
//   mMTC:         120 nodos, 8 paq/s,  200 B
//   URLLC:         20 nodos, 50 paq/s,  32 B  (bucle de control cada 20 ms)
//   Sensores IoT:  40 nodos, 0.1 paq/s, 20 B  (reporte cada 10 s)
//   Agregado:      1 nodo cableado, 20 flujos externos de 5 paq/s cada uno
//                  (100 paq/s agregados, 512 B)
//
network IoTNetwork
{
    parameters:
        int numMmtc = default(120);
        int numUrllc = default(20);
        int numSensors = default(40);
        @display("bgb=900,550");

    submodules:
        configurator: Ipv4NetworkConfigurator {
            @display("p=60,40");
        }
        radioMedium: Ieee80211ScalarRadioMedium {
            @display("p=60,120");
        }
        sensorMedium: Ieee802154NarrowbandScalarRadioMedium {
            @display("p=60,200");
        }
        mmtc[numMmtc]: AdhocHost {
            @display("i=device/pocketpc");
        }
        urllc[numUrllc]: AdhocHost {
            @display("i=device/pocketpc;i2=status/execute");
        }
        sensor[numSensors]: SensorNode {
            @display("i=misc/sensor2");
        }
        agregado: StandardHost {
            @display("i=misc/cloud");
        }
        gateway: Router {
            @display("i=device/router");
        }
        server: StandardHost {
            @display("i=device/server");
        }

    connections:
        // Enlace troncal (cuello de botella) -> gateway.ppp[0]
        gateway.pppg++ <--> {  datarate = 2Mbps; delay = 1ms;  } <--> server.pppg++;
        // Trafico agregado: enlace holgado, no es el cuello de botella
        agregado.pppg++ <--> {  datarate = 100Mbps; delay = 1ms;  } <--> gateway.pppg++;
}
