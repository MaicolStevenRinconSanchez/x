"""
Genera los brazos FPS estilo Roblox (bloque de piel + guante táctico negro sin dedos).

Uso dentro de Blender:
    Pestaña Scripting -> Abrir este archivo -> Run Script.
    Crea los 4 objetos en la escena (BrazoDerecho, GuanteDerecho, BrazoIzquierdo, GuanteIzquierdo).

Uso desde la terminal (guarda .blend + .fbx y, con --render, las vistas previas):
    blender -b -P generar_brazos.py -- --salida . --render
    o, con el módulo de Python (pip install bpy):
    python generar_brazos.py -- --salida . --render

Unidades: 1 unidad de Blender = 1 stud de Roblox.
Cada brazo mide 1 x 1 x 2 (igual que el brazo R6), con la mano hacia abajo (-Z)
y la ventana del guante en la cara +Y, que en Roblox queda como la cara frontal (-Z).
"""

import math
import os
import sys

import bpy  # antes que bmesh: fuera de Blender (pip install bpy) bmesh solo existe tras importar bpy
import bmesh
from mathutils import Matrix, Vector

# --------------------------------------------------------------------------
# Parámetros (todo en studs)
# --------------------------------------------------------------------------

ANCHO_BRAZO = 1.0
LARGO_BRAZO = 2.0
SEPARACION = 1.5  # distancia en X desde el centro, como en un torso R6

COLOR_PIEL = (245, 205, 182)
COLOR_GUANTE = (27, 27, 30)

FONDO = -LARGO_BRAZO / 2  # punta de la mano

# Tramos del guante, medidos desde el centro del brazo
MANO_Z = (-0.74, -0.20)
REBORDE_Z = (-0.765, -0.685)
PUNO_Z = (-0.27, 0.02)
VENTANA_Z = -0.47

MEDIO_MANO = 0.54
MEDIO_REBORDE = 0.56
MEDIO_PUNO = 0.575
MEDIO_ANILLO = 0.59


# --------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------

