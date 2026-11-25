# Análisis de la calidad de servicio en una red IoT

Modelo de simulación del trabajo de grado *Análisis de la calidad de servicio en una red IoT*, del programa de Ingeniería Electrónica y Telecomunicaciones de la Universidad del Cauca (Popayán, Colombia, 2026).

- **Autores:** Danny Alejandro Mejia Villa y Ricardo Andres Diaz Muñoz
- **Director:** Oscar J. Calderón C.
- **Herramientas:** OMNeT++ 6.1 e INET 4.5

## Qué contiene

El modelo representa una red IoT en la que cuatro clases de tráfico comparten un enlace troncal de 2 Mbps a través de un *gateway*. La demanda total es de 2,665 Mbps, el 133 % de la capacidad del troncal. Con él se compara una red sin calidad de servicio, con una sola cola FIFO, y una red con servicios diferenciados (DiffServ), que da a cada clase un tratamiento propio.

```
.
├── README.md
├── LICENSE
├── simulations/
│   ├── IoTNetwork.ned    red: nodos, gateway, servidor y enlaces
│   ├── DiffservIoT.ned   cola DiffServ del gateway (esquema 1P4Q)
│   ├── omnetpp.ini       parámetros y configuraciones de cada escenario
│   └── package.ned
└── src/
    └── package.ned
```

El módulo `DiffservIoT` se construyó solo con componentes de INET, así que el proyecto no tiene código C++ propio y no hay que compilar nada aparte de INET.

## Escenario

| Clase | Nodos | Tecnología | Envío por nodo | Carga útil | Marca DSCP |
|---|---|---|---|---|---|
| mMTC | 120 | Wi-Fi (IEEE 802.11g), canal 1 | 8 paquetes/s (Poisson) | 200 B | AF21 (18) |
| URLLC | 20 | Wi-Fi (IEEE 802.11g), canal 6 | 1 paquete cada 20 ms | 32 B | EF (46) |
| Sensores | 40 | IEEE 802.15.4 | 1 paquete cada 10 s (Poisson) | 20 B | AF11 (10) |
| Agregado | 1 (cableado) | Enlace de 100 Mbps | 100 paquetes/s (Poisson) | 512 B | CS1 (8) |

- Los 180 nodos inalámbricos se ubican al azar en un área de 100 × 100 m, con el *gateway* en el centro.
- El *gateway* envía todo el tráfico al servidor por un enlace troncal de 2 Mbps.
- **Sin calidad de servicio:** una cola FIFO de 100 paquetes.
- **Con DiffServ (`DiffservIoT`):**
  - un clasificador por DSCP;
  - un medidor *token bucket* para EF (CIR del 30 % del troncal y CBS de 5000 B);
  - una cola EF de 5 paquetes atendida con prioridad estricta;
  - colas de 100 paquetes para las demás clases, atendidas con WRR de pesos 16:1:1:1.

## Configuraciones

Cada escenario es una configuración de `omnetpp.ini`:

| Configuración | Escenario | Qué evalúa |
|---|---|---|
| `Etapa1_Base` | E-BASE | Red sin calidad de servicio, con una sola cola FIFO |
| `Etapa2_DiffServ` | E-QOS | Red con DiffServ y marcado DSCP por clase |
| `Etapa4_InvertidoSinVigilancia` | E-INV | Marcas de mMTC y URLLC intercambiadas, pesos iguales y CIR del 95 % |
| `Etapa3_Invertido` | E-VIG | Marcas intercambiadas, con la misma configuración de E-QOS |
| `Dinamico_Base` | E-DIN (FIFO) | Las clases se activan una tras otra durante 100 s |
| `Dinamico_DiffServ` | E-DIN (DiffServ) | Igual que la anterior, con DiffServ |

Los escenarios de carga constante duran 40 s, con 12 s de calentamiento y 10 replicaciones. Los dos escenarios dinámicos duran 100 s, sin calentamiento y en una sola replicación. La configuración `Prueba_Arp` es una prueba de diagnóstico y no se usó en los resultados.

## Cómo ejecutar

1. Instale OMNeT++ 6.1 y compile INET 4.5 en el mismo *workspace*.
2. Clone este repositorio dentro de ese *workspace*, al lado de la carpeta `inet4.5`:

   ```
   workspace/
   ├── inet4.5/
   └── calidad-servicio-red-iot/
   ```

   La ruta de INET está fijada en `omnetpp.ini` (`ned-path = .;../src;../../inet4.5/src`). Si INET está en otro lugar, cambie esa línea.
3. Ejecute una configuración desde la terminal de OMNeT++:

   ```
   cd calidad-servicio-red-iot/simulations
   opp_run -u Cmdenv -c Etapa1_Base -l ../../inet4.5/src/INET omnetpp.ini
   ```

   Cambie `Etapa1_Base` por la configuración que quiera ejecutar. Cmdenv ejecuta todas las replicaciones y guarda los resultados en `simulations/results/`.

   También puede crear un proyecto OMNeT++ en el IDE con referencia a INET, copiar en él la carpeta `simulations` y ejecutar `omnetpp.ini` eligiendo la configuración.

## Resultados principales

Promedio de 10 replicaciones, con troncal de 2 Mbps:

| Clase | Pérdida sin QoS | Pérdida con DiffServ | Retardo máx. sin QoS | Retardo máx. con DiffServ |
|---|---|---|---|---|
| URLLC | 27,26 % | 0,084 % | 83,99 ms | 3,92 ms |
| mMTC | 27,81 % | 29,20 % | 84,54 ms | 153,84 ms |
| Sensores | 26,84 % | 0,00 % | 80,94 ms | 41,86 ms |
| Agregado | 29,72 % | 57,42 % | 84,65 ms | 2362,72 ms |

- Sin calidad de servicio, las cuatro clases reciben el mismo trato.
- Con DiffServ, el retardo máximo de URLLC queda por debajo del PDB de 10 ms (5QI 82, 3GPP TS 23.501), a costa de las clases que toleran demoras.
- Con las marcas intercambiadas (E-INV), URLLC pierde el 93,62 % de sus paquetes: la protección depende de marcar bien cada tráfico.

El análisis completo está en el documento del trabajo de grado.

## Cómo citar

D. A. Mejia Villa y R. A. Diaz Muñoz, *Análisis de la calidad de servicio en una red IoT*, Trabajo de grado, Ingeniería Electrónica y Telecomunicaciones, Universidad del Cauca, Popayán, Colombia, 2026.

## Licencia

Este trabajo se publica bajo la licencia Creative Commons Atribución-NoComercial-SinDerivadas 4.0 Internacional (CC BY-NC-ND 4.0). Vea el archivo `LICENSE`.
