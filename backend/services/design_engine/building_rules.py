BUILDING_RULES = {

    "Living": {
        "adjacent": [
            "Dining",
            "Bedroom",
        ],
        "avoid": [
            "Bathroom",
        ],
    },

    "Dining": {
        "adjacent": [
            "Living",
            "Kitchen",
        ],
    },

    "Kitchen": {
        "adjacent": [
            "Dining",
        ],
        "avoid": [
            "Bedroom",
        ],
    },

    "Bedroom": {
        "adjacent": [
            "Living",
            "Bathroom",
        ],
    },

    "Bathroom": {
        "adjacent": [
            "Bedroom",
        ],
        "avoid": [
            "Living",
        ],
    },

    "Parking": {
        "adjacent": [
            "Living",
        ],
    },

    "Garden": {
        "adjacent": [
            "Living",
        ],
    },

    "Stair": {
        "adjacent": [
            "Living",
        ],
    },

}