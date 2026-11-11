import sys, runpy
L = runpy.run_path('/home/claude/art/new3/chars.py', run_name='lib')
globals().update({k: v for k, v in L.items() if not k.startswith('__')})
HAN = dict(main=(222, 124, 44), dark=(168, 86, 28), deep=(140, 70, 24))   # 한 = 주황
CHU = dict(main=(62, 58, 72), dark=(40, 38, 48), deep=(30, 28, 36))       # 초 = 먹색
RED = (196, 48, 52)
NEW4 = {
 "서황": dict(breed="블루 그레이트 데인", fur=(116, 124, 140), fur_d=(88, 96, 112), ear=(96, 104, 120), ear_in=(190, 160, 160),
   muzzle=(150, 156, 168), belly=(170, 176, 186), mask=None, ears="up", tail=-1, fat=1.04,
   brow="brave", brow_w=1.25, brow_col=(36, 38, 46), mouth="flat",
   hat="helmet", hat_col=SILV, hat_d=WEI["main"], orn=GOLD, knob=True,
   robe=WEI["main"], belt=GOLD, robe_trim=SILV, faction=WEI, beard="short", beard_col=(60, 64, 76)),
 # ── 한 (유방 편) ──
 "유방": dict(breed="옐로 래브라도", fur=(238, 208, 152), fur_d=(206, 170, 112), ear=(214, 176, 116), ear_in=None,
   muzzle=(250, 236, 210), belly=(250, 236, 210), mask=None, ears="droop", tail=1,
   brow="gentle", brow_col=(120, 84, 48), eye="happy", mouth="smile",
   hat="mian", hat_col=HAN["main"], hat_d=HAN["dark"], orn=GOLD,
   robe=HAN["main"], belt=GOLD, robe_trim=GOLD, faction=HAN, beard="neat", beard_col=(110, 76, 44)),
 "한신": dict(breed="그레이하운드", fur=(196, 190, 186), fur_d=(160, 152, 150), ear=(150, 142, 140), ear_in=(220, 180, 176),
   muzzle=(232, 228, 224), belly=(240, 236, 232), mask=None, ears="semi", tail=-1, fat=0.92,
   brow="calm", brow_col=(60, 56, 56), eye="sharp", mouth="flat",
   hat="plume", hat_col=SILV, hat_d=HAN["main"], orn=RED, plume=HAN["main"],
   robe=HAN["main"], belt=SILV, robe_trim=SILV, faction=HAN, beard=None, beard_col=None),
 "번쾌": dict(breed="세인트 버나드", fur=(250, 246, 238), fur_d=(214, 206, 194), ear=(176, 92, 48), ear_in=None,
   muzzle=(252, 250, 246), belly=(252, 250, 246), mask=None, ears="flop", tail=-1, pattern="patch", pat_col=(176, 92, 48), fat=1.2,
   brow="angry", brow_w=1.3, brow_col=(90, 48, 30), mouth="tongue",
   hat="band", hat_col=HAN["main"], hat_d=HAN["dark"], orn=GOLD, band_tails=True,
   robe=HAN["dark"], belt=GOLD, faction=HAN, beard="mane", beard_col=(132, 70, 38)),
 "영포": dict(breed="브린들 핏불", fur=(150, 108, 72), fur_d=(112, 78, 50), ear=(100, 68, 44), ear_in=(210, 160, 150),
   muzzle=(244, 230, 214), belly=(244, 230, 214), mask=None, ears="semi", tail=-1, stripes=(72, 48, 34),
   brow="angry", brow_w=1.2, brow_col=(40, 30, 26), mouth="fangs",
   hat="band", hat_col=HAN["main"], hat_d=HAN["dark"], orn=CHU["main"],
   robe=HAN["main"], belt=CHU["main"], faction=HAN, beard=None, beard_col=None),
 "조참": dict(breed="샤페이", fur=(214, 158, 104), fur_d=(178, 122, 74), ear=(180, 124, 76), ear_in=None,
   muzzle=(226, 176, 128), belly=(232, 190, 146), mask=None, ears="fold", tail=1, fat=1.1,
   brow="calm", brow_col=(130, 86, 52), eye="smug", mouth="smile",
   hat="cap", hat_col=HAN["main"], hat_d=HAN["dark"], orn=GOLD,
   robe=HAN["main"], belt=GOLD, faction=HAN, beard=None, beard_col=None),
 "장량": dict(breed="랙돌 고양이", fur=(246, 240, 230), fur_d=(214, 204, 190), ear=(150, 124, 108), ear_in=(240, 190, 190),
   muzzle=(252, 250, 246), belly=(252, 250, 246), mask=None, ears="cat", tail=1, tail_type="curl", tail_col=(150, 124, 108),
   whiskers=True, fluffy=True, eye_col=(90, 150, 210), lash=2, lash_col=(70, 120, 210),
   brow="gentle", brow_w=0.8, brow_col=(120, 100, 88), mouth="cat",
   hat="lunjin", hat_col=HAN["main"], hat_d=HAN["dark"], orn=GOLD,
   robe=(246, 236, 214), belt=HAN["main"], robe_trim=HAN["main"], faction=HAN, beard=None, beard_col=None),
 "소하": dict(breed="고등어 태비 고양이", fur=(176, 172, 164), fur_d=(140, 136, 128), ear=(150, 146, 138), ear_in=(236, 180, 176),
   muzzle=(240, 236, 228), belly=(240, 236, 228), mask=None, ears="cat", tail=-1, tail_type="curl", whiskers=True, stripes=(96, 92, 88),
   brow="calm", brow_col=(70, 66, 62), eye="dot", mouth="cat",
   hat="cap", hat_col=HAN["dark"], hat_d=HAN["deep"], orn=GOLD,
   robe=HAN["main"], belt=GOLD, robe_trim=GOLD, faction=HAN, beard="thin", beard_col=(90, 86, 80)),
 "여치": dict(breed="봄베이 고양이", fur=(44, 40, 48), fur_d=(28, 26, 32), ear=(36, 32, 40), ear_in=(200, 140, 150),
   muzzle=(70, 64, 74), belly=(62, 58, 68), mask=None, ears="cat", tail=1, tail_type="curl", whiskers=True,
   brow="elegant", brow_w=0.7, brow_col=(240, 200, 90), eye="sharp", eye_col=(240, 196, 70), lash=1, lash_col=(240, 200, 90),
   nose_col=(200, 120, 130), mouth="smirk",
   hat="crown", hat_col=GOLD, hat_d=HAN["main"], orn=RED,
   robe=HAN["main"], belt=GOLD, robe_trim=GOLD, faction=HAN, beard=None, beard_col=None),
 # ── 초 (항우 편) ──
 "항우": dict(breed="캉갈", fur=(214, 186, 140), fur_d=(178, 150, 106), ear=(70, 58, 52), ear_in=None,
   muzzle=(246, 232, 206), belly=(240, 222, 190), mask=None, ears="flop", tail=1, fat=1.16,
   brow="angry", brow_w=1.45, brow_col=(30, 26, 26), eye="sharp", mouth="smirk",
   hat="plume", hat_col=GOLD, hat_d=CHU["main"], orn=RED, plume=RED,
   robe=CHU["main"], belt=GOLD, robe_trim=RED, faction=CHU, beard="short", beard_col=(64, 50, 42)),
 "종리매": dict(breed="말리노이즈", fur=(204, 150, 86), fur_d=(168, 116, 60), ear=(70, 56, 46), ear_in=(220, 170, 150),
   muzzle=(74, 60, 50), belly=(226, 186, 130), mask=None, ears="shepherd", tail=-1, pattern="pug", pat_col=(74, 60, 50),
   brow="brave", brow_col=(250, 236, 210), mouth="flat",
   hat="helmet", hat_col=SILV, hat_d=CHU["main"], orn=GOLD, plume=RED,
   robe=CHU["main"], belt=GOLD, robe_trim=SILV, faction=CHU, beard=None, beard_col=None),
 "용저": dict(breed="도사견", fur=(184, 92, 52), fur_d=(146, 66, 36), ear=(130, 58, 32), ear_in=None,
   muzzle=(206, 120, 80), belly=(210, 130, 90), mask=None, ears="flop", tail=-1, fat=1.15,
   brow="angry", brow_w=1.35, brow_col=(50, 30, 24), mouth="fangs",
   hat="helmet", hat_col=(110, 104, 116), hat_d=CHU["main"], orn=GOLD, knob=True,
   robe=CHU["main"], belt=RED, faction=CHU, beard="short", beard_col=(80, 40, 26)),
 "우희": dict(breed="터키시 반 고양이", fur=(252, 248, 244), fur_d=(222, 214, 208), ear=(200, 118, 76), ear_in=(246, 184, 190),
   muzzle=(255, 252, 250), belly=(255, 252, 250), mask=None, ears="cat", tail=-1, tail_type="curl", tail_col=(200, 118, 76),
   whiskers=True, fluffy=True, pattern="patch", pat_col=(200, 118, 76),
   brow="elegant", brow_w=0.55, brow_col=(120, 70, 60), lash=2, mouth="cat",
   hat="flower", hat_col=RED, hat_d=CHU["main"], orn=GOLD,
   robe=CHU["main"], belt=RED, robe_trim=GOLD, faction=CHU, beard=None, beard_col=None),
}
DOGS.update(NEW4)

