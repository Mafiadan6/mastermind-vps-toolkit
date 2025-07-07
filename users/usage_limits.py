#!/usr/bin/env python3
"""
Mastermind VPS Toolkit - Usage Limits Manager
Version: 1.0.0

This module manages user usage limits for SSH and V2Ray connections.
Tracks data usage, connection limits, and time-based restrictions.
"""

import os
import sys
import json
import time
import sqlite3
import subprocess
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mastermind/usage-limits.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('usage-limits')

class UsageLimitsManager:
    """Manages user usage limits and tracking"""
    
    def __init__(self, db_path='/var/lib/mastermind/usage.db'):
        self.db_path = db_path
        self.ensure_db_directory()
        self.init_database()
    
    def ensure_db_directory(self):
        """Ensure database directory exists"""
        db_dir = os.path.dirname(self.db_path)
        if not os.path.exists(db_dir):
            os.makedirs(db_dir, mode=0o755)
    
    def init_database(self):
        """Initialize SQLite database with tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Users table with limits
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                user_type TEXT NOT NULL,
                data_limit_gb INTEGER DEFAULT 10,
                days_limit INTEGER DEFAULT 30,
                connection_limit INTEGER DEFAULT 5,
                created_date TEXT DEFAULT CURRENT_TIMESTAMP,
                expiry_date TEXT,
                status TEXT DEFAULT 'active'
            )
        ''')
        
        # Usage tracking table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS usage_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                service_type TEXT NOT NULL,
                bytes_used INTEGER DEFAULT 0,
                connections INTEGER DEFAULT 0,
                session_start TEXT DEFAULT CURRENT_TIMESTAMP,
                session_end TEXT,
                ip_address TEXT,
                FOREIGN KEY (username) REFERENCES users (username)
            )
        ''')
        
        # Current sessions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS active_sessions (
                session_id TEXT PRIMARY KEY,
                username TEXT NOT NULL,
                service_type TEXT NOT NULL,
                ip_address TEXT,
                start_time TEXT DEFAULT CURRENT_TIMESTAMP,
                last_activity TEXT DEFAULT CURRENT_TIMESTAMP,
                bytes_in INTEGER DEFAULT 0,
                bytes_out INTEGER DEFAULT 0,
                FOREIGN KEY (username) REFERENCES users (username)
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("Database initialized successfully")
    
    def add_user(self, username: str, user_type: str, data_limit_gb: int = 10, 
                 days_limit: int = 30, connection_limit: int = 5) -> bool:
        """Add new user with limits"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            expiry_date = (datetime.now() + timedelta(days=days_limit)).isoformat()
            
            cursor.execute('''
                INSERT OR REPLACE INTO users 
                (username, user_type, data_limit_gb, days_limit, connection_limit, expiry_date)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (username, user_type, data_limit_gb, days_limit, connection_limit, expiry_date))
            
            conn.commit()
            conn.close()
            logger.info(f"User {username} added with limits: {data_limit_gb}GB, {days_limit} days, {connection_limit} connections")
            return True
        except Exception as e:
            logger.error(f"Error adding user {username}: {e}")
            return False
    
    def get_user_limits(self, username: str) -> Optional[Dict]:
        """Get user limits and current usage"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get user info
            cursor.execute('SELECT * FROM users WHERE username = ?', (username,))
            user = cursor.fetchone()
            
            if not user:
                conn.close()
                return None
            
            # Get usage statistics
            cursor.execute('''
                SELECT 
                    SUM(bytes_used) as total_bytes,
                    COUNT(*) as total_sessions
                FROM usage_logs 
                WHERE username = ? AND session_start >= datetime('now', '-30 days')
            ''', (username,))
            
            usage = cursor.fetchone()
            
            # Get active sessions count
            cursor.execute('''
                SELECT COUNT(*) FROM active_sessions WHERE username = ?
            ''', (username,))
            active_sessions = cursor.fetchone()[0]
            
            conn.close()
            
            return {
                'username': user[0],
                'user_type': user[1],
                'data_limit_gb': user[2],
                'days_limit': user[3],
                'connection_limit': user[4],
                'created_date': user[5],
                'expiry_date': user[6],
                'status': user[7],
                'total_bytes_used': usage[0] or 0,
                'total_sessions': usage[1] or 0,
                'active_sessions': active_sessions,
                'data_used_gb': round((usage[0] or 0) / (1024**3), 2)
            }
        except Exception as e:
            logger.error(f"Error getting user limits for {username}: {e}")
            return None
    
    def check_user_limits(self, username: str) -> Tuple[bool, str]:
        """Check if user has exceeded limits"""
        user_info = self.get_user_limits(username)
        if not user_info:
            return False, "User not found"
        
        # Check if account is expired
        if user_info['expiry_date']:
            expiry = datetime.fromisoformat(user_info['expiry_date'])
            if datetime.now() > expiry:
                self.disable_user(username)
                return False, "Account expired"
        
        # Check status
        if user_info['status'] != 'active':
            return False, f"Account status: {user_info['status']}"
        
        # Check data limit
        if user_info['data_used_gb'] >= user_info['data_limit_gb']:
            self.disable_user(username)
            return False, f"Data limit exceeded: {user_info['data_used_gb']:.2f}GB/{user_info['data_limit_gb']}GB"
        
        # Check connection limit
        if user_info['active_sessions'] >= user_info['connection_limit']:
            return False, f"Connection limit reached: {user_info['active_sessions']}/{user_info['connection_limit']}"
        
        return True, "OK"
    
    def start_session(self, username: str, service_type: str, ip_address: str) -> Optional[str]:
        """Start new user session"""
        # Check limits first
        allowed, reason = self.check_user_limits(username)
        if not allowed:
            logger.warning(f"Session denied for {username}: {reason}")
            return None
        
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            session_id = f"{username}_{service_type}_{int(time.time())}"
            
            cursor.execute('''
                INSERT INTO active_sessions 
                (session_id, username, service_type, ip_address)
                VALUES (?, ?, ?, ?)
            ''', (session_id, username, service_type, ip_address))
            
            conn.commit()
            conn.close()
            logger.info(f"Session started for {username}: {session_id}")
            return session_id
        except Exception as e:
            logger.error(f"Error starting session for {username}: {e}")
            return None
    
    def end_session(self, session_id: str) -> bool:
        """End user session and log usage"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get session info
            cursor.execute('SELECT * FROM active_sessions WHERE session_id = ?', (session_id,))
            session = cursor.fetchone()
            
            if not session:
                conn.close()
                return False
            
            # Log usage
            cursor.execute('''
                INSERT INTO usage_logs 
                (username, service_type, bytes_used, connections, session_start, session_end, ip_address)
                VALUES (?, ?, ?, 1, ?, CURRENT_TIMESTAMP, ?)
            ''', (session[1], session[2], session[6] + session[7], session[4], session[8]))
            
            # Remove from active sessions
            cursor.execute('DELETE FROM active_sessions WHERE session_id = ?', (session_id,))
            
            conn.commit()
            conn.close()
            logger.info(f"Session ended: {session_id}")
            return True
        except Exception as e:
            logger.error(f"Error ending session {session_id}: {e}")
            return False
    
    def update_session_usage(self, session_id: str, bytes_in: int, bytes_out: int) -> bool:
        """Update session data usage"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE active_sessions 
                SET bytes_in = bytes_in + ?, bytes_out = bytes_out + ?, last_activity = CURRENT_TIMESTAMP
                WHERE session_id = ?
            ''', (bytes_in, bytes_out, session_id))
            
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Error updating session usage {session_id}: {e}")
            return False
    
    def disable_user(self, username: str) -> bool:
        """Disable user account"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('UPDATE users SET status = ? WHERE username = ?', ('disabled', username))
            
            # End all active sessions
            cursor.execute('DELETE FROM active_sessions WHERE username = ?', (username,))
            
            conn.commit()
            conn.close()
            
            # Kill user processes
            self.kill_user_processes(username)
            logger.info(f"User {username} disabled")
            return True
        except Exception as e:
            logger.error(f"Error disabling user {username}: {e}")
            return False
    
    def kill_user_processes(self, username: str):
        """Kill all processes for disabled user"""
        try:
            # Kill SSH sessions
            subprocess.run(['pkill', '-u', username], check=False)
            
            # Kill V2Ray connections (if using process tracking)
            subprocess.run(['pkill', '-f', f'v2ray.*{username}'], check=False)
            
            logger.info(f"Killed processes for user {username}")
        except Exception as e:
            logger.error(f"Error killing processes for {username}: {e}")
    
    def get_usage_report(self, username: str = None) -> Dict:
        """Get usage report for user or all users"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            if username:
                cursor.execute('''
                    SELECT u.username, u.user_type, u.data_limit_gb, u.expiry_date, u.status,
                           COALESCE(SUM(ul.bytes_used), 0) as total_bytes,
                           COUNT(ul.id) as total_sessions,
                           (SELECT COUNT(*) FROM active_sessions WHERE username = u.username) as active_sessions
                    FROM users u
                    LEFT JOIN usage_logs ul ON u.username = ul.username
                    WHERE u.username = ?
                    GROUP BY u.username
                ''', (username,))
            else:
                cursor.execute('''
                    SELECT u.username, u.user_type, u.data_limit_gb, u.expiry_date, u.status,
                           COALESCE(SUM(ul.bytes_used), 0) as total_bytes,
                           COUNT(ul.id) as total_sessions,
                           (SELECT COUNT(*) FROM active_sessions WHERE username = u.username) as active_sessions
                    FROM users u
                    LEFT JOIN usage_logs ul ON u.username = ul.username
                    GROUP BY u.username
                ''')
            
            results = cursor.fetchall()
            conn.close()
            
            report = {}
            for row in results:
                report[row[0]] = {
                    'username': row[0],
                    'user_type': row[1],
                    'data_limit_gb': row[2],
                    'expiry_date': row[3],
                    'status': row[4],
                    'total_bytes': row[5],
                    'total_sessions': row[6],
                    'active_sessions': row[7],
                    'data_used_gb': round(row[5] / (1024**3), 2)
                }
            
            return report
        except Exception as e:
            logger.error(f"Error getting usage report: {e}")
            return {}
    
    def cleanup_old_sessions(self):
        """Clean up old inactive sessions"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Remove sessions inactive for more than 1 hour
            cursor.execute('''
                DELETE FROM active_sessions 
                WHERE last_activity < datetime('now', '-1 hour')
            ''')
            
            conn.commit()
            conn.close()
            logger.info("Old sessions cleaned up")
        except Exception as e:
            logger.error(f"Error cleaning up sessions: {e}")

def main():
    """Main function for CLI usage"""
    if len(sys.argv) < 2:
        print("Usage: python3 usage_limits.py <command> [args]")
        print("Commands:")
        print("  add_user <username> <type> [data_gb] [days] [connections]")
        print("  check_limits <username>")
        print("  get_report [username]")
        print("  disable_user <username>")
        print("  cleanup")
        return
    
    manager = UsageLimitsManager()
    command = sys.argv[1]
    
    if command == 'add_user':
        if len(sys.argv) < 4:
            print("Usage: add_user <username> <type> [data_gb] [days] [connections]")
            return
        
        username = sys.argv[2]
        user_type = sys.argv[3]
        data_gb = int(sys.argv[4]) if len(sys.argv) > 4 else 10
        days = int(sys.argv[5]) if len(sys.argv) > 5 else 30
        connections = int(sys.argv[6]) if len(sys.argv) > 6 else 5
        
        success = manager.add_user(username, user_type, data_gb, days, connections)
        print(f"User added: {success}")
    
    elif command == 'check_limits':
        if len(sys.argv) < 3:
            print("Usage: check_limits <username>")
            return
        
        username = sys.argv[2]
        allowed, reason = manager.check_user_limits(username)
        print(f"Allowed: {allowed}, Reason: {reason}")
    
    elif command == 'get_report':
        username = sys.argv[2] if len(sys.argv) > 2 else None
        report = manager.get_usage_report(username)
        print(json.dumps(report, indent=2))
    
    elif command == 'disable_user':
        if len(sys.argv) < 3:
            print("Usage: disable_user <username>")
            return
        
        username = sys.argv[2]
        success = manager.disable_user(username)
        print(f"User disabled: {success}")
    
    elif command == 'cleanup':
        manager.cleanup_old_sessions()
        print("Cleanup completed")
    
    else:
        print(f"Unknown command: {command}")

if __name__ == '__main__':
    main()