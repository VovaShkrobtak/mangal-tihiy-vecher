"""Generate ORIGINAL offline/royalty-free radio tracks and Foley.
Requires numpy only when regenerating. Audio is bundled in the Godot project.
No streaming, network connection, copyrighted music or external API.
"""
from pathlib import Path
import math, wave
import numpy as np

SR=22050
OUT=Path(__file__).resolve().parent.parent/'audio'
OUT.mkdir(parents=True,exist_ok=True)
rg=np.random.default_rng(7331)


def wav(name, audio, normalize=.85):
    a=np.asarray(audio,dtype=np.float64)
    a=np.nan_to_num(a)
    peak=np.max(np.abs(a)) or 1
    a=np.clip(a/peak*normalize,-1,1)
    with wave.open(str(OUT/name),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2);f.setframerate(SR)
        f.writeframes((a*32767).astype('<i2').tobytes())
    print(name, f'{len(a)/SR:.1f}s')


def tone(freq, tt, kind):
    p=2*np.pi*freq*tt
    if kind=='guitar':
        return (.8*np.sin(p)+.30*np.sin(2*p)+.14*np.sin(3*p)+.07*np.sin(4*p))
    if kind=='lofi':
        return (.80*np.sin(p)+.18*np.sign(np.sin(p))+.10*np.sin(3*p))
    if kind=='square':
        return .60*np.tanh(2.5*np.sin(p))+.30*np.sin(2*p)
    if kind=='pad':
        return .64*np.sin(p)+.24*np.sin(p*.997)+.17*np.sin(p*1.003)
    if kind=='bass':
        return .9*np.sin(p)+.22*np.sin(2*p)
    return np.sin(p)


def note(buffer, start, dur, midi, vol=.20, kind='guitar', attack=.004, release=.10):
    n=int(dur*SR);pos=int(start*SR)
    if pos>=len(buffer):return
    n=min(n,len(buffer)-pos)
    if n<=0:return
    t=np.arange(n)/SR
    f=440*(2**((midi-69)/12))
    y=tone(f,t,kind)
    if kind in ('guitar','lofi','bass','square'):
        env=np.exp(-t*(2.8 if kind=='guitar' else 1.2 if kind=='lofi' else 1.5))
    else:
        env=np.ones(n)
    att=np.clip(t/max(attack,.0005),0,1)
    rel=np.clip((dur-t)/max(release,.0005),0,1)
    buffer[pos:pos+n]+=y*vol*env*att*rel


def kick(a,at,vol=.5):
    n=int(.30*SR); pos=int(at*SR)
    n=min(n,len(a)-pos)
    if n<=0:return
    t=np.arange(n)/SR
    phase=2*np.pi*(68*t+37*.013*(1-np.exp(-t/.013)))
    a[pos:pos+n]+=np.sin(phase)*np.exp(-t*17)*vol


def hat(a,at,vol=.1):
    n=int(.055*SR);pos=int(at*SR)
    n=min(n,len(a)-pos)
    if n<=0:return
    a[pos:pos+n]+=rg.normal(0,1,n)*np.exp(-np.arange(n)/SR*85)*vol


def snare(a,at,vol=.20):
    n=int(.14*SR);pos=int(at*SR)
    n=min(n,len(a)-pos)
    if n<=0:return
    t=np.arange(n)/SR
    a[pos:pos+n]+=(rg.normal(0,1,n)*.7+np.sin(2*np.pi*175*t)*.2)*np.exp(-t*30)*vol


