import sys, math
sys.argv=['x','/mnt/user-data/outputs/items5','/mnt/user-data/outputs/main.ttf']
sys.path.insert(0,'/home/claude/art')
import items
from items import ngon, render
from dogs import flat

def scroll(P0, E):
    rot = math.radians(-10)
    c, s = math.cos(rot), math.sin(rot)
    def P(pts, col):
        P0([(24 + (x - 24) * c - (y - 24) * s, 24 + (x - 24) * s + (y - 24) * c) for x, y in pts], col)
    paper, paper_d, paper_l = (244, 224, 172), (214, 186, 128), (252, 240, 206)
    # 펼쳐진 종이
    P([(11, 13), (37, 12), (37, 36), (11, 35)], paper)
    P([(11, 31.5), (37, 32), (37, 36), (11, 35)], flat(paper_d))
    P([(13, 13.6), (22, 13.3), (16, 17)], flat(paper_l))
    # 세로 글씨 (붓글씨 느낌, 4줄)
    ink = flat((70, 52, 44))
    for i, x in enumerate((31.5, 27.5, 23.5, 19.5)):
        y = 16.0
        for j, h in enumerate((2.6, 1.6, 3.0, 2.0) if i % 2 == 0 else (1.8, 3.0, 1.6, 2.4)):
            if y + h > 30:
                break
            P([(x - 0.75, y), (x + 0.75, y + 0.2), (x + 0.6, y + h), (x - 0.6, y + h - 0.2)], ink)
            y += h + 1.1
    # 빨간 낙관 도장
    P([(13.6, 25.5), (17.6, 25.4), (17.7, 29.6), (13.7, 29.7)], (206, 52, 54))
    P([(14.4, 26.3), (16.8, 26.2), (16.9, 28.8), (14.5, 28.9)], flat((236, 104, 96)))
    # 왼쪽 축 (나무 막대 + 금 꼭지)
    P([(7.6, 10.4), (11.6, 10.3), (11.8, 37.7), (7.8, 37.8)], (122, 70, 40))
    P([(7.6, 10.4), (9.2, 10.4), (9.4, 37.8), (7.8, 37.8)], flat((160, 98, 56)))
    for y in (8.6, 39.4):
        P(ngon(9.7, y, 2.9, 1.7, 8), (238, 186, 70))
        P(ngon(9.1, y - 0.4, 1.1, 0.6, 6), flat((255, 230, 150)))
    # 오른쪽: 돌돌 말린 종이 + 축
    P([(35.5, 10.6), (41.5, 10.4), (41.8, 37.6), (35.8, 37.9)], paper_d)
    P([(35.5, 10.6), (37.6, 10.6), (37.9, 37.8), (35.8, 37.9)], flat(paper))
    P(ngon(38.6, 10.5, 3.1, 1.3, 10), flat(paper_l))
    P(ngon(38.6, 10.5, 1.3, 0.55, 8), flat((150, 110, 70)))
    for y in (8.4, 39.6):
        P(ngon(38.7, y, 2.6, 1.5, 8), (238, 186, 70))
    # 붉은 끈 + 술
    P([(36.0, 22.6), (41.6, 22.4), (41.6, 24.6), (36.0, 24.8)], (196, 46, 52))
    P([(41.0, 23.4), (45.0, 27.0), (44.0, 33.5), (42.6, 33.5), (42.4, 27.6), (40.6, 25.2)], (214, 58, 60))
    P([(43.4, 33.0), (44.6, 33.0), (45.0, 36.0), (43.0, 36.0)], flat((230, 96, 90)))

im = render(scroll)
im.save('/mnt/user-data/outputs/items5/item_scroll.png', optimize=True)
from PIL import Image
big = render(scroll, 480); bg = Image.new('RGBA', big.size, (250, 243, 226, 255)); bg.alpha_composite(big); bg.convert('RGB').save('/tmp/claude-0/-home-claude/d555b348-bc7b-58ba-bd6c-7a38eca9feac/scratchpad/scroll2.png')
