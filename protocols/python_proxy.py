#!/usr/bin/env python3
"""
Mastermind VPS Toolkit - Python Proxy Suite
Version: 2.0.0

This module provides SOCKS5 proxy, HTTP proxy, WebSocket-to-SSH SOCKS proxy,
and custom HTTP response servers with adjustable 101 responses.
"""

import os
import sys
import asyncio
import socket
import threading
import struct
import select
import time
import logging
import signal
import json
import hashlib
import base64
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import websockets
import ssl

# Configuration - Fixed port structure to avoid conflicts
SOCKS_PORT = int(os.getenv('SOCKS_PORT', '1080'))
RESPONSE_PORTS = [int(p) for p in os.getenv('RESPONSE_PORTS', '9000,9001,9002,9003').split(',')]
RESPONSE_MSG = os.getenv('RESPONSE_MSG', 'HTTP/1.1 101 <span style="color: #9fff;"><strong>MasterMind!!</strong></span>')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8080'))  # WebSocket-to-SSH SOCKS proxy
HTTP_PROXY_PORT = int(os.getenv('HTTP_PROXY_PORT', '8888'))
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
ENABLE_WEBSOCKET = os.getenv('ENABLE_WEBSOCKET', 'true').lower() == 'true'
ENABLE_HTTP_PROXY = os.getenv('ENABLE_HTTP_PROXY', 'true').lower() == 'true'

# SSH Configuration for WebSocket proxy
SSH_HOST = os.getenv('SSH_HOST', 'localhost')
SSH_PORT = int(os.getenv('SSH_PORT', '22'))
SSH_USER = os.getenv('SSH_USER', 'root')
SSH_PASS = os.getenv('SSH_PASS', '')
SSH_KEY_PATH = os.getenv('SSH_KEY_PATH', '')

# WebSocket to SSH SOCKS response templates
RESPONSE_TEMPLATES = {
    "default": {
        "Sec-WebSocket-Accept": "base64-key",
        "X-Protocol": "socks5",
        "Connection": "Upgrade",
        "Upgrade": "websocket"
    },
    "dropbear": {
        "Sec-WebSocket-Accept": "dropbear-specific-key",
        "X-Server": "Dropbear",
        "X-SSH-Version": "SSH-2.0-dropbear_2020.81",
        "Connection": "Upgrade",
        "Upgrade": "websocket"
    },
    "openssh": {
        "Sec-WebSocket-Accept": "openssh-specific-key", 
        "X-Server": "OpenSSH",
        "X-SSH-Version": "SSH-2.0-OpenSSH_8.9",
        "Connection": "Upgrade",
        "Upgrade": "websocket"
    }
}

# Setup logging
try:
    os.makedirs('/var/log/mastermind', exist_ok=True)
    log_file = '/var/log/mastermind/python-proxy.log'
except (OSError, PermissionError):
    # Fallback to local log directory if system path is not writable
    os.makedirs('./logs', exist_ok=True)
    log_file = './logs/python-proxy.log'

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('MastermindProxy')

