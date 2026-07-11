class PhotosBuilder:

    @staticmethod
    def build(reports):

        photos = []

        for report in reports:

            for media in report.get("media_urls", []):

                if media.get("type") != "image":
                    continue

                photos.append({

                    "url": media.get("url"),

                    "thumbnail": media.get(
                        "thumbnail",
                        media.get("url"),
                    ),

                    "caption": media.get("caption"),

                    "site_name": report.get("site_name"),

                    "created_at": report.get("created_at"),

                })

        photos.sort(

            key=lambda x: x.get(
                "created_at"
            ),

            reverse=True,

        )

        return photos[:8]