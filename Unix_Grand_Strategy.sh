#!/bin/sh

# TerminalConqueror.sh - Grand Strategy Game with OS-specific features
# Inspired by AoH3, HOI4, Risk and more!

# Detect OS for specific features
OS=""
case "$(uname -s)" in
    Linux*)     OS="Linux";;
    FreeBSD*)   OS="FreeBSD";;
    OpenBSD*)   OS="OpenBSD";;
    Darwin*)    OS="MacOS";;
    *)          OS="Unknown";;
esac

# ====== GAME CONFIG ======
VERSION="1.2"
MAP_WIDTH=20
MAP_HEIGHT=10
COUNTRIES="Europa Atlantis Sparta Vikingland Oceania Eastasia"
COLORS="31 32 33 34 35 36" # Red, Green, Yellow, Blue, Magenta, Cyan
SPECIAL_EVENTS="Earthquake Plague Rebellion Alliance"

# ====== PLAYER DATA ======
PLAYER_COUNTRY=""
PLAYER_GOLD=100
PLAYER_ARMY=50
PLAYER_TECH=1
PLAYER_TERRITORIES=""
SAVE_FILE="terminal_conqueror_save.txt"

# ====== GAME DATA ======
WORLD_MAP=""
COUNTRY_OWNER=""
COUNTRY_ARMY=""
COUNTRY_TECH=""
COUNTRY_GOLD=""
DIPLOMACY=""
TURN=1

# ====== FUNCTIONS ======

# OS-specific features
os_specific_features() {
    case "$OS" in
        Linux)
            # Linux-specific features
            if [ -f "/proc/cpuinfo" ]; then
                CPU_CORES=$(grep -c processor /proc/cpuinfo)
                echo "Linux detected! Bonus: +$CPU_CORES gold per turn from optimized trade routes."
                PLAYER_GOLD=$((PLAYER_GOLD + CPU_CORES))
            fi
            ;;
        FreeBSD|OpenBSD)
            # BSD-specific features
            echo "$OS detected! Bonus: +10 army from hardened warriors."
            PLAYER_ARMY=$((PLAYER_ARMY + 10))
            ;;
        MacOS)
            # MacOS-specific features
            echo "MacOS detected! Bonus: +1 tech from advanced research labs."
            PLAYER_TECH=$((PLAYER_TECH + 1))
            ;;
        *)
            echo "Unknown OS - playing in compatibility mode"
            ;;
    esac
    sleep 2
}

# Generate world map with OS-specific terrain
generate_map() {
    WORLD_MAP=""
    COUNTRY_OWNER=""
    PLAYER_TERRITORIES=""
    
    # Initialize empty map with terrain based on OS
    y=0
    while [ $y -lt $MAP_HEIGHT ]; do
        x=0
        while [ $x -lt $MAP_WIDTH ]; do
            # Different terrain generation per OS
            case "$OS" in
                Linux)
                    terrain="."
                    ;;
                FreeBSD)
                    terrain="^"
                    ;;
                OpenBSD)
                    terrain="#"
                    ;;
                *)
                    terrain="."
                    ;;
            esac
            WORLD_MAP="${WORLD_MAP}${x},${y}=${terrain} "
            COUNTRY_OWNER="${COUNTRY_OWNER}${x},${y}= "
            x=$((x + 1))
        done
        y=$((y + 1))
    done

    # Assign territories to countries
    for country in $COUNTRIES; do
        COUNTRY_GOLD="${COUNTRY_GOLD}${country}=100 "
        COUNTRY_ARMY="${COUNTRY_ARMY}${country}=50 "
        COUNTRY_TECH="${COUNTRY_TECH}${country}=1 "
        DIPLOMACY="${DIPLOMACY}${country}=Neutral "

        # Random territories
        i=0
        while [ $i -lt 3 ]; do
            while true; do
                if [ "$OS" = "Linux" ]; then
                    x=$(( $(shuf -i 0-$((MAP_WIDTH - 1)) -n 1) ))
                    y=$(( $(shuf -i 0-$((MAP_HEIGHT - 1)) -n 1) ))
                else
                    x=$(( $(jot -r 1 0 $((MAP_WIDTH - 1))) ))
                    y=$(( $(jot -r 1 0 $((MAP_HEIGHT - 1))) ))
                fi
                cell=$(get_value "$WORLD_MAP" "$x,$y")
                if [ "$cell" = "." ] || [ "$cell" = "^" ] || [ "$cell" = "#" ]; then
                    WORLD_MAP=$(set_value "$WORLD_MAP" "$x,$y" "$(echo $country | cut -c1)")
                    COUNTRY_OWNER=$(set_value "$COUNTRY_OWNER" "$x,$y" "$country")
                    
                    if [ "$country" = "$PLAYER_COUNTRY" ]; then
                        PLAYER_TERRITORIES="${PLAYER_TERRITORIES}${x},${y} "
                    fi
                    break
                fi
            done
            i=$((i + 1))
        done
    done
}