class SOCKS5Server:
    """SOCKS5 Proxy Server Implementation"""
    
    def __init__(self, host='0.0.0.0', port=SOCKS_PORT):
        self.host = host
        self.port = port
        self.server_socket = None
        self.running = False
        
    def start(self):
        """Start the SOCKS5 server"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(128)
            self.running = True
            
            logger.info(f"SOCKS5 server started on {self.host}:{self.port}")
            
            while self.running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    logger.debug(f"New SOCKS5 connection from {addr}")
                    
                    # Handle connection in a separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, addr)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except Exception as e:
                    if self.running:
                        logger.error(f"Error accepting SOCKS5 connection: {e}")
                        
        except Exception as e:
            logger.error(f"Failed to start SOCKS5 server: {e}")
        finally:
            if self.server_socket:
                self.server_socket.close()
                
    def handle_client(self, client_socket, addr):
        """Handle SOCKS5 client connection"""
        try:
            # SOCKS5 authentication
            if not self.authenticate(client_socket):
                return
                
            # Handle SOCKS5 request
            self.handle_request(client_socket)
            
        except Exception as e:
            logger.error(f"Error handling SOCKS5 client {addr}: {e}")
        finally:
            client_socket.close()
            
    def authenticate(self, client_socket):
        """Handle SOCKS5 authentication"""
        try:
            # Read authentication methods
            data = client_socket.recv(2)
            if len(data) < 2:
                return False
                
            version, nmethods = struct.unpack('!BB', data)
            if version != 5:
                return False
                
            # Read methods
            methods = client_socket.recv(nmethods)
            if len(methods) < nmethods:
                return False
                
            # No authentication required (method 0)
            if 0 in methods:
                client_socket.send(struct.pack('!BB', 5, 0))
                return True
            else:
                client_socket.send(struct.pack('!BB', 5, 0xFF))
                return False
                
        except Exception as e:
            logger.error(f"SOCKS5 authentication error: {e}")
            return False
            
    def handle_request(self, client_socket):
        """Handle SOCKS5 connection request"""
        try:
            # Read request
            data = client_socket.recv(4)
            if len(data) < 4:
                return
                
            version, cmd, _, atyp = struct.unpack('!BBBB', data)
            
            if version != 5:
                return
                
            # Only support CONNECT command
            if cmd != 1:
                client_socket.send(struct.pack('!BBBBIH', 5, 7, 0, 1, 0, 0))
                return
                
            # Read destination address
            if atyp == 1:  # IPv4
                addr_data = client_socket.recv(4)
                addr = socket.inet_ntoa(addr_data)
            elif atyp == 3:  # Domain name
                addr_len = struct.unpack('!B', client_socket.recv(1))[0]
                addr = client_socket.recv(addr_len).decode('utf-8')
            else:
                client_socket.send(struct.pack('!BBBBIH', 5, 8, 0, 1, 0, 0))
                return
                
            # Read destination port
            port_data = client_socket.recv(2)
            port = struct.unpack('!H', port_data)[0]
            
            # Connect to destination
            try:
                remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                remote_socket.connect((addr, port))
                
                # Send success response
                client_socket.send(struct.pack('!BBBBIH', 5, 0, 0, 1, 0, 0))
                
                # Start relaying data
                self.relay_data(client_socket, remote_socket)
                
            except Exception as e:
                logger.error(f"Failed to connect to {addr}:{port}: {e}")
                client_socket.send(struct.pack('!BBBBIH', 5, 1, 0, 1, 0, 0))
                
        except Exception as e:
            logger.error(f"Error handling SOCKS5 request: {e}")
            
    def relay_data(self, client_socket, remote_socket):
        """Relay data between client and remote server"""
        try:
            sockets = [client_socket, remote_socket]
            
            while True:
                ready, _, _ = select.select(sockets, [], [], 60)
                
                if not ready:
                    break
                    
                for sock in ready:
                    try:
                        data = sock.recv(8192)
                        if not data:
                            return
                            
                        if sock is client_socket:
                            remote_socket.send(data)
                        else:
                            client_socket.send(data)
                            
                    except Exception:
                        return
                        
        except Exception as e:
            logger.error(f"Error relaying data: {e}")
        finally:
            remote_socket.close()
            
    def stop(self):
        """Stop the SOCKS5 server"""
        self.running = False
        if self.server_socket:
            self.server_socket.close()
            
class HTTPResponseHandler(BaseHTTPRequestHandler):
    """Custom HTTP response handler"""
    
    def do_GET(self):
        """Handle GET requests"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Server', 'Mastermind-Proxy/1.0')
        self.end_headers()
        
        # Generate response based on port
        response = self.generate_response()
        self.wfile.write(response.encode('utf-8'))
        
    def do_POST(self):
        """Handle POST requests"""
        self.do_GET()
        
    def generate_response(self):
        """Generate SSH server response message for tunneling apps"""
        port = self.server.server_port
        
        # Generate SSH-style server response like shown in NPV Tunnel
        # Updated for new port structure (9000-9003) - matches NPV Tunnel display
        ssh_responses = {
            9000: 'SSH-2.0-dropbear_2020.81',
            9001: '<div style="font-family: monospace; background-color: #000; color: #0f0; padding: 10px; text-align: center; border: 1px solid #0f0;"><strong style="font-size: 18px;">MasterMind\'s Server</strong><br>For support: Contact <span style="color: #00f;">@bitcockli</span> on Telegram<br><em style="color: #f00;">WARNING: Unauthorized access prohibited. All connections monitored.</em></div>',
            9002: 'HTTP/1.1 101 <span style="color: #9fff;"><strong>MasterMind!!</strong></span>',
            9003: 'SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.1'
        }
        
        # Get response for current port or default
        response = ssh_responses.get(port, 'SSH-2.0-dropbear_2020.81')
        
        # Create minimal HTML wrapper that shows the SSH response
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>SSH Server Response</title>
    <style>
        body {{
            font-family: monospace;
            background-color: #000;
            color: #00ff00;
            padding: 20px;
            margin: 0;
        }}
        .ssh-response {{
            background-color: #111;
            border: 1px solid #333;
            padding: 15px;
            border-radius: 5px;
            white-space: pre-wrap;
        }}
    </style>
