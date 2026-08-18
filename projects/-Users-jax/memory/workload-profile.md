---
name: workload-profile
description: jax의 평소 개발 작업 부하 프로파일 — 장비/메모리/성능 상담 시 참고
metadata: 
  node_type: memory
  type: user
  originSessionId: da20a09c-fa0e-4258-9bb9-e4fb602af3a9
---

jax는 폴리글랏 풀스택+인프라 개발자. 메모리 많이 먹는 조합을 동시에 켜놓고 쓰는 패턴이다.

**상시 가동 부하 (2026-06-22 기준, 32GB 머신 실측):**
- OrbStack + Docker 컨테이너 상시 3개 (postgres:15, pgvector:pg16, redis) ≈ 1.5GB+
- JetBrains IDE 동시 다수: WebStorm(~1.2GB) + IntelliJ(~0.6GB) + DataGrip(~0.2GB)
- VS Code 헬퍼 다수 (~1GB+)
- Whale 브라우저 탭 다수 (헬퍼 10개+)
- Claude Code 세션 동시 5개 (~1.8GB) — 워크트리 격리로 다중 세션 패턴
- Java 21(sdkman) + Node 22(nvm) + Python 런타임, Xcode/시뮬레이터, Ferdium

**프로젝트 영역:** 풀스택 FE/BE, 인프라(argo-cd/openvpn/home-infra), 데이터처리, MCP 서버, 임베디드(teach-pendant, thermal-camera), C++.

**메모리 실태:** 32GB에서도 이미 스왑 ~1.9GB 사용 + 압축메모리 ~3.6GB로 쥐어짜는 중. 32GB가 한계 근처.

**지급 장비(2026-06):** M5 Pro / RAM 24GB / SSD 1TB. RAM은 다운(32→24)이지만 칩 성능↑ + 빠른 NVMe 스왑으로 완충. 24GB 운영 가이드: ①JetBrains 동시 1개만 ②Claude 세션 2~3개로 ③안 쓰는 Docker 컨테이너 stop ④브라우저 탭 절제. 이 절제만 하면 24GB로 충분히 가동 가능.
