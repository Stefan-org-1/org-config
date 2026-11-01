"""Check the manifest. Prints every problem; exits non-zero if there are any.

usage: validate.py [manifest dir] [org-policy dir]

With GH_TOKEN set, also checks that every person named is a GitHub user.
"""

import os
import pathlib
import re
import subprocess
import sys

import yaml

TEAM_FIELDS = {"team", "lead", "channel", "members", "sentinels", "managers", "repos"}
REPO_FIELDS = {"name", "description", "tier", "shape", "status", "rulesets", "shared", "code_owner_review",
               "required_checks"}
VALUES = {
    "tier": {"critical", "internal"},
    "shape": {"service", "frontend", "vendor", "library", "config", "docs"},
    "status": {"active", "archived"},
}
# Settings that widen access or change enforcement. Only platform repos may set them.
PLATFORM_ONLY = {"shared", "code_owner_review", "required_checks"}


def check_team(path: pathlib.Path, rule_sets: set[str]) -> list[str]:
    t = yaml.safe_load(path.read_text())
    if not isinstance(t, dict):
        return ["not a mapping"]
    errors = [f"unknown field {k}" for k in sorted(t.keys() - TEAM_FIELDS)]
    errors += [f"missing {k}" for k in ("team", "lead", "channel", "repos") if k not in t]
    if errors:
        return errors
    if t["team"] != f"team-{path.stem}":
        errors.append(f"team is {t['team']}, but this file can only define team-{path.stem}")
    members = set(t.get("members", []))
    for role in ("sentinels", "managers"):
        if extra := set(t.get(role, [])) - members:
            errors.append(f"{role} {', '.join(sorted(extra))} not in members")
    for r in t["repos"]:
        where = f"repo {r.get('name', '?')}"
        errors += [f"{where}: unknown field {k}" for k in sorted(r.keys() - REPO_FIELDS)]
        errors += [f"{where}: missing {k}" for k in ("name", "description", "tier", "shape", "status") if k not in r]
        errors += [f"{where}: {k} must be one of {', '.join(sorted(v))}"
                   for k, v in VALUES.items() if k in r and r[k] not in v]
        if t["team"] != "team-platform":
            errors += [f"{where}: {k} is for platform repos only" for k in sorted(PLATFORM_ONLY & r.keys())]
        sets = r.get("rulesets", {})
        named = list(sets.get("merge", [])) + [n for names in sets.get("deploy", {}).values() for n in names]
        errors += [f"{where}: rule set {n} does not exist in org-policy" for n in named if n not in rule_sets]
        errors += [f"{where}: environment {e} must be lowercase letters, digits and dashes"
                   for e in sets.get("deploy", {}) if not re.fullmatch(r"[a-z0-9-]+", e)]
    return errors


def people(path: pathlib.Path) -> set[str]:
    t = yaml.safe_load(path.read_text())
    return {t.get("lead"), *t.get("members", [])} - {None}


def github_user_missing(login: str) -> bool:
    result = subprocess.run(["gh", "api", f"users/{login}"], capture_output=True, text=True)
    return result.returncode != 0 and "Not Found" in result.stderr


def main(manifest: str, policy: str) -> int:
    rule_sets = {p.stem for p in pathlib.Path(policy, "rulesets").glob("*.yaml")}
    files = sorted(pathlib.Path(manifest, "repos").glob("*.yaml"))
    problems = [(f, e) for f in files for e in check_team(f, rule_sets)]

    owners = {}
    for f in files:
        for r in yaml.safe_load(f.read_text()).get("repos", []):
            if r.get("name") in owners:
                problems.append((f, f"repo {r['name']} is already listed in {owners[r['name']].name}"))
            owners.setdefault(r.get("name"), f)

    if os.environ.get("GH_TOKEN"):
        for f in files:
            problems += [(f, f"{login} is not a GitHub user") for login in sorted(people(f)) if github_user_missing(login)]

    for f, e in problems:
        print(f"{f}: {e}")
    print(f"{len(files)} team files, {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(*(sys.argv[1:] or [".", "../org-policy"])))
