#!/bin/bash

# Настройки терминала
stty -echo        # Отключаем вывод вводимых символов
stty -icanon      # Отключаем буферизацию строки
exec < /dev/tty   # Работаем напрямую с TTY


# Функция отрисовки экрана
draw_screen() {
    clear  # Очищаем экран

    jq -f -r render.jq game.json
    
    echo
    echo "Controls: W - Up, S - Down, A - Left, D - Right, Q - Quit"
}



# Основной цикл игры
while true; do
    draw_screen
    
    # Читаем ввод пользователя
    read -n1 -s input
    
    case $input in
        w|W) 
            jq -f --arg dir "u" doStep.jq game.json > temp.json && mv temp.json game.json; jq -f -r render.jq game.json
            ;;
        s|S) 
            jq -f --arg dir "d" doStep.jq game.json > temp.json && mv temp.json game.json; jq -f -r render.jq game.json
            ;;
        a|A) 
            jq -f --arg dir "l" doStep.jq game.json > temp.json && mv temp.json game.json; jq -f -r render.jq game.json
            ;;
        d|D) 
            jq -f --arg dir "r" doStep.jq game.json > temp.json && mv temp.json game.json; jq -f -r render.jq game.json
            ;;
        q|Q)
            # Восстанавливаем настройки терминала и выходим
            stty echo
            stty icanon
            clear
            exit 0
            ;;
    esac
done