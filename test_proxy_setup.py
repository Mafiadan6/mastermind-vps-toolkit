#!/usr/bin/env python3
"""
Test script for Mastermind Proxy Structure v2.0
Tests all proxy services and WebSocket-to-SSH functionality
"""

import socket
import subprocess
import time
import requests
import json
import sys

def test_port_listening(port, service_name):
    """Test if a port is listening"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        result = sock.connect_ex(('localhost', port))
        sock.close()
        
        if result == 0:
            print(f"✓ {service_name} (Port {port}): LISTENING")
            return True
        else:
            print(f"✗ {service_name} (Port {port}): NOT LISTENING")
            return False
    except Exception as e:
        print(f"✗ {service_name} (Port {port}): ERROR - {e}")
        return False

def test_socks5_proxy():
    """Test SOCKS5 proxy functionality"""
    print("\n🔍 Testing SOCKS5 Proxy...")
    
    try:
        # Try to connect to SOCKS5 proxy
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect(('localhost', 1080))
        
        # Send SOCKS5 handshake
        sock.send(b'\x05\x01\x00')  # Version 5, 1 method, no auth
        response = sock.recv(2)
        
        if response == b'\x05\x00':  # SOCKS5 + no auth required
            print("✓ SOCKS5 handshake successful")
            sock.close()
            return True
        else:
            print(f"✗ SOCKS5 handshake failed: {response.hex()}")
            sock.close()
            return False
            
    except Exception as e:
        print(f"✗ SOCKS5 test failed: {e}")
        return False

def test_http_response_servers():
    """Test HTTP response servers"""
    print("\n🔍 Testing HTTP Response Servers...")
    
    ports = [9000, 9001, 9002, 9003]
    success = 0
    
    for port in ports:
        try:
            response = requests.get(f'http://localhost:{port}', timeout=5)
            if response.status_code == 200:
                print(f"✓ HTTP Response Server Port {port}: Working")
                success += 1
            else:
                print(f"✗ HTTP Response Server Port {port}: Status {response.status_code}")
        except Exception as e:
            print(f"✗ HTTP Response Server Port {port}: {e}")
    
    return success == len(ports)

def test_websocket_connection():
    """Test WebSocket proxy connection"""
    print("\n🔍 Testing WebSocket-to-SSH Proxy...")
    
    try:
        # Simple WebSocket connection test
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect(('localhost', 8080))
        
        # Send HTTP upgrade request for WebSocket
        request = (
            "GET / HTTP/1.1\r\n"
            "Host: localhost:8080\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
            "Sec-WebSocket-Version: 13\r\n"
            "\r\n"
        )
        
        sock.send(request.encode())
        response = sock.recv(1024).decode()
        
        if "101 Switching Protocols" in response:
            print("✓ WebSocket handshake successful")
            sock.close()
            return True
        else:
            print(f"✗ WebSocket handshake failed: {response[:100]}...")
            sock.close()
            return False
            
    except Exception as e:
        print(f"✗ WebSocket test failed: {e}")
        return False

def check_service_status():
    """Check systemd service status"""
    print("\n🔍 Checking Service Status...")
    
    try:
        result = subprocess.run(
            ['systemctl', 'is-active', 'python-proxy'], 
            capture_output=True, 
            text=True
        )
        
        if result.returncode == 0 and result.stdout.strip() == 'active':
            print("✓ python-proxy service: ACTIVE")
            return True
        else:
            print(f"✗ python-proxy service: {result.stdout.strip()}")
            return False
            
    except Exception as e:
        print(f"✗ Service check failed: {e}")
        return False

def check_ssh_setup():
    """Check SSH configuration for WebSocket-to-SSH proxy"""
    print("\n🔍 Checking SSH Setup...")
    
    try:
        # Test SSH connection to localhost
        result = subprocess.run(
            ['ssh', '-o', 'ConnectTimeout=5', '-o', 'StrictHostKeyChecking=no', 
             'root@localhost', 'echo "SSH test successful"'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            print("✓ SSH connection to localhost: Working")
            return True
        else:
            print(f"✗ SSH connection failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"✗ SSH test failed: {e}")
        return False

def main():
    """Main test function"""
    print("=" * 60)
    print("🧪 Mastermind Proxy Structure Test v2.0")
    print("=" * 60)
    
    # Test port listening
    print("\n🔍 Testing Port Connectivity...")
    
    tests = [
        (1080, "SOCKS5 Proxy"),
        (8080, "WebSocket-to-SSH Proxy"),
        (8888, "HTTP Proxy"),
        (9000, "HTTP Response Server #1"),
        (9001, "HTTP Response Server #2"),
        (9002, "HTTP Response Server #3"),
        (9003, "HTTP Response Server #4")
    ]
    
    port_results = []
    for port, name in tests:
        port_results.append(test_port_listening(port, name))
    
    # Additional functionality tests
    service_active = check_service_status()
    ssh_working = check_ssh_setup()
    socks5_working = test_socks5_proxy()
    http_servers_working = test_http_response_servers()
    websocket_working = test_websocket_connection()
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Test Summary")
    print("=" * 60)
    
    total_tests = len(port_results) + 5  # 5 additional tests
    passed_tests = sum(port_results) + sum([
        service_active, ssh_working, socks5_working, 
        http_servers_working, websocket_working
    ])
    
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {passed_tests}")
    print(f"Failed: {total_tests - passed_tests}")
    print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
    
    if passed_tests == total_tests:
        print("\n🎉 All tests passed! Proxy structure is working correctly.")
        return 0
    else:
        print(f"\n⚠️  {total_tests - passed_tests} test(s) failed. Check the output above for details.")
        return 1

if __name__ == "__main__":
    sys.exit(main())