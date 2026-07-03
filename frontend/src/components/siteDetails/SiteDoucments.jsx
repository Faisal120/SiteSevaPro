import {
  FileText,
  Download,
  Eye,
  FolderOpen
} from "lucide-react";

export default function SiteDocuments({

  documents = []

}) {

  return (

    <div className="rounded-3xl bg-white border border-slate-200 shadow-sm">

      <div className="flex items-center justify-between p-6 border-b">

        <div>

          <h2 className="text-xl font-bold">

            Site Documents

          </h2>

          <p className="text-slate-500 mt-1">

            Drawings, BOQ, Agreements & Reports

          </p>

        </div>

        <FolderOpen className="text-blue-600"/>

      </div>

      {

        documents.length===0 ?

        (

          <div className="p-12 text-center">

            <FolderOpen
              size={50}
              className="mx-auto text-slate-300"
            />

            <h3 className="mt-4 font-semibold">

              No Documents Uploaded

            </h3>

            <p className="text-slate-500 mt-2">

              Upload BOQ, Drawings or Reports.

            </p>

          </div>

        )

        :

        (

          <div className="divide-y">

            {

              documents.map(doc=>(

                <div

                  key={doc._id}

                  className="flex items-center justify-between p-5 hover:bg-slate-50 transition"

                >

                  <div className="flex items-center gap-4">

                    <div className="h-12 w-12 rounded-xl bg-blue-50 flex items-center justify-center">

                      <FileText className="text-blue-600"/>

                    </div>

                    <div>

                      <h4 className="font-semibold">

                        {doc.title}

                      </h4>

                      <p className="text-sm text-slate-500">

                        {doc.date}

                      </p>

                    </div>

                  </div>

                  <div className="flex gap-2">

                    <button className="h-10 w-10 rounded-xl bg-slate-100 hover:bg-blue-100 flex items-center justify-center">

                      <Eye size={18}/>

                    </button>

                    <button className="h-10 w-10 rounded-xl bg-slate-100 hover:bg-blue-100 flex items-center justify-center">

                      <Download size={18}/>

                    </button>

                  </div>

                </div>

              ))

            }

          </div>

        )

      }

    </div>

  );

}