extends RefCounted
## ── 언어 설정 ───────────────────────────────────────────
## 언어판마다 이 한 줄만 바꿔서 내보내요: "ko" / "en" / "ja" / "zh_CN"(간체) / "zh_TW"(번체)
const LANG := "ja"
## 세이브 파일은 언어별로 따로 (같은 주소에서 돌려도 섞이지 않게)
const SAVE_FILE := "user://save.json" if LANG == "ko" else "user://save_" + LANG + ".json"

## 언어별 번역표 (한국어 원문 → 번역). 한국어는 원문 그대로라 표가 필요 없음
const TABLES := {
	"en": "res://i18n/en.gd",
	"ja": "res://i18n/ja.gd",
	"zh_CN": "res://i18n/zh_CN.gd",
	"zh_TW": "res://i18n/zh_TW.gd",
}

## 언어별 글꼴 (없으면 기본 글꼴 res://assets/fonts/main.ttf)
const FONTS := {
	"ja": "res://assets/fonts/ja.ttf",
	"zh_CN": "res://assets/fonts/zh_CN.ttf",
	"zh_TW": "res://assets/fonts/zh_TW.ttf",
}

## 언어별 글자 크기 배율 (일본어 글꼴은 글자가 커서 조금 줄임)
const FONT_SCALES := {
	"ja": 0.86,
}