</head>
<body>
    <div class="ssh-response">
SSH Server response: {response}
    </div>
</body>
</html>"""
        
        return html
        
    def log_message(self, format, *args):
        """Override log message to use our logger"""
        logger.info(f"HTTP {self.server.server_port}: {format % args}")
        
class HTTPResponseServer:
    """HTTP Response Server"""
    
    def __init__(self, port):
        self.port = port
        self.server = None
        self.thread = None
        
    def start(self):
        """Start the HTTP response server"""
        try:
            self.server = HTTPServer(('0.0.0.0', self.port), HTTPResponseHandler)
            self.thread = threading.Thread(target=self.server.serve_forever)
            self.thread.daemon = True
            self.thread.start()
            
            logger.info(f"HTTP response server started on port {self.port}")
            
        except Exception as e:
            logger.error(f"Failed to start HTTP response server on port {self.port}: {e}")
            
    def stop(self):
        """Stop the HTTP response server"""
        if self.server:
            self.server.shutdown()
            self.server.server_close()
            
class WebSocketToSSHProxy:
    """WebSocket to SSH SOCKS proxy implementation"""
    
    def __init__(self, host='0.0.0.0', port=WEBSOCKET_PORT):
        self.host = host
        self.port = port
        self.server = None
        self.ssh_connections = {}
        
    async def start(self):
        """Start the WebSocket proxy server"""
        try:
            self.server = await websockets.serve(
                self.handle_websocket_connection,
                self.host,
                self.port,
                subprotocols=["socks"]
            )
            logger.info(f"WebSocket-to-SSH SOCKS proxy started on {self.host}:{self.port}")
            
        except Exception as e:
            logger.error(f"Failed to start WebSocket-to-SSH proxy: {e}")
            
    async def handle_websocket_connection(self, websocket, path):
        """Handle WebSocket connections with SSH SOCKS tunneling"""
        try:
            remote_addr = websocket.remote_address
            logger.info(f"New WebSocket connection from {remote_addr}")
            
            # Perform custom handshake with adjustable 101 response
            await self.custom_handshake(websocket)
            
            # Create SSH tunnel and SOCKS proxy
            ssh_process, socks_port = await self.create_ssh_tunnel()
            
            if ssh_process and socks_port:
                # Store SSH connection
                connection_id = f"{remote_addr[0]}:{remote_addr[1]}"
                self.ssh_connections[connection_id] = ssh_process
                
                # Create bridge between WebSocket and SOCKS proxy
                await self.create_tunnel_bridge(websocket, socks_port)
            else:
                await websocket.close(code=1011, reason="SSH tunnel creation failed")
                
        except websockets.exceptions.ConnectionClosed:
            logger.debug("WebSocket connection closed")
        except Exception as e:
            logger.error(f"WebSocket connection error: {e}")
        finally:
            # Clean up SSH connection
            if hasattr(websocket, 'remote_address'):
                connection_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
                if connection_id in self.ssh_connections:
                    self.cleanup_ssh_connection(connection_id)
                    
    async def custom_handshake(self, websocket):
        """Perform custom handshake with adjustable 101 response"""
        try:
            # Determine response template based on User-Agent or other headers
            template = "default"
            user_agent = websocket.request_headers.get("User-Agent", "").lower()
            
            if "dropbear" in user_agent:
                template = "dropbear"
            elif "openssh" in user_agent:
                template = "openssh"
                
            # Get response headers from template
            headers = RESPONSE_TEMPLATES.get(template, RESPONSE_TEMPLATES["default"])
            
            # Generate proper WebSocket accept key
            websocket_key = websocket.request_headers.get("Sec-WebSocket-Key", "")
            if websocket_key:
                accept_key = self.generate_websocket_accept_key(websocket_key)
                headers["Sec-WebSocket-Accept"] = accept_key
                
            logger.debug(f"Using handshake template: {template}")
            
        except Exception as e:
            logger.error(f"Handshake error: {e}")
            
    def generate_websocket_accept_key(self, websocket_key):
        """Generate proper WebSocket accept key"""
        guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        combined = websocket_key + guid
        sha1_hash = hashlib.sha1(combined.encode()).digest()
        return base64.b64encode(sha1_hash).decode()
        
    async def create_ssh_tunnel(self):
        """Create SSH tunnel with dynamic SOCKS proxy"""
        try:
            # Find available port for SOCKS proxy
            socks_port = self.find_available_port()
            
            # Build SSH command for dynamic port forwarding
            ssh_cmd = [
                "ssh",
                "-N",  # Don't execute remote commands
                "-D", str(socks_port),  # Dynamic port forwarding (SOCKS)
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "ServerAliveInterval=30",
                "-o", "ServerAliveCountMax=3"
            ]
            
            # Add authentication
            if SSH_KEY_PATH and os.path.exists(SSH_KEY_PATH):
                ssh_cmd.extend(["-i", SSH_KEY_PATH])
            elif SSH_PASS:
                # Use sshpass for password authentication
                ssh_cmd = ["sshpass", "-p", SSH_PASS] + ssh_cmd
                
            # Add SSH target
            ssh_cmd.append(f"{SSH_USER}@{SSH_HOST}")
            
            if SSH_PORT != 22:
                ssh_cmd.extend(["-p", str(SSH_PORT)])
                
            # Start SSH process
            ssh_process = subprocess.Popen(
                ssh_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Wait a moment for SSH to establish
            await asyncio.sleep(2)
            
            # Check if SSH tunnel is working
            if ssh_process.poll() is None:
                # Test SOCKS proxy connection
                if await self.test_socks_connection(socks_port):
                    logger.info(f"SSH tunnel established with SOCKS proxy on port {socks_port}")
                    return ssh_process, socks_port
                else:
                    ssh_process.terminate()
                    logger.error("SOCKS proxy test failed")
            else:
                logger.error("SSH process failed to start")
                
            return None, None
            
        except Exception as e:
            logger.error(f"SSH tunnel creation error: {e}")
            return None, None
            
    def find_available_port(self, start_port=10000, end_port=65535):
        """Find an available port for SOCKS proxy"""
        for port in range(start_port, end_port):
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.bind(('127.0.0.1', port))
                    return port
            except OSError:
                continue
        return None
        
    async def test_socks_connection(self, socks_port):
        """Test if SOCKS proxy is working"""
        try:
            test_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            test_socket.settimeout(5)
            test_socket.connect(('127.0.0.1', socks_port))
            test_socket.close()
            return True
        except Exception:
            return False
            
    async def create_tunnel_bridge(self, websocket, socks_port):
        """Create bidirectional bridge between WebSocket and SOCKS proxy"""
        try:
            # Connect to SOCKS proxy
            reader, writer = await asyncio.open_connection('127.0.0.1', socks_port)
            
            # Create tasks for bidirectional data relay
            ws_to_socks_task = asyncio.create_task(
                self.websocket_to_socks(websocket, writer)
            )
            socks_to_ws_task = asyncio.create_task(
                self.socks_to_websocket(reader, websocket)
            )
            
            # Wait for either task to complete (indicating connection closed)
            done, pending = await asyncio.wait(
                [ws_to_socks_task, socks_to_ws_task],
                return_when=asyncio.FIRST_COMPLETED
            )
            
            # Cancel remaining tasks
            for task in pending:
                task.cancel()
                
            # Close writer
            writer.close()
            await writer.wait_closed()
            
        except Exception as e:
            logger.error(f"Tunnel bridge error: {e}")
            
    async def websocket_to_socks(self, websocket, writer):
        """Relay data from WebSocket to SOCKS proxy"""
        try:
            async for message in websocket:
                if isinstance(message, bytes):
                    writer.write(message)
                    await writer.drain()
                elif isinstance(message, str):
                    writer.write(message.encode())
                    await writer.drain()
        except Exception as e:
            logger.debug(f"WebSocket to SOCKS relay ended: {e}")
            
    async def socks_to_websocket(self, reader, websocket):
        """Relay data from SOCKS proxy to WebSocket"""
        try:
            while True:
                data = await reader.read(4096)
                if not data:
                    break
                await websocket.send(data)
        except Exception as e:
            logger.debug(f"SOCKS to WebSocket relay ended: {e}")
            
    def cleanup_ssh_connection(self, connection_id):
        """Clean up SSH connection"""
        try:
            if connection_id in self.ssh_connections:
                ssh_process = self.ssh_connections[connection_id]
                ssh_process.terminate()
                del self.ssh_connections[connection_id]
                logger.debug(f"Cleaned up SSH connection: {connection_id}")
        except Exception as e:
            logger.error(f"SSH cleanup error: {e}")
            
class HTTPProxyHandler(BaseHTTPRequestHandler):
    """HTTP Proxy handler"""
    
    def do_CONNECT(self):
        """Handle CONNECT method for HTTPS tunneling"""
        try:
            # Parse the request
            host, port = self.path.split(':')
            port = int(port)
            
            # Connect to the target server
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.connect((host, port))
            
            # Send success response
            self.send_response(200, 'Connection Established')
            self.end_headers()
            
            # Start tunneling
            self.tunnel_data(self.connection, target_socket)
            
        except Exception as e:
            logger.error(f"CONNECT error: {e}")
            self.send_error(500, 'Internal Server Error')
            
    def tunnel_data(self, client_socket, target_socket):
        """Tunnel data between client and target"""
        try:
            sockets = [client_socket, target_socket]
            
            while True:
                ready, _, _ = select.select(sockets, [], [], 60)
                
                if not ready:
                    break
                    
                for sock in ready:
                    try:
                        data = sock.recv(8192)
                        if not data:
                            return
                            
                        if sock is client_socket:
                            target_socket.send(data)
                        else:
                            client_socket.send(data)
                            
                    except Exception:
                        return
                        
        except Exception as e:
            logger.error(f"Tunnel error: {e}")
        finally:
            target_socket.close()
            
    def log_message(self, format, *args):
        """Override log message"""
        logger.info(f"HTTP Proxy: {format % args}")
        
class HTTPProxyServer:
    """HTTP Proxy Server"""
    
    def __init__(self, host='0.0.0.0', port=HTTP_PROXY_PORT):
        self.host = host
        self.port = port
        self.server = None
        self.thread = None
        
    def start(self):
        """Start the HTTP proxy server"""
        try:
            self.server = HTTPServer((self.host, self.port), HTTPProxyHandler)
            self.thread = threading.Thread(target=self.server.serve_forever)
            self.thread.daemon = True
            self.thread.start()
            
            logger.info(f"HTTP proxy server started on {self.host}:{self.port}")
            
        except Exception as e:
            logger.error(f"Failed to start HTTP proxy server: {e}")
            
    def stop(self):
        """Stop the HTTP proxy server"""
        if self.server:
            self.server.shutdown()
            self.server.server_close()
            
class MastermindProxyManager:
    """Main proxy manager"""
    
    def __init__(self):
        self.socks5_server = None
        self.http_servers = []
        self.websocket_proxy = None
        self.http_proxy = None
        self.running = False
        
    def start_all(self):
        """Start all proxy services"""
        logger.info("Starting Mastermind Proxy Suite v2.0...")
        
        # Start SOCKS5 server
        self.socks5_server = SOCKS5Server()
        socks5_thread = threading.Thread(target=self.socks5_server.start)
        socks5_thread.daemon = True
        socks5_thread.start()
        
        # Start HTTP response servers on new ports (avoiding conflicts)
        for port in RESPONSE_PORTS:
            server = HTTPResponseServer(port)
            server.start()
            self.http_servers.append(server)
            
        # Start WebSocket-to-SSH SOCKS proxy if enabled
        if ENABLE_WEBSOCKET:
            self.websocket_proxy = WebSocketToSSHProxy()
            ws_thread = threading.Thread(target=self._start_websocket)
            ws_thread.daemon = True
            ws_thread.start()
            
        # Start HTTP proxy if enabled
        if ENABLE_HTTP_PROXY:
            self.http_proxy = HTTPProxyServer()
            self.http_proxy.start()
            
        self.running = True
        logger.info("All proxy services started successfully")
        logger.info(f"Service ports: SOCKS5({SOCKS_PORT}), WebSocket-SSH({WEBSOCKET_PORT}), HTTP-Proxy({HTTP_PROXY_PORT})")
        logger.info(f"Response servers on ports: {RESPONSE_PORTS}")
        
    def stop_all(self):
        """Stop all proxy services"""
        logger.info("Stopping Mastermind Proxy Suite...")
        
        self.running = False
        
        # Stop SOCKS5 server
        if self.socks5_server:
            self.socks5_server.stop()
            
        # Stop HTTP response servers
        for server in self.http_servers:
            server.stop()
            
        # Stop WebSocket-to-SSH proxy
        if self.websocket_proxy:
            # Clean up all SSH connections
            for connection_id in list(self.websocket_proxy.ssh_connections.keys()):
                self.websocket_proxy.cleanup_ssh_connection(connection_id)
            
        # Stop HTTP proxy
        if self.http_proxy:
            self.http_proxy.stop()
            
        logger.info("All proxy services stopped")
        
    def _start_websocket(self):
        """Start WebSocket-to-SSH proxy in new event loop"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(self.websocket_proxy.start())
            loop.run_forever()
        except Exception as e:
            logger.error(f"WebSocket-to-SSH proxy error: {e}")
            
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, shutting down...")
        self.stop_all()
        sys.exit(0)
        
def main():
    """Main function"""
    # Create proxy manager
    proxy_manager = MastermindProxyManager()
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, proxy_manager.signal_handler)
    signal.signal(signal.SIGTERM, proxy_manager.signal_handler)
    
    try:
        # Start all services
        proxy_manager.start_all()
        
        # Keep the main thread alive
        while proxy_manager.running:
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt, shutting down...")
        proxy_manager.stop_all()
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        proxy_manager.stop_all()
        sys.exit(1)
        
if __name__ == "__main__":
    main()
