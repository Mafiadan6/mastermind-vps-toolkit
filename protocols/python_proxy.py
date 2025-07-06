#!/usr/bin/env python3
"""
Mastermind VPS Toolkit - Python Proxy Suite
Version: 1.0.0

This module provides SOCKS5 proxy, HTTP proxy, and WebSocket proxy services
along with custom HTTP response servers.
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
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import websockets
import ssl

# Configuration
SOCKS_PORT = int(os.getenv('SOCKS_PORT', '8080'))
RESPONSE_PORTS = [int(p) for p in os.getenv('RESPONSE_PORTS', '101,200,300,301').split(',')]
RESPONSE_MSG = os.getenv('RESPONSE_MSG', 'Mastermind VPS Toolkit')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8081'))
HTTP_PROXY_PORT = int(os.getenv('HTTP_PROXY_PORT', '8082'))
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
ENABLE_WEBSOCKET = os.getenv('ENABLE_WEBSOCKET', 'true').lower() == 'true'
ENABLE_HTTP_PROXY = os.getenv('ENABLE_HTTP_PROXY', 'true').lower() == 'true'

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
        """Generate custom response"""
        port = self.server.server_port
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>{RESPONSE_MSG}</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    text-align: center;
                    padding: 50px;
                }}
                .container {{
                    max-width: 600px;
                    margin: 0 auto;
                    background: rgba(0,0,0,0.3);
                    padding: 40px;
                    border-radius: 10px;
                }}
                h1 {{
                    font-size: 2.5em;
                    margin-bottom: 20px;
                }}
                .info {{
                    font-size: 1.2em;
                    margin: 20px 0;
                }}
                .port {{
                    font-size: 3em;
                    font-weight: bold;
                    color: #ffd700;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>{RESPONSE_MSG}</h1>
                <div class="port">Port {port}</div>
                <div class="info">
                    <p>Server: {socket.gethostname()}</p>
                    <p>Time: {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
                    <p>Status: Active</p>
                </div>
            </div>
        </body>
        </html>
        """
        
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
            
class WebSocketProxy:
    """WebSocket to TCP proxy"""
    
    def __init__(self, host='0.0.0.0', port=WEBSOCKET_PORT):
        self.host = host
        self.port = port
        self.server = None
        
    async def start(self):
        """Start the WebSocket proxy server"""
        try:
            self.server = await websockets.serve(
                self.handle_websocket,
                self.host,
                self.port
            )
            logger.info(f"WebSocket proxy started on {self.host}:{self.port}")
            
        except Exception as e:
            logger.error(f"Failed to start WebSocket proxy: {e}")
            
    async def handle_websocket(self, websocket, path):
        """Handle WebSocket connections"""
        try:
            logger.debug(f"New WebSocket connection from {websocket.remote_address}")
            
            # Handle WebSocket to TCP proxy logic here
            # This is a basic echo server for demonstration
            async for message in websocket:
                await websocket.send(f"Echo: {message}")
                
        except websockets.exceptions.ConnectionClosed:
            logger.debug("WebSocket connection closed")
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
            
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
        logger.info("Starting Mastermind Proxy Suite...")
        
        # Start SOCKS5 server
        self.socks5_server = SOCKS5Server()
        socks5_thread = threading.Thread(target=self.socks5_server.start)
        socks5_thread.daemon = True
        socks5_thread.start()
        
        # Start HTTP response servers
        for port in RESPONSE_PORTS:
            server = HTTPResponseServer(port)
            server.start()
            self.http_servers.append(server)
            
        # Start WebSocket proxy if enabled
        if ENABLE_WEBSOCKET:
            self.websocket_proxy = WebSocketProxy()
            ws_thread = threading.Thread(target=self._start_websocket)
            ws_thread.daemon = True
            ws_thread.start()
            
        # Start HTTP proxy if enabled
        if ENABLE_HTTP_PROXY:
            self.http_proxy = HTTPProxyServer()
            self.http_proxy.start()
            
        self.running = True
        logger.info("All proxy services started successfully")
        
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
            
        # Stop HTTP proxy
        if self.http_proxy:
            self.http_proxy.stop()
            
        logger.info("All proxy services stopped")
        
    def _start_websocket(self):
        """Start WebSocket proxy in new event loop"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(self.websocket_proxy.start())
        except Exception as e:
            logger.error(f"WebSocket proxy error: {e}")
            
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
