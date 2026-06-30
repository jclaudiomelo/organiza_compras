from PIL import Image

def remove_background(image_path, output_path):
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()
        
        newData = []
        for item in datas:
            # item is (R, G, B, A). Black is (0,0,0)
            # Remove pixels that are very close to black
            if item[0] < 20 and item[1] < 20 and item[2] < 20:
                newData.append((255, 255, 255, 0)) # transparent
            else:
                newData.append(item)
                
        img.putdata(newData)
        img.save(output_path, "PNG")
        print("Success")
    except Exception as e:
        print(f"Error: {e}")

remove_background("assets/images/logo.png", "assets/images/logo.png")
