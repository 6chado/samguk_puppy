"""두루마리 / 공훈패 / 진·초한 뽑기 기계 색 바꾸기. python3 art5.py <out> <font>"""
import sys, os, math
sys.path.insert(0, '/home/claude/art')
import items
from items import ngon, render
from dogs import flat
import gacha_art as G
from PIL import Image, ImageDraw, ImageFont
OUT = items.OUT

def scroll(P, E):
    """오래된 두루마리: 양쪽 나무 축 + 누런 종이 + 붉은 끈"""
    paper, paper_d = (238, 214, 160), (206, 176, 120)
    P([(10, 14), (38, 14), (38, 34), (10, 34)], paper)
    P([(10, 30), (38, 30), (38, 34), (10, 34)], flat(paper_d))
    for y in (18.5, 22.5, 26.5):   # 글씨 줄
        P([(14, y), (31, y), (31, y + 1.3), (14, y + 1.3)], flat((150, 110, 70)))
    for x in (8.0, 40.0):           # 나무 축
        P([(x - 2.4, 11), (x + 2.4, 11), (x + 2.4, 37), (x - 2.4, 37)], (150, 92, 50))
        P([(x - 2.4, 11), (x - 0.6, 11), (x - 0.6, 37), (x - 2.4, 37)], flat((186, 124, 70)))
        P(ngon(x, 9.6, 3.2, 1.8, 6), (110, 64, 36))
        P(ngon(x, 38.4, 3.2, 1.8, 6), (110, 64, 36))
    P([(21, 34), (27, 34), (28.5, 42), (24, 39.5), (19.5, 42)], (204, 52, 56))   # 붉은 끈
    P(ngon(24, 34, 2.6, 2.0, 6), flat((232, 86, 84)))

def merit(P, E):
    """공훈패: 금색 육각 패 + 붉은 술"""
    P([(21, 36), (27, 36), (29, 46), (24, 43), (19, 46)], (204, 52, 56))
    P(ngon(24, 21, 15, 15, 6, math.pi / 6), (232, 176, 60))
    P(ngon(24, 21, 11, 11, 6, math.pi / 6), (250, 206, 92))
    star = []
    for i in range(10):
        r = 7.0 if i % 2 == 0 else 3.0
        a = -math.pi / 2 + i * math.pi / 5
        star.append((24 + r * math.cos(a), 21.5 + r * math.sin(a)))
    P(star, (206, 120, 40))
    P([(14, 12), (19, 9), (20, 10.6), (15.2, 13.6)], flat((255, 238, 180)))

THEMES = {
    "jin":    dict(body=(46, 146, 140), body_d=(28, 104, 100), caps=[(96, 200, 190), (250, 210, 96), (176, 230, 220), (120, 170, 240)]),
    "chohan": dict(body=(232, 150, 44), body_d=(184, 104, 26), caps=[(250, 196, 70), (226, 86, 70), (255, 226, 150), (70, 64, 80)]),
}
PINK, YEL, MINT, BLUE, PURP = (246, 132, 160), (250, 210, 96), (120, 206, 176), (120, 170, 240), (176, 140, 230)

def themed(fn, th):
    """기존 그림 함수의 색을 바꿔치기"""
    swap = {(222, 72, 74): th["body"], (176, 44, 52): th["body_d"],
            PINK: th["caps"][0], YEL: th["caps"][1], MINT: th["caps"][2], BLUE: th["caps"][3], PURP: th["caps"][0]}
    def g(P, E):
        fn(lambda pts, col: P(pts, swap.get(tuple(col) if not isinstance(col, tuple) else col, col)), E)
    return g

def capsule_th(th):
    c = th["caps"][0]; cd = tuple(int(v * 0.82) for v in c); hl = tuple(min(255, int(v * 1.12) + 20) for v in c)
    def g(P, E):
        P(ngon(24, 24, 15, 15, 12, 0.13), c)
        P([(9.2, 24), (38.8, 24), (37.4, 30.6), (33, 35.8), (24, 39), (15, 35.8), (10.6, 30.6)], (250, 248, 244))
        P([(9, 23.2), (39, 23.2), (39, 25.4), (9, 25.4)], flat(cd))
        P([(15, 15.4), (19.4, 12.0), (20.6, 13.4), (16.4, 16.8)], flat(hl))
    return g

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    out = {"item_scroll": render(scroll), "item_merit": render(merit)}
    for k, th in THEMES.items():
        out[f"gacha_machine_{k}"] = render(themed(G.machine, th), 512)
        out[f"gacha_lever_{k}"] = render(themed(G.lever, th), 512)
        out[f"capsule_{k}"] = render(capsule_th(th), 192)
    for k, im in out.items():
        im.save(f"{OUT}/{k}.png", optimize=True)
    sheet = Image.new("RGBA", (1700, 560), (250, 243, 226, 255))
    x = 0
    pad = 512 // 24; s = (512 - pad * 2) / 48; pivot = (pad + G.LEVER_PIVOT[0] * s, pad + G.LEVER_PIVOT[1] * s)
    base = Image.open('/mnt/user-data/outputs/assets_items_gacha_machine.png') if os.path.exists('/mnt/user-data/outputs/assets_items_gacha_machine.png') else None
    for k in ("jin", "chohan"):
        m = out[f"gacha_machine_{k}"].copy(); m.alpha_composite(out[f"gacha_lever_{k}"])
        sheet.alpha_composite(m, (x, 20)); x += 520
        sheet.alpha_composite(out[f"capsule_{k}"], (x, 180)); x += 200
    sheet.alpha_composite(out["item_scroll"], (x, 60)); sheet.alpha_composite(out["item_merit"], (x, 300))
    sheet.convert("RGB").save(f"{OUT}/_preview5.png")
