import sys
sys.argv=['x','/home/claude/art','/mnt/user-data/outputs/main.ttf']
exec(open('/home/claude/art/dogs.py').read().split('if __name__')[0])
GOLD=(240,196,84); SILV=(206,212,222)
JIN = dict(main=(44,128,128), dark=(28,88,92), deep=(22,72,78))   # 진 = 청록
NEW = {
 # ── 위 ──
 "장합": dict(breed="보르조이", fur=(246,240,228), fur_d=(214,204,186), ear=(206,170,120), ear_in=None,
   muzzle=(252,250,244), belly=(252,250,244), mask=None, ears="semi", tail=-1, pattern="patch", pat_col=(206,170,120),
   brow="brave", brow_col=BLACK, mouth="smirk",
   hat="plume", hat_col=WEI["main"], hat_d=WEI["dark"], orn=GOLD, plume=(250,250,246),
   robe=WEI["main"], belt=GOLD, robe_trim=SILV, faction=WEI, beard=None, beard_col=None),
 "이전": dict(breed="진돗개 황구", fur=(214,160,92), fur_d=(178,124,62), ear=(190,136,74), ear_in=(240,214,190),
   muzzle=(250,236,212), belly=(250,236,212), mask=None, ears="up", tail=1,
   brow="gentle", brow_col=(90,60,36), mouth="flat",
   hat="cap", hat_col=WEI["main"], hat_d=WEI["dark"], orn=SILV,
   robe=WEI["main"], belt=SILV, faction=WEI, beard="thin", beard_col=(70,48,32)),
 "악진": dict(breed="잭 러셀 테리어", fur=(250,248,242), fur_d=(216,212,204), ear=(170,104,58), ear_in=None,
   muzzle=(252,250,246), belly=(252,250,246), mask=None, ears="semi", tail=1, pattern="patch", pat_col=(170,104,58), fat=0.94,
   brow="angry", brow_w=1.2, brow_col=BLACK, mouth="grin",
   hat="helmet", hat_col=SILV, hat_d=WEI["main"], orn=GOLD, plume=WEI["main"],
   robe=WEI["main"], belt=GOLD, faction=WEI, beard=None, beard_col=None),
 "하후패": dict(breed="회색 복서", fur=(160,156,158), fur_d=(124,120,124), ear=(104,100,104), ear_in=None,
   muzzle=(242,238,232), belly=(242,238,232), mask=None, ears="flop", tail=-1,
   brow="brave", brow_w=1.15, brow_col=BLACK,
   hat="band", hat_col=WEI["main"], hat_d=WEI["dark"], orn=GOLD,
   robe=(64,104,190), belt=GOLD, faction=WEI, beard="short", young_beard="tidy", beard_col=(60,56,64)),
 # ── 촉 ──
 "관평": dict(breed="붉은 갈색 장모견", fur=(214,104,70), fur_d=(170,72,48), ear=(150,60,42), ear_in=None,
   muzzle=(248,220,192), belly=(248,220,192), mask=None, ears="droop", tail=-1,
   brow="brave", brow_col=BLACK,
   hat="band", hat_col=(46,150,92), hat_d=(30,104,64), orn=GOLD,
   robe=(46,150,92), belt=GOLD, faction=SHU, beard=None, beard_col=None),
 "마대": dict(breed="러프 콜리", fur=(150,96,56), fur_d=(114,70,40), ear=(104,62,36), ear_in=None,
   muzzle=(250,246,238), belly=(250,246,238), mask=None, ears="semi", tail=1, pattern="blaze",
   brow="lively", brow_col=BLACK, mouth="smirk",
   hat="helmet", hat_col=SILV, hat_d=SHU["main"], orn=GOLD, plume=SHU["main"],
   robe=SHU["main"], belt=SILV, faction=SHU, beard=None, beard_col=None),
 "주창": dict(breed="블랙 탄 로트와일러", fur=(52,44,46), fur_d=(36,30,32), ear=(40,34,36), ear_in=None,
   muzzle=(176,106,58), belly=(176,106,58), mask=None, ears="flop", tail=-1, fat=1.08,
   brow="angry", brow_w=1.3, brow_col=(176,106,58), eye_col=(250,240,220), mouth="grin",
   hat="band", hat_col=SHU["main"], hat_d=SHU["dark"], orn=GOLD,
   robe=SHU["dark"], belt=GOLD, faction=SHU, beard="scruff", beard_col=(30,24,26)),
 # ── 오 ──
 "정보": dict(breed="노견 셰퍼드", fur=(170,146,120), fur_d=(132,110,88), ear=(120,96,74), ear_in=(220,190,170),
   muzzle=(236,232,226), belly=(236,232,226), mask=None, ears="shepherd", tail=-1,
   brow="gentle", brow_w=1.2, brow_col=(236,232,226),
   hat="helmet", hat_col=SILV, hat_d=WU["main"], orn=GOLD, plume=WU["main"],
   robe=WU["main"], belt=GOLD, faction=WU, beard="tidy", beard_col=(236,232,226)),
 "주태": dict(breed="도베르만", fur=(46,40,44), fur_d=(30,26,30), ear=(34,30,34), ear_in=(150,110,104),
   muzzle=(170,96,56), belly=(170,96,56), mask=None, ears="up", tail=-1,
   brow="angry", brow_w=1.25, brow_col=(170,96,56), eye_col=(250,240,220), mouth="flat", eyepatch=True, patch_col=WU["main"],
   hat="band", hat_col=WU["main"], hat_d=WU["dark"], orn=GOLD,
   robe=WU["dark"], belt=GOLD, faction=WU, beard=None, beard_col=None),
 "한당": dict(breed="브린들 마스티프", fur=(170,124,74), fur_d=(130,90,50), ear=(96,68,44), ear_in=None,
   muzzle=(206,170,126), belly=(232,206,172), mask=None, ears="flop", tail=-1, stripes=(110,76,44), fat=1.06,
   brow="brave", brow_col=BLACK, mouth="grin",
   hat="helmet", hat_col=(236,196,90), hat_d=WU["main"], orn=(250,250,246), plume=WU["main"],
   robe=WU["main"], belt=GOLD, faction=WU, beard="short", beard_col=(52,36,32)),
 # ── 스페셜 ──
 "화타": dict(breed="하얀 장모 노묘", fur=(248,246,240), fur_d=(214,210,200), ear=(240,236,228), ear_in=(240,190,190),
   muzzle=(252,252,250), belly=(252,252,250), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True, fluffy=True,
   brow="gentle", brow_w=1.1, brow_col=(170,166,160), eye="happy", mouth="cat",
   hat="straw", hat_col=(222,186,110), hat_d=(170,130,70), orn=(110,170,96),
   robe=(110,170,96), belt=(240,236,220), robe_trim=(240,236,220), faction=SP, beard="long", beard_col=(244,242,236)),
 "동탁": dict(breed="불독", fur=(204,160,110), fur_d=(164,120,76), ear=(150,104,66), ear_in=None,
   muzzle=(244,226,200), belly=(244,226,200), mask=None, ears="flop", tail=1, pattern="pug", pat_col=(90,64,48), fat=1.22,
   brow="angry", brow_w=1.3, brow_col=BLACK, eye="smug", mouth="smirk",
   hat="mian", hat_col=SP["main"], hat_d=(44,30,64), orn=GOLD,
   robe=SP["dark"], belt=GOLD, robe_trim=GOLD, faction=SP, beard="mane", beard_col=(70,50,40)),
 # ── 진 ── (사마 가문 = 사마의와 같은 아비시니안)
 "사마사": dict(breed="아비시니안 고양이", fur=(168,104,66), fur_d=(130,76,44), ear=(150,90,54), ear_in=(236,170,150),
   muzzle=(240,222,198), belly=(240,222,198), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(116,66,38),
   brow="angry", brow_w=0.9, brow_col=BLACK, eye="sharp", eyepatch=True,
   hat="cap", hat_col=JIN["main"], hat_d=JIN["dark"], orn=SILV,
   robe=JIN["main"], belt=SILV, robe_trim=SILV, faction=JIN, beard=None, beard_col=None),
 "사마소": dict(breed="아비시니안 고양이", fur=(186,120,76), fur_d=(146,88,52), ear=(166,102,62), ear_in=(236,170,150),
   muzzle=(240,222,198), belly=(240,222,198), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(126,74,42),
   brow="sly", brow_w=0.8, brow_col=BLACK, eye="smug", mouth="smirk",
   hat="lunjin", hat_col=JIN["deep"], hat_d=JIN["dark"], orn=SILV,
   robe=JIN["main"], belt=GOLD, robe_trim=GOLD, faction=JIN, beard=None, beard_col=None),
 "사마염": dict(breed="아비시니안 고양이", fur=(196,134,88), fur_d=(156,100,62), ear=(176,114,72), ear_in=(240,180,160),
   muzzle=(244,228,206), belly=(244,228,206), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True, stripes=(140,88,52),
   brow="gentle", brow_col=(90,56,36), mouth="cat",
   hat="mian", hat_col=JIN["main"], hat_d=(20,50,56), orn=GOLD,
   robe=JIN["main"], belt=GOLD, robe_trim=GOLD, faction=JIN, beard=None, beard_col=None),
 "등애": dict(breed="버니즈 마운틴 독", fur=(44,40,44), fur_d=(30,28,32), ear=(36,32,36), ear_in=None,
   muzzle=(250,248,244), belly=(250,248,244), mask=None, ears="flop", tail=-1, pattern="blaze",
   brow="sad", brow_col=(196,120,60), eye_col=(250,240,220), mouth="flat",
   hat="helmet", hat_col=SILV, hat_d=JIN["main"], orn=GOLD, plume=JIN["main"],
   robe=JIN["main"], belt=(196,120,60), faction=JIN, beard=None, beard_col=None),
 "문앙": dict(breed="아키타견", fur=(222,168,108), fur_d=(186,132,76), ear=(196,140,84), ear_in=(246,226,206),
   muzzle=(252,244,232), belly=(252,244,232), mask="shiba", ears="up", tail=1,
   brow="brave", brow_w=1.3, brow_col=BLACK, mouth="grin",
   hat="helmet", hat_col=SILV, hat_d=JIN["main"], orn=GOLD, plume=JIN["main"],
   robe=JIN["main"], belt=GOLD, robe_trim=SILV, faction=JIN, beard=None, beard_col=None),
 "종회": dict(breed="턱시도 고양이", fur=(46,44,50), fur_d=(30,28,34), ear=(36,34,40), ear_in=(220,160,160),
   muzzle=(250,250,252), belly=(250,250,252), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True,
   brow="sly", brow_col=(250,250,252), eye="smug", eye_col=(240,200,90), mouth="smirk",
   hat="cap", hat_col=JIN["deep"], hat_d=(16,46,52), orn=GOLD,
   robe=JIN["main"], belt=GOLD, robe_trim=GOLD, faction=JIN, beard=None, beard_col=None),
}
# 진영 바뀐 모습 (어른 이후)
alt=dict(DOGS["사마의"]); alt.update(hat="mian", hat_col=JIN["main"], hat_d=(20,50,56), orn=GOLD, robe=JIN["main"], belt=GOLD, robe_trim=GOLD, faction=JIN)
NEW["사마의(진)"]=alt
alt=dict(NEW["하후패"]); alt.update(hat_col=SHU["main"], hat_d=SHU["dark"], robe=SHU["main"], faction=SHU)
NEW["하후패(촉)"]=alt
DOGS.update(NEW)
if __name__=="__main__":
    O='/mnt/user-data/outputs/'
    sheet(["장합","이전","악진","하후패","하후패(촉)"], O+"new3_wei.png")
    sheet(["관평","마대","주창","정보","주태","한당"], O+"new3_shu_wu.png")
    sheet(["화타","동탁","사마의(진)","사마사","사마소","사마염","등애","종회"], O+"new3_sp_jin.png")
