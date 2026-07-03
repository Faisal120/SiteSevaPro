from typing import Optional, Literal

from pydantic import BaseModel


NotificationType = Literal[
    "SITE",
    "PAYMENT",
    "MATERIAL",
    "ATTENDANCE",
    "TASK",
    "LABOUR",
    "WALLET",
    "SYSTEM",
]


NotificationPriority = Literal[
    "LOW",
    "MEDIUM",
    "HIGH",
]


class NotificationCreate(BaseModel):

    title: str

    message: str

    type: NotificationType

    priority: NotificationPriority = "MEDIUM"

    company_id: str

    user_id: Optional[str] = None

    site_id: Optional[str] = None

    labour_id: Optional[str] = None

    action_url: Optional[str] = None


class NotificationUpdate(BaseModel):

    read: bool = True