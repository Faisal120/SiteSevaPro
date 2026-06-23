def generate_layout(data):

    plot_width = float(data["plot_width"])
    plot_length = float(data["plot_length"])

    bedrooms = int(data["bedrooms"])
    bathrooms = int(data["bathrooms"])

    scale = 12

    plot_w = plot_width * scale
    plot_l = plot_length * scale

    rooms = []

    # Living Room

    rooms.append({
        "name": "Living Room",
        "x": 50,
        "y": 250,
        "w": plot_w * 0.45,
        "h": plot_l * 0.22
    })

    # Dining

    rooms.append({
        "name": "Dining",
        "x": 50,
        "y": 250 + (plot_l * 0.22),
        "w": plot_w * 0.30,
        "h": plot_l * 0.15
    })

    # Kitchen

    rooms.append({
        "name": "Kitchen",
        "x": plot_w * 0.55,
        "y": 250,
        "w": plot_w * 0.22,
        "h": plot_l * 0.18
    })

    # Staircase

    rooms.append({
        "name": "Stair",
        "x": plot_w * 0.80,
        "y": 250,
        "w": plot_w * 0.15,
        "h": plot_l * 0.22
    })

    current_y = 520

    for i in range(bedrooms):

        rooms.append({
            "name": f"Bedroom {i+1}",
            "x": 50 + ((i % 2) * 320),
            "y": current_y,
            "w": 280,
            "h": 180
        })

        if i % 2 == 1:
            current_y += 210

    bath_y = 520

    for i in range(bathrooms):

        rooms.append({
            "name": f"Bath {i+1}",
            "x": 720,
            "y": bath_y,
            "w": 140,
            "h": 100
        })

        bath_y += 120

    # Parking

    rooms.append({
        "name": "Parking",
        "x": 920,
        "y": 250,
        "w": 220,
        "h": 180
    })

    return rooms