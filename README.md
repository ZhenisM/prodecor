# PRODECOR — приложение для дизайнеров (Flutter)

Мобильная версия кабинета pro-decor.kz/designers/. Работает через тот же API (`/designers/api/`),
поэтому клиенты, проекты, заявки и заказы — общие с кабинетом на сайте.

- Bundle ID / applicationId: `kz.prodecor.designers`
- Минимум: iOS 15.0, Android — по умолчанию Flutter
- Вход: телефон + пароль, регистрация с кодом из письма, восстановление пароля.
  После входа приложение хранит ключ (токен) в защищённом хранилище телефона и шлёт его в заголовке
  `Authorization: Bearer …`. Для этого на сайте нужна серверная часть из `prodecor-update-app-token.zip`
  (`lib/AppToken.php`, `api/index.php`). Без неё вход в приложении выдаст «Сервер не выдал ключ входа…».

## Экраны

Нижнее меню: **Главная · Проекты · Заявки · Каталог · Ещё**. В «Ещё» — Мои заказы, Бонусы, Магазины,
Профиль, Как это работает, Поддержка, язык RU/ҚАЗ и выход. Пока профиль на модерации — только Главная и «Ещё».

- Главная — сводка, «Первые шаги», «Следующий шаг», последние проекты, заявки, менеджеры (звонок, WhatsApp).
- Проекты — клиенты с проектами, фильтр по статусу, поиск; создание клиента и проекта (свет или краски).
- Проект — объект, состав (кол-во, удаление), «Из каталога», смета PDF (поделиться/печать), отправка заявки.
- Заявки — этапы из сделки Битрикс24, прогресс; Мои заказы — оплаченные + «Заказы в салонах».
- Каталог — разделы, умный фильтр, сортировка, «в наличии», поиск, карточка товара, «В проект».

## Структура

    lib/main.dart                 запуск, провайдеры
    lib/app/shell.dart            нижнее меню и вкладки
    lib/core/                     API (api.dart), состояние (store.dart), модели (models.dart)
    lib/common/                   общие элементы (widgets.dart), форматирование (format.dart), RU/ҚАЗ (i18n.dart)
    lib/theme/theme.dart          цвета кабинета, светлая/тёмная тема, шрифт Onest
    lib/auth/                     вход, регистрация, восстановление пароля
    lib/dashboard/                главная
    lib/customer/                 клиенты и проекты, формы клиента и проекта
    lib/projects/                 карточка проекта, строка проекта, смета PDF
    lib/requests/                 заявки (данные заявок и примеры — request_data.dart)
    lib/orders/                   мои заказы и «Заказы в салонах»
    lib/catalog/                  каталог: состояние, экран, карточка товара, разделы, фильтр, действия «В проект»
    lib/bonuses/                  бонусы
    lib/pages/                    как это работает, поддержка, магазины
    lib/profile/                  профиль и «Ещё»
    test/screens_test.dart        все экраны рисуются на узком телефоне; сброс фильтра каталога

## Сборка (GitHub Actions)

`.github/workflows/ios.yml` — Xcode 27, подпись вручную, загрузка в TestFlight (как у centrkrasok).
`.github/workflows/android.yml` — APK и AAB, артефакты прогона.

Секреты репозитория (Settings → Secrets and variables → Actions):

| Секрет | Откуда |
|---|---|
| `P12_CERTIFICATE_BASE64`, `P12_PASSWORD` | тот же сертификат Apple Distribution, что у offlinesvet/centrkrasok |
| `APPSTORE_API_KEY_BASE64`, `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID` | тот же ключ App Store Connect API |
| `PRODECOR_PROFILE_BASE64` | новый App Store профиль для `kz.prodecor.designers` (base64 файла .mobileprovision) |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | необязательно: ключ для Google Play; без них APK подписан отладочным ключом (для теста) |

## Локально

    flutter pub get
    flutter analyze
    flutter test
    flutter run
