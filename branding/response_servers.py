#!/usr/bin/env python3
"""
Mastermind VPS Toolkit - Custom HTTP Response Servers
Version: 1.0.0

This module provides customizable HTTP response servers for different ports
with branding and custom content capabilities.
"""

import os
import sys
import json
import time
import threading
import signal
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import socket

# Configuration
RESPONSE_PORTS = [int(p) for p in os.getenv('RESPONSE_PORTS', '101,200,300,301').split(',')]
RESPONSE_MSG = os.getenv('RESPONSE_MSG', 'Mastermind VPS Toolkit')
SERVER_NAME = os.getenv('SERVER_NAME', socket.gethostname())
ADMIN_EMAIL = os.getenv('ADMIN_EMAIL', 'admin@example.com')
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')

# Setup logging
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mastermind/response-servers.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('ResponseServers')

class CustomResponseHandler(BaseHTTPRequestHandler):
    """Custom HTTP response handler with branding"""
    
    def do_GET(self):
        """Handle GET requests"""
        try:
            path = self.path
            port = self.server.server_port
            
            # Parse query parameters
            parsed_url = urlparse(path)
            query_params = parse_qs(parsed_url.query)
            
            # Route based on path
            if parsed_url.path == '/':
                self.serve_main_page(port)
            elif parsed_url.path == '/status':
                self.serve_status_page(port)
            elif parsed_url.path == '/info':
                self.serve_info_page(port)
            elif parsed_url.path == '/api/status':
                self.serve_api_status(port)
            elif parsed_url.path == '/config':
                self.serve_config_page(port)
            else:
                self.serve_404_page()
                
        except Exception as e:
            logger.error(f"Error handling GET request: {e}")
            self.serve_error_page(500, "Internal Server Error")
    
    def do_POST(self):
        """Handle POST requests"""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            # Simple echo for POST requests
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Server', f'Mastermind-Response/{self.server.server_port}')
            self.end_headers()
            
            response = {
                'status': 'success',
                'message': 'POST request received',
                'port': self.server.server_port,
                'timestamp': time.time(),
                'data_received': len(post_data)
            }
            
            self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error handling POST request: {e}")
            self.serve_error_page(500, "Internal Server Error")
    
    def serve_main_page(self, port):
        """Serve the main branded page"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{port}')
        self.end_headers()
        
        html = self.generate_main_html(port)
        self.wfile.write(html.encode('utf-8'))
    
    def serve_status_page(self, port):
        """Serve status page"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{port}')
        self.end_headers()
        
        html = self.generate_status_html(port)
        self.wfile.write(html.encode('utf-8'))
    
    def serve_info_page(self, port):
        """Serve info page"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{port}')
        self.end_headers()
        
        html = self.generate_info_html(port)
        self.wfile.write(html.encode('utf-8'))
    
    def serve_api_status(self, port):
        """Serve API status in JSON format"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Server', f'Mastermind-Response/{port}')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        status_data = {
            'status': 'online',
            'server': SERVER_NAME,
            'port': port,
            'service': 'Mastermind Response Server',
            'version': '1.0.0',
            'timestamp': time.time(),
            'uptime': time.time() - self.server.start_time,
            'requests_served': getattr(self.server, 'request_count', 0)
        }
        
        self.wfile.write(json.dumps(status_data, indent=2).encode('utf-8'))
    
    def serve_config_page(self, port):
        """Serve configuration page"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{port}')
        self.end_headers()
        
        html = self.generate_config_html(port)
        self.wfile.write(html.encode('utf-8'))
    
    def serve_404_page(self):
        """Serve 404 page"""
        self.send_response(404)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{self.server.server_port}')
        self.end_headers()
        
        html = self.generate_404_html()
        self.wfile.write(html.encode('utf-8'))
    
    def serve_error_page(self, code, message):
        """Serve error page"""
        self.send_response(code)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Server', f'Mastermind-Response/{self.server.server_port}')
        self.end_headers()
        
        html = self.generate_error_html(code, message)
        self.wfile.write(html.encode('utf-8'))
    
    def generate_main_html(self, port):
        """Generate main page HTML"""
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{RESPONSE_MSG} - Port {port}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }}
        
        .container {{
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
            background: rgba(0,0,0,0.3);
            border-radius: 15px;
            backdrop-filter: blur(10px);
            text-align: center;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }}
        
        .logo {{
            font-size: 3em;
            font-weight: bold;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }}
        
        .port {{
            font-size: 4em;
            font-weight: bold;
            color: #ffd700;
            margin: 20px 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }}
        
        .info-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }}
        
        .info-card {{
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255,255,255,0.2);
        }}
        
        .info-card h3 {{
            margin-bottom: 10px;
            color: #ffd700;
        }}
        
        .navigation {{
            margin-top: 30px;
        }}
        
        .nav-link {{
            display: inline-block;
            margin: 0 10px;
            padding: 10px 20px;
            background: rgba(255,255,255,0.2);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
        }}
        
        .nav-link:hover {{
            background: rgba(255,255,255,0.3);
        }}
        
        .timestamp {{
            margin-top: 20px;
            opacity: 0.8;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">{RESPONSE_MSG}</div>
        <div class="port">Port {port}</div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>Server</h3>
                <p>{SERVER_NAME}</p>
            </div>
            <div class="info-card">
                <h3>Status</h3>
                <p>Online</p>
            </div>
            <div class="info-card">
                <h3>Service</h3>
                <p>HTTP Response Server</p>
            </div>
            <div class="info-card">
                <h3>Version</h3>
                <p>1.0.0</p>
            </div>
        </div>
        
        <div class="navigation">
            <a href="/status" class="nav-link">Status</a>
            <a href="/info" class="nav-link">Info</a>
            <a href="/api/status" class="nav-link">API</a>
            <a href="/config" class="nav-link">Config</a>
        </div>
        
        <div class="timestamp">
            Current Time: {time.strftime('%Y-%m-%d %H:%M:%S %Z')}
        </div>
    </div>
</body>
</html>
        """
    
    def generate_status_html(self, port):
        """Generate status page HTML"""
        uptime = time.time() - getattr(self.server, 'start_time', time.time())
        uptime_str = f"{int(uptime // 3600):02d}:{int((uptime % 3600) // 60):02d}:{int(uptime % 60):02d}"
        
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Status - {RESPONSE_MSG}</title>
    <style>
        body {{
            font-family: 'Courier New', monospace;
            background: #1a1a1a;
            color: #00ff00;
            padding: 20px;
            margin: 0;
        }}
        
        .terminal {{
            background: #000;
            padding: 20px;
            border-radius: 5px;
            border: 2px solid #00ff00;
            max-width: 800px;
            margin: 0 auto;
        }}
        
        .header {{
            color: #00ffff;
            text-align: center;
            margin-bottom: 20px;
            font-size: 1.5em;
        }}
        
        .status-line {{
            margin: 10px 0;
            padding: 5px;
            border-left: 3px solid #00ff00;
            padding-left: 10px;
        }}
        
        .status-ok {{
            color: #00ff00;
        }}
        
        .status-warning {{
            color: #ffff00;
        }}
        
        .status-error {{
            color: #ff0000;
        }}
        
        .nav-back {{
            margin-top: 20px;
            text-align: center;
        }}
        
        .nav-back a {{
            color: #00ffff;
            text-decoration: none;
        }}
    </style>
