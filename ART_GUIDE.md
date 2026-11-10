# 멍냥이 그림 가이드

그림은 전부 `tools/dogs.py`가 코드로 그림 (48×48 좌표계 → 4배로 그려서 384px로 줄임).
새 장수는 `DOGS`에 한 줄(dict)을 추가하고 `export_game()`으로 뽑으면 됨.

## 스타일
- **큰 면 플랫 로우폴리**: 큰 부위 6~7각, 음영은 밝음·중간·어두움 3단계만
- 자잘한 하이라이트 선, 동그란 광택, **볼터치 없음**
- 무기는 들지 않음
- 앉은 자세: 앞발은 몸통 밑에 쏙, 뒷다리는 엉덩이 양옆으로 살짝
- 꼬리 방향(`tail`: 1 / -1)은 장수마다 다르게

## 진영 색 (옷 · 모자 · 목걸이에 반드시 크게)
| 진영 | 색 |
|---|---|
| 촉 | 초록 |
| 위 | 파랑 |
| 오 | 빨강 |
| 스페셜 | 보라 |

## 성장 단계별 그림 (게임 4단계 → 그림 3개)
| 게임 단계 | 그림 (form) | 들어가는 것 |
|---|---|---|
| 새끼 / 초딩 | 0 새끼 | 진영 색 목걸이만 (모자·옷·수염 없음) |
| 청소년 | 1 청년 | 모자 + 목걸이 + 짧은 수염(콧수염만) |
| 어른 | 2 어른 | 모자 + 옷 + 긴 수염 |

눈 그림 5종: `open` 기본, `closed` 잘 때(∪), `half` 피곤할 때, `squint` 쓰다듬기(>.<), `line` 쓰다듬기(ㅡ.ㅡ)

## 강아지(무장) / 고양이(책사)
- 몸 틀은 둘 다 같음. 고양이는 짧고 통통한 세모 귀, 말려 올라간 마디 꼬리, 수염 2가닥씩
- 얼굴 배치: 작은 까만 점 눈(하이라이트 없음), 눈 위 눈썹, 작은 코, 코 밑 작은 입, 살구색 주둥이

## 규칙
- **가족은 같은 종**: 생김새가 비슷해야 함 (털색만 다르게). 예: 손씨 일가 = 시바견, 원소·원술 = 보르조이, 하후돈·하후연 = 복서
- 털이 어두운 장수는 `eye_col`로 눈을 밝은 색으로 (예: 여포 = 금색 눈)
- 속눈썹(`lash`) 있는 장수는 >.< 표정에서 속눈썹을 자동으로 뺌
- 미형 = 장모(`fluffy`) + 속눈썹 2개 (제갈량, 주유, 초선)

## 자주 쓰는 옵션 (DOGS 항목)
| 키 | 뜻 |
|---|---|
| `ears` | droop / long / up / cat / flop / fold / shepherd / semi / mixed |
| `puppy_ears` | 새끼 때만 다른 귀 (예: "flop" = 접힌 귀 → 조운, 강유, 장료, 능통) |
| `young` | 새끼·청년 때만 바꿀 값들 (예: 여몽 = 어릴 땐 멍한 얼굴, 어른이 되면 늠름) |
| `brow` | angry / gentle / sly / calm / brave / lively / elegant / sad / blank / old / arch / dots / smirk |
| `eye` | sharp / happy / dot / smug (없으면 동그란 눈) |
| `mouth` | cat(ω) / smirk / flat / frown / grin / tongue / smile / laugh (없으면 기본 세모) |
| `beard` | long / purple / mane / stache / short / thin / scruff / neat / goatee |
| `hat` | turban / topknot / cap / lunjin / band / feather / helmet / straw / plume / ribbon / mian / crown / flower |
| `pattern` | fore / patch / pug / siam / blaze / cowpatch |
| `fluffy` / `ruff` | 장모 볼털·가슴털 / 얼굴을 두른 갈기 (태사자) |
| `fat` | 통통한 몸 (허저, 노숙, 원술 등) |
