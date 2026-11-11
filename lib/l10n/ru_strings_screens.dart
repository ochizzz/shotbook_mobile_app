/// Russian translations for the feed, create-post, profile, auth and
/// password screens. Key = English text passed to `context.tr`.
const Map<String, String> ruStringsScreens = {
  // Feed
  'Feed': 'Лента',
  'Refresh feed': 'Обновить ленту',
  'Post': 'Пост',
  'Community feed is not connected': 'Лента сообщества не подключена',
  'Add Supabase settings to load posts and publish your own photos.': 'Добавьте настройки Supabase, чтобы загружать посты и публиковать свои фото.',
  'Feed could not be loaded': 'Не удалось загрузить ленту',
  'Check your connection, then try again.':
      'Проверьте соединение и попробуйте снова.',
  'Try again': 'Повторить',
  'No community posts yet': 'Пока нет постов',
  'Be the first to share a photo and its shooting notes.':
      'Поделитесь первым фото и заметками о съёмке.',
  'Unlike photo': 'Убрать лайк',
  'Like photo': 'Поставить лайк',
  'Save photo': 'Сохранить фото',
  'now': 'сейчас',
  '{n}m': '{n} мин',
  '{n}h': '{n} ч',
  '{n}d': '{n} дн',
  // Create post
  'Could not open that image. Please choose another file.':
      'Не удалось открыть изображение. Выберите другой файл.',
  'Choose a photo before publishing.': 'Выберите фото перед публикацией.',
  'Publishing needs a configured Supabase project. See README for setup.':
      'Для публикации нужен настроенный проект Supabase. Инструкция в README.',
  'Could not reach Supabase. Check your connection and try again.': 'Не удалось связаться с Supabase. Проверьте соединение и попробуйте снова.',
  'New post': 'Новый пост',
  'Connect a Supabase project to publish posts. You can still browse the local catalog.': 'Подключите проект Supabase, чтобы публиковать посты. Локальный каталог доступен и без него.',
  'Choose a photo': 'Выбрать фото',
  'Change photo': 'Изменить фото',
  'Title': 'Название',
  'Add a title for your photo.': 'Добавьте название фото.',
  'Description (optional)': 'Описание (необязательно)',
  'Category': 'Категория',
  'Camera settings': 'Настройки камеры',
  'Device': 'Устройство',
  'Camera / Lens': 'Камера / объектив',
  'Focal length': 'Фокусное расстояние',
  'ISO': 'ISO',
  'Shutter speed': 'Выдержка',
  'Aperture': 'Диафрагма',
  'White balance': 'Баланс белого',
  'Exposure compensation': 'Экспокоррекция',
  'Color / Editing': 'Цвет / обработка',
  'Preset name': 'Название пресета',
  'Preset': 'Пресет',
  'Contrast': 'Контраст',
  'Highlights': 'Света',
  'Shadows': 'Тени',
  'Saturation': 'Насыщенность',
  'Temperature': 'Температура',
  'Tint': 'Оттенок',
  'Grain': 'Зерно',
  'Publish': 'Опубликовать',
  'Camera settings are optional. JPEG, PNG and WebP up to 10 MB.':
      'Настройки камеры необязательны. JPEG, PNG и WebP до 10 МБ.',
  // Image validation messages (data layer stays English)
  'The image file is empty.': 'Файл изображения пуст.',
  'Images must be 10 MB or smaller.':
      'Размер изображения не должен превышать 10 МБ.',
  'Choose a JPEG, PNG, or WebP image.':
      'Выберите изображение JPEG, PNG или WebP.',
  'The file extension does not match a supported image.':
      'Расширение файла не соответствует поддерживаемому изображению.',
  'Avatar images must be 5 MB or smaller.':
      'Размер аватара не должен превышать 5 МБ.',
  // Auth
  'Sign-in is unavailable. Add Supabase settings to enable accounts.':
      'Вход недоступен. Добавьте настройки Supabase, чтобы включить аккаунты.',
  'This email is already registered. Sign in instead, or use "Forgot password?".':
      'Этот email уже зарегистрирован. Войдите или нажмите «Забыли пароль?».',
  'Check your email to confirm your account, then sign in.':
      'Подтвердите аккаунт по ссылке из письма, затем войдите.',
  'Password reset instructions were sent to your email.':
      'Инструкции по сбросу пароля отправлены на вашу почту.',
  'Too many emails requested. Wait a minute, then use the newest email.': 'Слишком много запросов писем. Подождите минуту и используйте самое новое письмо.',
  'Could not reach Supabase. Check your connection and project settings.': 'Не удалось связаться с Supabase. Проверьте соединение и настройки проекта.',
  'Reset password': 'Сброс пароля',
  'Create your account': 'Создайте аккаунт',
  'Welcome back': 'С возвращением',
  'We will email you a secure reset link.':
      'Мы отправим вам безопасную ссылку для сброса.',
  'Save references and share what you shoot.':
      'Сохраняйте референсы и делитесь своими снимками.',
  'Username': 'Имя пользователя',
  'Use at least 3 characters.': 'Минимум 3 символа.',
  'Display name (optional)': 'Отображаемое имя (необязательно)',
  'Email': 'Email',
  'Enter a valid email address.': 'Введите корректный email.',
  'Password': 'Пароль',
  'Use at least 6 characters.': 'Минимум 6 символов.',
  'Send reset link': 'Отправить ссылку',
  'Create account': 'Создать аккаунт',
  'Sign in': 'Войти',
  'Forgot password?': 'Забыли пароль?',
  'Back to sign in': 'Назад ко входу',
  'Already have an account? Sign in': 'Уже есть аккаунт? Войти',
  'Create an account': 'Создать аккаунт',
  'Browsing works in demo mode. Configure Supabase to use accounts.': 'Просмотр работает в демо-режиме. Настройте Supabase, чтобы пользоваться аккаунтами.',
  // Update password
  'The passwords do not match.': 'Пароли не совпадают.',
  'The recovery session is no longer available. Request a new link.':
      'Сессия восстановления больше недоступна. Запросите новую ссылку.',
  'Password updated.': 'Пароль обновлён.',
  'Choose a new password': 'Выберите новый пароль',
  'New password': 'Новый пароль',
  'Confirm password': 'Подтвердите пароль',
  'Saving…': 'Сохранение…',
  'Update password': 'Обновить пароль',
  // Profile
  'Profile': 'Профиль',
  'Photographer': 'Фотограф',
  'Sign out': 'Выйти',
  'Sign in to open your profile': 'Войдите, чтобы открыть профиль',
  'Your profile starts with an account': 'Профиль начинается с аккаунта',
  'See your posts, saved photos and presets in one place.':
      'Посты, сохранённые фото и пресеты — всё в одном месте.',
  'Add Supabase settings to enable accounts and community features.': 'Добавьте настройки Supabase, чтобы включить аккаунты и функции сообщества.',
  'Sign in or create account': 'Войти или создать аккаунт',
  'Settings': 'Настройки',
  'Edit profile': 'Редактировать профиль',
  'Posts': 'Посты',
  'Saved': 'Сохранённые',
  'My Posts': 'Мои посты',
  'My Presets': 'Мои пресеты',
  'Your posts will appear here.': 'Здесь появятся ваши посты.',
  'Save a photo and it will be waiting here.':
      'Сохраните фото, и оно появится здесь.',
  'Presets from your posts will appear here.':
      'Здесь появятся пресеты из ваших постов.',
  'Delete this post?': 'Удалить этот пост?',
  'The photo will be removed from the feed.': 'Фото исчезнет из ленты.',
  'Cancel': 'Отмена',
  'Delete': 'Удалить',
  'Enter a display name and a username with at least 3 characters.':
      'Введите отображаемое имя и имя пользователя не короче 3 символов.',
  'Sign in again to edit your profile.':
      'Войдите снова, чтобы редактировать профиль.',
  'Display name': 'Отображаемое имя',
  'Bio': 'О себе',
  'Save changes': 'Сохранить',
  'Delete post': 'Удалить пост',
  'Remove saved photo': 'Убрать из сохранённых',
  'Could not load this profile.': 'Не удалось загрузить профиль.',
  'Could not load. Try again.': 'Не удалось загрузить. Повторить.',
};
