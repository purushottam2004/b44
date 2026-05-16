import email
import logging

from fastapi import APIRouter, Request

logger = logging.getLogger(__name__)


router = APIRouter(
    prefix="/api/v1",
)

@router.get("/hello")
def hello(request: Request) -> dict:
    """
    A sample endpoint that requires authentication.
    """

    return {
        "message": "hello",
    }