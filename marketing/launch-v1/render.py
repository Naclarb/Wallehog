"""独立宣传视频工程；只读取公开演示截图，不修改应用。"""
from pathlib import Path
import math, subprocess, wave, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
W,H,FPS,DURATION = 720,1280,24,32
INK='#49343f'; MUTED='#927d87'; PINK='#d96691'; CREAM='#fffaf7'
font_path='C:/Windows/Fonts/msyh.ttc'
bold_path='C:/Windows/Fonts/msyhbd.ttc'
def font(n,b=False): return ImageFont.truetype(bold_path if b else font_path,n)
home=Image.open(ROOT/'docs/public/home.png').convert('RGB')
calc=Image.open(ROOT/'docs/public/calculator.png').convert('RGB')
pig=home.crop((601,72,710,177)).resize((320,308),Image.Resampling.LANCZOS)
wish=home.crop((35,218,747,830))
progress=home.crop((24,875,748,1247))

bg=Image.new('RGB',(W,H),CREAM)
glow=Image.new('RGBA',(W,H)); d=ImageDraw.Draw(glow)
d.ellipse((80,180,850,1000),fill=(249,196,209,105))
d.ellipse((-350,750,450,1500),fill=(249,218,187,90))
bg=Image.alpha_composite(bg.convert('RGBA'),glow.filter(ImageFilter.GaussianBlur(100))).convert('RGB')

def txt(im,s,y,size=42,color=INK,b=False,x=None):
    dr=ImageDraw.Draw(im); f=font(size,b); box=dr.textbbox((0,0),s,font=f)
    if x is None: x=(W-(box[2]-box[0]))/2
    dr.text((x,y),s,font=f,fill=color)
def rounded(im,asset,box,r=30):
    x,y,w,h=map(int,box); a=asset.resize((w,h),Image.Resampling.LANCZOS)
    mask=Image.new('L',(w,h)); ImageDraw.Draw(mask).rounded_rectangle((0,0,w,h),r,fill=255)
    im.paste(a,(x,y),mask)
def card(im,asset,x,y,w,h,r=32):
    shadow=Image.new('RGBA',(W,H)); ImageDraw.Draw(shadow).rounded_rectangle((x,y+16,x+w,y+h+16),r,fill=(92,46,66,35))
    im.paste(Image.alpha_composite(im.convert('RGBA'),shadow.filter(ImageFilter.GaussianBlur(20))).convert('RGB'))
    rounded(im,asset,(x,y,w,h),r)
def ease(v): return 1-(1-max(0,min(1,v)))**3
def coin(im,x,y,r=20):
    dr=ImageDraw.Draw(im); dr.ellipse((x-r,y-r,x+r,y+r),fill='#efc777',outline='#dfb365',width=2)
    dr.line((x,y-r*.45,x,y+r*.45),fill='#fff2c9',width=3)
def base(n):
    im=bg.copy(); txt(im,'WALLEHOG',62,19,MUTED,x=48)
    txt(im,f'{n:02d} / 06',66,16,MUTED,x=590)
    ImageDraw.Draw(im).line((48,115,672,115),fill='#ebdfe2',width=1)
    return im
def phone(im,asset,x,y,w):
    h=int(w*1688/780); dr=ImageDraw.Draw(im)
    dr.rounded_rectangle((x-8,y-8,x+w+8,y+h+8),radius=36,fill='#40363e')
    rounded(im,asset,(x,y,w,h),29)
