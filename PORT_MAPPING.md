# Mastermind VPS Toolkit - Port Mapping

## Default Port Configuration

| Service | Port | Protocol | Description | Configurable |
|---------|------|----------|-------------|--------------|
| **SSH Services** |
| OpenSSH | 22 | TCP | Standard SSH access | ✓ |
| SSH TLS | 443 | TCP | SSH over TLS/SSL | ✓ |
| SSH UDP | 2222 | UDP | SSH over UDP tunnel | ✓ |
| Dropbear | 444 | TCP | Lightweight SSH daemon | ✓ |
| Dropbear Alt | 445 | TCP | Alternative Dropbear port | ✓ |
| **Proxy Services** |
| SOCKS5 | 1080 | TCP | SOCKS5 proxy server | ✓ |
| HTTP Proxy | 8888 | TCP | HTTP proxy server | ✓ |
| Squid Proxy | 3128 | TCP | Squid HTTP proxy | ✓ |
| Squid Transparent | 3129 | TCP | Transparent proxy | ✓ |
| Squid SSL | 8443 | TCP | SSL proxy | ✓ |
| WebSocket | 8000 | TCP | WebSocket to TCP proxy | ✓ |
| **VPN & Tunneling** |
| V2Ray | 10443 | TCP | V2Ray proxy protocol | ✓ |
| BadVPN UDP | 7300 | UDP | UDP gateway service | ✓ |
| TCP Bypass | 12345 | TCP | TCP bypass proxy | ✓ |
| **Response Servers** |
| Response 1 | 101 | TCP | Custom HTTP response | ✓ |
| Response 2 | 200 | TCP | Custom HTTP response | ✓ |
| Response 3 | 300 | TCP | Custom HTTP response | ✓ |
| Response 4 | 301 | TCP | Custom HTTP response | ✓ |
| **System Services** |
| HTTP | 80 | TCP | Web server | - |
| HTTPS | 443 | TCP | Secure web server | - |

## Port Conflict Resolution

### Resolved Conflicts:
1. **Port 443**: Originally used by both V2Ray and SSH TLS
   - Solution: Moved V2Ray to port 10443
   - SSH TLS remains on port 443 (standard HTTPS port)

2. **Port 8080**: Used by both Python Proxy and HTTP Proxy
   - Solution: Moved HTTP Proxy to port 8888
   - Python Proxy remains on port 8080

### Reserved System Ports:
- **1-1023**: Well-known ports (requires root privileges)
- **22**: SSH (can be changed but not recommended)
- **53**: DNS (system reserved)
- **80**: HTTP (system reserved)
- **443**: HTTPS/SSH TLS (system reserved)

## Configuration Management

All ports can be adjusted through the system configuration:

1. **Main Configuration**: `/opt/mastermind/core/config.cfg`
2. **Menu System**: System Settings > Port Configuration
3. **Individual Services**: Each service has its own port configuration option

## Firewall Rules

The following ports should be opened in the firewall:

```bash
# SSH Services
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 444/tcp
ufw allow 445/tcp
ufw allow 2222/udp

# Proxy Services
ufw allow 1080/tcp
ufw allow 3128/tcp
ufw allow 8000/tcp
ufw allow 8443/tcp
ufw allow 8888/tcp

# VPN & Tunneling
ufw allow 7300/udp
ufw allow 10443/tcp

# Response Servers
ufw allow 101/tcp
ufw allow 200/tcp
ufw allow 300/tcp
ufw allow 301/tcp

# System Services
ufw allow 80/tcp
```

## Testing Port Availability

Before starting services, the toolkit automatically checks for port conflicts:

```bash
# Check if port is available
netstat -tlnp | grep :PORT_NUMBER

# Test port connectivity
telnet SERVER_IP PORT_NUMBER
```

## Dynamic Port Assignment

The toolkit supports dynamic port assignment for:
- All proxy services
- SSH services (except standard SSH port 22)
- Response servers
- Custom applications

## Best Practices

1. **Production Environments**:
   - Use standard ports when possible (22, 80, 443)
   - Avoid conflicts with system services
   - Document any custom port assignments

2. **Security Considerations**:
   - Change default SSH port (22) to non-standard port
   - Use high-numbered ports (>1024) for custom services
   - Implement proper firewall rules

3. **Load Balancing**:
   - Distribute services across different port ranges
   - Consider using multiple ports for the same service
   - Monitor port usage and performance

## Troubleshooting

### Common Issues:
1. **Port Already in Use**: Check with `netstat -tlnp | grep :PORT`
2. **Permission Denied**: Ports <1024 require root privileges
3. **Firewall Blocking**: Ensure firewall rules allow the port
4. **Service Not Starting**: Check service logs for port conflicts

### Recovery Steps:
1. Stop conflicting services
2. Update port configuration
3. Restart affected services
4. Update firewall rules
5. Test connectivity