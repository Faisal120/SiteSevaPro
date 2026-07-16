from dataclasses import dataclass, field


@dataclass
class ScheduleRow:

    values: dict


@dataclass
class Schedule:

    title: str

    columns: list

    rows: list[ScheduleRow] = field(
        default_factory=list,
    )

    def add_row(
        self,
        **kwargs,
    ):
        self.rows.append(
            ScheduleRow(kwargs)
        )