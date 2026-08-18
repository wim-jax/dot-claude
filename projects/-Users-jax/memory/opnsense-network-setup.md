---
name: opnsense-network-setup
description: 사무실 네트워크 OPNSense 방화벽/토폴로지/모니터링 스택 구성 상태 — 네트워크 상담·설정 시 참고
metadata: 
  node_type: memory
  type: project
  originSessionId: cd5f8f56-5015-4f74-82ae-be0e50c1d8cf
---

사무실 네트워크 인프라 (2026-07-30 기준). SSH: `root@192.168.0.1` (jax가 `ssh -M -S /tmp/opnsense.sock -fN root@192.168.0.1`로 마스터 터널 열어줌; root 셸은 csh라 원격 명령은 `ssh ... sh -s <<'EOF'`로 POSIX 강제).

## 하드웨어/OPNSense
- OPNSense 방화벽: **i7-6700 / 8스레드 / 63GB RAM / 164GB 디스크(2% 사용)**. 관측용으로 작정하고 맞춘 스펙. **의도=이 한 대로 방화벽+관측+컨테이너 다 굴리는 올인원**(그래서 Orin으로 오프로드 제안하면 "그럴거면 i7로 안만들었다"고 함 — 별도 박스 offload는 오답).
- WAN=**igc0**(공인 /27, 218.158.38.243), LAN=**igb0**(192.168.0.0/24). igb1~3 여분. NIC은 igc0=I225-V(2.5G)/igb0~3=I350 쿼드(1G), 다 Intel(netmap 지원).

