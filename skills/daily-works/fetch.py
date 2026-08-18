#!/usr/bin/env python3
"""
WIM-Backoffice dev-activity 에서 이제성(jax) 커밋을 긁어 날짜>레포별로 묶어 출력.
사용법:
  python3 fetch.py <FROM YYYY-MM-DD> <TO YYYY-MM-DD> [REFRESH_TOKEN]
  REFRESH_TOKEN 생략 시 환경변수 WIM_REFRESH_TOKEN 사용.
출력: 날짜별 / 레포별 커밋 제목 (경영팀 포맷 가공은 호출한 Claude가 수행).
"""
import sys, json, os, urllib.request, urllib.error, datetime
from collections import defaultdict

BASE = "https://backoffice-api.wimcorp.co.kr"
EID = "6c40d177-a63c-46a9-87e9-5005ec96b456"  # 이제성 (jax) employeeId
DOW = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
# WAF가 기본 Python-urllib UA를 403으로 막으므로 브라우저 UA를 반드시 붙인다.
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"


def _get(url, token):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}",
                                               "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def refresh(rt):
    body = json.dumps({"refreshToken": rt}).encode()
    req = urllib.request.Request(BASE + "/api/v1/auth/refresh", data=body,
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)["accessToken"]


def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    frm, to = sys.argv[1], sys.argv[2]
    rt = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("WIM_REFRESH_TOKEN")
    if not rt:
        print("ERROR: refresh token 필요 (인자 또는 WIM_REFRESH_TOKEN)"); sys.exit(1)

    at = refresh(rt)
    cal = _get(f"{BASE}/api/v1/admin/dev-activity/{EID}/calendar?from={frm}&to={to}", at)
    days = [d["date"] for d in cal if d.get("commitCount", 0) > 0]

    for date in days:
        det = _get(f"{BASE}/api/v1/admin/dev-activity/{EID}/days/{date}", at)
        dt = datetime.date.fromisoformat(date)
        print(f"===== {date} ({DOW[dt.weekday()]}) commits={det['commitCount']} "
              f"+{det['totalAdditions']}/-{det['totalDeletions']} =====")
        byrepo = defaultdict(list)
        for c in det["commits"]:
            repo = (c.get("repo") or "?").split("/")[-1]
            byrepo[repo].append(c["message"].splitlines()[0])
        for repo, msgs in byrepo.items():
            print(f"  [{repo}] ({len(msgs)})")
            for m in msgs:
                print(f"    - {m}")
        print()


if __name__ == "__main__":
    main()
