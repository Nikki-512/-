# Путешествие в КФУ

Двухмерная пиксельная игра о студенте, который хочет стать учёным. Маршрут ведёт из канализации через улицы и крыши Казани в лаборатории КФУ, а затем на арену Зиланта.

## Запуск для игрока

Дважды щёлкните по `Puteshestvie_v_KFU.exe`.

## Запуск исходного проекта

Установите [Godot 4.5.1 Standard для Windows x86_64](https://godotengine.org/download/archive/4.5.1-stable/) и экспортные шаблоны той же версии через **Editor → Manage Export Templates**. Команды выполняются в PowerShell из корня репозитория. Укажите свой путь к Godot.

```powershell
$godot = 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe'
& $godot --headless --editor --path . --import
& $godot --path .
```

## Сборка Windows x64

```powershell
New-Item -ItemType Directory -Force dist | Out-Null
& $godot --headless --path . --export-release 'Windows Desktop' dist/Puteshestvie_v_KFU.exe
```

Профиль **Windows Desktop** использует Compatibility и встраивает PCK в EXE. Сохранение и язык записываются в `user://journey.cfg`, обычно в `%APPDATA%\Godot\app_userdata\Puteshestvie v KFU`.

## Управление

| Клавиши | Действие |
| --- | --- |
| A / D или ← / → | Движение |
| Пробел | Прыжок и перенос с фиолетовой платформы |
| W или ↑ | Подъём по лестнице и вход в дверь |
| Q / E | Уменьшение и увеличение частоты под ногами |
| F | Луч из книги на третьем уровне |
| Esc | Пауза |

## Проверки

```powershell
& $godot --headless --path . --script qa/playthrough.gd
```

Сценарий прогоняет игровую физику от новой игры до титров, в том числе обязательный прыжок, пять находок, проверку закрытой двери и бой. Он использует отдельный файл сохранения. Сценарий `./qa/smoke-release.ps1` повторяет прохождение на релизном EXE, скопированном в пустую временную папку. Команда `./qa/smoke-release.ps1 -Checkpoint` доводит игру до флага на улице, закрывает тестовый процесс и открывает EXE обычным способом с тем же сохранением. Нажмите «Дәвам итү», чтобы вернуться к флагу.

## Источники

- Казанский федеральный университет, [экспозиция Музея истории Казанского университета](https://kpfu.ru/eng/about-the-university/museums-and-library/the-museum-of-history-of-kazan-university/exhibition-halls/exhibition-halls_136679.html).
- Университет Сент-Эндрюса, [биография Николая Лобачевского](https://mathshistory.st-andrews.ac.uk/Biographies/Lobachevsky/).
- IBM Plex Mono распространяется по [SIL Open Font License](assets/OFL.txt).

