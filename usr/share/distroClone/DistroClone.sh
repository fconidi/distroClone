#!/bin/bash
echo "=========================================="
echo "    $MSG_BANNER_TITLE     "
echo "=========================================="

set -e
set -o pipefail
trap '' PIPE

# Funzione per trovare logo DC (pacchetto .deb → genera con convert)
get_dc_logo() {
    local SIZE="${1:-128}"
    for s in "$SIZE" 256 128; do
        local ICON="/usr/share/icons/hicolor/${s}x${s}/apps/distroClone.png"
        if [ -f "$ICON" ]; then
            echo "$ICON"
            return 0
        fi
    done
    local TMP="/tmp/distroClone-logo-${SIZE}.png"
    if [ -f "$TMP" ]; then
        echo "$TMP"
        return 0
    fi
    # ImageMagick 7 usa 'magick', IM6 usa 'convert'
    local IM_CMD=""
    command -v magick >/dev/null 2>&1 && IM_CMD="magick"
    [ -z "$IM_CMD" ] && command -v convert >/dev/null 2>&1 && IM_CMD="convert"
    if [ -n "$IM_CMD" ]; then
        if [ "$SIZE" -eq 256 ]; then
            $IM_CMD -size 256x256 xc:transparent \
                -fill '#0d47a1' \
                -draw 'polygon 128,6 228,58 228,198 128,250 28,198 28,58' \
                -fill 'none' -strokewidth 5 -stroke '#1976d2' \
                -draw 'polygon 128,28 208,72 208,184 128,228 48,184 48,72' \
                -fill '#2196f3' \
                -draw 'polygon 128,58 184,88 184,168 128,198 72,168 72,88' \
                -fill 'white' -font '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' \
                -pointsize 56 -gravity center -annotate +0+0 'DC' \
                "$TMP" 2>/dev/null && echo "$TMP" && return 0
        else
            $IM_CMD -size 128x128 xc:transparent \
                -fill '#0d47a1' \
                -draw 'polygon 64,3 114,29 114,99 64,125 14,99 14,29' \
                -fill 'none' -strokewidth 3 -stroke '#1976d2' \
                -draw 'polygon 64,14 104,36 104,92 64,114 24,92 24,36' \
                -fill '#2196f3' \
                -draw 'polygon 64,29 92,44 92,84 64,99 36,84 36,44' \
                -fill 'white' -font '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' \
                -pointsize 28 -gravity center -annotate +0+0 'DC' \
                "$TMP" 2>/dev/null && echo "$TMP" && return 0
        fi
    fi
    echo ""
}

# ImageMagick command (globale per tutto lo script)
IM_CMD=""
command -v magick >/dev/null 2>&1 && IM_CMD="magick"
[ -z "$IM_CMD" ] && command -v convert >/dev/null 2>&1 && IM_CMD="convert"

############################################
# MULTILANGUAGE SUPPORT
############################################
# Auto-detect language from system locale or --lang flag
# Supported: en (English, default), it (Italian), fr (French), es (Spanish), de (German), pt (Portuguese)
# Usage: distroClone --lang=it

DISTROCLONE_LANG="${DISTROCLONE_LANG:-}"

# Parse --lang flag from arguments
for arg in "$@"; do
    case "$arg" in
        --lang=*) DISTROCLONE_LANG="${arg#--lang=}" ;;
    esac
done

# Auto-detect from system locale if not specified
if [ -z "$DISTROCLONE_LANG" ]; then
    SYS_LANG="${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}"
    case "$SYS_LANG" in
        it*) DISTROCLONE_LANG="it" ;;
        fr*) DISTROCLONE_LANG="fr" ;;
        es*) DISTROCLONE_LANG="es" ;;
        de*) DISTROCLONE_LANG="de" ;;
        pt*) DISTROCLONE_LANG="pt" ;;
        *)   DISTROCLONE_LANG="en" ;;
    esac
fi

load_lang_en() {
    # --- Startup ---
    MSG_BANNER_TITLE="🐧 DistroClone - Live ISO Builder"
    MSG_ERROR_OS_RELEASE="ERROR: /etc/os-release not found!"
    MSG_DETECTED_DISTRO="Detected distribution:"
    MSG_NAME="Name"
    MSG_VERSION="Version"
    MSG_DESKTOP="Desktop"
    MSG_ARCHITECTURE="Architecture"
    MSG_KERNEL="Kernel"

    # --- Splash ---
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Live ISO Builder</b></big>\n\n<i>Initializing, please wait...\nInstalling required packages...</i>\n"

    # --- GUI detection ---
    MSG_STEP0="[0/28] Auto-detect Distro"
    MSG_STEP1="[1/30] GUI Tool Selection"
    MSG_GUI_SELECTED="✓ Graphical interface selected"
    MSG_STEP2="[2/30] GUI Question Wrapper"
    MSG_STEP3="[3/30] Welcome GUI"
    MSG_YAD_DETECTED="✓ YAD detected - advanced interface"
    MSG_ZENITY_DETECTED="✓ Zenity detected - standard interface"
    MSG_NO_GUI="No GUI available - terminal mode"

    # --- Question wrapper ---
    MSG_BTN_YES="Yes"
    MSG_BTN_NO="No"
    MSG_TTY_YN="y/N"
    MSG_TTY_PROCEED_YN="y/n"

    # --- Welcome dialog ---
    MSG_WELCOME_TITLE="DistroClone Universal ISO Builder v1.4.7"
    MSG_WELCOME_HEADING="Welcome to DistroClone"
    MSG_WELCOME_SUBTITLE="Universal Live ISO Builder for distro Debian-based"
    MSG_SYSTEM_DETECTED="System Detected"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="ISO Created"
    MSG_ISO_GENERATED="ISO that will be generated"
    MSG_BUILD_CONFIG="$MSG_BUILD_CONFIG"
    MSG_FIELD_COMPRESSION="<b>Squashfs compression type</b>:"
    MSG_COMP_STANDARD="Standard xz (15-20 min)"
    MSG_COMP_FAST="Fast lz4 (5-10 min)"
    MSG_COMP_MAX="Maximum xz+bcj (25-35 min)"
    MSG_FIELD_PASSWORD="<b>Password root live system</b> (user: admin):"
    MSG_FIELD_HOSTNAME="<b>Hostname live system</b>:"
    MSG_MIN_REQUIREMENTS="Minimum Requirements"
    MSG_MIN_REQ_TEXT="• Disk space: 4-6 GB free in /mnt\n• RAM: 2 GB minimum\n• Estimated time: 10-30 minutes (depends on the compression)"
    MSG_BTN_CANCEL="Cancel!gtk-cancel"
    MSG_BTN_NEXT="Next - Start Build!gtk-ok"
    MSG_BUILD_CANCELED="Build canceled by user"
    MSG_CHOSEN_CONFIG="✓ Chosen configuration:"
    MSG_COMPRESSION="Compression"
    MSG_PASSWORD_ROOT="Password root"
    MSG_DEFAULT_ROOT="default (root)"
    MSG_PERSONALIZED="personalized"
    MSG_DEFAULT_CONFIG="✓ Using default configurations"
    MSG_ZENITY_MODE="(Zenity mode)"
    MSG_PROCESS="Process"
    MSG_PROCESS_TEXT="[00-28] Cloning → Configuration → Squashfs → ISO"
    MSG_PRESS_OK="Press OK to start creating the live ISO..."
    MSG_PROCEED_BUILD="Proceed with the build?"
    MSG_BUILD_CANCELLED="Build cancelled"

    # --- TTY welcome ---
    MSG_TTY_UNIVERSAL="Universal"
    MSG_TTY_LIVEISOBUILDER="Live ISO Builder for Debian-based"
    MSG_TTY_DATE="Date"
    MSG_TTY_SYSTEM_DETECTED="SYSTEM DETECTED"
    MSG_TTY_ISO_GENERATED="ISO THAT WILL BE GENERATED"
    MSG_TTY_REQUIREMENTS="REQUIREMENTS"
    MSG_TTY_DISKSPACE="Disk space: 4-6 GB free in /mnt"
    MSG_TTY_RAM="RAM: 2 GB minimum"
    MSG_TTY_TIME="Estimated time: 10-30 minutes"

    # --- Build log ---
    MSG_BUILDLOG_TITLE="DistroClone - Build Log"
    MSG_BTN_HIDE="Hide"

    # --- Steps ---
    MSG_STEP4="[4/30] Config"
    MSG_STEP5="[5/30] Cleanup mount"
    MSG_STEP6="[6/30] Mount directory"
    MSG_STEP7="[7/30][PRE] SOURCE & mount sanity check"
    MSG_ERR_SOURCE="ERROR: SOURCE must be / (found: \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="ERROR: DEST is already mounted"
    MSG_ERR_LIVEDIR_MOUNTED="ERROR: LIVE_DIR is mounted (recursive clone risk)"
    MSG_WARN_MULTI_ROOT="WARNING: multiple root filesystems detected"
    MSG_STEP8="[8/30] System Clone rsync (this may take several minutes)..."
    MSG_FORCED_CLEAN_HOME="→ Forced cleaning /home on cloned system"
    MSG_STEP9="[9/30] Cleanup build-only tools"
    MSG_ERR_DEST_NOTSET="ERROR: DEST not set or not a directory, cleanup skipped"
    MSG_STEP10="[10/30] Bind mount chroot"
    MSG_STEP11="[11/30] Remove host user"
    MSG_STEP12="[12/30] Prep /boot for Calamares"
    MSG_STEP13="[13/30] Cleanup pre-build"
    MSG_STEP14="[14/30] Logo-config-user-/etc/skel"

    # --- User config dialog ---
    MSG_USERCONF_TITLE="DistroClone - User Configurations"
    MSG_USERCONF_HEADING="<b>Copy user configurations to /etc/skel?</b>"
    MSG_USERCONF_TEXT="This will allow new users created after installation\nto have the same settings (theme, icons, desktop layout).\n\n<b>What will be copied:</b>\n- Desktop configurations (theme, icons, wallpaper)\n- Panel and dock layout\n- Application preferences\n\n<b>What will NOT be copied:</b>\n- Password and credentials\n- Cache and temporary files\n- VirtualBox/Nextcloud configurations etc etc\n\n<i>Recommended if you want to distribute an ISO with preset configurations.</i>"
    MSG_TTY_COPY_CONFIG="Copy configurations?"
    MSG_USER_DETECTED="→ User detected"
    MSG_SKEL_COPIED="✓ Configurations copied to /etc/skel"
    MSG_SKEL_NEWUSERS="✓ New users will have the same settings"
    MSG_SKEL_NOTFOUND="✗ Could not find user's .config for"
    MSG_SKEL_CLEANING="→ Cleaning /etc/skel from host configurations"
    MSG_SKEL_KEEPING="✓ Keeping default"
    MSG_SKEL_DEFAULT="→ /etc/skel kept with default configurations only"

    # --- Branding ---
    MSG_STEP15="[15/30] Dynamic branding Calamares"
    MSG_LOGO_COPIED="✓ Logo DistroClone copied"
    MSG_LOGO_NOTFOUND="→ DistroClone logo not found, generate integrated Hexagon logo"
    MSG_LOGO_GENERATED="✓ Built-in Hexagon DistroClone logo generated"
    MSG_WELCOME_COPIED="✓ Welcome screen DistroClone copied"
    MSG_WELCOME_NOTFOUND="→ Welcome screen DistroClone not found, generating placeholder"
    MSG_BRANDING_DESC="→ Creating branding.desc"
    MSG_BRANDING_QML="→ Creating show.qml"
    MSG_BRANDING_DONE="✓ Branding configured in"
    MSG_INSTALLER_COPIED="✓ DistroClone installer icon copied"
    MSG_INSTALLER_NOTFOUND="→ Installer icon not found, built-in Hexagon logo"
    MSG_INSTALLER_GENERATED="✓ Built-in Hexagon installer icon generated"

    # --- Chroot ---
    MSG_STEP16="[16/30] Chroot Config"
    MSG_CHROOT_INSTALLING="→ Chroot: installing packages and configuring (this may take several minutes)..."
    MSG_CHROOT_DONE="✓ Chroot configuration completed"

    # --- Post install ---
    MSG_STEP17="[17/30] Hook post-install cleanup"
    MSG_STEP18="[18/30] Umount chroot"
    MSG_STEP19="[19/30] Sanity check /boot"
    MSG_ERR_MISSING="ERROR: Missing"
    MSG_STEP20="[20/30] Copy kernel/initrd"
    MSG_ERR_KERNEL="ERROR: Kernel or initrd not found!"

    # --- Manual edit ---
    MSG_STEP21="[21/30] Advanced manual modifications"
    MSG_MANEDIT_TITLE="DistroClone - Advanced Configurations"
    MSG_MANEDIT_HEADING="<b>Do you want to make manual changes into the filesystem before creating the squashfs?</b>"
    MSG_MANEDIT_TEXT="This option is for advanced users who want:\n- Add/remove packages into the chroot\n- Edit configuration file\n- Customize your system before compression"
    MSG_MANEDIT_PATH="Path chroot:"
    MSG_MANEDIT_SELECT="Select <b>No</b> to continue normally."
    MSG_MANEDIT_ZENITY="Do you want to make manual changes to the filesystem before squashfs?"
    MSG_BTN_EDIT="Yes, I want to edit"
    MSG_BTN_CONTINUE="No, continue"
    MSG_PAUSE_TITLE="PAUSE - MANUAL CHANGES ENABLED"
    MSG_PAUSE_AVAILABLE="The filesystem is available in:"
    MSG_PAUSE_CHROOT="To enter the chroot:"
    MSG_PAUSE_DONE="When you're done, press ENTER to continue."
    MSG_PAUSE_ENTER="Press ENTER to continue creating the squashfs..."
    MSG_PAUSE_SHOOTING="Shooting in progress..."

    # --- Compression selection ---
    MSG_STEP22="[22/30] SquashFS compression selection"
    MSG_COMP_SELECT_TITLE="SquashFS compression"
    MSG_COMP_SELECT_TEXT="Select the type of compression:"
    MSG_COMP_USING="Using"
    MSG_COMP_CODE="Code"
    MSG_COMP_DESCRIPTION="Description"
    MSG_COMP_FAST_DESC="Fast (lz4, larger ISO)"
    MSG_COMP_STD_DESC="Standard (xz balanced)"
    MSG_COMP_MAX_DESC="Maximum compression (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="Select SquashFS compression:"
    MSG_TTY_COMP_FAST="Fast (lz4, 5-10 min)"
    MSG_TTY_COMP_STD="Standard (xz, 15-20 min) [default]"
    MSG_TTY_COMP_MAX="Maximum (xz+bcj, 25-35 min)"
    MSG_TTY_CHOICE="Choice (F/S/M)"
    MSG_COMP_FAST_LOG="→ Fast compression (lz4)"
    MSG_COMP_STD_LOG="→ Standard compression (xz)"
    MSG_COMP_MAX_LOG="→ Maximum compression (xz+bcj)"

    # --- Squashfs ---
    MSG_STEP23="[23/30] Creating filesystem.squashfs (this may take several minutes)..."
    MSG_SQUASH_SIZE="✓ Squashfs size"

    # --- GRUB ---
    MSG_STEP24="[24/30] GRUB configuration"
    MSG_GRUB_CUSTOM="✓ GRUB custom background copied (override)"
    MSG_GRUB_DEFAULT="✓ GRUB background default generated (dark blue glass)"
    MSG_GRUB_NOCONVERT="⚠ convert not available - fallback black background"
    MSG_STEP25="[25/30] GRUB EFI binaries"

    # --- EFI/ISO ---
    MSG_STEP26="[26/30] Creating efiboot.img"
    MSG_STEP27="[27/30] Creating isolinux BIOS"
    MSG_STEP28="[28/30] Creating ISO bootable (this may take several minutes)..."
    MSG_WARN_BIGISO="Warning: Big ISO, possible problems on older BIOSes"

    # --- Final ---
    MSG_STEP29="[29/30] Iso check and md5sum-sha256sum (this may take several minutes)..."
    MSG_ISO_SUCCESS="✓ ISO COMPLETED SUCCESSFULLY!"
    MSG_FILE="File"
    MSG_SIZE="Size"
    MSG_MD5_GEN="MD5 and sha256 checksum generation"
    MSG_CREATED="Create"
    MSG_TEST_ISO="To test the ISO:"
    MSG_TEST_QEMU="QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox: Create VM and mount"
    MSG_TEST_USB="USB: dd if="

    MSG_STEP30="[30/30] (Last Step) Host system cleanup"
    MSG_REMOVING_CALAMARES="→ Removing Calamares from the host system..."
    MSG_WARN_CALA_FAIL="Warning: Calamares removal failed"
    MSG_CALAMARES_REMOVED="✓ Calamares removed from host system"
    MSG_REMOVING_LIVEBOOT="→ Removing live-boot and others from the host system..."
    MSG_REMOVING_DIR="→ Removing directory..."

    # --- Final dialog ---
    MSG_COMPLETED_TITLE="DistroClone - Completed"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ISO created successfully!</b></big>"
    MSG_TEST_TEXT="<b>Test the ISO:</b>\n• QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox: Create VM and mount the ISO\n• USB: dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ ERROR: ISO not created!"
    MSG_ERROR_TITLE="DistroClone - Error"
    MSG_ISO_FAIL_BIG="<big><b>✗ ISO creation failed!</b></big>\n\nCheck the terminal for details."

    # --- show.qml (Calamares slideshow) ---
    MSG_QML_INSTALLING="Installing your system..."
    MSG_QML_WAIT="Please wait while files are copied"
    MSG_QML_CONFIGURING="Configuring your system..."
    MSG_QML_SERVICES="Setting up users and system services"
    MSG_QML_ALMOST="Almost done!"
    MSG_QML_COMPLETE="Installation will complete shortly"

    # --- GRUB menu entries ---
    MSG_GRUB_TRY="Try or Install"
    MSG_GRUB_SAFE="Live (Safe Graphics)"
    MSG_GRUB_INSTALL="Install"
}

