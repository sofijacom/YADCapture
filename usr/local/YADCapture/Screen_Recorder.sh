#!/bin/bash
# Script: Screen_Recorder
# autor: josejp2424
#version 0.2.2
# Versión con vista previa, control completo en systray, sonido y atajos
# licencia MIT
#30062025 Implementada función de vista previa con detección automática de reproductores
#30062025 Añadidos atajos de teclado globales (Ctrl+F pausa, Ctrl+S detiene)
#30062025 Mejorado el systray con iconos de estado
#30062025 Corregida limpieza de procesos xbindkeys
#300620025 Añadida internacionalización para nuevos textos
# Configuración de rutas
sound_file="/usr/local/YADCapture/camera-shutter.wav"
ICON_PATH="/usr/local/YADCapture/camera.svg"
RECORD_ICON="/usr/local/YADCapture/icons/media-record.svg"
PAUSE_ICON="/usr/local/YADCapture/icons/media-playback-pause.svg"
STOP_ICON="/usr/local/YADCapture/icons/media-playback-stop.svg"

TMP_DIR="/tmp/screen_recorder_$$"
mkdir -p "$TMP_DIR"
trap 'cleanup' EXIT

# Configuración predeterminada
FRAME_RATE=25
VIDEO_QUALITY=23  
AUDIO_BITRATE=128 
OUTPUT_DIR="$HOME"
FILE_NAME="Recording"
FILE_EXT="mp4"

# Variables de estado
is_recording=false
is_paused=false
ffmpeg_pid=""
systray_pid=""
xbindkeys_pid=""
current_screen=""
preview_pid=""

# Configuración de idioma
LANG_CODE="${LANG%_*}"  
declare -A lang_strings

cleanup() {
    stop_hotkeys
    [ -n "$ffmpeg_pid" ] && kill -INT "$ffmpeg_pid" 2>/dev/null
    [ -n "$systray_pid" ] && kill "$systray_pid" 2>/dev/null
    [ -n "$preview_pid" ] && kill "$preview_pid" 2>/dev/null

    pkill -f "xbindkeys" 2>/dev/null
    
    rm -rf "$TMP_DIR"
}