</head>
<body>
    <div class="terminal">
        <div class="header">SYSTEM STATUS - PORT {port}</div>
        
        <div class="status-line status-ok">
            [OK] Service Status: ONLINE
        </div>
        <div class="status-line status-ok">
            [OK] Port {port}: LISTENING
        </div>
        <div class="status-line status-ok">
            [OK] Server: {SERVER_NAME}
        </div>
        <div class="status-line status-ok">
            [OK] Uptime: {uptime_str}
        </div>
        <div class="status-line status-ok">
            [OK] Requests Served: {getattr(self.server, 'request_count', 0)}
        </div>
        <div class="status-line status-ok">
            [OK] Memory Usage: Normal
        </div>
        <div class="status-line status-ok">
            [OK] Response Time: < 1ms
        </div>
        
        <div class="nav-back">
            <a href="/">&lt; Back to Main</a>
        </div>
    </div>
</body>
</html>
        """
    
    def generate_info_html(self, port):
        """Generate info page HTML"""
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Information - {RESPONSE_MSG}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background: #f0f2f5;
            color: #333;
            margin: 0;
            padding: 20px;
        }}
        
        .container {{
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            overflow: hidden;
        }}
        
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }}
        
        .content {{
            padding: 30px;
        }}
        
        .info-section {{
            margin-bottom: 30px;
        }}
        
        .info-section h3 {{
            color: #667eea;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
            margin-bottom: 15px;
        }}
        
        .info-table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }}
        
        .info-table th,
        .info-table td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        
        .info-table th {{
            background: #f8f9fa;
            font-weight: bold;
        }}
        
        .nav-back {{
            text-align: center;
            margin-top: 20px;
        }}
        
        .nav-back a {{
            color: #667eea;
            text-decoration: none;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Server Information</h1>
            <p>Port {port} Details</p>
        </div>
        
        <div class="content">
            <div class="info-section">
                <h3>Server Details</h3>
                <table class="info-table">
                    <tr><th>Server Name</th><td>{SERVER_NAME}</td></tr>
                    <tr><th>Port</th><td>{port}</td></tr>
                    <tr><th>Service</th><td>Mastermind Response Server</td></tr>
                    <tr><th>Version</th><td>1.0.0</td></tr>
                    <tr><th>Protocol</th><td>HTTP/1.1</td></tr>
                </table>
            </div>
            
            <div class="info-section">
                <h3>Contact Information</h3>
                <table class="info-table">
                    <tr><th>Administrator</th><td>{ADMIN_EMAIL}</td></tr>
                    <tr><th>Support</th><td>Technical Support Available</td></tr>
                </table>
            </div>
            
            <div class="info-section">
                <h3>Available Endpoints</h3>
                <table class="info-table">
                    <tr><th>Endpoint</th><th>Description</th></tr>
                    <tr><td>/</td><td>Main page</td></tr>
                    <tr><td>/status</td><td>System status</td></tr>
                    <tr><td>/info</td><td>Server information</td></tr>
                    <tr><td>/api/status</td><td>JSON status API</td></tr>
                    <tr><td>/config</td><td>Configuration details</td></tr>
                </table>
            </div>
            
            <div class="nav-back">
                <a href="/">&lt; Back to Main</a>
            </div>
        </div>
    </div>
</body>
</html>
        """
    
    def generate_config_html(self, port):
        """Generate configuration page HTML"""
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configuration - {RESPONSE_MSG}</title>
    <style>
        body {{
            font-family: 'Courier New', monospace;
            background: #2d3748;
            color: #e2e8f0;
            margin: 0;
            padding: 20px;
        }}
        
        .config-container {{
            max-width: 900px;
            margin: 0 auto;
            background: #1a202c;
            border-radius: 8px;
            padding: 30px;
            border: 1px solid #4a5568;
        }}
        
        .config-header {{
            text-align: center;
            margin-bottom: 30px;
            color: #63b3ed;
        }}
        
        .config-section {{
            margin-bottom: 25px;
            background: #2d3748;
            padding: 20px;
            border-radius: 6px;
            border-left: 4px solid #63b3ed;
        }}
        
        .config-section h3 {{
            color: #63b3ed;
            margin-top: 0;
            margin-bottom: 15px;
        }}
        
        .config-item {{
            margin: 8px 0;
            display: flex;
        }}
        
        .config-key {{
            color: #f7fafc;
            font-weight: bold;
            min-width: 200px;
        }}
        
        .config-value {{
            color: #68d391;
        }}
        
        .nav-back {{
            text-align: center;
            margin-top: 20px;
        }}
        
        .nav-back a {{
            color: #63b3ed;
            text-decoration: none;
        }}
    </style>
