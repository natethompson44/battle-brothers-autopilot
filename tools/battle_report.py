"""Battle report: turn Battle Brothers' log.html into a readable per-fight summary.

Usage:
    python tools/battle_report.py                 # reads the default log location
    python tools/battle_report.py path/to/log.html
    python tools/battle_report.py --last          # only the most recent fight, full turn list
    python tools/battle_report.py --dump out.txt  # also write the parsed plain-text log

Copy log.html somewhere before relaunching the game if you need to keep a crash: the game
overwrites it on start.
"""
import collections
import html
import pathlib
import re
import sys

DEFAULT_LOG = pathlib.Path.home() / "OneDrive" / "Documents" / "Battle Brothers" / "log.html"
ALT_LOG = pathlib.Path.home() / "Documents" / "Battle Brothers" / "log.html"
NOISE = re.compile(r"Texture|Resource|Brush|Sound|snh: movementCost|Persistence|Renderer|Platform")
ENEMY_WORDS = ("Peasant", "Bandit", "Brigand", "Thrall", "Caravan", "Farmhand", "Guard", "Drone", "Wolf",
               "Rabble", "Poacher", "Thug", "Mercenary", "Nomad", "Hyena", "Unhold", "Orc", "Goblin", "Ghoul",
               "Nachzehrer", "Hexe", "Skeleton", "Vampire", "Zombie", "Wiedergänger", "Slave", "Indebted",
               "Gladiator", "Sighthound", "Wardog", "Spider", "Webknecht", "Direwolf", "Basilisk", "Legionary",
               "Auxiliary", "Footman", "Knight", "Billman", "Cutthroat", "Slinger", "Butcher", "Minstrel")


def parse(path: pathlib.Path):
    src = path.read_text(encoding="utf-8", errors="replace")
    rows = re.findall(r'<div class="row (\w+)">(.*?)</div>\s*</div>', src, re.S)
    out = []
    for cls, body in rows:
        text = html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body))).strip()
        out.append((cls, text))
    return out


def battles(rows):
    starts = [i for i, (_, t) in enumerate(rows) if "Next round issued: 1" in t]
    result = []
    for b in starts:
        onhide = max((i for i, (_, t) in enumerate(rows[:b]) if "WorldState::onHide" in t), default=b)
        end = next((i for i in range(b, len(rows)) if "World::onCombatFinished" in rows[i][1]), len(rows) - 1)
        seg = [t for _, t in rows[onhide:end + 1]]
        enemies = collections.Counter(m.group(1) for t in seg if "Spawned Entity" in t
                                      for m in [re.search(r'/([a-z_]+)"', t)] if m)
        ours = sorted(set(f"{m.group(1)}={m.group(2)}" for t in seg for m in [re.search(r"expert: (.+?) role = (\w+)", t)] if m))
        rounds = max([int(m.group(1)) for t in seg for m in [re.search(r"round issued: (\d+)", t)] if m] or [1])
        deaths = [re.sub(r".*SQ ", "", t) for t in seg if "has died" in t or "unconscious" in t]
        skills = collections.Counter(m.group(2) for t in seg for m in [re.search(r"SQ (.+?) uses skill (.+)$", t)]
                                     if m and not any(w in m.group(1) for w in ENEMY_WORDS))
        errors = [t for t in seg if "Script Error" in t or "critical exception" in t]
        result.append({"time": rows[b][1].split()[0], "rounds": rounds, "enemies": dict(enemies), "ours": ours,
                       "skills": skills.most_common(12), "deaths": deaths, "errors": errors, "lines": seg})
    return result


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = pathlib.Path(args[0]) if args else (DEFAULT_LOG if DEFAULT_LOG.exists() else ALT_LOG)
    rows = parse(path)
    if "--dump" in argv:
        i = argv.index("--dump")
        pathlib.Path(argv[i + 1]).write_text("\n".join(f"[{c}] {t}" for c, t in rows), encoding="utf-8")
    versions = sorted(set(t.split("loaded ")[1] for _, t in rows if re.search(r"(expert|pilot): loaded", t)))
    print(f"log: {path}  rows: {len(rows)}  mod versions: {versions}")
    errs = [t for c, t in rows if c in ("error", "critical")]
    print(f"errors: {len(errs)}")
    for e in errs[:10]:
        print("  !!", e[:220])
    fights = battles(rows)
    print(f"fights: {len(fights)}")
    for f in (fights[-1:] if "--last" in argv else fights):
        print(f"\n# {f['time']}  rounds={f['rounds']}  enemies={f['enemies']}")
        print("  ours:", ", ".join(f["ours"]))
        print("  our skills:", dict(f["skills"]))
        print("  outcomes:", "; ".join(f["deaths"])[:600])
        if f["errors"]:
            print("  ERRORS:", f["errors"])
        if "--last" in argv:
            print("  --- turn by turn ---")
            for t in f["lines"]:
                if NOISE.search(t) or "Spawned Entity" in t:
                    continue
                print("  ", t[:200])


if __name__ == "__main__":
    main(sys.argv[1:])
