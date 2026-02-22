// GLFW C スタブ (mizchi/glfw)

#include <moonbit.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

#define GLFW_EXPOSE_NATIVE_COCOA
#if __has_include("/opt/homebrew/include/GLFW/glfw3.h")
#include "/opt/homebrew/include/GLFW/glfw3.h"
#include "/opt/homebrew/include/GLFW/glfw3native.h"
#elif __has_include("/usr/local/include/GLFW/glfw3.h")
#include "/usr/local/include/GLFW/glfw3.h"
#include "/usr/local/include/GLFW/glfw3native.h"
#elif __has_include(<GLFW/glfw3.h>)
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>
#else
#error "GLFW headers not found. install glfw (brew install glfw)."
#endif

// macOS Cocoa フレームワーク
#import <QuartzCore/CAMetalLayer.h>
#import <Cocoa/Cocoa.h>

// MoonBit の WindowSize 構造体（生成されたコードに合わせる）
struct $WindowSize {
  int32_t $0;  // width
  int32_t $1;  // height
};

// ウィンドウサイズを取得して構造体で返す（クラッシュするため未使用）
struct $WindowSize moonbit_glfw_get_window_size_struct(GLFWwindow* window) {
  int width, height;
  glfwGetWindowSize(window, &width, &height);
  struct $WindowSize result;
  result.$0 = width;
  result.$1 = height;
  return result;
}

// ウィンドウサイズを個別に取得（分割版）
int32_t moonbit_glfw_get_window_width(GLFWwindow* window) {
  int width, height;
  glfwGetWindowSize(window, &width, &height);
  return width;
}

int32_t moonbit_glfw_get_window_height(GLFWwindow* window) {
  int width, height;
  glfwGetWindowSize(window, &width, &height);
  return height;
}

// フレームバッファサイズを個別に取得（物理ピクセル、Retina対応）
int32_t moonbit_glfw_get_framebuffer_width(GLFWwindow* window) {
  int width, height;
  glfwGetFramebufferSize(window, &width, &height);
  return width;
}

int32_t moonbit_glfw_get_framebuffer_height(GLFWwindow* window) {
  int width, height;
  glfwGetFramebufferSize(window, &width, &height);
  return height;
}

static int g_windowed_x = 100;
static int g_windowed_y = 100;
static int g_windowed_width = 800;
static int g_windowed_height = 600;
static GLFWwindow* g_input_window = NULL;
static double g_scroll_x = 0.0;
static double g_scroll_y = 0.0;
#define MOONBIT_MAX_TOUCHES 16
typedef struct {
  int32_t id;
  double x;
  double y;
  int32_t touch_type; // 0=Direct, 1=Indirect, 3=Unknown
} moonbit_touch_state;
static moonbit_touch_state g_touches[MOONBIT_MAX_TOUCHES];
static int32_t g_touch_count = 0;

static void moonbit_glfw_scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
  if (window == NULL || window != g_input_window) {
    return;
  }
  g_scroll_x += xoffset;
  g_scroll_y += yoffset;
}

static int32_t moonbit_touch_id_from_identity(id identity) {
  if (identity == nil) {
    return -1;
  }
  const NSUInteger hash_value = [identity hash];
  return (int32_t)(hash_value & 0x7fffffffU);
}

static void moonbit_reset_touches(void) {
  g_touch_count = 0;
  for (int i = 0; i < MOONBIT_MAX_TOUCHES; i++) {
    g_touches[i].id = -1;
    g_touches[i].x = 0.0;
    g_touches[i].y = 0.0;
    g_touches[i].touch_type = 3; // Unknown
  }
}

static void moonbit_update_touches(GLFWwindow* window) {
  moonbit_reset_touches();
  if (window == NULL || window != g_input_window) {
    return;
  }
  NSWindow* nswindow = glfwGetCocoaWindow(window);
  if (nswindow == nil) {
    return;
  }
  NSView* contentView = [nswindow contentView];
  if (contentView == nil) {
    return;
  }
  NSEvent* event = [NSApp currentEvent];
  if (event == nil) {
    return;
  }

  NSSet* touches = nil;
  @try {
    touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:contentView];
  } @catch (NSException* exception) {
    (void)exception;
    return;
  }
  if (touches == nil || [touches count] == 0) {
    return;
  }

  NSRect bounds = [contentView bounds];
  const double width = bounds.size.width > 0.0 ? bounds.size.width : 1.0;
  const double height = bounds.size.height > 0.0 ? bounds.size.height : 1.0;

  int32_t index = 0;
  for (NSTouch* touch in touches) {
    if (index >= MOONBIT_MAX_TOUCHES) {
      break;
    }
    const NSPoint normalized = [touch normalizedPosition];
    double x = normalized.x * width;
    double y = (1.0 - normalized.y) * height;
    if (x < 0.0) {
      x = 0.0;
    }
    if (y < 0.0) {
      y = 0.0;
    }
    g_touches[index].id = moonbit_touch_id_from_identity([touch identity]);
    if (g_touches[index].id < 0) {
      g_touches[index].id = index;
    }
    g_touches[index].x = x;
    g_touches[index].y = y;
    // Determine touch type: Direct(0), Indirect(1), Unknown(3)
    if ([touch respondsToSelector:@selector(type)]) {
      NSInteger touchType = [touch type];
      if (touchType == NSTouchTypeDirect) {
        g_touches[index].touch_type = 0; // Direct
      } else if (touchType == NSTouchTypeIndirect) {
        g_touches[index].touch_type = 1; // Indirect
      } else {
        g_touches[index].touch_type = 3; // Unknown
      }
    } else {
      g_touches[index].touch_type = 3; // Unknown
    }
    index++;
  }
  g_touch_count = index;
}

