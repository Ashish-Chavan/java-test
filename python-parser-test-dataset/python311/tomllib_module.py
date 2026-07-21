"""
Python 3.11 Feature: tomllib — TOML parsing in the standard library (PEP 680)
Read TOML files without third-party dependencies.
tomllib is read-only (parsing only); use third-party tomli-w for writing.
"""
import tomllib
import io


# ── Basic TOML parsing ────────────────────────────────────────────────────
print("=== Basic TOML Parsing ===")

basic_toml = b"""
title = "TOML Example"
version = 1
debug = false
pi = 3.14159

[owner]
name = "Alice"
joined = 2020-01-15

[database]
host = "localhost"
port = 5432
name = "myapp"
enabled = true
"""

data = tomllib.loads(basic_toml.decode())
print(f"Title:   {data['title']}")
print(f"Version: {data['version']}")
print(f"Owner:   {data['owner']['name']}")
print(f"DB port: {data['database']['port']}")
print(f"Joined:  {data['owner']['joined']}")  # datetime.date object


# ── Arrays and inline tables ───────────────────────────────────────────────
print("\n=== Arrays and Inline Tables ===")

array_toml = b"""
fruits = ["apple", "banana", "cherry"]
matrix = [[1, 2], [3, 4], [5, 6]]
scores = [85, 92, 78, 96]

[server]
host = "0.0.0.0"
ports = [8080, 8081, 8082]
tags = ["web", "api", "v2"]

[[products]]
name = "Widget"
price = 9.99
in_stock = true

[[products]]
name = "Gadget"
price = 24.95
in_stock = false

[[products]]
name = "Doohickey"
price = 4.49
in_stock = true
"""

data = tomllib.loads(array_toml.decode())
print(f"Fruits:   {data['fruits']}")
print(f"Matrix:   {data['matrix']}")
print(f"Ports:    {data['server']['ports']}")
print(f"Products:")
for p in data['products']:
    status = "✓" if p['in_stock'] else "✗"
    print(f"  {status} {p['name']:12} ${p['price']:.2f}")


# ── pyproject.toml style ───────────────────────────────────────────────────
print("\n=== pyproject.toml Style ===")

pyproject = b"""
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.backends.legacy:build"

[project]
name = "my-package"
version = "1.2.3"
description = "A sample Python package"
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.11"
dependencies = [
    "requests>=2.28",
    "pydantic>=2.0",
    "click>=8.0",
]

[project.optional-dependencies]
dev = ["pytest>=7.0", "mypy>=1.0", "ruff>=0.1"]
docs = ["sphinx>=6.0", "furo"]

[project.urls]
Homepage = "https://github.com/example/my-package"
Issues = "https://github.com/example/my-package/issues"

[project.scripts]
my-cli = "my_package.cli:main"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"

[tool.mypy]
strict = true
python_version = "3.11"
"""

project = tomllib.loads(pyproject.decode())
pkg = project["project"]
print(f"Package: {pkg['name']} v{pkg['version']}")
print(f"Requires Python: {pkg['requires-python']}")
print(f"Dependencies ({len(pkg['dependencies'])}):")
for dep in pkg['dependencies']:
    print(f"  - {dep}")
print(f"Dev deps: {project['project']['optional-dependencies']['dev']}")
print(f"Test paths: {project['tool']['pytest.ini_options']['testpaths']}")


# ── tomllib.load() from binary file-like object ────────────────────────────
print("\n=== load() from binary stream ===")

config_bytes = b"""
[app]
name = "MyApp"
log_level = "INFO"
max_connections = 100

[app.timeouts]
connect = 5.0
read = 30.0
write = 10.0
"""

with io.BytesIO(config_bytes) as f:
    config = tomllib.load(f)

print(f"App: {config['app']['name']}")
print(f"Log level: {config['app']['log_level']}")
print(f"Connect timeout: {config['app']['timeouts']['connect']}s")


# ── Error handling ────────────────────────────────────────────────────────
print("\n=== Error Handling ===")

invalid_toml_cases = [
    (b"key = ", "incomplete value"),
    (b"[section\nkey = 1", "unclosed section"),
    (b'str = "unterminated', "unterminated string"),
]

for toml_bytes, description in invalid_toml_cases:
    try:
        tomllib.loads(toml_bytes.decode())
    except tomllib.TOMLDecodeError as e:
        print(f"  {description}: TOMLDecodeError caught ✓")
