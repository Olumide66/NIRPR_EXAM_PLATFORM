"""Regression tests for authentication boundaries; use a disposable database."""
from datetime import datetime, timedelta
from types import SimpleNamespace

import httpx
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from starlette.requests import Request

import auth
import main
import security_config
import infrastructure
import schemas
from models import UserRole


class FakeDB:
    def __init__(self, *results):
        self.results = iter(results)

    async def execute(self, query):
        value = next(self.results)
        return SimpleNamespace(scalar_one_or_none=lambda: value)


def request(headers=None):
    return Request({"type": "http", "method": "GET", "path": "/api/auth/me",
                    "headers": headers or [], "client": ("127.0.0.1", 1234)})


def credentials(**claims):
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=auth.create_access_token(claims))


def session(user_id=1, revoked=False):
    return SimpleNamespace(user_id=user_id, revoked_at=datetime.utcnow() if revoked else None,
                           expires_at=datetime.utcnow() + timedelta(minutes=5))


def user(user_id=1, role=UserRole.CANDIDATE):
    return SimpleNamespace(id=user_id, role=role, is_active=True, must_change_password=False)


@pytest.mark.asyncio
@pytest.mark.parametrize('claims', [{"sub": "1"}, {"sub": "invalid", "sid": "s"}])
async def test_sessionless_and_malformed_tokens_are_rejected(claims):
    with pytest.raises(HTTPException) as error:
        await auth.get_current_user(request(), credentials(**claims), FakeDB())
    assert error.value.status_code == 401


@pytest.mark.asyncio
@pytest.mark.parametrize('record', [None, session(2), session(revoked=True)])
async def test_invalid_session_cannot_authenticate(record):
    with pytest.raises(HTTPException) as error:
        await auth.get_current_user(request(), credentials(sub="1", sid="s"), FakeDB(record))
    assert error.value.status_code == 401


@pytest.mark.asyncio
async def test_valid_session_authenticates_its_owner():
    result = await auth.get_current_user(request(), credentials(sub="1", sid="s"), FakeDB(session(), user()))
    assert result.id == 1 and result.authenticated_session_id == "s"


@pytest.mark.asyncio
async def test_impersonation_checks_admin_session_and_blocks_exam_actions():
    result = await auth.get_current_user(request(), credentials(sub="2", sid="admin", impersonated_by=1),
                                        FakeDB(session(), user(role=UserRole.ADMIN), user(2)))
    with pytest.raises(HTTPException) as error:
        await auth.require_real_candidate(result)
    assert error.value.status_code == 403


@pytest.mark.asyncio
async def test_impersonation_rejected_after_admin_loses_role():
    with pytest.raises(HTTPException) as error:
        await auth.get_current_user(request(), credentials(sub="2", sid="admin", impersonated_by=1),
                                    FakeDB(session(), user()))
    assert error.value.status_code == 401


def test_untrusted_forwarded_header_cannot_change_rate_limit_identity():
    req = request([(b'x-forwarded-for', b'1.2.3.4'), (b'x-real-ip', b'5.6.7.8')])
    assert auth.get_client_ip(req) == '127.0.0.1'


@pytest.mark.parametrize('key', ['', 'short', 'nirpr-rso-platform-secret-key-change-in-production'])
def test_production_refuses_weak_signing_key(monkeypatch, key):
    monkeypatch.setenv('APP_ENV', 'production')
    monkeypatch.setenv('SECRET_KEY', key)
    with pytest.raises(RuntimeError):
        security_config.signing_key()


def test_production_refuses_public_recaptcha_test_keys(monkeypatch):
    monkeypatch.setenv('APP_ENV', 'production')
    monkeypatch.setenv('RECAPTCHA_SITE_KEY', security_config.RECAPTCHA_TEST_SITE_KEY)
    monkeypatch.setenv('RECAPTCHA_SECRET_KEY', security_config.RECAPTCHA_TEST_SECRET_KEY)
    monkeypatch.setenv('RECAPTCHA_ALLOWED_HOSTNAMES', 'example.test')
    with pytest.raises(RuntimeError):
        security_config.recaptcha_settings()


@pytest.mark.asyncio
@pytest.mark.parametrize('payload,expected', [
    ({'success': True, 'hostname': 'example.test'}, True),
    ({'success': True, 'hostname': 'attacker.test'}, False),
    ({'success': True}, False),
    ({'success': False, 'hostname': 'example.test', 'error-codes': ['timeout-or-duplicate']}, False),
    ({'success': 'true', 'hostname': 'example.test'}, False),
])
async def test_recaptcha_checks_google_result_and_hostname(monkeypatch, payload, expected):
    monkeypatch.setattr(main, 'RECAPTCHA_SECRET_KEY', 'test-only-private-value')
    monkeypatch.setattr(main, 'RECAPTCHA_ALLOWED_HOSTNAMES', {'example.test'})
    client_type = httpx.AsyncClient
    transport = httpx.MockTransport(lambda req: httpx.Response(200, json=payload))
    monkeypatch.setattr(main.httpx, 'AsyncClient', lambda **kw: client_type(transport=transport, **kw))
    assert await main.verify_recaptcha('token', '127.0.0.1') is expected


