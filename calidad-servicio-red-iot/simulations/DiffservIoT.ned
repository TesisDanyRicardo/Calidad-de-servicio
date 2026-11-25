package prueba2.simulations;

import inet.networklayer.diffserv.BehaviorAggregateClassifier;
import inet.networklayer.diffserv.TokenBucketMeter;
import inet.queueing.queue.CompoundPacketQueueBase;
import inet.queueing.queue.DropTailQueue;
import inet.queueing.scheduler.PriorityScheduler;
import inet.queueing.scheduler.WrrScheduler;
import inet.queueing.sink.PassivePacketSink;

//
// Cola DiffServ del gateway: esquema 1P4Q (una cola por clase de trafico
// del escenario, mas la cola EF de prioridad estricta).
//
// Marcas empleadas en este trabajo:
//   URLLC    -> EF   (46) -> efQueue    (prioridad estricta + token bucket)
//   mMTC     -> AF21 (18) -> mmtcQueue
//   Sensores -> AF11 (10) -> sensorQueue
//   Agregado -> CS1  (8)  -> agregadoQueue
//   Sin marcar           -> beQueue
//
// Las colas mmtcQueue, sensorQueue, agregadoQueue y beQueue se reparten
// la capacidad restante mediante WRR.
//
module DiffservIoT extends CompoundPacketQueueBase
{
    parameters:
        string interfaceTableModule;
        *.interfaceTableModule = default(absPath(this.interfaceTableModule));
    submodules:
        classifier: BehaviorAggregateClassifier {
            dscps = default("EF AF21 AF11 CS1");
            @display("p=100,350");
        }
        efMeter: TokenBucketMeter {
            cir = default("30%");
            cbs = default(5000B);
            @display("p=250,50");
        }
        sink: PassivePacketSink {
            @display("p=400,50");
        }
        efQueue: DropTailQueue {
            packetCapacity = default(5);
            @display("p=250,100");
        }
        mmtcQueue: DropTailQueue {
            // AF21 - clase mMTC
            @display("p=250,200");
        }
        sensorQueue: DropTailQueue {
            // AF11 - clase sensores IoT
            @display("p=250,300");
        }
        agregadoQueue: DropTailQueue {
            // CS1 - trafico agregado
            @display("p=250,400");
        }
        beQueue: DropTailQueue {
            // trafico sin marcar / cualquier otro DSCP
            @display("p=250,500");
        }
        wrr: WrrScheduler {
            weights = default("1 1 1 1");
            @display("p=400,350");
        }
        priority: PriorityScheduler {
            @display("p=550,350");
        }

    connections:
        in --> classifier.in;
        classifier.out++ --> efMeter.in;         // EF    -> URLLC
        classifier.out++ --> mmtcQueue.in;        // AF21  -> mMTC
        classifier.out++ --> sensorQueue.in;      // AF11  -> Sensores
        classifier.out++ --> agregadoQueue.in;    // CS1   -> Agregado
        classifier.defaultOut --> beQueue.in;     // sin marcar

        efMeter.greenOut --> { @display("ls=green"); } --> efQueue.in;
        efMeter.redOut --> { @display("ls=red"); } --> sink.in;

        mmtcQueue.out --> wrr.in++;
        sensorQueue.out --> wrr.in++;
        agregadoQueue.out --> wrr.in++;
        beQueue.out --> wrr.in++;
        efQueue.out --> priority.in++;
        wrr.out --> priority.in++;
        priority.out --> out;
}
