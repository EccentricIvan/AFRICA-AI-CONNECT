"""Server settings, from the environment. Nothing here is a secret the app
needs: the app holds no key, URL or code until a school enrolls it."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    #: Where the registry and every school's folder live.
    data_dir: Path
    #: Plain HTTP is refused unless this is set (development and tests).
    allow_http: bool = False
    #: Each school's database URL, from its id and folder. SQLite files by
    #: default; production can point this at one Postgres database (and
    #: role) per school, e.g. "postgresql+psycopg://otic_{school_id}@db/{school_id}".
    school_db_url: str = "sqlite:///{folder}/school.sqlite"
    #: How far a device's clock may be from the server's. Wide on purpose:
    #: learner devices' clocks are often wrong, and the nonce cache is what
    #: stops replays.
    clock_window_hours: int = 24
    #: How long a nonce is remembered per device.
    nonce_hours: int = 48
    max_body_bytes: int = 1 * 1024 * 1024
    max_file_bytes: int = 40 * 1024 * 1024
    #: Wrong enrollment codes per client address per hour before refusal.
    enroll_failures_per_hour: int = 20

    @property
    def registry_url(self) -> str:
        return f"sqlite:///{(self.data_dir / 'registry.sqlite').as_posix()}"

    def school_folder(self, school_id: str) -> Path:
        return self.data_dir / "schools" / school_id

    def school_url(self, school_id: str) -> str:
        return self.school_db_url.format(
            school_id=school_id, folder=self.school_folder(school_id).as_posix()
        )

    @staticmethod
    def from_env() -> "Settings":
        return Settings(
            data_dir=Path(os.environ.get("OTIC_DATA_DIR", "./otic-data")).resolve(),
            allow_http=os.environ.get("OTIC_ALLOW_HTTP") == "1",
            school_db_url=os.environ.get(
                "OTIC_SCHOOL_DB_URL", "sqlite:///{folder}/school.sqlite"
            ),
        )