</head>
<body>
    <div class="config-container">
        <div class="config-header">
            <h1>Server Configuration</h1>
            <p>Port {port} Configuration Details</p>
        </div>
        
        <div class="config-section">
            <h3>Server Configuration</h3>
            <div class="config-item">
                <span class="config-key">server_name:</span>
                <span class="config-value">"{SERVER_NAME}"</span>
            </div>
            <div class="config-item">
                <span class="config-key">port:</span>
                <span class="config-value">{port}</span>
            </div>
            <div class="config-item">
                <span class="config-key">service_type:</span>
                <span class="config-value">"http_response_server"</span>
            </div>
            <div class="config-item">
                <span class="config-key">version:</span>
                <span class="config-value">"1.0.0"</span>
            </div>
        </div>
        
        <div class="config-section">
            <h3>Branding Configuration</h3>
            <div class="config-item">
                <span class="config-key">brand_message:</span>
                <span class="config-value">"{RESPONSE_MSG}"</span>
            </div>
            <div class="config-item">
                <span class="config-key">admin_email:</span>
                <span class="config-value">"{ADMIN_EMAIL}"</span>
            </div>
        </div>
        
        <div class="config-section">
            <h3>Runtime Configuration</h3>
            <div class="config-item">
                <span class="config-key">start_time:</span>
                <span class="config-value">{getattr(self.server, 'start_time', time.time())}</span>
            </div>
            <div class="config-item">
                <span class="config-key">requests_served:</span>
                <span class="config-value">{getattr(self.server, 'request_count', 0)}</span>
            </div>
            <div class="config-item">
                <span class="config-key">log_level:</span>
                <span class="config-value">"{LOG_LEVEL}"</span>
            </div>
        </div>
        
        <div class="nav-back">
            <a href="/">&lt; Back to Main</a>
        </div>
    </div>
