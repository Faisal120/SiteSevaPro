import {
  Camera,
  ImageOff
} from "lucide-react";

export default function SitePhotoGallery({

  photos=[]

}){

  return(

    <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

      <div className="p-6 border-b">

        <div className="flex justify-between">

          <div>

            <h2 className="text-xl font-bold">

              Site Photos

            </h2>

            <p className="text-slate-500 mt-1">

              Latest construction updates

            </p>

          </div>

          <Camera className="text-blue-600"/>

        </div>

      </div>

      {

        photos.length===0

        ?

        (

          <div className="p-12 text-center">

            <ImageOff

              size={48}

              className="mx-auto text-slate-300"

            />

            <h3 className="mt-5 font-semibold">

              No Photos Available

            </h3>

            <p className="text-slate-500 mt-2">

              Upload site photos to track project progress.

            </p>

          </div>

        )

        :

        (

          <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-5 p-6">

            {

              photos.map(photo=>(

                <div

                  key={photo._id}

                  className="group overflow-hidden rounded-2xl border border-slate-200"

                >

                  <img

                    src={photo.url}

                    alt="Site"

                    className="h-56 w-full object-cover transition duration-300 group-hover:scale-105"

                  />

                  <div className="p-4">

                    <p className="font-semibold">

                      {photo.title || "Construction Photo"}

                    </p>

                    <p className="text-sm text-slate-500 mt-1">

                      {photo.date}

                    </p>

                  </div>

                </div>

              ))

            }

          </div>

        )

      }

    </div>

  )

}