# Get value from string "array"
get_value() {
    echo "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2
}

# Set value in string "array"
set_value() {
    echo "$1" | sed "s/$2=[^ ]*/$2=$3/"
}

# Draw the map with colors
draw_map() {
    clear
    echo "=== TERMINAL CONQUEROR v$VERSION ==="
    echo "OS: $OS | Turn: $TURN"
    echo "Country: $PLAYER_COUNTRY | Gold: $PLAYER_GOLD | Army: $PLAYER_ARMY | Tech: $PLAYER_TECH"
    echo "Territories: $(echo $PLAYER_TERRITORIES | wc -w | tr -d ' ')"
    echo

    y=0
    while [ $y -lt $MAP_HEIGHT ]; do
        x=0
        while [ $x -lt $MAP_WIDTH ]; do
            cell=$(get_value "$WORLD_MAP" "$x,$y")
            owner=$(get_value "$COUNTRY_OWNER" "$x,$y")
            color="37" # Default white

            # Find country color
            i=1
            for c in $COUNTRIES; do
                if [ "$owner" = "$c" ]; then
                    col=$(echo $COLORS | cut -d' ' -f$i)
                    color=$col
                    break
                fi
                i=$((i + 1))
            done

            printf "\033[1;${color}m%s\033[0m " "$cell"
            x=$((x + 1))
        done
        echo
        y=$((y + 1))
    done
    echo
}

# Random event system
random_event() {
    if [ $((RANDOM % 5)) -eq 0 ]; then
        event=$(echo $SPECIAL_EVENTS | tr ' ' '\n' | shuf -n 1)
        case "$event" in
            Earthquake)
                echo "EARTHQUAKE! Some territories lost armies."
                for coord in $PLAYER_TERRITORIES; do
                    if [ $((RANDOM % 3)) -eq 0 ]; then
                        PLAYER_ARMY=$((PLAYER_ARMY - 2))
                    fi
                done
                ;;
            Plague)
                echo "PLAGUE! Gold income reduced this turn."
                PLAYER_GOLD=$((PLAYER_GOLD / 2))
                ;;
            Rebellion)
                echo "REBELLION! Lost control of one territory."
                if [ $(echo $PLAYER_TERRITORIES | wc -w | tr -d ' ') -gt 1 ]; then
                    lost=$(echo $PLAYER_TERRITORIES | tr ' ' '\n' | shuf -n 1)
                    PLAYER_TERRITORIES=$(echo $PLAYER_TERRITORIES | sed "s/$lost//")
                    COUNTRY_OWNER=$(set_value "$COUNTRY_OWNER" "$lost" "Rebels")
                    WORLD_MAP=$(set_value "$WORLD_MAP" "$lost" "R")
                fi
                ;;
            Alliance)
                echo "ALLIANCE FORMED! Gained temporary army boost."
                PLAYER_ARMY=$((PLAYER_ARMY + 15))
                ;;
        esac
        sleep 2
    fi
}

# Main game loop with OS-specific options
game_loop() {
    while true; do
        draw_map
        echo "=== ACTIONS ==="
        echo "1. Recruit Army (10 gold)"
        echo "2. Research Tech (20 gold)"
        echo "3. Attack Territory"
        echo "4. Diplomacy"
        echo "5. Trade Routes"
        echo "6. End Turn"
        echo "7. Save & Exit"
        
        # OS-specific special action
        case "$OS" in
            Linux)
                echo "8. [Linux] Cyber Attack (30 gold)"
                ;;
            FreeBSD|OpenBSD)
                echo "8. [BSD] Fortify (20 gold)"
                ;;
            MacOS)
                echo "8. [MacOS] Tech Innovation (40 gold)"
                ;;
        esac
        
        printf "Choose: "
        read action

        case $action in
            1) recruit_army ;;
            2) research_tech ;;
            3) attack_territory ;;
            4) diplomacy_menu ;;
            5) trade_routes ;;
            6) end_turn ;;
            7) save_game; exit 0 ;;
            8) os_special_action ;;
            *) echo "Invalid choice!"; sleep 1 ;;
        esac
    done
}