set_language_strings() {
    local lang="$1"
    
    # Español
    lang_strings[es,title]="Grabador de Pantalla"
    lang_strings[es,dependencies_error]="Faltan dependencias:\n%s\n\nInstale con: sudo apt install %s"
    lang_strings[es,screen_error]="No se pudo obtener información de la pantalla: %s"
    lang_strings[es,recording_title]="Grabación en curso"
    lang_strings[es,complete_title]="Grabación completada"
    lang_strings[es,complete_text]="Archivo guardado en:\n%s"
    lang_strings[es,error_title]="Error"
    lang_strings[es,screen_prompt]="Seleccione pantalla:"
    lang_strings[es,audio_prompt]="Incluir audio (solo interno)"
    lang_strings[es,quality_prompt]="Calidad de video (0-51):"
    lang_strings[es,dir_prompt]="Carpeta destino:"
    lang_strings[es,name_prompt]="Nombre del archivo:"
    lang_strings[es,record_button]="▶️ Iniciar Grabación"
    lang_strings[es,stop_button]="⏹ Detener"
    lang_strings[es,pause_button]="⏸ Pausar"
    lang_strings[es,resume_button]="▶ Reanudar"
    lang_strings[es,exit_button]="🚪 Salir"
    lang_strings[es,open_button]="📂 Abrir carpeta"
    lang_strings[es,preview_button]="🎬 Vista previa"
    lang_strings[es,close_button]="Cancelar"
    lang_strings[es,systray_recording]="Grabando %s"
    lang_strings[es,systray_paused]="Grabación pausada"
    lang_strings[es,systray_tooltip]="Grabador de Pantalla"
    lang_strings[es,no_player_error]="No se encontró ningún reproductor compatible (mpv, mplayer o ffplay)"

    # Inglés
    lang_strings[en,title]="Screen Recorder"
    lang_strings[en,dependencies_error]="Missing dependencies:\n%s\n\nInstall with: sudo apt install %s"
    lang_strings[en,screen_error]="Could not get screen information: %s"
    lang_strings[en,recording_title]="Recording in progress"
    lang_strings[en,complete_title]="Recording Complete"
    lang_strings[en,complete_text]="File saved at:\n%s"
    lang_strings[en,error_title]="Error"
    lang_strings[en,screen_prompt]="Select screen:"
    lang_strings[en,audio_prompt]="Include audio (internal only)"
    lang_strings[en,quality_prompt]="Video quality (0-51):"
    lang_strings[en,dir_prompt]="Destination folder:"
    lang_strings[en,name_prompt]="File name:"
    lang_strings[en,record_button]="▶️ Start Recording"
    lang_strings[en,stop_button]="⏹ Stop"
    lang_strings[en,pause_button]="⏸ Pause"
    lang_strings[en,resume_button]="▶ Resume"
    lang_strings[en,exit_button]="🚪 Exit"
    lang_strings[en,open_button]="📂 Open Folder"
    lang_strings[en,preview_button]="🎬 Preview"
    lang_strings[en,close_button]="Close"
    lang_strings[en,systray_recording]="Recording %s"
    lang_strings[en,systray_paused]="Recording Paused"
    lang_strings[en,systray_tooltip]="Screen Recorder"
    lang_strings[en,no_player_error]="No compatible player found (mpv, mplayer or ffplay)"

    # Árabe
    lang_strings[ar,title]="مسجل الشاشة"
    lang_strings[ar,dependencies_error]="توجد تبعيات مفقودة:\n%s\n\nقم بالتثبيت باستخدام: sudo apt install %s"
    lang_strings[ar,screen_error]="تعذر الحصول على معلومات الشاشة: %s"
    lang_strings[ar,recording_title]="جاري التسجيل"
    lang_strings[ar,complete_title]="اكتمل التسجيل"
    lang_strings[ar,complete_text]="تم حفظ الملف في:\n%s"
    lang_strings[ar,error_title]="خطأ"
    lang_strings[ar,screen_prompt]="اختر الشاشة:"
    lang_strings[ar,audio_prompt]="تضمين الصوت (داخلي فقط)"
    lang_strings[ar,quality_prompt]="جودة الفيديو (0-51):"
    lang_strings[ar,dir_prompt]="مجلد الوجهة:"
    lang_strings[ar,name_prompt]="اسم الملف:"
    lang_strings[ar,record_button]="▶️ بدء التسجيل"
    lang_strings[ar,stop_button]="⏹ إيقاف"
    lang_strings[ar,pause_button]="⏸ إيقاف مؤقت"
    lang_strings[ar,resume_button]="▶ استئناف"
    lang_strings[ar,exit_button]="🚪 خروج"
    lang_strings[ar,open_button]="📂 فتح المجلد"
    lang_strings[ar,preview_button]="🎬 معاينة"
    lang_strings[ar,close_button]="إغلاق"
    lang_strings[ar,systray_recording]="جاري التسجيل %s"
    lang_strings[ar,systray_paused]="التسجيل متوقف مؤقتًا"
    lang_strings[ar,systray_tooltip]="مسجل الشاشة"
    lang_strings[ar,no_player_error]="لم يتم العثور على مشغل متوافق (mpv, mplayer أو ffplay)"

    # Ruso
    lang_strings[ru,title]="Запись экрана"
    lang_strings[ru,dependencies_error]="Отсутствуют зависимости:\n%s\n\nУстановите: sudo apt install %s"
    lang_strings[ru,screen_error]="Не удалось получить информацию об экране: %s"
    lang_strings[ru,recording_title]="Идет запись"
    lang_strings[ru,complete_title]="Запись завершена"
    lang_strings[ru,complete_text]="Файл сохранен в:\n%s"
    lang_strings[ru,error_title]="Ошибка"
    lang_strings[ru,screen_prompt]="Выберите экран:"
    lang_strings[ru,audio_prompt]="Включить звук (только внутренний)"
    lang_strings[ru,quality_prompt]="Качество видео (0-51):"
    lang_strings[ru,dir_prompt]="Папка назначения:"
    lang_strings[ru,name_prompt]="Имя файла:"
    lang_strings[ru,record_button]="▶️ Начать запись"
    lang_strings[ru,stop_button]="⏹ Остановить"
    lang_strings[ru,pause_button]="⏸ Пауза"
    lang_strings[ru,resume_button]="▶ Продолжить"
    lang_strings[ru,exit_button]="🚪 Выход"
    lang_strings[ru,open_button]="📂 Открыть папку"
    lang_strings[ru,preview_button]="🎬 Превью"
    lang_strings[ru,close_button]="Закрыть"
    lang_strings[ru,systray_recording]="Запись %s"
    lang_strings[ru,systray_paused]="Запись на паузе"
    lang_strings[ru,systray_tooltip]="Запись экрана"
    lang_strings[ru,no_player_error]="Совместимый плеер не найден (mpv, mplayer или ffplay)"

    # Italiano
    lang_strings[it,title]="Registratore Schermo"
    lang_strings[it,dependencies_error]="Dipendenze mancanti:\n%s\n\nInstalla con: sudo apt install %s"
    lang_strings[it,screen_error]="Impossibile ottenere informazioni sullo schermo: %s"
    lang_strings[it,recording_title]="Registrazione in corso"
    lang_strings[it,complete_title]="Registrazione completata"
    lang_strings[it,complete_text]="File salvato in:\n%s"
    lang_strings[it,error_title]="Errore"
    lang_strings[it,screen_prompt]="Seleziona schermo:"
    lang_strings[it,audio_prompt]="Includi audio (solo interno)"
    lang_strings[it,quality_prompt]="Qualità video (0-51):"
    lang_strings[it,dir_prompt]="Cartella destinazione:"
    lang_strings[it,name_prompt]="Nome file:"
    lang_strings[it,record_button]="▶️ Inizia registrazione"
    lang_strings[it,stop_button]="⏹ Ferma"
    lang_strings[it,pause_button]="⏸ Pausa"
    lang_strings[it,resume_button]="▶ Riprendi"
    lang_strings[it,exit_button]="🚪 Esci"
    lang_strings[it,open_button]="📂 Apri cartella"
    lang_strings[it,preview_button]="🎬 Anteprima"
    lang_strings[it,close_button]="Chiudi"
    lang_strings[it,systray_recording]="Registrando %s"
    lang_strings[it,systray_paused]="Registrazione in pausa"
    lang_strings[it,systray_tooltip]="Registratore schermo"
    lang_strings[it,no_player_error]="Nessun lettore compatibile trovato (mpv, mplayer o ffplay)"

    # Francés
    lang_strings[fr,title]="Enregistreur d'écran"
    lang_strings[fr,dependencies_error]="Dépendances manquantes:\n%s\n\nInstallez avec: sudo apt install %s"
    lang_strings[fr,screen_error]="Impossible d'obtenir les informations de l'écran: %s"
    lang_strings[fr,recording_title]="Enregistrement en cours"
    lang_strings[fr,complete_title]="Enregistrement terminé"
    lang_strings[fr,complete_text]="Fichier enregistré dans:\n%s"
    lang_strings[fr,error_title]="Erreur"
    lang_strings[fr,screen_prompt]="Sélectionnez l'écran:"
    lang_strings[fr,audio_prompt]="Inclure l'audio (interne seulement)"
    lang_strings[fr,quality_prompt]="Qualité vidéo (0-51):"
    lang_strings[fr,dir_prompt]="Dossier de destination:"
    lang_strings[fr,name_prompt]="Nom du fichier:"
    lang_strings[fr,record_button]="▶️ Démarrer l'enregistrement"
    lang_strings[fr,stop_button]="⏹ Arrêter"
    lang_strings[fr,pause_button]="⏸ Pause"
    lang_strings[fr,resume_button]="▶ Reprendre"
    lang_strings[fr,exit_button]="🚪 Quitter"
    lang_strings[fr,open_button]="📂 Ouvrir le dossier"
    lang_strings[fr,preview_button]="🎬 Aperçu"
    lang_strings[fr,close_button]="Fermer"
    lang_strings[fr,systray_recording]="Enregistrement %s"
    lang_strings[fr,systray_paused]="Enregistrement en pause"
    lang_strings[fr,systray_tooltip]="Enregistreur d'écran"
    lang_strings[fr,no_player_error]="Aucun lecteur compatible trouvé (mpv, mplayer ou ffplay)"

    # Húngaro
    lang_strings[hu,title]="Képernyőrögzítő"
    lang_strings[hu,dependencies_error]="Hiányzó függőségek:\n%s\n\nTelepítés: sudo apt install %s"
    lang_strings[hu,screen_error]="Nem sikerült lekérni a képernyő adatait: %s"
    lang_strings[hu,recording_title]="Felvétel folyamatban"
    lang_strings[hu,complete_title]="Felvétel kész"
    lang_strings[hu,complete_text]="Fájl mentve ide:\n%s"
    lang_strings[hu,error_title]="Hiba"
    lang_strings[hu,screen_prompt]="Válasszon képernyőt:"
    lang_strings[hu,audio_prompt]="Hang felvétele (csak belső)"
    lang_strings[hu,quality_prompt]="Videó minőség (0-51):"
    lang_strings[hu,dir_prompt]="Célmappa:"
    lang_strings[hu,name_prompt]="Fájlnév:"
    lang_strings[hu,record_button]="▶️ Felvétel indítása"
    lang_strings[hu,stop_button]="⏹ Leállítás"
    lang_strings[hu,pause_button]="⏸ Szünet"
    lang_strings[hu,resume_button]="▶ Folytatás"
    lang_strings[hu,exit_button]="🚪 Kilépés"
    lang_strings[hu,open_button]="📂 Mappa megnyitása"
    lang_strings[hu,preview_button]="🎬 Előnézet"
    lang_strings[hu,close_button]="Bezárás"
    lang_strings[hu,systray_recording]="Felvétel %s"
    lang_strings[hu,systray_paused]="Felvétel szünetel"
    lang_strings[hu,systray_tooltip]="Képernyőrögzítő"
    lang_strings[hu,no_player_error]="Nem található kompatibilis lejátszó (mpv, mplayer vagy ffplay)"

    # Japonés
    lang_strings[ja,title]="画面録画ツール"
    lang_strings[ja,dependencies_error]="必要な依存関係がありません:\n%s\n\nインストール: sudo apt install %s"
    lang_strings[ja,screen_error]="画面情報を取得できませんでした: %s"
    lang_strings[ja,recording_title]="録画中"
    lang_strings[ja,complete_title]="録画完了"
    lang_strings[ja,complete_text]="ファイルが保存されました:\n%s"
    lang_strings[ja,error_title]="エラー"
    lang_strings[ja,screen_prompt]="画面を選択:"
    lang_strings[ja,audio_prompt]="音声を含める (内部のみ)"
    lang_strings[ja,quality_prompt]="動画品質 (0-51):"
    lang_strings[ja,dir_prompt]="保存先フォルダ:"
    lang_strings[ja,name_prompt]="ファイル名:"
    lang_strings[ja,record_button]="▶️ 録画開始"
    lang_strings[ja,stop_button]="⏹ 停止"
    lang_strings[ja,pause_button]="⏸ 一時停止"
    lang_strings[ja,resume_button]="▶ 再開"
    lang_strings[ja,exit_button]="🚪 終了"
    lang_strings[ja,open_button]="📂 フォルダを開く"
    lang_strings[ja,preview_button]="🎬 プレビュー"
    lang_strings[ja,close_button]="閉じる"
    lang_strings[ja,systray_recording]="録画中 %s"
    lang_strings[ja,systray_paused]="一時停止中"
    lang_strings[ja,systray_tooltip]="画面録画ツール"
    lang_strings[ja,no_player_error]="互換性のあるプレーヤーが見つかりません (mpv, mplayer または ffplay)"

    # Chino simplificado
    lang_strings[zh,title]="屏幕录像机"
    lang_strings[zh,dependencies_error]="缺少依赖项:\n%s\n\n安装: sudo apt install %s"
    lang_strings[zh,screen_error]="无法获取屏幕信息: %s"
    lang_strings[zh,recording_title]="正在录制"
    lang_strings[zh,complete_title]="录制完成"
    lang_strings[zh,complete_text]="文件已保存到:\n%s"
    lang_strings[zh,error_title]="错误"
    lang_strings[zh,screen_prompt]="选择屏幕:"
    lang_strings[zh,audio_prompt]="包括音频 (仅内部)"
    lang_strings[zh,quality_prompt]="视频质量 (0-51):"
    lang_strings[zh,dir_prompt]="目标文件夹:"
    lang_strings[zh,name_prompt]="文件名:"
    lang_strings[zh,record_button]="▶️ 开始录制"
    lang_strings[zh,stop_button]="⏹ 停止"
    lang_strings[zh,pause_button]="⏸ 暂停"
    lang_strings[zh,resume_button]="▶ 继续"
    lang_strings[zh,exit_button]="🚪 退出"
    lang_strings[zh,open_button]="📂 打开文件夹"
    lang_strings[zh,preview_button]="🎬 预览"
    lang_strings[zh,close_button]="关闭"
    lang_strings[zh,systray_recording]="正在录制 %s"
    lang_strings[zh,systray_paused]="已暂停"
    lang_strings[zh,systray_tooltip]="屏幕录像机"
    lang_strings[zh,no_player_error]="未找到兼容的播放器 (mpv, mplayer 或 ffplay)"

    # Portugués
    lang_strings[pt,title]="Gravador de Tela"
    lang_strings[pt,dependencies_error]="Dependências ausentes:\n%s\n\nInstale com: sudo apt install %s"
    lang_strings[pt,screen_error]="Não foi possível obter informações da tela: %s"
    lang_strings[pt,recording_title]="Gravação em andamento"
    lang_strings[pt,complete_title]="Gravação concluída"
    lang_strings[pt,complete_text]="Arquivo salvo em:\n%s"
    lang_strings[pt,error_title]="Erro"
    lang_strings[pt,screen_prompt]="Selecione a tela:"
    lang_strings[pt,audio_prompt]="Incluir áudio (somente interno)"
    lang_strings[pt,quality_prompt]="Qualidade do vídeo (0-51):"
    lang_strings[pt,dir_prompt]="Pasta de destino:"
    lang_strings[pt,name_prompt]="Nome do arquivo:"
    lang_strings[pt,record_button]="▶️ Iniciar gravação"
    lang_strings[pt,stop_button]="⏹ Parar"
    lang_strings[pt,pause_button]="⏸ Pausar"
    lang_strings[pt,resume_button]="▶ Retomar"
    lang_strings[pt,exit_button]="🚪 Sair"
    lang_strings[pt,open_button]="📂 Abrir pasta"
    lang_strings[pt,preview_button]="🎬 Visualizar"
    lang_strings[pt,close_button]="Fechar"
    lang_strings[pt,systray_recording]="Gravando %s"
    lang_strings[pt,systray_paused]="Gravação pausada"
    lang_strings[pt,systray_tooltip]="Gravador de Tela"
    lang_strings[pt,no_player_error]="Nenhum player compatível encontrado (mpv, mplayer ou ffplay)"

    # Catalán
    lang_strings[ca,title]="Gravador de Pantalla"
    lang_strings[ca,dependencies_error]="Falten dependències:\n%s\n\nInstal·leu amb: sudo apt install %s"
    lang_strings[ca,screen_error]="No s'ha pogut obtenir informació de la pantalla: %s"
    lang_strings[ca,recording_title]="Enregistrament en curs"
    lang_strings[ca,complete_title]="Enregistrament completat"
    lang_strings[ca,complete_text]="Fitxer desat a:\n%s"
    lang_strings[ca,error_title]="Error"
    lang_strings[ca,screen_prompt]="Seleccioneu pantalla:"
    lang_strings[ca,audio_prompt]="Incloure àudio (només intern)"
    lang_strings[ca,quality_prompt]="Qualitat de vídeo (0-51):"
    lang_strings[ca,dir_prompt]="Carpeta destí:"
    lang_strings[ca,name_prompt]="Nom del fitxer:"
    lang_strings[ca,record_button]="▶️ Iniciar enregistrament"
    lang_strings[ca,stop_button]="⏹ Aturar"
    lang_strings[ca,pause_button]="⏸ Pausa"
    lang_strings[ca,resume_button]="▶ Reprendre"
    lang_strings[ca,exit_button]="🚪 Sortir"
    lang_strings[ca,open_button]="📂 Obrir carpeta"
    lang_strings[ca,preview_button]="🎬 Vista prèvia"
    lang_strings[ca,close_button]="Tancar"
    lang_strings[ca,systray_recording]="Enregistrant %s"
    lang_strings[ca,systray_paused]="Enregistrament en pausa"
    lang_strings[ca,systray_tooltip]="Gravador de Pantalla"
    lang_strings[ca,no_player_error]="No s'ha trobat cap reproductor compatible (mpv, mplayer o ffplay)"

    # Vietnamita
    lang_strings[vi,title]="Màn hình ghi hình"
    lang_strings[vi,dependencies_error]="Thiếu phụ thuộc:\n%s\n\nCài đặt bằng: sudo apt install %s"
    lang_strings[vi,screen_error]="Không thể lấy thông tin màn hình: %s"
    lang_strings[vi,recording_title]="Đang ghi hình"
    lang_strings[vi,complete_title]="Ghi hình hoàn tất"
    lang_strings[vi,complete_text]="Tệp đã lưu tại:\n%s"
    lang_strings[vi,error_title]="Lỗi"
    lang_strings[vi,screen_prompt]="Chọn màn hình:"
    lang_strings[vi,audio_prompt]="Bao gồm âm thanh (chỉ nội bộ)"
    lang_strings[vi,quality_prompt]="Chất lượng video (0-51):"
    lang_strings[vi,dir_prompt]="Thư mục đích:"
    lang_strings[vi,name_prompt]="Tên tệp:"
    lang_strings[vi,record_button]="▶️ Bắt đầu ghi"
    lang_strings[vi,stop_button]="⏹ Dừng"
    lang_strings[vi,pause_button]="⏸ Tạm dừng"
    lang_strings[vi,resume_button]="▶ Tiếp tục"
    lang_strings[vi,exit_button]="🚪 Thoát"
    lang_strings[vi,open_button]="📂 Mở thư mục"
    lang_strings[vi,preview_button]="🎬 Xem trước"
    lang_strings[vi,close_button]="Đóng"
    lang_strings[vi,systray_recording]="Đang ghi %s"
    lang_strings[vi,systray_paused]="Tạm dừng ghi"
    lang_strings[vi,systray_tooltip]="Màn hình ghi hình"
    lang_strings[vi,no_player_error]="Không tìm thấy trình phát tương thích (mpv, mplayer hoặc ffplay)"
    
    [ -z "${lang_strings[$lang,title]}" ] && LANG_CODE="en"
}

