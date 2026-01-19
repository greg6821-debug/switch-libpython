#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <structmember.h>
#include "video_player.h"

static PyObject *VideoPlayerError;

// Функция для проверки существования файла
static int file_exists(const char *path) {
    FILE *file = fopen(path, "rb");
    if (file) {
        fclose(file);
        return 1;
    }
    return 0;
}

// Обертка для play_video_file_delay
static PyObject *py_play_video(PyObject *self, PyObject *args, PyObject *kwargs)
{
    const char *path = NULL;
    int skip_enabled = 1;
    float delay_seconds = 0.0f;
    int show_skip_indicator = 1;
    
    static char *kwlist[] = {"path", "skip_enabled", "delay_seconds", "show_skip_indicator", NULL};
    
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "s|ifp", kwlist, 
                                     &path, &skip_enabled, &delay_seconds, &show_skip_indicator)) {
        return NULL;
    }
    
    if (!path) {
        PyErr_SetString(VideoPlayerError, "Path is required");
        return NULL;
    }
    
    printf("[Python] Playing video: %s\n", path);
    
    // Вызываем наш C-код
    play_video_file_delay(path, skip_enabled, delay_seconds);
    
    Py_RETURN_NONE;
}

// Простая функция для проверки работы
static PyObject *py_test_playback(PyObject *self, PyObject *args)
{
    const char *path = NULL;
    
    if (!PyArg_ParseTuple(args, "s", &path)) {
        return NULL;
    }
    
    printf("[Python] Testing playback of: %s\n", path);
    
    // Проверяем существование файла
    if (file_exists(path)) {
        return PyLong_FromLong(1);
    } else {
        // Пробуем разные пути
        const char *test_paths[] = {
            path,
            "",
            "",
            "",
            NULL
        };
        
        // Формируем альтернативные пути
        char alt_path1[512], alt_path2[512], alt_path3[512];
        
        if (strncmp(path, "game/", 5) == 0) {
            snprintf(alt_path1, sizeof(alt_path1), "romfs:/Contents/%s", path);
            snprintf(alt_path2, sizeof(alt_path2), "romfs:/Contents/game/%s", path + 5);
            test_paths[1] = alt_path1;
            test_paths[2] = alt_path2;
        }
        
        for (int i = 0; test_paths[i] != NULL; i++) {
            if (test_paths[i][0] && file_exists(test_paths[i])) {
                printf("[Python] Found file at: %s\n", test_paths[i]);
                return PyLong_FromLong(1);
            }
        }
        
        return PyLong_FromLong(0);
    }
}

// Обертка для video_player_init
static PyObject *py_init(PyObject *self, PyObject *args)
{
    video_player_init();
    Py_RETURN_NONE;
}

// Обертка для video_player_quit
static PyObject *py_quit(PyObject *self, PyObject *args)
{
    video_player_quit();
    Py_RETURN_NONE;
}

// Получение информации о видео-плеере
static PyObject *py_get_info(PyObject *self, PyObject *args)
{
    return Py_BuildValue("{s:s, s:s, s:i}",
        "name", "Switch Video Player",
        "version", "1.0",
        "available", 1
    );
}

// Методы модуля
static PyMethodDef VideoPlayerMethods[] = {
    {"play", (PyCFunction)py_play_video, METH_VARARGS | METH_KEYWORDS, 
     "Play video file on Switch\n\n"
     "Args:\n"
     "  path: Path to video file\n"
     "  skip_enabled: Whether skipping is enabled (default: True)\n"
     "  delay_seconds: Delay before playback (default: 0.0)\n"
     "  show_skip_indicator: Show skip indicator (default: True)\n"},
    {"test", py_test_playback, METH_VARARGS, "Test if video file exists"},
    {"init", py_init, METH_NOARGS, "Initialize video player"},
    {"quit", py_quit, METH_NOARGS, "Cleanup video player"},
    {"get_info", py_get_info, METH_NOARGS, "Get video player information"},
    {NULL, NULL, 0, NULL}
};

// Определение модуля
static struct PyModuleDef videoplayermodule = {
    PyModuleDef_HEAD_INIT,
    "_videoplayer",
    "Video player module for Nintendo Switch with FFmpeg and SDL2 integration",
    -1,
    VideoPlayerMethods,
    NULL, NULL, NULL, NULL
};

// Инициализация модуля
PyMODINIT_FUNC PyInit__videoplayer(void)
{
    PyObject *m;
    
    m = PyModule_Create(&videoplayermodule);
    if (m == NULL)
        return NULL;
    
    // Создаем исключение
    VideoPlayerError = PyErr_NewException("_videoplayer.error", NULL, NULL);
    Py_XINCREF(VideoPlayerError);
    
    if (PyModule_AddObject(m, "error", VideoPlayerError) < 0) {
        Py_XDECREF(VideoPlayerError);
        Py_DECREF(m);
        return NULL;
    }
    
    // Добавляем константы
    PyModule_AddIntConstant(m, "SKIP_HOLD_TIME", 3);
    PyModule_AddIntConstant(m, "DEFAULT_WIDTH", 1280);
    PyModule_AddIntConstant(m, "DEFAULT_HEIGHT", 720);
    
    printf("[Python] Switch video player module initialized\n");
    
    return m;
}
