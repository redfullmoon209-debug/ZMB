extends RefCounted

const SLOTS = ["head","armor","gloves","legs","boots","main","off","pet","bracelet1","ring1","necklace","ring2","bracelet2"]
const TYPES = ["Helm","Armor","Gloves","Leggings","Boots","Sword","Shield","Loot pet","Bracelet","Ring","Necklace","Ring","Bracelet"]
const ICONS = ["♜","▣","✦","▥","◆","⚔","⛨","★","◉","○","◇","○","◉"]
const RARITIES = ["Common","Uncommon","Rare","Epic","Legendary"]
const COLORS = ["eeeeee","64db85","66adff","c28aff","f6c35a"]

static func drop(tier: int) -> String:
	if randf()<0.35: return "Spirit shard"
	var roll := randf()
	var rarity := 0 if roll<0.50 else (1 if roll<0.78 else (2 if roll<0.93 else (3 if roll<0.99 else 4)))
	rarity=mini(4,rarity+clampi(tier,0,2))
	return RARITIES[rarity]+" "+TYPES[randi_range(0,10)]

static func describe(id: String) -> Dictionary:
	for r in range(RARITIES.size()):
		for i in range(11):
			if id!=RARITIES[r]+" "+TYPES[i]: continue
			var factor := r+1
			var slots: Array = [SLOTS[i]]
			if i==8: slots.append("bracelet2")
			if i==9: slots.append("ring2")
			return {"slots":slots,"icon":ICONS[i],"color":Color(COLORS[r]),"rarity":RARITIES[r],"attack":4*factor if i==5 else (factor if i>=8 else 0),"defense":factor if i<5 or i==6 else 0,"hp":5*factor if i==0 or i==1 or i==3 else 0,"mp":5*factor if i==4 or i==10 else 0,"crit":0.01*factor if i==9 or i==2 else 0.0}
	return {"slots":[],"icon":"✦" if id=="Spirit shard" else "+","color":Color.WHITE,"rarity":"Common","attack":0,"defense":0,"hp":0,"mp":0,"crit":0.0}
