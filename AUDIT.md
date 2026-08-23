# Аудит пакета `mostbyte_print`

Дата: 2026-08-05

Полный аудит структуры, "универсальности" API и безопасности пакета `flutter_packages/mostbyte_print` — Flutter-пакет для печати ESC/POS-чеков по сети (TCP/IP), USB и Bluetooth.

## 1. Структура пакета

```
lib/
  print.dart                     — публичный API: MostbytePrint (генерация чеков + отправка на печать)
  usb_esc_printer_windows.dart   — FFI + isolate обёртка над .dll (НЕ используется из print.dart)
  usb_esc_printer_windows.dll    — бинарник без исходников в репо
  esc_pos/                       — форк esc_pos_utils (Generator, capability_profile, GBK-кодек, barcode/qr)
  models/                        — POSPrinter/USBPrinter/NetWorkPrinter/BluetoothPrinter + data_models (Shift/User/Earned/...)
  helpers/network_analyzer.dart  — сканер подсети (ping_discover_network)
  enums/                         — ConnectionType, CyrillicEncoding, PrinterVendor, ConnectionResponse
```

Ключевое наблюдение по архитектуре: в пакете фактически **два несвязанных слоя**, которые нигде не пересекаются:
- слой обнаружения принтеров (`POSPrinter`/`NetWorkPrinter`/`USBPrinter`/`BluetoothPrinter`, `NetworkAnalyzer`) — нигде не используется самим `MostbytePrint` и не экспортируется через `print.dart`;
- слой печати (`MostbytePrint`) — принимает сырые `ip`/`name`/`connectionType`, не знает о моделях выше.

Итог: хост-приложение (cafe_dashboard/pos_order) не может напрямую передать найденный `POSPrinter` в `MostbytePrint` — приходится вручную мапить поля. Это и есть главный барьер для "универсализации".

## 2. Мёртвый код и лишняя поверхность атаки

- **`usb_esc_printer_windows.dart` + `usb_esc_printer_windows.dll` не используются.** `printTicket()` для USB идёт через `printRawData()` (прямой Win32 `OpenPrinter`/`WritePrinter`), а не через `sendPrintRequest()`/DLL. Единственная ссылка на DLL — экспорт биндингов в `esc_pos_utils_plus.dart`.
- Последствия: в репозитории лежит **скомпилированный бинарник (55 КБ) без единого файла исходников** (`.c`/`.cpp`/`CMakeLists.txt` нигде в пакете нет), загружаемый через `DynamicLibrary.open('usb_esc_printer_windows.dll')` по имени из текущей директории поиска Windows — классический вектор **DLL search-order hijacking**, если бы код реально исполнялся. Раз он мёртв — либо удалите файл и обёртку целиком, либо перенесите исходники нативной либы в репо и подключите реальный вызов.
- Реально используемый путь (`printRawData`) синхронно блокирует **вызывающий изолят** (обычно UI-изолят) на время `OpenPrinter/StartDocPrinter/WritePrinter` — то есть единственная асинхронная/изолятная инфраструктура в пакете не используется там, где она реально нужна (защита UI от фриза при печати).

**Рекомендация:** либо удалить DLL/isolate-обвязку как мёртвый код, либо переключить `printRawData` на вызов через хелпер-изолят (`sendPrintRequest`), раз инфраструктура уже написана.

## 3. "Универсализация" — пакет жёстко привязан к бизнес-логике Unipos

- `print.dart` — не generic ESC/POS SDK, а конкретные шаблоны чеков Unipos/Turkiston: `generateShift` (кассовая смена с полями "Наличка/Терминал/Перевод"), `generateOrderCheck` — вообще медицинский тикет очереди ("Ваш номер очереди", "Врач:", "Обычная/Быстрая процедура" — привет из pos_queue), `generateCheck`, `generateReceipt` с полями `tablePrice`/`hours`/`minutes` (почасовая аренда столов — PS Zone / кальянная specifics).
- Все строки на русском захардкожены внутри пакета — нет i18n, нет способа подставить другой шаблон без форка пакета.
- `Map<String, dynamic> orders` вместо типизированной модели — нет контракта, ошибки уровня `orderItem["amount"] * orderItem["price"]` всплывают в рантайме при неверном типе (например `amount` строкой).

**Рекомендация для реальной универсализации:** вынести доменные шаблоны (`generateShift`, `generateOrderCheck`, `generateReceipt`) в слой приложения, оставив в пакете низкоуровневый generic API (`Generator`, `MostbytePrint.printTicket(bytes)`, кодировка/профили). Либо явно принять, что пакет — internal Unipos-only, и убрать из README "generic printing package" формулировки (README сейчас — шаблон-заглушка pub.dev, вообще не описывает пакет).

## 4. Утечки и надёжность