## ❌ 폐기: Proxmox 마이그레이션 (2026-08-13 안 하기로 결정)
- **결정: OPNSense 네이티브 유지, 가상화 안 함.** 이유: Docker/장기지표 델타가 modest한데 방화벽 밑에 하이퍼바이저+패스스루취약성+SPOF를 영구히 지는 값으로 부족. "네이티브로 안 쓸 이유가 못 된다"는 판단(사용자 측 피드백과 claude 평가 일치). 베어메탈=안정.
- i7는 이미 네이티브 관측박스(netdata/ntopng/Zenarmor/Suricata/netwatch)로 잘 쓰는 중 — 포기하는 건 Grafana/Prometheus식 장기 시계열·알림 생태계뿐.
- **나중에 장기지표 필요하면**: OPNSense `os-telegraf`로 지표 외부 push → 별도 작은 리눅스 박스(또는 Orin arm64)에 Prometheus+Grafana. 방화벽 무손상. CBD는 x86 전용일 수 있어 확인 필요.
- 런북은 참고용으로 파킹: `OPN-Sense-Dashboard` `docs/plans/2026-08-03-proxmox-migration-runbook.md` (PR #3, 미머지 보류).

**netwatch 대시보드(현행)**: SPA+SNMP+트래픽차트+보안패널+Clients(MAC컬럼/정렬/검색)+게이트웨이 라벨 → **PR #2 머지 완료**(origin/master). 배포본 `/root/netwatch/netwatch.py`(658줄). ntopng 게이트웨이 호스트명 오탐("iPhone")→ip==BIND_HOST면 "OPNSense"로 강제.

<details><summary>(구) 예정: Proxmox 마이그레이션 — 폐기됨, 참고용</summary>
- **왜**: OPNSense=FreeBSD라 Docker 불가(리눅스 커널 없음). i7/63GB 올인원 의도 살리려면 방화벽 OS를 갈아엎지 말고 **하이퍼바이저化**가 정석. VyOS/OpenWrt(x86)도 Docker 되지만 OPNSense 방화벽/IDS 생태계 대비 다운그레이드라 기각.
- **계획(A안)**: i7에 **Proxmox VE** 설치 → ①**OPNSense=VM**(I350 쿼드 NIC **PCI 패스스루**, VT-d/IOMMU 필수) + ②**Docker=LXC/VM**. config.xml 백업→VM 복원으로 설정 이관. 롤백 위해 **베어메탈 디스크 안 밀고 별도 디스크에 Proxmox** 권장.
- **토요일 전 준비**: Proxmox ISO+USB / **BIOS VT-d 켜기** / OPNSense config.xml 백업 + 네이티브앱(netwatch·Suricata·Zenarmor·ntopng·netdata) 목록 / 다운타임 창 확정. 런북 초안은 claude가 사전 작성 예정.
- 반려한 대안: bhyve on OPNSense(재구축0이나 OPNSense가 bhyve 공식 GUI 미지원→업그레이드 관리부담, 지저분). Proxmox가 VM 스냅샷으로 방화벽 업그레이드도 더 안전해지는 이점.
- **다운타임 현실**: 같은 물리박스 in-place면 "짧은 컷오버" 불가 — 설치+VM+config복원+패스스루 검증 내내(수시간) 라우팅 down. 짧게/무중단은 ①스페어x86 빌드 후 케이블 스왑(A) ②재구축 중 임시 게이트웨이(C) ③새벽창 감수(B) 뿐. blast radius=개발망 유선만(경영망 AX23 무관). A/B/C·창시간·스페어 유무 **미결정**.
- **config 복원 주의**: NIC **PCI 패스스루**로 같은 카드 넘겨야 게스트가 igc0/igb0 동일 인식→config 매핑 1:1(virtio면 vtnet0로 깨짐). Proxmox 관리NIC 1개 패스스루 제외 필수. 별도 디스크 설치=롤백. **config.xml엔 방화벽설정만** — netwatch·ntopng·netdata·redis·net-snmp·Suricata룰·Zenarmor(ES데이터)는 수동 재설치.
</details>

## 인프라 주소 계획 (192.168.0.x, infra 밴드 .2–.10) — 2026-08-03 재넘버링
- **.1** OPNSense / **.2** AP / **.3 = CBS220-16T 코어 예약**(SG95 대체 예정, 아직 미설치라 .3 비어있음) / **.4 Switch5947A8·.5 Switch160058·.6 Switch162E5D = CBS220-8T 관리형 ×3**.
- **주소는 스위치에 static 직접 설정**(DHCP 예약 아님 — 예약 IP 맞교환하다 리스 꼬여서 static으로 전환). MAC↔현재IP: `84:5a:3e:59:47:a8`=.4, `30:01:af:16:00:58`=.5, `30:01:af:16:2e:5d`=.6.
- 관례: **코어(16T)를 제일 앞 .3**, 액세스 8T들 .4~.6 순차. 16T 물리 설치 시 .3 배정.
- ✅ **3대 SNMP 전부 정상**(2026-08-14). `.6`(2e:5d/Switch162E5D)도 살림 — netwatch /api/switches에 3대 up, stale 아님, FDB 49~50 하위기기. 과거 `.6`은 SNMP 데몬 hang(web OK/community무관 Timeout, 토글 저항)이라 **초기화/리부팅+Save로 복구**함(옆 .5=00:58도 초기화로 살아난 전례와 동일 패턴).
- ⚠️ **CBS220 교훈: 설정 후 반드시 💾Save(running→startup)** — 안 하면 재부팅 때 공장초기화됨(.5가 이 이유로 자가초기화돼 한참 삽질). 3대 다 Save 확인 필요.
- CBS220은 스마트 매니지드(SNMP v2c/v3 + LLDP 지원, UniFi 컨트롤러 아님). **OPNSense에 net-snmp 설치됨**(`/usr/local/bin/snmpwalk`)으로 폴링 예정. 스위치에서 SNMP community + LLDP 켜야 폴링 가능(2026-07-31 시점 아직 안 켬).
- 목적: netwatch 대시보드를 **멀티페이지 SPA(UniFi식)** 로 재구성 — Dashboard/Clients(ntopng)/Traffic(netdata)/Security(Suricata) 는 기존 소스로 즉시, **Ports/Topology 는 CBS220 SNMP(IF-MIB/FDB)+LLDP** 로. 진행 중.

## 토폴로지 (두 망, 공인 IP 다름)
- **개발망**: 외부망 → OPNSense(공인#1) → **IPtime BE5100M**(허브모드) + 유선. 여기가 flat /24, ~30 활성 기기.
- **경영망**: **TP-Link AX23**(공인#2, 자체 라우터/DHCP/DNS). OPNSense 밖이라 SSH로 안 보임.
- 개발팀=BE5100M만, 경영팀=둘 다 씀. **사무실 확장 시 스위치 사서 물리 분리 예정**(그때 CBS220-8T ×2 캐스케이드 등 논의함).
- 알려진 이슈: **IPtime BE5100M 주기적 데드락**(강한 AP라 capacity 아님 → 펌웨어/발열/초기불량, 5개월). AX23 펌웨어 업뎃함.

## DNS (했던 조치)
- OPNSense: dnsmasq=DHCP(+53053), **Unbound=리졸버(:53)**. DNSBL 비어있음(광고차단 미사용). **2026-07-31 jax가 Unbound DNS 껐다고 함**(DHCP는 유지, DNS는 상위 DNS 직배포 방향) — 실제 :53 서빙 주체/DNS 동작 검증은 미완(그때 DNS 테스트 명령 취소됨), 다음에 확인 필요.
- **Unbound Reporting(통계) 껐음** — config.xml `<stats>1→0`. logger.py가 1.5GB 먹고 duckdb 정리 때 **DNS 163초 스톨** 유발한 게 원인이었음. 백업: `/conf/config.xml.bak-unboundstats`.
- **AX23**: DHCP 옵션6으로 클라에 **구글 DNS 8.8.8.8/8.8.4.4 직접 배포**(자체 DNS 릴레이 우회 → "핑OK/DNS死" 해결). 한국망이라 CF(1.1.1.1)보다 구글이 ECS 지원해 CDN 라우팅 유리.

## 모니터링 스택 (on-box 네이티브, docker 아님 — FreeBSD라 docker 불가)
- ✅ **ntopng** 가동 http://192.168.0.1:3000 (기기별 트래픽)
- ✅ **netdata** 가동 http://192.168.0.1:19999 (netdata.conf `bind to` 직접 192.168.0.1로 고침; **영구화하려면 GUI Services→Netdata→Listen=192.168.0.1 저장 필요**, 안 하면 리부팅 시 127.0.0.1로 되돌아감)
- ✅ **Zenarmor(os-sensei 2.6.2)** 설치·가동 (2026-07-31). 설치법: `pkg install os-sunnyvalley`(벤더 repo) → `pkg install os-sensei`(원격 스크립트 파이프 불필요, OPNSense 플러그인 카탈로그). **배포=Passive Mode(Reporting Only) / 보호 iface=igb0(LAN) / zone=lan** — passive라 포워딩 경로 밖, 바운스 없음. **DB는 로컬 Elasticsearch 8.11.3**(config `<database><Type>ES</Type>`, dbpath `/usr/local/datastore/elasticsearch`, heap 3072MB, 보존 7일). ⚠️ 방화벽 zroot에 ES라 **디스크 감시 필요**; Orin 준비되면 Remote ES로 이관 논의됨.
- ✅ **Suricata IDS**(내장 8.0.4) enable (2026-07-31). **Capture mode=PCAP live mode(IDS-only, netmap 아님→바운스 없음) / iface=WAN(igc0) / homenet=192.168.0.0/24**. 룰셋 14개(ET open: malware/exploit/exploit_kit/attack_response/current_events/coinminer/mobile_malware/phishing/worm/shellcode/ja3 + abuse.ch feodo/sslblacklist/urlhaus) = rules.sqlite 8만 룰 로드, IDS-only(차단 없음). 노이즈 카테고리(scan/info/policy/icmp/games 등)는 의도적 제외.
  - **⚠️ SSH로 IDS 설정한 삽질 교훈**: IDS는 MVC 모델이지만 `$mdl->general` PHP 모델 set이 config.xml에 **안 써짐**(default값 생략). 우회로 config 객체에 `<general>` 직접 주입해도, **파생물(suricata.yaml·rule-updater.config)은 `configctl template reload OPNsense/IDS`로 재생성**해야 반영됨. 게다가 **옛 suricata 프로세스가 em0(default iface)에서 살아남아** `configctl ids stop`+`pkill -9 -f bin/suricata` 완전정리 후 `configctl ids start` 해야 igc0로 붙음. 룰 다운로드는 `configctl ids update`(=rule-updater.py는 `/usr/local/etc/suricata/rule-updater.config`의 enabled=1 섹션 읽음). **결론: IDS 룰셋 토글은 GUI가 훨씬 빠름**, SSH는 위 순서 다 밟아야 함.
- **netwatch** (자작 집계앱): `/root/netwatch/netwatch.py` — stdlib-only 파이썬, 소스 localhost 집계 + 규칙기반 서술분석. http://192.168.0.1:8888 (192.168.0.1:8888 바인딩, 4초 자동갱신). **netdata + ntopng 둘 다 연결됨**(ntopng는 `NTOPNG_TOKEN` 헤더인증, LAN top-talker는 ifname=igb0의 ifid 자동탐지→현재 ifid 5, 로컬 192.168.* 필터). ntopng REST 요령: 토큰은 `Authorization: Token <t>` **헤더만** 먹힘(쿼리파라미터 X), 인터페이스 ifid는 WAN igc0=1 / LAN igb0=5. **재부팅 자동시작 설치됨**: `/usr/local/etc/rc.syshook.d/start/99-netwatch`(LAN IP 대기 후 daemon 기동). ✅ **보안 패널 추가됨(2026-07-31)**: Suricata(`configctl ids query alerts`로 최근 alert, rules.sqlite 룰수, ps로 감시 iface) + Zenarmor(`pgrep -f zenarmor/.*eastpect`로 상태). subprocess로 온박스 로컬 명령 호출. sources pill에 suricata/zenarmor 추가. **레포 `WIM-Corporation/OPN-Sense-Dashboard`(private, master)에 커밋됨**(토큰 env 분리, `netwatch.env`는 gitignore).
- NIC: 온보드 **igc0=Intel I225-V(2.5GbE, 현재 WAN)**, PCIe 쿼드 **igb0~3=Intel I350(1GbE, LAN=igb0)**. 스위치가 다 1G 이하라 지금은 포트배치 성능 무관; 2.5G 스위치 들이면 그때 I225가 열쇠.
- Grafana 원하면 bhyve VM 안에서(방화벽 베이스와 격리). 방화벽에 앱 직접 얹는 건 지양(업그레이드 시 날아가고 데이터플레인 리스크). 단 netwatch는 읽기전용·의존성0이라 예외로 on-box 허용.

## OPNSense 함정
- **configd가 설정 모델을 메모리 캐시** → `/conf/config.xml` 직접 편집이 configd-렌더 서비스에 안 먹힘(netdata에서 겪음; config.cache 삭제·configd 재시작으로도 안 됨). GUI 저장이라야 모델 갱신됨. Unbound는 `configctl unbound restart`=`pluginctl -c unbound_start`가 디스크 직독이라 직접편집 먹혔음.
