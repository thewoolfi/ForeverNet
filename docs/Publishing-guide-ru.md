# Публикация ForeverNet на GitHub и CurseForge

Версия инструкции: 1 октября 2026. Текущий аддон: **0.3.2**, автор: **Andrew Woolfi**.

## 1. Что подготовить

- Учётные записи GitHub и CurseForge.
- Git для Windows для загрузки исходников.
- Описания: `docs/CurseForge-ru.md` и `docs/CurseForge-en.md`.
- Несколько скриншотов: главное окно, расчёт цепочки, настройки. Перед снимком дождитесь исчезновения сообщения «Скриншот сохранён».
- Отдельное изображение для логотипа страницы. Строка IconTexture в TOC задаёт иконку внутри игры, но не загружает картинку на CurseForge.
- Лицензия проекта — **MIT**. Файл LICENSE уже добавлен, автор: Copyright (c) 2026 Andrew Woolfi. На CurseForge выберите MIT License.

Перед первой публикацией проверьте в игре открытие окон, сканирование профессии и банка, расчёт и обмен запросом с другим игроком. Для текущей ранней версии разумно выбрать статус Alpha.

## 2. GitHub: исходники проекта

### Создание репозитория

На GitHub создайте новый репозиторий `ForeverNet`. Для открытой страницы выберите Public. Оставьте его пустым: не создавайте README, .gitignore и лицензию через форму — README и .gitignore уже есть локально.

Источник: [добавление существующего проекта — GitHub Docs](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github).

### Первая загрузка

Откройте PowerShell в папке проекта. В командах ниже замените `YOUR_LOGIN` своим логином GitHub. Команды в этом документе — инструкция; автоматически они не выполнялись.

```powershell
Set-Location -LiteralPath 'C:\Users\zxcad\OneDrive\Рабочий стол\ForeverNet'
git init -b main
git add .
git status
```

Проверьте список файлов перед коммитом. Нужны корневые Lua-файлы, TOC, README, CHANGELOG, docs, tests, requirements-dev.txt и .gitignore. Папки `work`, `outputs`, архивы ZIP и тестовая среда исключены существующим .gitignore. Не добавляйте папку игры или файлы сохранений персонажей.

```powershell
git commit -m "Initial release of ForeverNet 0.3.2"
git remote add origin https://github.com/YOUR_LOGIN/ForeverNet.git
git push -u origin main
```

Если Git попросит имя и email автора коммитов, задайте их для этого репозитория и повторите коммит:

```powershell
git config user.name "Andrew Woolfi"
git config user.email "YOUR_VERIFIED_OR_GITHUB_NOREPLY_EMAIL"
```

Замените email реальным подтверждённым адресом либо своим noreply-адресом из настроек GitHub. При запросе входа используйте предложенную авторизацию GitHub; обычный пароль аккаунта не является паролем для Git по HTTPS.

Если репозиторий уже существует, не повторяйте начальную настройку вслепую: сначала проверьте `git status` и `git remote -v`. Для неверного адреса используйте `git remote set-url origin НОВЫЙ_URL`.

### Страница проекта и выпуск

Заполните краткое описание, например:

> Profession sharing, crafting chains and material requests for WoW: Forever.

Включите Issues для сообщений об ошибках. После загрузки исходников создайте в разделе Releases выпуск с тегом `v0.3.2`, названием `ForeverNet 0.3.2`, заметками из CHANGELOG и отметкой предварительного выпуска. Прикрепите установочный ZIP, подготовленный ниже. Автоматический архив исходников GitHub не заменяет архив с правильной папкой аддона.

## 3. Подготовка установочного ZIP

В архив должны попасть только файлы, необходимые игре. Структура:

```text
ForeverNet-0.3.2.zip
└── ForeverNet/
    ├── LICENSE
    ├── ForeverNet.toc
    ├── Locale.lua
    ├── Core.lua
    ├── ... остальные Lua-файлы из TOC
    └── Bootstrap.lua
```

Не должно быть вложенности `ForeverNet/ForeverNet/`, папок `Interface/AddOns` или суффикса `ForeverNet-main` вместо имени аддона.

Следующий код PowerShell собирает архив из TOC. Он создаёт отдельную временную папку сборки и не удаляет исходники:

