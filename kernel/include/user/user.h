#pragma once

#include <fatfs/ff.h>

#include <user/framebuffer.h>

#include <stdint.h>

#define MODE_READ   0x01
#define MODE_WRITE  0x02
#define MODE_CREATE 0x04

typedef enum event_type_e {
    KEY_DOWN,
    KEY_UP
} event_type_t;

typedef enum file_type_e {
    T_FILE   = 0,
    T_STREAM = 1
} file_type_t;

typedef enum file_system_e {
    S_UNKNOWN = 0,
    S_FAT     = 1
} file_system_t;

typedef struct event_s {
    event_type_t type;
    uint32_t arg0;
    uint32_t arg1;
    uint32_t arg2;
    uint32_t arg3;
    uint32_t arg4;
    uint32_t arg5;
    uint32_t arg6;
    uint32_t arg7;
} event_t;

typedef struct file_s {
    file_type_t type;
    file_system_t filesystem;
    FIL fatfs;
    void *stream_read_callback;
    void *stream_write_callback;
} file_t;

font_t *global_font = (void *) 0xFF000000;

uint32_t exit();
uint32_t yield();
uint32_t open(file_t *file, char *path, uint32_t mode);
uint32_t read(file_t *file, char *buffer, uint32_t bytes_to_read);
uint32_t write(file_t *file, char *buffer, uint32_t bytes_to_write);
uint32_t new_event(event_t *event);
uint32_t get_next_event(event_t *event);
