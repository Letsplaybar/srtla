# SRT Live Server mit SRTLA-Unterstützung

Dieser Container bietet einen SRT (Secure Reliable Transport) Live-Server mit SRTLA-Unterstützung für zuverlässiges Streaming über unzuverlässige Netzwerke.

## Funktionen

- SRT-Protokoll für latenzarmes Streaming
- SRTLA-Support für Verbindungsbündelung über mehrere Netzwerkpfade
- HTTP-API für Statistiken und Monitoring
- HLS-Recording-Funktionalität
- VOD (Video-on-Demand) Zugriff auf aufgezeichnete Streams
- Konfigurierbar über Umgebungsvariablen

## Schnellstart

```bash
docker run -d \
  -p 8181:8181 \
  -p 8080:8080/udp \
  -p 5000:5000/udp \
  -v /path/to/recordings:/tmp/mov/sls \
  -e SLS_RECORD_HLS=on \
  --name srt-live-server \
  ghcr.io/letsplaybar/srt-live-server:latest
```

## Konfiguration

Der Server wird über Umgebungsvariablen konfiguriert:

| Variable | Standard | Beschreibung |
|----------|---------|-------------|
| SLS_HTTP_PORT | 8181 | HTTP-Server-Port für API und VOD |
| SLS_SRT_PORT | 8080 | SRT-Server-Port |
| SLS_LATENCY | 20 | Latenz in ms |
| SLS_DOMAIN_PLAYER | live.sls | Domain für Player |
| SLS_DOMAIN_PUBLISHER | uplive.sls | Domain für Publisher |
| SLS_RECORD_HLS | off | HLS-Aufzeichnung aktivieren (on/off) |
| SLS_RECORD_HLS_PATH | /tmp/mov/sls | Pfad für HLS-Aufzeichnungen |
| SRTLA_PORT | 5000 | SRTLA-Port für Verbindungsbündelung |

## Docker-Volumes

Es wird empfohlen, folgende Volumes zu mounten:
- `/logs`: Für Server-Logs
- `/tmp/mov/sls`: Für HLS-Aufzeichnungen