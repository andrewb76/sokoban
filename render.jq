#render

# .field | join("\n")

def color(c; s): "\u001b[38;5;\(c)m\(s)\u001b[0m";

.field | map(
    split("") | 
    map(
        if . == " " then "  "
        elif . == "#" then color(240; "██")
        elif . == "$" then color(214; "⬒ ")
        elif . == "." then color(196; "◉ ")
        elif . == "*" then color(46; "⬒◉")
        elif . == "@" then color(39; "Ⓟ ")
        elif . == "+" then color(129; "Ⓟ◉")
        else . end
    ) | 
    join("")
) | 
join("\n")