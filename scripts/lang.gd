class_name Lang
extends RefCounted
## Язык игры. Тексты в коде написаны по-русски, английский перевод лежит в locale/en.po.
## Язык выбирается сам по языку телефона: страны СНГ — русский, все остальные — английский.
## Игрок может сменить язык в настройках (Settings.language: "auto", "ru" или "en").

## Языки телефона, при которых игра запускается на русском (коды ISO 639-1).
const CIS := ["ru", "uk", "be", "kk", "uz", "ky", "tg", "hy", "az", "tk"]


## Язык по телефону: "ru" или "en".
static func detect() -> String:
	return "ru" if OS.get_locale_language() in CIS else "en"


## Язык, который сейчас должен быть в игре, с учётом выбора в настройках.
static func resolve(choice: String) -> String:
	return choice if choice in ["ru", "en"] else detect()


static func apply(choice: String) -> void:
	TranslationServer.set_locale(resolve(choice))


static func is_ru() -> bool:
	return TranslationServer.get_locale().begins_with("ru")


## Перевод строки там, где нет tr(): в статических функциях и данных.
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))


## Файл в русском и английском варианте: для английского берётся «имя_en.расширение», если он есть.
static func localized_path(path: String) -> String:
	if is_ru():
		return path
	var en := path.get_basename() + "_en." + path.get_extension()
	return en if ResourceLoader.exists(en) else path