load_lang_it() {
    # --- Startup ---
    MSG_BANNER_TITLE="🐧 DistroClone - Creatore ISO Live"
    MSG_ERROR_OS_RELEASE="ERRORE: /etc/os-release non trovato!"
    MSG_DETECTED_DISTRO="Distribuzione rilevata:"
    MSG_NAME="Nome"
    MSG_VERSION="Versione"
    MSG_DESKTOP="Desktop"
    MSG_ARCHITECTURE="Architettura"
    MSG_KERNEL="Kernel"

    # --- Splash ---
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Creatore ISO Live</b></big>\n\n<i>Inizializzazione in corso...\nInstallazione pacchetti necessari...</i>\n"

    # --- GUI detection ---
    MSG_STEP0="[0/28] Rilevamento automatico Distro"
    MSG_STEP1="[1/30] Selezione interfaccia grafica"
    MSG_GUI_SELECTED="✓ Interfaccia grafica selezionata"
    MSG_STEP2="[2/30] Wrapper domande GUI"
    MSG_STEP3="[3/30] Schermata di benvenuto"
    MSG_YAD_DETECTED="✓ YAD rilevato - interfaccia avanzata"
    MSG_ZENITY_DETECTED="✓ Zenity rilevato - interfaccia standard"
    MSG_NO_GUI="Nessuna GUI disponibile - modalità terminale"

    # --- Question wrapper ---
    MSG_BTN_YES="Sì"
    MSG_BTN_NO="No"
    MSG_TTY_YN="s/N"
    MSG_TTY_PROCEED_YN="s/n"

    # --- Welcome dialog ---
    MSG_WELCOME_TITLE="DistroClone Creatore Universale ISO v1.4.7"
    MSG_WELCOME_HEADING="Benvenuto in DistroClone"
    MSG_WELCOME_SUBTITLE="Creatore universale ISO Live per distribuzioni Debian-based"
    MSG_SYSTEM_DETECTED="Sistema Rilevato"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="ISO Creata"
    MSG_ISO_GENERATED="ISO che verrà generata"
    MSG_BUILD_CONFIG="Configurazione del processo di build:"
    MSG_FIELD_COMPRESSION="<b>Tipo compressione Squashfs</b>:"
    MSG_COMP_STANDARD="Standard xz (15-20 min)"
    MSG_COMP_FAST="Veloce lz4 (5-10 min)"
    MSG_COMP_MAX="Massima xz+bcj (25-35 min)"
    MSG_FIELD_PASSWORD="<b>Password root sistema live</b> (utente: admin):"
    MSG_FIELD_HOSTNAME="<b>Hostname sistema live</b>:"
    MSG_MIN_REQUIREMENTS="Requisiti Minimi"
    MSG_MIN_REQ_TEXT="• Spazio disco: 4-6 GB liberi in /mnt\n• RAM: 2 GB minimo\n• Tempo stimato: 10-30 minuti (dipende dalla compressione)"
    MSG_BTN_CANCEL="Annulla!gtk-cancel"
    MSG_BTN_NEXT="Avanti - Avvia Build!gtk-ok"
    MSG_BUILD_CANCELED="Build annullato dall'utente"
    MSG_CHOSEN_CONFIG="✓ Configurazione scelta:"
    MSG_COMPRESSION="Compressione"
    MSG_PASSWORD_ROOT="Password root"
    MSG_DEFAULT_ROOT="predefinita (root)"
    MSG_PERSONALIZED="personalizzata"
    MSG_DEFAULT_CONFIG="✓ Configurazioni predefinite in uso"
    MSG_ZENITY_MODE="(modalità Zenity)"
    MSG_PROCESS="Processo"
    MSG_PROCESS_TEXT="[00-28] Clonazione → Configurazione → Squashfs → ISO"
    MSG_PRESS_OK="Premi OK per avviare la creazione della ISO live..."
    MSG_PROCEED_BUILD="Procedere con il build?"
    MSG_BUILD_CANCELLED="Build annullato"

    # --- TTY welcome ---
    MSG_TTY_UNIVERSAL="Universale"
    MSG_TTY_LIVEISOBUILDER="Creatore ISO Live per Debian-based"
    MSG_TTY_DATE="Data"
    MSG_TTY_SYSTEM_DETECTED="SISTEMA RILEVATO"
    MSG_TTY_ISO_GENERATED="ISO CHE VERRÀ GENERATA"
    MSG_TTY_REQUIREMENTS="REQUISITI"
    MSG_TTY_DISKSPACE="Spazio disco: 4-6 GB liberi in /mnt"
    MSG_TTY_RAM="RAM: 2 GB minimo"
    MSG_TTY_TIME="Tempo stimato: 10-30 minuti"

    # --- Build log ---
    MSG_BUILDLOG_TITLE="DistroClone - Log di Build"
    MSG_BTN_HIDE="Nascondi"

    # --- Steps ---
    MSG_STEP4="[4/30] Configurazione"
    MSG_STEP5="[5/30] Pulizia mount"
    MSG_STEP6="[6/30] Directory di mount"
    MSG_STEP7="[7/30][PRE] Controllo sorgente e mount"
    MSG_ERR_SOURCE="ERRORE: SOURCE deve essere / (trovato: \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="ERRORE: DEST è già montato"
    MSG_ERR_LIVEDIR_MOUNTED="ERRORE: LIVE_DIR è montato (rischio clone ricorsivo)"
    MSG_WARN_MULTI_ROOT="AVVISO: rilevati filesystem root multipli"
    MSG_STEP8="[8/30] Clonazione sistema rsync (potrebbe richiedere diversi minuti)..."
    MSG_FORCED_CLEAN_HOME="→ Pulizia forzata /home nel sistema clonato"
    MSG_STEP9="[9/30] Pulizia strumenti di build"
    MSG_ERR_DEST_NOTSET="ERRORE: DEST non impostato o non è una directory, pulizia saltata"
    MSG_STEP10="[10/30] Bind mount chroot"
    MSG_STEP11="[11/30] Rimozione utenti host"
    MSG_STEP12="[12/30] Preparazione /boot per Calamares"
    MSG_STEP13="[13/30] Pulizia pre-build"
    MSG_STEP14="[14/30] Logo-config-utente-/etc/skel"

    # --- User config dialog ---
    MSG_USERCONF_TITLE="DistroClone - Configurazioni Utente"
    MSG_USERCONF_HEADING="<b>Copiare le configurazioni utente in /etc/skel?</b>"
    MSG_USERCONF_TEXT="Questo permetterà ai nuovi utenti creati dopo l'installazione\ndi avere le stesse impostazioni (tema, icone, layout desktop).\n\n<b>Cosa verrà copiato:</b>\n- Configurazioni desktop (tema, icone, sfondo)\n- Layout pannello e dock\n- Preferenze applicazioni\n\n<b>Cosa NON verrà copiato:</b>\n- Password e credenziali\n- Cache e file temporanei\n- Configurazioni VirtualBox/Nextcloud ecc ecc\n\n<i>Consigliato se vuoi distribuire una ISO con configurazioni preimpostate.</i>"
    MSG_TTY_COPY_CONFIG="Copiare le configurazioni?"
    MSG_USER_DETECTED="→ Utente rilevato"
    MSG_SKEL_COPIED="✓ Configurazioni copiate in /etc/skel"
    MSG_SKEL_NEWUSERS="✓ I nuovi utenti avranno le stesse impostazioni"
    MSG_SKEL_NOTFOUND="✗ Impossibile trovare .config dell'utente"
    MSG_SKEL_CLEANING="→ Pulizia /etc/skel dalle configurazioni host"
    MSG_SKEL_KEEPING="✓ Mantenuto predefinito"
    MSG_SKEL_DEFAULT="→ /etc/skel mantenuto con configurazioni predefinite"

    # --- Branding ---
    MSG_STEP15="[15/30] Branding dinamico Calamares"
    MSG_LOGO_COPIED="✓ Logo DistroClone copiato"
    MSG_LOGO_NOTFOUND="→ Logo DistroClone non trovato, generazione logo esagonale integrato"
    MSG_LOGO_GENERATED="✓ Logo esagonale DistroClone integrato generato"
    MSG_WELCOME_COPIED="✓ Schermata di benvenuto DistroClone copiata"
    MSG_WELCOME_NOTFOUND="→ Schermata di benvenuto non trovata, generazione placeholder"
    MSG_BRANDING_DESC="→ Creazione branding.desc"
    MSG_BRANDING_QML="→ Creazione show.qml"
    MSG_BRANDING_DONE="✓ Branding configurato in"
    MSG_INSTALLER_COPIED="✓ Icona installer DistroClone copiata"
    MSG_INSTALLER_NOTFOUND="→ Icona installer non trovata, logo esagonale integrato"
    MSG_INSTALLER_GENERATED="✓ Icona esagonale installer generata"

    # --- Chroot ---
    MSG_STEP16="[16/30] Configurazione Chroot"
    MSG_CHROOT_INSTALLING="→ Chroot: installazione pacchetti e configurazione (potrebbe richiedere diversi minuti)..."
    MSG_CHROOT_DONE="✓ Configurazione chroot completata"

    # --- Post install ---
    MSG_STEP17="[17/30] Hook pulizia post-installazione"
    MSG_STEP18="[18/30] Umount chroot"
    MSG_STEP19="[19/30] Verifica /boot"
    MSG_ERR_MISSING="ERRORE: Mancante"
    MSG_STEP20="[20/30] Copia kernel/initrd"
    MSG_ERR_KERNEL="ERRORE: Kernel o initrd non trovati!"

    # --- Manual edit ---
    MSG_STEP21="[21/30] Modifiche manuali avanzate"
    MSG_MANEDIT_TITLE="DistroClone - Configurazioni Avanzate"
    MSG_MANEDIT_HEADING="<b>Vuoi apportare modifiche manuali al filesystem prima di creare lo squashfs?</b>"
    MSG_MANEDIT_TEXT="Questa opzione è per utenti avanzati che vogliono:\n- Aggiungere/rimuovere pacchetti nel chroot\n- Modificare file di configurazione\n- Personalizzare il sistema prima della compressione"
    MSG_MANEDIT_PATH="Percorso chroot:"
    MSG_MANEDIT_SELECT="Seleziona <b>No</b> per continuare normalmente."
    MSG_MANEDIT_ZENITY="Vuoi apportare modifiche manuali al filesystem prima dello squashfs?"
    MSG_BTN_EDIT="Sì, voglio modificare"
    MSG_BTN_CONTINUE="No, continua"
    MSG_PAUSE_TITLE="PAUSA - MODIFICHE MANUALI ABILITATE"
    MSG_PAUSE_AVAILABLE="Il filesystem è disponibile in:"
    MSG_PAUSE_CHROOT="Per entrare nel chroot:"
    MSG_PAUSE_DONE="Quando hai finito, premi INVIO per continuare."
    MSG_PAUSE_ENTER="Premi INVIO per continuare con la creazione dello squashfs..."
    MSG_PAUSE_SHOOTING="Creazione in corso..."

    # --- Compression selection ---
    MSG_STEP22="[22/30] Selezione compressione SquashFS"
    MSG_COMP_SELECT_TITLE="Compressione SquashFS"
    MSG_COMP_SELECT_TEXT="Seleziona il tipo di compressione:"
    MSG_COMP_USING="Usa"
    MSG_COMP_CODE="Codice"
    MSG_COMP_DESCRIPTION="Descrizione"
    MSG_COMP_FAST_DESC="Veloce (lz4, ISO più grande)"
    MSG_COMP_STD_DESC="Standard (xz bilanciato)"
    MSG_COMP_MAX_DESC="Compressione massima (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="Seleziona compressione SquashFS:"
    MSG_TTY_COMP_FAST="Veloce (lz4, 5-10 min)"
    MSG_TTY_COMP_STD="Standard (xz, 15-20 min) [predefinito]"
    MSG_TTY_COMP_MAX="Massima (xz+bcj, 25-35 min)"
    MSG_TTY_CHOICE="Scelta (F/S/M)"
    MSG_COMP_FAST_LOG="→ Compressione veloce (lz4)"
    MSG_COMP_STD_LOG="→ Compressione standard (xz)"
    MSG_COMP_MAX_LOG="→ Compressione massima (xz+bcj)"

    # --- Squashfs ---
    MSG_STEP23="[23/30] Creazione filesystem.squashfs (potrebbe richiedere diversi minuti)..."
    MSG_SQUASH_SIZE="✓ Dimensione Squashfs"

    # --- GRUB ---
    MSG_STEP24="[24/30] Configurazione GRUB"
    MSG_GRUB_CUSTOM="✓ Sfondo GRUB personalizzato copiato (override)"
    MSG_GRUB_DEFAULT="✓ Sfondo GRUB predefinito generato (blu scuro)"
    MSG_GRUB_NOCONVERT="⚠ convert non disponibile - sfondo nero di fallback"
    MSG_STEP25="[25/30] Binari GRUB EFI"

    # --- EFI/ISO ---
    MSG_STEP26="[26/30] Creazione efiboot.img"
    MSG_STEP27="[27/30] Creazione isolinux BIOS"
    MSG_STEP28="[28/30] Creazione ISO avviabile (potrebbe richiedere diversi minuti)..."
    MSG_WARN_BIGISO="Avviso: ISO grande, possibili problemi su BIOS vecchi"

    # --- Final ---
    MSG_STEP29="[29/30] Verifica ISO e md5sum-sha256sum (potrebbe richiedere diversi minuti)..."
    MSG_ISO_SUCCESS="✓ ISO COMPLETATA CON SUCCESSO!"
    MSG_FILE="File"
    MSG_SIZE="Dimensione"
    MSG_MD5_GEN="Generazione checksum MD5 e sha256"
    MSG_CREATED="Creati"
    MSG_TEST_ISO="Per testare la ISO:"
    MSG_TEST_QEMU="QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox: Crea una VM e monta"
    MSG_TEST_USB="USB: dd if="

    MSG_STEP30="[30/30] (Ultimo passo) Pulizia sistema host"
    MSG_REMOVING_CALAMARES="→ Rimozione Calamares dal sistema host..."
    MSG_WARN_CALA_FAIL="Avviso: Rimozione Calamares fallita"
    MSG_CALAMARES_REMOVED="✓ Calamares rimosso dal sistema host"
    MSG_REMOVING_LIVEBOOT="→ Rimozione live-boot e altri dal sistema host..."
    MSG_REMOVING_DIR="→ Rimozione directory..."

    # --- Final dialog ---
    MSG_COMPLETED_TITLE="DistroClone - Completato"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ISO creata con successo!</b></big>"
    MSG_TEST_TEXT="<b>Testa la ISO:</b>\n• QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox: Crea una VM e monta la ISO\n• USB: dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ ERRORE: ISO non creata!"
    MSG_ERROR_TITLE="DistroClone - Errore"
    MSG_ISO_FAIL_BIG="<big><b>✗ Creazione ISO fallita!</b></big>\n\nControlla il terminale per i dettagli."

    # --- show.qml (Calamares slideshow) ---
    MSG_QML_INSTALLING="Installazione del sistema in corso..."
    MSG_QML_WAIT="Attendere la copia dei file"
    MSG_QML_CONFIGURING="Configurazione del sistema..."
    MSG_QML_SERVICES="Configurazione utenti e servizi di sistema"
    MSG_QML_ALMOST="Quasi fatto!"
    MSG_QML_COMPLETE="L'installazione verrà completata a breve"

    # --- GRUB menu entries ---
    MSG_GRUB_TRY="Prova o Installa"
    MSG_GRUB_SAFE="Live (Grafica Sicura)"
    MSG_GRUB_INSTALL="Installa"
}

load_lang_fr() {
    MSG_BANNER_TITLE="🐧 DistroClone - Créateur d'ISO Live"
    MSG_ERROR_OS_RELEASE="ERREUR : /etc/os-release introuvable !"
    MSG_DETECTED_DISTRO="Distribution détectée :"
    MSG_NAME="Nom"
    MSG_VERSION="Version"
    MSG_DESKTOP="Bureau"
    MSG_ARCHITECTURE="Architecture"
    MSG_KERNEL="Noyau"
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Créateur d'ISO Live</b></big>\n\n<i>Initialisation en cours...\nInstallation des paquets requis...</i>\n"
    MSG_STEP0="[0/28] Détection automatique de la Distro"
    MSG_STEP1="[1/30] Sélection de l'interface graphique"
    MSG_GUI_SELECTED="✓ Interface graphique sélectionnée"
    MSG_STEP2="[2/30] Wrapper questions GUI"
    MSG_STEP3="[3/30] Écran d'accueil"
    MSG_YAD_DETECTED="✓ YAD détecté - interface avancée"
    MSG_ZENITY_DETECTED="✓ Zenity détecté - interface standard"
    MSG_NO_GUI="Aucune interface graphique disponible - mode terminal"
    MSG_BTN_YES="Oui"
    MSG_BTN_NO="Non"
    MSG_TTY_YN="o/N"
    MSG_TTY_PROCEED_YN="o/n"
    MSG_WELCOME_TITLE="DistroClone Créateur Universel d'ISO v1.4.7"
    MSG_WELCOME_HEADING="Bienvenue dans DistroClone"
    MSG_WELCOME_SUBTITLE="Créateur universel d'ISO Live pour distributions Debian"
    MSG_SYSTEM_DETECTED="Système Détecté"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="ISO Créée"
    MSG_ISO_GENERATED="ISO qui sera générée"
    MSG_BUILD_CONFIG="Configuration du processus de build :"
    MSG_FIELD_COMPRESSION="<b>Type de compression Squashfs</b> :"
    MSG_COMP_STANDARD="Standard xz (15-20 min)"
    MSG_COMP_FAST="Rapide lz4 (5-10 min)"
    MSG_COMP_MAX="Maximale xz+bcj (25-35 min)"
    MSG_FIELD_PASSWORD="<b>Mot de passe root système live</b> (utilisateur : admin) :"
    MSG_FIELD_HOSTNAME="<b>Nom d'hôte système live</b> :"
    MSG_MIN_REQUIREMENTS="Configuration Minimale Requise"
    MSG_MIN_REQ_TEXT="• Espace disque : 4-6 Go libres dans /mnt\n• RAM : 2 Go minimum\n• Temps estimé : 10-30 minutes (selon la compression)"
    MSG_BTN_CANCEL="Annuler!gtk-cancel"
    MSG_BTN_NEXT="Suivant - Démarrer le Build!gtk-ok"
    MSG_BUILD_CANCELED="Build annulé par l'utilisateur"
    MSG_CHOSEN_CONFIG="✓ Configuration choisie :"
    MSG_COMPRESSION="Compression"
    MSG_PASSWORD_ROOT="Mot de passe root"
    MSG_DEFAULT_ROOT="par défaut (root)"
    MSG_PERSONALIZED="personnalisé"
    MSG_DEFAULT_CONFIG="✓ Configurations par défaut utilisées"
    MSG_ZENITY_MODE="(mode Zenity)"
    MSG_PROCESS="Processus"
    MSG_PROCESS_TEXT="[00-28] Clonage → Configuration → Squashfs → ISO"
    MSG_PRESS_OK="Appuyez sur OK pour démarrer la création de l'ISO live..."
    MSG_PROCEED_BUILD="Procéder au build ?"
    MSG_BUILD_CANCELLED="Build annulé"
    MSG_TTY_UNIVERSAL="Universel"
    MSG_TTY_LIVEISOBUILDER="Créateur ISO Live pour Debian-based"
    MSG_TTY_DATE="Date"
    MSG_TTY_SYSTEM_DETECTED="SYSTÈME DÉTECTÉ"
    MSG_TTY_ISO_GENERATED="ISO QUI SERA GÉNÉRÉE"
    MSG_TTY_REQUIREMENTS="CONFIGURATION REQUISE"
    MSG_TTY_DISKSPACE="Espace disque : 4-6 Go libres dans /mnt"
    MSG_TTY_RAM="RAM : 2 Go minimum"
    MSG_TTY_TIME="Temps estimé : 10-30 minutes"
    MSG_BUILDLOG_TITLE="DistroClone - Journal de Build"
    MSG_BTN_HIDE="Masquer"
    MSG_STEP4="[4/30] Configuration"
    MSG_STEP5="[5/30] Nettoyage montages"
    MSG_STEP6="[6/30] Répertoire de montage"
    MSG_STEP7="[7/30][PRÉ] Vérification source et montages"
    MSG_ERR_SOURCE="ERREUR : SOURCE doit être / (trouvé : \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="ERREUR : DEST est déjà monté"
    MSG_ERR_LIVEDIR_MOUNTED="ERREUR : LIVE_DIR est monté (risque de clone récursif)"
    MSG_WARN_MULTI_ROOT="ATTENTION : systèmes de fichiers root multiples détectés"
    MSG_STEP8="[8/30] Clonage système rsync (cela peut prendre plusieurs minutes)..."
    MSG_FORCED_CLEAN_HOME="→ Nettoyage forcé de /home sur le système cloné"
    MSG_STEP9="[9/30] Nettoyage outils de build"
    MSG_ERR_DEST_NOTSET="ERREUR : DEST non défini ou n'est pas un répertoire, nettoyage ignoré"
    MSG_STEP10="[10/30] Montage bind chroot"
    MSG_STEP11="[11/30] Suppression utilisateurs hôte"
    MSG_STEP12="[12/30] Préparation /boot pour Calamares"
    MSG_STEP13="[13/30] Nettoyage pré-build"
    MSG_STEP14="[14/30] Logo-config-utilisateur-/etc/skel"
    MSG_USERCONF_TITLE="DistroClone - Configurations Utilisateur"
    MSG_USERCONF_HEADING="<b>Copier les configurations utilisateur dans /etc/skel ?</b>"
    MSG_USERCONF_TEXT="Cela permettra aux nouveaux utilisateurs créés après l'installation\nd'avoir les mêmes paramètres (thème, icônes, disposition du bureau).\n\n<b>Ce qui sera copié :</b>\n- Configurations du bureau (thème, icônes, fond d'écran)\n- Disposition du panneau et du dock\n- Préférences des applications\n\n<b>Ce qui ne sera PAS copié :</b>\n- Mots de passe et identifiants\n- Cache et fichiers temporaires\n- Configurations VirtualBox/Nextcloud etc.\n\n<i>Recommandé si vous souhaitez distribuer une ISO avec des configurations prédéfinies.</i>"
    MSG_TTY_COPY_CONFIG="Copier les configurations ?"
    MSG_USER_DETECTED="→ Utilisateur détecté"
    MSG_SKEL_COPIED="✓ Configurations copiées dans /etc/skel"
    MSG_SKEL_NEWUSERS="✓ Les nouveaux utilisateurs auront les mêmes paramètres"
    MSG_SKEL_NOTFOUND="✗ Impossible de trouver .config de l'utilisateur"
    MSG_SKEL_CLEANING="→ Nettoyage de /etc/skel des configurations hôte"
    MSG_SKEL_KEEPING="✓ Conservation du défaut"
    MSG_SKEL_DEFAULT="→ /etc/skel conservé avec les configurations par défaut uniquement"
    MSG_STEP15="[15/30] Branding dynamique Calamares"
    MSG_LOGO_COPIED="✓ Logo DistroClone copié"
    MSG_LOGO_NOTFOUND="→ Logo DistroClone non trouvé, génération du logo hexagonal intégré"
    MSG_LOGO_GENERATED="✓ Logo hexagonal DistroClone intégré généré"
    MSG_WELCOME_COPIED="✓ Écran d'accueil DistroClone copié"
    MSG_WELCOME_NOTFOUND="→ Écran d'accueil non trouvé, génération d'un placeholder"
    MSG_BRANDING_DESC="→ Création de branding.desc"
    MSG_BRANDING_QML="→ Création de show.qml"
    MSG_BRANDING_DONE="✓ Branding configuré dans"
    MSG_INSTALLER_COPIED="✓ Icône d'installation DistroClone copiée"
    MSG_INSTALLER_NOTFOUND="→ Icône d'installation non trouvée, logo hexagonal intégré"
    MSG_INSTALLER_GENERATED="✓ Icône hexagonale d'installation générée"
    MSG_STEP16="[16/30] Configuration Chroot"
    MSG_CHROOT_INSTALLING="→ Chroot : installation des paquets et configuration (cela peut prendre plusieurs minutes)..."
    MSG_CHROOT_DONE="✓ Configuration chroot terminée"
    MSG_STEP17="[17/30] Hook nettoyage post-installation"
    MSG_STEP18="[18/30] Démontage chroot"
    MSG_STEP19="[19/30] Vérification /boot"
    MSG_ERR_MISSING="ERREUR : Manquant"
    MSG_STEP20="[20/30] Copie kernel/initrd"
    MSG_ERR_KERNEL="ERREUR : Kernel ou initrd introuvable !"
    MSG_STEP21="[21/30] Modifications manuelles avancées"
    MSG_MANEDIT_TITLE="DistroClone - Configurations Avancées"
    MSG_MANEDIT_HEADING="<b>Voulez-vous apporter des modifications manuelles au système de fichiers avant de créer le squashfs ?</b>"
    MSG_MANEDIT_TEXT="Cette option est pour les utilisateurs avancés qui souhaitent :\n- Ajouter/supprimer des paquets dans le chroot\n- Modifier des fichiers de configuration\n- Personnaliser le système avant la compression"
    MSG_MANEDIT_PATH="Chemin chroot :"
    MSG_MANEDIT_SELECT="Sélectionnez <b>Non</b> pour continuer normalement."
    MSG_MANEDIT_ZENITY="Voulez-vous apporter des modifications manuelles au système de fichiers avant le squashfs ?"
    MSG_BTN_EDIT="Oui, je veux modifier"
    MSG_BTN_CONTINUE="Non, continuer"
    MSG_PAUSE_TITLE="PAUSE - MODIFICATIONS MANUELLES ACTIVÉES"
    MSG_PAUSE_AVAILABLE="Le système de fichiers est disponible dans :"
    MSG_PAUSE_CHROOT="Pour entrer dans le chroot :"
    MSG_PAUSE_DONE="Quand vous avez terminé, appuyez sur ENTRÉE pour continuer."
    MSG_PAUSE_ENTER="Appuyez sur ENTRÉE pour continuer la création du squashfs..."
    MSG_PAUSE_SHOOTING="Création en cours..."
    MSG_STEP22="[22/30] Sélection compression SquashFS"
    MSG_COMP_SELECT_TITLE="Compression SquashFS"
    MSG_COMP_SELECT_TEXT="Sélectionnez le type de compression :"
    MSG_COMP_USING="Utiliser"
    MSG_COMP_CODE="Code"
    MSG_COMP_DESCRIPTION="Description"
    MSG_COMP_FAST_DESC="Rapide (lz4, ISO plus grosse)"
    MSG_COMP_STD_DESC="Standard (xz équilibré)"
    MSG_COMP_MAX_DESC="Compression maximale (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="Sélectionnez la compression SquashFS :"
    MSG_TTY_COMP_FAST="Rapide (lz4, 5-10 min)"
    MSG_TTY_COMP_STD="Standard (xz, 15-20 min) [défaut]"
    MSG_TTY_COMP_MAX="Maximale (xz+bcj, 25-35 min)"
    MSG_TTY_CHOICE="Choix (F/S/M)"
    MSG_COMP_FAST_LOG="→ Compression rapide (lz4)"
    MSG_COMP_STD_LOG="→ Compression standard (xz)"
    MSG_COMP_MAX_LOG="→ Compression maximale (xz+bcj)"
    MSG_STEP23="[23/30] Création filesystem.squashfs (cela peut prendre plusieurs minutes)..."
    MSG_SQUASH_SIZE="✓ Taille Squashfs"
    MSG_STEP24="[24/30] Configuration GRUB"
    MSG_GRUB_CUSTOM="✓ Fond GRUB personnalisé copié (override)"
    MSG_GRUB_DEFAULT="✓ Fond GRUB par défaut généré (bleu foncé)"
    MSG_GRUB_NOCONVERT="⚠ convert non disponible - fond noir de secours"
    MSG_STEP25="[25/30] Binaires GRUB EFI"
    MSG_STEP26="[26/30] Création efiboot.img"
    MSG_STEP27="[27/30] Création isolinux BIOS"
    MSG_STEP28="[28/30] Création ISO amorçable (cela peut prendre plusieurs minutes)..."
    MSG_WARN_BIGISO="Attention : ISO volumineuse, problèmes possibles sur anciens BIOS"
    MSG_STEP29="[29/30] Vérification ISO et md5sum-sha256sum (cela peut prendre plusieurs minutes)..."
    MSG_ISO_SUCCESS="✓ ISO COMPLÉTÉE AVEC SUCCÈS !"
    MSG_FILE="Fichier"
    MSG_SIZE="Taille"
    MSG_MD5_GEN="Génération des checksums MD5 et sha256"
    MSG_CREATED="Créés"
    MSG_TEST_ISO="Pour tester l'ISO :"
    MSG_TEST_QEMU="QEMU : qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox : Créer une VM et monter"
    MSG_TEST_USB="USB : dd if="
    MSG_STEP30="[30/30] (Dernière étape) Nettoyage système hôte"
    MSG_REMOVING_CALAMARES="→ Suppression de Calamares du système hôte..."
    MSG_WARN_CALA_FAIL="Attention : Suppression de Calamares échouée"
    MSG_CALAMARES_REMOVED="✓ Calamares supprimé du système hôte"
    MSG_REMOVING_LIVEBOOT="→ Suppression de live-boot et autres du système hôte..."
    MSG_REMOVING_DIR="→ Suppression du répertoire..."
    MSG_COMPLETED_TITLE="DistroClone - Terminé"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ISO créée avec succès !</b></big>"
    MSG_TEST_TEXT="<b>Tester l'ISO :</b>\n• QEMU : qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox : Créer une VM et monter l'ISO\n• USB : dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ ERREUR : ISO non créée !"
    MSG_ERROR_TITLE="DistroClone - Erreur"
    MSG_ISO_FAIL_BIG="<big><b>✗ Création de l'ISO échouée !</b></big>\n\nVérifiez le terminal pour les détails."
    MSG_QML_INSTALLING="Installation du système en cours..."
    MSG_QML_WAIT="Veuillez patienter pendant la copie des fichiers"
    MSG_QML_CONFIGURING="Configuration du système..."
    MSG_QML_SERVICES="Configuration des utilisateurs et services système"
    MSG_QML_ALMOST="Presque terminé !"
    MSG_QML_COMPLETE="L'installation se terminera bientôt"
    MSG_GRUB_TRY="Essayer ou Installer"
    MSG_GRUB_SAFE="Live (Graphiques Sécurisés)"
    MSG_GRUB_INSTALL="Installer"
}

