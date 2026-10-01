"""
UniSphere dependency compatibility layer.

Centralizes authentication dependencies so legacy and newer
API modules can use the same security implementation.
"""

from app.core.security import get_current_user

__all__ = [
    "get_current_user",
]