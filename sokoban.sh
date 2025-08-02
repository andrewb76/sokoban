#!/bin/bash

# Проверка наличия необходимых утилит
if ! command -v dialog &> /dev/null; then
    echo "Error: dialog is not installed. Please install it."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it."
    exit 1
fi

# Функция выбора коллекции и уровня
choose_level() {
    local collections=()
    local options=()

    # Собираем все файлы коллекций
    while IFS= read -r -d $'\0' file; do
        collections+=("$file")
        options+=("$(basename "$file")" "")
    done < <(find "collections" -maxdepth 1 -name "*.json" -print0)

    if [ ${#collections[@]} -eq 0 ]; then
        dialog --msgbox "No collections found in 'collections' directory!" 10 40
        exit 1
    fi

    # Выбор коллекции
    local chosen_collection
    chosen_collection=$(dialog --stdout \
        --backtitle "Sokoban Game" \
        --title "Choose Collection" \
        --menu "Select a collection:" \
        20 60 10 \
        "${options[@]}")

    [ -z "$chosen_collection" ] && exit 0

    # Загружаем уровни из коллекции
    local levels
    levels=$(jq -r 'to_entries[] | "\(.key) \(.value.title)"' "collections/$chosen_collection")
    if [ -z "$levels" ]; then
        dialog --msgbox "No levels found in collection!" 10 40
        exit 1
    fi

    # Выбор уровня
    local level_options=()
    while read -r key value; do
        level_options+=("$key" "$value")
    done <<< "$levels"

    local chosen_level
    chosen_level=$(dialog --stdout \
        --backtitle "Sokoban Game" \
        --title "Choose Level" \
        --menu "Select a level:" \
        20 60 10 \
        "${level_options[@]}")

    [ -z "$chosen_level" ] && exit 0

    # Создаем game.json
    jq --argjson idx "$chosen_level" \
        --arg time "$(date +%s)" \
        '.[$idx] | {field: .rows, startedAt: $time, steps: 0, title: .title, author: .author, limit: .limit}' \
        "collections/$chosen_collection" > game.json
}

# Настройки терминала
cleanup_terminal() {
    stty echo
    stty icanon
    clear
    exec &> /dev/tty
}

trap cleanup_terminal EXIT

# Функция отрисовки экрана
draw_screen() {
  clear
  jq -f -r render.jq game.json
  
  echo
  echo "Controls: Arrows/WASD - Move, Q - Quit to Menu"
  echo "Level: $(jq -r '.title' game.json)"
  echo "Steps: $(jq -r '.steps' game.json)"
  echo "Limit: $(jq -r '.limit' game.json)"
}

# Основной цикл игры
while true; do
    choose_level
    
    while true; do
        stty -echo
        stty -icanon
        exec < /dev/tty
        
        draw_screen
        
        # Читаем ввод пользователя
        read -n1 -s input
        
        # Обработка стрелок и WASD
        if [[ "$input" == $'\e' ]]; then
            read -n2 -s -t 0.001 rest
            case "$rest" in
                "[A") dir="u" ;;  # Up
                "[B") dir="d" ;;  # Down
                "[C") dir="r" ;;  # Right
                "[D") dir="l" ;;  # Left
                *) continue ;;
            esac
        else
            case "$input" in
                w|W) dir="u" ;;
                s|S) dir="d" ;;
                a|A) dir="l" ;;
                d|D) dir="r" ;;
                q|Q) 
                    cleanup_terminal
                    break  # Выход в меню
                    ;;
                *) continue ;;
            esac
        fi

        # Обновляем состояние игры
        jq -f --arg dir "$dir" doStep.jq game.json > temp.json && mv temp.json game.json
        # Проверка на завершение уровня (дополнительно)
        if ! jq -e '.field[] | contains("@") or contains("+") | not' game.json > /dev/null; then
            dialog --msgbox "Level completed!\nSteps: $(jq '.steps' game.json)" 10 30
            cleanup_terminal
            break
        fi
    done
done