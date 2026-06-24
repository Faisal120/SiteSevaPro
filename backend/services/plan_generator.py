def generate_plan(data):

    return {
        "plot_width": data["plot_width"],
        "plot_length": data["plot_length"],
        "facing": data["facing"],

        "rooms":[
            {
                "name":"Living Room",
                "x":0,
                "y":0,
                "width":15,
                "height":12
            },
            {
                "name":"Kitchen",
                "x":15,
                "y":0,
                "width":10,
                "height":10
            }
        ]
    }