get_text() {
    local key="$1"
    local text="${lang_strings[$LANG_CODE,$key]}"
    [ -z "$text" ] && text="${lang_strings[es,$key]}"
    printf "%s" "$text"
}

check_dependencies() {
    local missing=()
    for cmd in ffmpeg yad xrandr pactl xbindkeys; do
        command -v $cmd >/dev/null || missing+=("$cmd")
    done
    
    [ ${#missing[@]} -gt 0 ] && {
        yad --window-icon="$ICON_PATH" --image="$ICON_PATH" --center --error --title="$(get_text "error_title")" \
            --text="$(get_text "dependencies_error" "${missing[*]}" "${missing[*]}")"
        exit 1
    }
    
    if [ -f "$sound_file" ] && ! command -v aplay &>/dev/null; then
        missing+=("alsa-utils (para sonido)")
    fi
}

start_hotkeys() {
    stop_hotkeys
    
    cat > "$TMP_DIR/.xbindkeysrc" <<EOF
"echo pause > $TMP_DIR/control"
  Control + f

"echo stop > $TMP_DIR/control"
  Control + s
EOF

    xbindkeys -f "$TMP_DIR/.xbindkeysrc" &
    xbindkeys_pid=$!
}

stop_hotkeys() {
    pkill -f "xbindkeys -f $TMP_DIR/.xbindkeysrc" 2>/dev/null
    pkill -f "xbindkeys" 2>/dev/null  # Por si acaso
    xbindkeys_pid=""
}

play_sound() {
    [ -f "$sound_file" ] && aplay -q "$sound_file"
}

get_screens() {
    xrandr --current | grep " connected" | awk '{print $1}' > "$TMP_DIR/displays"
}

show_systray_menu() {
    if [ -n "$systray_pid" ] && kill -0 "$systray_pid" 2>/dev/null; then
        kill "$systray_pid" 2>/dev/null
        wait "$systray_pid" 2>/dev/null
    fi

    local menu_items=""
    local icon=""
    local tooltip=""

    if [ "$is_recording" = true ]; then
        if [ "$is_paused" = true ]; then
            menu_items+="$(get_text "resume_button")!bash -c 'echo pause > \"$TMP_DIR/control\"'|"
            icon="$RECORD_ICON"
            tooltip="$(get_text "systray_recording" "$current_screen")"
        else
            menu_items+="$(get_text "pause_button")!bash -c 'echo pause > \"$TMP_DIR/control\"'|"
            icon="$PAUSE_ICON"
            tooltip="$(get_text "systray_paused")"
        fi
        menu_items+="$(get_text "stop_button")!bash -c 'echo stop > \"$TMP_DIR/control\"'|"
    fi

    menu_items+="$(get_text "open_button")!xdg-open \"$OUTPUT_DIR\"|"
    menu_items+="$(get_text "exit_button")!bash -c 'echo quit > \"$TMP_DIR/control\"'"

    yad --window-icon="$ICON_PATH" --center --notification \
        --image="$icon" \
        --text="$tooltip" \
        --menu="$menu_items" \
        --command="" &

    systray_pid=$!
}

toggle_pause() {
    if [ "$is_paused" = false ]; then
        kill -STOP "$ffmpeg_pid"
        is_paused=true
    else
        kill -CONT "$ffmpeg_pid"
        is_paused=false
    fi
    play_sound
    show_systray_menu
}

preview_video() {
    local video_file="$1"
    
    local player=""
    if command -v mpv &>/dev/null; then
        player="mpv --quiet --force-window=immediate --loop --no-resume-playback"
    elif command -v mplayer &>/dev/null; then
        player="mplayer -quiet -loop 0"
    elif command -v ffplay &>/dev/null; then
        player="ffplay -autoexit -window_title \"Vista previa\""
    else
        yad --window-icon="$ICON_PATH" --image="$ICON_PATH" --center --error \
            --title="$(get_text "error_title")" \
            --text="$(get_text "no_player_error")"
        return 1
    fi

    eval "$player \"$video_file\"" &>/dev/null &
    preview_pid=$!
}

start_recording() {
    local screen="$1"
    local record_audio="$2"
    
    start_hotkeys
    
    local screen_info=$(xrandr --current | grep -w "$screen" | grep -oP '\d+x\d+\+\d+\+\d+')
    if [ -z "$screen_info" ]; then
        yad --window-icon="$ICON_PATH" --image="$ICON_PATH" --center --error --title="$(get_text "error_title")" \
            --text="$(get_text "screen_error" "$screen")"
        return 1
    fi

    local resolution=${screen_info%%+*}
    local position=${screen_info#*+}
    local output_file="${OUTPUT_DIR}/${FILE_NAME}-$(date +%Y%m%d-%H%M%S).${FILE_EXT}"
    
    mkdir -p "$OUTPUT_DIR"
    
    local cmd=(ffmpeg -hide_banner -loglevel error -f x11grab 
              -video_size "$resolution" -framerate "$FRAME_RATE" -i ":0.0+${position}")
    
    [ "$record_audio" = true ] && cmd+=(-f pulse -i "$(pactl get-default-sink).monitor" -c:a aac -b:a "${AUDIO_BITRATE}k")
    
    cmd+=(-c:v libx264 -crf "$VIDEO_QUALITY" -preset veryfast -pix_fmt yuv420p -y "$output_file")

    play_sound
    "${cmd[@]}" &> "$TMP_DIR/ffmpeg.log" &
    ffmpeg_pid=$!
    is_recording=true
    current_screen="$screen"
    current_output="$output_file"
    
    show_systray_menu
}

stop_recording() {
    play_sound
    kill -INT "$ffmpeg_pid" 2>/dev/null
    wait "$ffmpeg_pid"
    is_recording=false
    is_paused=false
    stop_hotkeys
    
    if [ -f "$current_output" ]; then
        response=$(yad --window-icon="$ICON_PATH" --image="$ICON_PATH" --center --info \
            --title="$(get_text "complete_title")" \
            --text="$(get_text "complete_text" "$current_output")" \
            --button="$(get_text "open_button")":0 \
            --button="$(get_text "preview_button")":1 \
            --button="$(get_text "close_button")":2)
        
        case $? in
            0) xdg-open "$OUTPUT_DIR" & ;;
            1) preview_video "$current_output" ;;
        esac
    else
        yad --window-icon="$ICON_PATH" --image="$ICON_PATH" --center --error \
            --title="$(get_text "error_title")" \
            --text="Error al crear el archivo de grabación"
    fi
    
    show_systray_menu
}

