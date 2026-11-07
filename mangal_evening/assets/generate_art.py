"""Original hand-coded 320x130 pixel art; rendered 2x with nearest neighbor.
Run: python assets/generate_art.py
Pillow is needed only to regenerate the art, not to play the Godot game.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import math, random
R = random.Random(1207)
W, H = 320, 130
im = Image.new('RGB', (W, H))
d = ImageDraw.Draw(im)
# Early-evening sky, horizontal dither and distant cloud strips
for y in range(0, 82):
    t=y/82
    color=(int(20+60*t),int(35+36*t),int(63+39*t))
    d.line((0,y,W,y),fill=color)
for i in range(110):
    x=R.randrange(W); y=R.randrange(4,69)
    if R.random()<0.55:
        d.point((x,y),fill=R.choice(['#b8c3b5','#e5cba2','#a6adc9']))
# setting moon behind cloud
for rad,color in [(15,'#687587'),(11,'#95a1a2'),(8,'#f5d9a9')]:
    x,y=254,24
    d.ellipse((x-rad,y-rad,x+rad,y+rad),fill=color)
for x,y,w in [(18,35,42),(72,17,33),(177,31,54)]:
    d.polygon([(x,y+4),(x+8,y),(x+w-9,y+1),(x+w,y+5),(x+20,y+5)],fill='#49516b')
    d.line([(x+3,y+4),(x+w-2,y+4)],fill='#56586f')
# distant hills
for layer, fill, points in [
    (0,'#384d59',[(0,86),(0,65),(28,52),(56,69),(81,54),(116,74),(144,59),(190,75),(216,48),(243,70),(276,56),(320,77),(320,95)]),
    (1,'#273d43',[(0,96),(0,78),(17,71),(47,83),(70,70),(92,86),(120,65),(158,80),(185,68),(214,82),(249,64),(274,81),(293,69),(320,75),(320,99)])
]:
    d.polygon(points,fill=fill)
# ground
for y in range(82,H):
    t=(y-82)/(H-82)
    col=(int(35+12*t),int(65-9*t),int(48-5*t))
    d.line((0,y,W,y),fill=col)
for i in range(480):
    x=R.randrange(W);y=R.randrange(85,H)
    d.point((x,y),fill=R.choice(['#415b3e','#526c43','#304838','#665e42','#394f32']))
# stone path winding toward foreground
path=[(117,130),(249,130),(214,107),(168,98),(137,106)]
d.polygon(path,fill='#55534a')
for i in range(180):
    x=R.randrange(121,249);y=R.randrange(103,130)
    if im.getpixel((x,y))[0] in range(65,100):
        d.point((x,y),fill=R.choice(['#7e7461','#494943','#625d51']))
# forest pines

def pine(x,y,s=1):
    d.rectangle((x-2*s,y-3*s,x+2*s,y+16*s),fill='#282e27')
    for n in range(3):
        top=y-21*s+n*10*s
        half=(9+n*3)*s
        d.polygon([(x,top),(x-half,top+19*s),(x+half,top+19*s)],fill=['#153c37','#163b38','#1b4a3c'][n])
        d.line((x-2*s,top+8*s,x-4*s,top+15*s),fill='#315247',width=s)
for args in [(10,74,2),(24,78,1),(41,71,2),(284,76,2),(309,76,2),(296,73,1),(116,78,1),(225,79,1)]:
    pine(*args)
# fence running behind foreground
d.rectangle((0,87,320,90),fill='#453a33')
d.rectangle((0,99,320,102),fill='#382f2c')
for x in range(0,320,13):
    d.rectangle((x,81,x+7,102),fill='#73543f')
    d.polygon([(x,81),(x+4,77),(x+7,81)],fill='#7f5b40')
    d.line((x+2,84,x+2,97),fill='#876447')
    d.rectangle((x+6,90,x+7,91),fill='#c09969')
# shed behind trees
d.rectangle((212,66,257,99),fill='#55473e')
d.polygon([(204,67),(232,49),(264,67)],fill='#362d32')
d.polygon([(212,65),(232,53),(254,65)],fill='#62433a')
for x in range(218,253,7):
    d.line((x,69,x,98),fill='#644e42')
d.rectangle((234,77,250,98),fill='#343039')
d.rectangle((237,80,247,91),fill='#d09d61')
d.line((242,80,242,91),fill='#614a41')
# string lights across the porch
d.line((3,38,92,55,184,39,286,50),fill='#292934',width=1)
for x,y in [(18,41),(40,44),(64,48),(89,53),(120,49),(149,45),(179,40),(211,43),(242,45),(275,49)]:
    d.line((x,y,x,y+4),fill='#232a2d')
    d.ellipse((x-2,y+2,x+2,y+6),fill='#f4c16e')
    d.point((x,y+4),fill='#fff0b1')
# Logs and pile at left
d.ellipse((11,110,52,124),fill='#332c2b')
for i in range(4):
    y=105+i*4
    d.rectangle((17+i%2*3,y,43+i%2*3,y+5),fill=['#654a36','#876444'][i%2])
    d.ellipse((12+i%2*3,y,21+i%2*3,y+5),fill='#b27e4c')
# wooden bench left
d.polygon([(25,99),(94,99),(100,106),(28,106)],fill='#9f6a3d')
d.rectangle((30,105,35,126),fill='#513b32')
d.rectangle((89,105,95,126),fill='#513b32')
d.line((30,99,93,99),fill='#c48b51',width=2)
# picnic table front left with plate, cup, bread
d.rectangle((24,113,117,119),fill='#2d2f30')
d.polygon([(25,100),(110,100),(125,110),(32,110)],fill='#a66b45')
d.polygon([(25,100),(110,100),(109,103),(27,103)],fill='#c48853')
for x in range(34,113,13):
    d.line((x,102,x+5,109),fill='#885b3c')
d.polygon([(33,110),(37,110),(33,128),(28,128)],fill='#624735')
d.polygon([(112,110),(119,110),(126,129),(121,129)],fill='#624735')
# table dish
d.ellipse((56,101,80,108),fill='#d5c9a6')
d.ellipse((59,102,78,106),fill='#7e7b65')
for x,y in [(63,102),(68,104),(74,103)]:
    d.rectangle((x,y,x+4,y+2),fill='#ad6b3c')
# loaf
d.ellipse((85,99,104,107),fill='#e2a96a')
d.arc((85,99,104,107),180,330,fill='#f1cc88')
# thermos on table
d.rectangle((40,88,47,102),fill='#85908d')
d.rectangle((41,85,46,89),fill='#c5cdba')
d.line((42,92,43,100),fill='#d7e0cd')
# person on bench, approximate chunky sprite
# boots and trousers
d.polygon([(81,105),(90,105),(100,120),(94,123),(83,114)],fill='#243647')
d.polygon([(71,104),(82,103),(84,121),(76,123),(73,112)],fill='#213140')
d.rectangle((77,119,88,122),fill='#322c29')
d.rectangle((95,121,105,125),fill='#322c29')
# coat
d.polygon([(70,74),(89,73),(94,84),(91,105),(72,108),(67,92)],fill='#5c6652')
d.polygon([(70,75),(80,81),(76,104),(71,106)],fill='#728064')
d.rectangle((85,82,91,105),fill='#435a4b')
# head and knit cap
d.rectangle((73,61,86,75),fill='#be8966')
d.rectangle((73,61,87,66),fill='#465b54')
d.rectangle((71,65,88,68),fill='#3f514c')
d.point((84,70),fill='#282d31')
d.rectangle((81,75,84,77),fill='#9b6c53')
# hand raised to cigarette: hand near (83,78) => 166,156
d.line((88,91,84,80),fill='#5d6a56',width=5)
d.line((84,80,83,77),fill='#c59a72',width=3)
# person's shadow
d.ellipse((66,119,113,127),fill='#26362e')
# mangal legs and metal body (x: 145..212 => 290..424)
d.polygon([(147,103),(153,103),(150,126),(146,126)],fill='#333b3a')
d.polygon([(205,103),(210,103),(214,126),(210,126)],fill='#333b3a')
d.polygon([(144,87),(213,87),(207,107),(151,107)],fill='#303738')
d.rectangle((144,88,211,103),fill='#3f4445')
d.line((148,90,209,90),fill='#737e7e',width=2)
d.line((150,104,206,104),fill='#22282b',width=2)
for x in range(152,205,11):
    d.rectangle((x,97,x+5,99),fill='#262a2b')
# upper rim
d.polygon([(143,81),(211,81),(218,89),(150,89)],fill='#191f20')
d.polygon([(149,82),(207,82),(211,85),(151,85)],fill='#424a49')
for x in range(150,214,12):
    d.point((x,84),fill='#918878')
# Radio cabinet on stack of crates
# wooden crate
d.rectangle((255,95,291,112),fill='#70583e')
d.rectangle((257,97,289,109),outline='#a07c4b',width=2)
d.line((257,97,289,109),fill='#513e32',width=2)
d.line((289,97,257,109),fill='#513e32',width=2)
d.rectangle((249,108,295,113),fill='#4e402e')
# radio x:250..291, y=68..97
d.rounded_rectangle((252,68,294,96),radius=3,fill='#a8784d',outline='#3c3534',width=2)
d.rectangle((255,71,291,90),fill='#54453c')
d.rectangle((260,74,290,82),fill='#cba96f')
d.rectangle((262,76,285,79),fill='#5b6257')
for n in range(16):
    d.point((263+n,77),fill='#eed39b' if n%3 else '#8e7755')
# speaker holes
for yy in range(84,91,3):
    for xx in range(260,280,4):
        d.rectangle((xx,yy,xx+1,yy+1),fill='#251e20')
for x in (282,289):
    d.ellipse((x-2,85,x+2,89),fill='#d7b37c',outline='#4c4038')
# long antenna
# top of antenna at (268,40) -> bottom radio at 278,70
d.line((272,69,266,44),fill='#c5c3a6',width=1)
d.point((266,43),fill='#ece7c5')
# thermos by radio
# wildflowers / grass clumps
for i in range(110):
    x=R.randrange(W);y=R.randrange(106,129)
    if x in range(140,221) or x in range(250,298) or x in range(25,129):
        continue
    h=R.randrange(2,6)
    d.line((x,y,x-1,y-h),fill=R.choice(['#64824d','#3e6947','#799052']))
    if i%14==0:
        d.point((x-1,y-h),fill='#e1ba71')
# sidewalk highlights
for x,y in [(129,122),(143,124),(239,120),(247,124),(228,116)]:
    d.rectangle((x,y,x+3,y+1),fill='#837b63')
# Foreground vignette with pixels
for x in range(0,W,4):
    d.rectangle((x,127,x+2,129),fill='#293b30')
# Native scale x2 for crisp 640x260 game space
out=Path(__file__).resolve().parent/'backyard.png'
im.resize((640,260),Image.Resampling.NEAREST).save(out,optimize=True)
print(out)
