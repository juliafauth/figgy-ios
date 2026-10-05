#!/usr/bin/env python3
"""Original geometric sticker artwork and app icons; no downloaded assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, zipfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'Resources' / 'Catalog'
OUT.mkdir(parents=True, exist_ok=True)
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
if not Path(FONT).exists():
    FONT = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def centered(d,text,y,size=46,fill='#322346'):
    font=ImageFont.truetype(FONT,size)
    while d.textbbox((0,0),text,font=font)[2]>460:
        size-=1; font=ImageFont.truetype(FONT,size)
    d.text((256,y),text,font=font,fill=fill,anchor='mt',stroke_width=1)
def star(d,cx,cy,r,color):
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5;radius=r if i%2==0 else r*.45
        pts.append((cx+math.cos(a)*radius,cy+math.sin(a)*radius))
    d.polygon(pts,fill=color)
def make(text,color,kind,index):
    im=Image.new('RGBA',(512,512)); d=ImageDraw.Draw(im)
    ink='#322346'
    if kind=='blob':
        # A round little mood character with a scalloped white border.
        d.rounded_rectangle((50,75,462,384),radius=100,fill='white')
        d.rounded_rectangle((63,87,449,372),radius=92,fill=color)
        d.ellipse((112,257,166,278),fill='#F7A8B8'); d.ellipse((346,257,400,278),fill='#F7A8B8')
        if index%3==0:
            d.arc((154,175,209,217),180,350,fill=ink,width=10);d.arc((302,175,357,217),180,350,fill=ink,width=10)
            d.arc((208,226,304,299),0,180,fill=ink,width=10)
        elif index%3==1:
            d.ellipse((173,183,192,216),fill=ink);d.ellipse((320,183,339,216),fill=ink)
            d.ellipse((232,245,280,286),fill=ink)
        else:
            d.line((164,194,202,194),fill=ink,width=10);d.line((310,194,348,194),fill=ink,width=10)
            d.arc((227,250,286,275),180,350,fill=ink,width=8)
        star(d,75,63,25,'#F7C556');star(d,455,376,27,'#7645D9')
    elif kind=='cat':
        d.polygon([(100,184),(100,65),(217,160)],fill='white');d.polygon([(295,160),(412,65),(412,184)],fill='white')
        d.polygon([(113,180),(115,92),(212,165)],fill=color);d.polygon([(300,166),(399,92),(399,180)],fill=color)
        d.ellipse((56,134,456,386),fill='white');d.ellipse((69,147,443,372),fill=color)
        d.polygon([(120,154),(125,120),(166,158)],fill='#F3A6BF');d.polygon([(347,157),(389,120),(394,156)],fill='#F3A6BF')
        d.ellipse((162,220,181,251),fill=ink);d.ellipse((331,220,350,251),fill=ink)
        d.polygon([(244,257),(268,257),(256,270)],fill=ink)
        d.arc((223,253,257,287),0,140,fill=ink,width=6);d.arc((255,253,289,287),40,180,fill=ink,width=6)
        for dy in (0,18):
            d.line((89,261+dy,142,268+dy),fill=ink,width=5);d.line((370,268+dy,423,261+dy),fill=ink,width=5)
        star(d,451,99,25,'#F7C556')
    else:
        d.rounded_rectangle((57,60,455,367),radius=44,fill='white')
        d.rounded_rectangle((72,73,440,352),radius=34,fill=color)
        d.rounded_rectangle((133,118,379,278),radius=22,fill='#322346')
        d.rounded_rectangle((147,130,365,261),radius=13,fill='#F7F0FF')
        d.polygon([(117,286),(395,286),(421,311),(91,311)],fill='#322346')
        d.line((180,172,159,193,180,214),fill='#7645D9',width=9)
        d.line((332,172,353,193,332,214),fill='#7645D9',width=9)
        d.line((278,155,233,229),fill='#E47FA9',width=9)
        star(d,431,72,25,'#F7C556')
    # Full rectangular text ribbon deliberately preserves every word.
    d.rounded_rectangle((25,390,487,478),radius=27,fill='white')
    d.rounded_rectangle((35,400,477,468),radius=20,fill=ink)
    centered(d,text,414,39,fill='white')
    return im
packs=[
 ('mood','Só reações','Reações','CDB9F4','blob',['AMEI','SOCORRO','TÔ DE BOA','SIM, SIM','SEM PALAVRAS','HOJE NÃO']),
 ('cats','Gatinhos & carinho','Fofo','C0E5D2','cat',['BOM DIA','SAUDADE','TE ADORO','OBRIGADA','BOA NOITE','TUDO BEM']),
 ('study','Modo universitária','Estudos','FFD996','laptop',['MAIS UM CAFÉ','COMPILOU!','TÔ ESTUDANDO','DEU BUG','EU CONSIGO','PRAZO HOJE'])
]
catalog=[]
for pid,name,category,color,kind,texts in packs:
    files=[]
    for i,text in enumerate(texts):
        filename=f'{pid}-{i+1}.png';make(text,'#'+color,kind,i).save(OUT/filename,optimize=True);files.append(filename)
    catalog.append(dict(id=pid,name=name,author='Figgy Originals',category=category,color=color,files=files,titles=texts))
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
assets=ROOT/'Resources'/'Assets.xcassets';assets.mkdir(exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info':{'version':1,'author':'xcode'}}))
icon=Image.new('RGB',(1024,1024),'#D9C4FA');d=ImageDraw.Draw(icon)
d.rounded_rectangle((172,172,852,852),radius=210,fill='#7645D9')
d.rounded_rectangle((194,194,830,830),radius=190,fill='#BDE9D1')
d.ellipse((353,378,403,455),fill='#322346');d.ellipse((621,378,671,455),fill='#322346')
d.arc((389,452,635,661),0,180,fill='#322346',width=32)
d.ellipse((293,477,360,519),fill='#F49CBA');d.ellipse((664,477,731,519),fill='#F49CBA')
star(d,794,224,95,'#FFE69B')
app=assets/'AppIcon.appiconset';app.mkdir(exist_ok=True);icon.save(app/'AppIcon.png')
(app/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'version':1,'author':'xcode'}}))
accent=assets/'AccentColor.colorset';accent.mkdir(exist_ok=True)
(accent/'Contents.json').write_text(json.dumps({'colors':[{'idiom':'universal','color':{'color-space':'srgb','components':{'red':'0.463','green':'0.271','blue':'0.851','alpha':'1.000'}}}],'info':{'version':1,'author':'xcode'}}))
# iMessage icon set needs rectangular template dimensions.
massets=ROOT/'Resources'/'MessagesAssets.xcassets';massets.mkdir(exist_ok=True)
(massets/'Contents.json').write_text(json.dumps({'info':{'version':1,'author':'xcode'}}))
micon=massets/'iMessage App Icon.stickersiconset';micon.mkdir(exist_ok=True)
entries=[]
for idiom,size,scale in [('iphone','29x29',2),('iphone','29x29',3),('iphone','60x45',2),('iphone','60x45',3),('ipad','29x29',2),('ipad','67x50',2),('ipad','74x55',2),('ios-marketing','1024x768',1)]:
    w,h=map(int,size.split('x'));filename=f'{idiom}-{w}-{h}-{scale}.png'
    frame=Image.new('RGB',(w*scale,h*scale),'#D9C4FA')
    face=icon.resize((h*scale,h*scale),Image.Resampling.LANCZOS);frame.paste(face,((w-h)*scale//2,0));frame.save(micon/filename)
    entries.append(dict(idiom=idiom,size=size,scale=f'{scale}x',filename=filename))
(micon/'Contents.json').write_text(json.dumps({'images':entries,'info':{'version':1,'author':'xcode'}}))
# A portable pack to try import/export with three existing original stickers.
example=ROOT/'Resources'/'Example.figpack'
manifest={'format':'figgy-pack','version':1,'name':'Meu primeiro pack','author':'Figgy Originals','color':'CDB9F4','stickers':[]}
with zipfile.ZipFile(example,'w',zipfile.ZIP_DEFLATED) as z:
    for i in range(3):
        file=f'images/example-{i}.png';z.writestr(file,(OUT/f'mood-{i+1}.png').read_bytes())
        manifest['stickers'].append({'file':file,'title':packs[0][-1][i],'emojis':[]})
    z.writestr('manifest.json',json.dumps(manifest,ensure_ascii=False))
print('Generated 18 original stickers, app icons, catalog and example pack.')
