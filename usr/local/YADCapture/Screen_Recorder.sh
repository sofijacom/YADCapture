#!/bin/bash
# Script: Screen_Recorder
# autor: josejp2424
# Grabador de Pantalla Mejorado - Versión con spinner animado funcional y soporte multidioma
# licencia MIT
# Configuración de rutas
sound_file="/usr/local/YADCapture/camera-shutter.wav"
ICON_PATH="/usr/local/YADCapture/camera.svg"
SPINNER_GIF="/usr/local/YADCapture/spinner.gif"

TMP_DIR="/tmp/screen_recorder_$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# Configuración predeterminada
FRAME_RATE=25
VIDEO_QUALITY=23  
AUDIO_BITRATE=128 
OUTPUT_DIR="$HOME"
FILE_NAME="Grabacion"
FILE_EXT="mp4"

# Configuración de idioma (basado en el locale del sistema)
LANG_CODE="${LANG%_*}"  

declare -A lang_strings

set_language_strings() {
    local lang="$1"
    
    # Español
    lang_strings[es,title]="Grabador de Pantalla"
    lang_strings[es,dependencies_error]="Faltan dependencias:\n%s\n\nInstale con: sudo apt install %s"
    lang_strings[es,spinner_error]="No se encontró el archivo spinner.gif en:\n%s"
    lang_strings[es,screen_error]="No se pudo obtener información de la pantalla: %s"
    lang_strings[es,recording_title]="Grabando..."
    lang_strings[es,recording_text]="Grabando pantalla: %s\nArchivo: %s"
    lang_strings[es,complete_title]="Grabación completada"
    lang_strings[es,complete_text]="Archivo guardado en:\n%s"
    lang_strings[es,error_title]="Error"
    lang_strings[es,error_text]="No se pudo crear el archivo de grabación\nRevise %s para más detalles"
    lang_strings[es,screen_prompt]="Pantalla:"
    lang_strings[es,audio_prompt]="Incluir audio (solo interno)"
    lang_strings[es,quality_prompt]="Calidad video (0-51):"
    lang_strings[es,dir_prompt]="Carpeta destino:"
    lang_strings[es,name_prompt]="Nombre archivo:"
    lang_strings[es,record_button]="Iniciar grabación"
    lang_strings[es,exit_button]="Salir"
    lang_strings[es,stop_button]="Detener Grabación"
    lang_strings[es,open_button]="Abrir carpeta"
    lang_strings[es,close_button]="Cerrar"

    # Inglés
    lang_strings[en,title]="Screen Recorder"
    lang_strings[en,dependencies_error]="Missing dependencies:\n%s\n\nInstall with: sudo apt install %s"
    lang_strings[en,spinner_error]="Could not find spinner.gif at:\n%s"
    lang_strings[en,screen_error]="Could not get screen information: %s"
    lang_strings[en,recording_title]="Recording..."
    lang_strings[en,recording_text]="Recording screen: %s\nFile: %s"
    lang_strings[en,complete_title]="Recording Complete"
    lang_strings[en,complete_text]="File saved at:\n%s"
    lang_strings[en,error_title]="Error"
    lang_strings[en,error_text]="Could not create recording file\nCheck %s for details"
    lang_strings[en,screen_prompt]="Screen:"
    lang_strings[en,audio_prompt]="Include audio (internal only)"
    lang_strings[en,quality_prompt]="Video quality (0-51):"
    lang_strings[en,dir_prompt]="Destination folder:"
    lang_strings[en,name_prompt]="File name:"
    lang_strings[en,record_button]="Start Recording"
    lang_strings[en,exit_button]="Exit"
    lang_strings[en,stop_button]="Stop Recording"
    lang_strings[en,open_button]="Open Folder"
    lang_strings[en,close_button]="Close"

    # Árabe
    lang_strings[ar,title]="مسجل الشاشة"
    lang_strings[ar,dependencies_error]="المكتبات الناقصة:\n%s\n\nثبت باستخدام: sudo apt install %s"
    lang_strings[ar,spinner_error]="تعذر العثور على spinner.gif في:\n%s"
    lang_strings[ar,screen_error]="تعذر الحصول على معلومات الشاشة: %s"
    lang_strings[ar,recording_title]="جارٍ التسجيل..."
    lang_strings[ar,recording_text]="تسجيل الشاشة: %s\nالملف: %s"
    lang_strings[ar,complete_title]="تم الانتهاء من التسجيل"
    lang_strings[ar,complete_text]="تم حفظ الملف في:\n%s"
    lang_strings[ar,error_title]="خطأ"
    lang_strings[ar,error_text]="تعذر إنشاء ملف التسجيل\nتحقق من %s للمزيد من التفاصيل"
    lang_strings[ar,screen_prompt]="الشاشة:"
    lang_strings[ar,audio_prompt]="تضمين الصوت (داخلي فقط)"
    lang_strings[ar,quality_prompt]="جودة الفيديو (0-51):"
    lang_strings[ar,dir_prompt]="مجلد الوجهة:"
    lang_strings[ar,name_prompt]="اسم الملف:"
    lang_strings[ar,record_button]="بدء التسجيل"
    lang_strings[ar,exit_button]="خروج"
    lang_strings[ar,stop_button]="إيقاف التسجيل"
    lang_strings[ar,open_button]="فتح المجلد"
    lang_strings[ar,close_button]="إغلاق"

    # Catalán
    lang_strings[ca,title]="Grabador de Pantalla"
    lang_strings[ca,dependencies_error]="Falten dependències:\n%s\n\nInstal·la amb: sudo apt install %s"
    lang_strings[ca,spinner_error]="No s'ha trobat spinner.gif a:\n%s"
    lang_strings[ca,screen_error]="No s'ha pogut obtenir informació de la pantalla: %s"
    lang_strings[ca,recording_title]="Gravant..."
    lang_strings[ca,recording_text]="Gravant pantalla: %s\nFitxer: %s"
    lang_strings[ca,complete_title]="Gravació completada"
    lang_strings[ca,complete_text]="Fitxer desat a:\n%s"
    lang_strings[ca,error_title]="Error"
    lang_strings[ca,error_text]="No s'ha pogut crear el fitxer de gravació\nRevisa %s per a més detalls"
    lang_strings[ca,screen_prompt]="Pantalla:"
    lang_strings[ca,audio_prompt]="Incloure àudio (només intern)"
    lang_strings[ca,quality_prompt]="Qualitat del vídeo (0-51):"
    lang_strings[ca,dir_prompt]="Carpeta de destinació:"
    lang_strings[ca,name_prompt]="Nom del fitxer:"
    lang_strings[ca,record_button]="Iniciar gravació"
    lang_strings[ca,exit_button]="Sortir"
    lang_strings[ca,stop_button]="Aturar gravació"
    lang_strings[ca,open_button]="Obrir carpeta"
    lang_strings[ca,close_button]="Tancar"

    # Francés
    lang_strings[fr,title]="Enregistreur d'écran"
    lang_strings[fr,dependencies_error]="Dépendances manquantes :\n%s\n\nInstallez avec : sudo apt install %s"
    lang_strings[fr,spinner_error]="Fichier spinner.gif introuvable à :\n%s"
    lang_strings[fr,screen_error]="Impossible d'obtenir les informations de l'écran : %s"
    lang_strings[fr,recording_title]="Enregistrement..."
    lang_strings[fr,recording_text]="Écran en cours d'enregistrement : %s\nFichier : %s"
    lang_strings[fr,complete_title]="Enregistrement terminé"
    lang_strings[fr,complete_text]="Fichier enregistré à :\n%s"
    lang_strings[fr,error_title]="Erreur"
    lang_strings[fr,error_text]="Impossible de créer le fichier d'enregistrement\nVoir %s pour plus de détails"
    lang_strings[fr,screen_prompt]="Écran :"
    lang_strings[fr,audio_prompt]="Inclure l'audio (interne uniquement)"
    lang_strings[fr,quality_prompt]="Qualité vidéo (0-51) :"
    lang_strings[fr,dir_prompt]="Dossier de destination :"
    lang_strings[fr,name_prompt]="Nom du fichier :"
    lang_strings[fr,record_button]="Démarrer l'enregistrement"
    lang_strings[fr,exit_button]="Quitter"
    lang_strings[fr,stop_button]="Arrêter l'enregistrement"
    lang_strings[fr,open_button]="Ouvrir le dossier"
    lang_strings[fr,close_button]="Fermer"

    # Italiano
    lang_strings[it,title]="Registratore Schermo"
    lang_strings[it,dependencies_error]="Dipendenze mancanti:\n%s\n\nInstalla con: sudo apt install %s"
    lang_strings[it,spinner_error]="Impossibile trovare spinner.gif in:\n%s"
    lang_strings[it,screen_error]="Impossibile ottenere informazioni sullo schermo: %s"
    lang_strings[it,recording_title]="Registrazione in corso..."
    lang_strings[it,recording_text]="Registrando lo schermo: %s\nFile: %s"
    lang_strings[it,complete_title]="Registrazione completata"
    lang_strings[it,complete_text]="File salvato in:\n%s"
    lang_strings[it,error_title]="Errore"
    lang_strings[it,error_text]="Impossibile creare il file di registrazione\nControlla %s per maggiori dettagli"
    lang_strings[it,screen_prompt]="Schermo:"
    lang_strings[it,audio_prompt]="Includi audio (solo interno)"
    lang_strings[it,quality_prompt]="Qualità video (0-51):"
    lang_strings[it,dir_prompt]="Cartella di destinazione:"
    lang_strings[it,name_prompt]="Nome file:"
    lang_strings[it,record_button]="Avvia registrazione"
    lang_strings[it,exit_button]="Esci"
    lang_strings[it,stop_button]="Ferma registrazione"
    lang_strings[it,open_button]="Apri cartella"
    lang_strings[it,close_button]="Chiudi"

    # Húngaro
    lang_strings[hu,title]="Képernyőrögzítő"
    lang_strings[hu,dependencies_error]="Hiányzó csomagok:\n%s\n\nTelepítse ezzel: sudo apt install %s"
    lang_strings[hu,spinner_error]="Nem található spinner.gif itt:\n%s"
    lang_strings[hu,screen_error]="Nem sikerült lekérni a képernyő információt: %s"
    lang_strings[hu,recording_title]="Rögzítés..."
    lang_strings[hu,recording_text]="Képernyő rögzítése: %s\nFájl: %s"
    lang_strings[hu,complete_title]="Rögzítés kész"
    lang_strings[hu,complete_text]="Fájl elmentve ide:\n%s"
    lang_strings[hu,error_title]="Hiba"
    lang_strings[hu,error_text]="Nem sikerült létrehozni a felvételi fájlt\nNézze meg: %s"
    lang_strings[hu,screen_prompt]="Képernyő:"
    lang_strings[hu,audio_prompt]="Hang rögzítése (csak belső)"
    lang_strings[hu,quality_prompt]="Videóminőség (0-51):"
    lang_strings[hu,dir_prompt]="Célkönyvtár:"
    lang_strings[hu,name_prompt]="Fájlnév:"
    lang_strings[hu,record_button]="Rögzítés indítása"
    lang_strings[hu,exit_button]="Kilépés"
    lang_strings[hu,stop_button]="Rögzítés leállítása"
    lang_strings[hu,open_button]="Mappa megnyitása"
    lang_strings[hu,close_button]="Bezárás"

    # Vietnamita
    lang_strings[vi,title]="Trình ghi màn hình"
    lang_strings[vi,dependencies_error]="Thiếu phụ thuộc:\n%s\n\nCài bằng: sudo apt install %s"
    lang_strings[vi,spinner_error]="Không tìm thấy spinner.gif tại:\n%s"
    lang_strings[vi,screen_error]="Không thể lấy thông tin màn hình: %s"
    lang_strings[vi,recording_title]="Đang ghi..."
    lang_strings[vi,recording_text]="Đang ghi màn hình: %s\nTệp: %s"
    lang_strings[vi,complete_title]="Hoàn tất ghi hình"
    lang_strings[vi,complete_text]="Tệp đã lưu tại:\n%s"
    lang_strings[vi,error_title]="Lỗi"
    lang_strings[vi,error_text]="Không thể tạo tệp ghi hình\nKiểm tra %s để biết thêm chi tiết"
    lang_strings[vi,screen_prompt]="Màn hình:"
    lang_strings[vi,audio_prompt]="Ghi âm (chỉ nội bộ)"
    lang_strings[vi,quality_prompt]="Chất lượng video (0-51):"
    lang_strings[vi,dir_prompt]="Thư mục lưu:"
    lang_strings[vi,name_prompt]="Tên tệp:"
    lang_strings[vi,record_button]="Bắt đầu ghi"
    lang_strings[vi,exit_button]="Thoát"
    lang_strings[vi,stop_button]="Dừng ghi"
    lang_strings[vi,open_button]="Mở thư mục"
    lang_strings[vi,close_button]="Đóng"

    # Alemán
    lang_strings[de,title]="Bildschirmaufnahme"
    lang_strings[de,dependencies_error]="Fehlende Abhängigkeiten:\n%s\n\nInstallieren mit: sudo apt install %s"
    lang_strings[de,spinner_error]="spinner.gif nicht gefunden unter:\n%s"
    lang_strings[de,screen_error]="Bildschirminformationen konnten nicht abgerufen werden: %s"
    lang_strings[de,recording_title]="Aufnahme läuft..."
    lang_strings[de,recording_text]="Bildschirm wird aufgenommen: %s\nDatei: %s"
    lang_strings[de,complete_title]="Aufnahme abgeschlossen"
    lang_strings[de,complete_text]="Datei gespeichert unter:\n%s"
    lang_strings[de,error_title]="Fehler"
    lang_strings[de,error_text]="Aufnahmedatei konnte nicht erstellt werden\nSiehe %s für weitere Details"
    lang_strings[de,screen_prompt]="Bildschirm:"
    lang_strings[de,audio_prompt]="Audio aufnehmen (nur intern)"
    lang_strings[de,quality_prompt]="Videoqualität (0-51):"
    lang_strings[de,dir_prompt]="Zielordner:"
    lang_strings[de,name_prompt]="Dateiname:"
    lang_strings[de,record_button]="Aufnahme starten"
    lang_strings[de,exit_button]="Beenden"
    lang_strings[de,stop_button]="Aufnahme stoppen"
    lang_strings[de,open_button]="Ordner öffnen"
    lang_strings[de,close_button]="Schließen"

    # Russian
    lang_strings[ru,title]="Запись экрана"
    lang_strings[ru,dependencies_error]="Отсутствующие зависимости:\n%s\n\nУстановите с помощью: sudo apt install %s"
    lang_strings[ru,spinner_error]="spinner.gif не найден в:\n%s"
    lang_strings[ru,screen_error]="Не удалось получить информацию о экране: %s"
    lang_strings[ru,recording_title]="Запись..."
    lang_strings[ru,recording_text]="Запись экрана: %s\nФайл: %s"
    lang_strings[ru,complete_title]="Запись завершена"
    lang_strings[ru,complete_text]="Файл сохранён в:\n%s"
    lang_strings[ru,error_title]="Ошибка"
    lang_strings[ru,error_text]="Не удалось создать файл записи\nПроверьте %s для получения подробностей"
    lang_strings[ru,screen_prompt]="Экран:"
    lang_strings[ru,audio_prompt]="Записать звук (только внутренний)"
    lang_strings[ru,quality_prompt]="Качество видео (0-51):"
    lang_strings[ru,dir_prompt]="Папка назначения:"
    lang_strings[ru,name_prompt]="Имя файла:"
    lang_strings[ru,record_button]="Начать запись"
    lang_strings[ru,exit_button]="Выход"
    lang_strings[ru,stop_button]="Остановить запись"
    lang_strings[ru,open_button]="Открыть папку"
    lang_strings[ru,close_button]="Закрыть"

    # Portugués
    lang_strings[pt,title]="Gravador de Tela"
    lang_strings[pt,dependencies_error]="Dependências ausentes:\n%s\n\nInstale com: sudo apt install %s"
    lang_strings[pt,spinner_error]="spinner.gif não encontrado em:\n%s"
    lang_strings[pt,screen_error]="Não foi possível obter informações da tela: %s"
    lang_strings[pt,recording_title]="Gravando..."
    lang_strings[pt,recording_text]="Gravando a tela: %s\nArquivo: %s"
    lang_strings[pt,complete_title]="Gravação completa"
    lang_strings[pt,complete_text]="Arquivo salvo em:\n%s"
    lang_strings[pt,error_title]="Erro"
    lang_strings[pt,error_text]="Não foi possível criar o arquivo de gravação\nVerifique %s para mais detalhes"
    lang_strings[pt,screen_prompt]="Tela:"
    lang_strings[pt,audio_prompt]="Incluir áudio (somente interno)"
    lang_strings[pt,quality_prompt]="Qualidade do vídeo (0-51):"
    lang_strings[pt,dir_prompt]="Pasta de destino:"
    lang_strings[pt,name_prompt]="Nome do arquivo:"
    lang_strings[pt,record_button]="Iniciar gravação"
    lang_strings[pt,exit_button]="Sair"
    lang_strings[pt,stop_button]="Parar gravação"
    lang_strings[pt,open_button]="Abrir pasta"
    lang_strings[pt,close_button]="Fechar"

    # Japonés
    lang_strings[ja,title]="スクリーンレコーダー"
    lang_strings[ja,dependencies_error]="不足している依存関係:\n%s\n\n以下でインストール: sudo apt install %s"
    lang_strings[ja,spinner_error]="spinner.gif が見つかりません:\n%s"
    lang_strings[ja,screen_error]="画面情報を取得できません: %s"
    lang_strings[ja,recording_title]="録画中..."
    lang_strings[ja,recording_text]="画面を録画中: %s\nファイル: %s"
    lang_strings[ja,complete_title]="録画完了"
    lang_strings[ja,complete_text]="ファイルが保存されました:\n%s"
    lang_strings[ja,error_title]="エラー"
    lang_strings[ja,error_text]="録画ファイルを作成できませんでした\n詳細は %s を確認してください"
    lang_strings[ja,screen_prompt]="画面:"
    lang_strings[ja,audio_prompt]="音声を含める（内部のみ）"
    lang_strings[ja,quality_prompt]="ビデオ品質 (0〜51):"
    lang_strings[ja,dir_prompt]="保存フォルダー:"
    lang_strings[ja,name_prompt]="ファイル名:"
    lang_strings[ja,record_button]="録画開始"
    lang_strings[ja,exit_button]="終了"
    lang_strings[ja,stop_button]="録画停止"
    lang_strings[ja,open_button]="フォルダーを開く"
    lang_strings[ja,close_button]="閉じる"

    # Chino simplificado
    lang_strings[zh_CN,title]="屏幕录制器"
    lang_strings[zh_CN,dependencies_error]="缺少依赖项：\n%s\n\n使用以下命令安装：sudo apt install %s"
    lang_strings[zh_CN,spinner_error]="未找到 spinner.gif：\n%s"
    lang_strings[zh_CN,screen_error]="无法获取屏幕信息：%s"
    lang_strings[zh_CN,recording_title]="正在录制..."
    lang_strings[zh_CN,recording_text]="正在录制屏幕：%s\n文件：%s"
    lang_strings[zh_CN,complete_title]="录制完成"
    lang_strings[zh_CN,complete_text]="文件已保存到：\n%s"
    lang_strings[zh_CN,error_title]="错误"
    lang_strings[zh_CN,error_text]="无法创建录制文件\n请查看 %s 获取详细信息"
    lang_strings[zh_CN,screen_prompt]="屏幕："
    lang_strings[zh_CN,audio_prompt]="包含音频（仅限内部）"
    lang_strings[zh_CN,quality_prompt]="视频质量 (0-51)："
    lang_strings[zh_CN,dir_prompt]="目标文件夹："
    lang_strings[zh_CN,name_prompt]="文件名："
    lang_strings[zh_CN,record_button]="开始录制"
    lang_strings[zh_CN,exit_button]="退出"
    lang_strings[zh_CN,stop_button]="停止录制"
    lang_strings[zh_CN,open_button]="打开文件夹"
    lang_strings[zh_CN,close_button]="关闭"
    
    # Inglés
    lang_strings[en,title]="Screen Recorder"
    lang_strings[en,dependencies_error]="Missing dependencies:\n%s\n\nInstall with: sudo apt install %s"
    lang_strings[en,spinner_error]="Could not find spinner.gif at:\n%s"
    lang_strings[en,screen_error]="Could not get screen information: %s"
    lang_strings[en,recording_title]="Recording..."
    lang_strings[en,recording_text]="Recording screen: %s\nFile: %s"
    lang_strings[en,complete_title]="Recording Complete"
    lang_strings[en,complete_text]="File saved at:\n%s"
    lang_strings[en,error_title]="Error"
    lang_strings[en,error_text]="Could not create recording file\nCheck %s for details"
    lang_strings[en,screen_prompt]="Screen:"
    lang_strings[en,audio_prompt]="Include audio (internal only)"
    lang_strings[en,quality_prompt]="Video quality (0-51):"
    lang_strings[en,dir_prompt]="Destination folder:"
    lang_strings[en,name_prompt]="File name:"
    lang_strings[en,record_button]="Start Recording"
    lang_strings[en,exit_button]="Exit"
    lang_strings[en,stop_button]="Stop Recording"
    lang_strings[en,open_button]="Open Folder"
    lang_strings[en,close_button]="Close"
    
    # Si el idioma no está configurado, usa español por defecto
    if [[ -z "${lang_strings[$lang,title]}" ]]; then
        LANG_CODE="en"
    fi
}

