#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Automatically registers the desktop entry and icons for portable / zip extracted runs.
static void auto_register_desktop_entry_if_needed() {
  const gchar* home = g_get_home_dir();
  if (home == nullptr) return;

  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path == nullptr) return;

  // Don't auto-register development debug builds inside build directory
  if (g_strrstr(exe_path, "intermediates_do_not_run") != nullptr) {
    return;
  }

  g_autofree gchar* apps_dir = g_build_filename(home, ".local", "share", "applications", nullptr);
  g_autofree gchar* desktop_path = g_build_filename(apps_dir, "phoenix.screen.recorder.desktop", nullptr);

  gboolean need_install = FALSE;
  if (!g_file_test(desktop_path, G_FILE_TEST_EXISTS)) {
    need_install = TRUE;
  } else {
    g_autoptr(GKeyFile) key_file = g_key_file_new();
    if (g_key_file_load_from_file(key_file, desktop_path, G_KEY_FILE_NONE, nullptr)) {
      g_autofree gchar* existing_exec = g_key_file_get_string(key_file, "Desktop Entry", "Exec", nullptr);
      if (existing_exec == nullptr || !g_str_has_prefix(existing_exec, exe_path)) {
        need_install = TRUE;
      }
    }
  }

  if (need_install) {
    g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);
    g_autofree gchar* icons_user_base = g_build_filename(home, ".local", "share", "icons", "hicolor", nullptr);

    const int sizes[] = {16, 24, 32, 48, 64, 128, 256, 512};
    for (size_t i = 0; i < G_N_ELEMENTS(sizes); ++i) {
      g_autofree gchar* size_str = g_strdup_printf("%dx%d", sizes[i], sizes[i]);
      g_autofree gchar* dest_dir = g_build_filename(icons_user_base, size_str, "apps", nullptr);
      g_mkdir_with_parents(dest_dir, 0755);

      g_autofree gchar* filename = g_strdup_printf("icon_%dx%d.png", sizes[i], sizes[i]);
      g_autofree gchar* src_icon = g_build_filename(exe_dir, "data", "icons", filename, nullptr);

      if (!g_file_test(src_icon, G_FILE_TEST_EXISTS)) {
        g_autofree gchar* fallback = g_build_filename(exe_dir, "../../../../linux/icons", filename, nullptr);
        if (g_file_test(fallback, G_FILE_TEST_EXISTS)) {
          src_icon = g_steal_pointer(&fallback);
        }
      }

      if (src_icon != nullptr && g_file_test(src_icon, G_FILE_TEST_EXISTS)) {
        g_autofree gchar* dest_file = g_build_filename(dest_dir, "phoenix.screen.recorder.png", nullptr);
        g_autoptr(GFile) src_f = g_file_new_for_path(src_icon);
        g_autoptr(GFile) dest_f = g_file_new_for_path(dest_file);
        g_file_copy(src_f, dest_f, G_FILE_COPY_OVERWRITE, nullptr, nullptr, nullptr, nullptr);
      }
    }

    // Main / 512x512 fallback icon
    g_autofree gchar* main_icon = g_build_filename(exe_dir, "data", "icons", "icon.png", nullptr);
    if (!g_file_test(main_icon, G_FILE_TEST_EXISTS)) {
      g_free(main_icon);
      main_icon = g_build_filename(exe_dir, "data", "flutter_assets", "assets", "icon", "icon.png", nullptr);
    }
    if (main_icon != nullptr && g_file_test(main_icon, G_FILE_TEST_EXISTS)) {
      g_autofree gchar* dest_512 = g_build_filename(icons_user_base, "512x512", "apps", nullptr);
      g_mkdir_with_parents(dest_512, 0755);
      g_autofree gchar* dest_file = g_build_filename(dest_512, "phoenix.screen.recorder.png", nullptr);
      g_autoptr(GFile) src_f = g_file_new_for_path(main_icon);
      g_autoptr(GFile) dest_f = g_file_new_for_path(dest_file);
      g_file_copy(src_f, dest_f, G_FILE_COPY_OVERWRITE, nullptr, nullptr, nullptr, nullptr);
    }

    // Write .desktop entry
    g_mkdir_with_parents(apps_dir, 0755);
    g_autofree gchar* desktop_content = g_strdup_printf(
      "[Desktop Entry]\n"
      "Version=1.0\n"
      "Type=Application\n"
      "Name=Phoenix Screen Recorder\n"
      "GenericName=Screen Recorder\n"
      "Comment=Record your screen and audio effortlessly\n"
      "Exec=\"%s\" %%U\n"
      "Icon=phoenix.screen.recorder\n"
      "Terminal=false\n"
      "StartupNotify=true\n"
      "StartupWMClass=phoenix.screen.recorder\n"
      "Categories=AudioVideo;Recorder;Utility;\n"
      "Keywords=screen;recorder;capture;video;audio;phoenix;\n",
      exe_path
    );

    g_file_set_contents(desktop_path, desktop_content, -1, nullptr);
  }
}

