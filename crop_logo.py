from PIL import Image
import os

def crop_center(image_path, output_path, zoom_factor=1.5):
    try:
        img = Image.open(image_path)
        width, height = img.size
        
        # Calculate new dimensions (view port)
        # If zoom is 1.5x, we want to keep 1/1.5 = 0.666 of the image
        view_width = width / zoom_factor
        view_height = height / zoom_factor
        
        # Calculate crop coordinates
        left = (width - view_width) / 2
        top = (height - view_height) / 2
        right = (width + view_width) / 2
        bottom = (height + view_height) / 2
        
        # Crop
        img_cropped = img.crop((left, top, right, bottom))
        
        # Resize back to original size for high quality icon generation (optional but good)
        # Or just save the cropped version. flutter_launcher_icons will handle resizing.
        # But let's resize to at least 1024x1024 or original to maintain quality.
        img_resampled = img_cropped.resize((width, height), Image.Resampling.LANCZOS)
        
        img_resampled.save(output_path)
        print(f"Successfully cropped {image_path} to {output_path} with {zoom_factor}x zoom.")
        
    except Exception as e:
        print(f"Error cropping image: {e}")

if __name__ == "__main__":
    input_file = "assets/images/savora_logo.png"
    output_file = "assets/images/savora_logo_clean.png"
    
    # Ensure assets dir exists
    if not os.path.exists("assets/images"):
        os.makedirs("assets/images")
        
    crop_center(input_file, output_file, zoom_factor=1.55) # Slightly more than 1.5 to be safe