```powershell
Set-Location -LiteralPath 'C:\Users\zxcad\OneDrive\Рабочий стол\ForeverNet'
$releaseVersion = '0.3.2'
$releaseStage = Join-Path (Get-Location) ('work\release-' + [guid]::NewGuid().ToString('N'))
$releaseAddon = Join-Path $releaseStage 'ForeverNet'
New-Item -ItemType Directory -Path $releaseAddon -Force | Out-Null
New-Item -ItemType Directory -Path 'outputs' -Force | Out-Null
$releaseFiles = @('ForeverNet.toc', 'LICENSE') + @(Get-Content ForeverNet.toc | Where-Object { $_ -match '\.lua$' })
foreach ($releaseFile in $releaseFiles) {
    Copy-Item -LiteralPath $releaseFile -Destination (Join-Path $releaseAddon $releaseFile)
}
$releaseZip = Join-Path (Get-Location) ('outputs\ForeverNet-' + $releaseVersion + '.zip')
Compress-Archive -LiteralPath $releaseAddon -DestinationPath $releaseZip -Force
Write-Output $releaseZip
```

Проверьте содержимое полученного ZIP в Проводнике. Убедитесь, что LICENSE включён в папку ForeverNet внутри архива; приведённая команда уже добавляет его. Для будущих ресурсов (текстур, звуков) потребуется также добавить их в упаковку; текущая версия использует игровые текстуры.

## 4. CurseForge: страница и файл аддона

Откройте [панель авторов — создание проекта](https://authors.curseforge.com/#/projects/create/choose-game) и выберите World of Warcraft, затем подходящий тип проекта для аддона.

Заполните данные:

| Поле | Для ForeverNet |
|---|---|
| Название | ForeverNet |
| Краткое описание | Profession sharing, crafting chains and material requests for WoW: Forever. |
| Автор/отображаемое имя | Andrew Woolfi, где поле доступно; владельцем проекта будет ваш аккаунт |
| Описание | Содержимое CurseForge-en.md; русское описание можно добавить отдельным разделом ниже |
| Категории | Подходящие категории профессий и взаимодействия игроков из доступного списка |
| Исходный код | https://github.com/YOUR_LOGIN/ForeverNet |
| Сообщения об ошибках | https://github.com/YOUR_LOGIN/ForeverNet/issues |
| Лицензия | MIT License |
| Логотип и изображения | Подготовленный логотип и скриншоты интерфейса |

Источник: [создание проекта](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project), [поля страницы проекта](https://support.curseforge.com/support/solutions/articles/9000199552-overview-of-the-project-submission-page).

### Загрузка версии

В разделе файлов проекта откройте загрузку файла и выберите `ForeverNet-0.3.2.zip`. Укажите название выпуска, статус Alpha и изменения из CHANGELOG.

В списке версий игры выберите именно вариант, соответствующий клиенту Forever 1.60.1, если он доступен. Не отмечайте Retail или другие Classic-клиенты только ради отправки формы: совместимость с ними не подтверждена. Если нужной версии нет в форме, уточните её поддержку у CurseForge. Эта инструкция не подтверждает наличие конкретного пункта Forever в вашем кабинете.

Завершите отправку проекта/файла на рассмотрение согласно подсказкам панели. После одобрения проверьте страницу, скачивание и структуру скачанного архива. Названия кнопок могут отличаться по языку и версии кабинета.

## 5. Следующие обновления

1. Измените версию в `ForeverNet.toc` и `Core.lua`, добавьте запись в CHANGELOG.
2. Проверьте аддон в игре и запустите тесты проекта.
3. Сохраните изменения в Git:

```powershell
git add .
git status
git commit -m "Release ForeverNet NEXT_VERSION"
git push
```

4. Соберите новый ZIP, изменив `$releaseVersion` в инструкции упаковки.
5. Создайте новый GitHub Release с новым тегом и прикрепите ZIP.
6. Загрузите этот же ZIP как новый файл существующего проекта CurseForge. Повторно создавать проект не нужно.

## Перед нажатием Publish

- Версия в TOC, коде, названии ZIP и описании выпуска совпадает.
- Внутри ZIP одна папка ForeverNet с TOC непосредственно в ней.
- Автор указан как Andrew Woolfi.
- В архиве нет резервных копий, work, tests и пользовательских сохранений.
- Выбраны фактически поддерживаемая версия игры и согласованная лицензия.
- В описании сохранены ограничения ранней версии.