// Sets up the window and application icons using multi-resolution icons or fallback files.
static void setup_window_icon(GtkWindow* window) {
  // Associate with the application ID so standard desktop themes and compositors
  // can match the window icon automatically.
  gtk_window_set_default_icon_name(APPLICATION_ID);
  if (window != nullptr) {
    gtk_window_set_icon_name(window, APPLICATION_ID);
  }

  // Resolve directory where the binary lives to handle relative assets reliably.
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  g_autofree gchar* exe_dir = exe_path != nullptr ? g_path_get_dirname(exe_path) : nullptr;

  const int icon_sizes[] = {16, 24, 32, 48, 64, 128, 256, 512};
  GList* icon_list = nullptr;

  const gchar* icon_dir_relatives[] = {
    "data/icons",
    "../bundle/data/icons",
    "../../../../linux/icons",
    "linux/icons",
  };

  for (size_t d = 0; d < G_N_ELEMENTS(icon_dir_relatives); ++d) {
    g_autofree gchar* test_dir = nullptr;
    if (exe_dir != nullptr && g_str_has_prefix(icon_dir_relatives[d], "..")) {
      test_dir = g_build_filename(exe_dir, icon_dir_relatives[d], nullptr);
    } else if (exe_dir != nullptr && g_file_test(g_build_filename(exe_dir, icon_dir_relatives[d], nullptr), G_FILE_TEST_IS_DIR)) {
      test_dir = g_build_filename(exe_dir, icon_dir_relatives[d], nullptr);
    } else if (g_file_test(icon_dir_relatives[d], G_FILE_TEST_IS_DIR)) {
      test_dir = g_strdup(icon_dir_relatives[d]);
    }

    if (test_dir != nullptr && g_file_test(test_dir, G_FILE_TEST_IS_DIR)) {
      for (size_t s = 0; s < G_N_ELEMENTS(icon_sizes); ++s) {
        g_autofree gchar* filename = g_strdup_printf("icon_%dx%d.png", icon_sizes[s], icon_sizes[s]);
        g_autofree gchar* icon_file = g_build_filename(test_dir, filename, nullptr);
        if (g_file_test(icon_file, G_FILE_TEST_EXISTS)) {
          GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(icon_file, nullptr);
          if (pixbuf != nullptr) {
            icon_list = g_list_append(icon_list, pixbuf);
          }
        }
      }
      if (icon_list != nullptr) {
        break;
      }
    }
  }

  if (icon_list != nullptr) {
    if (window != nullptr) {
      gtk_window_set_icon_list(window, icon_list);
    }
    gtk_window_set_default_icon_list(icon_list);
    g_list_free_full(icon_list, g_object_unref);
    return;
  }

  // Fallback: search candidate paths for single icon file
  const gchar* single_icon_candidates[] = {
    "data/flutter_assets/assets/icon/icon.png",
    "data/icons/icon.png",
    "../bundle/data/flutter_assets/assets/icon/icon.png",
    "../../../../assets/icon/icon.png",
    "../../../../linux/icons/icon.png",
    "assets/icon/icon.png",
    "linux/icons/icon.png",
  };

  for (size_t i = 0; i < G_N_ELEMENTS(single_icon_candidates); ++i) {
    g_autofree gchar* candidate_path = nullptr;
    if (exe_dir != nullptr && (g_str_has_prefix(single_icon_candidates[i], "..") ||
                               g_str_has_prefix(single_icon_candidates[i], "data/"))) {
      candidate_path = g_build_filename(exe_dir, single_icon_candidates[i], nullptr);
    } else {
      candidate_path = g_strdup(single_icon_candidates[i]);
    }

    if (candidate_path != nullptr && g_file_test(candidate_path, G_FILE_TEST_EXISTS)) {
      if (window != nullptr && gtk_window_set_icon_from_file(window, candidate_path, nullptr)) {
        gtk_window_set_default_icon_from_file(candidate_path, nullptr);
        break;
      }
    }
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Phoenix Screen Recorder");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Phoenix Screen Recorder");
  }

  setup_window_icon(window);

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.
  gtk_window_set_default_icon_name(APPLICATION_ID);

  // Auto-register desktop entry and icons for zip extract / portable runs.
  auto_register_desktop_entry_if_needed();

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
