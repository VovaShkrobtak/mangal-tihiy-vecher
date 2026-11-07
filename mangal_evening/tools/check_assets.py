"""Cross-check project structure, audio headers, and static resource references.
This is not a substitute for running the Godot interpreter.
"""
from pathlib import Path
import re, wave, ast
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
required=['project.godot','scenes/main.tscn','scripts/game.gd','scripts/world.gd','assets/backyard.png','README.md']
for p in required:
    assert (ROOT/p).is_file(),p
for p in (ROOT/'scripts').glob('*.gd'):
    content=p.read_text()
    for resource in re.findall(r'res://([A-Za-z0-9_./-]+)',content):
        assert (ROOT/resource).exists(),f'{p.name} references missing: {resource}'
for p in (ROOT/'audio').glob('*.wav'):
    with wave.open(str(p),'rb') as w:
        assert w.getnchannels()==1 and w.getframerate()==22050 and w.getnframes()>500,p
for p in [ROOT/'assets/generate_art.py',ROOT/'tools/generate_audio.py']:
    ast.parse(p.read_text())
with Image.open(ROOT/'assets/backyard.png') as im:
    assert im.size == (640,260) and im.mode == 'RGB'
game=(ROOT/'scripts/game.gd').read_text()
for freq in ['88.4','93.7','100.2','106.8']:
    assert freq in game
for dish in ['Свинина','Говядина','Курица','Рыба','Колбаски','Грибы','Овощи']:
    assert dish in game
for fn in ['station_forest.wav','station_yard.wav','station_night.wav','station_dance.wav','radio_static.wav','night_ambience.wav','sizzle.wav','lighter.wav','success.wav','coals.wav']:
    assert (ROOT/'audio'/fn).is_file(),fn
print('PASS: references, WAV files, 7 foods, 4 stations, image and Python sources')
