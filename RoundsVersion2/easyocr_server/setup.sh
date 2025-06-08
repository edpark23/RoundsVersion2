#!/bin/bash

# EasyOCR Server Setup Script
# This script sets up the Python environment for the EasyOCR server

echo "🚀 Setting up EasyOCR server environment..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

echo "✅ Setup complete!"
echo ""
echo "To start the server:"
echo "1. cd easyocr_server"
echo "2. source venv/bin/activate"
echo "3. python app.py"
echo ""
echo "The server will be available at http://localhost:5001" 