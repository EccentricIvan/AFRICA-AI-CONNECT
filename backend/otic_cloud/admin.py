"""Operator commands, run in the server's shell — never an API the app can
reach. Usage:

    python -m otic_cloud.admin pending
    python -m otic_cloud.admin approve <registration_id>
    python -m otic_cloud.admin reject <registration_id>
    python -m otic_cloud.admin schools
"""

from __future__ import annotations

import sys

from sqlalchemy import select

from .config import Settings
from .models import Registration, School
from .store import Store


def main(argv: list[str]) -> int:
    store = Store(Settings.from_env())
    if not argv:
        print(__doc__)
        return 2
    cmd, *args = argv
    if cmd == "pending":
        with store.registry() as s:
            for r in s.scalars(select(Registration).where(Registration.status == "pending")):
                print(f"{r.id}\t{r.name}\t{r.district}\t{r.contact_name} {r.contact_phone}")
        return 0
    if cmd == "approve" and len(args) == 1:
        school_id, code = store.approve(args[0])
        print(f"School {school_id} is active.")
        print(f"First Admin enrollment code (one use, 7 days): {code}")
        return 0
    if cmd == "reject" and len(args) == 1:
        with store.registry() as s:
            r = s.get(Registration, args[0])
            if r is None or r.status != "pending":
                print("No pending registration with that id.")
                return 1
            r.status = "rejected"
        store.operator_audit("registration.rejected", args[0])
        return 0
    if cmd == "schools":
        with store.registry() as s:
            for x in s.scalars(select(School)):
                print(f"{x.id}\t{x.status}\t{x.name}")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