int32_t moonbit_glfw_is_fullscreen(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  return glfwGetWindowMonitor(window) != NULL ? 1 : 0;
}

int32_t moonbit_glfw_set_fullscreen(GLFWwindow* window, int32_t enabled) {
  if (window == NULL) {
    return 0;
  }

  const int is_fullscreen = moonbit_glfw_is_fullscreen(window);
  if (enabled != 0) {
    if (is_fullscreen) {
      return 1;
    }
    GLFWmonitor* monitor = glfwGetPrimaryMonitor();
    if (monitor == NULL) {
      return 0;
    }
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);
    if (mode == NULL) {
      return 0;
    }
    glfwGetWindowPos(window, &g_windowed_x, &g_windowed_y);
    glfwGetWindowSize(window, &g_windowed_width, &g_windowed_height);
    glfwSetWindowMonitor(
      window,
      monitor,
      0,
      0,
      mode->width,
      mode->height,
      mode->refreshRate
    );
    return moonbit_glfw_is_fullscreen(window);
  }

  if (!is_fullscreen) {
    return 0;
  }
  const int restore_width = g_windowed_width <= 0 ? 800 : g_windowed_width;
  const int restore_height = g_windowed_height <= 0 ? 600 : g_windowed_height;
  glfwSetWindowMonitor(
    window,
    NULL,
    g_windowed_x,
    g_windowed_y,
    restore_width,
    restore_height,
    0
  );
  return moonbit_glfw_is_fullscreen(window);
}

static int32_t moonbit_cursor_mode_from_glfw(int glfw_mode) {
  switch (glfw_mode) {
    case GLFW_CURSOR_HIDDEN:
      return 1;
    case GLFW_CURSOR_DISABLED:
      return 2;
    case GLFW_CURSOR_NORMAL:
    default:
      return 0;
  }
}

static int moonbit_cursor_mode_to_glfw(int32_t cursor_mode) {
  switch (cursor_mode) {
    case 1:
      return GLFW_CURSOR_HIDDEN;
    case 2:
      return GLFW_CURSOR_DISABLED;
    case 0:
    default:
      return GLFW_CURSOR_NORMAL;
  }
}

int32_t moonbit_glfw_set_cursor_mode(GLFWwindow* window, int32_t cursor_mode) {
  if (window == NULL) {
    return 0;
  }
  glfwSetInputMode(window, GLFW_CURSOR, moonbit_cursor_mode_to_glfw(cursor_mode));
  const int current = glfwGetInputMode(window, GLFW_CURSOR);
  return moonbit_cursor_mode_from_glfw(current);
}

int32_t moonbit_glfw_get_cursor_mode(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  const int current = glfwGetInputMode(window, GLFW_CURSOR);
  return moonbit_cursor_mode_from_glfw(current);
}

double moonbit_glfw_get_cursor_x(GLFWwindow* window) {
  if (window == NULL) {
    return 0.0;
  }
  double cursor_x = 0.0;
  double cursor_y = 0.0;
  glfwGetCursorPos(window, &cursor_x, &cursor_y);
  return cursor_x;
}

double moonbit_glfw_get_cursor_y(GLFWwindow* window) {
  if (window == NULL) {
    return 0.0;
  }
  double cursor_x = 0.0;
  double cursor_y = 0.0;
  glfwGetCursorPos(window, &cursor_x, &cursor_y);
  return cursor_y;
}

double moonbit_glfw_take_scroll_x(GLFWwindow* window) {
  if (window == NULL || window != g_input_window) {
    return 0.0;
  }
  const double current = g_scroll_x;
  g_scroll_x = 0.0;
  return current;
}

