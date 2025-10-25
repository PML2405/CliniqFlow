#!/bin/bash

# CliniqFlow Firebase Configuration Setup Script
# This script automates the download of Firebase configuration files
# for Android and iOS development.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
FIREBASE_PROJECT="cliniqflow-cd4a7"
ANDROID_CONFIG="$PROJECT_ROOT/android/app/google-services.json"
IOS_CONFIG="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        return 1
    fi
    return 0
}

# Install Firebase CLI
install_firebase_cli() {
    print_info "Installing Firebase CLI..."
    
    if command -v npm &> /dev/null; then
        npm install -g firebase-tools
        print_success "Firebase CLI installed successfully"
    else
        print_error "npm is not installed. Please install Node.js and npm first."
        print_info "Visit: https://nodejs.org/"
        exit 1
    fi
}

# Check if user is logged in to Firebase
check_firebase_login() {
    if ! firebase auth:list &> /dev/null; then
        return 1
    fi
    return 0
}

# Login to Firebase
firebase_login() {
    print_info "You need to log in to Firebase to download configuration files."
    print_info "Opening Firebase login in your browser..."
    firebase login
}

# Download Android configuration
download_android_config() {
    print_info "Downloading Android configuration..."
    
    if firebase apps:sdkconfig android > "$ANDROID_CONFIG" 2>/dev/null; then
        print_success "Android configuration downloaded to: $ANDROID_CONFIG"
        return 0
    else
        print_error "Failed to download Android configuration"
        return 1
    fi
}

# Download iOS configuration
download_ios_config() {
    print_info "Downloading iOS configuration..."
    
    if firebase apps:sdkconfig ios > "$IOS_CONFIG" 2>/dev/null; then
        print_success "iOS configuration downloaded to: $IOS_CONFIG"
        return 0
    else
        print_error "Failed to download iOS configuration"
        return 1
    fi
}

# Verify downloaded files
verify_configs() {
    print_info "Verifying configuration files..."
    
    local android_ok=true
    local ios_ok=true
    
    if [ -f "$ANDROID_CONFIG" ] && [ -s "$ANDROID_CONFIG" ]; then
        print_success "Android configuration file verified"
    else
        print_error "Android configuration file not found or empty"
        android_ok=false
    fi
    
    if [ -f "$IOS_CONFIG" ] && [ -s "$IOS_CONFIG" ]; then
        print_success "iOS configuration file verified"
    else
        print_error "iOS configuration file not found or empty"
        ios_ok=false
    fi
    
    if [ "$android_ok" = true ] && [ "$ios_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

# Show user consent
show_consent() {
    print_header "Firebase Configuration Setup"
    echo ""
    echo "This script will:"
    echo "  1. Check for Firebase CLI installation"
    echo "  2. Install Firebase CLI if necessary (requires npm)"
    echo "  3. Authenticate with Firebase (opens browser)"
    echo "  4. Download Android configuration (google-services.json)"
    echo "  5. Download iOS configuration (GoogleService-Info.plist)"
    echo ""
    echo "Configuration files will be saved to:"
    echo "  • $ANDROID_CONFIG"
    echo "  • $IOS_CONFIG"
    echo ""
    print_warning "These files contain API keys and should NOT be committed to Git."
    echo ""
}

# Ask for user confirmation
ask_confirmation() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${BLUE}$prompt${NC}) (yes/no): " response
        case "$response" in
            [yY][eE][sS]|[yY])
                return 0
                ;;
            [nN][oO]|[nN])
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# Main script
main() {
    print_header "CliniqFlow Firebase Configuration Setup"
    echo ""
    
    # Show consent
    show_consent
    
    # Ask for user confirmation
    if ! ask_confirmation "Do you want to proceed?"; then
        print_info "Setup cancelled."
        exit 0
    fi
    
    echo ""
    
    # Check and install Firebase CLI
    if ! check_firebase_cli; then
        print_warning "Firebase CLI is not installed"
        
        if ask_confirmation "Would you like to install Firebase CLI?"; then
            install_firebase_cli
        else
            print_error "Firebase CLI is required. Exiting."
            exit 1
        fi
    else
        print_success "Firebase CLI is installed"
    fi
    
    echo ""
    
    # Check Firebase login
    if ! check_firebase_login; then
        print_warning "You are not logged in to Firebase"
        
        if ask_confirmation "Would you like to log in?"; then
            firebase_login
        else
            print_error "Firebase authentication is required. Exiting."
            exit 1
        fi
    else
        print_success "You are logged in to Firebase"
    fi
    
    echo ""
    
    # Download configurations
    print_header "Downloading Configuration Files"
    echo ""
    
    local android_success=false
    local ios_success=false
    
    if download_android_config; then
        android_success=true
    fi
    
    echo ""
    
    if download_ios_config; then
        ios_success=true
    fi
    
    echo ""
    
    # Verify configurations
    if verify_configs; then
        echo ""
        print_header "Setup Complete!"
        echo ""
        print_success "Firebase configuration files have been successfully downloaded."
        echo ""
        print_info "Next steps:"
        echo "  1. Run: flutter pub get"
        echo "  2. Run: flutter run"
        echo ""
        print_warning "Remember: Do NOT commit these files to Git!"
        echo ""
    else
        echo ""
        print_error "Some configuration files failed verification."
        echo ""
        print_info "Troubleshooting:"
        echo "  • Ensure you have the correct Firebase project access"
        echo "  • Try running: firebase login --reauth"
        echo "  • Check: firebase projects:list"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"