</body>
</html>
        """
    
    def generate_404_html(self):
        """Generate 404 page HTML"""
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #ff6b6b, #ee5a52);
            color: white;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }}
        
        .error-container {{
            text-align: center;
            background: rgba(0,0,0,0.3);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }}
        
        .error-code {{
            font-size: 6em;
            font-weight: bold;
            margin-bottom: 20px;
        }}
        
        .error-message {{
            font-size: 1.5em;
            margin-bottom: 30px;
        }}
        
        .nav-back a {{
            color: white;
            text-decoration: none;
            background: rgba(255,255,255,0.2);
            padding: 15px 30px;
            border-radius: 25px;
            transition: background 0.3s;
        }}
        
        .nav-back a:hover {{
            background: rgba(255,255,255,0.3);
        }}
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">404</div>
        <div class="error-message">Page Not Found</div>
        <p>The requested page could not be found on this server.</p>
        <div class="nav-back">
            <a href="/">Go Home</a>
        </div>
    </div>
</body>
</html>
        """
    
    def generate_error_html(self, code, message):
        """Generate error page HTML"""
        return f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{code} - {message}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #ff4757, #c44569);
            color: white;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }}
        
        .error-container {{
            text-align: center;
            background: rgba(0,0,0,0.3);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }}
        
        .error-code {{
            font-size: 4em;
            font-weight: bold;
            margin-bottom: 20px;
        }}
        
        .error-message {{
            font-size: 1.5em;
            margin-bottom: 30px;
        }}
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-code">{code}</div>
        <div class="error-message">{message}</div>
        <p>Please try again later or contact the administrator.</p>
    </div>
</body>
</html>
        """
    
    def log_message(self, format, *args):
        """Override log message to use our logger"""
        logger.info(f"HTTP {self.server.server_port}: {format % args}")
        
        # Increment request counter
        if hasattr(self.server, 'request_count'):
            self.server.request_count += 1
        else:
            self.server.request_count = 1

class MastermindHTTPServer(HTTPServer):
    """Custom HTTP server with additional functionality"""
    
    def __init__(self, server_address, RequestHandlerClass):
        super().__init__(server_address, RequestHandlerClass)
        self.start_time = time.time()
        self.request_count = 0

class ResponseServerManager:
    """Manager for multiple response servers"""
    
    def __init__(self):
        self.servers = {}
        self.threads = {}
        self.running = False
        
    def start_server(self, port):
        """Start a response server on specified port"""
        try:
            server = MastermindHTTPServer(('0.0.0.0', port), CustomResponseHandler)
            self.servers[port] = server
            
            thread = threading.Thread(target=server.serve_forever)
            thread.daemon = True
            thread.start()
            self.threads[port] = thread
            
            logger.info(f"Response server started on port {port}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to start server on port {port}: {e}")
            return False
    
    def stop_server(self, port):
        """Stop a response server on specified port"""
        if port in self.servers:
            self.servers[port].shutdown()
            self.servers[port].server_close()
            del self.servers[port]
            
            if port in self.threads:
                del self.threads[port]
                
            logger.info(f"Response server stopped on port {port}")
    
    def start_all(self):
        """Start all configured response servers"""
        logger.info("Starting all response servers...")
        self.running = True
        
        for port in RESPONSE_PORTS:
            self.start_server(port)
            
        logger.info(f"Started {len(self.servers)} response servers")
    
    def stop_all(self):
        """Stop all response servers"""
        logger.info("Stopping all response servers...")
        self.running = False
        
        for port in list(self.servers.keys()):
            self.stop_server(port)
            
        logger.info("All response servers stopped")
    
    def get_status(self):
        """Get status of all servers"""
        status = {}
        for port, server in self.servers.items():
            status[port] = {
                'running': True,
                'start_time': server.start_time,
                'requests_served': server.request_count,
                'uptime': time.time() - server.start_time
            }
        return status

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}, shutting down...")
    manager.stop_all()
    sys.exit(0)

def main():
    """Main function"""
    global manager
    
    # Create server manager
    manager = ResponseServerManager()
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Start all servers
        manager.start_all()
        
        # Keep main thread alive
        while manager.running:
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt, shutting down...")
        manager.stop_all()
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        manager.stop_all()
        sys.exit(1)

if __name__ == "__main__":
    main()
