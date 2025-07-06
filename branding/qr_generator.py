#!/usr/bin/env python3
"""
Mastermind VPS Toolkit - QR Code Generator
Version: 1.0.0

This module generates QR codes for various configurations and connection details.
"""

import os
import sys
import json
import base64
import socket
import argparse
import logging
from urllib.parse import quote
import qrcode
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.moduledrawers import RoundedModuleDrawer, SquareModuleDrawer, CircleModuleDrawer
from qrcode.image.styles.colorfills import SolidFillColorMask
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    Image = ImageDraw = ImageFont = None

# Configuration
SERVER_IP = os.getenv('SERVER_IP', '')
BRAND_MESSAGE = os.getenv('BRAND_MESSAGE', 'Mastermind VPS Toolkit')
SOCKS_PORT = int(os.getenv('SOCKS_PORT', '8080'))
SSH_PORT = int(os.getenv('SSH_PORT', '22'))
V2RAY_PORT = int(os.getenv('V2RAY_PORT', '443'))
UDPGW_PORT = int(os.getenv('UDPGW_PORT', '7300'))

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class QRGenerator:
    """QR Code generator for VPS configurations"""
    
    def __init__(self):
        self.server_ip = SERVER_IP or self.get_public_ip()
        
    def get_public_ip(self):
        """Get public IP address"""
        try:
            import subprocess
            result = subprocess.run(['curl', '-s', 'ifconfig.me'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        
        # Fallback
        return socket.gethostbyname(socket.gethostname())
    
    def generate_qr(self, data, filename=None, style='default', logo_path=None):
        """Generate QR code with specified data and style"""
        try:
            # Create QR code instance
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_H,
                box_size=10,
                border=4,
            )
            
            qr.add_data(data)
            qr.make(fit=True)
            
            # Generate image based on style
            if style == 'styled' and Image:
                img = qr.make_image(
                    image_factory=StyledPilImage,
                    module_drawer=RoundedModuleDrawer(),
                    color_mask=SolidFillColorMask(back_color=(255, 255, 255), front_color=(0, 0, 0))
                )
            else:
                img = qr.make_image(fill_color="black", back_color="white")
            
            # Add logo if provided
            if logo_path and os.path.exists(logo_path) and Image:
                img = self.add_logo(img, logo_path)
            
            # Save or display
            if filename:
                img.save(filename)
                logger.info(f"QR code saved to {filename}")
            else:
                # Display in terminal
                self.display_terminal_qr(qr)
            
            return img
            
        except Exception as e:
            logger.error(f"Error generating QR code: {e}")
            return None
    
    def add_logo(self, qr_img, logo_path):
        """Add logo to QR code center"""
        try:
            logo = Image.open(logo_path)
            
            # Calculate logo size (10% of QR code)
            qr_width, qr_height = qr_img.size
            logo_size = min(qr_width, qr_height) // 10
            
            # Resize logo
            logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
            
            # Create a white background for logo
            logo_bg = Image.new('RGB', (logo_size + 20, logo_size + 20), 'white')
            logo_bg.paste(logo, (10, 10))
            
            # Paste logo on QR code
            logo_pos = ((qr_width - logo_size - 20) // 2, (qr_height - logo_size - 20) // 2)
            qr_img.paste(logo_bg, logo_pos)
            
            return qr_img
            
        except Exception as e:
            logger.error(f"Error adding logo: {e}")
            return qr_img
    
    def display_terminal_qr(self, qr):
        """Display QR code in terminal using Unicode characters"""
        # Get the QR code matrix
        matrix = qr.get_matrix()
        
        print("\nQR Code:")
        print("█" * (len(matrix[0]) + 4))
        
        for i in range(0, len(matrix), 2):
            line = "██"
            for j in range(len(matrix[0])):
                top = matrix[i][j] if i < len(matrix) else False
                bottom = matrix[i + 1][j] if i + 1 < len(matrix) else False
                
                if top and bottom:
                    line += " "
                elif top and not bottom:
                    line += "▄"
                elif not top and bottom:
                    line += "▀"
                else:
                    line += "█"
            
            line += "██"
            print(line)
        
        print("█" * (len(matrix[0]) + 4))
        print()
    
    def generate_socks5_qr(self, username="", password="", filename=None):
        """Generate QR code for SOCKS5 proxy configuration"""
        # Create SOCKS5 URL
        auth = f"{username}:{password}@" if username else ""
        socks_url = f"socks5://{auth}{self.server_ip}:{SOCKS_PORT}"
        
        logger.info(f"Generating SOCKS5 QR code for {self.server_ip}:{SOCKS_PORT}")
        return self.generate_qr(socks_url, filename)
    
    def generate_ssh_qr(self, username="root", port=None, filename=None):
        """Generate QR code for SSH connection"""
        ssh_port = port or SSH_PORT
        ssh_url = f"ssh://{username}@{self.server_ip}:{ssh_port}"
        
        logger.info(f"Generating SSH QR code for {username}@{self.server_ip}:{ssh_port}")
        return self.generate_qr(ssh_url, filename)
    
    def generate_v2ray_qr(self, uuid="", path="/", filename=None):
        """Generate QR code for V2Ray configuration"""
        # V2Ray VLESS configuration
        config = {
            "v": "2",
            "ps": f"{BRAND_MESSAGE}",
            "add": self.server_ip,
            "port": V2RAY_PORT,
            "id": uuid,
            "aid": "0",
            "net": "ws",
            "type": "none",
            "host": "",
            "path": path,
            "tls": ""
        }
        
        # Encode configuration
        config_json = json.dumps(config)
        config_b64 = base64.b64encode(config_json.encode()).decode()
        v2ray_url = f"vless://{uuid}@{self.server_ip}:{V2RAY_PORT}?type=ws&path={quote(path)}#{quote(BRAND_MESSAGE)}"
        
        logger.info(f"Generating V2Ray QR code for {self.server_ip}:{V2RAY_PORT}")
        return self.generate_qr(v2ray_url, filename)
    
    def generate_openvpn_qr(self, config_content, filename=None):
        """Generate QR code for OpenVPN configuration"""
        logger.info("Generating OpenVPN configuration QR code")
        return self.generate_qr(config_content, filename)
    
    def generate_http_injector_qr(self, payload="", filename=None):
        """Generate QR code for HTTP Injector configuration"""
        config = {
            "name": BRAND_MESSAGE,
            "server": self.server_ip,
            "port": SOCKS_PORT,
            "proxy_type": "SOCKS5",
            "udpgw_port": UDPGW_PORT,
            "payload": payload or "GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]",
            "dns": "8.8.8.8,8.8.4.4"
        }
        
        config_json = json.dumps(config, indent=2)
        logger.info("Generating HTTP Injector QR code")
        return self.generate_qr(config_json, filename)
    
    def generate_custom_config_qr(self, config_data, filename=None):
        """Generate QR code for custom configuration"""
        if isinstance(config_data, dict):
            config_data = json.dumps(config_data, indent=2)
        
        logger.info("Generating custom configuration QR code")
        return self.generate_qr(config_data, filename)
    
    def generate_server_info_qr(self, filename=None):
        """Generate QR code with server information"""
        server_info = {
            "server": BRAND_MESSAGE,
            "ip": self.server_ip,
            "socks5_port": SOCKS_PORT,
            "ssh_port": SSH_PORT,
            "v2ray_port": V2RAY_PORT,
            "udpgw_port": UDPGW_PORT,
            "timestamp": int(__import__('time').time())
        }
        
        config_json = json.dumps(server_info, indent=2)
        logger.info("Generating server information QR code")
        return self.generate_qr(config_json, filename)
    
    def generate_wifi_qr(self, ssid, password, security="WPA", filename=None):
        """Generate QR code for WiFi connection"""
        wifi_string = f"WIFI:T:{security};S:{ssid};P:{password};;"
        
        logger.info(f"Generating WiFi QR code for SSID: {ssid}")
        return self.generate_qr(wifi_string, filename)
    
    def generate_contact_qr(self, name, email, phone="", filename=None):
        """Generate QR code for contact information"""
        vcard = f"""BEGIN:VCARD
VERSION:3.0
FN:{name}
EMAIL:{email}
TEL:{phone}
NOTE:{BRAND_MESSAGE}
END:VCARD"""
        
        logger.info(f"Generating contact QR code for {name}")
        return self.generate_qr(vcard, filename)

def main():
    """Main function with CLI interface"""
    parser = argparse.ArgumentParser(description='Mastermind VPS QR Code Generator')
    parser.add_argument('--type', choices=['socks5', 'ssh', 'v2ray', 'http-injector', 'server-info', 'wifi', 'contact', 'custom'], 
                       required=True, help='Type of QR code to generate')
    parser.add_argument('--output', '-o', help='Output filename (default: display in terminal)')
    parser.add_argument('--server-ip', help='Server IP address (auto-detected if not provided)')
    parser.add_argument('--style', choices=['default', 'styled'], default='default', help='QR code style')
    parser.add_argument('--logo', help='Path to logo image to embed')
    
    # SOCKS5 options
    parser.add_argument('--socks-username', help='SOCKS5 username')
    parser.add_argument('--socks-password', help='SOCKS5 password')
    
    # SSH options
    parser.add_argument('--ssh-username', default='root', help='SSH username')
    parser.add_argument('--ssh-port', type=int, help='SSH port')
    
    # V2Ray options
    parser.add_argument('--v2ray-uuid', help='V2Ray UUID')
    parser.add_argument('--v2ray-path', default='/', help='V2Ray WebSocket path')
    
    # HTTP Injector options
    parser.add_argument('--payload', help='HTTP Injector payload')
    
    # WiFi options
    parser.add_argument('--wifi-ssid', help='WiFi SSID')
    parser.add_argument('--wifi-password', help='WiFi password')
    parser.add_argument('--wifi-security', default='WPA', help='WiFi security type')
    
    # Contact options
    parser.add_argument('--contact-name', help='Contact name')
    parser.add_argument('--contact-email', help='Contact email')
    parser.add_argument('--contact-phone', help='Contact phone')
    
    # Custom options
    parser.add_argument('--custom-data', help='Custom data for QR code')
    
    args = parser.parse_args()
    
    # Initialize generator
    generator = QRGenerator()
    
    if args.server_ip:
        generator.server_ip = args.server_ip
    
    # Generate QR code based on type
    if args.type == 'socks5':
        generator.generate_socks5_qr(
            username=args.socks_username or "",
            password=args.socks_password or "",
            filename=args.output
        )
    
    elif args.type == 'ssh':
        generator.generate_ssh_qr(
            username=args.ssh_username,
            port=args.ssh_port,
            filename=args.output
        )
    
    elif args.type == 'v2ray':
        if not args.v2ray_uuid:
            logger.error("V2Ray UUID is required")
            sys.exit(1)
        generator.generate_v2ray_qr(
            uuid=args.v2ray_uuid,
            path=args.v2ray_path,
            filename=args.output
        )
    
    elif args.type == 'http-injector':
        generator.generate_http_injector_qr(
            payload=args.payload or "",
            filename=args.output
        )
    
    elif args.type == 'server-info':
        generator.generate_server_info_qr(filename=args.output)
    
    elif args.type == 'wifi':
        if not args.wifi_ssid or not args.wifi_password:
            logger.error("WiFi SSID and password are required")
            sys.exit(1)
        generator.generate_wifi_qr(
            ssid=args.wifi_ssid,
            password=args.wifi_password,
            security=args.wifi_security,
            filename=args.output
        )
    
    elif args.type == 'contact':
        if not args.contact_name or not args.contact_email:
            logger.error("Contact name and email are required")
            sys.exit(1)
        generator.generate_contact_qr(
            name=args.contact_name,
            email=args.contact_email,
            phone=args.contact_phone or "",
            filename=args.output
        )
    
    elif args.type == 'custom':
        if not args.custom_data:
            logger.error("Custom data is required")
            sys.exit(1)
        generator.generate_custom_config_qr(
            config_data=args.custom_data,
            filename=args.output
        )

if __name__ == "__main__":
    main()