double moonbit_glfw_take_scroll_y(GLFWwindow* window) {
  if (window == NULL || window != g_input_window) {
    return 0.0;
  }
  const double current = g_scroll_y;
  g_scroll_y = 0.0;
  return current;
}

int32_t moonbit_glfw_pressed_key_count(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  int32_t count = 0;
  for (int key = GLFW_KEY_SPACE; key <= GLFW_KEY_LAST; key++) {
    const int state = glfwGetKey(window, key);
    if (state == GLFW_PRESS || state == GLFW_REPEAT) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_pressed_key_at(GLFWwindow* window, int32_t index) {
  if (window == NULL || index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int key = GLFW_KEY_SPACE; key <= GLFW_KEY_LAST; key++) {
    const int state = glfwGetKey(window, key);
    if (state == GLFW_PRESS || state == GLFW_REPEAT) {
      if (current_index == index) {
        return key;
      }
      current_index++;
    }
  }
  return -1;
}

int32_t moonbit_glfw_pressed_mouse_button_count(GLFWwindow* window) {
  if (window == NULL) {
    return 0;
  }
  int32_t count = 0;
  for (int button = GLFW_MOUSE_BUTTON_1; button <= GLFW_MOUSE_BUTTON_LAST; button++) {
    const int state = glfwGetMouseButton(window, button);
    if (state == GLFW_PRESS) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_pressed_mouse_button_at(GLFWwindow* window, int32_t index) {
  if (window == NULL || index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int button = GLFW_MOUSE_BUTTON_1; button <= GLFW_MOUSE_BUTTON_LAST; button++) {
    const int state = glfwGetMouseButton(window, button);
    if (state == GLFW_PRESS) {
      if (current_index == index) {
        return button;
      }
      current_index++;
    }
  }
  return -1;
}

int32_t moonbit_glfw_touch_count(GLFWwindow* window) {
  moonbit_update_touches(window);
  return g_touch_count;
}

int32_t moonbit_glfw_touch_id_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return -1;
  }
  return g_touches[index].id;
}

double moonbit_glfw_touch_x_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 0.0;
  }
  return g_touches[index].x;
}

double moonbit_glfw_touch_y_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 0.0;
  }
  return g_touches[index].y;
}

int32_t moonbit_glfw_touch_type_at(GLFWwindow* window, int32_t index) {
  moonbit_update_touches(window);
  if (index < 0 || index >= g_touch_count) {
    return 3; // Unknown
  }
  return g_touches[index].touch_type;
}

#if defined(GLFW_GAMEPAD_AXIS_LAST) && defined(GLFW_GAMEPAD_BUTTON_LAST)
static int32_t moonbit_glfw_gamepad_jid_at(int32_t index) {
  if (index < 0) {
    return -1;
  }
  int32_t current_index = 0;
  for (int jid = GLFW_JOYSTICK_1; jid <= GLFW_JOYSTICK_LAST; jid++) {
    if (glfwJoystickPresent(jid) != GLFW_TRUE) {
      continue;
    }
    if (glfwJoystickIsGamepad(jid) != GLFW_TRUE) {
      continue;
    }
    if (current_index == index) {
      return (int32_t)jid;
    }
    current_index++;
  }
  return -1;
}

