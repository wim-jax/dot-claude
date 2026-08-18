---
name: vsphere-vsan-setup
description: "사무실 vSphere/vCenter(192.168.1.45) 접속법과 vSAN 스토리지 회수 작업 내역, vSAN/쿠버 상담 시 참고"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 17238d3b-00c3-4dfd-a867-606789770825
---

vCenter(VCSA) `192.168.1.45`, VMware vCenter Server 8.0.3, **vSAN OSA**(ESA 아님), 호스트 3대(192.168.1.53/54/55), 단일 `vsanDatastore` 35.77TB.

## 접속
- SSH: `~/.ssh/conf.d/server-lab.conf`의 `Host vSphere`(대문자 S — Host 매칭 대소문자 구분). VCSA는 appliancesh(제한된 `api`/`pi` 셸)로 떨어짐. bash는 `shell` 명령이나 `pi com.vmware.shell`인데 mux 소켓+비대화식이 불안정. 반복 shell 진입 실패 시 VCSA root가 lockout(자동해제)되니 주의.
- **API 조사는 govc/pyvmomi가 정석**. 자격증명은 사용자가 세팅하는 env `VSPHERE_USER`/`VSPHERE_PASSWORD`(값 출력 금지). `administrator@vsphere.local`이 아니라 별도 SSO 관리자 계정. appliance `root`는 vCenter API 권한 없음.
- govc: `GOVC_URL=https://192.168.1.45 GOVC_INSECURE=true GOVC_USERNAME=$VSPHERE_USER GOVC_PASSWORD=$VSPHERE_PASSWORD`. govc는 vSAN 규칙 정책 생성/디스크 정책배정 불가 → pyvmomi+PBM 사용(py3.9면 `pyvmomi==8.0.1.0.2`, PBM 인증은 `SoapStubAdapter(requestContext={'vcSessionCookie': cookie})`).
- 쿠버 접근: 컨텍스트 `kubernetes-admin@kubernetes`(API 192.168.1.100). 노드=master.1/2/3(.100/.101/.102), slave-1/2/3(.110/.112/.113). ⚠️ kubeconfig 주의: 실제 config는 `~/.kube/config_wim.txt`, `KUBECONFIG=~/.kube/config:~/.kube/config_wim`. 빈 `~/.kube/config`가 `current-context: ""`로 병합 우선권을 먹어 kubectl이 localhost:8080 폴백하는 사고 있었음 → 실제 config를 `~/.kube/config`에 복사해 정상화함(빈 원본은 `config.empty.bak`).

## vSAN 용량 회수 (2026-08 완료)
- 시작 26.84TB 사용/9.4TB free → **최종 ~13.8TB 사용 / ~21.4TB free**.
- 원리: vSAN에서 thick=저장정책 OSR(proportionalCapacity)100%. OSR 낮추기=예약 반납(무중단·즉시). FTT0=미러 제거(리던던시 없음). 클러스터 **Unmap(TRIM) 꺼짐** → 게스트 삭제블록은 OSR로 안 빠짐(추가 회수하려면 Unmap+fstrim).
- 생성한 정책: `vSAN-RAID1-OSR10`(FTT1/OSR10), `vSAN-FTT0-OSR10`(FTT0/OSR10). 롤백용 thick=`Management Storage Policy - Regular`(RAID1/OSR100).
- **minio 2대**(.71/.72): thick→OSR10→FTT0, ~7.4TB. 둘 다 .54라 FTT0 전 minio.2를 .55로 vMotion. RustFS 전환·폐기 예정(비핵심)이라 FTT0 허용. 폐기 시 +~3TB.
- **vROps**(.46): FTT0, ~0.22TB(재수집 가능 데이터).
- **slave 3대(Longhorn)**: **FTT0 적용 완료, ~5.1TB 회수**(committed 각 ~3.3→1.7TB). Longhorn `default-replica-count=3`+3호스트 분산(slave.1@.54/.2@.55/.3@.53, replica 각 노드 48개씩)이라 vSAN 미러 불필요. 적용 시 Longhorn 48볼륨 전부 healthy 확인. ⚠️ 이제 slave는 vSAN 여분 없음 → ESXi 호스트 maintenance 시 해당 slave 잠깐 내려야(Longhorn 나머지 2노드로 버팀).
- **Harbor registry PVC 600→160Gi 이관** 등 쿠버 내부 정리는 [[harbor-registry-setup]] 참고.

## 원칙 / 현황
- **master 3대(etcd)는 FTT1 유지**(안 건드림). slave는 위처럼 FTT0로 전환함(Longhorn 3x가 커버). 증설템플릿 `kube.longhorn.base ver5`(off, 25GB)는 노드 클론용이라 보존.
- 목적: 쿠버 스토리지를 "늘리는" 것. 비쿠버(minio/vROps 등)에서 vSAN 회수 + slave FTT0로 vSAN 여유 21TB 확보 → 새 스토리지 서비스(RustFS 등) 올릴 때 slave Longhorn 디스크(vmdk 2048GB)를 이 여유로 확장 예정(vmdk→LVM lv_longhorn→Longhorn 자동인식). 노드 확장은 나중.
- FTT0는 앱 층 이중화(Longhorn 3x / MinIO EC)가 노드손실을 커버할 때만. 호스트 maintenance 시 FTT0 오브젝트 접근불가 운영비용 있음.
- 비쿠버 남은 회수후보: hojoon-1(.250, thick 1TB/실사용 327GB, 소유자 확인 필요). minio 폐기(+3TB).
- 서버 인프라 정본 문서는 [[server-infra-docs-location]] 참고.
