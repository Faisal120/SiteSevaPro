def generate_plan(data):

    plot_width = float(data["plot_width"])
    plot_length = float(data["plot_length"])

    bedrooms = int(data["bedrooms"])
    bathrooms = int(data["bathrooms"])

    rooms = []

    # Living Room
    rooms.append({
        "name": "Living Room",
        "x": 0,
        "y": 0,
        "width": round(plot_width * 0.45, 2),
        "height": round(plot_length * 0.25, 2),
        "type": "living"
    })

    # Kitchen
    rooms.append({
        "name": "Kitchen",
        "x": round(plot_width * 0.50, 2),
        "y": 0,
        "width": round(plot_width * 0.20, 2),
        "height": round(plot_length * 0.18, 2),
        "type": "kitchen"
    })

    # Parking
    rooms.append({
        "name": "Parking",
        "x": round(plot_width * 0.75, 2),
        "y": 0,
        "width": round(plot_width * 0.22, 2),
        "height": 12,
        "type": "parking"
    })

    current_y = 15

    for i in range(bedrooms):

        rooms.append({
            "name": f"Bedroom {i+1}",
            "x": (i % 2) * 14,
            "y": current_y,
            "width": 12,
            "height": 12,
            "type": "bedroom"
        })

        if i % 2 == 1:
            current_y += 13

    for i in range(bathrooms):

        rooms.append({
            "name": f"Bath {i+1}",
            "x": 30,
            "y": 15 + (i * 8),
            "width": 6,
            "height": 6,
            "type": "bathroom"
        })

    return {
        "plot_width": plot_width,
        "plot_length": plot_length,
        "facing": data["facing"],
        "floors": data["floors"],
        "rooms": rooms
    }