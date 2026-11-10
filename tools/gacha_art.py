"""뽑기 기계 (몸통 / 손잡이 따로) + 캡슐. 사용: python3 gacha_art.py <출력폴더> <폰트.ttf>
손잡이(gacha_lever.png)는 기계와 같은 48칸 좌표계 → 겹쳐 놓고 회전축 (38, 31) 기준으로 돌림"""
import math
import os

from PIL import Image

import items  # noqa: E402
from items import ngon, render
from dogs import flat

OUT = items.OUT
LEVER_PIVOT = (39.4, 34)


def inside(poly, x, y, margin=0.0):
    """볼록다각형 안쪽인지 (가장자리에서 margin 만큼 더 안쪽)"""
    n = len(poly)
    for i in range(n):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
        ex, ey = x1 - x0, y1 - y0
        cross = ex * (y - y0) - ey * (x - x0)
        if cross < margin * math.hypot(ex, ey):
            return False
    return True


def machine(P, E):
    red, red_d = (222, 72, 74), (176, 44, 52)
    # 유리 돔 (크게) — 아랫부분은 빨간 받침대 뒤로 들어감
    P(ngon(22, 17.0, 16.0, 15.0, 14, 0.11), (206, 232, 244))
    # 안에 든 캡슐들 (아래쪽에 소복이, 일부는 받침대에 가려짐)
    caps = [(14.4, 25.2, (246, 132, 160)), (19.2, 27.0, (250, 210, 96)), (24.8, 27.0, (120, 206, 176)),
            (29.6, 25.2, (120, 170, 240)),
            (13.4, 21.0, (120, 206, 176)), (19.0, 22.0, (246, 132, 160)), (24.8, 22.2, (250, 210, 96)),
            (30.4, 21.0, (246, 132, 160)), (10.3, 17.6, (250, 210, 96)), (33.9, 17.4, (120, 206, 176)),
            (16.0, 16.6, (120, 170, 240)), (22.0, 17.0, (176, 140, 230)), (28.0, 16.4, (120, 206, 176)),
            (19.2, 11.8, (250, 210, 96)), (25.4, 11.6, (246, 132, 160))]
    globe = ngon(22, 17.0, 16.0, 15.0, 14, 0.11)
    for i, (x, y, col) in enumerate(caps):
        assert all(inside(globe, px, py, 0.6) for px, py in ngon(x, y, 3.0, 3.0, 7, i * 0.4)), (x, y)
        P(ngon(x, y, 3.0, 3.0, 7, i * 0.4), col)
        P([(x - 2.8, y + 0.3), (x + 2.8, y + 0.3), (x + 2.3, y + 1.9), (x - 2.3, y + 1.9)], flat((250, 248, 244)))
    # 유리 반짝임
    P([(10.6, 11.0), (14.6, 6.2), (16.0, 7.2), (12.2, 12.4)], flat((250, 254, 255)))
    P([(9.6, 14.0), (10.6, 12.6), (11.4, 13.2), (10.4, 14.8)], flat((250, 254, 255)))
    # 뚜껑
    P([(16, 2.6), (28, 2.6), (29.2, 4.6), (14.8, 4.6)], red_d)
    P(ngon(22, 1.8, 2.4, 1.6, 6), red)
    # 받침
    P([(4, 43), (40, 43), (41, 47), (3, 47)], red_d)
    # 몸통 (돔 아래를 덮음)
    P([(8, 28.4), (36, 28.4), (38.4, 43.4), (5.6, 43.4)], red)
    P([(6.4, 27.0), (37.6, 27.0), (38.0, 30.4), (6.0, 30.4)], red_d)
    # 손잡이 축 받침 (오른쪽 옆)
    P(ngon(LEVER_PIVOT[0], LEVER_PIVOT[1], 2.6, 2.6, 6, 0.3), (176, 182, 196))
    # 동전 다이얼 (가운데 금색 손잡이)
    P(ngon(22, 34.6, 4.2, 4.2, 8, 0.2), (246, 200, 86))
    P([(21.2, 31.2), (22.8, 31.2), (22.8, 38.0), (21.2, 38.0)], flat((206, 150, 50)))
    # 캡슐 나오는 구멍 + 덮개
    P([(15, 39.0), (29, 39.0), (29, 42.6), (15, 42.6)], (70, 40, 46))
    P([(15, 39.0), (29, 39.0), (28.2, 40.6), (15.8, 40.6)], flat((120, 74, 80)))


def lever(P, E):
    px, py = LEVER_PIVOT
    P([(px - 0.85, py), (px + 0.85, py), (px + 0.85, py - 13.6), (px - 0.85, py - 13.6)], (196, 202, 214))
    P(ngon(px, py - 15.2, 2.9, 2.9, 7, 0.2), (222, 72, 74))
    P(ngon(px - 0.8, py - 16.0, 0.9, 0.9, 5), flat((250, 170, 170)))


def capsule(P, E):
    P(ngon(24, 24, 15, 15, 12, 0.13), (246, 132, 160))
    P([(9.2, 24), (38.8, 24), (37.4, 30.6), (33, 35.8), (24, 39), (15, 35.8), (10.6, 30.6)], (250, 248, 244))
    P([(9, 23.2), (39, 23.2), (39, 25.4), (9, 25.4)], flat((214, 96, 126)))
    P([(15, 15.4), (19.4, 12.0), (20.6, 13.4), (16.4, 16.8)], flat((255, 214, 224)))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    m = render(machine, 512)
    lv = render(lever, 512)
    m.save(f"{OUT}/gacha_machine.png", optimize=True)
    lv.save(f"{OUT}/gacha_lever.png", optimize=True)
    render(capsule, 192).save(f"{OUT}/capsule.png", optimize=True)
    # 미리보기: 손잡이 올림 / 내림
    pad = 512 // 24
    s = (512 - pad * 2) / 48
    pivot = (pad + LEVER_PIVOT[0] * s, pad + LEVER_PIVOT[1] * s)
    sheet = Image.new("RGBA", (512 * 2 + 192 + 80, 512), (250, 243, 226, 255))
    for i, ang in enumerate((0, -150)):
        frame = m.copy()
        frame.alpha_composite(lv.rotate(ang, center=pivot, resample=Image.BICUBIC))
        sheet.alpha_composite(frame, (552 * i, 0))
    sheet.alpha_composite(render(capsule, 192), (1024 + 80, 160))
    sheet.convert("RGB").save(f"{OUT}/_gacha_preview.png")
    print("pivot px", pivot)
