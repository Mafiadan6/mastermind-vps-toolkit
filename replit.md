# Mastermind VPS Toolkit

## Overview

This is a comprehensive terminal-based VPS management toolkit called "Mastermind." The project provides powerful shell scripts and Python tools for VPS management, proxy services, network optimization, and system administration on Ubuntu/Debian systems.

## System Architecture

### Terminal-Based Architecture
- **Core Management**: Bash-based menu system and service controls
- **Scripting Language**: Shell scripts with Python integration
- **Configuration**: File-based configuration management
- **Service Management**: systemd integration for service control
- **User Interface**: Interactive terminal menus and command-line tools

### VPS Toolkit Components
The project includes several Python-based network tools:
- **Proxy Services**: SOCKS5, HTTP, and WebSocket proxy implementations
- **Response Servers**: Custom HTTP response servers for multiple ports
- **QR Code Generation**: Dynamic QR code generation for connection configurations
- **Network Protocols**: Support for V2Ray, SSH ecosystem, TCP bypass, and BadVPN

## Key Components

### Database Schema
- **Users Table**: Basic user management with username/password authentication
- **Drizzle ORM**: Type-safe database operations with PostgreSQL dialect
- **Schema Validation**: Zod schemas for runtime type validation

### Authentication & Authorization
- **Session-based Authentication**: Using PostgreSQL for session storage
- **User Management**: Basic CRUD operations for user accounts
- **Memory Storage**: Fallback in-memory storage for development

### API Structure
- **Express Server**: RESTful API endpoints under `/api` prefix
- **Error Handling**: Centralized error handling middleware
- **Request Logging**: Comprehensive logging for API requests

### Frontend Components
- **shadcn/ui**: Comprehensive UI component library
- **Form Handling**: React Hook Form with Zod validation
- **Responsive Design**: Mobile-first design with Tailwind CSS
- **Dark Mode**: CSS variables-based theming system

## Data Flow

1. **Client Requests**: React frontend makes HTTP requests to Express backend
2. **API Processing**: Express routes handle business logic and database operations
3. **Database Operations**: Drizzle ORM manages PostgreSQL interactions
4. **Response Handling**: TanStack Query manages client-side caching and state
5. **UI Updates**: React components re-render based on state changes

## External Dependencies

### Database
- **Neon Database**: Serverless PostgreSQL hosting
- **Connection Pooling**: Built-in connection management

### UI Libraries
- **Radix UI**: Accessible, unstyled UI primitives
- **Tailwind CSS**: Utility-first CSS framework
- **Lucide Icons**: Icon library for React

### Development Tools
- **TypeScript**: Static type checking
- **ESLint**: Code linting and formatting
- **Vite**: Fast development server and build tool

### VPS Toolkit Dependencies
- **Python 3**: Runtime for proxy services and network tools
- **System Packages**: Various Linux utilities for network management
- **Service Management**: systemd integration for service management

## Deployment Strategy

### Development
- **Vite Dev Server**: Hot module replacement for frontend development
- **Express Server**: Backend API server with auto-restart
- **Database**: Development database connection via environment variables

### Production
- **Build Process**: Vite builds optimized frontend assets
- **Server Bundle**: esbuild creates server bundle for production
- **Static Serving**: Express serves built frontend assets
- **Environment Variables**: DATABASE_URL required for production

### VPS Deployment
- **Operating System**: Ubuntu 20.04+ or Debian 10+
- **System Requirements**: 1 vCPU, 512MB RAM minimum
- **Network Ports**: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Service Management**: systemd services for various toolkit components

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes

