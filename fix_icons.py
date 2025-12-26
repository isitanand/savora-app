import os
from PIL import Image

def fix_icons():
    source_path = r'c:\Users\ASUS\.gemini\antigravity\scratch\core-vission\core_vision\assets\images\savora_logo_clean.png'
    base_res_path = r'c:\Users\ASUS\.gemini\antigravity\scratch\core-vission\core_vision\android\app\src\main\res'
    
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    if not os.path.exists(source_path):
        print(f"Error: Source image not found at {source_path}")
        return

    try:
        img = Image.open(source_path)
        print(f"Opened source image: {img.size}")

        for folder, size in sizes.items():
            target_dir = os.path.join(base_res_path, folder)
            if not os.path.exists(target_dir):
                os.makedirs(target_dir)
            
            target_path = os.path.join(target_dir, 'ic_launcher.png')
            
            # Resize
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            resized_img.save(target_path, 'PNG')
            print(f"Saved {folder}/ic_launcher.png ({size}x{size})")

    except Exception as e:
        print(f"Failed to process icons: {e}")

if __name__ == "__main__":
    fix_icons()
