---
name: harbor-registry-setup
description: "쿠버 클러스터 내 Harbor 레지스트리(harbor.wimcorp.dev) 접속·retention·GC·PVC 구성, Harbor/이미지 정리 상담 시 참고"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 17238d3b-00c3-4dfd-a867-606789770825
---

Harbor v2.11.0, 쿠버 클러스터(`kubernetes-admin@kubernetes`) `harbor` 네임스페이스. 외부 URL `https://harbor.wimcorp.dev`. [[vsphere-vsan-setup]]의 slave 노드 Longhorn 위에 올라감.

## 접속 (API)
- **robot admin** 계정 사용. 자격증명은 사용자 zsh 환경변수 `HARBOR_ROBOT_ADMIN_ID`/`HARBOR_ROBOT_ADMIN_PW`(값 출력 금지). 비대화식 셸엔 안 뜨니 `source ~/.zshrc` 먼저.
- ⚠️ curl 시 `-u "$ID:$PW"` **반드시 쿼트** — robot 토큰에 특수문자 있어 언쿼트 확장하면 401.
- harbor-core 시크릿의 `HARBOR_ADMIN_PASSWORD`는 부트스트랩값이라 **현재 admin 비번 아님**(GET 공개프로젝트만 되고 쓰기 401). robot admin을 써야 함.
- API 접근: `kubectl -n harbor port-forward svc/harbor-core 18080:80` → `http://127.0.0.1:18080/api/v2.0`. (harbor-core scale 0이면 API 죽음.)
- 레지스트리 v2 blob 검증: `/service/token?service=harbor-registry&scope=repository:<repo>:pull`로 Bearer 토큰 → `/v2/<repo>/manifests|blobs`.

## 정리 정책 (2026-08 적용)
- **모든 프로젝트에 tag retention = latestPushedK(최근 30개 유지)**, 매일 02:00 스케줄. (Harbor 규칙은 OR만 되어 "최대 N + N일 이내" 동시강제 불가 → keep-last-30 단일 규칙으로 상한 고정.)
- **시스템 GC 주간 스케줄**: Custom cron `0 0 3 * * 0`(매주 일 03:00), delete_untagged=off. retention이 매니페스트만 지우므로 GC 있어야 blob 실회수.
- retention은 삭제(delete)라 GC(delete_untagged=false)로도 회수됨.

## 대청소 내역 (2026-08-15)
- 프로젝트 21개 통삭제(ktx + airflow/billg/codemeter-*/fundus-*/kitech*/production-data-manufacturing/staging-kitech*/staging-data-manufacturing/staging-vtd/staging-wimmy/test/wecobot/wimmy 등). 남은 10개: ai-team, depot, plem, production-wdata, srt, staging-wdata, staging-wim-backoffice, util, w_data_processing_tool, wim-backoffice.
- GC로 12,827+ blob 회수.

## harbor-registry PVC 600Gi → 160Gi 이관 완료
- 이유: Longhorn은 thin이라 물리는 81GB뿐이나 PVC 크기가 **스케줄 예약**을 600GB×3replica로 잡아 새 볼륨 스케줄을 막음(노드당 여유 ~246GB뿐이었음).
- 방법: scale 0(다운타임) → 새 160Gi PVC → rsync 복사(81GB/47024파일 일치) → PV surgery로 PVC 이름 `harbor-registry` 유지(Helm 관리라 필수) → scale 1 → blob 53개 HEAD 200 검증 → 옛 볼륨 삭제.
- 결과: 노드 scheduled 1586→**986GB**(−600), over-provisioning 임시 200%→105% 원복. 노드당 신규 스케줄 여유 ~690GB.
- **소스 동기화 완료**: Harbor는 **ArgoCD 관리**(`argocd.argoproj.io/instance: harbor`, git `WIM-Corporation/argo-cd-manifest` path `charts/harbor`, values.yaml에서 helm 렌더). registry size를 `charts/harbor/values.yaml`에서 600Gi→160Gi로 고쳐 **PR #42 머지 완료** → ArgoCD desired=160Gi라 sync해도 재확장 안 됨. ArgoCD는 manual sync(automated 없음)라 자동 되돌림 위험 없었음.
- 수동 생성한 새 PVC에 원본 Helm/ArgoCD 라벨 + `recurring-job-group.longhorn.io/default=enabled`(Longhorn 기본 백업 job 그룹) 복원함. registry PVC는 volumeName 등으로 ArgoCD상 계속 OutOfSync로 보이나 무해(size 일치, 축소 불가).
- StorageClass longhorn: reclaimPolicy=Delete(단 옛 PV는 Retain이라 롤백 가능했음), allowVolumeExpansion=true(확장만, 축소 불가 → 축소는 새 PVC+rsync 이관뿐).

## 쿠버 스토리지 확장(예정)
- 신 스토리지 서비스(RustFS 등, S3호환) 올리면 남은 Longhorn 용량 대부분 할당 예정. 더 필요하면 slave Longhorn 디스크를 [[vsphere-vsan-setup]]의 확보된 vSAN 여유로 확장(vmdk→LVM(lv_longhorn)→Longhorn 자동인식). 노드 확장은 나중.
- slave containerd: 미사용 이미지 prune로 ~152GB 회수했음(slave-1 157→35G). 별도 파티션이라 Longhorn 용량과는 무관.
