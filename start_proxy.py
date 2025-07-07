#!/usr/bin/env python3
"""
Simple script to start the MasterMind proxy services
"""
import subprocess
import sys
import os

def main():
    # Change to protocols directory
    os.chdir('protocols')
    
    # Start the proxy services
    try:
        subprocess.run([sys.executable, 'python_proxy.py'], check=True)
    except KeyboardInterrupt:
        print("\nProxy services stopped by user")
    except Exception as e:
        print(f"Error starting proxy services: {e}")

if __name__ == "__main__":
    main()