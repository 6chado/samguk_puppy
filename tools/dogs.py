"""장수 강아지 공통 그리기 (관우 몸 틀 기준) — 플랫 로우폴리, 새끼/청년/어른.
사용: python3 dogs.py <출력폴더> <폰트.ttf>
"""
import math
import sys

from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1]
FONT = sys.argv[2]

BLACK = (32, 24, 24)
# 진영 색: 옷(또는 모자·목걸이)에 반드시 크게 들어가야 함
SHU = dict(main=(52, 148, 84), dark=(30, 100, 58), deep=(32, 92, 60))      # 촉 = 초록
WEI = dict(main=(52, 86, 172), dark=(34, 56, 122), deep=(30, 48, 104))     # 위 = 파랑
WU = dict(main=(200, 52, 52), dark=(148, 34, 38), deep=(130, 30, 34))      # 오 = 빨강
SP = dict(main=(132, 82, 176), dark=(92, 54, 132), deep=(76, 44, 112))     # 스페셜 = 보라
FLAT = 254  # 알파값 254 = 면 나누지 않고 단색으로 (오목한 수염 같은 모양용)


def flat(col):
    return (*col[:3], FLAT)


# ─────────────────────────── 장수 데이터 ───────────────────────────
DOGS = {
    "관우": dict(
        breed="붉은 갈색 장모견",
        fur=(204, 92, 62), fur_d=(160, 62, 42), ear=(140, 52, 38), ear_in=None,
        muzzle=(247, 216, 186), belly=(247, 216, 186), mask=None,
        ears="droop", tail=-1,
        brow="angry", brow_col=BLACK,
        hat="turban", hat_col=(46, 150, 92), hat_d=(30, 104, 64), orn=(240, 196, 84),
        robe=(46, 150, 92), belt=(240, 196, 84), faction=SHU,
        beard="long", beard_col=(38, 30, 32),
    ),
    "유비": dict(
        breed="골든 리트리버",   # 유비 = 귀가 커서 어깨까지 닿았다는 이야기
        fur=(234, 190, 118), fur_d=(198, 150, 84), ear=(196, 140, 74), ear_in=None,
        muzzle=(252, 238, 214), belly=(252, 238, 214), mask=None,
        ears="long", tail=1,
        brow="gentle", brow_col=(110, 72, 40),
        hat="topknot", hat_col=SHU["main"], hat_d=SHU["dark"], orn=(240, 196, 84),
        robe=(84, 168, 96), belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SHU,
        beard=None, beard_col=None,
    ),
    "조조": dict(
        breed="회색 허스키",
        fur=(112, 116, 130), fur_d=(84, 88, 102), ear=(92, 96, 110), ear_in=(214, 214, 222),
        muzzle=(242, 242, 246), belly=(242, 242, 246), mask=(242, 242, 246),
        ears="up", tail=-1,
        brow="sly", brow_col=BLACK,
        hat="cap", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(206, 212, 222),
        robe=WEI["main"], belt=(206, 212, 222), faction=WEI,
        beard="goatee", beard_col=(38, 30, 32),
    ),
    "손권": dict(
        breed="시바견",
        fur=(230, 140, 64), fur_d=(194, 104, 42), ear=(206, 116, 48), ear_in=(250, 236, 216),
        muzzle=(252, 244, 232), belly=(252, 244, 232), mask="shiba",
        ears="up", tail=1,
        brow="dots", brow_col=(252, 244, 232),   # 시바 특유의 하얀 눈썹 점
        hat="crown", hat_col=(240, 196, 84), hat_d=WU["main"], orn=WU["dark"],
        robe=WU["main"], belt=(240, 196, 84), faction=WU,
        beard="purple", beard_col=(104, 58, 138),  # 손권 = 자줏빛 수염(紫髯)
    ),
    # ── 책사 = 고양이 ──
    "제갈량": dict(
        breed="회색 장모 고양이",
        fur=(176, 180, 192), fur_d=(140, 144, 158), ear=(176, 180, 192), ear_in=(244, 184, 188),
        muzzle=(250, 250, 248), belly=(250, 250, 248), mask=None,
        ears="cat", tail=-1, tail_type="curl", whiskers=True, fluffy=True,
        brow="elegant", brow_w=0.6, brow_col=(60, 56, 70), lash=2,
        hat="lunjin", hat_col=SHU["deep"], hat_d=(22, 64, 42), orn=(236, 236, 226),
        robe=(62, 132, 88), belt=(22, 64, 42), robe_trim=(240, 238, 228), faction=SHU,
        beard=None, beard_col=None,
    ),
    # ═════════ 촉 (초록) ═════════
    "장비": dict(
        breed="티베탄 마스티프",
        fur=(124, 86, 62), fur_d=(94, 62, 44), ear=(84, 56, 40), ear_in=None,
        muzzle=(226, 190, 150), belly=(226, 190, 150), mask=None,
        ears="droop", tail=1,
        brow="angry", brow_w=1.3, brow_col=BLACK,
        hat="band", hat_col=SHU["deep"], hat_d=(22, 64, 42), orn=(240, 196, 84),
        robe=(40, 112, 70), belt=(240, 196, 84), faction=SHU,
        beard="mane", beard_col=(38, 30, 32),
    ),
    "조운": dict(
        breed="흰 진돗개",
        fur=(232, 234, 236), fur_d=(200, 204, 210), ear=(214, 216, 220), ear_in=(244, 190, 190),
        muzzle=(255, 250, 240), belly=(255, 250, 240), mask=None,
        puppy_ears="flop", ears="up", tail=-1,
        brow="brave", brow_w=1.15, brow_col=BLACK,
        hat="helmet", hat_col=(206, 214, 224), hat_d=SHU["main"], orn=SHU["dark"], plume=SHU["main"],
        robe=SHU["main"], belt=(206, 214, 224), robe_trim=(240, 240, 236), faction=SHU,
        beard=None, beard_col=None,
    ),
    "강유": dict(
        breed="셰퍼드",
        fur=(212, 158, 92), fur_d=(170, 118, 62), ear=(70, 54, 46), ear_in=(196, 140, 84),
        muzzle=(240, 214, 170), belly=(240, 214, 170), mask=None,
        puppy_ears="flop", ears="shepherd", tail=1, pattern="fore", pat_col=(70, 54, 46), saddle=(70, 54, 46),
        brow="lively", brow_col=BLACK,
        hat="helmet", hat_col=(38, 126, 84), hat_d=(240, 196, 84), orn=(240, 196, 84), knob=True,
        robe=(38, 126, 84), belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SHU,
        beard=None, beard_col=None,
    ),
    "마초": dict(
        breed="러프 콜리",
        fur=(176, 112, 62), fur_d=(136, 82, 44), ear=(120, 72, 40), ear_in=None,
        muzzle=(250, 246, 238), belly=(250, 246, 238), mask=None,
        ears="semi", tail=1, pattern="blaze",
        brow="brave", brow_w=1.1, brow_col=BLACK,
        hat="helmet", hat_col=(236, 196, 90), hat_d=SHU["main"], orn=(250, 250, 246), plume=(250, 250, 246),
        robe=SHU["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SHU,
        beard="goatee", beard_col=(70, 44, 30),
    ),
    "방통": dict(
        breed="갈색 얼룩 고양이",
        fur=(160, 122, 86), fur_d=(124, 90, 60), ear=(160, 122, 86), ear_in=(232, 170, 160),
        muzzle=(240, 226, 204), belly=(240, 226, 204), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(112, 80, 54),
        brow="gentle", brow_col=(70, 50, 40),
        hat="straw", hat_col=(226, 196, 128), hat_d=SHU["main"], orn=SHU["dark"],
        robe=(70, 128, 82), belt=(60, 48, 40), faction=SHU,
        beard="scruff", beard_col=(70, 50, 40),
    ),
    "법정": dict(
        breed="러시안 블루",
        fur=(108, 118, 140), fur_d=(80, 88, 110), ear=(108, 118, 140), ear_in=(226, 170, 176),
        muzzle=(228, 232, 240), belly=(228, 232, 240), mask=None,
        ears="cat", tail=-1, tail_type="curl", whiskers=True,
        brow="smirk", brow_col=BLACK, mouth="cat", eye="smug",
        hat="cap", hat_col=SHU["main"], hat_d=SHU["dark"], orn=(240, 196, 84),
        robe=(40, 128, 78), belt=(240, 196, 84), robe_trim=(236, 236, 226), faction=SHU,
        beard=None, beard_col=None,
    ),
    # ═════════ 오 (빨강) ═════════
    "주유": dict(
        breed="흰 장모 고양이",
        fur=(246, 244, 238), fur_d=(214, 210, 206), ear=(246, 244, 238), ear_in=(246, 186, 190),
        muzzle=(255, 244, 236), belly=(255, 244, 236), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True,
        brow="elegant", brow_w=0.6, brow_col=(60, 50, 56), lash=2, fluffy=True,
        hat="plume", hat_col=(240, 196, 84), hat_d=WU["main"], orn=WU["dark"], plume=(176, 70, 50),
        robe=WU["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WU,
        beard=None, beard_col=None,
    ),
    "육손": dict(
        breed="크림 치즈 고양이",
        fur=(240, 206, 146), fur_d=(206, 166, 104), ear=(240, 206, 146), ear_in=(244, 186, 180),
        muzzle=(253, 244, 226), belly=(253, 244, 226), mask=None,
        ears="cat", tail=-1, tail_type="curl", whiskers=True, stripes=(214, 170, 104),
        brow="calm", brow_col=(110, 76, 44), lash=1,
        hat="cap", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(214, 78, 70), belt=WU["dark"], robe_trim=(250, 240, 226), faction=WU,
        beard=None, beard_col=None,
    ),
    "손상향": dict(
        breed="주황 시바견",
        fur=(240, 152, 74), fur_d=(204, 114, 48), ear=(214, 124, 52), ear_in=(252, 238, 220),
        muzzle=(253, 246, 236), belly=(253, 246, 236), mask="shiba",
        ears="up", tail=-1,
        brow="dots", brow_col=(253, 246, 236), lash=2,
        hat="ribbon", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(214, 60, 72), belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WU,
        beard=None, beard_col=None,
    ),
    "감녕": dict(
        breed="얼룩 스트릿독",
        fur=(234, 218, 188), fur_d=(198, 178, 144), ear=(150, 100, 62), ear_r=(198, 178, 144), ear_in=(240, 200, 180),
        muzzle=(255, 250, 240), belly=(255, 250, 240), mask=None,
        ears="mixed", tail=1, pattern="patch", pat_col=(150, 100, 62),
        brow="arch", brow_col=BLACK, mouth="tongue", bells=True,
        hat="feather", hat_col=WU["main"], hat_d=(240, 196, 84), orn=(250, 250, 244),
        robe=WU["main"], belt=(240, 196, 84), faction=WU,
        beard=None, beard_col=None,
    ),
    "손견": dict(
        breed="적갈색 시바견",
        fur=(188, 102, 50), fur_d=(150, 74, 32), ear=(156, 80, 36), ear_in=(240, 216, 190),
        muzzle=(246, 232, 212), belly=(246, 232, 212), mask="shiba",
        ears="up", tail=1,
        brow="brave", brow_w=1.25, brow_col=BLACK,
        hat="turban", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(170, 40, 44), belt=(240, 196, 84), faction=WU,
        beard="short", beard_col=(52, 36, 32),
    ),
    "손책": dict(
        breed="크림 시바견",
        fur=(246, 190, 110), fur_d=(212, 150, 74), ear=(222, 160, 82), ear_in=(255, 244, 226),
        muzzle=(255, 250, 240), belly=(255, 250, 240), mask="shiba",
        ears="up", tail=-1,
        brow="lively", brow_col=BLACK, mouth="grin",
        hat="band", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84), band_tails=True,
        robe=WU["main"], belt=(240, 196, 84), robe_trim=(252, 244, 232), faction=WU,
        beard=None, beard_col=None,
    ),
    # ═════════ 위 (파랑) ═════════
    "하후돈": dict(
        breed="복서",
        fur=(206, 150, 96), fur_d=(166, 112, 64), ear=(150, 98, 56), ear_in=None,
        muzzle=(244, 224, 196), belly=(244, 224, 196), mask=None,
        ears="flop", tail=1, eyepatch=True,
        brow="angry", brow_w=1.2, brow_col=BLACK,
        hat="band", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(240, 196, 84),
        robe=WEI["main"], belt=(240, 196, 84), faction=WEI,
        beard="short", young_beard="tidy", beard_col=(52, 36, 32),
    ),
    "장료": dict(
        breed="도베르만",
        fur=(92, 88, 104), fur_d=(66, 62, 78), ear=(66, 62, 78), ear_in=(206, 150, 96),
        muzzle=(226, 178, 122), belly=(226, 178, 122), mask=None,
        puppy_ears="flop", ears="shepherd", tail=-1,
        brow="brave", brow_w=1.2, brow_col=(226, 178, 122),
        hat="helmet", hat_col=WEI["main"], hat_d=(206, 212, 222), orn=(206, 212, 222), plume=(240, 240, 244),
        robe=WEI["main"], belt=(206, 212, 222), robe_trim=(206, 212, 222), faction=WEI,
        beard="stache", beard_col=(38, 30, 32),
    ),
    "허저": dict(
        breed="퍼그",
        fur=(232, 200, 150), fur_d=(196, 160, 110), ear=(84, 68, 62), ear_in=None,
        muzzle=(214, 194, 176), belly=(250, 236, 212), mask=None,
        ears="flop", tail=1, pattern="pug", pat_col=(104, 84, 74), fat=1.28,
        brow="arch", brow_col=BLACK, mouth="tongue",
        hat="band", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(240, 196, 84),
        robe=WEI["main"], belt=(240, 196, 84), faction=WEI,
        beard=None, beard_col=None,
    ),
    "하후연": dict(
        breed="회색 복서",   # 하후돈과 같은 복서 형제, 털만 회색빛
        fur=(170, 166, 164), fur_d=(134, 128, 128), ear=(112, 106, 106), ear_in=None,
        muzzle=(242, 238, 232), belly=(242, 238, 232), mask=None,
        ears="flop", tail=-1,
        brow="lively", brow_col=BLACK,
        hat="feather", hat_col=WEI["main"], hat_d=(240, 196, 84), orn=(250, 250, 244),
        robe=(64, 104, 190), belt=(240, 196, 84), faction=WEI,
        beard="short", young_beard="tidy", beard_col=(60, 56, 64),
    ),
    "전위": dict(
        breed="불마스티프",
        fur=(160, 110, 76), fur_d=(122, 80, 52), ear=(96, 64, 46), ear_in=None,
        muzzle=(234, 202, 166), belly=(234, 202, 166), mask=None,
        ears="flop", tail=1, fat=1.16,
        brow="angry", brow_w=1.4, brow_col=BLACK,
        hat="band", hat_col=WEI["deep"], hat_d=WEI["dark"], orn=(206, 212, 222),
        robe=(40, 64, 140), belt=(206, 212, 222), faction=WEI,
        beard=None, beard_col=None,
    ),
    "우금": dict(
        breed="슈나우저",
        fur=(146, 148, 158), fur_d=(112, 114, 126), ear=(112, 114, 126), ear_in=None,
        muzzle=(238, 238, 242), belly=(238, 238, 242), mask=None,
        ears="semi", tail=-1,
        brow="brave", brow_w=1.7, brow_col=(240, 240, 244),
        hat="helmet", hat_col=(206, 212, 222), hat_d=WEI["main"], orn=WEI["dark"], knob=True,
        robe=WEI["main"], belt=(206, 212, 222), robe_trim=(236, 236, 240), faction=WEI,
        beard="short", young_beard="tidy", side_tufts=True, beard_col=(238, 238, 242),
    ),
    "조비": dict(
        breed="푸른빛 허스키",
        fur=(96, 108, 140), fur_d=(70, 80, 110), ear=(76, 86, 116), ear_in=(214, 214, 222),
        muzzle=(242, 242, 246), belly=(242, 242, 246), mask=(242, 242, 246),
        ears="up", tail=1,
        brow="sly", brow_w=0.8, brow_col=BLACK,
        hat="mian", hat_col=WEI["main"], hat_d=(34, 36, 52), orn=(240, 196, 84),
        robe=WEI["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WEI,
        beard="thin", beard_col=(38, 30, 32),
    ),
    "가후": dict(
        breed="턱시도 고양이",
        fur=(86, 86, 100), fur_d=(62, 62, 76), ear=(86, 86, 100), ear_in=(226, 170, 176),
        muzzle=(244, 244, 246), belly=(244, 244, 246), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True,
        brow="sly", brow_col=BLACK,
        hat="cap", hat_col=WEI["deep"], hat_d=(22, 34, 80), orn=(240, 196, 84),
        robe=(40, 64, 140), belt=(240, 196, 84), robe_trim=(236, 236, 240), faction=WEI,
        beard="goatee", beard_col=(30, 26, 32),
    ),
    "순욱": dict(
        breed="은빛 장모 고양이",
        fur=(200, 208, 224), fur_d=(164, 172, 194), ear=(200, 208, 224), ear_in=(246, 186, 190),
        muzzle=(250, 250, 252), belly=(250, 250, 252), mask=None,
        ears="cat", tail=-1, tail_type="curl", whiskers=True, fluffy=True,
        brow="elegant", brow_w=0.6, brow_col=(70, 70, 90), lash=1,
        hat="cap", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(240, 196, 84),
        robe=WEI["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WEI,
        beard=None, beard_col=None,
    ),
    "곽가": dict(
        breed="샴 고양이",
        fur=(240, 226, 200), fur_d=(206, 188, 160), ear=(104, 80, 70), ear_in=(150, 116, 104),
        muzzle=(128, 100, 88), belly=(252, 246, 234), mask=None,
        ears="cat", tail=1, tail_type="curl", tail_col=(104, 80, 70), whiskers=True,
        pattern="siam", pat_col=(104, 80, 70),
        brow="smirk", brow_col=BLACK, mouth="cat", eye="smug",
        hat="lunjin", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(240, 240, 244),
        robe=(72, 110, 196), belt=WEI["dark"], robe_trim=(240, 240, 244), faction=WEI,
        beard=None, beard_col=None,
    ),
    "순유": dict(
        breed="스코티시 폴드",
        fur=(204, 176, 144), fur_d=(168, 138, 104), ear=(168, 138, 104), ear_in=None,
        muzzle=(248, 238, 222), belly=(248, 238, 222), mask=None,
        ears="fold", tail=1, tail_type="curl", whiskers=True, stripes=(160, 128, 94),
        brow="sad", brow_col=(90, 64, 44),
        hat="cap", hat_col=WEI["main"], hat_d=WEI["dark"], orn=(240, 196, 84),
        robe=WEI["main"], belt=(240, 196, 84), robe_trim=(240, 240, 244), faction=WEI,
        beard="thin", beard_col=(70, 50, 40),
    ),
    "제갈근": dict(
        breed="회색 장모 고양이",   # 제갈량의 형: 같은 털, 미형 대신 순한 얼굴
        fur=(176, 180, 192), fur_d=(140, 144, 158), ear=(176, 180, 192), ear_in=(244, 184, 188),
        muzzle=(250, 250, 248), belly=(250, 250, 248), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True, fluffy=True,
        brow="gentle", brow_col=(90, 84, 96), mouth="cat",
        hat="cap", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(200, 64, 62), belt=(240, 196, 84), robe_trim=(250, 240, 226), faction=WU,
        beard="neat", beard_col=(84, 80, 92),
    ),
    # ═════════ 스페셜 (보라) ═════════
    "여포": dict(
        breed="카네코르소",   # 천하무쌍: 검고 다부진 맹견 + 긴 꿩깃 관
        fur=(70, 66, 74), fur_d=(50, 46, 54), ear=(50, 46, 54), ear_in=(150, 110, 110),
        muzzle=(120, 112, 120), belly=(110, 102, 110), mask=None,
        ears="up", tail=-1, fat=1.08,
        brow="angry", brow_w=1.4, brow_col=(240, 200, 90), eye="sharp", eye_col=(240, 200, 90), mouth="smirk",
        hat="plume", hat_col=(240, 196, 84), hat_d=SP["main"], orn=(210, 52, 52), plume=(170, 40, 46),
        robe=SP["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SP,
        beard=None, beard_col=None,
    ),
    "진궁": dict(
        breed="초콜릿 고양이",   # 여포 곁의 깐깐한 책사
        fur=(132, 92, 72), fur_d=(104, 70, 54), ear=(132, 92, 72), ear_in=(220, 160, 150),
        muzzle=(236, 214, 196), belly=(236, 214, 196), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True,
        brow="brave", brow_w=0.9, brow_col=(50, 34, 28),
        hat="lunjin", hat_col=SP["deep"], hat_d=(56, 32, 84), orn=(236, 236, 226),
        robe=(110, 70, 150), belt=(56, 32, 84), robe_trim=(236, 236, 226), faction=SP,
        beard="thin", beard_col=(60, 40, 32),
    ),
    "원소": dict(
        breed="크림 보르조이",   # 4대 삼공 명문가: 귀티 + 거만한 반쯤 감은 눈
        fur=(236, 218, 176), fur_d=(204, 184, 140), ear=(214, 190, 140), ear_in=None,
        muzzle=(252, 246, 234), belly=(252, 246, 234), mask=None,
        ears="semi", tail=-1,
        brow="elegant", brow_w=0.9, brow_col=(110, 84, 50), eye="smug", mouth="flat",
        hat="helmet", hat_col=(236, 196, 90), hat_d=SP["main"], orn=SP["dark"], plume=SP["main"],
        robe=SP["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SP,
        beard="short", young_beard="tidy", beard_col=(110, 84, 50),
    ),
    "원술": dict(
        breed="황금 보르조이",   # 원소의 동생 = 같은 종. 황제가 되고 싶은 통통한 욕심쟁이
        fur=(240, 206, 140), fur_d=(208, 170, 104), ear=(214, 176, 108), ear_in=None,
        muzzle=(252, 244, 228), belly=(252, 244, 228), mask=None,
        ears="semi", tail=1, fat=1.16,
        brow="arch", brow_col=(110, 80, 44), eye="smug", mouth="smirk",
        hat="mian", hat_col=SP["main"], hat_d=(44, 30, 64), orn=(240, 196, 84),
        robe=(150, 92, 190), belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SP,
        beard="thin", beard_col=(110, 80, 44),
    ),
    "공손찬": dict(
        breed="사모예드",   # 백마장군: 새하얀 털
        fur=(248, 248, 250), fur_d=(218, 220, 228), ear=(232, 234, 240), ear_in=(240, 200, 200),
        muzzle=(255, 255, 255), belly=(255, 255, 255), mask=None,
        ears="up", tail=1, fluffy=True,
        brow="brave", brow_w=1.15, brow_col=BLACK, mouth="grin",
        hat="helmet", hat_col=(236, 238, 244), hat_d=SP["main"], orn=SP["dark"], plume=(250, 250, 252),
        robe=SP["main"], belt=(236, 238, 244), robe_trim=(250, 250, 252), faction=SP,
        beard="short", young_beard="tidy", beard_col=(150, 150, 160),
    ),
    "초선": dict(
        breed="장모 고양이",   # 경국지색: 복숭아빛 장모 + 속눈썹 둘 + 꽃 머리장식
        fur=(250, 232, 226), fur_d=(228, 200, 196), ear=(250, 232, 226), ear_in=(246, 176, 190),
        muzzle=(255, 248, 246), belly=(255, 248, 246), mask=None,
        ears="cat", tail=-1, tail_type="curl", whiskers=True, fluffy=True,
        brow="elegant", brow_w=0.55, brow_col=(110, 70, 90), lash=2, mouth="cat",
        hat="flower", hat_col=(246, 150, 186), hat_d=SP["main"], orn=(250, 214, 96),
        robe=(176, 96, 184), belt=(250, 214, 96), robe_trim=(250, 228, 238), faction=SP,
        beard=None, beard_col=None,
    ),
    # ═════════ 4차 추가 ═════════
    "사마의": dict(
        breed="아비시니안 고양이",
        fur=(178, 112, 70), fur_d=(140, 82, 48), ear=(160, 96, 58), ear_in=(236, 170, 150),
        muzzle=(240, 222, 198), belly=(240, 222, 198), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(122, 70, 40),
        brow="sly", brow_w=0.8, brow_col=BLACK, eye="sharp",
        hat="lunjin", hat_col=WEI["deep"], hat_d=(22, 34, 80), orn=(206, 212, 222),
        robe=(40, 64, 140), belt=(206, 212, 222), robe_trim=(206, 212, 222), faction=WEI,
        beard="thin", beard_col=(40, 30, 30),
    ),
    "태사자": dict(
        breed="차우차우",
        fur=(198, 112, 58), fur_d=(160, 82, 40), ear=(160, 82, 40), ear_in=(240, 200, 170),
        muzzle=(240, 200, 150), belly=(236, 170, 110), mask=None,
        ears="up", tail=1, fluffy=True, ruff=True,
        brow="brave", brow_w=1.35, brow_col=BLACK,
        hat="helmet", hat_col=WU["main"], hat_d=(240, 196, 84), orn=(240, 196, 84), plume=(250, 250, 244),
        robe=WU["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WU,
        beard="short", young_beard="tidy", beard_col=(70, 40, 26),
    ),
    "능통": dict(
        breed="웰시코기",
        fur=(232, 150, 76), fur_d=(196, 112, 48), ear=(214, 128, 58), ear_in=(252, 230, 210),
        muzzle=(255, 250, 242), belly=(255, 250, 242), mask=None,
        puppy_ears="flop", ears="shepherd", tail=-1, pattern="blaze",
        brow="lively", brow_col=BLACK, mouth="grin",
        hat="feather", hat_col=WU["main"], hat_d=(240, 196, 84), orn=(250, 250, 244),
        robe=(214, 60, 60), belt=(240, 196, 84), faction=WU,
        beard=None, beard_col=None,
    ),
    "노숙": dict(
        breed="통통한 치즈 태비",
        fur=(236, 166, 88), fur_d=(200, 128, 58), ear=(236, 166, 88), ear_in=(246, 190, 176),
        muzzle=(254, 242, 222), belly=(254, 242, 222), mask=None,
        ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(196, 118, 52), fat=1.16,
        brow="gentle", brow_col=(120, 70, 36), eye="happy", mouth="cat",
        hat="cap", hat_col=WU["main"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(196, 56, 56), belt=(240, 196, 84), robe_trim=(250, 240, 226), faction=WU,
        beard="thin", beard_col=(110, 66, 36),
    ),
    "여몽": dict(
        breed="비글",
        fur=(214, 150, 84), fur_d=(176, 114, 56), ear=(150, 92, 48), ear_in=None,
        muzzle=(255, 250, 242), belly=(255, 250, 242), mask=None,
        ears="droop", tail=1, pattern="blaze", saddle=(60, 48, 44),
        brow="brave", brow_w=1.2, brow_col=BLACK,
        # 새끼·청년: 해맑은 바보 얼굴 → 어른이 되면 용맹·똑똑 (괄목상대)
        young=dict(brow="blank", brow_w=0.7, eye="dot", mouth="tongue", beard=None),
        hat="helmet", hat_col=WU["main"], hat_d=(240, 196, 84), orn=(240, 196, 84), knob=True,
        robe=WU["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=WU,
        beard="stache", beard_col=(50, 36, 30),
    ),
    "황개": dict(
        breed="늙은 누렁이",
        fur=(208, 166, 98), fur_d=(172, 130, 70), ear=(166, 122, 64), ear_in=None,
        muzzle=(240, 236, 226), belly=(244, 232, 210), mask=None,
        ears="semi", tail=-1,
        brow="angry", brow_w=1.5, brow_col=(246, 246, 242),
        hat="band", hat_col=WU["deep"], hat_d=WU["dark"], orn=(240, 196, 84),
        robe=(170, 40, 44), belt=(240, 196, 84), faction=WU,
        beard="mane", beard_col=(240, 240, 236), mane_in=(214, 214, 208),
    ),
    "유선": dict(
        breed="골든 리트리버",
        fur=(240, 206, 140), fur_d=(206, 166, 102), ear=(206, 156, 90), ear_in=None,
        muzzle=(254, 242, 222), belly=(254, 242, 222), mask=None,
        ears="long", tail=-1,
        brow="gentle", brow_col=(120, 82, 46), eye="smug", mouth="cat",
        hat="mian", hat_col=SHU["main"], hat_d=(30, 60, 44), orn=(240, 196, 84),
        robe=(84, 168, 96), belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SHU,
        beard=None, beard_col=None,
    ),
    "서서": dict(
        breed="젖소 고양이",
        fur=(250, 248, 244), fur_d=(214, 212, 208), ear=(46, 42, 48), ear_in=(220, 160, 168),
        muzzle=(255, 252, 248), belly=(255, 252, 248), mask=None,
        ears="cat", tail=-1, tail_type="curl", tail_col=(46, 42, 48), whiskers=True,
        pattern="cowpatch", pat_col=(46, 42, 48),
        brow="sad", brow_col=(60, 54, 60), mouth="frown",
        hat="band", hat_col=SHU["main"], hat_d=SHU["dark"], orn=(240, 196, 84), band_tails=True,
        robe=(52, 136, 84), belt=(70, 56, 46), robe_trim=(236, 236, 226), faction=SHU,
        beard=None, beard_col=None,
    ),
    "황충": dict(
        breed="바셋 하운드",
        fur=(196, 132, 80), fur_d=(158, 100, 56), ear=(132, 82, 46), ear_in=None,
        muzzle=(242, 238, 230), belly=(250, 246, 238), mask=None,
        ears="long", tail=1, pattern="blaze",
        brow="angry", brow_w=1.6, brow_col=(246, 246, 242),
        hat="helmet", hat_col=(236, 196, 90), hat_d=SHU["main"], orn=SHU["dark"], knob=True,
        robe=SHU["main"], belt=(240, 196, 84), robe_trim=(240, 196, 84), faction=SHU,
        beard="long", beard_col=(242, 242, 238),
    ),
    "위연": dict(
        breed="아프간 하운드",
        fur=(150, 112, 80), fur_d=(116, 82, 56), ear=(64, 48, 44), ear_in=None,
        muzzle=(222, 190, 154), belly=(196, 160, 122), mask=None,
        ears="long", tail=1, fluffy=True,
        brow="angry", brow_w=1.15, brow_col=(20, 14, 14), eye="sharp", mouth="smirk",
        hat="band", hat_col=SHU["deep"], hat_d=(22, 64, 42), orn=(206, 212, 222),
        robe=(36, 104, 64), belt=(206, 212, 222), faction=SHU,
        beard="goatee", beard_col=(24, 18, 18),
    ),
}


# ─────────────────────────── 면 나누기 ───────────────────────────
class FacetDraw:
    LIGHT = math.atan2(-1.0, -0.8)

    def __init__(self, img, s):
        self.d = ImageDraw.Draw(img)
        self.s = s

    @staticmethod
    def _tone(col, k):
        return tuple(int(max(0, min(255, c * k))) for c in col[:3])

    def _shade(self, angle):
        dot = math.cos(angle - self.LIGHT)
        if dot > 0.45:
            return 1.12
        if dot > -0.25:
            return 0.97
        return 0.82

    def _faceted(self, pts, fill, inset=0.5):
        pts = [tuple(p) for p in pts]
        if len(fill) == 4 and fill[3] == FLAT:
            self.d.polygon(pts, fill=fill[:3])
            return
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        w, h = max(xs) - min(xs), max(ys) - min(ys)
        if min(w, h) < 3.5 * self.s:
            self.d.polygon(pts, fill=fill[:3])
            return
        cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
        fx, fy = cx - w * 0.06, cy - h * 0.08
        inner = [(fx + (x - cx) * inset, fy + (y - cy) * inset) for x, y in pts]
        n = len(pts)
        for i in range(n):
            a, b = pts[i], pts[(i + 1) % n]
            ia, ib = inner[i], inner[(i + 1) % n]
            mx, my = (a[0] + b[0]) / 2 - cx, (a[1] + b[1]) / 2 - cy
            self.d.polygon([a, b, ib, ia], fill=self._tone(fill, self._shade(math.atan2(my, mx))))
        self.d.polygon(inner, fill=self._tone(fill, 1.03))

    def ellipse(self, box, fill):
        (x0, y0), (x1, y1) = box
        cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
        size = max(rx, ry) / self.s
        n = 12 if size < 1.5 else 6 if size < 6 else 7
        rot = 0.3 + (cx * 0.013) % 0.5
        pts = [(cx + rx * math.cos(rot + i * 2 * math.pi / n),
                cy + ry * math.sin(rot + i * 2 * math.pi / n)) for i in range(n)]
        self._faceted(pts, fill)

    def polygon(self, pts, fill):
        self._faceted(pts, fill)

    def rectangle(self, box, fill):
        (x0, y0), (x1, y1) = box
        self.d.rectangle([x0, y0, x1, y1], fill=fill[:3])


def tail_points(side):
    raw = [(835, 745), (930, 745), (1110, 678), (1098, 745), (1062, 800), (1030, 835),
           (950, 855), (855, 852)]
    k = 0.041
    base_x = 22 + 6.4 * side
    return [(base_x + (px - 835) * k * side, 21 + (py - 366) * k) for px, py in raw]


def mirror(pts):
    return [(44 - x, y) for x, y in pts]


# ─────────────────────────── 그리기 ───────────────────────────
def design(d, s, g, form, eyes="open"):
    """g: 장수 데이터, form: 0 새끼 / 1 청년 / 2 어른"""

    def P(x, y):
        return (x * s, y * s)

    def ell(cx, cy, rx, ry, col):
        d.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=col)

    def poly(pts, col):
        d.polygon([P(x, y) for x, y in pts], fill=col)

    def rect(x0, y0, x1, y1, col):
        d.rectangle([P(x0, y0), P(x1, y1)], fill=col)

    def bar(x0, y0, x1, y1, w, col):
        dx, dy = x1 - x0, y1 - y0
        L = math.hypot(dx, dy)
        nx, ny = -dy / L * w / 2, dx / L * w / 2
        poly([(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)], col)
        ell(x0, y0, w / 2, w / 2, col)
        ell(x1, y1, w / 2, w / 2, col)

    if form < 2 and g.get("young"):
        g = {**g, **g["young"]}
    ears_kind = g.get("puppy_ears", g["ears"]) if form == 0 else g["ears"]
    fur, fur_d = g["fur"], g["fur_d"]

    # 꼬리
    if g.get("tail_type") == "curl":
        # 고양이: 굵은 마디 몇 개로 꺾어서 말아 올리고, 끝은 육각 덩어리
        sd = g["tail"]
        tcol = g.get("tail_col", fur)
        center = [(28.4, 39.8), (32.8, 40.6), (35.9, 38.3), (36.7, 34.6), (35.3, 31.8), (33.0, 31.4)]
        center = [(22 + (x - 22) * sd, y) for x, y in center]
        widths = [3.8, 3.6, 3.4, 3.2, 3.0, 2.9]
        if g.get("fluffy"):
            widths = [5.0, 5.6, 5.8, 5.6, 5.0, 4.4]

        def tone(col, angle):
            dot = math.cos(angle - FacetDraw.LIGHT)
            k = 1.12 if dot > 0.45 else 0.97 if dot > -0.25 else 0.82
            return flat(tuple(int(max(0, min(255, c * k))) for c in col))

        L, R = [], []
        for i, (x, y) in enumerate(center):
            a = center[max(i - 1, 0)]
            b = center[min(i + 1, len(center) - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx, dy)
            nx, ny = -dy / ln, dx / ln
            w = widths[i] / 2
            L.append((x + nx * w, y + ny * w))
            R.append((x - nx * w, y - ny * w))
        for i in range(len(center) - 1):
            (x0, y0), (x1, y1) = center[i], center[i + 1]
            dx, dy = x1 - x0, y1 - y0
            poly([L[i], L[i + 1], center[i + 1], center[i]], tone(tcol, math.atan2(dx, -dy)))
            poly([center[i], center[i + 1], R[i + 1], R[i]], tone(tcol, math.atan2(-dx, dy)))
        # 끝 덩어리: 육각형을 빛 방향으로 3톤
        ex, ey = center[-1]
        tr = 3.2 if g.get("fluffy") else 2.4
        hexp = [(ex + tr * math.cos(math.radians(30 + 60 * k)), ey + tr * math.sin(math.radians(30 + 60 * k)))
                for k in range(6)]
        for k in range(6):
            mid = math.radians(60 + 60 * k)
            poly([(ex, ey), hexp[k], hexp[(k + 1) % 6]], tone(tcol, mid))
    else:
        poly(tail_points(g["tail"]), fur)
    fat = g.get("fat", 1.0)            # 통통한 체형: 몸통만 옆으로 넓게

    def fx(x):
        return 22 + (x - 22) * fat
    # 앉은 뒷다리
    ell(fx(15.6), 40.8, 2.8, 2.4, fur_d)
    ell(fx(28.4), 40.8, 2.8, 2.4, fur_d)
    # 몸통
    poly([(fx(x), y) for x, y in [(17, 30.4), (27, 30.4), (28.6, 36), (29.2, 40.6), (27.4, 42.6),
          (16.6, 42.6), (14.8, 40.6), (15.4, 36)]], g["robe"] if form >= 2 else fur)
    if form >= 2:
        rect(fx(15.2), 37.2, fx(28.8), 38.6, g["belt"])
        if g.get("robe_trim"):         # 학창의: 깃에 짙은 테두리
            bar(17.4, 30.8, 21.6, 36.4, 0.9, flat(g["robe_trim"]))
            bar(26.6, 30.8, 22.4, 36.4, 0.9, flat(g["robe_trim"]))
        if g.get("bells"):             # 감녕: 허리띠에 방울
            for bx in (18.6, 22, 25.4):
                ell(bx, 39.3, 1.0, 1.0, flat((240, 196, 84)))
    else:
        if g.get("saddle"):            # 셰퍼드: 어깨·등 쪽 짙은 무늬
            poly([(17, 30.4), (27, 30.4), (28.6, 36), (28.9, 38.4), (15.1, 38.4), (15.4, 36)], g["saddle"])
        ell(22, 37.6, 4.0 * fat, 4.4, g["belly"])
    if g.get("fluffy") and form < 2:   # 장모: 풍성한 가슴 털
        poly([(16.0, 32.0), (28.0, 32.0), (27.6, 35.6), (25.6, 34.8), (24.6, 37.8), (22.8, 36.4), (22, 39.4),
              (21.2, 36.4), (19.4, 37.8), (18.4, 34.8), (16.4, 35.6)], g["belly"])
    # 진영 색 목걸이 (새끼·청년)
    if form < 2:
        fc = g["faction"]
        bar(fx(16.8), 31.2, fx(27.2), 31.2, 1.3, flat(fc["main"]))
        bar(fx(16.8), 31.7, fx(27.2), 31.7, 0.35, flat(fc["dark"]))
        ell(22, 32.6, 0.95, 0.95, flat((240, 196, 84)))
        if g.get("bells"):
            ell(19.2, 32.4, 0.95, 0.95, flat((240, 196, 84)))
            ell(24.8, 32.4, 0.95, 0.95, flat((240, 196, 84)))

    # 앞발
    for px in (19.4, 24.6):
        ell(px, 42.7, 1.9, 1.15, fur)
    for tx in (18.8, 20.0, 24.0, 25.2):
        rect(tx - 0.1, 42.6, tx + 0.1, 43.8, fur_d)

    # 귀 (머리 뒤)
    if ears_kind == "droop":
        ear = [(10.8, 13.2), (7.5, 13.5), (5, 16.5), (4.2, 22), (4.6, 29.5), (7.5, 30.6), (10.5, 29.5)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
    elif ears_kind == "long":
        ear = [(11, 13.0), (7.2, 13.4), (4.4, 17), (3.4, 24.5), (3.6, 33.5), (6.8, 35.2), (10.4, 33.2)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
    elif ears_kind == "cat":           # 짧고 통통한 세모 귀
        ear = [(9.8, 16.4), (9.0, 10.4), (10.4, 7.6), (12.6, 8.0), (17.8, 11.9)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
        inner = [(11.0, 14.6), (10.6, 10.6), (11.4, 9.4), (15.0, 12.0)]
        poly(inner, flat(g["ear_in"])); poly(mirror(inner), flat(g["ear_in"]))
    elif ears_kind == "flop":          # 작게 접혀 늘어진 귀
        flop = [(11.4, 12.4), (7.2, 12.6), (5.0, 16.0), (5.6, 21.4), (8.8, 20.8), (11.2, 16.6)]
        poly(flop, g["ear"]); poly(mirror(flop), g["ear"])
    elif ears_kind == "fold":          # 스코티시 폴드: 앞으로 납작 접힌 귀
        ear = [(10.4, 15.6), (10.2, 11.6), (12.4, 10.0), (16.4, 10.6), (17.6, 12.4)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
        flap = [(10.2, 11.6), (12.4, 10.0), (16.4, 10.6), (13.4, 13.6)]
        poly(flap, flat(g["fur_d"])); poly(mirror(flap), flat(g["fur_d"]))
    elif ears_kind == "shepherd":      # 크고 높이 선 귀
        ear = [(9.8, 17.5), (7.4, 8.0), (8.8, 2.2), (12.8, 5.4), (17.8, 12.4)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
        inner = [(10.8, 14.6), (9.6, 7.6), (10.4, 5.2), (15.0, 11.6)]
        poly(inner, flat(g["ear_in"])); poly(mirror(inner), flat(g["ear_in"]))
    elif ears_kind == "semi":          # 콜리: 섰다가 끝만 앞으로 접힌 귀
        ear = [(9.6, 17.5), (8.6, 10.4), (10.2, 7.0), (13.8, 8.6), (17.4, 12.4)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
        tip = [(10.2, 7.0), (13.8, 8.6), (13.2, 11.6), (10.6, 10.2)]
        poly(tip, flat(g["fur_d"])); poly(mirror(tip), flat(g["fur_d"]))
    elif ears_kind == "mixed":         # 스트릿독: 한쪽은 서고 한쪽은 접힘
        ear = [(9.6, 17.5), (8.2, 9.2), (9.4, 4.6), (12.6, 6.8), (17.4, 12.4)]
        poly(ear, g["ear"])
        inner = [(10.8, 14.6), (10.2, 8.4), (11.0, 7.0), (14.8, 11.8)]
        poly(inner, flat(g["ear_in"]))
        flop = [(11.4, 12.4), (7.2, 12.6), (5.0, 16.0), (5.6, 21.4), (8.8, 20.8), (11.2, 16.6)]
        poly(mirror(flop), g.get("ear_r", g["ear"]))
    elif ears_kind == "up":
        ear = [(9.6, 17.5), (8.2, 9.2), (9.4, 4.6), (12.6, 6.8), (17.4, 12.4)]
        poly(ear, g["ear"]); poly(mirror(ear), g["ear"])
        if g["ear_in"]:
            inner = [(10.8, 14.6), (10.2, 8.4), (11.0, 7.0), (14.8, 11.8)]
            poly(inner, flat(g["ear_in"])); poly(mirror(inner), flat(g["ear_in"]))

    if g.get("ruff"):                  # 차우차우: 머리 윤곽을 그대로 따라 둘러싼 갈기
        pts = []
        for k in range(20):
            a = math.radians(18 + 18 * k)
            r = 1.0 if k % 2 else 1.13
            pts.append((22 + 13.5 * r * math.cos(a), 21.6 + 9.8 * r * 1.08 * math.sin(a)))
        poly(pts, g["fur_d"])
    elif g.get("fluffy"):              # 장모: 양 볼에 삐죽 나온 털
        tuft = [(11.5, 20.5), (6.8, 21.6), (9.4, 23.6), (5.6, 25.6), (9.0, 27.0), (6.6, 29.8), (11.0, 29.6),
                (10.6, 31.8), (15.0, 30.2)]
        poly(tuft, g["fur_d"]); poly(mirror(tuft), g["fur_d"])
    # 머리 (좌우대칭 10각형)
    poly([(22 + 13.5 * math.cos(math.radians(18 + 36 * k)),
           21 + 9.8 * math.sin(math.radians(18 + 36 * k))) for k in range(10)], fur)

    pat = g.get("pattern")
    if pat == "fore":                  # 셰퍼드: 이마의 짙은 무늬
        poly([(14.5, 13.4), (22, 11.4), (29.5, 13.4), (27.5, 16.8), (22, 18.6), (16.5, 16.8)], g["pat_col"])
    elif pat == "patch":               # 스트릿독: 한쪽 눈 얼룩
        ell(29.7, 23.8, 4.0, 3.8, g["pat_col"])
    elif pat == "pug":                 # 퍼그: 주둥이 둘레 짙은 가면 + 이마 주름
        ell(22, 26.8, 7.8, 4.6, g["pat_col"])
        bar(20.2, 16.6, 23.8, 16.6, 0.5, flat(g["fur_d"]))
        bar(20.8, 18.2, 23.2, 18.2, 0.5, flat(g["fur_d"]))
    elif pat == "siam":                # 샴: 코·주둥이 둘레가 짙은 포인트
        poly([(22, 23.4), (25.0, 24.6), (26.4, 27.0), (25.2, 29.6), (22, 30.3), (18.8, 29.6), (17.6, 27.0),
              (19.0, 24.6)], g["pat_col"])
    elif pat == "cowpatch":            # 젖소: 한쪽 이마~눈 덩어리 + 반대쪽 귀밑 얼룩
        poly([(22.6, 11.6), (28.6, 12.2), (33.6, 16.0), (34.2, 21.0), (31.6, 23.0), (27.0, 22.0), (23.6, 18.0)],
             g["pat_col"])
        ell(12.2, 17.0, 2.6, 2.2, g["pat_col"])
    elif pat == "blaze":               # 콜리: 흰 볼 + 이마 흰 줄
        ell(22, 27.0, 8.4, 3.9, g["muzzle"])
        poly([(22, 12.0), (24.0, 23.6), (20.0, 23.6)], flat(g["muzzle"]))

    # 고등어 무늬: 이마 M자 줄 + 볼 옆 줄
    if g.get("stripes"):
        st = flat(g["stripes"])
        bar(22, 14.6, 22, 17.4, 0.75, st)
        bar(19.6, 15.0, 20.0, 17.0, 0.7, st)
        bar(24.4, 15.0, 24.0, 17.0, 0.7, st)
        for y in (21.8, 23.6):
            bar(10.0, y, 11.7, y + 0.3, 0.7, st)
            bar(34.0, y, 32.3, y + 0.3, 0.7, st)

    # 얼굴 무늬
    if g["mask"] == "shiba":           # 시바: 하얀 볼(우라지로)
        ell(22, 27.0, 9.0, 3.9, g["muzzle"])
    elif g["mask"]:                    # 허스키: 눈 주변까지 하얀 가면 + 이마 줄
        ell(22, 25.6, 11.8, 5.6, g["mask"])
        poly([(22, 14.6), (23.8, 23.0), (20.2, 23.0)], flat(g["mask"]))

    # 모자 (청년부터)
    if form >= 1:
        h, hd, o = g["hat_col"], g["hat_d"], g["orn"]
        if g["hat"] == "turban":       # 관우: 녹색 두건
            poly([(9.5, 16), (13, 9), (22, 6), (31, 9), (34.5, 16), (22, 13)], h)
            poly([(9.5, 16), (22, 13), (34.5, 16), (34.5, 17.4), (22, 14.6), (9.5, 17.4)], hd)
            ell(22, 13.4, 1.6, 1.6, o)
        elif g["hat"] == "topknot":    # 유비: 상투관 + 옥비녀
            poly([(17.6, 12.8), (17.8, 9.0), (19.6, 6.8), (24.4, 6.8), (26.2, 9.0), (26.4, 12.8), (22, 13.4)], h)
            rect(17.4, 11.6, 26.6, 12.9, hd)
            bar(15.4, 9.4, 28.6, 8.6, 0.8, o)
        elif g["hat"] == "cap":        # 조조: 각진 관모
            poly([(16.4, 13.0), (16.8, 7.6), (27.2, 7.6), (27.6, 13.0), (22, 13.8)], h)
            rect(15.2, 6.4, 28.8, 7.8, hd)
            ell(22, 10.6, 1.3, 1.3, o)
        elif g["hat"] == "lunjin":     # 제갈량: 윤건 (높고 각진 비단 두건)
            poly([(16.6, 13.4), (17.4, 6.8), (19.6, 4.6), (24.4, 4.6), (26.6, 6.8), (27.4, 13.4), (22, 14.0)], h)
            rect(16.4, 11.8, 27.6, 13.4, hd)
            bar(22, 5.2, 22, 11.4, 0.55, flat(hd))          # 가운데 접힌 선
            ell(22, 12.6, 0.9, 0.9, o)
        elif g["hat"] in ("band", "feather"):   # 머리띠 (+휘날리는 끈 / +깃털)
            if g.get("band_tails"):
                poly([(33.6, 15.4), (39.6, 12.2), (40.6, 14.4), (34.6, 17.2)], flat(hd))
                poly([(33.8, 16.2), (40.0, 17.6), (39.4, 19.8), (34.0, 18.0)], flat(h))
            if g["hat"] == "feather":
                poly([(29.6, 14.4), (30.0, 6.0), (32.0, 3.2), (32.9, 8.6), (31.6, 14.8)], o)
                poly([(31.9, 15.0), (34.6, 7.4), (36.8, 6.0), (36.0, 11.2), (33.6, 15.6)], hd)
            poly([(9.6, 15.4), (22, 12.6), (34.4, 15.4), (34.4, 17.6), (22, 14.8), (9.6, 17.6)], h)
            ell(22, 13.8, 1.3, 1.3, flat(g["orn"] if g["hat"] == "band" else hd))
        elif g["hat"] == "helmet":     # 투구 (+깃털 장식 / +꼭지)
            if g.get("plume"):
                poly([(21.0, 6.4), (19.8, 2.6), (22.4, 0.7), (26.0, 1.5), (24.6, 3.8), (23.2, 6.4)], g["plume"])
            elif g.get("knob"):
                poly([(21.0, 6.2), (22, 3.2), (23.0, 6.2)], flat(o))
            poly([(14.6, 14.2), (15.2, 9.2), (18.4, 6.0), (25.6, 6.0), (28.8, 9.2), (29.4, 14.2), (22, 12.6)], h)
            poly([(14.4, 14.4), (22, 12.6), (29.6, 14.4), (29.6, 15.9), (22, 14.1), (14.4, 15.9)], hd)
            ell(22, 10.0, 1.2, 1.2, flat(o))
        elif g["hat"] == "straw":      # 방통: 삿갓 + 초록 꼭지·끈
            poly([(10.5, 14.6), (22, 4.6), (33.5, 14.6), (22, 16.0)], h)
            poly([(18.6, 7.6), (22, 4.6), (25.4, 7.6), (22, 8.6)], flat(hd))
            poly([(10.5, 14.6), (22, 16.0), (33.5, 14.6), (33.5, 15.7), (22, 17.1), (10.5, 15.7)], flat(hd))
        elif g["hat"] == "plume":      # 주유: 금관 + 긴 꿩 깃 두 가닥
            for sd in (-1, 1):
                # 뿌리는 굵고 끝은 뾰족하게, 바깥으로 휘어 늘어지는 꿩 깃
                top = [(1.0, 9.0), (3.6, 4.2), (7.4, 1.4), (11.6, 1.0), (15.2, 3.4)]
                bot = [(12.0, 2.6), (8.0, 3.2), (5.2, 5.6), (3.0, 9.6)]
                poly([(22 + sd * x, y) for x, y in top + bot], flat(g["plume"]))
                for (x0, y0, x1, y1) in ((4.0, 4.6, 5.0, 6.2), (6.6, 2.4, 7.2, 3.9), (9.6, 1.4, 9.8, 3.0)):
                    bar(22 + sd * x0, y0, 22 + sd * x1, y1, 0.6, flat((240, 196, 84)))
            poly([(18.2, 13.2), (18.6, 9.2), (20.3, 10.4), (22, 7.6), (23.7, 10.4), (25.4, 9.2),
                  (25.8, 13.2), (22, 13.8)], h)
            rect(18.0, 11.9, 26.0, 13.2, hd)
            ell(22, 10.6, 1.0, 1.0, o)
        elif g["hat"] == "flower":     # 초선: 귀 옆에 꽃 두 송이 + 비녀 + 늘어진 구슬
            bar(29.0, 9.4, 36.2, 14.8, 0.7, flat(o))                  # 비녀
            for i, by in enumerate((15.6, 17.4, 19.2)):               # 늘어진 구슬
                ell(35.4, by, 0.55, 0.55, flat(hd if i % 2 else o))
            for (fx, fy, fr, col) in ((28.4, 9.6, 2.5, h), (32.4, 11.6, 1.9, hd)):
                for k in range(5):
                    a = math.radians(-90 + 72 * k)
                    ell(fx + math.cos(a) * fr * 0.62, fy + math.sin(a) * fr * 0.62, fr * 0.52, fr * 0.52,
                        flat(col))
                ell(fx, fy, fr * 0.32, fr * 0.32, flat(o))
        elif g["hat"] == "ribbon":     # 손상향: 큰 리본
            wing = [(22, 10.8), (16.4, 7.2), (15.8, 13.2)]
            poly(wing, h); poly(mirror(wing), h)
            fold = [(22, 10.8), (18.6, 9.4), (18.4, 11.9)]
            poly(fold, flat(hd)); poly(mirror(fold), flat(hd))
            ell(22, 10.8, 1.5, 1.5, flat(o))
        elif g["hat"] == "mian":       # 조비: 면류관 (평평한 판 + 구슬 줄)
            poly([(17.4, 13.2), (17.8, 8.6), (26.2, 8.6), (26.6, 13.2), (22, 13.8)], h)
            rect(17.2, 11.9, 26.8, 13.2, flat(o))
            poly([(13.6, 6.6), (30.4, 6.6), (31.2, 8.6), (12.8, 8.6)], flat(hd))
            for bx in (14.6, 17.0, 27.0, 29.4):
                bar(bx, 8.8, bx, 11.2, 0.5, flat(o))
        elif g["hat"] == "crown":      # 손권: 금관 + 붉은 보석
            poly([(17, 13.2), (17, 8.6), (18.9, 10.4), (20.4, 7.0), (22, 9.6), (23.6, 7.0),
                  (25.1, 10.4), (27, 8.6), (27, 13.2), (22, 13.8)], h)
            rect(16.8, 11.8, 27.2, 13.2, hd)
            ell(22, 11.0, 1.0, 1.0, o)

    # 주둥이
    ell(22, 27.0, 5.4, 3.4, g["muzzle"])

    # 수염
    bc = g["beard_col"]
    if g["beard"] in ("long", "purple") and form >= 1:
        tip = {("long", 1): 35.5, ("long", 2): 39.5, ("purple", 1): 32.8, ("purple", 2): 36.0}[(g["beard"], form)]
        side = tip - 6 if g["beard"] == "long" else tip - 2.6
        poly([(16.2, 29.5), (19, 30.3), (22, 30.1), (25, 30.3), (27.8, 29.5),
              (27.6, side), (22, tip), (16.4, side)], bc)
        poly([(22, 26.3), (24, 26.4), (25.8, 27.0), (26.8, 28.3), (27.3, 30.0), (26.4, 30.0),
              (26.0, 28.6), (25.2, 27.6), (23.8, 27.05), (22, 26.95), (20.2, 27.05), (18.8, 27.6),
              (18.0, 28.6), (17.6, 30.0), (16.7, 30.0), (17.2, 28.3), (18.2, 27.0), (20, 26.4)], flat(bc))
    elif g["beard"] == "mane" and form >= 1:
        # 장비: 사자 갈기처럼 삐죽삐죽 뻗친 수염 (볼에서 턱까지)
        for (ro_x, ro_y, ri_x, ri_y, col) in (
                ((12.6, 11.4, 9.6, 8.2, bc) if form >= 2 else (10.4, 8.4, 8.0, 6.2, bc)),
                ((9.4, 8.4, 7.2, 6.0, g.get("mane_in", (74, 60, 58))) if form >= 2
                 else (7.8, 6.2, 6.0, 4.6, g.get("mane_in", (74, 60, 58))))):
            pts = []
            n = 9
            for i in range(n + 1):
                a = math.radians(180 * i / n)
                pts.append((22 + ro_x * math.cos(a), 26.6 + ro_y * math.sin(a)))
                if i < n:
                    a2 = math.radians(180 * (i + 0.5) / n)
                    pts.append((22 + ri_x * math.cos(a2), 26.6 + ri_y * math.sin(a2)))
            poly(pts, flat(col))
        ell(22, 27.0, 5.4, 3.4, g["muzzle"])
        poly([(22, 26.3), (24, 26.4), (25.8, 27.0), (26.8, 28.3), (27.3, 30.0), (26.4, 30.0),
              (26.0, 28.6), (25.2, 27.6), (23.8, 27.05), (22, 26.95), (20.2, 27.05), (18.8, 27.6),
              (18.0, 28.6), (17.6, 30.0), (16.7, 30.0), (17.2, 28.3), (18.2, 27.0), (20, 26.4)], flat(bc))
    elif g["beard"] == "stache" and form >= 1:
        # 장료: 굵고 당당한 콧수염만
        poly([(22, 26.2), (24, 26.3), (25.9, 26.9), (27.0, 28.2), (27.6, 30.0), (26.4, 30.0),
              (26.0, 28.7), (25.1, 27.8), (23.8, 27.3), (22, 27.2), (20.2, 27.3), (18.9, 27.8),
              (18.0, 28.7), (17.6, 30.0), (16.4, 30.0), (17.0, 28.2), (18.1, 26.9), (20, 26.3)], flat(bc))
    elif g["beard"] == "short" and form >= 1:
        # 손견: 짧고 다부진 턱수염 + 콧수염
        if g.get("side_tufts"):        # 슈나우저: 주둥이 양옆으로 덥수룩하게 늘어진 털
            tuft = [(17.6, 26.2), (15.4, 26.6), (14.0, 28.6), (14.8, 30.4), (17.8, 30.2)]
            poly(tuft, flat(bc)); poly(mirror(tuft), flat(bc))
        if form == 1:
            # 청년: 턱수염 없이 짧은 콧수염만 (끝을 위로 올려 목걸이와 띄움)
            poly([(22, 26.3), (24, 26.4), (25.8, 26.9), (26.8, 27.8), (27.0, 28.6), (26.1, 28.5),
                  (25.4, 27.8), (23.8, 27.2), (22, 27.05), (20.2, 27.2), (18.6, 27.8), (17.9, 28.5),
                  (17.0, 28.6), (17.2, 27.8), (18.2, 26.9), (20, 26.4)], flat(bc))
        else:
            poly([(16.6, 29.5), (19, 30.3), (22, 30.1), (25, 30.3), (27.4, 29.5),
                  (26.6, 31.6), (22, 34.6), (17.4, 31.6)], bc)
            poly([(22, 26.3), (24, 26.4), (25.8, 27.0), (26.8, 28.3), (27.3, 30.0), (26.4, 30.0),
                  (26.0, 28.6), (25.2, 27.6), (23.8, 27.05), (22, 26.95), (20.2, 27.05), (18.8, 27.6),
                  (18.0, 28.6), (17.6, 30.0), (16.7, 30.0), (17.2, 28.3), (18.2, 27.0), (20, 26.4)], flat(bc))
    elif g["beard"] in ("scruff", "thin") and form >= 1:
        # 가는 팔자 콧수염 (+방통은 덥수룩한 턱수염)
        poly([(22, 26.3), (24.2, 26.5), (26.4, 27.6), (25.6, 27.6), (23.8, 27.1), (22, 27.0),
              (20.2, 27.1), (18.4, 27.6), (17.6, 27.6), (19.8, 26.5)], flat(bc))
        if g["beard"] == "scruff":
            k = 1.0 if form == 1 else 1.5
            poly([(20.0, 29.6), (24.0, 29.6), (23.6, 30.6 + 1.4 * k), (22.8, 30.9), (22, 31.2 + 2.2 * k),
                  (21.2, 30.9), (20.4, 30.6 + 1.4 * k)], flat(bc))
    elif g["beard"] == "neat" and form >= 1:
        # 제갈량: 단정한 콧수염 + 가지런한 턱수염 (어른은 더 길게)
        poly([(22, 26.3), (23.9, 26.5), (25.6, 27.5), (24.9, 27.6), (23.6, 27.1), (22, 27.0),
              (20.4, 27.1), (19.1, 27.6), (18.4, 27.5), (20.1, 26.5)], flat(bc))
        tip = 33.0 if form == 1 else 36.0
        poly([(20.6, 29.5), (23.4, 29.5), (23.2, tip - 2.0), (22, tip), (20.8, tip - 2.0)], flat(bc))
    elif g["beard"] == "goatee" and form >= 1:
        # 조조: 가는 팔자 콧수염 (+ 어른은 뾰족 염소수염)
        poly([(22, 26.3), (24.2, 26.5), (26.4, 27.6), (25.6, 27.6), (23.8, 27.1), (22, 27.0),
              (20.2, 27.1), (18.4, 27.6), (17.6, 27.6), (19.8, 26.5)], flat(bc))
        if form >= 2:
            poly([(20.9, 29.5), (23.1, 29.5), (22.7, 32.4), (22, 34.4), (21.3, 32.4)], flat(bc))

    # 눈썹
    bw = g.get("brow_w", 0.95)
    brows = {
        "angry": (13.8, 21.1, 16.7, 22.2),
        "gentle": (13.8, 22.2, 16.7, 21.3),
        "sly": (13.6, 20.5, 16.9, 22.5),
        "calm": (13.7, 21.7, 16.6, 21.5),
        "brave": (13.5, 20.8, 16.9, 21.9),      # 굵고 곧은 눈썹
        "lively": (13.9, 20.7, 16.6, 21.7),     # 짧고 시원하게 올라간 눈썹
        "elegant": (13.0, 21.0, 16.8, 21.9),    # 가늘고 긴 눈썹
        "sad": (13.2, 22.9, 16.8, 20.7),        # 억울한 팔자 눈썹
        "blank": (13.9, 19.9, 16.5, 19.7),      # 멍하게 높이 올라간 눈썹
        "old": (13.0, 22.6, 16.9, 21.0),        # 늙은이: 굵게 처진 흰 눈썹
    }
    if g["brow"] == "dots":
        ell(14.4, 21.4, 1.0, 0.8, g["brow_col"])
        ell(29.6, 21.4, 1.0, 0.8, g["brow_col"])
    elif g["brow"] == "arch":                   # 해맑은 ^ ^ 눈썹
        for sx in (1, -1):
            c = 22 - 7.7 * sx
            bar(c - 1.6, 21.7, c, 20.7, 0.9, g["brow_col"])
            bar(c, 20.7, c + 1.6, 21.7, 0.9, g["brow_col"])
    elif g["brow"] == "smirk":                  # 능글: 한쪽은 내리깔고 한쪽은 치켜올림
        bar(13.7, 21.9, 16.6, 21.7, 0.95, g["brow_col"])
        bar(27.4, 21.3, 28.9, 20.0, 0.95, g["brow_col"])
        bar(28.9, 20.0, 30.4, 20.5, 0.95, g["brow_col"])
    else:
        lx0, ly0, lx1, ly1 = brows[g["brow"]]
        bar(lx0, ly0, lx1, ly1, bw, g["brow_col"])
        bar(44 - lx0, ly0, 44 - lx1, ly1, bw, g["brow_col"])
    # 눈, 코, 입 (eye_col: 눈 색. 털이 까만 애는 밝은 색으로 해야 보임)
    EYE = g.get("eye_col", BLACK)
    for ex in (14.3, 29.7):
        if eyes == "closed":           # 잘 때: ∪ 모양으로 감은 눈
            bar(ex - 1.2, 24.3, ex, 25.2, 0.55, EYE)
            bar(ex, 25.2, ex + 1.2, 24.3, 0.55, EYE)
        elif eyes == "squint":         # 쓰다듬을 때: >.<
            sx = 1 if ex < 22 else -1
            bar(ex - 1.0 * sx, 23.7, ex + 0.9 * sx, 24.6, 0.6, EYE)
            bar(ex + 0.9 * sx, 24.6, ex - 1.0 * sx, 25.5, 0.6, EYE)
        elif eyes == "line":           # 쓰다듬을 때: ㅡ.ㅡ
            bar(ex - 1.3, 24.7, ex + 1.3, 24.7, 0.62, EYE)
        elif eyes == "half":           # 피곤할 때: 반쯤 감긴 눈
            poly([(ex - 1.15, 24.6)] + [(ex + 1.05 * math.cos(math.radians(a)), 24.6 + 1.05 * math.sin(math.radians(a)))
                                         for a in range(0, 181, 30)], flat(EYE))
            bar(ex - 1.3, 24.5, ex + 1.3, 24.5, 0.5, EYE)
        elif g.get("eye") == "sharp":  # 날카롭게 치켜 올라간 눈
            sx = 1 if ex < 22 else -1
            poly([(ex - 1.5 * sx, 23.7), (ex + 0.1 * sx, 24.0), (ex + 1.3 * sx, 24.9), (ex - 0.1 * sx, 25.3)],
                 flat(EYE))
        elif g.get("eye") == "happy":  # 허허 웃는 ^ ^ 눈
            bar(ex - 1.25, 25.1, ex, 24.0, 0.6, EYE)
            bar(ex, 24.0, ex + 1.25, 25.1, 0.6, EYE)
        elif g.get("eye") == "dot":    # 멍한 작은 점 눈
            ell(ex, 24.8, 0.7, 0.7, EYE)
        elif g.get("eye") == "smug":   # 반만 뜬 눈 (훗)
            poly([(ex - 1.25, 24.5)] + [(ex + 1.25 * math.cos(math.radians(a)), 24.5 + 1.15 * math.sin(math.radians(a)))
                                         for a in range(0, 181, 30)], flat(EYE))
            bar(ex - 1.6, 24.4, ex + 1.6, 24.4, 0.55, EYE)
        else:
            ell(ex, 24.6, 1.05, 1.05, EYE)
    # 안대 (보는 쪽 기준 오른쪽 눈 = 왼눈)
    if g.get("eyepatch"):
        pc = g.get("patch_col", (30, 26, 30))   # 안대 색
        bar(12.6, 15.6, 29.7, 24.4, 0.6, flat(pc))
        bar(29.7, 24.4, 34.6, 25.6, 0.6, flat(pc))
        poly([(29.7 + 2.5 * math.cos(math.radians(30 + 60 * k)), 24.5 + 2.3 * math.sin(math.radians(30 + 60 * k)))
              for k in range(6)], flat(pc))
    # 속눈썹 (눈꼬리 바깥 위로)
    if g.get("lash") and eyes != "squint":   # >.< 일 때는 속눈썹이 겹쳐 보여서 잠깐 뺌
        angs = {1: (215,), 2: (200, 235), 3: (195, 218, 240)}[g["lash"]]
        for ex, sx in ((14.3, 1), (29.7, -1)):
            for a in angs:
                ca, sa = math.cos(math.radians(a)) * sx, math.sin(math.radians(a))
                bar(ex + ca * 0.8, 24.6 + sa * 0.8, ex + ca * 2.5, 24.6 + sa * 2.5, 0.42, BLACK)
    NM = g.get("nose_col", BLACK)   # 코·입 색 (털이 까만 애는 밝게)
    poly([(21.3, 24.85), (22.7, 24.85), (23.1, 25.25), (23.1, 25.7), (22.8, 26.0),
          (21.2, 26.0), (20.9, 25.7), (20.9, 25.25)], NM)
    mouth = g.get("mouth")
    if mouth == "cat":                 # 고양이 입 (ω)
        w = [(20.7, 28.0), (21.0, 28.6), (21.7, 28.6), (22.0, 28.0), (22.3, 28.6), (23.0, 28.6), (23.3, 28.0)]
        for (x0, y0), (x1, y1) in zip(w, w[1:]):
            bar(x0, y0, x1, y1, 0.45, NM)
    elif mouth == "flat":              # 깐깐하게 꾹 다문 입
        bar(21.0, 28.3, 23.0, 28.3, 0.5, NM)
    elif mouth == "frown":             # 억울하게 처진 입
        bar(20.9, 28.9, 22.0, 28.2, 0.5, NM)
        bar(22.0, 28.2, 23.1, 28.9, 0.5, NM)
    elif mouth == "laugh":             # 허허: 크게 벌린 입
        poly([(20.4, 28.0), (23.6, 28.0), (23.2, 29.6), (22, 30.4), (20.8, 29.6)], flat((140, 48, 58)))
        poly([(21.2, 29.5), (22.8, 29.5), (22, 30.2)], flat((244, 130, 140)))
        bar(20.4, 28.0, 23.6, 28.0, 0.45, NM)
    elif mouth == "smile":             # 여유로운 미소
        bar(20.6, 28.0, 21.5, 28.65, 0.5, NM)
        bar(21.5, 28.65, 22.0, 28.05, 0.5, NM)
        bar(22.0, 28.05, 22.5, 28.65, 0.5, NM)
        bar(22.5, 28.65, 23.4, 28.0, 0.5, NM)
    elif mouth == "smirk":             # 한쪽 입꼬리만 씩
        bar(21.3, 28.6, 22.0, 28.1, 0.55, NM)
        bar(22.0, 28.1, 23.7, 27.7, 0.55, NM)
    else:
        if mouth in ("grin", "tongue"):   # 벌린 입
            poly([(20.9, 28.5), (23.1, 28.5), (22.8, 29.9), (21.2, 29.9)], flat((140, 48, 58)))
        if mouth == "tongue":             # 헤벌쭉 내민 혀
            poly([(21.4, 29.2), (23.2, 29.2), (23.4, 31.2), (22.4, 32.0), (21.4, 31.2)], flat((244, 130, 140)))
            bar(22.4, 29.6, 22.4, 31.0, 0.25, flat((214, 96, 110)))
        bar(21.5, 28.65, 22.0, 28.05, 0.55, NM)
        bar(22.0, 28.05, 22.5, 28.65, 0.55, NM)
        if mouth == "fangs":              # 아래에서 솟은 송곳니
            for sx in (-1, 1):
                poly([(22 + sx * 1.9, 29.3), (22 + sx * 0.9, 29.3), (22 + sx * 1.4, 27.7)], flat((255, 255, 255)))
    # 고양이 수염
    if g.get("whiskers"):
        wc = flat((70, 62, 64))
        for (x0, y0, x1, y1) in ((16.9, 27.2, 12.6, 26.4), (16.9, 28.1, 12.8, 28.7)):
            bar(x0, y0, x1, y1, 0.28, wc)
            bar(44 - x0, y0, 44 - x1, y1, 0.28, wc)


def render(g, form, size, eyes="open"):
    # 4배로 크게 그린 뒤 줄여서 계단 현상 없이 매끈하게
    big = size * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    design(FacetDraw(img, big / 48), big / 48, g, form, eyes)
    return img.resize((size, size), Image.LANCZOS)


GAME_IDS = {"관우": "guan_yu", "유비": "liu_bei", "제갈량": "zhuge_liang", "조조": "cao_cao", "손권": "sun_quan"}


def export_game(out_dir, size=384):
    """게임용: <id>_<form>_<eyes>.png  (form 0 새끼 / 1 청년 / 2 어른, eyes open/closed/half)"""
    import os
    os.makedirs(out_dir, exist_ok=True)
    for name, gid in GAME_IDS.items():
        for form in range(3):
            for eyes in ("open", "closed", "half", "squint", "line"):
                render(DOGS[name], form, size, eyes).save(f"{out_dir}/{gid}_{form}_{eyes}.png", optimize=True)


def sheet(names, path, cell=420):
    font = ImageFont.truetype(FONT, 34)
    small = ImageFont.truetype(FONT, 24)
    forms = [("새끼", 0, 0.78), ("청년", 1, 0.9), ("어른", 2, 1.0)]
    head_w = 190
    W, H = head_w + cell * 3, 70 + cell * len(names)
    img = Image.new("RGB", (W, H), (250, 243, 226))
    d = ImageDraw.Draw(img)
    for j, (label, _, _) in enumerate(forms):
        d.text((head_w + cell * j + cell / 2, 38), label, fill=(80, 60, 50), font=font, anchor="mm")
    for i, name in enumerate(names):
        g = DOGS[name]
        top = 70 + cell * i
        d.text((head_w / 2, top + cell / 2 - 18), name, fill=(80, 60, 50), font=font, anchor="mm")
        d.text((head_w / 2, top + cell / 2 + 20), g["breed"], fill=(130, 110, 95), font=small, anchor="mm")
        ground = top + cell - 28
        for j, (_, form, sc) in enumerate(forms):
            size = int(cell * sc)
            pic = render(g, form, size)
            cx = head_w + cell * j + cell / 2
            feet = 43.8 / 48 * size
            sh = 110 * sc
            d.ellipse([cx - sh, ground - 10 * sc, cx + sh, ground + 10 * sc], fill=(232, 222, 200))
            img.paste(pic, (int(cx - 22 / 48 * size), int(ground - feet)), pic)
    img.save(path)


if __name__ == "__main__":
    if len(sys.argv) > 3 and sys.argv[3] == "batch4":
        sheet(["사마의", "서서", "노숙", "제갈량"], OUT + "/b4_cats.png", cell=380)
        sheet(["태사자", "능통", "여몽", "황개"], OUT + "/b4_wu.png", cell=380)
        sheet(["유선", "황충", "위연"], OUT + "/b4_shu.png", cell=380)
        font = ImageFont.truetype(FONT, 32)
        im = Image.new("RGB", (430 * 3, 500), (250, 243, 226))
        dr = ImageDraw.Draw(im)
        for i, nm in enumerate(["조운", "강유", "장료"]):
            pic = render(DOGS[nm], 0, 400)
            dr.ellipse([430 * i + 100, 372, 430 * i + 330, 396], fill=(232, 222, 200))
            im.paste(pic, (430 * i + 32, 20), pic)
            dr.text((430 * i + 215, 450), nm + " (새끼)", fill=(80, 60, 50), font=font, anchor="mm")
        im.save(OUT + "/b4_ears.png")
    elif len(sys.argv) > 3 and sys.argv[3] == "guojia":
        sheet(["곽가"], OUT + "/guojia.png", cell=420)
    elif len(sys.argv) > 3 and sys.argv[3] == "zgj":
        sheet(["제갈근", "제갈량"], OUT + "/zgj.png", cell=400)
    elif len(sys.argv) > 3 and sys.argv[3] == "export_sp":
        GAME_IDS.clear()
        GAME_IDS.update({"여포": "lu_bu", "진궁": "chen_gong", "원소": "yuan_shao", "원술": "yuan_shu",
                         "공손찬": "gongsun_zan", "초선": "diao_chan"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "lubu":
        sheet(["여포"], OUT + "/lubu.png", cell=380)
    elif len(sys.argv) > 3 and sys.argv[3] == "special":
        sheet(["여포", "진궁", "원소"], OUT + "/sp1.png", cell=380)
        sheet(["원술", "공손찬", "초선"], OUT + "/sp2.png", cell=380)
    elif len(sys.argv) > 3 and sys.argv[3] == "hhy":
        sheet(["하후돈", "하후연"], OUT + "/hhy.png", cell=400)
    elif len(sys.argv) > 3 and sys.argv[3] == "export_hhy":
        GAME_IDS.clear()
        GAME_IDS.update({"하후연": "xiahou_yuan"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "lashfix":
        import os
        os.makedirs(OUT, exist_ok=True)
        ids = {"제갈량": "zhuge_liang", "주유": "zhou_yu", "육손": "lu_xun", "손상향": "sun_shangxiang", "순욱": "xun_yu"}
        for name, gid in ids.items():
            for form in range(3):
                render(DOGS[name], form, 384, "squint").save(f"{OUT}/{gid}_{form}_squint.png", optimize=True)
        sheet_img = Image.new("RGB", (220 * 5, 240), (250, 243, 226))
        for i, name in enumerate(ids):
            pic = render(DOGS[name], 2, 220, "squint")
            sheet_img.paste(pic, (220 * i, 10), pic)
        sheet_img.save(OUT + "/_lashfix.png")
    elif len(sys.argv) > 3 and sys.argv[3] == "export_zgj":
        GAME_IDS.clear()
        GAME_IDS.update({"제갈근": "zhuge_jin"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "export14":
        GAME_IDS.clear()
        GAME_IDS.update({"사마의": "sima_yi", "태사자": "taishi_ci", "능통": "ling_tong", "노숙": "lu_su",
                         "여몽": "lu_meng", "황개": "huang_gai", "유선": "liu_shan", "서서": "xu_shu",
                         "황충": "huang_zhong", "위연": "wei_yan", "제갈량": "zhuge_liang",
                         "조운": "zhao_yun", "강유": "jiang_wei", "장료": "zhang_liao"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "export1":
        GAME_IDS.clear()
        GAME_IDS.update({"곽가": "guo_jia"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "export4":
        GAME_IDS.clear()
        GAME_IDS.update({"하후돈": "xiahou_dun", "하후연": "xiahou_yuan", "전위": "dian_wei", "우금": "yu_jin"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "weifix":
        sheet(["전위", "곽가"], OUT + "/weifix_a.png", cell=400)
        font = ImageFont.truetype(FONT, 32)
        im = Image.new("RGB", (430 * 3, 500), (250, 243, 226))
        dr = ImageDraw.Draw(im)
        for i, nm in enumerate(["하후돈", "하후연", "우금"]):
            pic = render(DOGS[nm], 1, 400)
            dr.ellipse([430 * i + 100, 372, 430 * i + 330, 396], fill=(232, 222, 200))
            im.paste(pic, (430 * i + 32, 20), pic)
            dr.text((430 * i + 215, 450), nm + " (청년)", fill=(80, 60, 50), font=font, anchor="mm")
        im.save(OUT + "/weifix_b.png")
    elif len(sys.argv) > 3 and sys.argv[3] == "export6":
        GAME_IDS.clear()
        GAME_IDS.update({"장료": "zhang_liao", "허저": "xu_chu", "조비": "cao_pi", "가후": "jia_xu",
                         "순욱": "xun_yu", "순유": "xun_you"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "wei":
        sheet(["하후돈", "장료", "허저", "하후연", "전위", "우금"], OUT + "/new_wei1.png", cell=380)
        sheet(["조비", "가후", "순욱", "곽가", "순유"], OUT + "/new_wei2.png", cell=380)
    elif len(sys.argv) > 3 and sys.argv[3] == "export3":
        GAME_IDS.clear()
        GAME_IDS.update({"법정": "fa_zheng", "마초": "ma_chao", "주유": "zhou_yu"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "fix3":
        sheet(["법정", "마초", "주유"], OUT + "/fix3.png", cell=420)
    elif len(sys.argv) > 3 and sys.argv[3] == "export9":
        GAME_IDS.clear()
        GAME_IDS.update({"장비": "zhang_fei", "조운": "zhao_yun", "강유": "jiang_wei", "방통": "pang_tong",
                         "육손": "lu_xun", "손상향": "sun_shangxiang", "감녕": "gan_ning",
                         "손견": "sun_jian", "손책": "sun_ce"})
        export_game(OUT)
    elif len(sys.argv) > 3 and sys.argv[3] == "new":
        sheet(["장비", "조운", "강유", "마초", "방통", "법정"], OUT + "/new_shu.png", cell=380)
        sheet(["주유", "육손", "손상향", "감녕", "손견", "손책"], OUT + "/new_wu.png", cell=380)
    elif len(sys.argv) > 3 and sys.argv[3] == "export":
        export_game(OUT)
    else:
        sheet(["관우", "유비", "제갈량"], OUT + "/shu_growth.png")
        sheet(["조조", "손권"], OUT + "/weiwu_growth.png")
