"""
Common Response Models

SiteSeva Pro
"""

from typing import Any, Generic, List, Optional, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class MessageResponse(BaseModel):
    success: bool = True
    message: str


class IdResponse(BaseModel):
    success: bool = True
    id: str


class PaginatedResponse(BaseModel, Generic[T]):
    success: bool = True
    total: int
    items: List[T]


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    detail: Optional[Any] = None