set_language_strings "$LANG_CODE"

get_text() {
    local key="$1"
    local params=("${@:2}")
    local text="${lang_strings[$LANG_CODE,$key]}"
    
    if [ -z "$text" ]; then
        text="${lang_strings[es,$key]}"
    fi
    
    if [ ${#params[@]} -gt 0 ]; then
        printf -v text "$text" "${params[@]}"
    fi
    
    echo "$text"
}

check_dependencies() {
    local missing=()
    
    if ! command -v ffmpeg >/dev/null; then
        missing+=("ffmpeg")
    fi
    
    if ! command -v yad >/dev/null; then
        missing+=("yad")
    fi
    
    if ! command -v xrandr >/dev/null; then
        missing+=("xrandr")
    fi
    
    if ! command -v pactl >/dev/null; then
        missing+=("pulseaudio-utils")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        yad --center --window-icon="$ICON_PATH" --error \
            --text="$(get_text "dependencies_error" "${missing[*]}" "${missing[*]}")" \
            --width=300 --title="$(get_text "error_title")"
        exit 1
    fi
    
    if [ ! -f "$SPINNER_GIF" ]; then
        yad --center --window-icon="$ICON_PATH" --error \
            --text="$(get_text "spinner_error" "$SPINNER_GIF")" \
            --width=300 --title="$(get_text "error_title")"
        exit 1
    fi
}

# Obtener pantallas disponibles
get_screens() {
    xrandr --current | grep " connected" | awk '{print $1}' > "$TMP_DIR/displays"
}

# Función principal de grabación
record_screen() {
    local screen="$1"
    local record_audio="$2"
    local ffmpeg_pid
    local spinner_pid
    
    # Obtener información de la pantalla
    local screen_info=$(xrandr --current | grep -w "$screen" | grep -oP '\d+x\d+\+\d+\+\d+')
    if [ -z "$screen_info" ]; then
        yad --center --window-icon="$ICON_PATH" --error \
            --text="$(get_text "screen_error" "$screen")" \
            --width=300 --title="$(get_text "error_title")"
        return 1
    fi
    
    local resolution=${screen_info%%+*}
    local position=${screen_info#*+}
    
    local output_file="${OUTPUT_DIR}/${FILE_NAME}-$(date +%Y%m%d-%H%M%S).${FILE_EXT}"
    
    mkdir -p "$OUTPUT_DIR"
    
    local cmd=(ffmpeg -hide_banner -loglevel error -stats -f x11grab -video_size "$resolution" -framerate "$FRAME_RATE" -i ":0.0+${position}")
    
    if [ "$record_audio" = true ]; then
        cmd+=(-f pulse -i "$(pactl get-default-sink).monitor" -c:a aac -b:a "${AUDIO_BITRATE}k")
    fi
    
    cmd+=(-c:v libx264 -crf "$VIDEO_QUALITY" -preset veryfast -pix_fmt yuv420p -y "$output_file")
    
    "${cmd[@]}" &> "$TMP_DIR/ffmpeg.log" &
    ffmpeg_pid=$!
    
    yad --center --window-icon="$ICON_PATH" --on-top --picture --filename="$SPINNER_GIF" --title="$(get_text "recording_title")" \
        --text="$(get_text "recording_text" "$screen" "${output_file##*/}")" \
        --button="$(get_text "stop_button"):0" --width=300 --height=100
    
    # Detener procesos
    kill -INT "$ffmpeg_pid" 2>/dev/null
    kill "$spinner_pid" 2>/dev/null
    wait "$ffmpeg_pid" 2>/dev/null
    
    # Verificar si se creó el archivo
    if [ -f "$output_file" ]; then
        yad --center --window-icon="$ICON_PATH" --info \
            --title="$(get_text "complete_title")" \
            --text="$(get_text "complete_text" "$output_file")" \
            --width=400 \
            --button="$(get_text "open_button"):0" \
            --button="$(get_text "close_button"):1"
        
        if [ $? -eq 0 ]; then
            xdg-open "$OUTPUT_DIR" &
        fi
    else
        yad --center --window-icon="$ICON_PATH" --error \
            --title="$(get_text "error_title")" \
            --text="$(get_text "error_text" "$TMP_DIR/ffmpeg.log")" \
            --width=400
    fi
}

# Interfaz principal
main_interface() {
    while true; do
        get_screens

        input=$(yad --center --form \
            --title="$(get_text "title")" \
            --window-icon="$ICON_PATH" \
            --image="$ICON_PATH" \
            --image-on-top \
            --align=center \
            --width=400 \
            --height=200 \
            --field="$(get_text "screen_prompt"):CB" "$(tr '\n' '!' < "$TMP_DIR/displays")" \
            --field="$(get_text "audio_prompt"):CHK" TRUE \
            --field="$(get_text "quality_prompt"):NUM" "$VIDEO_QUALITY!0..51!1" \
            --field="$(get_text "dir_prompt"):DIR" "$OUTPUT_DIR" \
            --field="$(get_text "name_prompt")" "$FILE_NAME" \
            --button="🎬$(get_text "record_button"):0" \
            --button="❌$(get_text "exit_button"):1" 2>/dev/null)
        
        [ $? -ne 0 ] && break
        
        # Procesar entrada
        screen=$(echo "$input" | cut -d'|' -f1)
        record_audio=$(echo "$input" | cut -d'|' -f2)
        VIDEO_QUALITY=$(echo "$input" | cut -d'|' -f3)
        OUTPUT_DIR=$(echo "$input" | cut -d'|' -f4)
        FILE_NAME=$(echo "$input" | cut -d'|' -f5)
        
        [ "$record_audio" = "TRUE" ] && record_audio=true || record_audio=false
        
        record_screen "$screen" "$record_audio"
    done
}

check_dependencies
main_interface
