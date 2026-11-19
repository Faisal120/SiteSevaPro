import {
  Package,
  AlertTriangle,
  ShoppingCart,
  TrendingDown,
  Plus,
  Download,
  Eye
} from "lucide-react";

export default function MaterialsTab({
  materials = [],
  actions = {}
}) {

  const totalItems = materials.length;

  const lowStock = materials.filter(
    m => (m.available_qty || 0) <= (m.min_stock || 0)
  ).length;

  const totalValue = materials.reduce(
    (sum, m) => sum + ((m.available_qty || 0) * (m.rate || 0)),
    0
  );

  const todayConsumption = materials.reduce(
    (sum, m) => sum + (m.today_consumption || 0),
    0
  );

  return (

    <div className="space-y-6">

      {/* Summary */}

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">

        <StatsCard  
          title="Materials"
          value={totalItems}
          icon={Package}
          color="blue"
        />

        <StatsCard
          title="Low Stock"
          value={lowStock}
          icon={AlertTriangle}
          color="blue"
        />

        <StatsCard
          title="Today's Consumption"
          value={todayConsumption}
          icon={TrendingDown}
          color="red"
        />

        <StatsCard
          title="Inventory Value"
          value={`₹${totalValue.toLocaleString("en-IN")}`}
          icon={ShoppingCart}
          color="green"
        />

      </div>

      {/* Table */}

      <div className="rounded-3xl bg-white border border-slate-200 shadow-sm overflow-hidden">

        <div className="flex items-center justify-between p-6 border-b">

          <div>

            <h2 className="text-xl font-bold">

              Material Inventory

            </h2>

            <p className="text-slate-500">

              Live stock management

            </p>

          </div>

          <div className="flex gap-3">

            <button className="h-11 px-5 rounded-xl bg-blue-600 text-white flex items-center gap-2">

              <Plus size={18}/>

              Add Material

            </button>

            <button className="h-11 px-5 rounded-xl border flex items-center gap-2">

              <Download size={18}/>

              Export

            </button>

          </div>

        </div>

        <div className="overflow-x-auto">

          <table className="w-full">

            <thead className="bg-slate-50">

              <tr>

                <th className="text-left px-6 py-4">Material</th>

                <th>Available</th>

                <th>Min Stock</th>

                <th>Rate</th>

                <th>Status</th>

                <th>Action</th>

              </tr>

            </thead>

            <tbody>

              {

                materials.map(material => {

                  const low =
                    (material.available_qty || 0) <=
                    (material.min_stock || 0);

                  return (

                    <tr
                      key={material._id}
                      className="border-t hover:bg-slate-50"
                    >

                      <td className="px-6 py-5">

                        <div>

                          <div className="font-semibold">

                            {material.name}

                          </div>

                          <div className="text-sm text-slate-500">

                            {material.category}

                          </div>

                        </div>

                      </td>

                      <td className="text-center">

                        {material.available_qty}

                      </td>

                      <td className="text-center">

                        {material.min_stock}

                      </td>

                      <td className="text-center">

                        ₹{material.rate}

                      </td>

                      <td className="text-center">

                        <span
                          className={`px-3 py-1 rounded-full text-sm ${
                            low
                              ? "bg-red-100 text-red-700"
                              : "bg-green-100 text-green-700"
                          }`}
                        >

                          {low ? "Low Stock" : "Available"}

                        </span>

                      </td>

                      <td className="text-center">

                        <button className="text-blue-600">

                          <Eye size={18} />

                        </button>

                      </td>

                    </tr>

                  );

                })

              }

            </tbody>

          </table>

        </div>

      </div>

    </div>

  );

}
