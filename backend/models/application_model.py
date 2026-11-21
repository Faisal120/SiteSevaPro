from pydantic import BaseModel


class ApplicationSubmittedOut(BaseModel):

    success: bool

    message: str

    application_id: str
