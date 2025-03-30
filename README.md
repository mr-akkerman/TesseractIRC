# TesseractIRC

![Status](https://img.shields.io/badge/status-alpha-orange)
![Python](https://img.shields.io/badge/python-3.8+-blue)
![PySide6](https://img.shields.io/badge/PySide6-latest-green)
![License](https://img.shields.io/badge/license-MIT-blue)

## 🌟 Overview

TesseractIRC is a hobby project created out of love for the classic IRC protocol and a desire to add a modern touch to it. This client is my personal experiment in bringing new life to IRC with a contemporary interface inspired by modern messengers while maintaining full compatibility with existing IRC servers.

I'm building this in my spare time primarily because I enjoy IRC and want to enhance it with features I personally find useful, with no professional pretensions or commercial goals. It's simply a passion project by an IRC enthusiast.

## ✨ Core Concept

IRC remains a robust chat protocol that powers numerous communities across the internet, and I've always appreciated its simplicity and resilience. However, most existing clients haven't evolved to meet contemporary UX expectations. As a fun side project, TesseractIRC is my attempt to address this by:

1. **Reimagining IRC UX**: Creating a sleek, intuitive interface comparable to Telegram and other modern messengers
2. **Extending Bot Capabilities**: Supporting interactive elements (buttons, polls, media) without server modification
3. **Enhancing Security**: Integrating additional mechanisms for improved privacy and security
4. **Cross-Platform Support**: Initially targeting macOS and iOS with plans for expansion
5. **Maintaining Compatibility**: Working seamlessly with existing IRC servers and clients

The innovation lies in implementing extended features via a special text markup in standard IRC messages, allowing enhanced functionality for TesseractIRC users while remaining compatible with traditional clients.

## 🔧 Technical Implementation

TesseractIRC is built with technologies I enjoy working with:

- **PySide6**: Qt for Python enabling a modern, customizable UI
- **Python 3.8+**: Providing a solid foundation for application logic
- **SQLite**: For local storage of settings and chat history
- **irc.client**: Python library for IRC protocol implementation

Extended functionality is implemented through specialized text markup that is interpreted by the client but appears as regular text on traditional clients:


## 🚀 Current Features

- ✅ Dark theme user interface
- ✅ Connection to IRC servers
- ✅ Joining and participating in channels
- ✅ Private messaging support
- ✅ System message integration
- ✅ Server and channel management
- ✅ Settings persistence
- ✅ Auto-join channel configuration

## 📝 TODO

This is my personal wishlist of features I'd like to implement as I find time and motivation:

- [ ] Server/channel deletion and editing
- [ ] Disconnect buttons for servers and channels
- [ ] Chat history saving
- [ ] Chat history clearing functionality
- [ ] Interactive elements for bots (buttons, polls)
- [ ] Media file exchange support
- [ ] Client-to-client encryption for TesseractIRC users
- [ ] Nickname autocomplete
- [ ] Customizable themes and appearance
- [ ] Message search functionality
- [ ] Emoji and reactions
- [ ] File transfers with progress indication
- [ ] Desktop notifications
- [ ] Keyboard shortcuts
- [ ] Multiple window support
- [ ] Channel topic display and editing
- [ ] User list with status indicators
- [ ] Extended IRC command support (/mode, /whois, etc.)
- [ ] Tools for IRC operators
- [ ] Plugin system for extensibility
- [ ] Multilingual support (English and Russian)

Progress may be intermittent as this is a side project I work on when time permits, but I'm always open to ideas and suggestions!

## 📦 Installation

If you'd like to try out this work-in-progress:

Prerequisites:
- Python 3.8+
- PySide6
- irc.client

Installation steps:

```bash
# Clone the repository
git clone https://github.com/mr-akkerman/TesseractIRC.git
cd TesseractIRC

# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py
```

## 📸 Screenshots

(Screenshots will be added soon)

## 🤝 Contributing

While this is primarily a personal project, I'm always happy to receive feedback, suggestions, or contributions. Feel free to submit a Pull Request if you're interested in adding features or fixing bugs!

---

# TesseractIRC (Russian)

## 🌟 Обзор

TesseractIRC - это любительский проект, созданный из желания добавить в него современные черты. Этот клиент - мой личный эксперимент по оживлению IRC с помощью современного интерфейса, вдохновленного современными мессенджерами, при этом сохраняющий полную совместимость с существующими IRC-серверами.

Я разрабатываю его в свободное время в первую очередь потому, что мне нравится IRC, и я хочу добавить в него функции, которые лично я считаю полезными, без профессиональных претензий или коммерческих целей. Это просто проект по интересам от энтузиаста IRC.

## ✨ Основная концепция

IRC остается надежным протоколом чата, который поддерживает множество сообществ в Интернете, и я всегда ценил его простоту и устойчивость. Однако большинство существующих клиентов не эволюционировали, чтобы соответствовать современным ожиданиям UX. Как увлекательный побочный проект, TesseractIRC - это моя попытка частично решить эту проблему:

1. **Переосмысление пользовательского опыта IRC**: Создание элегантного, интуитивно понятного интерфейса
2. **Расширение возможностей ботов**: Поддержка интерактивных элементов (кнопки, опросы, медиа) без модификации сервера
3. **Повышение безопасности**: Интеграция дополнительных механизмов для улучшения конфиденциальности и безопасности
4. **Кроссплатформенная поддержка**: Изначально нацелен на macOS и iOS с планами расширения на остальные платформы включая мобильные
5. **Поддержание совместимости**: Бесперебойная работа с существующими IRC-серверами и клиентами

Инновация заключается в реализации расширенных функций через специальную текстовую разметку в стандартных IRC-сообщениях, что позволяет пользователям TesseractIRC получать расширенную функциональность, сохраняя совместимость с традиционными клиентами.

## 🔧 Техническая реализация

TesseractIRC построен с использованием технологий, с которыми мне нравится работать:

- **PySide6**: Qt для Python, обеспечивающий современный, настраиваемый пользовательский интерфейс
- **Python 3.8+**: Обеспечивает прочную основу для логики приложения
- **SQLite**: Для локального хранения настроек и истории чата
- **irc.client**: Библиотека Python для реализации протокола IRC

Расширенная функциональность реализуется через специализированную текстовую разметку, которая интерпретируется клиентом, но отображается как обычный текст на традиционных клиентах.

## 🚀 Текущие возможности

- ✅ Пользовательский интерфейс с темной темой
- ✅ Подключение к IRC-серверам
- ✅ Присоединение и участие в каналах
- ✅ Поддержка личных сообщений
- ✅ Интеграция системных сообщений
- ✅ Управление серверами и каналами
- ✅ Сохранение настроек
- ✅ Конфигурация автоматического подключения к каналам

## 📝 Планы развития

Это мой список желаемых функций, которые я хотел бы реализовать по мере появления времени и мотивации:

- [ ] Удаление и редактирование серверов/каналов
- [ ] Кнопки отключения для серверов и каналов
- [ ] Сохранение истории чата
- [ ] Функциональность очистки истории чата
- [ ] Интерактивные элементы для ботов (кнопки, опросы)
- [ ] Поддержка обмена медиафайлами
- [ ] Шифрование "клиент-клиент" для пользователей TesseractIRC
- [ ] Автодополнение никнеймов
- [ ] Настраиваемые темы и внешний вид
- [ ] Функция поиска сообщений
- [ ] Эмодзи и реакции
- [ ] Передача файлов с индикацией прогресса
- [ ] Настольные уведомления
- [ ] Сочетания клавиш
- [ ] Поддержка нескольких окон
- [ ] Отображение и редактирование темы канала
- [ ] Список пользователей с индикаторами статуса
- [ ] Расширенная поддержка IRC-команд (/mode, /whois и т.д.)
- [ ] Инструменты для IRC-операторов
- [ ] Система плагинов для расширяемости
- [ ] Мультиязычность (поддержка английского и русского языков)

Прогресс может быть непостоянным, так как это побочный проект, над которым я работаю, когда позволяет время, но я всегда открыт для идей и предложений!

## 📦 Установка

Если вы хотите попробовать эту находящуюся в разработке программу:

Предварительные требования:
- Python 3.8+
- PySide6
- irc.client

Шаги установки:

```bash
# Клонировать репозиторий
git clone https://github.com/mr-akkerman/TesseractIRC.git
cd TesseractIRC

# Установить зависимости
pip install -r requirements.txt

# Запустить приложение
python main.py
```

## 📸 Скриншоты

(Скриншоты скоро будут добавлены)

## 🤝 Участие в разработке

Хотя это в первую очередь личный проект, я всегда рад получить отзывы, предложения или вклад в разработку. Не стесняйтесь отправлять Pull Request, если вы заинтересованы в добавлении функций или исправлении ошибок!