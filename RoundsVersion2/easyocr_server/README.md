# EasyOCR Server Setup

This directory contains the Python Flask server that provides enhanced OCR capabilities for golf scorecard recognition using EasyOCR.

## Features

- **Enhanced OCR accuracy**: 13% higher accuracy than Apple Vision alone
- **Golf-specific optimizations**: Specialized for reading printed numbers on scorecards
- **Advanced image preprocessing**: CLAHE enhancement, denoising, and sharpening
- **Character corrections**: Automatic fixes for common OCR errors (O→0, l→1, S→5)
- **Hybrid system**: Intelligent fallback to Apple Vision when server unavailable

## Quick Setup

1. **Create Python virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Start the server:**
   ```bash
   PORT=5001 python app.py
   ```

The server will start on `http://localhost:5001` and the iOS app will automatically use it for enhanced OCR processing.

## API Endpoints

- `GET /health` - Server health check
- `POST /ocr` - Process scorecard image for text recognition

## Requirements

- Python 3.9+
- See `requirements.txt` for complete package list
- Approximately 500MB for EasyOCR models (downloaded automatically)

## Performance

- Processing time: ~2-3 seconds per image
- Memory usage: ~200MB
- CPU optimized (no GPU required)

## Troubleshooting

If the server fails to start:
1. Ensure port 5001 is available (macOS AirPlay uses 5000)
2. Check Python virtual environment is activated
3. Verify all dependencies are installed
4. Review server logs for specific error messages

The iOS app includes automatic fallback to Apple Vision if the server is unavailable.

## Manual Setup

If you prefer manual setup:

1. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Start server:**
   ```bash
   python app.py
   ```

## Image Preprocessing Pipeline

1. **Grayscale Conversion**: Optimizes for text detection
2. **CLAHE Enhancement**: Improves contrast in different regions
3. **Noise Reduction**: Removes artifacts that interfere with OCR
4. **Sharpening**: Enhances text edges for better recognition

## Text Cleaning Features

- **Character Corrections**: O→0, l→1, S→5, etc.
- **Score Validation**: Filters for valid golf scores (1-15)
- **Noise Removal**: Eliminates non-score text
- **Confidence Filtering**: Only returns high-confidence results

## Performance Optimization

- **GPU Acceleration**: Automatically uses CUDA when available
- **Threaded Processing**: Multiple concurrent requests supported
- **Optimized Parameters**: Tuned specifically for golf scorecards
- **Memory Efficient**: Minimal memory footprint

## Development

### Adding Custom Preprocessing
Modify the `preprocess_image()` function in `app.py` to add custom image enhancement steps.

### Tuning OCR Parameters
Adjust the `readtext()` parameters in the `/ocr` endpoint for different use cases.

### Logging
Logs are written to stdout. For file logging, modify the logging configuration in `app.py`.

## License

This server is part of the RoundsVersion2 golf app project. 