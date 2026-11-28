extends Node
## Реклама за награду и покупки. Автозагрузка «Shop».
##
## Игра зовёт только три вещи: rewarded() — показать ролик и дать награду, buy() — купить товар,
## и open_chest() — сундук дня. Откуда берутся ролики и оплата, решает этот файл:
## — есть плагины AdMob и Google Play Billing (сборка для магазина) — работают они;
## — плагинов нет (сборка для теста, редактор) — ролик и оплата имитируются окном «ТЕСТ»,
##   настоящих денег и настоящей рекламы нет.
## «Без рекламы» — разовая покупка: награды выдаются сразу, без роликов.

signal purchased(id: String)

## Тестовые номера Google: показывают пробную рекламу, денег не приносят.
## Перед выпуском заменить на свои из кабинета AdMob (см. README, раздел «Монетизация»).
const ADMOB_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const ADMOB_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

## Товары Google Play. id совпадают с теми, что заводятся в Play Console.
## price — запасная надпись, пока магазин не прислал настоящую цену в валюте игрока.
const PRODUCTS := {
	"shells_small": {"title": "Горсть ракушек", "shells": 500, "price": "$0.99", "consumable": true},
	"shells_medium": {"title": "Сундучок ракушек", "shells": 1500, "price": "$2.49", "consumable": true},
	"shells_large": {"title": "Клад ракушек", "shells": 5000, "price": "$5.99", "consumable": true},
	"no_ads": {"title": "Без рекламы", "price": "$2.99", "consumable": false},
	"hero_witch": {"title": "Ведьма", "hero": "witch", "price": "$1.99", "consumable": false},
	"hero_siren": {"title": "Сирена", "hero": "siren", "price": "$2.99", "consumable": false},
}

const CHEST_MIN := 25  ## сундук дня: от CHEST_MIN до CHEST_MIN * 2 ракушек, больше в поздних главах

var _prices := {}  ## id -> цена от магазина («12 900 сум»)


## Есть ли настоящая реклама и оплата (плагины подключены).
func is_live() -> bool:
	return false


func price_of(id: String) -> String:
	return _prices.get(id, PRODUCTS[id].price)


## Показать ролик и по его окончании вызвать on_done(true), если награда положена.
## С покупкой «Без рекламы» награда выдаётся сразу.
func rewarded(reason: String, on_done: Callable) -> void:
	if SaveData.no_ads:
		on_done.call(true)
		return
	_fake_ad(reason, on_done)


## Купить товар. on_done(true) — покупка прошла и товар выдан.
func buy(id: String, on_done: Callable = Callable()) -> void:
	var p: Dictionary = PRODUCTS[id]
	_fake_purchase(id, p, on_done)


func owns(id: String) -> bool:
	var p: Dictionary = PRODUCTS[id]
	if id == "no_ads":
		return SaveData.no_ads
	if p.has("hero"):
		return p.hero in SaveData.heroes
	return false


## Выдать товар после оплаты.
func _grant(id: String) -> void:
	var p: Dictionary = PRODUCTS[id]
	if p.has("shells"):
		SaveData.add_shells(p.shells)
	elif id == "no_ads":
		SaveData.set_no_ads(true)
	elif p.has("hero"):
		SaveData.unlock_hero(p.hero)
	Sound.play("shell")
	purchased.emit(id)


# --- Сундук дня ---------------------------------------------------------

func chest_ready() -> bool:
	return SaveData.chest_day != _today()


## Сколько ракушек в сундуке: растёт с главой, до которой дошёл игрок.
func chest_amount() -> int:
	return CHEST_MIN + Nights.CHAPTERS.find(Nights.progress_chapter()) * 10


## Открыть сундук (после ролика или сразу с «Без рекламы»). on_done(сколько выпало) или 0.
func open_chest(on_done: Callable) -> void:
	if not chest_ready():
		on_done.call(0)
		return
	rewarded("chest", func(ok: bool) -> void:
		if not ok:
			on_done.call(0)
			return
		var amount := randi_range(chest_amount(), chest_amount() * 2)
		SaveData.chest_day = _today()
		SaveData.add_shells(amount)
		on_done.call(amount))


func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


# --- Имитация для теста (пока нет плагинов) ----------------------------

func _fake_ad(_reason: String, on_done: Callable) -> void:
	var ad := FakeAd.new()
	get_tree().root.add_child(ad)
	ad.finished.connect(func(ok: bool) -> void: on_done.call(ok))


func _fake_purchase(id: String, p: Dictionary, on_done: Callable) -> void:
	var dlg := UiDialog.new()
	get_tree().root.add_child(dlg)
	dlg.setup(tr("Тестовая покупка"), tr("%s за %s.\nЭто проверка: деньги не спишутся, товар выдастся сразу.") % [tr(p.title), price_of(id)])
	dlg.add_choice(tr("Купить"), true, func() -> void:
		_grant(id)
		if on_done.is_valid():
			on_done.call(true))
	dlg.add_choice(tr("Отмена"), false, func() -> void:
		if on_done.is_valid():
			on_done.call(false))
	dlg.open()