load_lang_es() {
    MSG_BANNER_TITLE="🐧 DistroClone - Creador de ISO Live"
    MSG_ERROR_OS_RELEASE="ERROR: ¡/etc/os-release no encontrado!"
    MSG_DETECTED_DISTRO="Distribución detectada:"
    MSG_NAME="Nombre"
    MSG_VERSION="Versión"
    MSG_DESKTOP="Escritorio"
    MSG_ARCHITECTURE="Arquitectura"
    MSG_KERNEL="Kernel"
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Creador de ISO Live</b></big>\n\n<i>Inicializando, por favor espere...\nInstalando paquetes necesarios...</i>\n"
    MSG_STEP0="[0/28] Detección automática de Distro"
    MSG_STEP1="[1/30] Selección de interfaz gráfica"
    MSG_GUI_SELECTED="✓ Interfaz gráfica seleccionada"
    MSG_STEP2="[2/30] Wrapper preguntas GUI"
    MSG_STEP3="[3/30] Pantalla de bienvenida"
    MSG_YAD_DETECTED="✓ YAD detectado - interfaz avanzada"
    MSG_ZENITY_DETECTED="✓ Zenity detectado - interfaz estándar"
    MSG_NO_GUI="Sin interfaz gráfica disponible - modo terminal"
    MSG_BTN_YES="Sí"
    MSG_BTN_NO="No"
    MSG_TTY_YN="s/N"
    MSG_TTY_PROCEED_YN="s/n"
    MSG_WELCOME_TITLE="DistroClone Creador Universal de ISO v1.4.7"
    MSG_WELCOME_HEADING="Bienvenido a DistroClone"
    MSG_WELCOME_SUBTITLE="Creador universal de ISO Live para distribuciones Debian"
    MSG_SYSTEM_DETECTED="Sistema Detectado"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="ISO Creada"
    MSG_ISO_GENERATED="ISO que se generará"
    MSG_BUILD_CONFIG="Configuración del proceso de build:"
    MSG_FIELD_COMPRESSION="<b>Tipo de compresión Squashfs</b>:"
    MSG_COMP_STANDARD="Estándar xz (15-20 min)"
    MSG_COMP_FAST="Rápida lz4 (5-10 min)"
    MSG_COMP_MAX="Máxima xz+bcj (25-35 min)"
    MSG_FIELD_PASSWORD="<b>Contraseña root sistema live</b> (usuario: admin):"
    MSG_FIELD_HOSTNAME="<b>Nombre de host sistema live</b>:"
    MSG_MIN_REQUIREMENTS="Requisitos Mínimos"
    MSG_MIN_REQ_TEXT="• Espacio en disco: 4-6 GB libres en /mnt\n• RAM: 2 GB mínimo\n• Tiempo estimado: 10-30 minutos (depende de la compresión)"
    MSG_BTN_CANCEL="Cancelar!gtk-cancel"
    MSG_BTN_NEXT="Siguiente - Iniciar Build!gtk-ok"
    MSG_BUILD_CANCELED="Build cancelado por el usuario"
    MSG_CHOSEN_CONFIG="✓ Configuración elegida:"
    MSG_COMPRESSION="Compresión"
    MSG_PASSWORD_ROOT="Contraseña root"
    MSG_DEFAULT_ROOT="predeterminada (root)"
    MSG_PERSONALIZED="personalizada"
    MSG_DEFAULT_CONFIG="✓ Configuraciones predeterminadas en uso"
    MSG_ZENITY_MODE="(modo Zenity)"
    MSG_PROCESS="Proceso"
    MSG_PROCESS_TEXT="[00-28] Clonación → Configuración → Squashfs → ISO"
    MSG_PRESS_OK="Presione OK para iniciar la creación de la ISO live..."
    MSG_PROCEED_BUILD="¿Proceder con el build?"
    MSG_BUILD_CANCELLED="Build cancelado"
    MSG_TTY_UNIVERSAL="Universal"
    MSG_TTY_LIVEISOBUILDER="Creador ISO Live para Debian-based"
    MSG_TTY_DATE="Fecha"
    MSG_TTY_SYSTEM_DETECTED="SISTEMA DETECTADO"
    MSG_TTY_ISO_GENERATED="ISO QUE SE GENERARÁ"
    MSG_TTY_REQUIREMENTS="REQUISITOS"
    MSG_TTY_DISKSPACE="Espacio en disco: 4-6 GB libres en /mnt"
    MSG_TTY_RAM="RAM: 2 GB mínimo"
    MSG_TTY_TIME="Tiempo estimado: 10-30 minutos"
    MSG_BUILDLOG_TITLE="DistroClone - Registro de Build"
    MSG_BTN_HIDE="Ocultar"
    MSG_STEP4="[4/30] Configuración"
    MSG_STEP5="[5/30] Limpieza de montajes"
    MSG_STEP6="[6/30] Directorio de montaje"
    MSG_STEP7="[7/30][PRE] Verificación de origen y montajes"
    MSG_ERR_SOURCE="ERROR: SOURCE debe ser / (encontrado: \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="ERROR: DEST ya está montado"
    MSG_ERR_LIVEDIR_MOUNTED="ERROR: LIVE_DIR está montado (riesgo de clonación recursiva)"
    MSG_WARN_MULTI_ROOT="ADVERTENCIA: múltiples sistemas de archivos root detectados"
    MSG_STEP8="[8/30] Clonación del sistema rsync (puede tardar varios minutos)..."
    MSG_FORCED_CLEAN_HOME="→ Limpieza forzada de /home en el sistema clonado"
    MSG_STEP9="[9/30] Limpieza de herramientas de build"
    MSG_ERR_DEST_NOTSET="ERROR: DEST no configurado o no es un directorio, limpieza omitida"
    MSG_STEP10="[10/30] Montaje bind chroot"
    MSG_STEP11="[11/30] Eliminación de usuarios del host"
    MSG_STEP12="[12/30] Preparación /boot para Calamares"
    MSG_STEP13="[13/30] Limpieza pre-build"
    MSG_STEP14="[14/30] Logo-config-usuario-/etc/skel"
    MSG_USERCONF_TITLE="DistroClone - Configuraciones de Usuario"
    MSG_USERCONF_HEADING="<b>¿Copiar configuraciones de usuario a /etc/skel?</b>"
    MSG_USERCONF_TEXT="Esto permitirá que los nuevos usuarios creados después de la instalación\ntengan las mismas configuraciones (tema, iconos, disposición del escritorio).\n\n<b>Lo que se copiará:</b>\n- Configuraciones del escritorio (tema, iconos, fondo)\n- Disposición del panel y dock\n- Preferencias de aplicaciones\n\n<b>Lo que NO se copiará:</b>\n- Contraseñas y credenciales\n- Caché y archivos temporales\n- Configuraciones de VirtualBox/Nextcloud etc.\n\n<i>Recomendado si desea distribuir una ISO con configuraciones preestablecidas.</i>"
    MSG_TTY_COPY_CONFIG="¿Copiar configuraciones?"
    MSG_USER_DETECTED="→ Usuario detectado"
    MSG_SKEL_COPIED="✓ Configuraciones copiadas a /etc/skel"
    MSG_SKEL_NEWUSERS="✓ Los nuevos usuarios tendrán las mismas configuraciones"
    MSG_SKEL_NOTFOUND="✗ No se pudo encontrar .config del usuario"
    MSG_SKEL_CLEANING="→ Limpieza de /etc/skel de configuraciones del host"
    MSG_SKEL_KEEPING="✓ Manteniendo predeterminado"
    MSG_SKEL_DEFAULT="→ /etc/skel mantenido solo con configuraciones predeterminadas"
    MSG_STEP15="[15/30] Branding dinámico Calamares"
    MSG_LOGO_COPIED="✓ Logo DistroClone copiado"
    MSG_LOGO_NOTFOUND="→ Logo DistroClone no encontrado, generando logo hexagonal integrado"
    MSG_LOGO_GENERATED="✓ Logo hexagonal DistroClone integrado generado"
    MSG_WELCOME_COPIED="✓ Pantalla de bienvenida DistroClone copiada"
    MSG_WELCOME_NOTFOUND="→ Pantalla de bienvenida no encontrada, generando placeholder"
    MSG_BRANDING_DESC="→ Creando branding.desc"
    MSG_BRANDING_QML="→ Creando show.qml"
    MSG_BRANDING_DONE="✓ Branding configurado en"
    MSG_INSTALLER_COPIED="✓ Icono del instalador DistroClone copiado"
    MSG_INSTALLER_NOTFOUND="→ Icono del instalador no encontrado, logo hexagonal integrado"
    MSG_INSTALLER_GENERATED="✓ Icono hexagonal del instalador generado"
    MSG_STEP16="[16/30] Configuración Chroot"
    MSG_CHROOT_INSTALLING="→ Chroot: instalando paquetes y configurando (puede tardar varios minutos)..."
    MSG_CHROOT_DONE="✓ Configuración chroot completada"
    MSG_STEP17="[17/30] Hook limpieza post-instalación"
    MSG_STEP18="[18/30] Desmontaje chroot"
    MSG_STEP19="[19/30] Verificación /boot"
    MSG_ERR_MISSING="ERROR: Faltante"
    MSG_STEP20="[20/30] Copiar kernel/initrd"
    MSG_ERR_KERNEL="ERROR: ¡Kernel o initrd no encontrados!"
    MSG_STEP21="[21/30] Modificaciones manuales avanzadas"
    MSG_MANEDIT_TITLE="DistroClone - Configuraciones Avanzadas"
    MSG_MANEDIT_HEADING="<b>¿Desea realizar cambios manuales en el sistema de archivos antes de crear el squashfs?</b>"
    MSG_MANEDIT_TEXT="Esta opción es para usuarios avanzados que desean:\n- Agregar/eliminar paquetes en el chroot\n- Editar archivos de configuración\n- Personalizar el sistema antes de la compresión"
    MSG_MANEDIT_PATH="Ruta chroot:"
    MSG_MANEDIT_SELECT="Seleccione <b>No</b> para continuar normalmente."
    MSG_MANEDIT_ZENITY="¿Desea realizar cambios manuales al sistema de archivos antes del squashfs?"
    MSG_BTN_EDIT="Sí, quiero editar"
    MSG_BTN_CONTINUE="No, continuar"
    MSG_PAUSE_TITLE="PAUSA - MODIFICACIONES MANUALES HABILITADAS"
    MSG_PAUSE_AVAILABLE="El sistema de archivos está disponible en:"
    MSG_PAUSE_CHROOT="Para entrar al chroot:"
    MSG_PAUSE_DONE="Cuando termine, presione ENTER para continuar."
    MSG_PAUSE_ENTER="Presione ENTER para continuar con la creación del squashfs..."
    MSG_PAUSE_SHOOTING="Creación en curso..."
    MSG_STEP22="[22/30] Selección de compresión SquashFS"
    MSG_COMP_SELECT_TITLE="Compresión SquashFS"
    MSG_COMP_SELECT_TEXT="Seleccione el tipo de compresión:"
    MSG_COMP_USING="Usar"
    MSG_COMP_CODE="Código"
    MSG_COMP_DESCRIPTION="Descripción"
    MSG_COMP_FAST_DESC="Rápida (lz4, ISO más grande)"
    MSG_COMP_STD_DESC="Estándar (xz equilibrado)"
    MSG_COMP_MAX_DESC="Compresión máxima (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="Seleccione compresión SquashFS:"
    MSG_TTY_COMP_FAST="Rápida (lz4, 5-10 min)"
    MSG_TTY_COMP_STD="Estándar (xz, 15-20 min) [predeterminado]"
    MSG_TTY_COMP_MAX="Máxima (xz+bcj, 25-35 min)"
    MSG_TTY_CHOICE="Elección (F/S/M)"
    MSG_COMP_FAST_LOG="→ Compresión rápida (lz4)"
    MSG_COMP_STD_LOG="→ Compresión estándar (xz)"
    MSG_COMP_MAX_LOG="→ Compresión máxima (xz+bcj)"
    MSG_STEP23="[23/30] Creando filesystem.squashfs (puede tardar varios minutos)..."
    MSG_SQUASH_SIZE="✓ Tamaño Squashfs"
    MSG_STEP24="[24/30] Configuración GRUB"
    MSG_GRUB_CUSTOM="✓ Fondo GRUB personalizado copiado (override)"
    MSG_GRUB_DEFAULT="✓ Fondo GRUB predeterminado generado (azul oscuro)"
    MSG_GRUB_NOCONVERT="⚠ convert no disponible - fondo negro de respaldo"
    MSG_STEP25="[25/30] Binarios GRUB EFI"
    MSG_STEP26="[26/30] Creando efiboot.img"
    MSG_STEP27="[27/30] Creando isolinux BIOS"
    MSG_STEP28="[28/30] Creando ISO arrancable (puede tardar varios minutos)..."
    MSG_WARN_BIGISO="Advertencia: ISO grande, posibles problemas en BIOS antiguos"
    MSG_STEP29="[29/30] Verificación ISO y md5sum-sha256sum (puede tardar varios minutos)..."
    MSG_ISO_SUCCESS="✓ ¡ISO COMPLETADA CON ÉXITO!"
    MSG_FILE="Archivo"
    MSG_SIZE="Tamaño"
    MSG_MD5_GEN="Generación de checksums MD5 y sha256"
    MSG_CREATED="Creados"
    MSG_TEST_ISO="Para probar la ISO:"
    MSG_TEST_QEMU="QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox: Crear VM y montar"
    MSG_TEST_USB="USB: dd if="
    MSG_STEP30="[30/30] (Último paso) Limpieza del sistema host"
    MSG_REMOVING_CALAMARES="→ Eliminando Calamares del sistema host..."
    MSG_WARN_CALA_FAIL="Advertencia: Eliminación de Calamares fallida"
    MSG_CALAMARES_REMOVED="✓ Calamares eliminado del sistema host"
    MSG_REMOVING_LIVEBOOT="→ Eliminando live-boot y otros del sistema host..."
    MSG_REMOVING_DIR="→ Eliminando directorio..."
    MSG_COMPLETED_TITLE="DistroClone - Completado"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ¡ISO creada con éxito!</b></big>"
    MSG_TEST_TEXT="<b>Probar la ISO:</b>\n• QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox: Crear una VM y montar la ISO\n• USB: dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ ERROR: ¡ISO no creada!"
    MSG_ERROR_TITLE="DistroClone - Error"
    MSG_ISO_FAIL_BIG="<big><b>✗ ¡Creación de ISO fallida!</b></big>\n\nRevise el terminal para más detalles."
    MSG_QML_INSTALLING="Instalando el sistema..."
    MSG_QML_WAIT="Por favor espere mientras se copian los archivos"
    MSG_QML_CONFIGURING="Configurando el sistema..."
    MSG_QML_SERVICES="Configurando usuarios y servicios del sistema"
    MSG_QML_ALMOST="¡Casi listo!"
    MSG_QML_COMPLETE="La instalación se completará en breve"
    MSG_GRUB_TRY="Probar o Instalar"
    MSG_GRUB_SAFE="Live (Gráficos Seguros)"
    MSG_GRUB_INSTALL="Instalar"
}

load_lang_de() {
    MSG_BANNER_TITLE="🐧 DistroClone - Live-ISO-Ersteller"
    MSG_ERROR_OS_RELEASE="FEHLER: /etc/os-release nicht gefunden!"
    MSG_DETECTED_DISTRO="Erkannte Distribution:"
    MSG_NAME="Name"
    MSG_VERSION="Version"
    MSG_DESKTOP="Desktop"
    MSG_ARCHITECTURE="Architektur"
    MSG_KERNEL="Kernel"
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Live-ISO-Ersteller</b></big>\n\n<i>Initialisierung läuft...\nErforderliche Pakete werden installiert...</i>\n"
    MSG_STEP0="[0/28] Automatische Distro-Erkennung"
    MSG_STEP1="[1/30] Auswahl der grafischen Oberfläche"
    MSG_GUI_SELECTED="✓ Grafische Oberfläche ausgewählt"
    MSG_STEP2="[2/30] GUI-Fragen-Wrapper"
    MSG_STEP3="[3/30] Willkommensbildschirm"
    MSG_YAD_DETECTED="✓ YAD erkannt - erweiterte Oberfläche"
    MSG_ZENITY_DETECTED="✓ Zenity erkannt - Standard-Oberfläche"
    MSG_NO_GUI="Keine grafische Oberfläche verfügbar - Terminalmodus"
    MSG_BTN_YES="Ja"
    MSG_BTN_NO="Nein"
    MSG_TTY_YN="j/N"
    MSG_TTY_PROCEED_YN="j/n"
    MSG_WELCOME_TITLE="DistroClone Universeller ISO-Ersteller v1.4.7"
    MSG_WELCOME_HEADING="Willkommen bei DistroClone"
    MSG_WELCOME_SUBTITLE="Universeller Live-ISO-Ersteller für Debian-basierte Distributionen"
    MSG_SYSTEM_DETECTED="Erkanntes System"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="Erstellte ISO"
    MSG_ISO_GENERATED="ISO die erstellt wird"
    MSG_BUILD_CONFIG="Build-Prozesskonfiguration:"
    MSG_FIELD_COMPRESSION="<b>Squashfs-Komprimierungstyp</b>:"
    MSG_COMP_STANDARD="Standard xz (15-20 Min.)"
    MSG_COMP_FAST="Schnell lz4 (5-10 Min.)"
    MSG_COMP_MAX="Maximal xz+bcj (25-35 Min.)"
    MSG_FIELD_PASSWORD="<b>Root-Passwort Live-System</b> (Benutzer: admin):"
    MSG_FIELD_HOSTNAME="<b>Hostname Live-System</b>:"
    MSG_MIN_REQUIREMENTS="Mindestanforderungen"
    MSG_MIN_REQ_TEXT="• Festplattenspeicher: 4-6 GB frei in /mnt\n• RAM: mindestens 2 GB\n• Geschätzte Zeit: 10-30 Minuten (abhängig von der Komprimierung)"
    MSG_BTN_CANCEL="Abbrechen!gtk-cancel"
    MSG_BTN_NEXT="Weiter - Build starten!gtk-ok"
    MSG_BUILD_CANCELED="Build vom Benutzer abgebrochen"
    MSG_CHOSEN_CONFIG="✓ Gewählte Konfiguration:"
    MSG_COMPRESSION="Komprimierung"
    MSG_PASSWORD_ROOT="Root-Passwort"
    MSG_DEFAULT_ROOT="Standard (root)"
    MSG_PERSONALIZED="benutzerdefiniert"
    MSG_DEFAULT_CONFIG="✓ Standardkonfigurationen werden verwendet"
    MSG_ZENITY_MODE="(Zenity-Modus)"
    MSG_PROCESS="Prozess"
    MSG_PROCESS_TEXT="[00-28] Klonen → Konfiguration → Squashfs → ISO"
    MSG_PRESS_OK="Drücken Sie OK um die Erstellung der Live-ISO zu starten..."
    MSG_PROCEED_BUILD="Mit dem Build fortfahren?"
    MSG_BUILD_CANCELLED="Build abgebrochen"
    MSG_TTY_UNIVERSAL="Universal"
    MSG_TTY_LIVEISOBUILDER="Live-ISO-Ersteller für Debian-basiert"
    MSG_TTY_DATE="Datum"
    MSG_TTY_SYSTEM_DETECTED="ERKANNTES SYSTEM"
    MSG_TTY_ISO_GENERATED="ISO DIE ERSTELLT WIRD"
    MSG_TTY_REQUIREMENTS="ANFORDERUNGEN"
    MSG_TTY_DISKSPACE="Festplattenspeicher: 4-6 GB frei in /mnt"
    MSG_TTY_RAM="RAM: mindestens 2 GB"
    MSG_TTY_TIME="Geschätzte Zeit: 10-30 Minuten"
    MSG_BUILDLOG_TITLE="DistroClone - Build-Protokoll"
    MSG_BTN_HIDE="Ausblenden"
    MSG_STEP4="[4/30] Konfiguration"
    MSG_STEP5="[5/30] Mount-Bereinigung"
    MSG_STEP6="[6/30] Mount-Verzeichnis"
    MSG_STEP7="[7/30][PRE] Quell- und Mount-Prüfung"
    MSG_ERR_SOURCE="FEHLER: SOURCE muss / sein (gefunden: \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="FEHLER: DEST ist bereits eingehängt"
    MSG_ERR_LIVEDIR_MOUNTED="FEHLER: LIVE_DIR ist eingehängt (Risiko eines rekursiven Klons)"
    MSG_WARN_MULTI_ROOT="WARNUNG: Mehrere Root-Dateisysteme erkannt"
    MSG_STEP8="[8/30] Systemklon rsync (kann mehrere Minuten dauern)..."
    MSG_FORCED_CLEAN_HOME="→ Erzwungene Bereinigung von /home im geklonten System"
    MSG_STEP9="[9/30] Bereinigung der Build-Tools"
    MSG_ERR_DEST_NOTSET="FEHLER: DEST nicht gesetzt oder kein Verzeichnis, Bereinigung übersprungen"
    MSG_STEP10="[10/30] Bind-Mount chroot"
    MSG_STEP11="[11/30] Host-Benutzer entfernen"
    MSG_STEP12="[12/30] Vorbereitung /boot für Calamares"
    MSG_STEP13="[13/30] Vor-Build-Bereinigung"
    MSG_STEP14="[14/30] Logo-Config-Benutzer-/etc/skel"
    MSG_USERCONF_TITLE="DistroClone - Benutzerkonfigurationen"
    MSG_USERCONF_HEADING="<b>Benutzerkonfigurationen nach /etc/skel kopieren?</b>"
    MSG_USERCONF_TEXT="Dies ermöglicht neuen Benutzern nach der Installation\ndie gleichen Einstellungen (Theme, Icons, Desktop-Layout).\n\n<b>Was kopiert wird:</b>\n- Desktop-Konfigurationen (Theme, Icons, Hintergrund)\n- Panel- und Dock-Layout\n- Anwendungseinstellungen\n\n<b>Was NICHT kopiert wird:</b>\n- Passwörter und Anmeldedaten\n- Cache und temporäre Dateien\n- VirtualBox/Nextcloud-Konfigurationen usw.\n\n<i>Empfohlen wenn Sie eine ISO mit voreingestellten Konfigurationen verteilen möchten.</i>"
    MSG_TTY_COPY_CONFIG="Konfigurationen kopieren?"
    MSG_USER_DETECTED="→ Benutzer erkannt"
    MSG_SKEL_COPIED="✓ Konfigurationen nach /etc/skel kopiert"
    MSG_SKEL_NEWUSERS="✓ Neue Benutzer haben die gleichen Einstellungen"
    MSG_SKEL_NOTFOUND="✗ Konnte .config des Benutzers nicht finden"
    MSG_SKEL_CLEANING="→ Bereinigung von /etc/skel von Host-Konfigurationen"
    MSG_SKEL_KEEPING="✓ Standard beibehalten"
    MSG_SKEL_DEFAULT="→ /etc/skel nur mit Standardkonfigurationen beibehalten"
    MSG_STEP15="[15/30] Dynamisches Calamares-Branding"
    MSG_LOGO_COPIED="✓ DistroClone-Logo kopiert"
    MSG_LOGO_NOTFOUND="→ DistroClone-Logo nicht gefunden, integriertes Hexagon-Logo wird generiert"
    MSG_LOGO_GENERATED="✓ Integriertes Hexagon-DistroClone-Logo generiert"
    MSG_WELCOME_COPIED="✓ DistroClone-Willkommensbildschirm kopiert"
    MSG_WELCOME_NOTFOUND="→ Willkommensbildschirm nicht gefunden, Platzhalter wird generiert"
    MSG_BRANDING_DESC="→ Erstelle branding.desc"
    MSG_BRANDING_QML="→ Erstelle show.qml"
    MSG_BRANDING_DONE="✓ Branding konfiguriert in"
    MSG_INSTALLER_COPIED="✓ DistroClone-Installationssymbol kopiert"
    MSG_INSTALLER_NOTFOUND="→ Installationssymbol nicht gefunden, integriertes Hexagon-Logo"
    MSG_INSTALLER_GENERATED="✓ Hexagonales Installationssymbol generiert"
    MSG_STEP16="[16/30] Chroot-Konfiguration"
    MSG_CHROOT_INSTALLING="→ Chroot: Pakete installieren und konfigurieren (kann mehrere Minuten dauern)..."
    MSG_CHROOT_DONE="✓ Chroot-Konfiguration abgeschlossen"
    MSG_STEP17="[17/30] Hook Nachinstallations-Bereinigung"
    MSG_STEP18="[18/30] Chroot aushängen"
    MSG_STEP19="[19/30] Überprüfung /boot"
    MSG_ERR_MISSING="FEHLER: Fehlt"
    MSG_STEP20="[20/30] Kernel/initrd kopieren"
    MSG_ERR_KERNEL="FEHLER: Kernel oder initrd nicht gefunden!"
    MSG_STEP21="[21/30] Erweiterte manuelle Änderungen"
    MSG_MANEDIT_TITLE="DistroClone - Erweiterte Konfigurationen"
    MSG_MANEDIT_HEADING="<b>Möchten Sie manuelle Änderungen am Dateisystem vornehmen bevor das Squashfs erstellt wird?</b>"
    MSG_MANEDIT_TEXT="Diese Option ist für fortgeschrittene Benutzer die:\n- Pakete im Chroot hinzufügen/entfernen möchten\n- Konfigurationsdateien bearbeiten möchten\n- Das System vor der Komprimierung anpassen möchten"
    MSG_MANEDIT_PATH="Chroot-Pfad:"
    MSG_MANEDIT_SELECT="Wählen Sie <b>Nein</b> um normal fortzufahren."
    MSG_MANEDIT_ZENITY="Möchten Sie manuelle Änderungen am Dateisystem vor dem Squashfs vornehmen?"
    MSG_BTN_EDIT="Ja, ich möchte bearbeiten"
    MSG_BTN_CONTINUE="Nein, weiter"
    MSG_PAUSE_TITLE="PAUSE - MANUELLE ÄNDERUNGEN AKTIVIERT"
    MSG_PAUSE_AVAILABLE="Das Dateisystem ist verfügbar in:"
    MSG_PAUSE_CHROOT="Um das Chroot zu betreten:"
    MSG_PAUSE_DONE="Wenn Sie fertig sind, drücken Sie ENTER um fortzufahren."
    MSG_PAUSE_ENTER="Drücken Sie ENTER um mit der Squashfs-Erstellung fortzufahren..."
    MSG_PAUSE_SHOOTING="Erstellung läuft..."
    MSG_STEP22="[22/30] SquashFS-Komprimierungsauswahl"
    MSG_COMP_SELECT_TITLE="SquashFS-Komprimierung"
    MSG_COMP_SELECT_TEXT="Wählen Sie den Komprimierungstyp:"
    MSG_COMP_USING="Verwenden"
    MSG_COMP_CODE="Code"
    MSG_COMP_DESCRIPTION="Beschreibung"
    MSG_COMP_FAST_DESC="Schnell (lz4, größere ISO)"
    MSG_COMP_STD_DESC="Standard (xz ausgewogen)"
    MSG_COMP_MAX_DESC="Maximale Komprimierung (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="SquashFS-Komprimierung wählen:"
    MSG_TTY_COMP_FAST="Schnell (lz4, 5-10 Min.)"
    MSG_TTY_COMP_STD="Standard (xz, 15-20 Min.) [Standard]"
    MSG_TTY_COMP_MAX="Maximal (xz+bcj, 25-35 Min.)"
    MSG_TTY_CHOICE="Auswahl (F/S/M)"
    MSG_COMP_FAST_LOG="→ Schnelle Komprimierung (lz4)"
    MSG_COMP_STD_LOG="→ Standard-Komprimierung (xz)"
    MSG_COMP_MAX_LOG="→ Maximale Komprimierung (xz+bcj)"
    MSG_STEP23="[23/30] Erstelle filesystem.squashfs (kann mehrere Minuten dauern)..."
    MSG_SQUASH_SIZE="✓ Squashfs-Größe"
    MSG_STEP24="[24/30] GRUB-Konfiguration"
    MSG_GRUB_CUSTOM="✓ Benutzerdefinierter GRUB-Hintergrund kopiert (Override)"
    MSG_GRUB_DEFAULT="✓ Standard-GRUB-Hintergrund generiert (Dunkelblau)"
    MSG_GRUB_NOCONVERT="⚠ convert nicht verfügbar - schwarzer Fallback-Hintergrund"
    MSG_STEP25="[25/30] GRUB-EFI-Binärdateien"
    MSG_STEP26="[26/30] Erstelle efiboot.img"
    MSG_STEP27="[27/30] Erstelle isolinux BIOS"
    MSG_STEP28="[28/30] Erstelle bootfähige ISO (kann mehrere Minuten dauern)..."
    MSG_WARN_BIGISO="Warnung: Große ISO, mögliche Probleme auf älteren BIOS"
    MSG_STEP29="[29/30] ISO-Überprüfung und md5sum-sha256sum (kann mehrere Minuten dauern)..."
    MSG_ISO_SUCCESS="✓ ISO ERFOLGREICH ERSTELLT!"
    MSG_FILE="Datei"
    MSG_SIZE="Größe"
    MSG_MD5_GEN="MD5- und SHA256-Prüfsummen werden generiert"
    MSG_CREATED="Erstellt"
    MSG_TEST_ISO="Zum Testen der ISO:"
    MSG_TEST_QEMU="QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox: VM erstellen und einbinden"
    MSG_TEST_USB="USB: dd if="
    MSG_STEP30="[30/30] (Letzter Schritt) Bereinigung des Host-Systems"
    MSG_REMOVING_CALAMARES="→ Entferne Calamares vom Host-System..."
    MSG_WARN_CALA_FAIL="Warnung: Entfernung von Calamares fehlgeschlagen"
    MSG_CALAMARES_REMOVED="✓ Calamares vom Host-System entfernt"
    MSG_REMOVING_LIVEBOOT="→ Entferne live-boot und andere vom Host-System..."
    MSG_REMOVING_DIR="→ Entferne Verzeichnis..."
    MSG_COMPLETED_TITLE="DistroClone - Abgeschlossen"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ISO erfolgreich erstellt!</b></big>"
    MSG_TEST_TEXT="<b>ISO testen:</b>\n• QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox: VM erstellen und ISO einbinden\n• USB: dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ FEHLER: ISO nicht erstellt!"
    MSG_ERROR_TITLE="DistroClone - Fehler"
    MSG_ISO_FAIL_BIG="<big><b>✗ ISO-Erstellung fehlgeschlagen!</b></big>\n\nÜberprüfen Sie das Terminal für Details."
    MSG_QML_INSTALLING="System wird installiert..."
    MSG_QML_WAIT="Bitte warten während die Dateien kopiert werden"
    MSG_QML_CONFIGURING="System wird konfiguriert..."
    MSG_QML_SERVICES="Benutzer und Systemdienste werden eingerichtet"
    MSG_QML_ALMOST="Fast fertig!"
    MSG_QML_COMPLETE="Die Installation wird in Kürze abgeschlossen"
    MSG_GRUB_TRY="Testen oder Installieren"
    MSG_GRUB_SAFE="Live (Sichere Grafik)"
    MSG_GRUB_INSTALL="Installieren"
}

