# ASCII 상영관

AI에게 붙여넣으면 원하는 장면을 글자(ASCII)로 그려 주는 프롬프트 모음.
받은 HTML을 붙여넣으면 사이트에서 바로 재생하고, 구글 로그인한 친구들은 상영작으로 올릴 수 있어요.

```
index.html           사이트 전체
config.js            Supabase 주소와 키 (직접 채우기)
supabase/schema.sql  저장소 설정 SQL
```

## 1. Supabase 만들기 (저장소)

1. https://supabase.com 가입 → **New project** (이름 자유, 지역은 Northeast Asia (Seoul)).
2. 왼쪽 **SQL Editor** → New query → `supabase/schema.sql` 내용을 전부 붙여넣고 **Run**.
3. 왼쪽 **Project Settings → API** 에서 `Project URL`과 `anon public` 키를 복사해 `config.js`에 넣기.

## 2. 구글 로그인 켜기

1. https://console.cloud.google.com → 새 프로젝트 만들기.
2. **API 및 서비스 → OAuth 동의 화면**: 외부(External) 선택, 앱 이름과 이메일만 채우고 저장.
   - 다 만든 뒤 **앱 게시(프로덕션으로 푸시)** 를 눌러야 아무 구글 계정이나 로그인할 수 있어요. 테스트 상태로 두면 등록한 테스트 사용자만 로그인돼요.
3. **사용자 인증 정보 → 사용자 인증 정보 만들기 → OAuth 클라이언트 ID** → 유형 "웹 애플리케이션".
   - 승인된 리디렉션 URI: Supabase의 **Authentication → Sign In / Providers → Google** 화면에 나오는 Callback URL
     (`https://<프로젝트>.supabase.co/auth/v1/callback`)
4. 만들어진 **클라이언트 ID / 보안 비밀번호**를 Supabase Google 화면에 넣고 **Enable** → Save.

## 3. GitHub Pages에 올리기

1. GitHub에서 새 저장소 만들기 (Public, 예: `ascii-theater`).
2. **Add file → Upload files** 로 이 폴더의 파일을 전부 올리고 Commit.
3. 저장소 **Settings → Pages** → Source: `Deploy from a branch`, Branch: `main` / `/(root)` → Save.
4. 1~2분 뒤 `https://<깃허브아이디>.github.io/ascii-theater/` 주소가 생겨요.

## 4. 로그인 주소 등록

Supabase **Authentication → URL Configuration**
- Site URL: `https://<깃허브아이디>.github.io/ascii-theater/`
- Redirect URLs에도 같은 주소 추가

## 5. 나를 관리자로 등록

사이트에서 구글 로그인을 한 번 한 뒤, Supabase SQL Editor에서 `schema.sql` 맨 아래 줄의 이메일을 바꿔 실행하세요.
관리자는 다른 사람의 상영작도 내릴 수 있어요.

## 참고

- `anon` 키는 공개돼도 괜찮아요. 누가 무엇을 할 수 있는지는 SQL의 접근 규칙이 지켜요. `service_role` 키는 절대 올리지 마세요.
- 친구들이 올린 코드는 사이트와 분리된 칸(sandbox iframe) 안에서만 돌아서 로그인 정보에 접근할 수 없어요.
- 한 사람당 하루 20편, 한 편에 23만 자까지 올릴 수 있어요. `schema.sql`에서 바꿀 수 있어요.