- **Отсутствует прямая зависимость `image` в `pubspec.yaml`**, хотя `print.dart` и `generator.dart` используют `package:image/image.dart` в публичном API (`Image? barcodeImg`, `generator.imageRaster`). Сейчас резолвится только как *transitive* dependency через `flutter_esc_pos_network` — по правилам pub это нарушение (`depend_on_referenced_packages` линт), и обновление/удаление зависимости `flutter_esc_pos_network` в будущем сломает компиляцию без явного сигнала. **Добавить `image:` в `dependencies`.**
- `printTicket()` для сети сравнивает результат `printing.msg == "Success"` (строкой), а не `printing == PosPrintResult.success` (типом) — хрупко, легко сломать при рефакторинге `PosPrintResult`.
- Модели `User.fromJson`, `Filial.fromJson`, `Shift.fromJson` берут значения из JSON **без null-fallback** для non-nullable полей (`id`, `firstname`, `surname`, `openedAt`, `name_ru`...). Если бэкенд когда-нибудь пришлёт `null` в одном из этих полей — `TypeError` в рантайме прямо во время печати смены, чек не распечатается вообще (в отличие от `patronymic`/`phone`/`email`, которые в том же классе аккуратно defaultятся).
- 38 вызовов `print()` по всему `lib/` (включая IP принтера, тайминги, стектрейсы ошибок) — в проде это уходит в системный лог без возможности выключить/подменить на нормальный логгер. Мелкая, но реальная утечка диагностической информации (IP принтеров, внутренние тайминги) в консольные логи.
- `NetworkAnalyzer.discover2` — параллельно открывает до 254 сокетов без ограничения concurrency; на слабом железе/при большом timeout может исчерпать file descriptors (в коде даже есть закомментированная обработка ошибки "Too many open files").

## 5. Безопасность

Существенных "классических" уязвимостей (инъекции, XSS и т.п.) в пакете нет — это офлайн ESC/POS SDK без сети общего назначения. Но есть специфичные для домена риски:

- **Нет аутентификации/шифрования соединения с принтером** (`PrinterNetworkManager(ip)` — обычный TCP, порт 9100 по умолчанию для ESC/POS). Это нормально для этого класса устройств, но означает: любой, кто имеет доступ к той же локальной сети/VLAN, что и принтер, может слать на него произвольные ESC/POS-команды (открыть денежный ящик — `generator.drawer()`/`cCashDrawerPin2`, распечатать что угодно). Пакет не привносит проблему, но и не документирует её — стоит явно указать хостам (cafe_dashboard/pos_order), что принтерная подсеть должна быть изолирована (отдельный VLAN, не publicly routable).
- `NetworkAnalyzer.discover`/`discover2` сканируют весь `/24` (адреса 1–254) на заданный порт — по сути мини port-scanner. Легитимно для автообнаружения принтера, но если он вызывается на устройстве в незнакомой/чужой сети (например, ноутбук официанта в кафе с общим Wi-Fi), это может триггерить IDS/жалобы сетевых админов. Стоит документировать и/или дать возможность отключить.
- `printRawData` (Win32 API) шлёт байты в любой принтер по строковому имени `printerName` без валидации — теоретически, если `name`/`ip` когда-либо будет формироваться из пользовательского ввода (например, из формы настройки принтера), это позволяет отправить RAW job на произвольный установленный в Windows принтер (не обязательно чек-принтер). Риск низкий (нужен физический/локальный доступ к устройству), но раз имя не валидируется против списка реально известных POS-принтеров — стоит хотя бы whitelisting на уровне вызывающего приложения.
- Бинарник `usb_esc_printer_windows.dll` без исходников — см. п.2, отдельный supply-chain риск: никто в команде не может аудировать/пересобрать то, что реально делает эта библиотека при вызове `sendPrintReq`.

## 6. Прочее

- `ConnectionType.bluetooth` объявлен в enum, `BluetoothPrinter`-модель существует, но `MostbytePrint.printTicket()` **не обрабатывает bluetooth вообще** — просто падает в `return false` в конце метода. Bluetooth-печать полностью нереализована, несмотря на видимость поддержки в публичном API.
- Тесты (`test/*.dart`) покрывают только конструктор и `formattedNumber` — ни один из `generate*`-методов, `printTicket`, `printRawData`, `NetworkAnalyzer` не протестирован.
- `README.md` — дефолтный шаблон `flutter create --template=package`, не описывает сам пакет.
- `CHANGELOG.md` — тоже TODO-заглушка, при этом в `pubspec.yaml` `version: 0.0.1` не менялась ни разу за всю историю коммитов.

## Итог — приоритеты

**Сделать в первую очередь:**
1. Добавить `image:` в `pubspec.yaml` (ломающийся неявный transitive dependency).
2. Удалить или довести до ума мёртвый DLL/isolate-код (`usb_esc_printer_windows.*`) — либо реально подключить, либо выпилить бинарник без исходников.
3. Null-safety в `fromJson` моделях (`User`, `Filial`, `Shift`) — обернуть обязательные поля в `?? default`, чтобы не падать при неполном JSON со смены.

**Второй эшелон:**
4. Заменить строковое сравнение `msg == "Success"` на сравнение по enum.
5. Реализовать или явно задокументировать отсутствие Bluetooth-печати.
6. Прогнать `print()`-вызовы через единый (отключаемый) логгер вместо голого `print`.

**По желанию (архитектура/универсализация):**
7. Вынести доменные шаблоны чеков в приложения-потребители, оставить в пакете только generic ESC/POS слой + типы принтеров, связав слой обнаружения (`POSPrinter`) со слоем печати (`MostbytePrint`).