✓ Removed all web UI components (React, Node.js, TypeScript)
✓ Converted to pure terminal-based VPS toolkit
✓ Updated documentation to reflect script-only structure
✓ Maintained comprehensive .gitignore file for security
✓ Updated README.md for terminal toolkit focus
✓ Kept MIT LICENSE file
✓ Updated DEPLOYMENT.md with script deployment instructions
✓ Completely redesigned menu.sh with modern UI/UX (v3.0.0)
✓ Enhanced color scheme with bright colors and modern design
✓ Added numbered menu options with visual icons
✓ Fixed arithmetic errors in progress bar calculations
✓ Improved system monitoring with real-time dashboards
✓ Added quick actions menu for common tasks
✓ Enhanced service status indicators with color coding
✓ Project ready for GitHub upload as VPS script toolkit
✓ Removed web UI components - pure terminal-based toolkit
✓ Fixed Python proxy dependencies and logging paths
✓ Verified all Python protocols working correctly
✓ Removed web UI components - pure terminal VPS toolkit
✓ Python proxy, QR generator, and core protocols functioning
✓ Ready for manual GitHub upload with provided access token
✓ Terminal toolkit fully functional and ready for deployment
✓ Fixed Python proxy and TCP bypass service configuration issues
✓ Resolved log directory creation and permissions problems  
✓ Updated systemd services to run with proper environment variables
✓ Fixed empty directory path error in first_run.sh and helpers.sh
✓ Fixed Python proxy AsyncIO event loop error with threading
✓ Completed V2Ray manager with VLESS/VMESS configuration support
✓ Added comprehensive Domain & SSL management system
✓ Enhanced service status detection and port monitoring
✓ Fixed all file duplication and syntax errors
✓ Completed all missing protocol management functions
✓ Successfully uploaded all updated files to GitHub repository
✓ Fixed Python proxy AsyncIO threading issues for production deployment
✓ Updated QR code generator with verified working dependencies
✓ Enhanced main menu system with modern terminal UI (v3.0.0)
✓ All protocols tested and working: SOCKS5, HTTP proxy, WebSocket, V2Ray
✓ Repository ready for production VPS deployment
✓ Fixed installation script error - backup directory parameter missing
✓ Added error handling and backup directory creation to install.sh
✓ Installation script now runs successfully on production VPS
✓ Updated port configuration to correct structure across all protocols
✓ Fixed Python proxy, V2Ray, SSH, and Dropbear port assignments
✓ Updated fail2ban configuration with correct port monitoring
✓ All protocols now use production-ready port structure
✓ Implemented all missing menu functions in core/menu.sh
✓ Added User Administration menu with SSH user creation and management
✓ Added Network Optimization menu with BBR and kernel tuning options
✓ Added Security Center menu with firewall and fail2ban management
✓ Added System Monitoring menu with real-time stats and log analysis
✓ Added Branding & QR Code menu with connection QR generation
✓ Added System Tools menu with updates, cleanup, and backup options
✓ Added Advanced Settings menu with configuration and debug tools
✓ Updated user_manager.sh to support command line arguments properly
✓ Replaced all "coming soon" placeholders with fully functional menus
✓ Enhanced proxy suite listing with user-friendly descriptions and clear service status
✓ Added Quick Setup Wizard replacing branding menu for better user experience
✓ Redesigned Port Mapping Info with mobile app focus and connection examples
✓ Created step-by-step setup wizards for mobile apps, desktop, and complete server
✓ Improved main menu with better service status indicators and clear explanations
✓ Added real-time open port monitoring with live status indicators for all services
✓ Verified MasterMind branding across all proxy services and response ports (9001 shows branded message)
✓ Fixed SSH user management path resolution for proper functionality
✓ Created comprehensive GitHub documentation and deployment guides
✓ Prepared manual upload guide with access token for final GitHub deployment
✓ Created comprehensive uninstall script that removes ALL traces from VPS (ports, banners, users, services)
✓ Developed reinstall script with automatic configuration backup and restore functionality
✓ Updated install.sh to reference new uninstall/reinstall scripts
✓ Enhanced manual upload guide with complete lifecycle management documentation
✓ Prepared GitHub credentials and comprehensive commit message for complete edition upload
✓ Fixed System Tools menu to include uninstall and reinstall options (Menu option 10)

## Changelog

- July 07, 2025: Enhanced user experience with Quick Setup Wizard and improved proxy listings (v5.1.0)
  - Redesigned proxy suite listing with clear service descriptions and user-friendly explanations
  - Added Quick Setup Wizard to replace branding menu - guides users through mobile apps, desktop, and complete setup
  - Enhanced Port Mapping Info screen with mobile app focus (NPV Tunnel, HTTP Injector configuration)
  - Created step-by-step setup wizards with automatic service starting and connection testing
  - Improved main menu service status indicators showing clear proxy service purposes
  - Added connection examples screen with real server IP and copy-ready configuration details
  - Simplified proxy configuration with highlighted ports and recommended settings for different use cases
