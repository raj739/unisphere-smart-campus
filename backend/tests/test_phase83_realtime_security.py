import pytest
from app.api.v1.realtime import is_channel_authorized, get_websocket_user
from app.models.user import User
from app.models.student import Student


def test_public_channel_authorization():
    user = User(id=1, role="student", is_active=True)
    assert is_channel_authorized(user, "public", db=None)
    assert is_channel_authorized(user, "global", db=None)
    assert is_channel_authorized(user, "announcements", db=None)


def test_admin_channel_authorization():
    admin_user = User(id=1, role="admin", is_active=True)
    student_user = User(id=2, role="student", is_active=True)

    assert is_channel_authorized(admin_user, "admin", db=None)
    assert not is_channel_authorized(student_user, "admin", db=None)
    assert not is_channel_authorized(student_user, "system", db=None)


def test_student_channel_authorization():
    student_user = User(id=10, role="student", is_active=True)
    student_obj = Student(id=5, user_id=10, uni_id="STU100")

    class FakeQuery:
        def __init__(self, obj):
            self.obj = obj
        def filter(self, *args, **kwargs):
            return self
        def first(self):
            return self.obj

    class FakeDB:
        def query(self, model):
            return FakeQuery(student_obj)

    # Own student channel
    assert is_channel_authorized(student_user, "student:STU100", db=FakeDB())

    # Different student channel
    other_student_obj = Student(id=6, user_id=99, uni_id="STU200")
    class FakeDBOther:
        def query(self, model):
            return FakeQuery(other_student_obj)

    assert not is_channel_authorized(student_user, "student:STU200", db=FakeDBOther())


def test_missing_websocket_token_returns_none():
    class FakeWS:
        query_params = {}
        headers = {}

    assert get_websocket_user(FakeWS(), db=None) is None
