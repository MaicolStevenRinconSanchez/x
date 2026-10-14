"""
Instala y activa el plugin "Meshy for Blender" desde la carpeta Descargas.

Uso:
    1. En Blender, abre la pestaña Scripting (arriba).
    2. En el editor de texto pulsa "New", pega este archivo y pulsa el botón ▶ (Run Script).
    3. Sale un aviso diciendo si funcionó. Después: vista 3D -> tecla N -> pestaña Meshy -> Run Bridge.

Busca la carpeta "meshy-blender-plugin" (la que tiene __init__.py) dentro de Descargas,
la copia a la carpeta de add-ons de tu usuario y la activa.
"""

import glob
import importlib
import os
import shutil
import sys

import addon_utils
import bpy

NOMBRE = "meshy-blender-plugin"
DESCARGAS = os.path.join(os.path.expanduser("~"), "Downloads")


def avisar(titulo, texto, icono="INFO"):
    print(titulo + ": " + texto)
    if bpy.app.background:
        return

    def dibujar(menu, _context):
        for linea in texto.split("\n"):
            menu.layout.label(text=linea)

    bpy.context.window_manager.popup_menu(dibujar, title=titulo, icon=icono)


def buscar_plugin():
    patron = os.path.join(DESCARGAS, "**", NOMBRE, "__init__.py")
    encontrados = glob.glob(patron, recursive=True)
    if not encontrados:
        return None
    # Si hay varias copias, la más reciente
    encontrados.sort(key=os.path.getmtime, reverse=True)
    return os.path.dirname(encontrados[0])


def instalar():
    origen = buscar_plugin()
    if origen is None:
        avisar(
            "No encontré el plugin",
            "No hay ninguna carpeta '" + NOMBRE + "' con __init__.py dentro de:\n" + DESCARGAS,
            "ERROR",
        )
        return

    carpeta_addons = bpy.utils.user_resource('SCRIPTS', path="addons", create=True)
    destino = os.path.join(carpeta_addons, NOMBRE)
    shutil.copytree(
        origen,
        destino,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns("__pycache__"),
    )

    # Si la carpeta de add-ons no existía al abrir Blender, Python todavía no la conoce
    if carpeta_addons not in sys.path:
        sys.path.append(carpeta_addons)
    importlib.invalidate_caches()
    bpy.ops.preferences.addon_refresh()

    errores = []
    modulo = addon_utils.enable(NOMBRE, default_set=True, handle_error=lambda ex: errores.append(repr(ex)))
    if modulo is None:
        avisar(
            "Se copió, pero no se pudo activar",
            "Copiado en: " + destino + "\nError: " + (errores[0] if errores else "desconocido"),
            "ERROR",
        )
        return

    bpy.ops.wm.save_userpref()
    avisar(
        "Meshy instalado",
        "Copiado en: " + destino + "\nAhora: vista 3D -> tecla N -> pestaña Meshy -> Run Bridge",
    )


instalar()
