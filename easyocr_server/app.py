#!/usr/bin/env python3
"""
EasyOCR Server for Golf Scorecard Text Recognition
"""

import os
import base64
import time
from io import BytesIO
import cv2
import numpy as np
import easyocr
from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image

app = Flask(__name__)
CORS(app)

print("Initializing EasyOCR reader...")
reader = easyocr.Reader(['en'], gpu=False)
print("EasyOCR reader initialized successfully")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'message': 'EasyOCR server is running',
        'timestamp': time.time()
    })

@app.route('/ocr', methods=['POST'])
def perform_ocr():
    start_time = time.time()
    
    try:
        if not request.json or 'image' not in request.json:
            return jsonify({
                'success': False,
                'error': 'Missing image data in request',
                'processing_time': time.time() - start_time
            }), 400
        
        # Decode base64 image
        image_data = base64.b64decode(request.json['image'])
        image = Image.open(BytesIO(image_data))
        cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        # Perform OCR
        results = reader.readtext(cv_image)
        
        detections = []
        for (bbox, text, confidence) in results:
            top_left = bbox[0]
            bottom_right = bbox[2]
            
            detection = {
                'text': text,
                'confidence': float(confidence),
                'bbox': {
                    'x': float(top_left[0]),
                    'y': float(top_left[1]),
                    'width': float(bottom_right[0] - top_left[0]),
                    'height': float(bottom_right[1] - top_left[1])
                }
            }
            detections.append(detection)
        
        processing_time = time.time() - start_time
        
        return jsonify({
            'success': True,
            'detections': detections,
            'processing_time': processing_time,
            'message': f'Found {len(detections)} text elements'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'OCR processing failed: {str(e)}',
            'processing_time': time.time() - start_time
        }), 500

@app.route('/extract_scores', methods=['POST'])
def extract_scores():
    """Extract golf scores from image"""
    start_time = time.time()
    
    try:
        # Get OCR results first
        ocr_response = perform_ocr()
        if hasattr(ocr_response, 'json'):
            ocr_data = ocr_response.json
        else:
            # Handle Flask response object
            ocr_data = ocr_response[0].get_json() if isinstance(ocr_response, tuple) else ocr_response.get_json()
        
        if not ocr_data.get('success'):
            return ocr_data
        
        detections = ocr_data['detections']
        expected_holes = request.json.get('expected_holes', 18)
        
        # Extract potential scores (numbers 1-12 typically for golf)
        potential_scores = []
        for detection in detections:
            text = detection['text'].strip()
            confidence = detection['confidence']
            
            # Look for numbers that could be golf scores
            if text.isdigit() and 1 <= int(text) <= 12 and confidence > 0.5:
                potential_scores.append({
                    'score': int(text),
                    'confidence': confidence,
                    'bbox': detection['bbox']
                })
        
        # Sort by position (left to right, top to bottom)
        potential_scores.sort(key=lambda x: (x['bbox']['y'], x['bbox']['x']))
        
        # Take the most likely scores up to expected holes
        scores = [s['score'] for s in potential_scores[:expected_holes]]
        avg_confidence = np.mean([s['confidence'] for s in potential_scores[:expected_holes]]) if scores else 0.0
        
        processing_time = time.time() - start_time
        
        return jsonify({
            'success': True,
            'scores': scores,
            'total': sum(scores),
            'confidence': float(avg_confidence),
            'holes_found': len(scores),
            'expected_holes': expected_holes,
            'processing_time': processing_time
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Score extraction failed: {str(e)}',
            'processing_time': time.time() - start_time
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    print(f"Starting EasyOCR server on port {port}")
    print(f"Health check: http://localhost:{port}/health")
    print(f"OCR endpoint: http://localhost:{port}/ocr")
    print(f"Score extraction: http://localhost:{port}/extract_scores")
    app.run(host='0.0.0.0', port=port, debug=True)
