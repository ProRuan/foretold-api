# Standard library
import os

# Third-party
from django.http import JsonResponse


TRUTHY_VALUES = {'1', 'true', 'yes', 'on'}


def get_env(name: str, default: str | None = None) -> str:
    """
    Return an environment variable or a default value.
    Raise an error if the variable is required and missing.
    """
    value = os.getenv(name, default)
    if value is None:
        raise RuntimeError(f'Missing required env var: {name}')
    return value


def get_env_bool(name: str, default: bool = False) -> bool:
    """
    Return a boolean environment variable,
    interpreting common truthy values.
    """
    return get_env(name, str(default)).strip().lower() in TRUTHY_VALUES


def get_env_csv(name: str, default: str = '') -> list[str]:
    """
    Return a list from a comma-separated environment variable.
    """
    raw = get_env(name, default).strip()
    return [item.strip() for item in raw.split(',') if item.strip()]


def health_view(_request: object) -> JsonResponse:
    """View function for health check endpoint."""
    return JsonResponse({'status': 'ok'})
