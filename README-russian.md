Тип игры FAF | Тип игры FAF Develop | Тип игры Баланс FAF Beta
 ------------ | ------------- | -----------
[![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffaf)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafdevelop)](https://github.com/FAForever/fa/actions/workflows/build.yaml) | [![Build](https://github.com/FAForever/fa/actions/workflows/build.yaml/badge.svg?branch=deploy%2Ffafbeta)](https://github.com/FAForever/fa/actions/workflows/build.yaml)

Read this in other languages: [English](README.md), [Russian](README-russian.md)

О Forged Alliance Forever
-----------------------------

![Impression of the game](/images/impression-a.jpg)

Forged Alliance Forever — это [проект](https://github.com/FAForever) сообщества, созданный для облегчения онлайн-игры в Supreme Commander: Forged Alliance. Мы процветающее сообщество с самодельными [клиентом](https://github.com/FAForever/downlords-faf-client), [серверной частью](https://github.com/FAForever/server) и [веб-сайтом](https://github.com/FAForever/website). У нас есть обширная библиотека созданных сообществом карт, модов и сценариев совместной игры. Мы внедрили рейтинговую систему, основанную на [TrueSkill](https://www.microsoft.com/en-us/research/project/trueskill-ranking-system/), чтобы обеспечить конкурентную среду с автоматическим подбором игроков. Чтобы увидеть все, что мы добавили, лучше всего испытать это на себе, играя в игру через клиент.

Скачать клиент можно на нашем [сайте](https://faforever.com/). Чтобы играть, вам нужно будет синхронизировать свою учетную запись со Steam, чтобы подтвердить, что у вас есть копия [Supreme Commander: Forged Aliance](https://store.steampowered.com/app/9420/Supreme_Commander_Forged_Alliance/). Вы можете связаться с сообществом через [форумы](https://forum.faforever.com/) и официальный сервер [Discord](https://discord.gg/mXahVSKGVb). Чат разработчиков можно найти на [Zulip](https://zulip.com/) — вы можете запросить доступ у администратора этого репозитория. Проект поддерживается за счет пожертвований на [Patreon](https://www.patreon.com/faf).

Список изменений
---------

Вот полный [список изменений](changelog.md). Существует [альтернативный журнал изменений](http://patchnotes.faforever.com/), особенно для патчей баланса, в удобном для пользователя виде.

Помощь сообществу
------------

Есть инструкции на [английском](setup/setup-english.md) и [русском](setup/setup-russian.md) языках, которые помогут настроить среду разработки. Пожалуйста, ознакомьтесь с [правилами помощи сообществу](CONTRIBUTING.md) и [правилами перевода](loc/guidelines.md) перед тем, как делать ваш первый PR.

Об этом репозитории
---------------------

Этот репозиторий содержит изменения Lua-стороны игры, такие как изменения баланса, улучшения производительности и дополнительные функции. Репозиторий имитирует организацию базовой игры. Краткое справочное руководство:

Папка           | Описание
--------------- | -----------
`effects`       | Чертежи, текстуры и меши эффектов и шейдеры HLSL, которые используются для рендеринга игры
`engine*`       | Документация движка: все объекты и их функции задокументированы
`env`           | Пропы, декали, знаки, слои и эффекты окружающей среды
`etc*`          | Legacy — рудиментарная реализация контроля версий
`loc`           | Файлы локализации для игры, см. рекомендации по переводу
`lua`           | Файлы Lua, которые управляют всем поведением вне физического моделирования
`meshes`        | Меши, не принадлежащие пропам, юнитам или снарядам. Например, граница мира
`projectiles`   | Файлы чертежей, текстуры и меши снарядов
`props`         | Файлы чертежей, текстуры и меши реквизита
`schook`        | Устаревшая — папка **s**upreme **c**ommander **hook**, которая использовалась из-за проблем с лицензированием.
`testmaps*`     | Пробные карты. Например, эталонная карта, поставляемая с игрой
`tests*`        | Модульные тесты, которые выполняются на функциях движка oblivion. Например, проверка строковых операций
`textures`      | Текстуры, используемые движком (в качестве запасного варианта) и пользовательским интерфейсом
`units`         | Файлы чертежей, текстуры и меши юнитов

Неизмененные файлы извлекаются из базовой игры. Папки со звездочкой (*) не отправляются пользователю вместе с клиентом. См. инструкции по установке в разделе помощи сообществу для получения дополнительной информации.

Репозитории, имеющие непосредственное отношение к игре:
 - [Профайлер Lua](https://github.com/FAForever/FAFProfiler)
 - [Инструмент для тестирования Lua](https://gitlab.com/supreme-commander-forged-alliance/other/profiler)
 - [Исполняемый патчер](https://github.com/FAForever/FA_Patcher)
 - [Исполняемые патчи](https://github.com/FAForever/FA-Binary-Patches)
 - [Отладчик](https://github.com/FAForever/FADeepProbe) помогающий с исключениями