def track(name,bpm,progression,melody,genre):
    beat=60/bpm
    bars=8
    total=bars*4*beat
    a=np.zeros(int(total*SR),dtype=np.float64)
    for bar in range(bars):
        root=progression[bar%len(progression)]
        for k,semi in enumerate([0,3 if genre=='night' else 4,7]):
            if genre=='night':
                note(a,(bar*4)*beat,4.0*beat,root+semi, .095,'pad', .24, .45)
            elif genre=='yard':
                for i in range(2): note(a,(bar*4+i*2)*beat,1.8*beat,root+12+semi,.075,'lofi',.012,.15)
            elif genre=='forest':
                for i in range(4):
                    note(a,(bar*4+i)*beat,1.0*beat,root+semi+12,.09,'guitar',.005,.09)
            else:
                note(a,(bar*4)*beat,2.0*beat,root+12+semi,.05,'pad',.08,.1)
        for beat_num in range(4):
            pos=(bar*4+beat_num)*beat
            if genre != 'night':
                note(a,pos,beat*.9,root-12,.25 if genre=='dance' else .16,'bass')
            if genre=='dance':
                kick(a,pos,.48)
                for h in range(2):hat(a,pos+h*beat/2,.14)
                if beat_num%2==1:snare(a,pos,.20)
            elif genre=='yard':
                if beat_num%2==0:kick(a,pos,.18)
                else:snare(a,pos,.10)
                hat(a,pos,.045)
            elif genre=='forest':
                if beat_num==0:kick(a,pos,.11)
                hat(a,pos,.018)
            else:
                hat(a,pos,.014)
        for i in range(8):
            mi=melody[(bar*8+i)%len(melody)]
            if mi is None:continue
            at=(bar*4+i*.5)*beat
            if genre=='night':
                note(a,at,beat*.92,mi,.048,'pad',.08,.20)
            elif genre=='dance':
                note(a,at,beat*.38,mi,.135,'square',.005,.07)
            elif genre=='forest':
                note(a,at,beat*.48,mi,.12,'guitar',.003,.08)
            else:
                note(a,at,beat*.5,mi,.11,'lofi',.01,.09)
    # Taper for seamless looping; first/last 30ms almost silent.
    fade=int(.045*SR)
    a[:fade]*=np.linspace(0,1,fade)
    a[-fade:]*=np.linspace(1,0,fade)
    wav(name,a,.72 if genre=='night' else .84)

track('station_forest.wav',96,[48,53,55,51],
      [72,76,79,None,76,74,72,None,69,72,76,77,76,None,72,None],'forest')
track('station_yard.wav',112,[57,53,50,55],
      [69,72,74,76,74,None,72,69,67,69,72,74,72,69,67,None],'yard')
track('station_night.wav',72,[45,41,48,43],
      [69,None,72,None,76,None,72,None,67,None,72,None,76,79,76,None],'night')
track('station_dance.wav',126,[45,48,41,43],
      [81,81,None,84,83,81,76,None,79,79,None,83,81,79,76,None],'dance')

n=SR*3
white=rg.normal(0,1,n)
hiss=.55*white+.45*np.concatenate([[0],white[:-1]])
hiss*=.45
for st in [.2,.51,1.37,1.83,2.44]:
    i=int(st*SR)
    hiss[i:i+150]+=rg.normal(0,.7,150)
wav('radio_static.wav',hiss,.55)
# sizzling fire: bursts of crackle
N=int(SR*.86); t=np.arange(N)/SR
h=rg.normal(0,1,N)
sizzle=(h-np.convolve(h,np.ones(5)/5,mode='same'))*np.exp(-t*2)*.38
wav('sizzle.wav',sizzle,.72)
# lighter: click + tiny hiss
N=int(SR*.32);t=np.arange(N)/SR
lighter=np.zeros(N)
lighter[:180]=rg.normal(0,1,180)*np.exp(-np.arange(180)/50)*.5
lighter[190:]+=rg.normal(0,1,N-190)*np.exp(-np.arange(N-190)/SR*12)*.06
wav('lighter.wav',lighter,.68)
# coals: fire crackle + rustling
N=int(SR*.62);t=np.arange(N)/SR
coals=rg.normal(0,1,N)*np.sin(np.minimum(t/.08,1)*np.pi/2)*np.exp(-t*3)*.25
for start in [0.06,0.12,0.3,0.39,0.5]:
    i=int(start*SR)
    coals[i:i+100]+=rg.normal(0,1,100)*np.exp(-np.arange(100)/20)*.7
wav('coals.wav',coals,.65)
# harmless 'success' bell
N=int(SR*.62);t=np.arange(N)/SR
success=.22*np.sin(2*np.pi*523.25*t)*np.exp(-t*5)
success+=.2*np.sin(2*np.pi*659.25*t)*np.exp(-t*4)
success+=.18*np.sin(2*np.pi*783.99*t)*np.exp(-t*3)
wav('success.wav',success,.62)
# Original looping evening wind & crickets. Intentionally subtle beneath the radio.
N=SR*8;t=np.arange(N)/SR
wind=rg.normal(0,1,N)
# soft filtered wind
kernel=np.ones(220)/220
wind=np.convolve(wind,kernel,mode='same')*.7
ambient=wind.copy()
for start in np.arange(.18,7.8,.67):
    dur=.22
    n=int(dur*SR);p=int(start*SR)
    tt=np.arange(n)/SR
    chirp=np.sin(2*np.pi*(2300*tt+270*tt**2))*np.sin(np.pi*tt/dur)**2*.012
    ambient[p:p+n]+=chirp
wav('night_ambience.wav',ambient,.24)
