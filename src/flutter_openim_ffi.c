#include <stdio.h>
#include "flutter_openim_ffi.h"
#include "include/dart_api_dl.c"

#if defined(_WIN32) || defined(_WIN64)
DWORD WINAPI entry_point(LPVOID args)
{
    ThreadArgs *thread_args = (ThreadArgs *)args;

    // Construct dart_object using the received arguments
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kString;
    dart_object.value.as_string = thread_args->message;

    const bool result = Dart_PostCObject_DL(thread_args->port, &dart_object);
    if (!result)
    {
        printf("C   :  Posting message to port failed.\n");
    }

    free(thread_args);
    return 0;
}

void onMethodChannelFunc(Dart_Port_DL port, char *message)
{
    ThreadArgs *args = (ThreadArgs *)malloc(sizeof(ThreadArgs));
    if (args == NULL)
    {
        printf("C   :  Failed to allocate memory for args.\n");
        return;
    }

    // Assign values to the arguments
    args->port = port;
    args->message = message; // strdup allocates memory for the string

    HANDLE thread = CreateThread(NULL, 0, entry_point, (LPVOID)args, 0, NULL);
    if (thread == NULL)
    {
        printf("C   :  Failed to create thread.\n");
        free(args);
        return;
    }

    CloseHandle(thread);
}
#else

void *entry_point(void *args)
{
    ThreadArgs *thread_args = (ThreadArgs *)args;

    // Construct dart_object using the received arguments
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kString;
    dart_object.value.as_string = thread_args->message;

    const bool result = Dart_PostCObject_DL(thread_args->port, &dart_object);
    if (!result)
    {
        printf("C   :  Posting message to port failed.\n");
    }
    free(thread_args->message);
    free(thread_args);

    pthread_exit(NULL);
}

void onMethodChannelFunc(Dart_Port_DL port, char *message)
{

    // Allocate memory for the arguments
    ThreadArgs *args = (ThreadArgs *)malloc(sizeof(ThreadArgs));
    if (args == NULL)
    {
        printf("C   :  Failed to allocate memory for args.\n");
        return;
    }

    // Assign values to the arguments
    args->port = port;
    args->message = strdup(message); // strdup allocates memory for the string

    pthread_t thread;
    pthread_create(&thread, NULL, entry_point, (void *)args);
    pthread_detach(thread);
}
#endif

FFI_PLUGIN_EXPORT Openim_Listener getIMListener()
{
    Openim_Listener openimListener = {
        .onMethodChannel = onMethodChannelFunc,
    };
    return openimListener;
}
