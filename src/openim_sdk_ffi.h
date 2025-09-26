#include "./include/dart_api_dl.h"

typedef struct
{
    void (*onMethodChannel)(Dart_Port_DL port, char *);
} Openim_Listener;