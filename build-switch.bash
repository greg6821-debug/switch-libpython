set -e

source $DEVKITPRO/switchvars.sh
mkdir Python-3.9.22/Modules
# Копируем наши видео-плеер файлы в Python
echo "Copying video player files to Python build..."
cp -r video_player Python-3.9.22/Modules/

pushd Python-3.9.22
mkdir -p build-switch
cp ../cpython_config_files/config.site build-switch
pushd build-switch
mkdir local_prefix
export LOCAL_PREFIX=$(realpath local_prefix)

# Копируем Setup.local с видео-плеером
cat > Setup.local << 'EOF'
# Video player module for Nintendo Switch
_videoplayer videoplayer_python.c video_player.c video_player.h -lavformat -lavcodec -lavutil -lswscale -lswresample -lSDL2 -lm -logg -lvorbisidec -lz -lbz2

# Отключаем ненужные модули для экономии места
#*disabled*
#_tkinter
#_curses
#_curses_panel
#_dbm
#_gdbm
#_sqlite3
#_ssl
#_hashlib
EOF

echo "Configuration for Switch video player added to Setup.local"

../configure \
  --host=aarch64-none-elf \
  --build=$(../config.guess) \
  --prefix="$LOCAL_PREFIX" \
  --disable-ipv6 \
  --disable-shared \
  --enable-optimizations \
  --without-ensurepip \
  --without-pymalloc \
  ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no \
  LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs $LDFLAGS" \
  CONFIG_SITE="config.site"
  
popd

# Копируем наши исходники видео-плеера в build-switch
echo "Copying video player source files..."
mkdir -p build-switch/Modules
cp Modules/video_player/video_player.c build-switch/Modules/
cp Modules/video_player/video_player.h build-switch/Modules/
cp Modules/video_player/videoplayer_python.c build-switch/Modules/

pushd build-switch
echo "Building Python with video player support..."
make -j $(getconf _NPROCESSORS_ONLN) libpython3.9.a
mkdir -p $LOCAL_PREFIX/lib
cp libpython3.9.a $LOCAL_PREFIX/lib/libpython3.9.a
make libinstall
make inclinstall

# Собираем отдельно модуль видео-плеера
echo "Building video player module..."
cd Modules
$CC -O2 -Wall -fPIC -D__SWITCH__ \
    -I../../Include \
    -I$DEVKITPRO/libnx/include \
    -I$DEVKITPRO/portlibs/switch/include \
    -c videoplayer_python.c -o videoplayer_python.o
    
$CC -O2 -Wall -fPIC -D__SWITCH__ \
    -I../../Include \
    -I$DEVKITPRO/libnx/include \
    -I$DEVKITPRO/portlibs/switch/include \
    -c video_player.c -o video_player.o
    
$CC -shared -specs=$DEVKITPRO/libnx/switch.specs \
    -o _videoplayer.so \
    videoplayer_python.o video_player.o \
    -L$DEVKITPRO/libnx/lib -L$DEVKITPRO/portlibs/switch/lib \
    -lavformat -lavcodec -lavutil -lswscale -lswresample \
    -lSDL2 -lm -logg -lvorbisidec -lz -lbz2 -lnx

# Копируем собранный модуль
mkdir -p $LOCAL_PREFIX/lib/python3.9/lib-dynload/
cp _videoplayer.so $LOCAL_PREFIX/lib/python3.9/lib-dynload/
echo "Video player module built and installed"

popd
popd

# Создаем структуру вывода
mkdir -p python-output
cp -r $LOCAL_PREFIX/* python-output/

# Создаем Python-обертку для видео-плеера
cat > python-output/lib/python3.9/videoplayer.py << 'EOF'
"""
Video player module for Ren'Py on Nintendo Switch
"""

import sys
import os

# Импортируем C-модуль
try:
    from _videoplayer import *
    VIDEO_PLAYER_AVAILABLE = True
    print("Switch video player module loaded successfully")
except ImportError as e:
    print(f"WARNING: Could not import _videoplayer: {e}")
    VIDEO_PLAYER_AVAILABLE = False
    
    # Создаем заглушки для отладки
    class VideoPlayerError(Exception):
        pass
    
    error = VideoPlayerError
    
    def play_video(path, skip_enabled=True, delay_seconds=3.0):
        print(f"STUB: Would play video: {path}")
        return True
    
    def init():
        print("STUB: Initializing video player")
        
    def quit():
        print("STUB: Quitting video player")

class SwitchVideoPlayer:
    """Video player for Nintendo Switch with Ren'Py integration"""
    
    def __init__(self):
        if VIDEO_PLAYER_AVAILABLE:
            init()
        self.is_playing = False
        
    def play_file(self, filename, skip_enabled=True, delay=0.0):
        """
        Play a video file
        """
        if not VIDEO_PLAYER_AVAILABLE:
            print(f"Cannot play video: video player not available")
            return False
            
        if self.is_playing:
            self.stop()
            
        # Преобразуем пути для Switch
        if filename.startswith("game/"):
            filename = "romfs:/Contents/" + filename
        elif filename.startswith("/"):
            filename = "romfs:" + filename
        elif not filename.startswith(("romfs:", "sdmc:")):
            # Пробуем найти файл
            for prefix in ["romfs:/Contents/game/", "romfs:/Contents/", "romfs:/"]:
                test_path = prefix + filename
                import os
                if os.path.exists(test_path.replace("romfs:", "")):
                    filename = test_path
                    break
        
        print(f"SwitchVideoPlayer: Playing {filename}")
        
        try:
            self.is_playing = True
            play_video(filename, skip_enabled, delay)
            self.is_playing = False
            return True
        except Exception as e:
            print(f"Error playing video: {e}")
            self.is_playing = False
            return False
    
    def stop(self):
        """Stop video playback"""
        self.is_playing = False
    
    def cleanup(self):
        """Cleanup resources"""
        if VIDEO_PLAYER_AVAILABLE:
            quit()

# Создаем глобальный экземпляр
_player = None

def get_player():
    """Get or create global video player instance"""
    global _player
    if _player is None:
        _player = SwitchVideoPlayer()
    return _player

def play_movie(filename, delay=0, loops=0, stop_music=True):
    """
    Replacement for renpy.movie_cutscene
    """
    player = get_player()
    success = player.play_file(filename, delay=delay)
    return success

# Экспорт
__all__ = ['SwitchVideoPlayer', 'play_movie', 'get_player']
EOF

echo "Python build with video player support completed!"
