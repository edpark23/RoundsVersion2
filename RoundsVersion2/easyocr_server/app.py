#!/usr/bin/env python3
"""
EasyOCR Server for Golf Scorecard Text Recognition
Provides enhanced OCR capabilities with image preprocessing and golf-specific text cleaning.
"""

import os
import sys
import base64
import time
from io import BytesIO
from typing import Dict, List, Any, Optional, Tuple

import cv2
import numpy as np
import easyocr
from flask import Flask, request, jsonify
from PIL import Image, ImageEnhance

app = Flask(__name__)

# Initialize EasyOCR reader with English language
print("Initializing EasyOCR reader...")
reader = easyocr.Reader(['en'], gpu=False)
print("EasyOCR reader initialized successfully")

def preprocess_image(image: np.ndarray) -> np.ndarray:
    """
    Apply comprehensive image preprocessing for better OCR results.
    
    Args:
        image: Input image as numpy array
        
    Returns:
        Preprocessed image
    """
    # Convert to grayscale if needed
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image.copy()
    
    # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    
    # Noise reduction
    denoised = cv2.bilateralFilter(enhanced, 9, 75, 75)
    
    # Sharpening
    kernel = np.array([[-1, -1, -1],
                      [-1,  9, -1],
                      [-1, -1, -1]])
    sharpened = cv2.filter2D(denoised, -1, kernel)
    
    # Ensure good contrast
    normalized = cv2.normalize(sharpened, None, 0, 255, cv2.NORM_MINMAX)
    
    return normalized

def clean_golf_text(text: str) -> str:
    """
    Apply golf-specific text cleaning and character corrections.
    
    Args:
        text: Raw OCR text
        
    Returns:
        Cleaned text with golf-specific corrections
    """
    if not text:
        return ""
    
    # Remove extra whitespace
    cleaned = ' '.join(text.split())
    
    # Common OCR corrections for golf scorecards
    corrections = {
        'O': '0',  # Letter O to number 0
        'o': '0',  # Lowercase o to number 0
        'l': '1',  # Lowercase L to number 1
        'I': '1',  # Uppercase i to number 1
        'S': '5',  # S to 5 (common in small numbers)
        'G': '6',  # G to 6
        'B': '8',  # B to 8
        '|': '1',  # Pipe to 1
    }
    
    # Apply corrections only to isolated characters that could be numbers
    words = cleaned.split()
    corrected_words = []
    
    for word in words:
        # If it's a single character and in our corrections map
        if len(word) == 1 and word in corrections:
            corrected_words.append(corrections[word])
        # If it's a short word that might be a score
        elif len(word) <= 3 and any(c in corrections for c in word):
            corrected_word = word
            for old_char, new_char in corrections.items():
                corrected_word = corrected_word.replace(old_char, new_char)
            corrected_words.append(corrected_word)
        else:
            corrected_words.append(word)
    
    return ' '.join(corrected_words)

def extract_text_with_confidence(results: List[Tuple]) -> List[Dict[str, Any]]:
    """
    Extract text and confidence scores from EasyOCR results.
    
    Args:
        results: EasyOCR detection results
        
    Returns:
        List of text detections with coordinates, text, and confidence
    """
    detections = []
    
    for (bbox, text, confidence) in results:
        # Clean the text
        cleaned_text = clean_golf_text(text)
        
        # Extract bounding box coordinates
        top_left = bbox[0]
        bottom_right = bbox[2]
        
        detection = {
            'text': cleaned_text,
            'confidence': float(confidence),
            'bbox': {
                'x': float(top_left[0]),
                'y': float(top_left[1]),
                'width': float(bottom_right[0] - top_left[0]),
                'height': float(bottom_right[1] - top_left[1])
            }
        }
        detections.append(detection)
    
    # Sort by confidence score (highest first)
    detections.sort(key=lambda x: x['confidence'], reverse=True)
    
    return detections

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'message': 'EasyOCR server is running'
    })

@app.route('/ocr', methods=['POST'])
def perform_ocr():
    """
    Perform OCR on uploaded image.
    
    Expected request format:
    {
        "image": "base64_encoded_image_data"
    }
    
    Returns:
    {
        "success": bool,
        "detections": [
            {
                "text": str,
                "confidence": float,
                "bbox": {
                    "x": float,
                    "y": float, 
                    "width": float,
                    "height": float
                }
            }
        ],
        "processing_time": float,
        "message": str
    }
    """
    start_time = time.time()
    
    try:
        # Validate request
        if not request.json or 'image' not in request.json:
            return jsonify({
                'success': False,
                'error': 'Missing image data in request',
                'processing_time': time.time() - start_time
            }), 400
        
        # Decode base64 image
        try:
            image_data = base64.b64decode(request.json['image'])
            image = Image.open(BytesIO(image_data))
            
            # Convert PIL image to OpenCV format
            cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'Invalid image data: {str(e)}',
                'processing_time': time.time() - start_time
            }), 400
        
        # Preprocess image
        processed_image = preprocess_image(cv_image)
        
        # Perform OCR
        results = reader.readtext(processed_image)
        
        # Extract and clean text with confidence scores
        detections = extract_text_with_confidence(results)
        
        processing_time = time.time() - start_time
        
        return jsonify({
            'success': True,
            'detections': detections,
            'processing_time': processing_time,
            'message': f'Successfully processed {len(detections)} text detections'
        })
        
    except Exception as e:
        processing_time = time.time() - start_time
        print(f"Error processing OCR request: {str(e)}")
        
        return jsonify({
            'success': False,
            'error': f'OCR processing failed: {str(e)}',
            'processing_time': processing_time
        }), 500

if __name__ == '__main__':
    # Get port from environment variable, default to 5001 to avoid AirPlay conflicts
    port = int(os.environ.get('PORT', 5001))
    
    print(f"Starting EasyOCR server on port {port}...")
    print("Server endpoints:")
    print(f"  Health check: http://localhost:{port}/health")
    print(f"  OCR endpoint: http://localhost:{port}/ocr")
    
    app.run(host='0.0.0.0', port=port, debug=False) 