#!/bin/bash

# Standardwerte für Umgebungsvariablen festlegen
: ${SLS_HTTP_PORT:=8181}
: ${SLS_SRT_PORT:=8080}
: ${SLS_LOG_LEVEL:=info}
: ${SLS_LATENCY:=20}
: ${SLS_DOMAIN_PLAYER:=live.sls}
: ${SLS_DOMAIN_PUBLISHER:=uplive.sls}
: ${SLS_DEFAULT_SID:=uplive.sls/live/test}
: ${SLS_IDLE_TIMEOUT:=10}
: ${SLS_CORS_HEADER:=*}
: ${SLS_WORKER_THREADS:=1}
: ${SLS_WORKER_CONNECTIONS:=300}
: ${SRTLA_PORT:=5000}
: ${SRTLA_SRT_HOSTNAME:=127.0.0.1}
: ${SRTLA_SRT_PORT:=$SLS_SRT_PORT}
# VOD-Konfiguration
: ${SLS_RECORD_HLS:=off}
: ${SLS_RECORD_HLS_PATH:=/tmp/mov/sls}
: ${SLS_RECORD_HLS_SEGMENT_DURATION:=10}

echo "Generiere sls.conf mit Konfiguration aus Umgebungsvariablen..."

# Verzeichnis für VOD erstellen
mkdir -p ${SLS_RECORD_HLS_PATH}
chown -R srt:srt ${SLS_RECORD_HLS_PATH}

# Konfigurationsdatei generieren
cat > /etc/sls/sls.conf << EOF
srt { # SRT
    worker_threads ${SLS_WORKER_THREADS};
    worker_connections ${SLS_WORKER_CONNECTIONS};

    http_port ${SLS_HTTP_PORT};
    cors_header ${SLS_CORS_HEADER};
    log_file logs/srt_server.log;
    log_level ${SLS_LOG_LEVEL};

    pidfile /tmp/sls/sls_server.pid;

    stat_post_url http://127.0.0.1:${SLS_HTTP_PORT}/stats;
    stat_post_interval 5;

    # VOD-Konfiguration
    record_hls_path_prefix ${SLS_RECORD_HLS_PATH};

    server {
        listen ${SLS_SRT_PORT};
        latency ${SLS_LATENCY}; # unit ms

        domain_player ${SLS_DOMAIN_PLAYER};
        domain_publisher ${SLS_DOMAIN_PUBLISHER};
        default_sid ${SLS_DEFAULT_SID};
        backlog 100;
        idle_streams_timeout ${SLS_IDLE_TIMEOUT};

        app {
            app_player live;
            app_publisher live;

            allow publish all;
            allow play all;

            # VOD-Aufzeichnung
            record_hls ${SLS_RECORD_HLS};
            record_hls_segment_duration ${SLS_RECORD_HLS_SEGMENT_DURATION};
        }
    }
}
EOF

echo "Konfigurationsdatei erstellt."

# Signal-Handler, um alle Kindprozesse zu beenden
cleanup() {
    echo "Container wird gestoppt. Beende alle Prozesse..."
    kill $(jobs -p)
    exit 0
}

# Signal-Handler registrieren
trap cleanup SIGTERM SIGINT

# SRT-Server im Hintergrund starten
echo "Starte SRT-Server mit Port ${SLS_SRT_PORT} und HTTP-Port ${SLS_HTTP_PORT}..."
srt_server -c /etc/sls/sls.conf &
SRT_PID=$!
echo "SRT-Server gestartet mit PID: $SRT_PID"
sleep 10

# SRTLA-Receiver im Hintergrund starten
echo "Starte SRTLA-Receiver auf Port ${SRTLA_PORT}..."
srtla_rec --srtla_port ${SRTLA_PORT} --srt_hostname ${SRTLA_SRT_HOSTNAME} --srt_port ${SRTLA_SRT_PORT} &
SRTLA_PID=$!
echo "SRTLA-Receiver gestartet mit PID: $SRTLA_PID"

# Warte auf alle Hintergrundprozesse
echo "Alle Dienste gestartet. Container läuft..."
wait