load_lang_pt() {
    MSG_BANNER_TITLE="🐧 DistroClone - Criador de ISO Live"
    MSG_ERROR_OS_RELEASE="ERRO: /etc/os-release não encontrado!"
    MSG_DETECTED_DISTRO="Distribuição detectada:"
    MSG_NAME="Nome"
    MSG_VERSION="Versão"
    MSG_DESKTOP="Ambiente de trabalho"
    MSG_ARCHITECTURE="Arquitetura"
    MSG_KERNEL="Kernel"
    MSG_SPLASH_TITLE="DistroClone"
    MSG_SPLASH_TEXT="\n<big><b>DistroClone - Criador de ISO Live</b></big>\n\n<i>Inicializando, por favor aguarde...\nInstalando pacotes necessários...</i>\n"
    MSG_STEP0="[0/28] Detecção automática da Distro"
    MSG_STEP1="[1/30] Seleção da interface gráfica"
    MSG_GUI_SELECTED="✓ Interface gráfica selecionada"
    MSG_STEP2="[2/30] Wrapper de perguntas GUI"
    MSG_STEP3="[3/30] Tela de boas-vindas"
    MSG_YAD_DETECTED="✓ YAD detectado - interface avançada"
    MSG_ZENITY_DETECTED="✓ Zenity detectado - interface padrão"
    MSG_NO_GUI="Nenhuma interface gráfica disponível - modo terminal"
    MSG_BTN_YES="Sim"
    MSG_BTN_NO="Não"
    MSG_TTY_YN="s/N"
    MSG_TTY_PROCEED_YN="s/n"
    MSG_WELCOME_TITLE="DistroClone Criador Universal de ISO v1.4.7"
    MSG_WELCOME_HEADING="Bem-vindo ao DistroClone"
    MSG_WELCOME_SUBTITLE="Criador universal de ISO Live para distribuições Debian"
    MSG_SYSTEM_DETECTED="Sistema Detectado"
    MSG_DISTRO="Distro"
    MSG_ISO_CREATED="ISO Criada"
    MSG_ISO_GENERATED="ISO que será gerada"
    MSG_BUILD_CONFIG="Configuração do processo de build:"
    MSG_FIELD_COMPRESSION="<b>Tipo de compressão Squashfs</b>:"
    MSG_COMP_STANDARD="Padrão xz (15-20 min)"
    MSG_COMP_FAST="Rápida lz4 (5-10 min)"
    MSG_COMP_MAX="Máxima xz+bcj (25-35 min)"
    MSG_FIELD_PASSWORD="<b>Senha root sistema live</b> (utilizador: admin):"
    MSG_FIELD_HOSTNAME="<b>Hostname sistema live</b>:"
    MSG_MIN_REQUIREMENTS="Requisitos Mínimos"
    MSG_MIN_REQ_TEXT="• Espaço em disco: 4-6 GB livres em /mnt\n• RAM: 2 GB mínimo\n• Tempo estimado: 10-30 minutos (depende da compressão)"
    MSG_BTN_CANCEL="Cancelar!gtk-cancel"
    MSG_BTN_NEXT="Seguinte - Iniciar Build!gtk-ok"
    MSG_BUILD_CANCELED="Build cancelado pelo utilizador"
    MSG_CHOSEN_CONFIG="✓ Configuração escolhida:"
    MSG_COMPRESSION="Compressão"
    MSG_PASSWORD_ROOT="Senha root"
    MSG_DEFAULT_ROOT="padrão (root)"
    MSG_PERSONALIZED="personalizada"
    MSG_DEFAULT_CONFIG="✓ Configurações padrão em uso"
    MSG_ZENITY_MODE="(modo Zenity)"
    MSG_PROCESS="Processo"
    MSG_PROCESS_TEXT="[00-28] Clonagem → Configuração → Squashfs → ISO"
    MSG_PRESS_OK="Prima OK para iniciar a criação da ISO live..."
    MSG_PROCEED_BUILD="Prosseguir com o build?"
    MSG_BUILD_CANCELLED="Build cancelado"
    MSG_TTY_UNIVERSAL="Universal"
    MSG_TTY_LIVEISOBUILDER="Criador ISO Live para Debian-based"
    MSG_TTY_DATE="Data"
    MSG_TTY_SYSTEM_DETECTED="SISTEMA DETECTADO"
    MSG_TTY_ISO_GENERATED="ISO QUE SERÁ GERADA"
    MSG_TTY_REQUIREMENTS="REQUISITOS"
    MSG_TTY_DISKSPACE="Espaço em disco: 4-6 GB livres em /mnt"
    MSG_TTY_RAM="RAM: 2 GB mínimo"
    MSG_TTY_TIME="Tempo estimado: 10-30 minutos"
    MSG_BUILDLOG_TITLE="DistroClone - Registo de Build"
    MSG_BTN_HIDE="Ocultar"
    MSG_STEP4="[4/30] Configuração"
    MSG_STEP5="[5/30] Limpeza de montagens"
    MSG_STEP6="[6/30] Diretório de montagem"
    MSG_STEP7="[7/30][PRÉ] Verificação de origem e montagens"
    MSG_ERR_SOURCE="ERRO: SOURCE deve ser / (encontrado: \$SOURCE)"
    MSG_ERR_DEST_MOUNTED="ERRO: DEST já está montado"
    MSG_ERR_LIVEDIR_MOUNTED="ERRO: LIVE_DIR está montado (risco de clone recursivo)"
    MSG_WARN_MULTI_ROOT="AVISO: múltiplos sistemas de ficheiros root detectados"
    MSG_STEP8="[8/30] Clonagem do sistema rsync (pode demorar vários minutos)..."
    MSG_FORCED_CLEAN_HOME="→ Limpeza forçada de /home no sistema clonado"
    MSG_STEP9="[9/30] Limpeza de ferramentas de build"
    MSG_ERR_DEST_NOTSET="ERRO: DEST não definido ou não é um diretório, limpeza ignorada"
    MSG_STEP10="[10/30] Montagem bind chroot"
    MSG_STEP11="[11/30] Remoção de utilizadores do host"
    MSG_STEP12="[12/30] Preparação /boot para Calamares"
    MSG_STEP13="[13/30] Limpeza pré-build"
    MSG_STEP14="[14/30] Logo-config-utilizador-/etc/skel"
    MSG_USERCONF_TITLE="DistroClone - Configurações do Utilizador"
    MSG_USERCONF_HEADING="<b>Copiar configurações do utilizador para /etc/skel?</b>"
    MSG_USERCONF_TEXT="Isto permitirá que novos utilizadores criados após a instalação\ntenham as mesmas definições (tema, ícones, disposição do ambiente de trabalho).\n\n<b>O que será copiado:</b>\n- Configurações do ambiente de trabalho (tema, ícones, fundo)\n- Disposição do painel e dock\n- Preferências de aplicações\n\n<b>O que NÃO será copiado:</b>\n- Palavras-passe e credenciais\n- Cache e ficheiros temporários\n- Configurações VirtualBox/Nextcloud etc.\n\n<i>Recomendado se pretende distribuir uma ISO com configurações predefinidas.</i>"
    MSG_TTY_COPY_CONFIG="Copiar configurações?"
    MSG_USER_DETECTED="→ Utilizador detectado"
    MSG_SKEL_COPIED="✓ Configurações copiadas para /etc/skel"
    MSG_SKEL_NEWUSERS="✓ Novos utilizadores terão as mesmas definições"
    MSG_SKEL_NOTFOUND="✗ Não foi possível encontrar .config do utilizador"
    MSG_SKEL_CLEANING="→ Limpeza de /etc/skel das configurações do host"
    MSG_SKEL_KEEPING="✓ Mantendo padrão"
    MSG_SKEL_DEFAULT="→ /etc/skel mantido apenas com configurações padrão"
    MSG_STEP15="[15/30] Branding dinâmico Calamares"
    MSG_LOGO_COPIED="✓ Logo DistroClone copiado"
    MSG_LOGO_NOTFOUND="→ Logo DistroClone não encontrado, a gerar logo hexagonal integrado"
    MSG_LOGO_GENERATED="✓ Logo hexagonal DistroClone integrado gerado"
    MSG_WELCOME_COPIED="✓ Ecrã de boas-vindas DistroClone copiado"
    MSG_WELCOME_NOTFOUND="→ Ecrã de boas-vindas não encontrado, a gerar placeholder"
    MSG_BRANDING_DESC="→ A criar branding.desc"
    MSG_BRANDING_QML="→ A criar show.qml"
    MSG_BRANDING_DONE="✓ Branding configurado em"
    MSG_INSTALLER_COPIED="✓ Ícone do instalador DistroClone copiado"
    MSG_INSTALLER_NOTFOUND="→ Ícone do instalador não encontrado, logo hexagonal integrado"
    MSG_INSTALLER_GENERATED="✓ Ícone hexagonal do instalador gerado"
    MSG_STEP16="[16/30] Configuração Chroot"
    MSG_CHROOT_INSTALLING="→ Chroot: a instalar pacotes e configurar (pode demorar vários minutos)..."
    MSG_CHROOT_DONE="✓ Configuração chroot concluída"
    MSG_STEP17="[17/30] Hook limpeza pós-instalação"
    MSG_STEP18="[18/30] Desmontar chroot"
    MSG_STEP19="[19/30] Verificação /boot"
    MSG_ERR_MISSING="ERRO: Em falta"
    MSG_STEP20="[20/30] Copiar kernel/initrd"
    MSG_ERR_KERNEL="ERRO: Kernel ou initrd não encontrados!"
    MSG_STEP21="[21/30] Modificações manuais avançadas"
    MSG_MANEDIT_TITLE="DistroClone - Configurações Avançadas"
    MSG_MANEDIT_HEADING="<b>Deseja efetuar alterações manuais no sistema de ficheiros antes de criar o squashfs?</b>"
    MSG_MANEDIT_TEXT="Esta opção é para utilizadores avançados que pretendem:\n- Adicionar/remover pacotes no chroot\n- Editar ficheiros de configuração\n- Personalizar o sistema antes da compressão"
    MSG_MANEDIT_PATH="Caminho chroot:"
    MSG_MANEDIT_SELECT="Selecione <b>Não</b> para continuar normalmente."
    MSG_MANEDIT_ZENITY="Deseja efetuar alterações manuais ao sistema de ficheiros antes do squashfs?"
    MSG_BTN_EDIT="Sim, quero editar"
    MSG_BTN_CONTINUE="Não, continuar"
    MSG_PAUSE_TITLE="PAUSA - MODIFICAÇÕES MANUAIS ATIVADAS"
    MSG_PAUSE_AVAILABLE="O sistema de ficheiros está disponível em:"
    MSG_PAUSE_CHROOT="Para entrar no chroot:"
    MSG_PAUSE_DONE="Quando terminar, prima ENTER para continuar."
    MSG_PAUSE_ENTER="Prima ENTER para continuar com a criação do squashfs..."
    MSG_PAUSE_SHOOTING="Criação em curso..."
    MSG_STEP22="[22/30] Seleção de compressão SquashFS"
    MSG_COMP_SELECT_TITLE="Compressão SquashFS"
    MSG_COMP_SELECT_TEXT="Selecione o tipo de compressão:"
    MSG_COMP_USING="Usar"
    MSG_COMP_CODE="Código"
    MSG_COMP_DESCRIPTION="Descrição"
    MSG_COMP_FAST_DESC="Rápida (lz4, ISO maior)"
    MSG_COMP_STD_DESC="Padrão (xz equilibrado)"
    MSG_COMP_MAX_DESC="Compressão máxima (xz -Xbcj x86)"
    MSG_TTY_SELECT_COMP="Selecione compressão SquashFS:"
    MSG_TTY_COMP_FAST="Rápida (lz4, 5-10 min)"
    MSG_TTY_COMP_STD="Padrão (xz, 15-20 min) [padrão]"
    MSG_TTY_COMP_MAX="Máxima (xz+bcj, 25-35 min)"
    MSG_TTY_CHOICE="Escolha (F/S/M)"
    MSG_COMP_FAST_LOG="→ Compressão rápida (lz4)"
    MSG_COMP_STD_LOG="→ Compressão padrão (xz)"
    MSG_COMP_MAX_LOG="→ Compressão máxima (xz+bcj)"
    MSG_STEP23="[23/30] A criar filesystem.squashfs (pode demorar vários minutos)..."
    MSG_SQUASH_SIZE="✓ Tamanho Squashfs"
    MSG_STEP24="[24/30] Configuração GRUB"
    MSG_GRUB_CUSTOM="✓ Fundo GRUB personalizado copiado (override)"
    MSG_GRUB_DEFAULT="✓ Fundo GRUB padrão gerado (azul escuro)"
    MSG_GRUB_NOCONVERT="⚠ convert não disponível - fundo preto de reserva"
    MSG_STEP25="[25/30] Binários GRUB EFI"
    MSG_STEP26="[26/30] A criar efiboot.img"
    MSG_STEP27="[27/30] A criar isolinux BIOS"
    MSG_STEP28="[28/30] A criar ISO arrancável (pode demorar vários minutos)..."
    MSG_WARN_BIGISO="Aviso: ISO grande, possíveis problemas em BIOS antigos"
    MSG_STEP29="[29/30] Verificação ISO e md5sum-sha256sum (pode demorar vários minutos)..."
    MSG_ISO_SUCCESS="✓ ISO CONCLUÍDA COM SUCESSO!"
    MSG_FILE="Ficheiro"
    MSG_SIZE="Tamanho"
    MSG_MD5_GEN="Geração de checksums MD5 e sha256"
    MSG_CREATED="Criados"
    MSG_TEST_ISO="Para testar a ISO:"
    MSG_TEST_QEMU="QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom"
    MSG_TEST_VBOX="VirtualBox: Criar VM e montar"
    MSG_TEST_USB="USB: dd if="
    MSG_STEP30="[30/30] (Último passo) Limpeza do sistema host"
    MSG_REMOVING_CALAMARES="→ A remover Calamares do sistema host..."
    MSG_WARN_CALA_FAIL="Aviso: Remoção do Calamares falhou"
    MSG_CALAMARES_REMOVED="✓ Calamares removido do sistema host"
    MSG_REMOVING_LIVEBOOT="→ A remover live-boot e outros do sistema host..."
    MSG_REMOVING_DIR="→ A remover diretório..."
    MSG_COMPLETED_TITLE="DistroClone - Concluído"
    MSG_ISO_SUCCESS_BIG="<big><b>✓ ISO criada com sucesso!</b></big>"
    MSG_TEST_TEXT="<b>Testar a ISO:</b>\n• QEMU: qemu-system-x86_64 -enable-kvm -m 4G -bios /usr/share/ovmf/OVMF.fd -cdrom %ISO%\n• VirtualBox: Criar uma VM e montar a ISO\n• USB: dd if=%ISO% of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct &amp;&amp; sudo sync"
    MSG_ISO_ERROR="✗ ERRO: ISO não criada!"
    MSG_ERROR_TITLE="DistroClone - Erro"
    MSG_ISO_FAIL_BIG="<big><b>✗ Criação da ISO falhou!</b></big>\n\nVerifique o terminal para detalhes."
    MSG_QML_INSTALLING="A instalar o sistema..."
    MSG_QML_WAIT="Por favor aguarde enquanto os ficheiros são copiados"
    MSG_QML_CONFIGURING="A configurar o sistema..."
    MSG_QML_SERVICES="A configurar utilizadores e serviços do sistema"
    MSG_QML_ALMOST="Quase pronto!"
    MSG_QML_COMPLETE="A instalação será concluída em breve"
    MSG_GRUB_TRY="Experimentar ou Instalar"
    MSG_GRUB_SAFE="Live (Gráficos Seguros)"
    MSG_GRUB_INSTALL="Instalar"
}

# Load selected language
case "$DISTROCLONE_LANG" in
    it) load_lang_it ;;
    fr) load_lang_fr ;;
    es) load_lang_es ;;
    de) load_lang_de ;;
    pt) load_lang_pt ;;
    *)  load_lang_en ;;
esac

echo "  Language: $DISTROCLONE_LANG"


############################################
# [0/28] AUTO-DETECT DISTRO
############################################
echo "$MSG_STEP0"

if [ ! -f /etc/os-release ]; then
    echo "$MSG_ERROR_OS_RELEASE"
    exit 1
fi

source /etc/os-release

# Variabili dinamiche dalla distribuzione
DISTRO_NAME="${NAME}"
# Capitalizza prima lettera (ubuntu -> Ubuntu, debian -> Debian)
DISTRO_NAME="$(echo "$DISTRO_NAME" | sed 's/^./\U&/')"
DISTRO_ID="${ID}"
DISTRO_VERSION="${VERSION_ID:-unknown}"
DISTRO_PRETTY="${PRETTY_NAME}"

# Rilevamento desktop environment
# pkexec pulisce l'ambiente, recupera XDG_CURRENT_DESKTOP dalla sessione utente
if [ -z "$XDG_CURRENT_DESKTOP" ] && [ -n "$SUDO_USER" ]; then
    XDG_CURRENT_DESKTOP=$(su - "$SUDO_USER" -c 'echo $XDG_CURRENT_DESKTOP' 2>/dev/null) || true
fi
if [ -z "$XDG_CURRENT_DESKTOP" ] && [ -n "$PKEXEC_UID" ]; then
    PKEXEC_USER=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
    if [ -n "$PKEXEC_USER" ]; then
        XDG_CURRENT_DESKTOP=$(su - "$PKEXEC_USER" -c 'echo $XDG_CURRENT_DESKTOP' 2>/dev/null) || true
    fi
fi

if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    DESKTOP_ENV="$XDG_CURRENT_DESKTOP"
elif pgrep -x "io.elementary.wingpanel" >/dev/null 2>&1 || pgrep -x "gala" >/dev/null 2>&1; then
    DESKTOP_ENV="Pantheon"
elif pgrep -x "mate-panel" >/dev/null 2>&1; then
    DESKTOP_ENV="MATE"
elif pgrep -x "gnome-shell" >/dev/null 2>&1; then
    DESKTOP_ENV="GNOME"
elif pgrep -x "cinnamon" >/dev/null 2>&1; then
    DESKTOP_ENV="Cinnamon"
elif pgrep -x "plasmashell" >/dev/null 2>&1; then
    DESKTOP_ENV="KDE"
elif pgrep -x "xfce4-panel" >/dev/null 2>&1; then
    DESKTOP_ENV="XFCE"
else
    DESKTOP_ENV="Unknown"
fi

# Capitalizzazione corretta per nome ISO (es: ubuntu -> Ubuntu, linuxmint -> LinuxMint)
DISTRO_ID_CAPITALIZED=$(echo "${DISTRO_ID}" | sed -e 's/\b\(.\)/\u\1/g' -e 's/linux/Linux/g' -e 's/mint/Mint/g')
DESKTOP_CAPITALIZED=$(echo "$DESKTOP_ENV" | sed -e 's/\b\(.\)/\u\1/g')

ISO_NAME="${DISTRO_ID_CAPITALIZED}-${DISTRO_VERSION}-${DESKTOP_CAPITALIZED}.iso"
ISO_LABEL="${DISTRO_ID}-Live"

echo ""
echo "$MSG_DETECTED_DISTRO"
echo "  $MSG_NAME: $DISTRO_NAME"
echo "  ID: $DISTRO_ID (ISO: $DISTRO_ID_CAPITALIZED)"
echo "  $MSG_VERSION: $DISTRO_VERSION"
echo "  $MSG_DESKTOP: $DESKTOP_ENV (ISO: $DESKTOP_CAPITALIZED)"
echo ""

