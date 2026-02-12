#!/bin/bash

# HDTN Path Variables
export HDTN_SOURCE_ROOT=$(pwd)
config_files=$HDTN_SOURCE_ROOT/config_files
hdtn_config=$config_files/hdtn/hdtn_ingress1ltp_port4556_egress1ltp_port4558flowid2.json
sink_config=$config_files/inducts/bpsink_one_ltp_port4558.json
gen_config=$config_files/outducts/bpgen_one_ltp_port4556_thisengineid200.json

packet_induct_config=$HDTN_SOURCE_ROOT/packet_induct_udp_6565.json
packet_outduct_config=$HDTN_SOURCE_ROOT/packet_outduct_udp_8554.json

echo "=== Starting HDTN UDP Tunnel Demo (Packet Tunnel Mode) ==="

# Cleanup function
cleanup() {
    echo "=== Shutting down... ==="
    kill $(jobs -p) 2>/dev/null
    exit
}
trap cleanup SIGINT SIGTERM

# 1. Start Python UDP Receiver (Sink)
echo "[1/5] Starting Python UDP Receiver on port 8554..."
python3 -u recv_udp.py > receiver.log 2>&1 &
PID_RECV=$!
sleep 1

# 2. Start BpReceivePacket (HDTN Egress)
# Receives Bundles from Router (via sink_config LTP) -> Extracts Packet -> Sends via packet_outduct_config (UDP)
echo "[2/5] Starting BpReceivePacket (Egress)..."
./build/common/bpcodec/apps/bpreceivepacket \
    --my-uri-eid=ipn:2.1 \
    --max-rx-bundle-size-bytes=70000 \
    --inducts-config-file=$sink_config \
    --packet-outducts-config-file=$packet_outduct_config > hdtn_egress.log 2>&1 &
sleep 2

# 3. Start HDTN Router
echo "[3/5] Starting HDTN One Process (Router)..."
./build/module/hdtn_one_process/hdtn-one-process \
    --contact-plan-file=$HDTN_SOURCE_ROOT/module/router/contact_plans/contactPlanCutThroughMode_unlimitedRate.json \
    --hdtn-config-file=$hdtn_config > hdtn_router.log 2>&1 &
sleep 5

# 4. Start BpSendPacket (HDTN Ingress)
# Receives Packets (via packet_induct_config UDP) -> Wraps in Bundle -> Sends to ipn:2.1 (via gen_config LTP)
echo "[4/5] Starting BpSendPacket (Ingress listening on 6565)..."
./build/common/bpcodec/apps/bpsendpacket \
    --use-bp-version-7 \
    --my-uri-eid=ipn:1.1 \
    --dest-uri-eid=ipn:2.1 \
    --packet-inducts-config-file=$packet_induct_config \
    --outducts-config-file=$gen_config > hdtn_ingress.log 2>&1 &
sleep 3

# 5. Start Python Sender (Source)
echo "[5/5] Starting Python UDP Sender (Target: 127.0.0.1:6565)..."
echo "-----------------------------------------------------------"
echo "Sending packets... check receiver output above!"
echo "Press Ctrl+C to stop."
echo "-----------------------------------------------------------"

python3 send_udp.py

wait
