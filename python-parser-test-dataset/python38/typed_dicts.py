"""
Python 3.8 Feature: TypedDict (typing.TypedDict — PEP 589)
TypedDict lets you annotate dicts with specific key/value types.
Two definition styles: class syntax and functional syntax.
"""
from __future__ import annotations
from typing import TypedDict, Optional, List, NotRequired, Required


# ── Class-based syntax ─────────────────────────────────────────────────────
class Movie(TypedDict):
    title: str
    year: int
    rating: float


class Person(TypedDict):
    name: str
    age: int
    email: str


# ── Functional syntax (useful for keys that are reserved words) ────────────
Config = TypedDict("Config", {
    "host": str,
    "port": int,
    "debug": bool,
    "class": str,    # 'class' would be invalid in class syntax
})


# ── Inheritance: extending TypedDicts ─────────────────────────────────────
class MediaItem(TypedDict):
    id: int
    title: str
    created_at: str


class Film(MediaItem):
    director: str
    duration_minutes: int
    genres: List[str]


class Series(MediaItem):
    seasons: int
    episodes_per_season: int
    status: str


# ── total=False: all keys optional ────────────────────────────────────────
class PartialConfig(TypedDict, total=False):
    timeout: int
    retries: int
    verbose: bool
    log_file: str


# ── Mixing required and optional (Python 3.11 style with Required/NotRequired) ─
class UserProfile(TypedDict):
    user_id: int                         # required
    username: str                        # required
    email: str                           # required
    bio: NotRequired[str]                # optional
    avatar_url: NotRequired[Optional[str]]  # optional, can be None
    follower_count: NotRequired[int]


# ── Nested TypedDicts ──────────────────────────────────────────────────────
class Address(TypedDict):
    street: str
    city: str
    country: str
    zip_code: str


class ContactInfo(TypedDict):
    phone: str
    address: Address
    emergency_contact: Optional[str]


class Employee(TypedDict):
    employee_id: str
    personal: Person
    contact: ContactInfo
    department: str
    salary: float


# ── Usage examples ────────────────────────────────────────────────────────
movie: Movie = {
    "title": "Inception",
    "year": 2010,
    "rating": 8.8,
}
print(f"Movie: {movie['title']} ({movie['year']}) ★{movie['rating']}")


film: Film = {
    "id": 1,
    "title": "The Matrix",
    "created_at": "1999-03-31",
    "director": "Wachowski Sisters",
    "duration_minutes": 136,
    "genres": ["sci-fi", "action"],
}
print(f"Film: {film['title']} by {film['director']}")


partial: PartialConfig = {
    "timeout": 30,
    "verbose": True,
    # retries and log_file not provided — all keys optional
}
print(f"Config timeout: {partial.get('timeout')}")


profile: UserProfile = {
    "user_id": 42,
    "username": "alice",
    "email": "alice@example.com",
    # bio, avatar_url, follower_count are NotRequired — omitted
}
print(f"User: {profile['username']} <{profile['email']}>")


# ── Functions accepting TypedDicts ────────────────────────────────────────
def format_movie(m: Movie) -> str:
    return f"{m['title']} ({m['year']}) — rated {m['rating']}/10"


def get_employee_summary(emp: Employee) -> str:
    return (
        f"{emp['personal']['name']} | {emp['department']} | "
        f"{emp['contact']['address']['city']}"
    )


print(f"\n{format_movie(movie)}")

employee: Employee = {
    "employee_id": "E001",
    "personal": {"name": "Bob Smith", "age": 35, "email": "bob@corp.com"},
    "contact": {
        "phone": "+1-555-0100",
        "address": {
            "street": "123 Main St",
            "city": "Springfield",
            "country": "USA",
            "zip_code": "12345",
        },
        "emergency_contact": "Jane Smith",
    },
    "department": "Engineering",
    "salary": 95000.0,
}
print(get_employee_summary(employee))


# ── Type checking behavior (runtime is just a regular dict) ────────────────
print(f"\ntype(movie) = {type(movie)}")          # <class 'dict'>
print(f"isinstance dict: {isinstance(movie, dict)}")   # True
print(f"Movie keys: {list(Movie.__annotations__.keys())}")