############################################
# SPLASH SCREEN
############################################
SPLASH_PID="${DISTROCLONE_SPLASH_PID:-}"

# Se non lanciato dal launcher .deb, crea splash se yad è già disponibile
if [ -z "$SPLASH_PID" ] && command -v yad >/dev/null 2>&1; then
    SPLASH_LOGO="$(get_dc_logo 256)"

    yad --info \
        --no-buttons \
        --timeout=300 \
        --title="$MSG_SPLASH_TITLE" \
        --text="$MSG_SPLASH_TEXT" \
        ${SPLASH_LOGO:+--window-icon="$SPLASH_LOGO"} \
        ${SPLASH_LOGO:+--image="$SPLASH_LOGO"} \
        --width=450 --height=280 \
        --center \
        --undecorated \
        --on-top \
        2>/dev/null &
    SPLASH_PID=$!
fi

# Ripara stato dpkg da build precedenti (clone da clone)
export NEEDRESTART_SUSPEND=1
DEBIAN_FRONTEND=noninteractive dpkg --configure -a 2>/dev/null || true
DEBIAN_FRONTEND=noninteractive apt-get install -f -y 2>/dev/null || true

# Pacchetti obbligatori
apt-get update || true; DEBIAN_FRONTEND=noninteractive apt install -y mtools syslinux-utils isolinux zenity syslinux-common \
  rsync xorriso live-boot live-config live-config-systemd imagemagick \
  calamares calamares-settings-debian grub-pc-bin yad fdisk \
  cryptsetup cryptsetup-initramfs cryptsetup-bin

# Forza reinstall yad (può fallire nel blocco precedente su clone da clone)
apt-get install --reinstall -y yad 2>/dev/null || apt-get install -y yad 2>/dev/null || true
unset NEEDRESTART_SUSPEND
  
# Aggiorna IM_CMD dopo installazione pacchetti
IM_CMD=""
command -v magick >/dev/null 2>&1 && IM_CMD="magick"
[ -z "$IM_CMD" ] && command -v convert >/dev/null 2>&1 && IM_CMD="convert" 

############################################
# [1/30] GUI TOOL SELECTION (YAD FIRST)
############################################
echo "$MSG_STEP1"

if command -v yad >/dev/null 2>&1; then
    GUI_TOOL="yad"
elif command -v zenity >/dev/null 2>&1; then
    GUI_TOOL="zenity"
else
    GUI_TOOL="tty"
fi
echo " $MSG_GUI_SELECTED: $GUI_TOOL"

############################################
# [2/30] GUI QUESTION WRAPPER (YAD FIRST)
############################################
echo "$MSG_STEP2"

gui_question() {
    local TITLE="$1"
    local TEXT="$2"
    local WIDTH="${3:-550}"
    local HEIGHT="${4:-300}"

    case "$GUI_TOOL" in
        yad)
            yad --question \
                --title="$TITLE" \
                --text="$TEXT" \
                --image="dialog-question" \
                --button="$MSG_BTN_YES:0" \
                --button="$MSG_BTN_NO:1" \
                --buttons-layout=spread \
                --center \
                --width="$WIDTH" \
                --height="$HEIGHT"
            return $?
            ;;
        zenity)
            zenity --question \
                --title="$TITLE" \
                --text="$TEXT" \
                --width="$WIDTH" \
                --height="$HEIGHT" 2>/dev/null
            return $?
            ;;
        *)
            read -rp "$TEXT [$MSG_TTY_YN]: " ans
            [[ "$ans" =~ ^[Yy]$ ]]
            return $?
            ;;
    esac
}

############################################
# [3/30] SCHERMATA DI BENVENUTO
############################################
echo "$MSG_STEP3"

# Rileva quale tool GUI usare
if command -v yad >/dev/null 2>&1; then
    GUI_TOOL="yad"
    echo "  $MSG_YAD_DETECTED"
elif command -v zenity >/dev/null 2>&1; then
    GUI_TOOL="zenity"
    echo "  $MSG_ZENITY_DETECTED"
else
    GUI_TOOL="none"
    echo "$MSG_NO_GUI"
fi

# Genera logo DistroClone temporaneo per YAD
TEMP_LOGO="$(get_dc_logo 256)"

# Chiudi splash prima del welcome dialog
if [ -n "$SPLASH_PID" ] && kill -0 "$SPLASH_PID" 2>/dev/null; then
    kill "$SPLASH_PID" 2>/dev/null
    wait "$SPLASH_PID" 2>/dev/null || true
    SPLASH_PID=""
fi
rm -f /tmp/distroClone-splash.png 2>/dev/null

# DCB cache detection
SOURCE_MODE="live"
CACHE_DIR="/mnt/SysLinuxOS_backup/.rootfs_cache"
DCB_CACHE_LABEL=""
if [ -d "$CACHE_DIR" ] && [ -f "/mnt/SysLinuxOS_backup/.backup_meta" ]; then
    _META_DATE=""; _META_DISTRO=""; _META_SIZE=""
    # shellcheck source=/dev/null
    source /mnt/SysLinuxOS_backup/.backup_meta 2>/dev/null || true
    _META_DATE="${META_DATE:-}"
    _META_DISTRO="${META_DISTRO:-}"
    _META_SIZE="${META_SIZE:-}"
    [ -n "$_META_DATE" ] && DCB_CACHE_LABEL="$_META_DATE | $_META_DISTRO | $_META_SIZE"
fi

