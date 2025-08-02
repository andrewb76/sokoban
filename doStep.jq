# doStep.jq

def getPlayer:
  . as $field |
  $field | length as $rowCount |
  $field | to_entries[] | select(.value | test("[@+]")) | .key as $playerRow |
  $field[$playerRow] | (index("@") // index("+")) as $playerCol |
  { val: $field[$playerRow][$playerCol:$playerCol+1], row: $playerRow, col: $playerCol };

def getPath:
  .player.row as $r | .player.col as $c | { key: "\($r):\($c)", value: .field[$r][$c] } as $p |
  if .dir == "r" and (.player.col + 2) < (.field[.player.row] | length) then 
     [$p, { key: "\($r):\($c+1)", value: .field[$r][$c+1] }, { key: "\($r):\($c+2)", value: .field[$r][$c+2] }] 
  elif .dir == "l" and (.player.col - 2) >= 0 then
     [$p, { key: "\($r):\($c-1)", value: .field[$r][$c-1] }, { key: "\($r):\($c-2)", value: .field[$r][$c-2] }] 
  elif .dir == "u" and (.player.row - 2) >= 0 then
     [$p, { key: "\($r-1):\($c)", value: .field[$r-1][$c] }, { key: "\($r-2):\($c)", value: .field[$r-2][$c] }]
  elif .dir == "d" and (.player.row + 2) < (.field | length) then
     [$p, { key: "\($r+1):\($c)", value: .field[$r+1][$c] }, { key: "\($r+2):\($c)", value: .field[$r+2][$c] }]
  else
    null
  end;

  def toArr:
    . | map(. | split(""));

def updatePath:
  if .[0].value == "@" and .[1].value == " " then 
    [.[0] + {value: " "}, .[1] + {value: "@"}, .[2]]  
  
  elif .[0].value == "@" and .[1].value == "." then 
    [.[0] + {value: " "}, .[1] + {value: "+"}, .[2]]

  elif .[0].value == "@" and .[1].value == "$" and .[2].value == " " then 
    [.[0] + {value: " "}, .[1] + {value: "@"}, .[2] + {value: "$"}]

  elif .[0].value == "@" and .[1].value == "$" and .[2].value == "." then 
    [.[0] + {value: " "}, .[1] + {value: "@"}, .[2] + {value: "*"}]

  elif .[0].value == "@" and .[1].value == "*" and .[2].value == " " then 
    [.[0] + {value: " "}, .[1] + {value: "+"}, .[2] + {value: "$"}]
  
  elif .[0].value == "@" and .[1].value == "*" and .[2].value == "." then 
    [.[0] + {value: " "}, .[1] + {value: "+"}, .[2] + {value: "*"}]


  elif .[0].value == "+" and .[1].value == " " then 
    [.[0] + {value: "."}, .[1] + {value: "@"}, .[2]]

  elif .[0].value == "+" and .[1].value == "." then 
    [.[0] + {value: "."}, .[1] + {value: "+"}, .[2]]

  elif .[0].value == "+" and .[1].value == "$" and .[2].value == " " then 
    [.[0] + {value: "."}, .[1] + {value: "@"}, .[2] + {value: "$"}]

  elif .[0].value == "+" and .[1].value == "$" and .[2].value == "." then 
    [.[0] + {value: "."}, .[1] + {value: "@"}, .[2] + {value: "*"}]

  elif .[0].value == "+" and .[1].value == "*" and .[2].value == " " then 
    [.[0] + {value: "."}, .[1] + {value: "+"}, .[2] + {value: "$"}]
  
  elif .[0].value == "+" and .[1].value == "*" and .[2].value == "." then 
    [.[0] + {value: "."}, .[1] + {value: "+"}, .[2] + {value: "*"}]

  else
   [.[0], .[1], .[2]]

  end;

def updateField(f):
  . as $replacements  # Сохраняем объект замен в переменную
  | f | to_entries    # Преобразуем массив в {index: строка}
  | map(
      .key as $row_index
      | .value | split("")  # Разбиваем строку на массив символов
      | to_entries          # Преобразуем в {index: символ}
      | map(
          .key as $col_index
          | .value as $char
          # Формируем ключ вида "строка:столбец"
          | ($replacements["\($row_index):\($col_index)"] // $char)
        )
      | join("")  # Собираем символы обратно в строку
    );

. as $game | $game.field | getPlayer as $player | { field: . | toArr, player: $player, dir: $dir } | 
  getPath | debug | updatePath | from_entries | debug | updateField($game.field) as $field |


{ 
  field: $field, 
  startedAt: $game.startedAt,
  steps: ($game.steps + 1)
}