main_interface() {
    while true; do
        get_screens
        
        input=$(yad --center --form \
            --title="$(get_text "title")" \
            --window-icon="$ICON_PATH" \
            --image="$ICON_PATH" \
            --image-on-top \
            --width=400 \
            --field="$(get_text "screen_prompt"):CB" "$(tr '\n' '!' < "$TMP_DIR/displays")" \
            --field="$(get_text "audio_prompt"):CHK" TRUE \
            --field="$(get_text "quality_prompt"):NUM" "$VIDEO_QUALITY!0..51!1" \
            --field="$(get_text "dir_prompt"):DIR" "$OUTPUT_DIR" \
            --field="$(get_text "name_prompt")" "$FILE_NAME" \
            --button="$(get_text "record_button")":0 \
            --button="$(get_text "exit_button")":1)
        
        [ $? -ne 0 ] && break
        
        IFS='|' read -r screen record_audio VIDEO_QUALITY OUTPUT_DIR FILE_NAME <<< "$input"
        
        start_recording "$screen" "$([ "$record_audio" = "TRUE" ] && echo true || echo false)"
        
        while [ "$is_recording" = true ]; do
            if [ -f "$TMP_DIR/control" ]; then
                case $(cat "$TMP_DIR/control") in
                    "pause") toggle_pause ;;
                    "stop") stop_recording ;;
                    "quit") cleanup; exit 0 ;;
                esac
                rm -f "$TMP_DIR/control"
            fi
            sleep 0.5
        done
    done
}

# Inicio
set_language_strings "$LANG_CODE"
check_dependencies

show_systray_menu

main_interface
