---
name: kb
description: WIM Knowledge Base 검색 - 사내 문서에서 정보를 검색합니다
triggers:
  - kb
  - 검색
  - 문서검색
  - knowledge
argument-hint: "<검색어>"
---

# KB (Knowledge Base) 검색

## Purpose

WIM 백오피스의 Knowledge Base에서 문서를 검색합니다. 로컬 파일, Google Drive, Notion 등에서 동기화된 문서들을 벡터 유사도 검색으로 찾습니다.

## When to Activate

- 사용자가 `/kb <검색어>` 형태로 검색을 요청할 때
- 사내 문서나 정책에 대한 질문이 있을 때
- "검색해줘", "찾아줘" 등의 요청과 함께 검색어가 제공될 때

## Workflow

1. 검색어 확인
2. AI 서비스 API 호출 (http://localhost:8000/api/v1/search)
3. 검색 결과 정리하여 표시

## API 호출

```bash
curl -s -X POST http://localhost:8000/api/v1/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "<검색어>",
    "limit": 5,
    "threshold": 0.3
  }'
```

## 실행 방법

검색어가 제공되면:

1. Bash 도구로 curl 명령 실행
2. 결과를 파싱하여 사용자에게 표시:
   - 문서 제목
   - 관련 내용 (청크)
   - 유사도 점수
   - 소스 타입 (LOCAL_FILE_SYSTEM, GOOGLE_DRIVE 등)

## 결과 표시 형식

```
## 검색 결과: "<검색어>"

### 1. [문서제목] (유사도: 0.85)
- 소스: LOCAL_FILE_SYSTEM
- 내용: 관련 텍스트 조각...

### 2. [문서제목] (유사도: 0.72)
- 소스: GOOGLE_DRIVE
- 내용: 관련 텍스트 조각...
```

## Examples

```
/kb 휴가 정책
/kb 급여 계산
/kb 출장비 정산
```

## Notes

- threshold 값은 0.3으로 설정 (더 많은 결과 포함)
- limit은 기본 5개, 필요시 조정 가능
- AI 서비스가 실행 중이어야 함 (localhost:8000)
