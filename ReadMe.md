# SRT Live Server with SRTLA Support

This container provides an SRT (Secure Reliable Transport) Live Server with SRTLA support for reliable streaming over unreliable networks.

## Features

- SRT protocol for low-latency streaming
- SRTLA support for connection bundling across multiple network paths
- HTTP API for statistics and monitoring
- HLS recording functionality
- Configurable via environment variables

## Quick Start

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

## Configuration

The server is configured using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| SLS_HTTP_PORT | 8181 | HTTP server port for API and VOD |
| SLS_SRT_PORT | 8080 | SRT server port |
| SLS_LATENCY | 20 | Latency in ms |
| SLS_DOMAIN_PLAYER | live.sls | Domain for player |
| SLS_DOMAIN_PUBLISHER | uplive.sls | Domain for publisher |
| SLS_RECORD_HLS | off | Enable HLS recording (on/off) |
| SLS_RECORD_HLS_PATH | /tmp/mov/sls | Path for HLS recordings |
| SRTLA_PORT | 5000 | SRTLA port for connection bundling |

## Docker Volumes

It's recommended to mount the following volumes:
- `/logs`: For server logs
- `/tmp/mov/sls`: For HLS recordings

## Kubernetes Deployment with Helm

### Prerequisites

- Kubernetes cluster
- Helm v3+
- cert-manager (for TLS/HTTPS)

### Installation

```bash
# Pull the Helm chart from GitHub Container Registry
helm install srt-server oci://ghcr.io/letsplaybar/chart/srt-live-server --version <version> -f my-values.yaml
```

### Helm Configuration

Key configuration parameters in `values.yaml`:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of server replicas | `1` |
| `image.repository` | Docker image repository | `ghcr.io/letsplaybar/srt-live-server` |
| `image.tag` | Docker image tag | `latest` |
| `udpService.type` | Service type for UDP ports | `LoadBalancer` |
| `ingress.enabled` | Enable ingress for HTTP | `true` |
| `ingress.hosts` | Hostnames for ingress | `["example.com"]` |

### Networking

- **UDP Service**: Exposes SRT (8080/UDP) and SRTLA (5000/UDP) ports
- **HTTP Service**: Internal service for the HTTP interface
- **Ingress**: HTTP/HTTPS access with TLS support

### TLS/HTTPS Configuration

The Helm chart supports automatic TLS certificate management via cert-manager. Configure it in your `values.yaml`:

```yaml
ingress:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-cluster-issuer"
  tls:
    - secretName: srt-live-server-tls
      hosts:
        - "your-domain.com"
```