def srgb_a_lineal(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def material(nombre, rgb, rugosidad):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    color = tuple(srgb_a_lineal(c) for c in rgb) + (1.0,)
    mat.diffuse_color = color
    if mat.node_tree is None:
        mat.use_nodes = True
    bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = rugosidad
    return mat


def caja(nombre, tam, centro, bisel=0.0, segmentos=2, solo_eje=None):
    """Caja con bisel. Si solo_eje es 0/1/2 solo se biselan las aristas paralelas a ese eje."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
    if bisel > 0:
        aristas = bm.edges[:]
        if solo_eje is not None:
            aristas = [
                e for e in aristas
                if abs((e.verts[0].co - e.verts[1].co)[solo_eje]) > 1e-6
            ]
        bmesh.ops.bevel(
            bm, geom=aristas, offset=bisel, segments=segmentos,
            profile=0.5, affect='EDGES', clamp_overlap=True,
        )
    malla = bpy.data.meshes.new(nombre)
    bm.to_mesh(malla)
    bm.free()
    obj = bpy.data.objects.new(nombre, malla)
    obj.location = centro
    bpy.context.scene.collection.objects.link(obj)
    return obj


def ranura_anillo(nombre, medio, z, caras, ancho=0.022, profundidad=0.014):
    """Ranura poco profunda alrededor de una caja de semiancho `medio`, solo en las caras indicadas."""
    largo = 2 * medio + 0.1
    grosor = 2 * profundidad
    cortes = []
    for cara in caras:
        signo = 1 if cara[0] == '+' else -1
        if cara[1] == 'x':
            cortes.append(caja(f"{nombre}{cara}", (grosor, largo, ancho), (signo * medio, 0, z)))
        else:
            cortes.append(caja(f"{nombre}{cara}", (largo, grosor, ancho), (0, signo * medio, z)))
    return cortes


def aplicar_booleanas(base, uniones, cortes):
    solver = 'MANIFOLD' if 'MANIFOLD' in _solvers() else 'EXACT'
    for obj in uniones:
        mod = base.modifiers.new(f"U_{obj.name}", 'BOOLEAN')
        mod.operation, mod.object, mod.solver = 'UNION', obj, solver
    for obj in cortes:
        mod = base.modifiers.new(f"D_{obj.name}", 'BOOLEAN')
        mod.operation, mod.object, mod.solver = 'DIFFERENCE', obj, solver

    deps = bpy.context.evaluated_depsgraph_get()
    nueva = bpy.data.meshes.new_from_object(base.evaluated_get(deps))
    vieja = base.data
    base.modifiers.clear()
    base.data = nueva
    bpy.data.meshes.remove(vieja)
    nueva.name = base.name
    for obj in uniones + cortes:
        malla = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(malla)


def _solvers():
    prop = bpy.types.BooleanModifier.bl_rna.properties['solver']
    return {item.identifier for item in prop.enum_items}


def acabado(obj, mat):
    malla = obj.data
    malla.materials.clear()
    malla.materials.append(mat)
    for p in malla.polygons:
        p.use_smooth = True
    malla.set_sharp_from_angle(angle=math.radians(35))
    proyeccion_uv(malla)


def proyeccion_uv(malla):
    """Proyección cúbica simple: Roblox no exige textura, pero así la malla ya trae UVs."""
    bm = bmesh.new()
    bm.from_mesh(malla)
    capa = bm.loops.layers.uv.verify()
    for cara in bm.faces:
        n = cara.normal
        eje = max(range(3), key=lambda i: abs(n[i]))
        u, v = [i for i in range(3) if i != eje]
        for loop in cara.loops:
            co = loop.vert.co
            loop[capa].uv = (co[u] * 0.5 + 0.5, co[v] * 0.25 + 0.5)
    bm.to_mesh(malla)
    bm.free()


# --------------------------------------------------------------------------
# Modelado
# --------------------------------------------------------------------------

def centro_z(tramo):
    return (tramo[0] + tramo[1]) / 2


def alto(tramo):
    return tramo[1] - tramo[0]


def crear_brazo(nombre, mat):
    obj = caja(nombre, (ANCHO_BRAZO, ANCHO_BRAZO, LARGO_BRAZO), (0, 0, 0), bisel=0.015, segmentos=2)
    acabado(obj, mat)
    return obj


def crear_guante(nombre, mat, lado):
    """lado = 1 para el brazo derecho (hebilla en +X), -1 para el izquierdo."""
    mano = caja(nombre, (2 * MEDIO_MANO, 2 * MEDIO_MANO, alto(MANO_Z)),
                (0, 0, centro_z(MANO_Z)), bisel=0.03, segmentos=3)

    uniones = [
        # Reborde de los nudillos, donde termina el guante y empiezan los dedos
        caja("reborde", (2 * MEDIO_REBORDE, 2 * MEDIO_REBORDE, alto(REBORDE_Z)),
             (0, 0, centro_z(REBORDE_Z)), bisel=0.02, segmentos=2),
        # Puño (muñequera)
        caja("puno", (2 * MEDIO_PUNO, 2 * MEDIO_PUNO, alto(PUNO_Z)),
             (0, 0, centro_z(PUNO_Z)), bisel=0.035, segmentos=3),
        # Anillos en los bordes del puño
        caja("anillo_inf", (2 * MEDIO_ANILLO, 2 * MEDIO_ANILLO, 0.035),
             (0, 0, PUNO_Z[0] + 0.025), bisel=0.012, segmentos=2),
        caja("anillo_sup", (2 * MEDIO_ANILLO, 2 * MEDIO_ANILLO, 0.035),
             (0, 0, PUNO_Z[1] - 0.025), bisel=0.012, segmentos=2),
        # Pestaña de velcro en el lado exterior del puño
        caja("velcro", (0.05, 0.5, 0.17),
             (lado * (MEDIO_PUNO + 0.02), -0.02, centro_z(PUNO_Z)), bisel=0.018, segmentos=2),
        # Marco elevado alrededor de la ventana del dorso (cara +Y)
        caja("marco", (0.80, 0.13, 0.44),
             (0, 0.5, VENTANA_Z), bisel=0.14, segmentos=6, solo_eje=1),
        # Almohadilla de la palma (cara -Y)
        caja("palma", (0.62, 0.13, 0.30),
             (0, -0.5, VENTANA_Z - 0.01), bisel=0.09, segmentos=5, solo_eje=1),
    ]

    interior = "-x" if lado > 0 else "+x"
    cortes = [
        # Ventana del dorso: deja ver la piel
        caja("ventana", (0.62, 0.30, 0.30),
             (0, 0.61, VENTANA_Z), bisel=0.10, segmentos=6, solo_eje=1),
        # Ranuras longitudinales en los costados
        caja("ranura_lado_a", (0.03, 0.022, 0.40), (MEDIO_MANO, 0, -0.47)),
        caja("ranura_lado_b", (0.03, 0.022, 0.40), (-MEDIO_MANO, 0, -0.47)),
    ]
    # Ranura transversal: forma una cruz con las de los costados
    cortes += ranura_anillo("ranura_mano", MEDIO_MANO, -0.47, ("+x", "-x"))
    # Ranura central del puño (sin pasar por debajo del velcro)
    cortes += ranura_anillo("ranura_puno", MEDIO_PUNO, centro_z(PUNO_Z), (interior, "+y", "-y"))
    # Rayas de agarre en la palma
    for i, z in enumerate((-0.56, -0.48, -0.40)):
        cortes.append(caja(f"agarre_{i}", (0.44, 0.04, 0.022), (0, -0.565, z)))

    aplicar_booleanas(mano, uniones, cortes)
    acabado(mano, mat)
    return mano


def limpiar():
    """Desde la terminal parte de una escena vacía; dentro de Blender solo reemplaza la colección Brazos."""
    if bpy.app.background:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        return
    col = bpy.data.collections.get("Brazos")
    if col is None:
        return
    for obj in list(col.objects):
        malla = obj.data
        bpy.data.objects.remove(obj)
        if malla.users == 0:
            bpy.data.meshes.remove(malla)
    bpy.data.collections.remove(col)


def construir():
    limpiar()
    escena = bpy.context.scene
    escena.unit_settings.system = 'METRIC'
    escena.unit_settings.scale_length = 1.0

    piel = material("Piel", COLOR_PIEL, 0.6)
    guante = material("Guante", COLOR_GUANTE, 0.45)

    col = bpy.data.collections.new("Brazos")
    escena.collection.children.link(col)

    objetos = {}
    for lado, sufijo in ((1, "Derecho"), (-1, "Izquierdo")):
        brazo = crear_brazo(f"Brazo{sufijo}", piel)
        mano = crear_guante(f"Guante{sufijo}", guante, lado)
        for obj in (brazo, mano):
            obj.location.x = lado * SEPARACION
            escena.collection.objects.unlink(obj)
            col.objects.link(obj)
        objetos[sufijo] = (brazo, mano)
    return objetos


# --------------------------------------------------------------------------
# Exportación y vistas previas (solo desde la terminal)
# --------------------------------------------------------------------------

def exportar(carpeta):
    os.makedirs(carpeta, exist_ok=True)
    blend = os.path.join(carpeta, "brazos_fps.blend")
    if os.path.exists(blend):
        os.remove(blend)  # evita que Blender deje un brazos_fps.blend1 de respaldo
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(carpeta, "brazos_fps.fbx"),
        use_selection=False,
        object_types={'MESH'},
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y',
        use_mesh_modifiers=True,
        mesh_smooth_type='FACE',
        add_leaf_bones=False,
        bake_anim=False,
    )


def apuntar(obj_brazo, obj_guante, mano, hombro, giro=0.0):
    """Coloca un brazo en pose de primera persona: la mano en `mano`, el codo hacia `hombro`."""
    d = (Vector(mano) - Vector(hombro)).normalized()
    rot = d.to_track_quat('-Z', 'Y').to_matrix().to_4x4() @ Matrix.Rotation(giro, 4, 'Z')
    centro = Vector(mano) - d * (LARGO_BRAZO / 2)
    for obj in (obj_brazo, obj_guante):
        obj.matrix_world = Matrix.Translation(centro) @ rot


def preparar_render(escena):
    escena.render.engine = 'CYCLES'
    escena.cycles.device = 'CPU'
    escena.cycles.samples = 96
    escena.cycles.use_denoising = True
    escena.render.resolution_x = 1280
    escena.render.resolution_y = 720
    escena.view_settings.view_transform = 'AgX'

    mundo = bpy.data.worlds.new("Mundo")
    mundo.color = (0.10, 0.08, 0.16)
    if mundo.node_tree is None:
        mundo.use_nodes = True
    fondo = mundo.node_tree.nodes.get("Background")
    if fondo is not None:
        fondo.inputs["Color"].default_value = (0.10, 0.08, 0.16, 1.0)
        fondo.inputs["Strength"].default_value = 1.0
    escena.world = mundo

    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", 'SUN'))
    sol.data.energy = 3.5
    sol.data.angle = math.radians(8)
    sol.rotation_euler = (math.radians(40), math.radians(-25), math.radians(30))
    escena.collection.objects.link(sol)

    relleno = bpy.data.objects.new("Relleno", bpy.data.lights.new("Relleno", 'AREA'))
    relleno.data.energy = 250
    relleno.data.size = 4
    relleno.data.color = (0.75, 0.8, 1.0)
    escena.collection.objects.link(relleno)
    return relleno


def camara(escena, pos, mira, lente):
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.lens = lente
    cam.location = pos
    cam.rotation_euler = (Vector(mira) - Vector(pos)).to_track_quat('-Z', 'Y').to_euler()
    escena.collection.objects.link(cam)
    escena.camera = cam
    return cam


def renderizar(carpeta, objetos):
    escena = bpy.context.scene
    relleno = preparar_render(escena)
    os.makedirs(carpeta, exist_ok=True)

    # 1) Vista de primera persona, parecida a la captura del juego
    der, izq = objetos["Derecho"], objetos["Izquierdo"]
    apuntar(*der, mano=(0.45, 2.7, -0.75), hombro=(1.7, 0.7, -1.35), giro=math.radians(25))
    apuntar(*izq, mano=(-0.85, 2.6, -1.0), hombro=(-1.9, 0.6, -1.6), giro=math.radians(-35))
    relleno.location = (-2, 1, 2)
    relleno.rotation_euler = (Vector((0, 2.5, -0.8)) - relleno.location).to_track_quat('-Z', 'Y').to_euler()
    cam = camara(escena, (0, 0, 0), (0, 1, -0.22), 18)
    escena.render.filepath = os.path.join(carpeta, "vista_fps.png")
    bpy.ops.render.render(write_still=True)

    # 2) Vista de detalle de los dos brazos colgando (pose de exportación)
    for lado, sufijo in ((1, "Derecho"), (-1, "Izquierdo")):
        for obj in objetos[sufijo]:
            obj.matrix_world = Matrix.Translation((lado * SEPARACION, 0, 0))
    bpy.data.objects.remove(cam)
    relleno.location = (3, 4, 1)
    relleno.rotation_euler = (Vector((0, 0, -0.5)) - relleno.location).to_track_quat('-Z', 'Y').to_euler()
    camara(escena, (3.6, 6.4, -0.9), (0, 0, -0.25), 42)
    escena.render.filepath = os.path.join(carpeta, "vista_detalle.png")
    bpy.ops.render.render(write_still=True)

    # 3) Vista de la palma y la hebilla
    bpy.data.objects.remove(escena.camera)
    relleno.location = (3, -4, 0)
    relleno.rotation_euler = (Vector((0, 0, -0.5)) - relleno.location).to_track_quat('-Z', 'Y').to_euler()
    camara(escena, (3.6, -6.4, -0.9), (0, 0, -0.25), 42)
    escena.render.filepath = os.path.join(carpeta, "vista_palma.png")
    bpy.ops.render.render(write_still=True)


def main():
    argumentos = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    objetos = construir()
    if "--salida" in argumentos:
        carpeta = os.path.abspath(argumentos[argumentos.index("--salida") + 1])
        exportar(carpeta)
        if "--render" in argumentos:
            renderizar(os.path.join(carpeta, "previews"), objetos)


if __name__ == "__main__":
    main()
