BUILDING_RULES = {

    "Living":{

        "adjacent":[

            "Dining",

            "Entrance",

        ],

        "avoid":[

            "Bathroom",

        ],

    },

    "Dining":{

        "adjacent":[

            "Kitchen",

            "Living",

        ],

    },

    "Kitchen":{

        "adjacent":[

            "Dining",

        ],

        "avoid":[

            "Master Bedroom",

        ],

    },

    "Bathroom":{

        "avoid":[

            "Living",

        ],

    }

}