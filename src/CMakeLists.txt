# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_openim_ffi_library VERSION 0.0.1 LANGUAGES C)


add_library(flutter_openim_ffi SHARED
  "flutter_openim_ffi.c"
  "flutter_openim_ffi.h"
  "openim_ffi.c"
  "openim_ffi.h"
)

set_target_properties(flutter_openim_ffi PROPERTIES
  PUBLIC_HEADER flutter_openim_ffi.h
  OUTPUT_NAME "flutter_openim_ffi"
)

target_compile_definitions(flutter_openim_ffi PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(flutter_openim_ffi PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_link_libraries(flutter_openim_ffi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../linux/libopenim_sdk_ffi.so)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
  file(GLOB ANDROID_SO_FILES ${CMAKE_CURRENT_SOURCE_DIR}/../android/libs/${CMAKE_ANDROID_ARCH_ABI}/*.so)
  target_link_libraries(flutter_openim_ffi PUBLIC ${ANDROID_SO_FILES})
# elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
#   target_link_libraries(flutter_openim_ffi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../windows/libopenim_sdk_ffi.dll)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin") # macOS
  target_link_libraries(flutter_openim_ffi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../macos/libopenim_sdk_ffi.dylib)
elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
 target_link_libraries(flutter_openim_ffi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../ios/openim_sdk_ffi.framework/openim_sdk_ffi)
endif()

# target_link_libraries(flutter_openim_ffi PUBLIC)
