# dotfiles

Личные dotfiles (zsh) для всех машин. Общая конвенция + хост-специфичные оверрайды.

## Установка на новую машину

```bash
curl -fsSL https://raw.githubusercontent.com/QueryWorm/dotfiles/main/scripts/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

Скрипт сам поставит zsh/git если их нет, настроит SSH-ключ для GitHub (или предложит
переиспользовать уже существующий — см. ниже), склонирует репо, спросит роль машины
(`DOTFILES_ROLE`) и пропишет `~/.zshrc`.

Если на машине уже есть рабочий SSH-ключ, добавленный в GitHub (`ssh -T git@github.com`
отвечает `Hi QueryWorm!`) — не создавай новый, а скопируй под ожидаемым именем:

```bash
cp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_dotfiles
cp ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519_dotfiles.pub
```

и перезапусти `install.sh` — генерацию он пропустит.

## Структура

zsh/
.zsh_env # общие переменные окружения
.zsh_ui # алиасы/настройки внешнего вида шелла
.zsh_aliases # общие алиасы
.zsh_functions # общие функции (mkcd, mksh, setip и т.п.)
.zsh_dev # DEV-конвенция: $DEV, mkproject, venvon
hosts/
<role>.zsh # хост-специфичные алиасы/переменные (например, DEV override)
scripts/
install.sh # bootstrap для новой машины


`~/.zshrc` **не хранится в репо** (он машинно-специфичный: разные PATH под nvm/bun/opencode
и т.п. на разных машинах). Вместо этого на каждой машине он — тонкая обёртка, которая
сорсит файлы из `~/dotfiles/zsh/` и подключает хост-роль:

```bash
# dotfiles bootstrap
source ~/dotfiles/zsh/.zsh_env
source ~/dotfiles/zsh/.zsh_ui
source ~/dotfiles/zsh/.zsh_aliases
source ~/dotfiles/zsh/.zsh_functions
source ~/dotfiles/zsh/.zsh_dev
DOTFILES_ROLE="<role>"
[[ -f ~/dotfiles/zsh/hosts/$DOTFILES_ROLE.zsh ]] && \
  source ~/dotfiles/zsh/hosts/$DOTFILES_ROLE.zsh
```

Symlink-менеджеры (Stow/chezmoi) не нужны — `.zshrc` сорсит файлы напрямую из
`~/dotfiles`, поэтому `git pull` + новый шелл (или `source ~/.zshrc`) достаточно, чтобы
изменения применились.

## DEV-конвенция

Единая точка для кода — `$DEV` (по умолчанию `~/DEV`, на машинах с отдельным разделом
хранения переопределяется в `hosts/<role>.zsh`, например `export DEV=/mnt/storage/DEV`).

Venv — всегда **внутри** папки проекта, никогда отдельно/россыпью:

```bash
mkproject myproject   # создаёт $DEV/myproject + .venv внутри
cd $DEV/myproject
venvon                # активирует .venv (или venv) из текущей папки
```

## Текущие машины/роли

| Роль | Машина |
|---|---|
| `masha` | Ubuntu headless сервер (Chuwi) |
| `pi` | Raspberry Pi |
| `proxmox` | Ubuntu 24.04 на Proxmox (katya) |
| `casaos` | CasaOS (debik) |
| `wsl` | Windows WSL, юзер dasha |
| `debi-wsl` | Windows WSL, Debian-дистрибутив, юзер debi |

## Если нужно внести изменения

1. На любой машине с push-доступом отредактируй файл в `~/dotfiles/` (общий — в
   `zsh/`, под конкретный хост — в `zsh/hosts/<role>.zsh`).
2. Проверь что не сломал текущий шелл: `source ~/.zshrc`.
3. Закоммить и запушь:
```bash
   cd ~/dotfiles
   git add -A
   git commit -m "описание изменения"
   git push
```
4. На остальных машинах, когда удобно — подтянуть изменения и открыть новый шелл
   (или `source ~/.zshrc` в текущем):
```bash
   cd ~/dotfiles && git pull
```
   Отдельного шага "применить" не требуется — `.zshrc` сорсит файлы напрямую.

## Новая роль/хост

Если заводишь новую машину с уникальными настройками — просто создай
`zsh/hosts/<role>.zsh` (можно пустым как плейсхолдер) и укажи `<role>` при запуске
`install.sh`, либо вручную впиши в `~/.zshrc`.