def frame(t):
    if t<4:
        s=t; im=base(1)
        txt(im,'今天，',246,55,b=True)
        txt(im,'省下了一点点。',324,55,b=True)
        txt(im,'离喜欢的生活，又近了一点。',435,25,MUTED)
        p=int(12*math.sin(s*2)); rounded(im,pig,(210,580+p,300,289),45)
        coin(im,360,560-45*ease(s/2),19)
        txt(im,'给每一次小小的选择，一个回应。',1025,24,MUTED)
    elif t<9:
        s=t-4; im=base(2)
        txt(im,'先放一个',188,48,b=True); txt(im,'喜欢的心愿。',254,48,b=True)
        y=415+int(36*(1-ease(s/0.8)))
        card(im,wish,40,y,640,550)
        txt(im,'一副耳机，也是一份期待。',1040,27,MUTED)
    elif t<16:
        s=t-9; im=base(3)
        txt(im,'记录，只需三步。',172,43,b=True)
        labels=['点加号','输入金额','确认']
        active=min(2,int(s/2.1))
        for j,label in enumerate(labels):
            x=52+j*220; dr=ImageDraw.Draw(im)
            dr.rounded_rectangle((x,267,x+182,323),22,fill=PINK if j==active else '#f0e2e7')
            txt(im,label,280,23,'#ffffff' if j==active else MUTED,x=x+25)
        a=home if s<1.8 or s>5.4 else calc
        phone(im,a,190,375,340)
        if s<1.8:
            x,y=360,1068; rad=24+int(9*(.5+.5*math.sin(s*6)))
            ImageDraw.Draw(im).ellipse((x-rad,y-rad,x+rad,y+rad),outline=PINK,width=3)
        txt(im,'没有必填分类，也不用记完整流水。',1160,22,MUTED)
    elif t<22:
        s=t-16; im=base(4)
        txt(im,'小小一笔，',204,49,b=True); txt(im,'也值得被看见。',274,49,b=True)
        card(im,wish,90,408,540,464)
        card(im,progress,70,910,580,298)
        txt(im,'界面为演示数据 · 金额由用户自行记录',1228,16,MUTED)
    elif t<26:
        s=t-22; im=base(5)
        txt(im,'还有一只小猪，',218,45,b=True); txt(im,'陪你慢慢来。',284,45,b=True)
        rounded(im,pig,(170,477+int(9*math.sin(s*2.7)),380,366),50)
        for j in range(3):
            a=s*1.5+j*2.09; coin(im,360+170*math.cos(a),660+150*math.sin(a),12)
        txt(im,'无需账号  ·  离线使用  ·  没有广告',1010,25,MUTED)
        txt(im,'不用每天打卡。按自己的节奏就好。',1070,22,MUTED)
    else:
        s=t-26; im=base(6)
        rounded(im,pig,(270,205,180,173),30)
        txt(im,'Wallehog',437,70,b=True)
        txt(im,'把省下的小小一笔，',568,35,b=True)
        txt(im,'变成喜欢的生活。',623,35,b=True)
        dr=ImageDraw.Draw(im); dr.rounded_rectangle((190,790,530,860),35,fill=INK)
        txt(im,'Android · 早期体验',809,24,'#ffffff')
        txt(im,'从下一次小小的节省开始。',929,25,MUTED)
        txt(im,'记录节省成果，不代表实际存款或可用余额。',1168,18,MUTED)
    # 每个段落短溶入暖白；保持文字稳定可读。
    starts=[0,4,9,16,22,26]; start=max(x for x in starts if x<=t)
    fade=min(1,(t-start)/.28)
    if fade<1: im=Image.blend(bg,im,fade)
    if t>31.6: im=Image.blend(im,bg,(t-31.6)/.4)
    return im

def audio():
    sr=44100; a=np.zeros((sr*DURATION,2),dtype=np.float64)
    def note(at,hz,length,vol,pan=0):
        n=int(length*sr); ts=np.arange(n)/sr
        env=(1-np.exp(-ts*45))*np.exp(-ts*2.1)*np.minimum(1,(length-ts)*8)
        tone=(np.sin(2*np.pi*hz*ts)+.20*np.sin(2*np.pi*hz*2*ts)+.06*np.sin(2*np.pi*hz*3*ts))*env*vol
        k=int(at*sr); n=min(n,len(a)-k)
        if n>0: a[k:k+n,0]+=tone[:n]*(1-pan*.3); a[k:k+n,1]+=tone[:n]*(1+pan*.3)
    # 原创 Cmaj7 / Am7 / Fmaj7 / Gsus 和弦分解及短旋律。
    chords=[[48,55,59,64],[45,52,55,60],[41,48,52,57],[43,50,55,60]]
    for beat in range(48):
        at=beat*2/3; chord=chords[(beat//6)%4]
        midi=chord[beat%4]; note(at,440*2**((midi-69)/12),1.8,.105,(-1)**beat)
        if beat%3==0: note(at,440*2**((chord[0]-12-69)/12),2,.055)
    for at,midi in [(1.33,76),(2,79),(4,76),(5.33,74),(8,72),(10,76),(12,79),(14,81),(16,79),(18,76),(20,74),(22,72),(24,76),(26,79),(28,76),(30,72)]:
        note(at,440*2**((midi-69)/12),1.6,.065,.3)
    fade=np.minimum(1,np.arange(len(a))/sr/1.2)*np.minimum(1,(len(a)-np.arange(len(a)))/sr/1.8)
    a*=fade[:,None]; a=np.tanh(a)*.8
    with wave.open(str(OUT/'original-score.wav'),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(sr); f.writeframes((a*32767).astype('<i2').tobytes())

if __name__=='__main__':
    audio()
    ff=imageio_ffmpeg.get_ffmpeg_exe()
    command=[ff,'-y','-f','rawvideo','-vcodec','rawvideo','-s',f'{W}x{H}','-pix_fmt','rgb24','-r',str(FPS),'-i','-','-i',str(OUT/'original-score.wav'),'-vf','scale=1080:1920:flags=lanczos','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-c:a','aac','-b:a','192k','-af','loudnorm=I=-18:TP=-1.5:LRA=9','-t',str(DURATION),'-movflags','+faststart',str(OUT/'Wallehog-launch-v1.mp4')]
    p=subprocess.Popen(command,stdin=subprocess.PIPE,stderr=open(OUT/'render.log','w'))
    for i in range(FPS*DURATION):
        p.stdin.write(frame(i/FPS).tobytes())
        if i%96==0: print(f'{i/FPS:.0f}s / {DURATION}s',flush=True)
    p.stdin.close()
    if p.wait(): raise RuntimeError('ffmpeg failed: see render.log')
    contact=Image.new('RGB',(720,854),'#fffaf7')
    for j,t in enumerate([2,6,12,19,24,29]):
        thumb=frame(t).resize((240,427),Image.Resampling.LANCZOS); contact.paste(thumb,((j%3)*240,(j//3)*427))
    contact.save(OUT/'storyboard.jpg',quality=93)
    frame(29).save(OUT/'poster.jpg',quality=95)
    print('完成',flush=True)
