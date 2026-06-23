def generate_layout(data):

    plot_width = float(data["plot_width"])
    plot_length = float(data["plot_length"])

    scale = 15

    W = plot_width * scale
    H = plot_length * scale

    rooms = []

    parking_w = W * 0.35

    living_w = W * 0.45
    living_h = H * 0.22

    rooms.append({

        "name":"Living Room",

        "x":40,

        "y":80,

        "w":living_w,

        "h":living_h,

        "furniture":"SOFA"
    })

    rooms.append({
        "name":"Dining",
        "x":40,
        "y":80 + living_h,
        "w":living_w * 0.65,
        "h":100
    })

    rooms.append({
        "name":"Kitchen",
        "x":40 + living_w,
        "y":80,
        "w":140,
        "h":120
    })

    rooms.append({
        "name":"Stair",
        "x":40 + living_w + 160,
        "y":80,
        "w":90,
        "h":140
    })

    rooms.append({
        "name":"Parking",
        "x":W - parking_w,
        "y":80,
        "w":parking_w - 60,
        "h":180
    })

    bedroom_y = 320

    for i in range(bedrooms):

        rooms.append({

            "name": f"Bedroom {i+1}",

            "x": 40 + (i % 2) * 280,

            "y": bedroom_y,

            "w": 240,

            "h": 180,

            "furniture": "BED"

        })

    bath_x = 620

    for i in range(int(data["bathrooms"])):

        rooms.append({
            "name":f"Bath {i+1}",
            "x":bath_x,
            "y":320 + i*120,
            "w":120,
            "h":90
        })

    return rooms