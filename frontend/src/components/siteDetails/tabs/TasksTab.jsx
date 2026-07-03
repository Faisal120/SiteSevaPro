import React from "react";
import {
  Plus,
  Calendar,
  User,
  Flag,
  MoreVertical,
  CheckCircle2
} from "lucide-react";

const columns = [
  {
    id: "TODO",
    title: "To Do"
  },
  {
    id: "IN_PROGRESS",
    title: "In Progress"
  },
  {
    id: "DONE",
    title: "Completed"
  }
];

export default function TasksTab({

  tasks = [],

  actions = {}

}) {

  return (

    <div className="space-y-6">

      {/* Header */}

      <div className="flex items-center justify-between">

        <div>

          <h2 className="text-2xl font-bold">

            Project Tasks

          </h2>

          <p className="text-slate-500">

            Track construction activities

          </p>

        </div>

        <button

          onClick={actions?.createTask}

          className="bg-blue-600 hover:bg-blue-700 text-white rounded-xl h-11 px-5 flex items-center gap-2"

        >

          <Plus size={18}/>

          New Task

        </button>

      </div>

      {/* Kanban */}

      <div className="grid lg:grid-cols-3 gap-6">

        {

          columns.map(column=>(

            <div

              key={column.id}

              className="rounded-3xl bg-slate-100 p-4"

            >

              <div className="flex items-center justify-between mb-5">

                <h3 className="font-bold">

                  {column.title}

                </h3>

                <span className="rounded-full bg-white px-3 py-1 text-sm">

                  {

                    tasks.filter(

                      t=>t.status===column.id

                    ).length

                  }

                </span>

              </div>

              <div className="space-y-4">

                {

                  tasks

                    .filter(

                      t=>t.status===column.id

                    )

                    .map(task=>(

                      <TaskCard

                        key={task._id}

                        task={task}

                      />

                    ))

                }

              </div>

            </div>

          ))

        }

      </div>

    </div>

  );

}

function TaskCard({

  task

}){

  return(

    <div className="rounded-2xl bg-white shadow-sm border border-slate-200 p-5 hover:shadow-md transition">

      <div className="flex justify-between">

        <h4 className="font-semibold">

          {task.title}

        </h4>

        <MoreVertical

          size={18}

          className="text-slate-400"

        />

      </div>

      <p className="text-sm text-slate-500 mt-3">

        {task.description}

      </p>

      <div className="mt-5 space-y-3">

        <div className="flex items-center gap-2 text-sm">

          <User size={15}/>

          {task.assigned_to}

        </div>

        <div className="flex items-center gap-2 text-sm">

          <Calendar size={15}/>

          {task.due_date}

        </div>

        <div className="flex items-center gap-2 text-sm">

          <Flag size={15}/>

          {task.priority}

        </div>

      </div>

      {

        task.status==="DONE" && (

          <div className="mt-5 flex items-center gap-2 text-green-600">

            <CheckCircle2 size={18}/>

            Completed

          </div>

        )

      }

    </div>

  )

}