# HDTN UDP Tunnel Demo

This demonstration shows how High-Rate Delay Tolerant Networking (HDTN) can tunnel generic UDP traffic through a delay-tolerant network. The system encapsulates incoming UDP packets into bundles, routes them through the HDTN stack, and decapsulates them back into UDP packets at the destination.

## Architecture

Data flows through the system in five stages:

```mermaid
graph LR
    A[Python Sender] -- UDP:6565 --> B[Ingress Node]
    B -- LTP:4556 --> C[HDTN Router]
    C -- LTP:4558 --> D[Egress Node]
    D -- UDP:8554 --> E[Python Receiver]
```

1.  **UDP Source**: A Python script generates UDP packets containing a text payload.
2.  **Ingress (`bpsendpacket`)**: Listens for UDP packets, wraps them in Bundle Protocol (BPv7) bundles, and transmits them via Licklider Transmission Protocol (LTP) to the router.
3.  **Router (`hdtn-one-process`)**: Receives bundles and routes them based on the destination EID (`ipn:2.1`).
4.  **Egress (`bpreceivepacket`)**: Receives bundles from the router, extracts the original UDP payload, and transmits it to the final destination.
5.  **UDP Sink**: A Python script listens for the final UDP packets and prints the message.

## Components & Configuration

The demo uses three main HDTN executables running in parallel.

### 1. Ingress Node (`bpsendpacket`)
*   **Role**: Entry point for UDP traffic.
*   **Executable**: `./build/common/bpcodec/apps/bpsendpacket`
*   **Arguments**:
    *   `--my-uri-eid=ipn:1.1`: Source Node ID.
    *   `--dest-uri-eid=ipn:2.1`: Destination Node ID.
    *   `--packet-inducts-config-file`: Defines how to receive UDP packets (Port 6565).
    *   `--outducts-config-file`: Defines how to send bundles to the Router (LTP).
*   **Key Config**: `packet_induct_udp_6565.json`
    ```json
    {
        "inductVector": [{
            "convergenceLayer": "udp",
            "boundPort": 6565
        }]
    }
    ```

### 2. HDTN Router (`hdtn-one-process`)
*   **Role**: Central switching node.
*   **Executable**: `./build/module/hdtn_one_process/hdtn-one-process`
*   **Arguments**:
    *   `--hdtn-config-file`: Defines the router's inducts (inputs) and outducts (outputs).
*   **Key Config**: `config_files/hdtn/hdtn_ingress1ltp_port4556_egress1ltp_port4558flowid2.json`
    *   Accepts bundles on LTP Port 4556 (from Ingress).
    *   Forwards bundles to LTP Port 4558 (to Egress).

### 3. Egress Node (`bpreceivepacket`)
*   **Role**: Exit point for traffic.
*   **Executable**: `./build/common/bpcodec/apps/bpreceivepacket`
*   **Arguments**:
    *   `--my-uri-eid=ipn:2.1`: This node's ID (matches destination).
    *   `--inducts-config-file`: Defines how to receive bundles (LTP Port 4558).
    *   `--packet-outducts-config-file`: Defines where to send the final UDP packets.
*   **Key Config**: `packet_outduct_udp_8554.json`
    ```json
    {
        "outductVector": [{
            "convergenceLayer": "udp",
            "remoteHostname": "127.0.0.1",
            "remotePort": 8554
        }]
    }
    ```

## Running the Demo

A helper script `run_udp_demo.sh` orchestrates the entire process.

1.  **Ensure the project is built**:
    ```bash
    mkdir -p build && cd build
    cmake .. -DENABLE_STREAMING_SUPPORT=ON
    make -j4
    cd ..
    ```

2.  **Run the demo script**:
    ```bash
    ./run_udp_demo.sh
    ```

    You should see output indicating packets are being sent and received:
    ```
    Sending UDP packets to 127.0.0.1:6565...
    Sent: Hello HDTN (Seq: 0)
    Received from ('127.0.0.1', 35011): Hello HDTN (Seq: 0)
    Sent: Hello HDTN (Seq: 1)
    Received from ('127.0.0.1', 35011): Hello HDTN (Seq: 1)
    ```

3.  **Stop the demo**:
    Press `Ctrl+C` to cleanly shut down all background processes.