- July 07, 2025: Complete menu system overhaul with full functionality implementation (v5.0.0)
  - Fixed menu.sh to properly display new port mapping structure (v2.0)
  - Eliminated ALL "coming soon" placeholders - every menu option now functional
  - Added comprehensive System Monitoring menu with real-time stats and port monitoring
  - Implemented complete System Tools menu with package management and service control
  - Enhanced Advanced Settings menu with configuration editing and debug capabilities
  - Added detailed Port Mapping Information screen showing proxy structure v2.0
  - Completed Security Center with SSH hardening, SSL/TLS management, and intrusion detection
  - Integrated Backup & Restore framework for system maintenance
  - Updated service status display to show correct port mappings for all services
  - Added command line arguments for direct menu access (monitoring, tools, advanced, etc.)
  - Enhanced error handling and integration with existing toolkit scripts
  - Menu system now shows: SOCKS5:1080, WebSocket-SSH:8080, HTTP:8888, Responses:9000-9003
- July 07, 2025: Completely rebuilt proxy structure with WebSocket-to-SSH SOCKS implementation (v3.5.0)
  - Implemented full WebSocket-to-SSH SOCKS proxy as per technical documentation
  - Fixed all port conflicts: WebSocket(8080), HTTP Response Servers(9000-9003)
  - Added adjustable 101 response templates for different SSH server types
  - Created proper SSH tunnel management with dynamic port allocation
  - Enhanced bidirectional data relay between WebSocket and SOCKS proxy
  - Added comprehensive connection cleanup and process management
  - Updated systemd service with proper environment variables
  - Created automated fix script (fix_proxy_structure.sh) for deployment
  - Generated detailed port mapping documentation (PORT_MAPPING_v2.md)
  - All proxy services now properly isolated with no port conflicts
- July 07, 2025: Fixed proxy port configuration and added usage limits system (v3.4.0)
  - Fixed WebSocket proxy to use port 8080 as requested (moved from 8443)
  - Moved HTTP response servers to 9000-9003 range to avoid conflicts
  - Created comprehensive usage limits system with SQLite database
  - Enhanced SSH user creation with proper credential display and connection info
  - Added data limits (GB), time limits (days), and connection limits enforcement
  - Integrated usage tracking for both SSH and V2Ray users
  - Updated all configuration files for consistent port mapping
  - HTTP response messages now properly formatted for HTTP Injector/Custom apps
  - Fixed python-proxy.service environment variables
  - Created PORT_MAPPING.md for comprehensive port documentation
- July 07, 2025: Implemented all missing menu functionality (v3.3.0)
  - Added comprehensive User Administration menu with SSH user creation, permissions, and key management
  - Implemented Network Optimization menu with BBR, kernel tuning, and UDP optimization
  - Created Security Center menu with firewall management, fail2ban setup, and SSH hardening
  - Added System Monitoring menu with real-time stats, logs, and performance analysis
  - Implemented Branding & QR Code menu with connection QR generation and custom banners
  - Added System Tools menu with updates, cleanup, backups, and service control
  - Created Advanced Settings menu with configuration editing and debug tools
  - Updated user_manager.sh to support command line arguments for menu integration
  - Replaced all "coming soon" placeholders with fully functional implementations
  - All menu options now connect to working scripts and provide real functionality
- July 06, 2025: Corrected port structure across all protocols (v3.2.0)
  - SOCKS Python: Port 1080 (standard SOCKS5 port)
  - WebSocket: Port 8080 (as requested)
  - V2Ray WebSocket VLESS non-TLS: Port 80 (HTTP port)
  - SSH TLS: Port 443 (HTTPS port for SSL tunneling)
  - Dropbear: Port 444 and 445 (custom SSH ports)
  - Updated config.cfg, python_proxy.py, and fail2ban_setup.sh
  - All configurations now match requested port structure
- July 06, 2025: Fixed critical installation script error (v3.1.1)
  - Fixed banner_setup.sh missing backup directory parameter causing installation failure
  - Added proactive backup directory creation in install.sh
  - Enhanced error handling for non-critical setup scripts
  - Installation now completes successfully on Ubuntu 22.04 LTS
- July 06, 2025: Complete GitHub repository update with all fixes (v3.1.0)
  - Successfully uploaded install.sh, python_proxy.py, qr_generator.py, menu.sh
  - Fixed AsyncIO threading issues in Python proxy services  
  - Verified QR code generation with proper qrcode library dependencies
  - Updated README.md with complete installation and usage instructions
  - Repository URL: https://github.com/Mafiadan6/mastermind-vps-toolkit
- July 06, 2025: Complete UI/UX redesign of menu system (v3.0.0)
  - Modern colorful interface with numbered options
  - Enhanced system monitoring dashboards
  - Quick actions menu for common tasks
  - Fixed syntax errors and improved reliability
- July 05, 2025: Initial setup and complete project preparation for GitHub upload