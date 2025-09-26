// Copyright (c) 2025 河川(MrYzys)[https://github.com/MrYzys]
// Created: 2025-09-26
// License: AGPL-3.0-only (see LICENSE)
#include "./include/dart_api_dl.h"

typedef struct
{
    void (*onMethodChannel)(Dart_Port_DL port, char *);
} Openim_Listener;