# OS-specific special actions
os_special_action() {
    case "$OS" in
        Linux)
            if [ $PLAYER_GOLD -ge 30 ]; then
                PLAYER_GOLD=$((PLAYER_GOLD - 30))
                echo "Cyber Attack launched! Enemy tech levels reduced."
                for country in $COUNTRIES; do
                    if [ "$country" != "$PLAYER_COUNTRY" ]; then
                        current_tech=$(get_value "$COUNTRY_TECH" "$country")
                        COUNTRY_TECH=$(set_value "$COUNTRY_TECH" "$country" "$((current_tech > 1 ? current_tech - 1 : 1))")
                    fi
                done
            else
                echo "Not enough gold!"
            fi
            ;;
        FreeBSD|OpenBSD)
            if [ $PLAYER_GOLD -ge 20 ]; then
                PLAYER_GOLD=$((PLAYER_GOLD - 20))
                PLAYER_ARMY=$((PLAYER_ARMY + 20))
                echo "Fortifications built! Army +20."
            else
                echo "Not enough gold!"
            fi
            ;;
        MacOS)
            if [ $PLAYER_GOLD -ge 40 ]; then
                PLAYER_GOLD=$((PLAYER_GOLD - 40))
                PLAYER_TECH=$((PLAYER_TECH + 2))
                echo "Tech Innovation! Tech +2."
            else
                echo "Not enough gold!"
            fi
            ;;
        *)
            echo "No special action for your OS."
            ;;
    esac
    sleep 1
}

# New trade routes system
trade_routes() {
    echo "Establishing trade routes..."
    income=$(( $(echo $PLAYER_TERRITORIES | wc -w | tr -d ' ') * 2 ))
    PLAYER_GOLD=$((PLAYER_GOLD + income))
    echo "Gained $income gold from trade routes!"
    sleep 1
}

# Save game with OS-specific format
save_game() {
    echo "Saving game to $SAVE_FILE..."
    echo "VERSION=$VERSION" > $SAVE_FILE
    echo "OS=$OS" >> $SAVE_FILE
    echo "PLAYER_COUNTRY=$PLAYER_COUNTRY" >> $SAVE_FILE
    echo "PLAYER_GOLD=$PLAYER_GOLD" >> $SAVE_FILE
    echo "PLAYER_ARMY=$PLAYER_ARMY" >> $SAVE_FILE
    echo "PLAYER_TECH=$PLAYER_TECH" >> $SAVE_FILE
    echo "PLAYER_TERRITORIES=$PLAYER_TERRITORIES" >> $SAVE_FILE
    echo "WORLD_MAP=$WORLD_MAP" >> $SAVE_FILE
    echo "COUNTRY_OWNER=$COUNTRY_OWNER" >> $SAVE_FILE
    echo "COUNTRY_ARMY=$COUNTRY_ARMY" >> $SAVE_FILE
    echo "COUNTRY_TECH=$COUNTRY_TECH" >> $SAVE_FILE
    echo "COUNTRY_GOLD=$COUNTRY_GOLD" >> $SAVE_FILE
    echo "DIPLOMACY=$DIPLOMACY" >> $SAVE_FILE
    echo "TURN=$TURN" >> $SAVE_FILE
    sleep 1
}

# Load game with OS detection
load_game() {
    if [ -f "$SAVE_FILE" ]; then
        echo "Loading game from $SAVE_FILE..."
        . $SAVE_FILE
        OS=$(grep "^OS=" $SAVE_FILE | cut -d= -f2)
        sleep 1
        game_loop
    else
        echo "No save file found!"
        sleep 1
    fi
}

# Initialize game
main_menu() {
    while true; do
        clear
        echo "=== TERMINAL CONQUEROR ==="
        echo "1. New Game"
        echo "2. Load Game"
        echo "3. View GitHub (Linux)"
        echo "4. Exit"
        printf "Choose: "
        read choice

        case $choice in
            1) 
                new_game 
                os_specific_features
                ;;
            2) load_game ;;
            3) 
                if [ "$OS" = "Linux" ]; then
                    xdg-open "https://github.com/danast942/Bash-Grand-Strategy" 2>/dev/null || \
                    echo "Visit: https://github.com/danast942/Bash-Grand-Strategy"
                else
                    echo "This feature is Linux-only. Game will start normally."
                    sleep 1
                    new_game
                fi
                ;;
            4) exit 0 ;;
            *) echo "Invalid choice!"; sleep 1 ;;
        esac
    done
}

# Initialize new game
new_game() {
    clear
    echo "=== SELECT YOUR KINGDOM ==="
    i=1
    for country in $COUNTRIES; do
        echo "$i. $country"
        i=$((i + 1))
    done
    printf "Choose your country (1-%d): " $(echo $COUNTRIES | wc -w | tr -d ' ')
    read choice

    count=$(echo $COUNTRIES | wc -w | tr -d ' ')
    if [ $choice -ge 1 ] && [ $choice -le $count ]; then
        PLAYER_COUNTRY=$(echo $COUNTRIES | cut -d' ' -f$choice)
        generate_map
    else
        echo "Invalid choice!"
        sleep 1
        new_game
    fi
}

# ... (остальные функции остаются аналогичными, но адаптированными под BSD sh)

# Start the game
main_menu
