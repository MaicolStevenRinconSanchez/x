# Cuchillo en primera persona para Roblox

Una herramienta (Tool) con la mano con guante y el cuchillo de sierra en primera persona, como en la captura:

- Cuchillo hecho con Parts: hoja con dientes de sierra en el lomo, filo claro, canal, guarda, mango y pomo.
- Mano con el color de piel de tu avatar, guante oscuro y antebrazo con placas de armadura.
- Animaciones sin AnimationIds: sacar el cuchillo, dos tajos que se alternan, inspeccionar con **F**, vaivén al caminar, respiración e inercia al girar la cámara.
- Daño del lado del servidor: alcance, ángulo, paredes, tiempo entre golpes y equipos. Deja la etiqueta `creator` para los tableros de puntuación.
- Los demás jugadores ven el cuchillo en la mano de tu personaje.

## Instalación en Roblox Studio (la forma fácil)

1. Descarga [`Cuchillo.rbxmx`](Cuchillo.rbxmx): ábrelo en GitHub y pulsa **Download raw file**.
2. En Roblox Studio, en el **Explorer**, haz clic derecho sobre **StarterPack** → **Insert from File...** y elige `Cuchillo.rbxmx`.
3. Pulsa **Play**. Equipa el cuchillo desde la barra de abajo (o con su número, normalmente **1**).

| Acción | Control |
| --- | --- |
| Atacar | Clic izquierdo (o tocar la pantalla en móvil) |
| Inspeccionar | **F** |

> Si lo insertaste en otro lugar (por ejemplo arrastrando el archivo a Workspace), muévelo dentro de **StarterPack**.

## Qué hay dentro

```
Cuchillo (Tool)
├── Config       (ModuleScript)  ← ajustes: daño, alcance, posición de la mano, sonidos...
├── Modelo       (ModuleScript)  ← construye el cuchillo y el brazo con Parts
├── Animaciones  (ModuleScript)  ← poses de los tajos, equipar e inspeccionar
├── Cliente      (LocalScript)   ← mano en pantalla, animaciones y clics
├── Servidor     (Script)        ← cuchillo visible para todos y daño
└── Ataque       (RemoteEvent)
```

## Personalizar

Casi todo se cambia en **Config**:

| Ajuste | Qué hace | Valor |
| --- | --- | --- |
| `DANO` | Vida que quita cada tajo | `35` |
| `ALCANCE` | Distancia máxima del golpe (studs) | `7` |
| `ENFRIAMIENTO` | Segundos entre tajos | `0.45` |
| `DANO_A_COMPANEROS` | Si es `false`, no daña a los de tu mismo equipo | `false` |
| `FORZAR_PRIMERA_PERSONA` | Pone la cámara en primera persona con el cuchillo en la mano | `true` |
| `POSE_REPOSO` | Dónde queda la mano en pantalla (X derecha, Y arriba, -Z adelante) | |
| `ESCALA_VIEWMODEL` | Tamaño de la mano en pantalla | `0.3` |
| `ESCALA_MUNDO` | Tamaño del cuchillo que ven los demás | `0.32` |
| `USAR_COLOR_DE_PIEL` | Usa el color de piel de tu avatar en la mano | `true` |
| `SONIDO_TAJO`, `SONIDO_DESENFUNDAR` | Sonidos (puedes poner `rbxassetid://TU_ID`) | sonidos de la espada clásica |
| `TECLA_INSPECCIONAR` | Tecla para mirar el cuchillo | `F` |

- **Colores** del cuchillo, la piel y el guante: tabla `COLORES` al principio de **Modelo**.
- **Movimientos** de los tajos: `TAJO_1`, `TAJO_2`, `EQUIPAR` e `INSPECCIONAR` en **Animaciones**. Cada clave tiene un tiempo y una pose.

La mano solo se dibuja en primera persona. Si alejas la cámara, se ve el cuchillo en la mano del personaje.

## Para desarrolladores (Rojo)

El código está en `src/Cuchillo`. Con [Rojo](https://rojo.space) 7:

```bash
rojo serve                                    # sincroniza con Studio (pone el Tool en StarterPack)
rojo build cuchillo.project.json -o Cuchillo.rbxmx   # vuelve a generar el archivo para Studio
```
