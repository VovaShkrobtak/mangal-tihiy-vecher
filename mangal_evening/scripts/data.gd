extends RefCounted
## All tweakable gameplay content lives here.

const FOODS := {
	"Свинина": {"target": 22.0, "color": "#d08b86", "veg": false},
	"Говядина": {"target": 27.0, "color": "#ae5a5a", "veg": false},
	"Курица": {"target": 20.0, "color": "#efd4a4", "veg": false},
	"Рыба": {"target": 15.0, "color": "#b4c2bb", "veg": false},
	"Колбаски": {"target": 16.0, "color": "#bf7463", "veg": false},
	"Грибы": {"target": 11.0, "color": "#d7c49b", "veg": true},
	"Овощи": {"target": 10.0, "color": "#d9a45e", "veg": true}
}
const FOOD_ORDER := ["Свинина", "Говядина", "Курица", "Рыба", "Колбаски", "Грибы", "Овощи"]
const STATIONS := [
	{"freq": 88.4, "name": "Лесное FM", "file": "station_forest.wav", "genre": "уютная гитара"},
	{"freq": 93.7, "name": "Дворовая волна", "file": "station_yard.wav", "genre": "ретро-мелодии"},
	{"freq": 100.2, "name": "Полночь", "file": "station_night.wav", "genre": "ночной эмбиент"},
	{"freq": 106.8, "name": "Искра", "file": "station_dance.wav", "genre": "электронная музыка"}
]
