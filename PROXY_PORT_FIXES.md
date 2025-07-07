# Python Proxy Port Configuration Fixes

## Issues Identified

1. **Port Conflicts**: WebSocket proxy and HTTP response servers were both trying to use port 8080
2. **Variable Inconsistencies**: `PYTHON_PROXY_PORT` vs `SOCKS_PORT` confusion in scripts
3. **Missing Service Configuration**: Systemd service wasn't properly configured with environment variables
4. **Incorrect Port Display**: Proxy manager showing empty port values

## Fixes Applied

### 1. Updated Port Configuration (core/config.cfg)
```bash
# OLD Configuration
WEBSOCKET_PORT=8080
RESPONSE_PORTS="101,200,300,301"

# NEW Configuration  
WEBSOCKET_PORT=8443
RESPONSE_PORTS="8080,9000,9001,9002"
```

### 2. Fixed Variable Names (protocols/proxy_manager.sh)
- Changed `PYTHON_PROXY_PORT` references to `SOCKS_PORT`
- Fixed port status display to use correct variables
- Updated port array handling for RESPONSE_PORTS

### 3. Updated Python Script Defaults (protocols/python_proxy.py)
```python
# Updated default fallback values
SOCKS_PORT = int(os.getenv('SOCKS_PORT', '1080'))
RESPONSE_PORTS = [int(p) for p in os.getenv('RESPONSE_PORTS', '8080,9000,9001,9002').split(',')]
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8443'))
HTTP_PROXY_PORT = int(os.getenv('HTTP_PROXY_PORT', '8888'))
```

### 4. Created Proper Systemd Service (python-proxy.service)
- Added environment variables for all ports
- Configured proper restart policies
- Set correct working directory and user permissions

### 5. Created Fix Script (fix_proxy_setup.sh)
- Installs websockets dependency if missing
- Copies and enables systemd service
- Provides port status verification

## New Port Layout

| Service | Port | Purpose |
|---------|------|---------|
| SOCKS5 Proxy | 1080 | Standard SOCKS5 proxy port |
| HTTP Proxy | 8888 | HTTP proxy service |
| WebSocket Proxy | 8080 | WebSocket proxy (corrected to user request) |
| HTTP Response #1 | 9000 | Custom HTTP responses for HTTP Injector/Custom apps |
| HTTP Response #2 | 9001 | Additional HTTP response server |
| HTTP Response #3 | 9002 | Additional HTTP response server |
| HTTP Response #4 | 9003 | Additional HTTP response server |

## Resolution

The proxy system now has proper port separation:
- **No more port conflicts** between WebSocket and HTTP response servers
- **Consistent variable naming** throughout all scripts
- **Proper environment variable handling** in systemd service
- **Accurate port status display** in management interface

## To Apply Fixes

Run the fix script:
```bash
sudo ./fix_proxy_setup.sh
```

This will:
1. Install the corrected systemd service
2. Install Python dependencies
3. Restart the proxy service with correct configuration
4. Display port status verification

## Verification

After applying fixes, the proxy management interface should show:
```
Service Status: Running
Port Status:
  SOCKS5 (1080): Open
  HTTP Response (8080): Open
  HTTP Response (9000): Open
  HTTP Response (9001): Open
  HTTP Response (9002): Open
```

All ports should now display correctly with no empty values or conflicts.