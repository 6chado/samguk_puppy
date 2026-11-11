import sys
sys.argv=['x','/mnt/user-data/outputs/items5','/mnt/user-data/outputs/main.ttf']
sys.path.insert(0,'/home/claude/art')
import items2
from items import render, ngon
from dogs import flat
from PIL import Image
GOLD = {(255,178,158):(250,206,92),(255,204,150):(255,226,130),(246,120,132):(236,170,50),(232,96,114):(214,142,30),
        (252,146,146):(246,190,72),(232,106,120):(214,146,36),(255,236,228):(255,250,220)}
def golden(P,E):
    def P2(pts,col):
        key=None
        # flat() 결과도 같은 튜플이면 바꿈
        c3=tuple(col[:3])
        P(pts, (*GOLD[c3], *col[3:]) if c3 in GOLD else col)
    items2.peach(P2,E)
    # 반짝 별 두 개
    for cx,cy,r in ((36.5,30.5,3.2),(12.8,27.6,2.2)):
        P([(cx,cy-r),(cx+r*0.3,cy-r*0.3),(cx+r,cy),(cx+r*0.3,cy+r*0.3),(cx,cy+r),(cx-r*0.3,cy+r*0.3),(cx-r,cy),(cx-r*0.3,cy-r*0.3)],flat((255,255,240)))
im=render(golden); im.save('/mnt/user-data/outputs/items5/item_golden_peach.png',optimize=True)
bg=Image.new('RGBA',(400,200),(250,243,226,255)); bg.alpha_composite(render(items2.peach),(0,0)); bg.alpha_composite(im,(200,0)); bg.convert('RGB').save('/tmp/claude-0/-home-claude/d555b348-bc7b-58ba-bd6c-7a38eca9feac/scratchpad/gp.png')
