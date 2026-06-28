import cv2
import numpy as np
import mediapipe as mp
from rembg import remove
from pathlib import Path
from PIL import Image
import os
import glob

# Load OpenCV face detector
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def extract_hair(image_path, output_path):
    print(f"Processing: {image_path}")
    try:
        # 1. Remove background using rembg
        img = Image.open(image_path)
        img_nobg = remove(img)
        
        # Convert to OpenCV format (RGBA)
        cv_img = np.array(img_nobg)
        
        # 2. Detect face and mask it out using OpenCV Haar Cascades
        if cv_img.shape[2] == 4:
            gray_img = cv2.cvtColor(cv_img, cv2.COLOR_RGBA2GRAY)
        else:
            gray_img = cv2.cvtColor(cv_img, cv2.COLOR_RGB2GRAY)
            cv_img = cv2.cvtColor(cv_img, cv2.COLOR_RGB2RGBA)
            
        faces = face_cascade.detectMultiScale(gray_img, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
        
        if len(faces) > 0:
            h_img, w_img = cv_img.shape[:2]
            
            # Create a mask for the face
            mask = np.zeros((h_img, w_img), dtype=np.uint8)
            
            for (x, y, w, h) in faces:
                # We want to keep the hair (top of head and sides)
                # So we only mask the inner face: from below eyebrows to chin
                # Adjust bounding box to cover the eyes, nose, mouth
                face_center_x = x + w // 2
                face_center_y = y + int(h * 0.6) # Shift center down to avoid cutting bangs
                axes = (int(w * 0.45), int(h * 0.45)) # Ellipse size
                
                cv2.ellipse(mask, (face_center_x, face_center_y), axes, 0, 0, 360, 255, -1)
                
            # Smooth the mask for blending
            mask = cv2.GaussianBlur(mask, (41, 41), 0)
            
            # Apply mask to alpha channel (make face area transparent)
            alpha_channel = cv_img[:, :, 3].astype(float)
            alpha_channel = alpha_channel * (1.0 - (mask.astype(float) / 255.0))
            cv_img[:, :, 3] = alpha_channel.astype(np.uint8)
                
        # 3. Save as PNG
        output_img = Image.fromarray(cv_img)
        output_img.save(output_path)
        return True
    except Exception as e:
        print(f"Failed {image_path}: {e}")
        return False

def main():
    base_dir = r"d:\Pyin_Mal_App\pyin-mal-assets\assets\images\Hair"
    
    # Find all jpg and png files
    search_paths = [
        os.path.join(base_dir, "**", "*.jpg"),
        os.path.join(base_dir, "**", "*.png")
    ]
    
    files = []
    for p in search_paths:
        files.extend(glob.glob(p, recursive=True))
        
    print(f"Found {len(files)} images to process.")
    
    success_count = 0
    for file_path in files:
        # We'll save with a .png extension
        out_path = os.path.splitext(file_path)[0] + ".png"
        
        # If it was a jpg, we will process it, save as png, and delete the original jpg
        # If it was a png, we will process and overwrite
        
        if extract_hair(file_path, out_path):
            success_count += 1
            if file_path.lower().endswith(".jpg") or file_path.lower().endswith(".jpeg"):
                os.remove(file_path) # Delete original jpg
                
    print(f"Successfully processed {success_count} images!")

if __name__ == "__main__":
    main()