@pytest.mark.asyncio
async def test_recaptcha_fails_closed_on_network_error(monkeypatch):
    monkeypatch.setattr(main, 'RECAPTCHA_SECRET_KEY', 'test-only-private-value')
    monkeypatch.setattr(main, 'RECAPTCHA_ALLOWED_HOSTNAMES', {'example.test'})
    def fail(req):
        raise httpx.ConnectError('unavailable')
    client_type = httpx.AsyncClient
    monkeypatch.setattr(main.httpx, 'AsyncClient', lambda **kw: client_type(transport=httpx.MockTransport(fail), **kw))
    assert await main.verify_recaptcha('token', '127.0.0.1') is False


@pytest.mark.asyncio
async def test_mfa_setup_cannot_disable_enabled_mfa():
    with pytest.raises(HTTPException) as error:
        await main.setup_mfa(user(role=UserRole.ADMIN), FakeDB(SimpleNamespace(enabled=True)))
    assert error.value.status_code == 409


@pytest.mark.asyncio
async def test_body_limit_rejects_chunked_upload_before_app_runs():
    called = False
    async def app(scope, receive, send):
        nonlocal called
        called = True
    chunks = iter([{'type': 'http.request', 'body': b'1234', 'more_body': True},
                   {'type': 'http.request', 'body': b'5678', 'more_body': False}])
    async def receive():
        return next(chunks)
    sent = []
    async def send(message):
        sent.append(message)
    await security_config.RequestBodyLimitMiddleware(app, max_bytes=6)(
        {'type': 'http', 'path': '/api/upload', 'headers': []}, receive, send)
    assert not called and sent[0]['status'] == 413


@pytest.mark.asyncio
async def test_small_body_is_replayed_without_changes():
    async def app(scope, receive, send):
        assert (await receive())['body'] == b'123456'
    chunks = iter([{'type': 'http.request', 'body': b'123', 'more_body': True},
                   {'type': 'http.request', 'body': b'456', 'more_body': False}])
    async def receive():
        return next(chunks)
    await security_config.RequestBodyLimitMiddleware(app, max_bytes=6)(
        {'type': 'http', 'path': '/api/upload', 'headers': []}, receive, None)


@pytest.mark.asyncio
async def test_rate_limit_fallback_is_bounded(monkeypatch):
    from collections import OrderedDict
    monkeypatch.setattr(infrastructure, 'redis_client', None)
    monkeypatch.setattr(infrastructure, '_memory_windows', OrderedDict())
    monkeypatch.setattr(infrastructure, '_MAX_RATE_KEYS', 2)
    assert await infrastructure.rate_limit('a', 1, 60)
    assert not await infrastructure.rate_limit('a', 1, 60)
    assert await infrastructure.rate_limit('b', 1, 60)
    assert not await infrastructure.rate_limit('c', 1, 60)
    assert len(infrastructure._memory_windows) == 2


@pytest.mark.asyncio
@pytest.mark.parametrize('operation', ['update', 'reset', 'delete', 'create'])
async def test_admin_cannot_take_over_super_admin(operation):
    actor, target = user(1, UserRole.ADMIN), user(2, UserRole.SUPER_ADMIN)
    with pytest.raises(HTTPException) as error:
        if operation == 'update':
            await main.update_user(2, schemas.UserUpdate(is_active=False), actor, FakeDB(target))
        elif operation == 'reset':
            await main.admin_reset_password(2, SimpleNamespace(new_password='a-new-password'), actor, FakeDB(target))
        elif operation == 'delete':
            await main.delete_user(2, False, actor, FakeDB(target))
        else:
            await main.create_staff_user(SimpleNamespace(email='admin@example.test', role=schemas.UserRole.SUPER_ADMIN), actor, FakeDB(None))
    assert error.value.status_code == 403


def test_jwt_without_expiration_is_rejected():
    token = auth.jwt.encode({'sub': '1', 'sid': 'session'}, auth.SECRET_KEY, algorithm='HS256')
    assert auth.decode_token(token) is None


@pytest.mark.asyncio
async def test_logout_revokes_authenticated_session():
    statements = []
    class DB:
        async def execute(self, stmt):
            statements.append(stmt.compile().params)
        async def commit(self):
            statements.append('committed')
    actor = user()
    actor.authenticated_session_id = 'current-session'
    await main.logout(actor, DB())
    assert statements[0]['id_1'] == 'current-session'
    assert statements[0]['revoked_at'] is not None
    assert statements[-1] == 'committed'


@pytest.mark.asyncio
async def test_recaptcha_config_never_returns_secret(monkeypatch):
    monkeypatch.setattr(main, 'RECAPTCHA_SITE_KEY', 'public-site-key')
    monkeypatch.setattr(main, 'RECAPTCHA_SECRET_KEY', 'private-secret-key')
    monkeypatch.setattr(main, 'RECAPTCHA_ALLOWED_HOSTNAMES', {'example.test'})
    assert await main.recaptcha_config() == {'site_key': 'public-site-key', 'provider': 'google_recaptcha_v2'}


@pytest.mark.asyncio
@pytest.mark.parametrize('content_type,content', [('application/pdf', b'<html>bad</html>'), ('image/png', b'not an image')])
async def test_receipt_spoofing_is_rejected_before_storage(content_type, content):
    from starlette.datastructures import UploadFile, Headers
    from io import BytesIO
    upload = UploadFile(BytesIO(content), filename='receipt', headers=Headers({'content-type': content_type}))
    with pytest.raises(HTTPException) as error:
        await main.upload_payment(1, upload, None, None, user(), FakeDB())
    assert error.value.status_code == 400