int32_t moonbit_glfw_gamepad_count(void) {
  int32_t count = 0;
  for (int jid = GLFW_JOYSTICK_1; jid <= GLFW_JOYSTICK_LAST; jid++) {
    if (glfwJoystickPresent(jid) == GLFW_TRUE && glfwJoystickIsGamepad(jid) == GLFW_TRUE) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_gamepad_id_at(int32_t index) {
  return moonbit_glfw_gamepad_jid_at(index);
}

int32_t moonbit_glfw_gamepad_axis_count(int32_t index) {
  const int32_t jid = moonbit_glfw_gamepad_jid_at(index);
  if (jid < 0) {
    return 0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0;
  }
  return (int32_t)(GLFW_GAMEPAD_AXIS_LAST + 1);
}

double moonbit_glfw_gamepad_axis_at(int32_t gamepad_index, int32_t axis_index) {
  if (axis_index < 0 || axis_index > GLFW_GAMEPAD_AXIS_LAST) {
    return 0.0;
  }
  const int32_t jid = moonbit_glfw_gamepad_jid_at(gamepad_index);
  if (jid < 0) {
    return 0.0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0.0;
  }
  return (double)state.axes[axis_index];
}

int32_t moonbit_glfw_gamepad_pressed_button_count(int32_t index) {
  const int32_t jid = moonbit_glfw_gamepad_jid_at(index);
  if (jid < 0) {
    return 0;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return 0;
  }
  int32_t count = 0;
  for (int button = 0; button <= GLFW_GAMEPAD_BUTTON_LAST; button++) {
    if (state.buttons[button] == GLFW_PRESS) {
      count++;
    }
  }
  return count;
}

int32_t moonbit_glfw_gamepad_pressed_button_at(int32_t gamepad_index, int32_t button_index) {
  if (button_index < 0) {
    return -1;
  }
  const int32_t jid = moonbit_glfw_gamepad_jid_at(gamepad_index);
  if (jid < 0) {
    return -1;
  }
  GLFWgamepadstate state;
  if (glfwGetGamepadState((int)jid, &state) != GLFW_TRUE) {
    return -1;
  }
  int32_t current_index = 0;
  for (int button = 0; button <= GLFW_GAMEPAD_BUTTON_LAST; button++) {
    if (state.buttons[button] == GLFW_PRESS) {
      if (current_index == button_index) {
        return (int32_t)button;
      }
      current_index++;
    }
  }
  return -1;
}
#else
int32_t moonbit_glfw_gamepad_count(void) {
  return 0;
}

int32_t moonbit_glfw_gamepad_id_at(int32_t index) {
  (void)index;
  return -1;
}

int32_t moonbit_glfw_gamepad_axis_count(int32_t index) {
  (void)index;
  return 0;
}

double moonbit_glfw_gamepad_axis_at(int32_t gamepad_index, int32_t axis_index) {
  (void)gamepad_index;
  (void)axis_index;
  return 0.0;
}

int32_t moonbit_glfw_gamepad_pressed_button_count(int32_t index) {
  (void)index;
  return 0;
}

int32_t moonbit_glfw_gamepad_pressed_button_at(int32_t gamepad_index, int32_t button_index) {
  (void)gamepad_index;
  (void)button_index;
  return -1;
}
#endif

double moonbit_glfw_get_window_content_scale(GLFWwindow* window) {
  if (window == NULL) {
    return 1.0;
  }
  float xscale = 1.0f;
  float yscale = 1.0f;
  glfwGetWindowContentScale(window, &xscale, &yscale);
  if (xscale <= 0.0f) {
    return 1.0;
  }
  return (double)xscale;
}

void moonbit_glfw_request_window_attention_safe(GLFWwindow* window) {
  if (window == NULL) {
    return;
  }
#if defined(GLFW_VERSION_MAJOR) && (GLFW_VERSION_MAJOR > 3 || (GLFW_VERSION_MAJOR == 3 && GLFW_VERSION_MINOR >= 3))
  glfwRequestWindowAttention(window);
#endif
}

// MoonBit String から安全にウィンドウを作成
// MoonBit の String は UTF-16 エンコード (uint16_t*)
GLFWwindow* moonbit_glfw_create_window_safe(int32_t width, int32_t height, uint16_t* title_utf16) {
  // UTF-16 から UTF-8 に変換（簡易版：ASCII範囲のみ対応）
  char title_utf8[256] = {0};
  if (title_utf16) {
    int i = 0;
    while (i < 255 && title_utf16[i] != 0) {
      // ASCII範囲のみ変換（0x00-0x7F）
      if (title_utf16[i] < 0x80) {
        title_utf8[i] = (char)title_utf16[i];
      } else {
        title_utf8[i] = '?';  // 非ASCII文字は'?'に
      }
      i++;
    }
    title_utf8[i] = '\0';
  } else {
    strcpy(title_utf8, "Window");
  }

  // ウィンドウヒント設定（WebGPU 用）
  glfwWindowHint(0x00022001, 0);  // GLFW_CLIENT_API = GLFW_NO_API
  glfwWindowHint(0x00020003, 1);  // GLFW_RESIZABLE = GLFW_TRUE

  // ウィンドウ作成
  GLFWwindow* window = glfwCreateWindow(width, height, title_utf8, NULL, NULL);
  g_input_window = window;
  g_scroll_x = 0.0;
  g_scroll_y = 0.0;
  if (window != NULL) {
    glfwSetScrollCallback(window, moonbit_glfw_scroll_callback);
    NSWindow* nswindow = glfwGetCocoaWindow(window);
    if (nswindow != nil) {
      NSView* contentView = [nswindow contentView];
      if (contentView != nil) {
        if ([contentView respondsToSelector:@selector(setAllowedTouchTypes:)]) {
          [contentView setAllowedTouchTypes:(NSTouchTypeMaskDirect | NSTouchTypeMaskIndirect)];
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([contentView respondsToSelector:@selector(setAcceptsTouchEvents:)]) {
          [contentView setAcceptsTouchEvents:YES];
        }
#pragma clang diagnostic pop
        if ([contentView respondsToSelector:@selector(setWantsRestingTouches:)]) {
          [contentView setWantsRestingTouches:YES];
        }
      }
    }
  }
  moonbit_reset_touches();

  return window;
}