# Mostra schermata di benvenuto
if [ "$GUI_TOOL" = "yad" ]; then
    # ===== INTERFACCIA YAD (AVANZATA) =====
    DCB_CACHE_FIELDS=()
    if [ -n "$DCB_CACHE_LABEL" ]; then
        DCB_CACHE_FIELDS=(
            --field="Build from DCB cache ($DCB_CACHE_LABEL)":CHK "FALSE"
        )
    fi
    RESULT=$(yad --form \
        --title="$MSG_WELCOME_TITLE" \
        ${TEMP_LOGO:+--window-icon="$TEMP_LOGO"} \
        ${TEMP_LOGO:+--image="$TEMP_LOGO"} \
        --image-on-top \
        --width=750 --height=550 \
        --text="<big><b>$MSG_WELCOME_HEADING</b></big>\n\
<i>$MSG_WELCOME_SUBTITLE</i>\n\n\
<b>$MSG_SYSTEM_DETECTED:</b>\n\
  • $MSG_DISTRO: <b>$DISTRO_PRETTY</b>\n\
  • $MSG_DESKTOP: <b>$DESKTOP_ENV</b>\n\
  • Kernel: $(uname -r)\n\
  • Architecture: $(uname -m)\n\n\
<b>$MSG_ISO_CREATED:</b>\n\
  • Name: <b>$ISO_NAME</b>\n\
  • Label: $ISO_LABEL\n\n\
<span color='#666666'><i>$MSG_BUILD_CONFIG</i></span>" \
        --separator="|" \
        --field="$MSG_FIELD_COMPRESSION":CB "$MSG_COMP_STANDARD!$MSG_COMP_FAST!$MSG_COMP_MAX" \
        --field="$MSG_FIELD_PASSWORD":H "root" \
        --field="$MSG_FIELD_HOSTNAME":TEXT "live-system" \
        "${DCB_CACHE_FIELDS[@]}" \
        --field=" ":LBL "" \
        --field="<span color='#0d47a1'><b>$MSG_MIN_REQUIREMENTS</b></span>:":LBL "" \
        --field="<span color='#666666'>$MSG_MIN_REQ_TEXT</span>:":LBL "" \
        --button="$MSG_BTN_CANCEL:1" \
        --button="$MSG_BTN_NEXT:0" \
        2>/dev/null)
    
    DIALOG_EXIT=$?
    
    # Cleanup logo temporaneo
    [[ "$TEMP_LOGO" == /tmp/* ]] && rm -f "$TEMP_LOGO"
    
    if [ $DIALOG_EXIT -ne 0 ]; then
        echo ""
        echo "$MSG_BUILD_CANCELED"
        exit 0
    fi
    
    # Parse risultati YAD
    COMPRESSION_CHOICE=$(echo "$RESULT" | cut -d'|' -f1)
    CUSTOM_ROOT_PASSWORD=$(echo "$RESULT" | cut -d'|' -f2)
    CUSTOM_HOSTNAME=$(echo "$RESULT" | cut -d'|' -f3)
    if [ -n "$DCB_CACHE_LABEL" ]; then
        _USE_DCB=$(echo "$RESULT" | cut -d'|' -f4)
        [ "$_USE_DCB" = "TRUE" ] && SOURCE_MODE="cache"
    fi
    
    # Determina tipo compressione
    case "$COMPRESSION_CHOICE" in
        *lz4*)
            SQUASHFS_COMP="lz4"
            ;;
        *xz+bcj*|*xz*bcj*)
            SQUASHFS_COMP="xz-bcj"
            ;;
        *)
            SQUASHFS_COMP="xz"
            ;;
    esac
    
   # Aggiorna password root se specificata
    [ -n "$CUSTOM_ROOT_PASSWORD" ] && ROOT_PASSWORD="$CUSTOM_ROOT_PASSWORD"
    [ -n "$CUSTOM_HOSTNAME" ] && LIVE_HOSTNAME="$CUSTOM_HOSTNAME"
    
    echo ""
    
    echo ""
    echo "$MSG_CHOSEN_CONFIG"
    echo "  • $MSG_COMPRESSION: $SQUASHFS_COMP"
    echo "  • Password root: $([ "$ROOT_PASSWORD" = "root" ] && echo "default (root)" || echo "personalized")"
    echo ""

elif [ "$GUI_TOOL" = "zenity" ]; then
    # ===== INTERFACCIA ZENITY (FALLBACK) =====
    zenity --info \
        --title="$MSG_WELCOME_TITLE" \
        --icon-name="drive-harddisk" \
        --width=650 --height=450 \
        --text="<big><b>$MSG_WELCOME_HEADING</b></big>\n\n\
<b>$MSG_WELCOME_SUBTITLE</b>\n\n\
<span color='#0d47a1'><b>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</b></span>\n\n\
<b>$MSG_SYSTEM_DETECTED:</b>\n\
  • $MSG_DISTRO: <b>$DISTRO_PRETTY</b>\n\
  • $MSG_DESKTOP: <b>$DESKTOP_ENV</b>\n\
  • Kernel: $(uname -r)\n\
  • Architecture: $(uname -m)\n\n\
<b>$MSG_ISO_GENERATED:</b>\n\
  • <b>$ISO_NAME</b>\n\n\
<span color='#0d47a1'><b>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</b></span>\n\n\
<b>$MSG_MIN_REQUIREMENTS:</b>\n\
  $MSG_MIN_REQ_TEXT\n\n\
<b>$MSG_PROCESS:</b> $MSG_PROCESS_TEXT\n\n\
<i>$MSG_PRESS_OK</i>" \
        2>/dev/null || {
            echo "$MSG_BUILD_CANCELED"
            exit 0
        }
    
    # Con Zenity, usa configurazioni di default
    SQUASHFS_COMP="xz"
    echo ""
    echo "$MSG_DEFAULT_CONFIG $MSG_ZENITY_MODE:"
    echo "  • $MSG_COMPRESSION: xz (standard)"
    echo "  • $MSG_PASSWORD_ROOT: root ($MSG_DEFAULT_ROOT)"
    echo ""

else

    # ===== MODALITÀ TERMINALE (NESSUNA GUI) =====
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                 DISTROCLONE $MSG_TTY_UNIVERSAL                    ║"
    echo "║          $MSG_TTY_LIVEISOBUILDER                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  $MSG_VERSION: 1.3.7"
    echo "  $MSG_TTY_DATE: $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "$MSG_TTY_SYSTEM_DETECTED:"
    echo "  ├─ $MSG_DISTRO: $DISTRO_PRETTY"
    echo "  ├─ $MSG_DESKTOP: $DESKTOP_ENV"
    echo "  ├─ $MSG_KERNEL: $(uname -r)"
    echo "  └─ $MSG_ARCHITECTURE: $(uname -m)"
    echo ""
    echo "$MSG_TTY_ISO_GENERATED:"
    echo "  └─ $MSG_NAME: $ISO_NAME"
    echo ""
    echo "$MSG_TTY_REQUIREMENTS:"
    echo "  • $MSG_TTY_DISKSPACE"
    echo "  • $MSG_TTY_RAM"
    echo "  • $MSG_TTY_TIME"
    echo ""
    read -p "$MSG_PROCEED_BUILD ($MSG_TTY_PROCEED_YN): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "$MSG_BUILD_CANCELLED"
        exit 0
    fi
    
    # Usa configurazioni di default
    SQUASHFS_COMP="xz"
    echo ""
    echo "$MSG_DEFAULT_CONFIG:"
    echo "  • $MSG_COMPRESSION: xz (standard)"
    echo "  • $MSG_PASSWORD_ROOT: root ($MSG_DEFAULT_ROOT)"
    echo ""
fi

   # Avvia finestra log in tempo reale
LOG_PID=""

TEMP_LOGO="$(get_dc_logo 128)"
if [ "$GUI_TOOL" = "yad" ]; then
    # Scrivi direttamente nello stdin di YAD tramite fd 3
    exec 3> >(yad --text-info \
        --title="$MSG_BUILDLOG_TITLE" \
        ${TEMP_LOGO:+--window-icon="$TEMP_LOGO"} \
        ${TEMP_LOGO:+--image="$TEMP_LOGO"} \
        --image-on-top \
        --back="#1a1a2e" \
        --fore="#2196f3" \
        --fontname="Monospace 11" \
        --width=500 --height=400 \
        --tail \
        --no-edit \
        --button="$MSG_BTN_HIDE:1" \
        --center \
        2>/dev/null)
    LOG_PID=$!
fi

   # Funzione per scrivere sia su terminale che sulla finestra log
log_msg() {
    echo "$@"
    { echo "$@" >&3; } 2>/dev/null || true
}


############################################
# [3x1/30] Cleanup pre build
############################################
log_msg "$MSG_STEP3x1"

# Pulizia residui da build precedenti
rm -rf /etc/calamares 2>/dev/null || true
rm -rf /usr/share/calamares/branding 2>/dev/null || true
DEBIAN_FRONTEND=noninteractive dpkg --configure -a 2>/dev/null || true
DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -f -y 2>/dev/null || true

############################################
# [4/30] CONFIG
############################################
log_msg "$MSG_STEP4"

SOURCE="/"
LIVE_DIR="/mnt/${DISTRO_ID}_live"
DEST="$LIVE_DIR/rootfs"
ISO_DIR="$LIVE_DIR/iso"

LIVE_USER="admin"
LIVE_PASSWORD="root"
LIVE_FULLNAME="${DISTRO_NAME} Live User"
LIVE_HOSTNAME="${DISTRO_ID}"
ROOT_PASSWORD="${ROOT_PASSWORD:-root}"

############################################
# [5/30] Cleanup mount precedenti (se script interrotto)
############################################
log_msg "$MSG_STEP5"

umount -l "$LIVE_DIR/rootfs/proc" "$LIVE_DIR/rootfs/sys" \
       "$LIVE_DIR/rootfs/dev/pts" "$LIVE_DIR/rootfs/dev" \
       "$LIVE_DIR/rootfs/run" "$LIVE_DIR/rootfs/tmp" 2>/dev/null || true

rm -rf "/mnt/${DISTRO_ID}_live"
mkdir -p "/mnt/${DISTRO_ID}_live"

############################################
# [6/30] PREP DIRECTORY
############################################
log_msg "$MSG_STEP6"

rm -rf "$LIVE_DIR"
mkdir -p "$DEST" "$ISO_DIR"/{live,isolinux,boot/grub,EFI/BOOT}

############################################
# [7/30] [PRE] SOURCE & MOUNT SANITY CHECK
############################################

log_msg "$MSG_STEP7"

# SOURCE must be / (skip check in cache mode)
if [ "$SOURCE_MODE" != "cache" ] && [ "$SOURCE" != "/" ]; then
    log_msg "$(eval echo "$MSG_ERR_SOURCE")"
    exit 1
fi

# DEST must not be mounted
if mount | grep -q " $DEST "; then
    log_msg "$MSG_ERR_DEST_MOUNTED"
    exit 1
fi

# LIVE_DIR must not be mounted
if mount | grep -q " $LIVE_DIR "; then
    log_msg "$MSG_ERR_LIVEDIR_MOUNTED"
    exit 1
fi

# Warn if multiple root filesystems exist
ROOT_FS_COUNT=$(df -hT | awk '$7=="/" {c++} END {print c+0}')
if [ "$ROOT_FS_COUNT" -ne 1 ]; then
    log_msg "$MSG_WARN_MULTI_ROOT"
fi

############################################
# [8/30] CLONAZIONE SISTEMA
############################################
log_msg "$MSG_STEP8"

if [ "$SOURCE_MODE" = "cache" ]; then
    log_msg "  [DCB] Source: $CACHE_DIR"
    rsync -aAXH --numeric-ids --info=progress2 \
      --exclude=/dev/* \
      --exclude=/proc/* \
      --exclude=/sys/* \
      --exclude=/run/* \
      --exclude=/tmp/* \
      --exclude=/mnt/* \
      --exclude=/media/* \
      --exclude=/lost+found \
      --exclude=/swapfile \
      --exclude=/home/* \
      --exclude=/root/* \
      --exclude=/var/cache/apt/archives/* \
      --exclude=/var/lib/apt/lists/* \
      --exclude=/var/log/* \
      --exclude=/var/tmp/* \
      --exclude=/etc/NetworkManager/system-connections/* \
      --exclude=/snap \
      --exclude=/snap/* \
      --exclude=/var/snap \
      --exclude=/var/lib/snapd \
      --exclude=/.snapshots \
      --exclude=/.snapshots/* \
      --exclude=/@.rollback-bak-* \
      "$CACHE_DIR/" "$DEST" || { RC=$?; [ $RC -eq 24 ] && true || exit $RC; }
else
    rsync -aAXH --numeric-ids --info=progress2 --one-file-system \
      --exclude=/dev/* \
      --exclude=/proc/* \
      --exclude=/sys/* \
      --exclude=/run/* \
      --exclude=/tmp/* \
      --exclude=/mnt/* \
      --exclude=/media/* \
      --exclude=/lost+found \
      --exclude=/swapfile \
      --exclude="$LIVE_DIR" \
      --exclude=/home/* \
      --exclude=/root/* \
      --exclude=/var/cache/apt/archives/* \
      --exclude=/var/lib/apt/lists/* \
      --exclude=/var/log/* \
      --exclude=/var/tmp/* \
      --exclude=/etc/NetworkManager/system-connections/* \
      --exclude=/snap \
      --exclude=/snap/* \
      --exclude=/var/snap \
      --exclude=/var/lib/snapd \
      --exclude=/.snapshots \
      --exclude=/.snapshots/* \
      --exclude=/@.rollback-bak-* \
      "$SOURCE" "$DEST" || { RC=$?; [ $RC -eq 24 ] && true || exit $RC; }
fi

mkdir -p "$DEST"/{var/log,var/tmp}
chmod 1777 "$DEST/var/tmp"

# FORCE: Rimuovi completamente /home/* per sicurezza
echo "  $MSG_FORCED_CLEAN_HOME"
rm -rf "$DEST"/home/*
rm -rf "$DEST"/root/*

mkdir -p "$DEST"/{var/log,var/tmp}

# Ubuntu/Debian filesystem sanitation (definitiva)
umount -lf "$DEST/run" "$DEST/proc" "$DEST/sys" 2>/dev/null || true
rm -rf "$DEST/run" "$DEST/proc" "$DEST/sys"
rm -rf "$DEST/snap" "$DEST/var/snap" "$DEST/var/lib/snapd"
mkdir -p "$DEST"/{run,proc,sys}

# Btrfs snapshot sanitation: even with --one-file-system + --exclude rsync may
# leave stub dirs (or partial copies if subvol boundaries shift between rsync
# pass and squashfs). Snapper metadata (config/state) and rollback subvols
# would otherwise leak the source machine's snapshot identity into the live
# system and onto every install. Wipe them so the target's first-boot setup
# starts from a clean state and creates its own baseline.
rm -rf "$DEST/.snapshots" \
       "$DEST"/@.rollback-bak-* \
       "$DEST/var/lib/snapper/snapshots" \
       "$DEST/etc/snapper/configs"/root.pre-spike-bak \
       2>/dev/null || true

log_msg "$MSG_STEP9"

if [ -z "$DEST" ] || [ ! -d "$DEST" ]; then
    log_msg "$MSG_ERR_DEST_NOTSET"
else
    # Remove DistroClone package (not needed in live)
    #chroot "$DEST" dpkg --purge distroclone 2>/dev/null || true

    # Clean apt cache
    chroot "$DEST" apt-get -y clean

    # Remove YAD leftover files
    rm -f "$DEST/usr/bin/yad" 2>/dev/null || true
fi

############################################
# [10/30] MOUNT CHROOT
############################################
log_msg "$MSG_STEP10"

for d in proc sys dev dev/pts run tmp; do
  mkdir -p "$DEST/$d"
  mount --bind "/$d" "$DEST/$d"
done
chmod 1777 "$DEST/tmp"

############################################
# [11/30] RIMOZIONE UTENTI HOST
############################################
log_msg "$MSG_STEP11"

for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' "$DEST/etc/passwd"); do
  [ "$u" != "$LIVE_USER" ] && sed -i "/^$u:/d" "$DEST/etc/"{passwd,shadow,group,gshadow} || true
  rm -rf "$DEST/home/$u"
done

############################################
# [12/30] FIX BOOT DIRECTORY
############################################
log_msg "$MSG_STEP12"

mkdir -p "$DEST/boot/grub" "$DEST/boot/efi"
chmod 755 "$DEST/boot" "$DEST/boot/grub" "$DEST/boot/efi"

############################################
# [13/30] PRE-CLEANUP
############################################
log_msg "$MSG_STEP13"

rm -rf "$DEST"/var/cache/apt/archives/*.deb
rm -rf "$DEST"/var/lib/apt/lists/*
rm -rf "$DEST"/var/log/*.log
rm -rf "$DEST"/tmp/*
rm -rf "$DEST"/root/.bash_history
rm -rf "$DEST"/home/*/.bash_history

# Pulizia MINIMA e MIRATA - Mantiene tema/icone/Plank/configurazioni
# Bluetooth - dispositivi associati
rm -rf "$DEST"/var/lib/bluetooth/* 2>/dev/null || true

for homedir in "$DEST"/home/* "$DEST"/root; do
  [ -d "$homedir" ] || continue
  
  # File recenti GTK (dialoghi apertura file)
  rm -f "$homedir"/.local/share/recently-used.xbel* 2>/dev/null || true
  
  # Cache thumbnails
  rm -rf "$homedir"/.cache/thumbnails 2>/dev/null || true
  rm -rf "$homedir"/.thumbnails 2>/dev/null || true
  
  # Browser cache (opzionale)
  rm -rf "$homedir"/.mozilla 2>/dev/null || true
  rm -rf "$homedir"/.config/chromium 2>/dev/null || true
  rm -rf "$homedir"/.config/google-chrome 2>/dev/null || true
  
  # Configurazioni Nextcloud (cartelle e client)
  rm -rf "$homedir"/.config/Nextcloud 2>/dev/null || true
  rm -rf "$homedir"/.config/nextcloud 2>/dev/null || true
  rm -rf "$homedir"/Nextcloud 2>/dev/null || true
  rm -rf "$homedir"/nextcloud 2>/dev/null || true

done

############################################
# [14/30] COPIA CONFIGURAZIONI UTENTE IN /etc/skel
############################################
log_msg "$MSG_STEP14"

# Genera logo DistroClone temporaneo per YAD
TEMP_LOGO="$(get_dc_logo 128)"
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    export DISPLAY=:0
fi

if [ "$GUI_TOOL" = "yad" ]; then
    if yad --question \
        --title="$MSG_USERCONF_TITLE" \
        ${TEMP_LOGO:+--window-icon="$TEMP_LOGO"} \
        ${TEMP_LOGO:+--image="$TEMP_LOGO"} \
        --button="$MSG_BTN_NO:1" \
        --button="$MSG_BTN_YES:0" \
        --buttons-layout=spread \
        --center \
        --width=550 --height=400 \
        --fixed \
        --text="$MSG_USERCONF_HEADING\n\n$MSG_USERCONF_TEXT"; then
        COPY_USER_CONFIG=true
    else
        COPY_USER_CONFIG=false
    fi
elif [ "$GUI_TOOL" = "zenity" ]; then
    if zenity --question \
        --title="$MSG_USERCONF_TITLE" \
        --text="$MSG_USERCONF_HEADING\n\n$MSG_USERCONF_TEXT" \
        --width=550 --height=300 --timeout=60 2>/dev/null; then
        COPY_USER_CONFIG=true
    else
        COPY_USER_CONFIG=false
    fi
else
    read -p "$MSG_TTY_COPY_CONFIG ($MSG_TTY_PROCEED_YN): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        COPY_USER_CONFIG=true
    else
        COPY_USER_CONFIG=false
    fi
fi
  
if [ "$COPY_USER_CONFIG" = true ]; then
    # Identifica l'utente corrente (non root)
    CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
        CURRENT_USER=$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)
    fi

    if [ -n "$CURRENT_USER" ] && [ -d "/home/$CURRENT_USER/.config" ]; then
        echo "  $MSG_USER_DETECTED: $CURRENT_USER"

        # Pulisci skel clonato dall'host prima di copiare
        rm -rf "$DEST/etc/skel/.config" "$DEST/etc/skel/.local"
        mkdir -p "$DEST/etc/skel/.config"

        # Copia .config escludendo dati sensibili
        rsync -a --exclude='*.log' \
                 --exclude='*cache*' \
                 --exclude='*Cache*' \
                 --exclude='chromium' \
                 --exclude='google-chrome' \
                 --exclude='mozilla' \
                 --exclude='Code/User/globalStorage' \
                 --exclude='Code/User/workspaceStorage' \
                 --exclude='VirtualBox' \
                 --exclude='nextcloud' \
                 --exclude='Nextcloud' \
                 --exclude='pulse' \
                 --exclude='*.sock' \
                 --exclude='*.pid' \
                 "/home/$CURRENT_USER/.config/" "$DEST/etc/skel/.config/"

        rm -f "$DEST/etc/skel/.config/user-dirs.dirs" 2>/dev/null || true

        # Copia .local/share (icone, temi custom)
        if [ -d "/home/$CURRENT_USER/.local/share" ]; then
            mkdir -p "$DEST/etc/skel/.local/share"
            rsync -a --exclude='Trash' \
                     --exclude='recently-used.xbel*' \
                     "/home/$CURRENT_USER/.local/share/icons" \
                     "/home/$CURRENT_USER/.local/share/themes" \
                     "/home/$CURRENT_USER/.local/share/applications" \
                     "$DEST/etc/skel/.local/share/" 2>/dev/null || true
        fi

        # Copia dotfile shell
        for f in .profile .bashrc .bash_logout; do
            if [ -f "/home/$CURRENT_USER/$f" ]; then
                cp "/home/$CURRENT_USER/$f" "$DEST/etc/skel/$f"
            fi
        done

        # Fix permessi
        chown -R root:root "$DEST/etc/skel/.config"
        [ -d "$DEST/etc/skel/.local" ] && chown -R root:root "$DEST/etc/skel/.local"

        echo "  $MSG_SKEL_COPIED"
        echo "  $MSG_SKEL_NEWUSERS"
    else
        echo "  $MSG_SKEL_NOTFOUND $CURRENT_USER"
    fi
else
    # Utente ha scelto NO: pulisci /etc/skel da configurazioni host
    echo "  $MSG_SKEL_CLEANING"
    rm -rf "$DEST/etc/skel/.config"
    rm -rf "$DEST/etc/skel/.local"
    # Mantieni solo i dotfile shell di default Debian
    for f in .profile .bashrc .bash_logout; do
        if [ -f "$DEST/etc/skel/$f" ]; then
            echo "  $MSG_SKEL_KEEPING $f"
        fi
    done
    echo "  $MSG_SKEL_DEFAULT"
fi
    
############################################
# [15/30] BRANDING AUTOMATICO
############################################
log_msg "$MSG_STEP15"

BRANDING_DIR="$DEST/usr/share/calamares/branding/${DISTRO_ID}"
mkdir -p "$BRANDING_DIR"

# Nome distribuzione formattato per UI (max 20 caratteri per evitare troncamento)
DISTRO_NAME_SHORT=$(echo "${DISTRO_ID}" | tr '[:lower:]' '[:upper:]')

# Controlla se esistono file branding personalizzati
CUSTOM_BRANDING=false

# Logo - Usa DistroClone logo universale o genera hexagon integrato
if [ -f "/usr/share/distroClone/distroClone-logo.png" ]; then
    cp "/usr/share/distroClone/distroClone-logo.png" "$BRANDING_DIR/${DISTRO_ID}-logo.png"
    echo "  $MSG_LOGO_COPIED"
    CUSTOM_BRANDING=true
elif [ -f "distroClone-logo.png" ]; then
    cp "distroClone-logo.png" "$BRANDING_DIR/${DISTRO_ID}-logo.png"
    echo "  $MSG_LOGO_COPIED"
    CUSTOM_BRANDING=true
else
    echo "  $MSG_LOGO_NOTFOUND"
    if command -v $IM_CMD >/dev/null 2>&1; then
        $IM_CMD -size 256x256 xc:transparent \
                -fill '#0d47a1' \
                -draw 'polygon 128,6 228,58 228,198 128,250 28,198 28,58' \
                -fill 'none' -strokewidth 5 -stroke '#1976d2' \
                -draw 'polygon 128,28 208,72 208,184 128,228 48,184 48,72' \
                -fill '#2196f3' \
                -draw 'polygon 128,58 184,88 184,168 128,198 72,168 72,88' \
                -fill 'white' -font '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' -pointsize 56 -gravity center \
                -annotate +0+0 'DC' \
                "$BRANDING_DIR/${DISTRO_ID}-logo.png" 2>/dev/null && \
        echo "  $MSG_LOGO_GENERATED"
    fi
fi

# Welcome screen - Usa DistroClone welcome universale
if [ -f "/usr/share/distroClone/distroClone-welcome.png" ]; then
    cp "/usr/share/distroClone/distroClone-welcome.png" "$BRANDING_DIR/welcome.png"
    echo "  $MSG_WELCOME_COPIED"
    CUSTOM_BRANDING=true
elif [ -f "distroClone-welcome.png" ]; then
    cp "distroClone-welcome.png" "$BRANDING_DIR/welcome.png"
    echo "  $MSG_WELCOME_COPIED"
    CUSTOM_BRANDING=true
else
    echo "  $MSG_WELCOME_NOTFOUND"
    if command -v $IM_CMD >/dev/null 2>&1; then
        $IM_CMD -size 800x400 xc:'#0c0d45' \
                -fill '#ecf0f1' \
                -pointsize 64 \
                -gravity center \
                -annotate +0-50 'DistroClone' \
                -pointsize 28 \
                -fill '#95a5a6' \
                -annotate +0+30 'Universal Live ISO Builder' \
                "$BRANDING_DIR/welcome.png" 2>/dev/null
    fi
fi

# Slide opzionali
cp -v slide*.png "$BRANDING_DIR/" 2>/dev/null || true

# Genera branding.desc
echo "  $MSG_BRANDING_DESC"
cat > "$BRANDING_DIR/branding.desc" << EOBRAND
---
componentName: ${DISTRO_ID}

images:
    productLogo: "${DISTRO_ID}-logo.png"
    productIcon: "${DISTRO_ID}-logo.png"
    productWelcome: "welcome.png"

slideshow: "show.qml"
slideshowAPI: 2

strings:
    productName: "${DISTRO_NAME_SHORT} ${DISTRO_VERSION}"
    shortProductName: "${DISTRO_ID}"
    version: "${DISTRO_VERSION}"
    shortVersion: "${DISTRO_VERSION}"
    versionedName: "${DISTRO_NAME_SHORT} ${DISTRO_VERSION}"
    shortVersionedName: "${DISTRO_ID} ${DISTRO_VERSION}"
    bootloaderEntryName: "${DISTRO_ID}"
    productUrl: "https://www.debian.org/"
    supportUrl: "https://www.debian.org/support"
    knownIssuesUrl: "https://www.debian.org/"
    releaseNotesUrl: "https://www.debian.org/"

style:
    SidebarBackground: "#0a0a36"
    SidebarBackgroundCurrent: "#2196f3"
    SidebarText: "#FFFFFF"
    SidebarTextCurrent: "#0a0a36"
    sidebarBackground: "#0a0a36"
    sidebarBackgroundCurrent: "#2196f3"
    sidebarText: "#FFFFFF"
    sidebarTextCurrent: "#0a0a36"

welcomeStyleCalamares: true
EOBRAND

# Genera show.qml
echo "  $MSG_BRANDING_QML"
cat > "$BRANDING_DIR/show.qml" << EOQML
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a36"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_INSTALLING"
                    font.pointSize: 28
                    font.bold: true
                    color: "white"
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_WAIT"
                    font.pointSize: 16
                    color: "#ecf0f1"
                }
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a36"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_CONFIGURING"
                    font.pointSize: 28
                    font.bold: true
                    color: "white"
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_SERVICES"
                    font.pointSize: 16
                    color: "#ecf0f1"
                }
            }
        }
    }
    
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a36"
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_ALMOST"
                    font.pointSize: 28
                    font.bold: true
                    color: "white"
                }
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "$MSG_QML_COMPLETE"
                    font.pointSize: 16
                    color: "#ecf0f1"
                }
            }
        }
    }
}
EOQML

echo "$MSG_BRANDING_DONE: $BRANDING_DIR"
ls -lh "$BRANDING_DIR/" | sed 's/^/  /'

# Copia icona installer DistroClone nel live system
if [ -f "/usr/share/distroClone/distroClone-installer.png" ]; then
    cp "/usr/share/distroClone/distroClone-installer.png" "$DEST/usr/share/icons/install-system.png"
    echo "  $MSG_INSTALLER_COPIED"
elif [ -f "distroClone-installer.png" ]; then
    cp "distroClone-installer.png" "$DEST/usr/share/icons/install-system.png"
    echo "  $MSG_INSTALLER_COPIED"
else
    echo "  $MSG_INSTALLER_NOTFOUND"
    if command -v $IM_CMD >/dev/null 2>&1; then
        $IM_CMD -size 256x256 xc:transparent \
                -fill '#0d47a1' \
                -draw 'polygon 128,6 228,58 228,198 128,250 28,198 28,58' \
                -fill 'none' -strokewidth 5 -stroke '#1976d2' \
                -draw 'polygon 128,28 208,72 208,184 128,228 48,184 48,72' \
                -fill '#2196f3' \
                -draw 'polygon 128,58 184,88 184,168 128,198 72,168 72,88' \
                -fill 'white' -font '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' -pointsize 56 -gravity center \
                -annotate +0+0 'DC' \
                "$DEST/usr/share/icons/install-system.png" 2>/dev/null && \
        echo "  $MSG_INSTALLER_GENERATED"
    fi
fi

############################################
# [16/30] CHROOT CONFIG
############################################
log_msg "$MSG_STEP16"
log_msg "  $MSG_CHROOT_INSTALLING"

# Detect host root filesystem so Calamares defaults match (btrfs host -> btrfs default).
HOST_ROOT_FS="$(findmnt -n -o FSTYPE / 2>/dev/null || echo ext4)"
case "$HOST_ROOT_FS" in
    ext4|btrfs|xfs) : ;;
    *) HOST_ROOT_FS="ext4" ;;
esac
mkdir -p "$DEST/tmp"
printf '%s\n' "$HOST_ROOT_FS" > "$DEST/tmp/.host_root_fs"

chroot "$DEST" /bin/bash << 'CHROOT_EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1
mkdir -p /etc/needrestart/conf.d
printf '$nrconf{restart} = "a";\n$nrconf{verbosity} = 0;\n' > /etc/needrestart/conf.d/99-silent.conf

# Pre-configure debconf to avoid interactive grub-efi dialog
echo "grub-efi-amd64 grub2/update_nvram boolean false" | debconf-set-selections
echo "grub-efi-amd64 grub-efi/install_devices string" | debconf-set-selections
echo "grub-pc grub-pc/install_devices string" | debconf-set-selections

apt-get update || true
apt install -y --no-install-recommends \
  live-boot live-config live-config-systemd \
  initramfs-tools rsync squashfs-tools \
  grub-efi-amd64 mtools grub-pc-bin os-prober efibootmgr \
  syslinux-common syslinux-utils imagemagick isolinux fdisk

# Crypto SENZA --no-install-recommends: i recommended sono necessari
# per copiare /lib/cryptsetup/functions nell'initramfs
apt install -y cryptsetup cryptsetup-initramfs

# Calamares senza --no-install-recommends (richiede QML + rsync)
apt install -y calamares calamares-settings-debian

rm -f /etc/NetworkManager/system-connections/* 2>/dev/null || true
rm -rf /var/lib/NetworkManager/* 2>/dev/null || true
rm -f /etc/systemd/network/* 2>/dev/null || true
rm -rf /var/lib/systemd/network/* 2>/dev/null || true
rm -f /etc/netplan/* 2>/dev/null || true
rm -f /etc/wpa_supplicant/* 2>/dev/null || true
rm -f /etc/resolv.conf 2>/dev/null || true

# Ripristina DNS per operazioni apt nel chroot
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Pulizia DHCP leases (risolve problema connessioni WiFi replicate)
echo "  → Cleaning DHCP leases"
rm -f /var/lib/dhcp/dhclient*.leases 2>/dev/null || true
rm -f /var/lib/dhcp/dhclient*.lease 2>/dev/null || true
rm -rf /var/lib/dhcpcd/* 2>/dev/null || true

# Pulizia MINIMA file personali (mantiene tema/icone/Plank)
echo "  → Personal data cleaning (maintains aesthetic configuration)"
rm -rf /var/lib/bluetooth/* 2>/dev/null || true

for homedir in /home/* /root; do
  [ -d "$homedir" ] || continue
  
  # File recenti GTK
  rm -f "$homedir"/.local/share/recently-used.xbel* 2>/dev/null || true
  
  # Cache thumbnails
  rm -rf "$homedir"/.cache/thumbnails 2>/dev/null || true
  rm -rf "$homedir"/.thumbnails 2>/dev/null || true
  
  # Browser cache
  rm -rf "$homedir"/.mozilla 2>/dev/null || true
  rm -rf "$homedir"/.config/chromium 2>/dev/null || true
  rm -rf "$homedir"/.config/google-chrome 2>/dev/null || true
  
    # Configurazioni Nextcloud (cartelle e client)
  rm -rf "$homedir"/.config/Nextcloud 2>/dev/null || true
  rm -rf "$homedir"/.config/nextcloud 2>/dev/null || true
  rm -rf "$homedir"/Nextcloud 2>/dev/null || true
  rm -rf "$homedir"/nextcloud 2>/dev/null || true

done

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# fstab

cat > /etc/fstab <<'EOF'
proc  /proc  proc   defaults  0 0
sysfs /sys   sysfs  defaults  0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
tmpfs /run   tmpfs  defaults  0 0
tmpfs /tmp   tmpfs  defaults,nosuid,nodev,mode=1777 0 0
EOF


# Utente live
id admin &>/dev/null || useradd -m -s /bin/bash -u 1000 admin
usermod -aG sudo,audio,video,dialout,cdrom,plugdev,netdev admin

# Pulizia Nextcloud dalla home admin appena creata
rm -rf /home/admin/.config/Nextcloud 2>/dev/null || true
rm -rf /home/admin/.config/nextcloud 2>/dev/null || true
rm -rf /home/admin/.config/autostart 2>/dev/null || true
rm -rf /home/admin/.local/share/Nextcloud 2>/dev/null || true
rm -rf /home/admin/Nextcloud 2>/dev/null || true
rm -rf /home/admin/nextcloud 2>/dev/null || true

# Pulizia keyrings
rm -rf /home/admin/.local/share/keyrings 2>/dev/null || true

# 1) Rimuovi la voce Debian nel live
rm -f /usr/share/applications/calamares-install-debian.desktop 2>/dev/null || true
rm -f /home/admin/Desktop/calamares-install-debian.desktop 2>/dev/null || true
rm -f /etc/skel/Desktop/calamares-install-debian.desktop 2>/dev/null || true
rm -f /etc/xdg/autostart/calamares-desktop-icon.desktop 2>/dev/null || true
rm -f /usr/bin/add-calamares-desktop-icon 2>/dev/null || true

# 2a) Wrapper che lancia Calamares con logging persistente.
# Calamares in pkexec normalmente non scrive log in posti facili da trovare
# (env stripped, /var/log non scritto). Wrapper salva stdout+stderr in
# /var/log/calamares-install-<timestamp>.log e copia anche /tmp/Calamares*.log
# eventualmente prodotti dal core. Necessario per diagnosticare failure di
# install che lascia target non bootabile senza traccia.
cat > /usr/local/bin/launch-calamares.sh << 'LAUNCHCAL'
#!/bin/bash
TS="$(date +%Y%m%d-%H%M%S)"
LOG="/var/log/calamares-install-${TS}.log"
mkdir -p /var/log
echo "=== distroClone calamares wrapper $(date -Iseconds) ===" > "$LOG"
echo "argv: $*" >> "$LOG"
echo "user: $(id)" >> "$LOG"
echo "===" >> "$LOG"
calamares -d "$@" >> "$LOG" 2>&1
rc=$?
echo "=== exit code: $rc ===" >> "$LOG"
# Copia eventuali log di sessione che Calamares scrive in /tmp o ~/.cache
for src in /tmp/Calamares*.log /root/.cache/Calamares/session.log /root/.cache/calamares/session.log; do
  [ -f "$src" ] || continue
  cp -a "$src" "/var/log/calamares-session-${TS}-$(basename "$src")" 2>/dev/null || true
done
exit $rc
LAUNCHCAL
chmod 755 /usr/local/bin/launch-calamares.sh

# 2b) Polkit action per il wrapper (pkexec senza prompt-noauth interattivo
# usa stesso schema di pkexec calamares: auth_admin_keep). Senza questa
# action pkexec chiede password admin via dialog, comportamento accettato.
cat > /usr/share/polkit-1/actions/org.distroclone.launch-calamares.policy << 'POLKIT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="org.distroclone.launch-calamares">
    <description>Run Calamares installer with logging</description>
    <message>Authentication is required to run the system installer</message>
    <defaults>
      <allow_any>auth_admin_keep</allow_any>
      <allow_inactive>auth_admin_keep</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/launch-calamares.sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
  </action>
</policyconfig>
POLKIT

# 2c) Crea la voce Install System (menu)
cat > /usr/share/applications/install-system.desktop << EOF
[Desktop Entry]
Type=Application
Name=Install System
Comment=Install $DISTRO_NAME on disk
Exec=pkexec /usr/local/bin/launch-calamares.sh
Icon=/usr/share/icons/install-system.png
Terminal=false
Categories=System;Installer;
StartupNotify=true
EOF
chmod 644 /usr/share/applications/install-system.desktop

# 3) Metti l’icona sul Desktop (live)
install -Dm644 /usr/share/applications/install-system.desktop /home/admin/Desktop/install-system.desktop
chmod 755 /home/admin/Desktop/install-system.desktop
chown admin:admin /home/admin/Desktop/install-system.desktop
chown -R admin:admin /home/admin/Desktop
chmod 755 /home/admin/Desktop

IS_GNOME=0
dpkg-query -W -f='${Status}\n' gnome-shell 2>/dev/null | grep -q "installed" && IS_GNOME=1

if [ "$IS_GNOME" -eq 1 ]; then
  apt-get update || true

cat > /usr/local/bin/syslinuxos-trust-desktop-launchers.sh <<'EOF'
#!/bin/bash
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
f="$DESKTOP_DIR/install-system.desktop"
[ -f "$f" ] || exit 0

# Attendi che Nautilus/GNOME desktop sia pronto
for i in $(seq 1 30); do
    if pgrep -x nautilus >/dev/null 2>&1 || pgrep -x gnome-shell >/dev/null 2>&1; then
        break
    fi
    sleep 1
done
sleep 2

chmod +x "$f"
gio set "$f" metadata::trusted true 2>/dev/null || true
EOF

  chmod +x /usr/local/bin/syslinuxos-trust-desktop-launchers.sh

  mkdir -p /etc/xdg/autostart
  cat > /etc/xdg/autostart/syslinuxos-trust-desktop-launchers.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Trust Desktop Launchers
Exec=/usr/local/bin/syslinuxos-trust-desktop-launchers.sh
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
fi

# 4. Remove problematic systemd services with syntax errors
echo "  Removing problematic systemd services..."
PROBLEMATIC_SERVICES=(
    "telinit-emerd.service"
    "calamares-anydesk.service"
)

for service in "${PROBLEMATIC_SERVICES[@]}"; do
    if [ -f "/etc/systemd/system/$service" ]; then
        echo "    Removing $service (syntax errors/deprecated paths)"
        systemctl disable "$service" 2>/dev/null || true
        systemctl mask "$service" 2>/dev/null || true
        rm -f "/etc/systemd/system/$service"
    fi
done

# 4b. Prevent Samba (nmbd) from blocking boot
# nmbd.service binds to a network interface; on the Live/clone no NIC has an IP
# at that point, so the start job stalls ~1m41s (TimeoutStartSec) before failing
# ("A start job is running for Samba NMB daemon..."). Disable Samba *server*
# autostart so boot is not held up. The SMB client (gvfs/smbclient) is
# unaffected; users who serve shares can re-enable with `systemctl enable nmbd`.
echo "    Disabling Samba server autostart (nmbd/smbd boot hang)..."
for service in nmbd.service smbd.service; do
    systemctl disable "$service" 2>/dev/null || true
done

# 5. Ensure /var/run → /run symlink (fix deprecated path warnings)
if [ ! -L /var/run ]; then
    echo "    Creating /var/run → /run symlink"
    rm -rf /var/run 2>/dev/null || true
    ln -s /run /var/run
fi

# 6. Reload systemd to apply changes
systemctl daemon-reload

echo "Legacy init cleanup completed - system ready for installation"

# Live-config parameters
mkdir -p /etc/live
cat > /etc/live/config.conf << 'LIVECONFIG'
LIVE_HOSTNAME="${BOOTLOADER_ID}"
LIVE_USERNAME="admin"
LIVE_USER_DEFAULT_GROUPS="audio,cdrom,dip,dialout,floppy,video,plugdev,netdev,powerdev,scanner,bluetooth,sudo"
LIVE_USER_FULLNAME="${BOOTLOADER_ID} Live User"
LIVE_LOCALES="en_US.UTF-8"
LIVE_TIMEZONE="Europe/Rome"
LIVE_KEYBOARD_LAYOUTS="us"
LIVECONFIG

# Generate locale to prevent boot warnings
echo "Generating system locales..."
locale-gen en_US.UTF-8 2>/dev/null || true
update-locale LANG=en_US.UTF-8 2>/dev/null || true

# ============================================
# CALAMARES CONFIGURATION
# ============================================

# Backup configurazione originale
mkdir -p /etc/calamares/modules
mkdir -p /etc/calamares/modules-backup
cp -r /etc/calamares/modules/*.conf /etc/calamares/modules-backup/ 2>/dev/null || true

# 1. UNPACKFS
cat > /etc/calamares/modules/unpackfs.conf << 'UNPACK'
---
unpack:
    -   source: "/run/live/medium/live/filesystem.squashfs"
        sourcefs: "squashfs"
        destination: ""
        exclude:
            - /dev/*
            - /proc/*
            - /sys/*
            - /run/*
            - /tmp/*
            - /mnt/*
            - /media/*
            - /lost+found
            - /var/cache/apt/archives/*
            - /var/lib/apt/lists/*
            - /var/log/*
            - /var/tmp/*
            - /swapfile
            - /home/admin
UNPACK

# 2. MOUNT
cat > /etc/calamares/modules/mount.conf << 'MOUNT'
---
extraMounts:
  - device: proc
    fs: proc
    mountPoint: /proc
  - device: sys
    fs: sysfs
    mountPoint: /sys
  - device: /dev
    mountPoint: /dev
    options: [ "bind" ]
  - device: /dev/pts
    mountPoint: /dev/pts
    options: [ "bind" ]
  - device: tmpfs
    fs: tmpfs
    mountPoint: /run
  - device: /run/udev
    mountPoint: /run/udev
    options: [ "bind" ]

extraMountsEfi:
  - device: efivarfs
    fs: efivarfs
    mountPoint: /sys/firmware/efi/efivars

MOUNT


# 3. FSTAB
# IMPORTANT: btrfs option must NOT include compress=zstd. Calamares' mount
# module reuses mountOptions when mounting the target during install, so any
# compression here is applied at install time. Files written by unpackfs
# (rsync from squashfs, including /boot/vmlinuz-*) then land as compressed
# extents on disk, and GRUB 2.12's btrfs driver fails reading them with
# "premature end of file" on first boot. Leaving btrfs with the same plain
# "defaults,noatime" as ext4/xfs ensures kernel files stay readable.
# Users who want btrfs compression can enable it post-install (e.g. via
# btrfs property set or mount option change), but not on /boot.
cat > /etc/calamares/modules/fstab.conf << 'FSTAB_CONF'
---
mountOptions:
    default: defaults,noatime
    btrfs: defaults,noatime
    ext4: defaults,noatime
    xfs: defaults,noatime

ssdExtraMountOptions:
    ext4: discard
    jfs: discard
    xfs: discard

# Abilita scrittura crypttab per partizioni LUKS
crypttab: true
crypttabOptions: luks,discard
FSTAB_CONF

# 4. USERS
cat > /etc/calamares/modules/users.conf << 'USERS'
---
defaultGroups:
  - name: users
    mustexist: true
  - audio
  - cdrom
  - dialout
  - floppy
  - video
  - plugdev
  - netdev
  - scanner
  - bluetooth
  - sudo

autologinGroup: autologin
doAutologin: false
sudoersGroup: sudo
setRootPassword: true
doReusePassword: false

passwordRequirements:
  nonempty: true
  minLength: 4
  maxLength: -1

allowWeakPasswords: true
allowWeakPasswordsDefault: true
userShell: /bin/bash
USERS

# 5. Partition.conf (obbligatorio su Ubuntu-based evita errore rsync 11)
# Evita che installer Calamares in modalità auto non vede la partizione /
# Default FS = host root FS so "Erase disk" dropdown matches host (btrfs host -> btrfs default).
# partitionLayout filesystem MUST be set to a real FS — Calamares treats an
# empty/missing filesystem value as "Unformatted" (not "use UI dropdown"),
# which leaves the partition raw and rsync (unpackfs) fails with exit 11.
# We bind both defaultFileSystemType and partitionLayout.filesystem to the
# host root FS so Erase-mode installs always format with a valid FS that
# matches the host. Users needing a different FS use "Manual partitioning".
HOST_FS_TYPE="$(cat /tmp/.host_root_fs 2>/dev/null || echo ext4)"
case "$HOST_FS_TYPE" in
    ext4|btrfs|xfs) : ;;
    *) HOST_FS_TYPE="ext4" ;;
esac
cat > /etc/calamares/modules/partition.conf << PARTCONF
---
efiSystemPartition: "/boot/efi"
efiSystemPartitionSize: 512M
efiSystemPartitionName: EFI

drawNestedPartitions: true
alwaysShowPartitionLabels: true

enabledPartitionChoices:
    - erase
    - replace
    - manual

enabledEncryptionTypes:
  - luks

userSwapChoices:
    - none
    - small
    - file

initialPartitioningChoice: erase
initialSwapChoice: none

defaultFileSystemType: "${HOST_FS_TYPE}"
availableFileSystemTypes: ["ext4","btrfs","xfs"]

partitionLayout:
    - name: "rootfs"
      filesystem: "${HOST_FS_TYPE}"
      mountPoint: "/"
      size: 100%
      minSize: 8G

# Btrfs subvolume layout (Calamares 3.3+ partition module).
# Auto-applicato SOLO quando il target FS è btrfs; ignorato per ext4/xfs → zero regressioni.
# SysLinuxOS layout Debian-style: @ come rootfs, @home come /home (subvol top-level).
# .snapshots viene creato come subvol nidificato dentro @ dal postinst di
# syslinuxos-snapshots al primo boot del target (snapper -c root create-config /).
btrfsSubvolumes:
  - mountPoint: /
    subvolume: /@
  - mountPoint: /home
    subvolume: /@home
PARTCONF
rm -f /tmp/.host_root_fs

# 6. PACKAGES (NON rimuovere durante install)
cat > /etc/calamares/modules/packages.conf << 'PACKAGES'
---
backend: apt
operations: []
skip_if_no_internet: false
update_db: false
update_system: false
PACKAGES

# DISPLAYMANAGER
cat > /etc/calamares/modules/displaymanager.conf << 'DMCONF'
---
displaymanagers:
    - lightdm
    - gdm
    - sddm
    - slim
basicSetup: false
DMCONF

# FINISHED
cat > /etc/calamares/modules/finished.conf << 'FINCONF'
---
restartNowEnabled: true
restartNowChecked: true
restartNowCommand: "systemctl reboot"
notifyOnFinished: true
FINCONF

# 7. SCRIPT STANDALONE PER GRUB
cat > /usr/local/bin/calamares-grub-install.sh << 'GRUBSCRIPT'
#!/bin/bash
set -e
set -x

# Mirror all output (stdout + stderr) into a persistent log on the target so
# we can diagnose post-reboot regressions even if Calamares' live /var/log
# was lost. Find it later at /var/log/distroclone-grub-install.log on the
# installed system, or mount the target and look in /@/var/log/.
# Ensure /var/log exists first: Calamares' target chroot is sometimes minimal
# at this stage and tee silently dropped output when the dir was missing.
mkdir -p /var/log
exec > >(tee -a /var/log/distroclone-grub-install.log) 2>&1

echo "======================================"
echo "  GRUB Installation Script"
echo "======================================"
echo "[INFO] $(date -Iseconds) - script start"
echo "[INFO] root FS: $(findmnt -n -o FSTYPE / 2>/dev/null || echo unknown)"
echo "[INFO] root device: $(findmnt -n -o SOURCE / 2>/dev/null || echo unknown)"
echo "[INFO] /boot listing:"
ls -laFh /boot/ 2>&1 || true
echo "[INFO] /lib/modules listing:"
ls -laFh /lib/modules/ 2>&1 || true

# Detect distribution
if [ -f /etc/os-release ]; then
  source /etc/os-release
  DISTRO_ID="${ID}"
  BOOTLOADER_ID="$(echo ${DISTRO_ID} | sed 's/^./\U&/')"  # Capitalize first letter
else
  DISTRO_ID="debian"
  BOOTLOADER_ID="Debian"
fi

echo "[INFO] Distribution: $DISTRO_ID"
echo "[INFO] Bootloader ID: $BOOTLOADER_ID"

# Detect boot mode
if [ -d /sys/firmware/efi ]; then
  echo "[INFO] UEFI mode detected"
  BOOT_MODE="uefi"
else
  echo "[INFO] BIOS mode detected"
  BOOT_MODE="bios"
fi

# --- Rileva LUKS da /etc/fstab (fonte più affidabile nel chroot Calamares) ---
# Calamares scrive sempre fstab con /dev/mapper/luks-<UUID> come root device
LUKS_UUID=""
MAPPER_NAME=""

ROOT_FSTAB="$(awk '$2=="/" {print $1}' /etc/fstab 2>/dev/null | head -1)"
echo "[INFO] Root device from fstab: $ROOT_FSTAB"

if [[ "$ROOT_FSTAB" == /dev/mapper/luks-* ]]; then
    MAPPER_NAME="${ROOT_FSTAB#/dev/mapper/}"
    LUKS_UUID="${MAPPER_NAME#luks-}"
    echo "[INFO] LUKS mapper: $MAPPER_NAME"
    echo "[INFO] LUKS UUID:   $LUKS_UUID"
fi

if [ -n "$LUKS_UUID" ]; then
    echo "[INFO] LUKS detected - configuring GRUB and crypttab"

    # 1) GRUB_ENABLE_CRYPTODISK - DEVE essere prima di grub-install
    if grep -q "^GRUB_ENABLE_CRYPTODISK" /etc/default/grub 2>/dev/null; then
        sed -i 's|^GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub
    else
        echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    fi

    # 2) Scrivi crypttab - Rimuovi riga incompleta di Calamares e riscrivi corretta
    sed -i "/$MAPPER_NAME/d" /etc/crypttab 2>/dev/null || true
    echo "$MAPPER_NAME UUID=$LUKS_UUID none luks,discard,initramfs" >> /etc/crypttab
    echo "[OK] crypttab written: $MAPPER_NAME UUID=$LUKS_UUID none luks,discard,initramfs"
    cat /etc/crypttab  # debug

    # 3) Forza CRYPTSETUP in entrambi i percorsi (doppia garanzia)
    mkdir -p /etc/cryptsetup-initramfs
    echo "CRYPTSETUP=y" > /etc/cryptsetup-initramfs/conf-hook
    mkdir -p /etc/initramfs-tools/conf.d
    echo "CRYPTSETUP=y" > /etc/initramfs-tools/conf.d/cryptsetup

    # Verifica hook cryptroot installato
    if [ ! -f /usr/share/initramfs-tools/hooks/cryptroot ] && \
       [ ! -f /usr/share/initramfs-tools/hooks/cryptsetup ]; then
        echo "[WARN] cryptsetup hook not found - reinstalling"
        apt-get install -y --reinstall cryptsetup-initramfs 2>&1
    fi

    # 4) dm-crypt obbligatorio - Debian Trixie + kernel Liquorix: modulo esterno
    echo "dm-crypt"        >> /etc/initramfs-tools/modules
    echo "dm-mod"          >> /etc/initramfs-tools/modules
    echo "aes"             >> /etc/initramfs-tools/modules
    echo "aes_generic"     >> /etc/initramfs-tools/modules
    echo "sha256"          >> /etc/initramfs-tools/modules
    echo "sha256_generic"  >> /etc/initramfs-tools/modules
    echo "cbc"             >> /etc/initramfs-tools/modules
    echo "xts"             >> /etc/initramfs-tools/modules
    echo "algif_skcipher"  >> /etc/initramfs-tools/modules
    echo "[OK] dm-crypt modules added to /etc/initramfs-tools/modules"

    # 5) Hook custom: cryptsetup-initramfs non copia /etc/crypttab nell'initramfs
    # Senza questo il hook cryptroot non trova il device da sbloccare al boot
    printf '#!/bin/sh\nPREREQ="cryptroot"\nprereqs() { echo "$PREREQ"; }\ncase "$1" in prereqs) prereqs; exit 0;; esac\n. /usr/share/initramfs-tools/hook-functions\nif [ -f /etc/crypttab ]; then\n    mkdir -p "${DESTDIR}/etc"\n    install -m 644 /etc/crypttab "${DESTDIR}/etc/crypttab"\nfi\nif [ -f /lib/cryptsetup/functions ]; then\n    mkdir -p "${DESTDIR}/lib/cryptsetup"\n    install -m 644 /lib/cryptsetup/functions "${DESTDIR}/lib/cryptsetup/functions"\nfi\ncopy_exec /sbin/cryptsetup\ncopy_exec /sbin/dmsetup\n' \
        > /etc/initramfs-tools/hooks/copy-crypttab
    chmod +x /etc/initramfs-tools/hooks/copy-crypttab
    echo "[OK] custom hook copy-crypttab installed"

# 6) Rigenera initramfs con mkinitramfs (bypassa il check live di update-initramfs)
    # update-initramfs viene disabilitato nel chroot Calamares perché rileva il live system
    mkdir -p /var/tmp
    KERNEL_VER="$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')"
    if [ -n "$KERNEL_VER" ]; then
        echo "[INFO] Building initramfs for kernel: $KERNEL_VER"
        mkinitramfs -o "/boot/initrd.img-${KERNEL_VER}" "$KERNEL_VER" 2>&1
        echo "[OK] initramfs rebuilt: /boot/initrd.img-${KERNEL_VER}"
    else
        echo "[WARN] No kernel found - skipping initramfs rebuild"
    fi

    # 7) Verifica che crypttab sia nell'initramfs
    INITRD="$(ls /boot/initrd.img-* 2>/dev/null | sort -V | tail -1)"
    if [ -n "$INITRD" ]; then
        if lsinitramfs "$INITRD" 2>/dev/null | grep -q "etc/crypttab"; then
            echo "[OK] crypttab confirmed in initramfs: $INITRD"
        else
            echo "[WARN] crypttab NOT found in initramfs"
        fi
    fi

    echo "[OK] LUKS configured: GRUB_ENABLE_CRYPTODISK=y + crypttab + initramfs"
else
    echo "[INFO] No LUKS detected - standard installation"
fi
# --- Fine blocco LUKS ---

# --- btrfs /boot file rewrite ---
# GRUB 2.12's btrfs driver fails with "premature end of file" reading kernel
# images written by unpackfs (rsync from squashfs). Even after btrfs
# defragment -t 32M -f the bug persisted on the bigger Liquorix vmlinuz
# (16M) while the smaller Debian stock kernel (12M) read fine — defragment
# only rewrites in place and leaves extent metadata GRUB still cannot
# traverse. The known reliable workaround is "apt-get install --reinstall
# linux-image-<ver>" because it deletes the file and writes a fresh one
# from the package, picking up a clean extent allocation. We can do the
# same here without re-running apt: copy each /boot file to a temp name
# with --reflink=never (forces a real data copy, no btrfs reflink), remove
# the original, and rename. The replacement is allocated fresh and lands
# as one or very few contiguous extents that GRUB reads correctly.
# btrfs-progs ships in every Debian live with btrfs support, so the binary
# is guaranteed present whenever the target FS is btrfs.
if [ "$(findmnt -n -o FSTYPE / 2>/dev/null)" = "btrfs" ]; then
  echo "[INFO] btrfs target - rewriting /boot files for clean extent allocation"
  for f in /boot/vmlinuz-* /boot/initrd.img-*; do
    [ -f "$f" ] || continue
    echo "[INFO] rewrite: $f"
    cp -a --reflink=never "$f" "${f}.new" && \
      rm -f "$f" && \
      mv "${f}.new" "$f" && \
      echo "[OK] rewritten: $f" || \
      echo "[WARN] rewrite failed: $f"
  done
  sync
  # Defragment as belt-and-suspenders for any residual fragmentation
  # (e.g. on /boot/grub/* that we did not rewrite).
  btrfs filesystem defragment -r -t 32M -f /boot 2>&1 || true
  sync
  echo "[OK] /boot rewrite + defragment complete"
fi
# --- end btrfs /boot file rewrite ---

if [ "$BOOT_MODE" = "uefi" ]; then
  echo "[STEP 1/5] Installing GRUB for UEFI..."

  if ! mountpoint -q /boot/efi; then
    echo "[ERROR] /boot/efi is not mounted!"
    exit 1
  fi

  # Remove any existing case-variant EFI directories (FAT32 case-insensitive conflict)
  # Without this, old lowercase dirs (e.g. syslinuxos) coexist with new mixed-case
  # dirs (e.g. SysLinuxOS), causing UEFI to load the wrong grubx64.efi → GRUB console
  BOOTLOADER_ID_LOWER="${BOOTLOADER_ID,,}"
  for existing_dir in /boot/efi/EFI/*/; do
    [ -d "$existing_dir" ] || continue
    dirname=$(basename "$existing_dir")
    if [ "${dirname,,}" = "$BOOTLOADER_ID_LOWER" ]; then
      echo "[INFO] Removing existing EFI dir (case conflict): $existing_dir"
      rm -rf "$existing_dir"
    fi
  done

  # Primary install (vendor path)
  grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot/efi \
    --bootloader-id=${BOOTLOADER_ID} \
    --recheck \
    --no-nvram || {
      echo "[WARN] grub-install --no-nvram failed, retrying without it"
      grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id=${BOOTLOADER_ID} \
        --recheck
    }

  # Fallback install (EFI/BOOT/BOOTX64.EFI)
  grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot/efi \
    --removable \
    --recheck || echo "[WARN] grub-install --removable failed"

echo "[STEP 2/5] Creating NVRAM entry (best effort)..."

ESP_DEV="$(findmnt -n -o SOURCE /boot/efi 2>/dev/null | head -1)"
if [ -n "$ESP_DEV" ]; then
  BOOT_DISK="/dev/$(lsblk -no PKNAME "$ESP_DEV" 2>/dev/null | head -1)"
  ESP_PARTNUM="$(lsblk -no PARTNUM "$ESP_DEV" 2>/dev/null | head -1)"

  if [ -n "$BOOT_DISK" ] && [ -n "$ESP_PARTNUM" ]; then
    efibootmgr -c -d "$BOOT_DISK" -p "$ESP_PARTNUM" \
      -L "${BOOTLOADER_ID}" \
      -l "\\EFI\\${BOOTLOADER_ID}\\grubx64.efi" 2>/dev/null || echo "[WARN] efibootmgr failed"
  fi
fi


  echo "[STEP 3/5] Verifying UEFI installation..."
  if [ -f /boot/efi/EFI/${BOOTLOADER_ID}/grubx64.efi ]; then
    echo "[OK] Vendor GRUB UEFI binary found"
    ls -lh /boot/efi/EFI/${BOOTLOADER_ID}/
  else
    echo "[ERROR] Vendor GRUB UEFI binary not found!"
    exit 1
  fi

  if [ -f /boot/efi/EFI/BOOT/BOOTX64.EFI ]; then
    echo "[OK] Fallback BOOTX64.EFI found"
    ls -lh /boot/efi/EFI/BOOT/BOOTX64.EFI
  else
    echo "[WARN] Fallback BOOTX64.EFI missing"
    ls -la /boot/efi/EFI/BOOT || true
  fi

else
  echo "[STEP 1/5] Installing GRUB for BIOS..."

  BOOT_DISK="$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null | head -1)"
  if [ -z "$BOOT_DISK" ]; then
    echo "[WARN] Cannot detect boot disk, trying /dev/sda"
    BOOT_DISK="sda"
  fi

  echo "[INFO] Installing to /dev/$BOOT_DISK"
  grub-install \
    --target=i386-pc \
    --recheck \
    "/dev/$BOOT_DISK" || {
      echo "[ERROR] grub-install failed"
      exit 1
    }

  echo "[OK] GRUB BIOS installed successfully"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Initramfs rebuild deferred to remove-live-admin.service at first boot of the
# installed target. Doing it here (mkinitramfs inside the Calamares chroot)
# was producing 0-byte initrd files on some hosts, breaking both kernels on
# all filesystems. The live-mode initrd copied by unpackfs still boots a real
# installation because the kernel root=UUID arg drives the boot path before
# live-boot scripts try to find live media.

echo "[STEP 5/5] Verifying grub.cfg..."
if [ -f /boot/grub/grub.cfg ] && [ -s /boot/grub/grub.cfg ]; then
  echo "[OK] GRUB config generated successfully"
  echo "First boot entry:"
  grep -A 2 "^menuentry" /boot/grub/grub.cfg | head -5 || true
else
  echo "[ERROR] GRUB config is empty or missing!"
  exit 1
fi

echo "======================================"
echo "  GRUB Installation COMPLETED"
echo "======================================"
exit 0
GRUBSCRIPT

chmod +x /usr/local/bin/calamares-grub-install.sh

# 7b. SCRIPT STANDALONE PER SNAPSHOTS SETUP (btrfs target only — no-op altrove)
# Invoca syslinuxos-snapshots-setup nel target dopo grubinstall, ricreando
# /.snapshots subvol mancante (escluso dalla squashfs source), generando il
# baseline snapshot e rigenerando grub.cfg per popolare grub-btrfs.cfg.
cat > /usr/local/bin/calamares-snapshots-setup.sh << 'SNAPSCRIPT'
#!/bin/bash
# Invoked by Calamares shellprocess inside the installed target (dontChroot:false).
# The setup script bails on `ischroot` unless bypassed: we pass `--force` as argv
# (immune to env stripping) AND set the legacy env var inline as fallback for
# syslinuxos-snapshots < 0.3.6.
set +e  # non bloccante: snapshot setup è "best effort"

LOG=/var/log/calamares-snapshots-setup.log
exec > >(tee -a "$LOG") 2>&1
echo "[snapshots-setup] $(date -Iseconds) start"

if [ -x /usr/sbin/syslinuxos-snapshots-setup ]; then
    SYSLINUXOS_SNAPSHOTS_FORCE=1 /usr/sbin/syslinuxos-snapshots-setup --force
    RC=$?
    echo "[snapshots-setup] exit=$RC"
else
    echo "[snapshots-setup] /usr/sbin/syslinuxos-snapshots-setup non presente, skip."
    echo "[snapshots-setup] (probabile: pacchetto syslinuxos-snapshots non installato sul host)"
fi
echo "[snapshots-setup] $(date -Iseconds) done"
exit 0
SNAPSCRIPT

chmod +x /usr/local/bin/calamares-snapshots-setup.sh

# 8. SHELLPROCESS per GRUB
cat > /etc/calamares/modules/grubinstall.conf << 'GRUBINSTALL'
---
dontChroot: false
timeout: 600
script:
    - /usr/local/bin/calamares-grub-install.sh
GRUBINSTALL

# 8b. SHELLPROCESS per SNAPSHOTS SETUP
cat > /etc/calamares/modules/snapshots-setup.conf << 'SNAPCONF'
---
dontChroot: false
timeout: 300
script:
    - /usr/local/bin/calamares-snapshots-setup.sh
SNAPCONF

# 8. SETTINGS.CONF (CON BRANDING PERSONALIZZATO)
cat > /etc/calamares/settings.conf << 'SETTINGS'
---
modules-search: [ local, /usr/lib/x86_64-linux-gnu/calamares/modules ]

instances:
  - id: grubinstall
    module: shellprocess
    config: grubinstall.conf

  - id: remove-live-user
    module: shellprocess
    config: remove-live-user.conf

  - id: snapshots-setup
    module: shellprocess
    config: snapshots-setup.conf

sequence:
  - show:
      - welcome
      - locale
      - keyboard
      - partition
      - users
      - summary
  - exec:
      - partition
      - mount
      - unpackfs
      - shellprocess@remove-live-user
      - machineid
      - fstab
      - locale
      - keyboard
      - localecfg
      - users
      - displaymanager
      - networkcfg
      - hwclock
      - initramfscfg
      - initramfs
      - services-systemd
      - shellprocess@grubinstall
      - shellprocess@snapshots-setup
      - umount

  - show:
      - finished

branding: syslinuxos
prompt-install: true
dont-chroot: false
disable-cancel: false
disable-cancel-during-exec: false
quit-at-end: false
SETTINGS


# Remove calamares-live-user
cat > /usr/local/bin/calamares-remove-live-user.sh <<'EOF'
#!/bin/bash
set -e

LIVEUSER="admin"

# Se esiste e non è loggato, elimina l'utente e la home (idempotente)
if getent passwd "$LIVEUSER" >/dev/null 2>&1; then
  userdel -r "$LIVEUSER" 2>/dev/null || userdel "$LIVEUSER" 2>/dev/null || true
fi

rm -rf "/home/$LIVEUSER" 2>/dev/null || true

# Rimuovi script Calamares non più necessari nel sistema installato
echo "Cleaning up Calamares live scripts..."
rm -f /usr/local/bin/calamares-grub-install.sh
rm -f /usr/local/bin/calamares-snapshots-setup.sh
rm -f /usr/local/bin/calamares-remove-live-user.sh
rm -f /usr/local/bin/launch-calamares.sh
rm -f /usr/share/polkit-1/actions/org.distroclone.launch-calamares.policy
rm -f /etc/calamares/modules/grubinstall.conf
rm -f /etc/calamares/modules/remove-live-user.conf

# Rimuovi anche script autostart live system se presenti
rm -f /usr/local/bin/*-clean-history.sh
rm -f /etc/xdg/autostart/*-clean-history.desktop
rm -f /usr/local/bin/*-trust-desktop-launchers.sh
rm -f /etc/xdg/autostart/*-trust-desktop-launchers.desktop

echo "Cleanup completed"
EOF
chmod +x /usr/local/bin/calamares-remove-live-user.sh

cat > /etc/calamares/modules/remove-live-user.conf <<'EOF'
---
dontChroot: false
timeout: 30
script:
  - "/bin/bash -c 'if id admin >/dev/null 2>&1; then deluser --remove-home admin 2>/dev/null || true; fi'"
  - "/bin/rm -rf /home/admin"
  - "/bin/bash -c 'mkdir -p /var/log/audit && chmod 0750 /var/log/audit'"
EOF

# Update initramfs
update-initramfs -c -k all

# /var/log/audit is owned by auditd package but rsync --exclude=/var/log/*
# strips it. Recreate so auditd can start on the live ISO and installed target.
mkdir -p /var/log/audit
chmod 0750 /var/log/audit
chown root:root /var/log/audit
apt-mark manual auditd 2>/dev/null || true

# Cleanup
apt clean

# Pulizia finale: rimuovi calamares-install-debian.desktop (può riapparire dopo apt)
rm -f /usr/share/applications/calamares-install-debian.desktop 2>/dev/null || true
rm -f /etc/skel/Desktop/calamares-install-debian.desktop 2>/dev/null || true
find /home/admin/Desktop -name "calamares-install-debian*" -delete 2>/dev/null || true

CHROOT_EOF

echo "admin:${ROOT_PASSWORD}" | chroot "$DEST" chpasswd
echo "root:${ROOT_PASSWORD}" | chroot "$DEST" chpasswd

log_msg "  $MSG_CHROOT_DONE"

# Sostituisci branding statico con quello dinamico
echo "  → Dynamic branding configuration in settings.conf"
sed -i "s/^branding: syslinuxos$/branding: ${DISTRO_ID}/" "$DEST/etc/calamares/settings.conf"

############################################
# [17/30] HOOK POST-INSTALL
############################################
log_msg "$MSG_STEP17"

# Scrive la unit NEL filesystem che finirà installato (DEST)
tee "$DEST/etc/systemd/system/remove-live-admin.service" > /dev/null << 'EOF'

[Unit]
Description=Cleanup live system after installation
After=multi-user.target apt-daily.service apt-daily-upgrade.service
ConditionKernelCommandLine=!boot=live
ConditionPathExists=!/run/live

[Service]
Type=oneshot
Environment=DEBIAN_FRONTEND=noninteractive
TimeoutStartSec=600
ExecStart=/bin/true
RemainAfterExit=no

# Wait for dpkg lock
ExecStartPost=-/bin/bash -c 'for i in $(seq 1 60); do fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || break; sleep 5; done'

# Remove live packages + Calamares (wildcard) + build tools
# Wildcard "calamares*" catches calamares, calamares-settings-debian,
# calamares-extensions, qml-module-io-calamares-*, branding packages, etc.
# bash -c required: systemd ExecStart does not expand globs.
ExecStartPost=-/bin/bash -c 'apt-get -y purge live-boot live-boot-doc live-config live-config-systemd live-tools "calamares*" isolinux syslinux-common syslinux-utils mtools squashfs-tools qt5-assistant 2>/dev/null || true'

# Retry calamares purge (may fail on first attempt due to dpkg lock)
ExecStartPost=-/bin/bash -c 'sleep 10 && apt-get -y purge "calamares*" 2>/dev/null || true'

# Keep SysLinuxOS Tools: distroClone and distroclone-backup must survive autoremove
# auditd: marked manual to survive autoremove after calamares purge
ExecStartPost=-/usr/bin/apt-mark manual distroclone distroclone-backup auditd
ExecStartPost=-/usr/bin/apt-get -y autoremove --purge
ExecStartPost=-/usr/bin/apt-get clean

# Reset snapshot history: apt purges above triggered snapper apt-hook pre/post
# pairs (5+ noise snapshots). Wipe them and create a single clean baseline so
# the user boots into a sensible snapshot state. No-op on non-btrfs / missing
# snapper config (the script self-guards). Non-fatal (leading dash).
# Logs to a file so we have persistent evidence: journald may be volatile and
# the unit file is removed below, making `journalctl -u` queries return empty.
ExecStartPost=-/bin/bash -c '{ echo "=== $(date -Iseconds) reset-baseline start ==="; /usr/sbin/syslinuxos-snapshots-setup --reset-baseline; echo "exit=$?"; echo "=== $(date -Iseconds) reset-baseline done ==="; } >> /var/log/distroclone-reset-baseline.log 2>&1'

# Remove Calamares leftovers/icons
ExecStartPost=-/usr/bin/find /usr/share/applications -maxdepth 1 -type f -iname '*calamares*.desktop' -delete
ExecStartPost=-/usr/bin/update-desktop-database

# Remove Debian Installer desktop entry (Install Debian)
ExecStartPost=-/usr/bin/find /usr/share/applications -maxdepth 1 -type f \( -iname 'debian-installer*.desktop' -o -iname '*debian*install*.desktop' \) -delete
ExecStartPost=-/usr/bin/find /etc/xdg/autostart -maxdepth 1 -type f \( -iname 'debian-installer*.desktop' -o -iname '*debian*install*.desktop' \) -delete
ExecStartPost=-/usr/bin/update-desktop-database

# Remove installer launchers/icons after installation
ExecStartPost=-/bin/rm -f /usr/share/applications/calamares-install-debian.desktop
ExecStartPost=-/bin/rm -f /usr/share/applications/install-system.desktop
ExecStartPost=-/bin/bash -c 'rm -f /home/*/Desktop/calamares-install-debian.desktop /home/*/Desktop/install-system.desktop 2>/dev/null || true'
ExecStartPost=-/bin/rm -f /etc/skel/Desktop/calamares-install-debian.desktop
ExecStartPost=-/bin/rm -f /etc/skel/Desktop/install-system.desktop
ExecStartPost=-/usr/bin/update-desktop-database

# Remove Imagemagick GUI menu entry (keep imagemagick: needed by distroclone-backup)
ExecStartPost=-/bin/rm -f /usr/share/applications/display-im7.q16.desktop
ExecStartPost=-/usr/bin/update-desktop-database

# (Opzionale) se aggiungi il fix GNOME "trusted launcher", pulisci anche quello
ExecStartPost=-/bin/rm -f /etc/xdg/autostart/syslinuxos-trust-desktop-launchers.desktop
ExecStartPost=-/bin/rm -f /usr/local/bin/syslinuxos-trust-desktop-launchers.sh

# Delete live user
ExecStartPost=-/usr/sbin/deluser --remove-home admin
ExecStartPost=-/bin/rm -rf /home/admin

# Remove host network configurations (WiFi, Ethernet connections from build system)
ExecStartPost=-/bin/rm -rf /etc/NetworkManager/system-connections/*
ExecStartPost=-/bin/rm -rf /var/lib/NetworkManager/*
ExecStartPost=-/bin/rm -f /etc/netplan/*.yaml
ExecStartPost=-/bin/rm -f /etc/wpa_supplicant/wpa_supplicant.conf
ExecStartPost=-/bin/systemctl restart NetworkManager

# Clean icon cache (non fatal)
ExecStartPost=-/bin/rm -rf /usr/share/icons/hicolor/icon-theme.cache

# Rimuovi pacchetti LUKS solo se root NON è cifrato
# (se cifrato, cryptsetup-initramfs deve rimanere!)
#ExecStartPost=-/bin/bash -c 'if ! grep -q luks /etc/crypttab 2>/dev/null; then apt-get -y purge cryptsetup-bin; fi'
ExecStartPost=-/usr/sbin/update-initramfs -c -k all

# Remove self (non fatal)
ExecStartPost=-/bin/systemctl disable --now remove-live-admin.service
ExecStartPost=-/bin/rm -f /etc/systemd/system/remove-live-admin.service

# Remove self calamares-live-user
ExecStartPost=-/bin/rm -f /usr/local/bin/calamares-remove-live-user.sh

# Remove DistroClone-created scripts (not part of any package)
ExecStartPost=-/bin/rm -f /usr/local/bin/calamares-grub-install.sh
rm -f /usr/local/bin/calamares-snapshots-setup.sh
ExecStartPost=-/bin/rm -f /usr/local/bin/launch-calamares.sh
ExecStartPost=-/bin/rm -f /usr/share/polkit-1/actions/org.distroclone.launch-calamares.policy
ExecStartPost=-/bin/rm -rf /etc/calamares
ExecStartPost=-/bin/rm -rf /usr/share/calamares

[Install]
WantedBy=multi-user.target
EOF

# Abilita la unit nel chroot installabile
chroot "$DEST" /bin/bash -c "systemctl daemon-reload && systemctl enable remove-live-admin.service"

############################################
# [18/30] UMOUNT CHROOT
############################################
log_msg "$MSG_STEP18"

for d in tmp dev/pts dev run sys proc; do
  umount -l "$DEST/$d" || true
done

############################################
# [19/30] SANITY CHECK
############################################
log_msg "$MSG_STEP19"

for d in boot boot/grub boot/efi; do
  [ -d "$DEST/$d" ] || { echo "$MSG_ERR_MISSING $DEST/$d"; exit 1; }
done

############################################
# [20/30] KERNEL + INITRD
############################################
log_msg "$MSG_STEP20"

KERNEL=$(ls "$DEST"/boot/vmlinuz-* | sort -V | tail -n1)
INITRD=$(ls "$DEST"/boot/initrd.img-* | sort -V | tail -n1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
  echo "$MSG_ERR_KERNEL"
  exit 1
fi

cp "$KERNEL" "$ISO_DIR/live/vmlinuz"
cp "$INITRD" "$ISO_DIR/live/initrd.img"

echo "  ✓ $MSG_KERNEL: $(basename $KERNEL)"
echo "  ✓ Initrd: $(basename $INITRD)"

############################################
# [21/30] PAUSE PER MODIFICHE MANUALI
############################################
log_msg "$MSG_STEP21"

MANUAL_EDIT=false

# Rigenera logo DC per il dialog
TEMP_LOGO="$(get_dc_logo 128)"

if [ "$GUI_TOOL" = "yad" ]; then
        yad --question \
        --title="$MSG_MANEDIT_TITLE" \
        ${TEMP_LOGO:+--window-icon="$TEMP_LOGO"} \
        ${TEMP_LOGO:+--image="$TEMP_LOGO"} \
        --text="$MSG_MANEDIT_HEADING\n\n$MSG_MANEDIT_TEXT\n\n<b>$MSG_MANEDIT_PATH</b> $DEST\n\n$MSG_MANEDIT_SELECT" \
        --button="$MSG_BTN_EDIT:0" \
        --button="$MSG_BTN_CONTINUE:1" \
        --width=500 --height=200 \
        --fixed \
        --center 2>/dev/null && MANUAL_EDIT=true

else
    zenity --question \
        --title="$MSG_MANEDIT_TITLE" \
        --text="$MSG_MANEDIT_ZENITY ($DEST)" \
        --ok-label="$MSG_BTN_YES" --cancel-label="$MSG_BTN_NO" \
        --width=400 2>/dev/null && MANUAL_EDIT=true
fi

if [ "$MANUAL_EDIT" = true ]; then
    echo ""
    echo "=========================================="
    echo "  $MSG_PAUSE_TITLE"
    echo "=========================================="
    echo ""
    echo "  $MSG_PAUSE_AVAILABLE"
    echo "  → $DEST"
    echo ""
    echo "  $MSG_PAUSE_CHROOT"
    echo "  sudo chroot $DEST /bin/bash"
    echo ""
    echo "  $MSG_PAUSE_DONE"
    echo ""
    echo "=========================================="
    read -p "$MSG_PAUSE_ENTER "
    echo "$MSG_PAUSE_SHOOTING"
fi

############################################
# [22/30] SCELTA COMPRESSIONE SQUASHFS
############################################
log_msg "$MSG_STEP22"

# Se YAD è stato usato, la compressione è già impostata
# Altrimenti, chiedi all'utente con Zenity o terminale
if [ "$GUI_TOOL" != "yad" ]; then
    SQUASH_OPTS=""
    COMP_LABEL="standard"
    
    if command -v zenity >/dev/null 2>&1; then
        CHOICE=$(zenity --list \
            --title="$MSG_COMP_SELECT_TITLE" \
            --text="$MSG_COMP_SELECT_TEXT" \
            --radiolist \
            --column="$MSG_COMP_USING" --column="$MSG_COMP_CODE" --column="$MSG_COMP_DESCRIPTION" \
            TRUE  "F" "$MSG_COMP_FAST_DESC" \
            FALSE "S" "$MSG_COMP_STD_DESC" \
            FALSE "M" "$MSG_COMP_MAX_DESC" \
            --height=320 --width=500) || CHOICE="S"
    else
        # Terminale: chiedi manualmente
        echo ""
        echo "$MSG_TTY_SELECT_COMP"
        echo "  F = $MSG_TTY_COMP_FAST"
        echo "  S = $MSG_TTY_COMP_STD"
        echo "  M = $MSG_TTY_COMP_MAX"
        read -p "$MSG_TTY_CHOICE: " -n 1 -r CHOICE
        echo ""
        [ -z "$CHOICE" ] && CHOICE="S"
    fi
    
    case "$CHOICE" in
        F|f)
            SQUASHFS_COMP="lz4"
            ;;
        M|m)
            SQUASHFS_COMP="xz-bcj"
            ;;
        *)
            SQUASHFS_COMP="xz"
            ;;
    esac
fi

# Configura opzioni squashfs in base alla scelta
SQUASH_OPTS=""
COMP_LABEL="standard"

case "$SQUASHFS_COMP" in
  lz4)
    echo "  $MSG_COMP_FAST_LOG"
    SQUASH_OPTS="-comp lz4"
    COMP_LABEL="fast"
    ;;
  xz-bcj)
    echo "  $MSG_COMP_MAX_LOG"
    SQUASH_OPTS="-comp xz -Xbcj x86 -Xdict-size 100% -b 1M"
    COMP_LABEL="max"
    ;;
  *)
    echo "  $MSG_COMP_STD_LOG"
    SQUASH_OPTS="-comp xz -b 256K -Xdict-size 100%"
    COMP_LABEL="standard"
    ;;
esac

############################################
# [23/30] CREAZIONE SQUASHFS
############################################
log_msg "$MSG_STEP23 ($COMP_LABEL)"

# Pulisci var/log prima dello squashfs: rimuovi file log ma preserva
# var/log/audit/ (directory owned da auditd, necessaria all'avvio del daemon).
# Non usiamo -e var/log in mksquashfs per permettere l'inclusione di audit/.
find "$DEST/var/log" -maxdepth 1 -mindepth 1 ! -name 'audit' -exec rm -rf {} + 2>/dev/null || true

mksquashfs "$DEST" "$ISO_DIR/live/filesystem.squashfs" \
  $SQUASH_OPTS \
  -e var/cache \
  -e var/tmp \
  -e usr/share/doc \
  -e usr/share/info \
  -e root/.cache \
  -e home/*/.cache \
  -e home/*/.local/share/Trash \
  -e .snapshots \
  -e .snapshots/* \
  -e var/lib/snapper/snapshots \
  -e '@.rollback-bak-*' \
  -wildcards

echo "  $MSG_SQUASH_SIZE: $(du -h "$ISO_DIR/live/filesystem.squashfs" | cut -f1)"

############################################
# [24/30] GRUB configuration
############################################
log_msg "$MSG_STEP24"

mkdir -p "$ISO_DIR/boot/grub"

# Gestione grub.png - Usa DistroClone background se presente
if [ -f "distroClone-grub.png" ]; then
    cp "distroClone-grub.png" "$ISO_DIR/boot/grub/grub.png"
    echo "  $MSG_GRUB_CUSTOM"
else
    if command -v $IM_CMD >/dev/null 2>&1; then
        $IM_CMD -size 1024x768 -depth 8 \
            -define gradient:direction=south \
            gradient:'#0a1628'-'#162d50' \
            -gravity center \
            -font DejaVu-Sans-Bold -pointsize 36 \
            -fill white -annotate +0-40 "${DISTRO_NAME}" \
            -font DejaVu-Sans -pointsize 18 \
            -fill '#ccddff' -annotate +0+20 "Boot Menu" \
            -depth 8 -type TrueColor \
            -interlace none \
            -define png:color-type=2 \
            -define png:bit-depth=8 \
            "$ISO_DIR/boot/grub/grub.png"
        echo "  $MSG_GRUB_DEFAULT"
    else
        echo "  $MSG_GRUB_NOCONVERT"
    fi
fi

cp /usr/share/grub/unicode.pf2 "$ISO_DIR/boot/grub/unicode.pf2"

cat > "$ISO_DIR/boot/grub/grub.cfg" << EOF
# Carica i moduli necessari
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660
insmod all_video
insmod font
insmod png
insmod gfxterm
insmod gfxterm_background

# Trova la partizione della ISO tramite l'etichetta
search --no-floppy --set=root --label ${ISO_LABEL}

# Attivazione Grafica (Il font deve essere caricato PRIMA di gfxterm)
loadfont /boot/grub/unicode.pf2
set gfxmode=auto
terminal_output gfxterm

# Caricamento Sfondo (se disponibile)
if background_image /boot/grub/grub.png ; then
    set color_normal=white/black
    set color_highlight=yellow/black
fi

set default=0
set timeout=5

menuentry "$MSG_GRUB_TRY ${DISTRO_NAME}" {
    linux /live/vmlinuz boot=live user=admin quiet
    initrd /live/initrd.img
}

menuentry "${DISTRO_NAME} $MSG_GRUB_SAFE" {
    linux /live/vmlinuz boot=live user=admin quiet nomodeset
    initrd /live/initrd.img
}

menuentry "$MSG_GRUB_INSTALL ${DISTRO_NAME}" {
    linux /live/vmlinuz boot=live user=admin quiet systemd.unit=multi-user.target
    initrd /live/initrd.img
}

menuentry "UEFI Firmware Settings" {
    setparams 'UEFI Firmware Settings'
    fwsetup
}

EOF

############################################
# [25/30] GRUB EFI binaries
############################################
log_msg "$MSG_STEP25"

# Nota: ho aggiunto video_fb, efi_gop e efi_uga che sono vitali su UEFI/VirtualBox
grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos fat iso9660 search search_label all_video video_fb efi_gop efi_uga font gfxterm gfxterm_background png echo test" \
    --output="$ISO_DIR/EFI/BOOT/BOOTX64.EFI" \
    "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg"

############################################
# [26/30] EFI SYSTEM PARTITION IMAGE
############################################
log_msg "$MSG_STEP26"
(
  cd "$ISO_DIR" || exit 1
  dd if=/dev/zero of=efiboot.img bs=1M count=20 status=none
  mkfs.vfat -n 'EFIBOOT' efiboot.img >/dev/null
  mmd -i efiboot.img ::/EFI ::/EFI/BOOT
  mcopy -i efiboot.img EFI/BOOT/BOOTX64.EFI ::/EFI/BOOT/
  echo "[OK] efiboot.img: $(du -h efiboot.img | cut -f1)"
)

############################################
# [27/30] ISOLINUX BIOS
############################################
log_msg "$MSG_STEP27"

mkdir -p "$ISO_DIR/isolinux"

cat > "$ISO_DIR/isolinux/isolinux.cfg" << EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
DEFAULT live

MENU TITLE ${DISTRO_NAME} Boot Menu

LABEL live
  MENU LABEL ^${DISTRO_NAME} Live
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live user=admin quiet

LABEL install
  MENU LABEL ^Install ${DISTRO_NAME}
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live user=admin quiet

LABEL debug
  MENU LABEL Live (^Debug)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live user=admin systemd.log_level=debug

LABEL failsafe
  MENU LABEL Live (^Failsafe)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live user=admin noapic noacpi
EOF

# Auto-detect paths Syslinux
for file in isolinux.bin isohdpfx.bin; do
  found=false
  for dir in /usr/lib/ISOLINUX /usr/lib/syslinux/bios /usr/share/syslinux /usr/lib/syslinux/modules/bios; do
    if [ -f "$dir/$file" ]; then
      cp "$dir/$file" "$ISO_DIR/isolinux/"
      echo "[OK] Copied $file da $dir"
      found=true
      break
    fi
  done
  if [ "$found" = false ]; then
    echo "WARN: $file not found, skip (not critical for UEFI)"
  fi
done

# Moduli C32 (fallback multiplo)
cp /usr/lib/syslinux/modules/bios/*.c32 "$ISO_DIR/isolinux/" 2>/dev/null || \
cp /usr/lib/syslinux/bios/*.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true

############################################
# [28/30] ISO IBRIDA FINALE
############################################
log_msg "$MSG_STEP28"

ISO_SIZE=$(du -sm "$ISO_DIR" | cut -f1)
CYLINDERS=$((ISO_SIZE * 2 / 255 / 63 + 1))

if [ $CYLINDERS -gt 1024 ]; then
  echo "$MSG_WARN_BIGISO ($ISO_SIZE MB)"
fi

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "$ISO_LABEL" \
  -joliet -joliet-long \
  -rational-rock \
  --mbr-force-bootable \
  -partition_offset 16 \
  -isohybrid-mbr "$ISO_DIR/isolinux/isohdpfx.bin" \
  -eltorito-boot isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
  --eltorito-catalog isolinux/isolinux.cat \
  -eltorito-alt-boot \
    -e --interval:appended_partition_2:all:: \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
  -isohybrid-apm-hfsplus \
  -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "$ISO_DIR/efiboot.img" \
  -output "$LIVE_DIR/$ISO_NAME" \
  "$ISO_DIR" 2>&1 | grep -E "(Warning|Error)" || true

############################################
# [29/30] VERIFICA FINALE
############################################
log_msg "$MSG_STEP29"

if [ -f "$LIVE_DIR/$ISO_NAME" ]; then
  ISO_SIZE_FINAL=$(du -h "$LIVE_DIR/$ISO_NAME" | cut -f1)
  
  echo ""
  echo "=========================================="
  echo "$MSG_ISO_SUCCESS"
  echo "=========================================="
  echo "  $MSG_FILE: $LIVE_DIR/$ISO_NAME"
  echo "  $MSG_SIZE: $ISO_SIZE_FINAL"
  
echo "$MSG_MD5_GEN"

cd "$LIVE_DIR"
md5sum "$ISO_NAME" > "$ISO_NAME.md5"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"

echo "$MSG_CREATED: $LIVE_DIR/$ISO_NAME.md5 & $LIVE_DIR/$ISO_NAME.sha256"
  
  echo "=========================================="
  echo ""
  echo "$MSG_TEST_ISO"
  echo "  1. $MSG_TEST_QEMU $LIVE_DIR/$ISO_NAME"
  echo "  2. $MSG_TEST_VBOX $ISO_NAME"
  echo "  3. ${MSG_TEST_USB}$LIVE_DIR/$ISO_NAME of=/dev/sdX bs=4M status=progress conv=fsync oflag=direct && sudo sync"
  echo ""
  
############################################
  # [30/30] PULIZIA SISTEMA HOST
############################################
# Salva logo in /tmp PRIMA della pulizia
  FINAL_LOGO="$(get_dc_logo 128)"
  if [ -n "$FINAL_LOGO" ] && [ -f "$FINAL_LOGO" ]; then
      cp "$FINAL_LOGO" /tmp/distroClone-final-logo.png 2>/dev/null
      FINAL_LOGO="/tmp/distroClone-final-logo.png"
  fi
log_msg "$MSG_STEP30"
  
  # Rimuovi directory di lavoro
  echo "$MSG_REMOVING_DIR"
  # Umount residui prima di rm
  umount -lR /mnt/${DISTRO_ID}_live/rootfs 2>/dev/null || true
  sleep 2
  rm -rf /mnt/${DISTRO_ID}_live/rootfs 2>/dev/null || true
  rm -rf /mnt/${DISTRO_ID}_live/iso 2>/dev/null || true

  # Rimuovi voce "Install Debian" dal sistema host
  # calamares-settings-debian deploya /etc/xdg/autostart/calamares-desktop-icon.desktop
  # che a ogni login esegue add-calamares-desktop-icon e ricrea l'icona sul Desktop.
  # Rimuoviamo autostart + script + launcher "Install Debian" residui.
  # NB: install-system.desktop (creato in chroot per la live ISO) non viene toccato.
  # distroClone reinstallera' calamares al prossimo lancio (riga ~1416),
  # il cleanup verra' rieseguito qui.
  echo "$MSG_REMOVING_CALAMARES"
  rm -f /etc/xdg/autostart/calamares-desktop-icon.desktop 2>/dev/null || true
  rm -f /usr/bin/add-calamares-desktop-icon 2>/dev/null || true
  rm -f /usr/share/applications/calamares-install-debian.desktop 2>/dev/null || true
  for d in /home/*/Desktop /root/Desktop; do
    [ -d "$d" ] || continue
    rm -f "$d"/calamares-install-debian.desktop 2>/dev/null || true
  done
  update-desktop-database 2>/dev/null || true
  echo "$MSG_CALAMARES_REMOVED"

  # Chiudi finestra log
  exec 3>&- 2>/dev/null || true
  if [ -n "$LOG_PID" ] && kill -0 "$LOG_PID" 2>/dev/null; then
      kill "$LOG_PID" 2>/dev/null
      wait "$LOG_PID" 2>/dev/null || true
  fi

  # Dialog finale di successo
  if [ "$GUI_TOOL" = "yad" ]; then
      TEMP_LOGO="$FINAL_LOGO"
      yad --info \
          --title="$MSG_COMPLETED_TITLE" \
          ${TEMP_LOGO:+--window-icon="$TEMP_LOGO"} \
          ${TEMP_LOGO:+--image="$TEMP_LOGO"} \
          --text="$MSG_ISO_SUCCESS_BIG\n\n<b>$MSG_FILE:</b> $LIVE_DIR/$ISO_NAME\n<b>$MSG_SIZE:</b> $ISO_SIZE_FINAL\n\n${MSG_TEST_TEXT//%ISO%/$LIVE_DIR/$ISO_NAME}" \
          --button="OK:0" \
          --width=510 --height=200 \
          --fixed \
          --center \
          2>/dev/null
  fi
  
  
else
  echo ""
  echo "=========================================="
  echo "$MSG_ISO_ERROR"
  echo "=========================================="

  # Chiudi finestra log
  exec 3>&- 2>/dev/null || true
  if [ -n "$LOG_PID" ] && kill -0 "$LOG_PID" 2>/dev/null; then
      kill "$LOG_PID" 2>/dev/null
      wait "$LOG_PID" 2>/dev/null || true
  fi

  if [ "$GUI_TOOL" = "yad" ]; then
      yad --error \
          --title="$MSG_ERROR_TITLE" \
          --text="$MSG_ISO_FAIL_BIG" \
          --button="OK:0" \
          --width=400 --height=200 \
          --fixed
          --center \
          2>/dev/null
  fi

  exit 1
fi
