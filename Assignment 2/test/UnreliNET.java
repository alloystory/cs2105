// (C) 2019 Wu Biao
// (C) 2015, 2016 Marc Bruenink
// (C) 2014 Hong Hande


import java.net.*;
import java.util.*;

public class UnreliNET {
    static int max_packet_size = 64;
    int total_forwarded = 0;
    int returnPort;
    
    // define thread which is used to handle one-direction of communication
    public class Forwarder extends Thread {
        private DatagramSocket source;
        private DatagramSocket dst_socket;
        private InetAddress dst_addr;
        private int dst_port;
        private int min_delay = 0;
        private int max_delay;
        private float corrupt_rate;
        private int corruptionCounter = 0;
        private float drop_rate;
        private int dropCounter = 0;
        private Random random;
        private Random rnd_byte;
        private boolean ack_stream;
        
        public Forwarder(DatagramSocket source, 
                         DatagramSocket dst_socket, String dst_host, int dst_port,
                         float corrupt_rate, float drop_rate,
                         int min_delay, int max_delay,
                         long seed, boolean ack_stream) throws UnknownHostException {
            this.source = source;
            this.dst_socket = dst_socket;
            this.dst_addr = InetAddress.getByName(dst_host);
            this.dst_port = dst_port;
            this.corrupt_rate = corrupt_rate;
            this.drop_rate = drop_rate;
            this.min_delay = min_delay;
            this.max_delay = max_delay;
            this.random = new Random(seed);
            this.rnd_byte = new Random(seed);
            this.ack_stream = ack_stream;
        }
        
        public void run() {
            try {
                byte[] data = new byte[max_packet_size + 1000];
                DatagramPacket packet = new DatagramPacket(data, data.length);
                
                while (true) {
                    // read data from the incoming socket
                    source.receive(packet);
                    total_forwarded += packet.getLength();
                    
                    // check the length of the packet
                    if (packet.getLength() > max_packet_size) {
                        System.err.println("Error: packet length is more than " + max_packet_size + " bytes");
			dropCounter++;
                        System.out.println(dropCounter + " packet(s) dropped");
                        continue;
                    }
                    
                    // decide if to drop the packet or not
                    if (random.nextFloat() <= drop_rate) {
                        dropCounter++;
                        System.out.println(dropCounter + " packet(s) dropped");
                        continue;
                    }
                    
                    // decide if to corrupt the packet or not
                    if (random.nextFloat() <= corrupt_rate) {
                        for (int i = 0; i < packet.getLength(); ++i)
                            // we have an extra random number generator for the corruption since the packet
                            // length might be different between submissions
                            if (i == 0 || rnd_byte.nextFloat() <= 0.3)  //decide if to corrupt a byte
                                data[i] = (byte) ((data[i] + 1) % 10);
                        corruptionCounter++;
                        System.out.println(corruptionCounter + " packet(s) corrupted");
                    }
                    
                    // This is a bit hackish but o well...
                    // In the second thread (the one that forwards the ACKS)
                    // we need to know the source port from the packets
                    if (!ack_stream)
                      returnPort = packet.getPort();
                    else 
                      dst_port = returnPort;
                    // add some delay
                    int delay = min_delay + random.nextInt(max_delay - min_delay + 1);
                    // Thread.sleep(delay);
                    // send the data
                    dst_socket.send(new DatagramPacket(data, packet.getLength(), dst_addr, dst_port));
                }
                
            } catch (Exception e) {
                e.printStackTrace();
                System.exit(-1);
            }
        }
    }
    
    public UnreliNET(float data_corrupt_rate, float data_loss_rate,
                     float ack_corrupt_rate, float ack_loss_rate, 
                     int min_delay, int max_delay,
                     int unreliNetPort, String rcvHost, int rcvPort) {
        
        System.out.println("unreliNetPort = " + unreliNetPort
                               + "\nrcvHost = " + rcvHost 
                               + "\nrcvPort = " + rcvPort 
                               + "\ndata corruption rate = " + data_corrupt_rate
                               + "\nack/nak corruption rate = " + ack_corrupt_rate
                               + "\ndata loss rate = " + data_loss_rate
                               + "\nack/nak loss rate = " + ack_loss_rate
                               + "\nmin delay = " + min_delay
                               + "\nmax delay = " + max_delay
                               );
                               
        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() { System.out.println("Forwarded " + total_forwarded + " bytes"); }
        });
        
        try {
            DatagramSocket sender = new DatagramSocket(unreliNetPort);
            DatagramSocket receiver = new DatagramSocket();
            
            // create threads to process sender's incoming data
            Forwarder th1 = new Forwarder(sender, receiver, rcvHost, rcvPort,
                                          data_corrupt_rate, data_loss_rate,
                                          min_delay, max_delay,
                                          0, false);
            th1.start();
            
            // create threads to process receiver's incoming data
            Forwarder th2 = new Forwarder(receiver, sender, "localhost", returnPort,
                                          ack_corrupt_rate, ack_loss_rate,
                                          min_delay, max_delay,
                                          0, true);
            th2.start();
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }
    
    public static void main(String[] args) {
        // parse parameters
        if (args.length != 6) {
            System.err.println("Usage: java UnreliNET <P_DATA_CORRUPT> <P_DATA_LOSS> " +
                               "<P_ACK_CORRUPT> <P_ACK_LOSS> " +
                               "<unreliNetPort> <rcvPort>");
            System.exit(-1);
        } else {
            new UnreliNET(Float.parseFloat(args[0]), Float.parseFloat(args[1]),
                          Float.parseFloat(args[2]), Float.parseFloat(args[3]),
                          10, 30,
                          Integer.parseInt(args[4]), "localhost", Integer.parseInt(args[5]) );
        }
    }
}