def adult_sheet(names, path, cols=5, cell=340):
    from PIL import Image, ImageDraw, ImageFont
    font = ImageFont.truetype(FONT, 30); small = ImageFont.truetype(FONT, 20)
    rows = (len(names) + cols - 1) // cols
    W, H = cols * cell, rows * (cell + 70)
    img = Image.new("RGB", (W, H), (250, 243, 226)); d = ImageDraw.Draw(img)
    for i, n in enumerate(names):
        cx = (i % cols) * cell + cell / 2; top = (i // cols) * (cell + 70)
        size = int(cell * 0.92); pic = render(DOGS[n], 2, size)
        ground = top + cell - 6
        d.ellipse([cx - 95, ground - 9, cx + 95, ground + 9], fill=(232, 222, 200))
        img.paste(pic, (int(cx - 22 / 48 * size), int(ground - 43.8 / 48 * size)), pic)
        d.text((cx, top + cell + 22), n, fill=(80, 60, 50), font=font, anchor="mm")
        d.text((cx, top + cell + 52), DOGS[n]["breed"], fill=(130, 110, 95), font=small, anchor="mm")
    img.save(path)

if __name__ == "__main__":
    O = '/mnt/user-data/outputs/'
    adult_sheet(["서황", "유방", "한신", "번쾌", "영포", "조참", "장량", "소하", "여치"], O + "new4_han.png")
    adult_sheet(["항우", "종리매", "용저", "우희"], O + "new4_chu.png", cols=4)
