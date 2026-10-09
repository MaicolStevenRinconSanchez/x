# Prompt para un juego PvP de Roblox: "PRISMA STRIKE"

Shooter arena con colores neón, varios modos PvP, pistolas con buenos controles y miras limpias, mapa para 15–20 jugadores y código optimizado.

## Cómo usarlo

1. Copia todo el bloque **PROMPT MAESTRO** y pégalo en una IA de código potente (Claude, por ejemplo). Va a generar muchos scripts, así que conviene un modelo fuerte.
2. La IA entrega el juego **por fases**. Prueba cada fase en Roblox Studio antes de escribir `SIGUIENTE` (pestaña **Test → Clients and Servers**, 1 servidor + 4 clientes).
3. El **Assistant de Roblox Studio** funciona mejor con pedidos cortos. Úsalo para tareas puntuales (insertar cosas de la Toolbox, ajustar un script). Al final de este archivo tienes prompts cortos para eso.
4. Cambia lo que está entre `[corchetes]` si quieres otro nombre, colores o tema.

---

## PROMPT MAESTRO

```text
Actúa como un desarrollador senior de Roblox (Luau) y diseñador de shooters competitivos. Vas a construir conmigo, por fases, un juego PvP completo y listo para publicar, para servidores de 15 a 20 jugadores.

# 1. VISIÓN
- Nombre: [PRISMA STRIKE]
- Género: shooter arena PvP rápido, en primera persona, estilo arcade (sensación de referencia: Arsenal, Rivals, Big Paintball). Sin sangre.
- Estética: colores neón hipnotizantes y saturados. Ciudad synthwave flotante de noche, suelo con cuadrícula brillante, cielo de nebulosa morada, hologramas, luces que pulsan y cambian de color.
- Paleta: Cian #00F5FF (equipo 1), Magenta #FF2EB8 (equipo 2), Violeta #8A2BE2, Amarillo #FFE600 (objetivos y alertas), Verde lima #39FF14 (curación y aliados), fondo #0B0420.
- Bucle de diversión: partidas cortas (5–8 min), respawn rápido (3 s), rachas de bajas con anunciador, votación de modo, podio MVP al final, subir de nivel y desbloquear skins neón.
- Plataformas: PC, móvil, tablet y consola (teclado y ratón, táctil y mando).

# 2. REGLAS DE ENTREGA (OBLIGATORIAS)
1. Entrega por FASES (sección 11). Al terminar cada fase, detente y espera a que yo escriba "SIGUIENTE".
2. Para CADA archivo indica: ruta exacta en el Explorer (ej. ServerScriptService/Services/RoundService), tipo (Script, LocalScript o ModuleScript) y el código COMPLETO. Prohibido usar "...", "resto igual" o "implementa aquí".
3. Si un archivo cambia en una fase posterior, entrégalo completo otra vez.
4. Todo debe funcionar sin plugins de pago ni Rojo. Si algo se configura a mano en Studio (propiedades, Game Settings), dame los pasos exactos.
5. Comentarios breves en español; nombres de variables y funciones en inglés.
6. Al final de cada fase: cómo probarlo (Test → Clients and Servers, 1 servidor + 4 clientes) y qué debería ver.
7. No inventes IDs de assets. Donde haga falta un sonido, mesh o imagen, deja una constante vacía en Config con un comentario de qué buscar en la Toolbox, y que el juego funcione aunque esté vacía (con un fallback).

# 3. ARQUITECTURA
- Servidor autoritativo: el cliente solo maneja input, cámara, efectos y predicción visual. Daño, munición, puntuación, XP y estado de la ronda viven en el servidor.
- Estructura:
  - ReplicatedStorage/Shared/Config: GameConfig, WeaponConfig, ModeConfig, SkinConfig (todo el balance se cambia aquí, sin tocar lógica).
  - ReplicatedStorage/Shared/Util: Signal, Trove (limpieza de conexiones), Spring, ObjectPool, RateLimiter, Types.
  - ServerScriptService: un único Script "ServerMain" que carga los servicios (ModuleScripts): DataService, PlayerService (equipos, spawns, hitboxes), WeaponService, RoundService, ProgressionService y Modes/ (ModeBase + un módulo por modo).
  - StarterPlayer/StarterPlayerScripts: un único LocalScript "ClientMain" que carga los controladores: InputController, CameraController, WeaponController, ViewmodelController, EffectsController, HUDController, MenuController, SettingsController.
  - ReplicatedFirst: LoadingScreen (LocalScript).
- Remotes: los crea el servidor al iniciar, en ReplicatedStorage/Remotes. UnreliableRemoteEvent para efectos cosméticos (trazadoras e impactos de otros jugadores); RemoteEvent para acciones que importan.
- Estado de la ronda replicado con Attributes en un Folder ReplicatedStorage/GameState (Phase, Mode, EndTime calculado con workspace:GetServerTimeNow()). El cliente calcula el contador; NO envíes el tiempo cada segundo.
- Puntuación de equipo como Attributes en los objetos Team; estadísticas por jugador en leaderstats (Bajas, Muertes, Nivel).
- Personajes R15 y Players.CharacterAutoLoads = false: el servidor decide cuándo y dónde aparece cada jugador.
- Hitboxes justas: el tamaño del avatar no puede dar ventaja. Fija las escalas en Game Settings → Avatar o crea hitboxes uniformes invisibles (cabeza y torso) desde el servidor. Dime qué opción usas y por qué.

# 4. ARMAS (prioridad máxima: tienen que sentirse PERFECTAS)
## 4.1 Arsenal (vida = 100; todos los números en WeaponConfig)
| Arma        | Tipo                 | Daño          | x Cabeza | Cadencia             | Cargador | Recarga          |
| Pulse       | Pistola semi         | 25            | 2.0      | 400 RPM máx          | 12       | 1.4 s            |
| Nova        | Revólver             | 45            | 2.25     | 120 RPM              | 6        | 2.2 s            |
| Flux        | Pistola automática   | 14            | 1.5      | 900 RPM              | 20       | 1.6 s            |
| Triad       | Pistola ráfaga x3    | 20            | 1.75     | 1 ráfaga cada 0.35 s | 18       | 1.5 s            |
| Volt        | Subfusil             | 18            | 1.5      | 800 RPM              | 30       | 1.8 s            |
| Spectrum    | Rifle de asalto      | 24            | 1.75     | 600 RPM              | 30       | 2.0 s            |
| Bloom       | Escopeta             | 8 x 14        | 1.25     | 70 RPM               | 6        | 0.5 s por cartucho |
| Laser Line  | Francotirador        | 90            | 2.0      | 45 RPM               | 5        | 2.6 s            |
| Neon Blade  | Cuerpo a cuerpo (F)  | 55            | -        | 1 golpe cada 0.6 s   | -        | -                |
Cada arma define además: alcance y caída de daño (distancia de daño completo y mínimo), dispersión (cadera, apuntando, moviéndose, saltando), retroceso (vertical, horizontal aleatorio, recuperación), tiempo de ADS, FOV de ADS, multiplicador de velocidad al caminar y tiempo de equipar.
- Loadout: principal (Volt, Spectrum, Bloom o Laser Line) + pistola (Pulse, Nova, Flux o Triad) + Neon Blade.
- Movimiento: caminar 16, correr 22, apuntando 11. No se dispara mientras corres (disparar cancela el sprint).

## 4.2 Controles
- PC: clic izquierdo dispara · clic derecho apunta (mantener; opción "alternar" en ajustes) · R recarga · Shift corre · F cuerpo a cuerpo · 1/2/3 o rueda cambia de arma · Tab marcador.
- Móvil: botón de disparo grande que también permite arrastrar para girar la cámara mientras disparas; botones de apuntar, recargar, correr y cambiar arma; todo con Scale + UIAspectRatioConstraint.
- Mando: RT dispara, LT apunta, X recarga, L3 corre, R3 cuerpo a cuerpo, Y cambia de arma. Asistencia de apuntado leve (fricción cerca de enemigos) SOLO para mando y táctil, nunca para ratón, y desactivable.
- Usa ContextActionService para que las acciones se desactiven en menús.
- Desactiva la Backpack por defecto (StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)) y crea una hotbar propia. No uses Tools de Roblox para las armas.

## 4.3 Miras limpias (ADS) y sensación de disparo
- Primera persona forzada en partida (Enum.CameraMode.LockFirstPerson); tercera persona en el lobby.
- Viewmodel local (brazos + arma) pegado a la cámara, con CanCollide, CanQuery y CanTouch en false y CastShadow en false. Se actualiza con RunService:BindToRenderStep justo después de la cámara.
- Cada arma tiene Attachments Grip, Muzzle y AimPoint. Al apuntar, el AimPoint queda EXACTAMENTE en el centro de la pantalla: calcula el offset a partir del attachment, nunca con números a ojo.
- Transición cadera ↔ mira independiente de los FPS: alpha += (target - alpha) * (1 - math.exp(-speed * dt)), con tiempo de ADS por arma.
- Al apuntar: tween del FOV (FOV base configurable 70–100 → FOV de ADS del arma), se oculta la cruz, baja la dispersión y el balanceo, y la sensibilidad se multiplica por un valor configurable.
- Miras: punto rojo u holográfico nítido (SurfaceGui con retícula neón) en pistolas y rifles; el francotirador usa overlay de mira a pantalla completa y oculta el viewmodel con el zoom.
- Retroceso con muelles (Spring): patada de cámara vertical + horizontal pequeña aleatoria que se recupera suave, y una patada separada para el viewmodel. Balanceo con el ratón y al caminar, ambos menores al apuntar.
- Cruz dinámica que se abre al disparar, moverse o saltar; color y tamaño configurables.
- Feedback: hitmarker instantáneo (predicción del cliente), marcador distinto para disparo a la cabeza, confirmación de baja que manda el servidor (sonido + icono), números de daño opcionales, indicador de dirección del daño recibido, fogonazo, trazadoras, impactos, casquillos (solo en calidad alta), sonido con PlaybackSpeed aleatoria entre 0.95 y 1.05.
- Recargar, equipar e inspeccionar con animaciones PROCEDURALES (CFrame y springs) en el viewmodel. Roblox normalmente bloquea animaciones subidas por otros, así que no dependas de IDs de animación de terceros. En tercera persona, los demás ven el arma soldada a la mano y los brazos apuntando con IKControl.

## 4.4 Validación en el servidor (antitrampas)
El cliente hace el raycast para que se sienta instantáneo y envía: id del arma, origen, dirección(es), parte golpeada, posición del impacto y número de disparo. El servidor:
- Comprueba tipos con typeof, descarta NaN o infinitos y aplica rate limit por jugador en cada remote.
- Lleva la munición, la recarga y la cadencia (tolerancia de ~20% por variación de red).
- Comprueba que el origen esté a pocos studs de la cabeza del tirador, que la distancia no supere el alcance y que no haya pared entre origen e impacto (re-raycast solo contra el mapa).
- Comprueba que el objetivo esté vivo, sea enemigo (sin fuego amigo en modos por equipos), no tenga protección de spawn y que su posición real esté cerca del impacto declarado (tolerancia según el ping). Si es viable, guarda ~1 s de historial de posiciones a 20 Hz para compensar el lag.
- Calcula el daño con caída por distancia y multiplicador de cabeza; asigna bajas y asistencias (25+ de daño en los últimos 5 s).
- Reenvía la trazadora a los demás clientes por UnreliableRemoteEvent (no al tirador, que ya la dibujó).

# 5. MODOS DE JUEGO (rotan con votación)
Intermedio de 20 s: salen 3 modos al azar para votar; si hay empate se elige al azar. Mínimo 2 jugadores para empezar; con menos, calentamiento FFA libre que no guarda estadísticas.
1. Combate por Equipos (TDM): Cian vs Magenta. Gana el primero en llegar a 50 bajas, o el que más tenga a los 8 min.
2. Captura la Bandera (CTF): 3 capturas o 10 min. Para capturar, tu bandera tiene que estar en tu base. Una bandera caída vuelve sola a los 20 s o al tocarla un aliado. El portador tiene un marcador visible para todos.
3. Todos contra Todos (FFA): primero en llegar a 25 bajas. Cada jugador aparece en el punto más alejado de los enemigos.
4. Dominación: zonas A, B y C. Se captura quedándose en la zona (más jugadores = más rápido; se bloquea si hay enemigos dentro). 1 punto por zona cada 2 s; gana el primero en llegar a 200.
5. Carrera de Armas (Gun Game): cada baja te pasa a la siguiente arma; la última es el Neon Blade. Una baja con cuchillo le quita un nivel a la víctima.
6. Duelo de Pistolas: TDM solo con pistolas, a 30 bajas. Rápido y caótico.
Común a todos: balanceo automático de equipos al entrar y al empezar la ronda, protección de spawn de 3 s (se cancela al disparar), regeneración de vida tras 5 s sin recibir daño, respawn en 3 s con cámara de muerte (enfoca al asesino y muestra la vida que le queda), anunciador de rachas (Doble baja, Triple baja, Imparable, Leyenda) y de primera sangre, killfeed, y pantalla final con podio MVP top 3 y la XP ganada.
Implementa los modos sobre una clase base ModeBase (Start, OnPlayerAdded, OnPlayerRemoving, OnPlayerDied, GetSpawnFor, CheckWin, Cleanup) para que añadir modos nuevos sea fácil.

# 6. MAPA "NEXO PRISMA"
- Tamaño medio-grande para 20 jugadores: zona jugable de ~500 x 360 studs, 3 alturas (0, 18 y 36 studs), simétrico en espejo para que sea justo.
- Distribución: Base Cian (oeste) y Base Magenta (este), cada una con sala de spawn protegida (10+ puntos) y bandera; plaza central con torre (zona B); carril norte de combate cercano (mercado neón cubierto, ideal para pistolas, zona A); carril sur abierto con puentes sobre el vacío y líneas de visión largas para francotiradores (zona C); pasillos que conectan carriles cada ~60 studs.
- Coberturas cada 15–20 studs. Ninguna línea de visión supera ~180 studs salvo en el carril sur.
- 4–6 plataformas de salto con anillos neón animados. Caer al vacío mata. Paredes invisibles en los bordes.
- Marcadores en workspace/Map/Markers (Spawns/Cyan, Spawns/Magenta, Spawns/FFA, Flags, Zones) con Parts invisibles y tags de CollectionService, para que los modos lean el mapa sin rutas fijas en el código.
- Entrega: (a) un script para la Command Bar que construya el blockout jugable del mapa con partes y acentos neón, para poder jugar de inmediato; (b) un script de Command Bar que configure Lighting; (c) una lista de búsquedas para la Toolbox (props, cielo, carteles, plantas neón, sonidos, música) y dónde colocar cada cosa.
- Iluminación hipnótica: Lighting.Technology = Future, de noche, Ambient y OutdoorAmbient morados, Atmosphere con neblina violeta, Bloom (Intensity ~1, Size ~24, Threshold ~0.9), ColorCorrection (Saturation ~0.25, Contrast ~0.15), SunRays sutiles y un Sky de nebulosa o synthwave.
- Animaciones de ambiente SOLO en el cliente: partes con tag "NeonPulse" cambian de color y brillo, texturas con tag "ScrollTexture" se desplazan y los hologramas giran. Todo desde UN solo loop a ~30 Hz que se apaga en Modo Rendimiento.

# 7. INTERFAZ Y PANTALLA DE ENTRADA
- Pantalla de carga en ReplicatedFirst: quita la de Roblox (RemoveDefaultLoadingScreen) y muestra el logo del juego con un UIGradient neón animado, barra de progreso real con ContentProvider:PreloadAsync de los assets clave, consejos aleatorios, botón "Saltar" a los 3 s y un límite de 10 s.
- Menú principal: cámara cinemática que recorre el mapa (Parts CamPath1..N) y botones JUGAR, ARSENAL (armas y skins) y AJUSTES, con animaciones y sonidos al pasar el ratón y al hacer clic.
- HUD: vida (abajo a la izquierda), munición del cargador y de reserva (abajo a la derecha), tiempo y marcador (arriba al centro), killfeed (arriba a la derecha), marcadores de objetivo con BillboardGui (banderas y zonas, con distancia), hotbar y anuncios de rachas en el centro.
- Marcador con Tab, pantalla de votación y pantalla de fin de ronda con podio 3D de los MVP.
- Ajustes guardados: sensibilidad, multiplicador de ADS, FOV, apuntar mantener o alternar, color y tamaño de la cruz, volumen y Modo Rendimiento (apaga bloom, partículas, casquillos y animaciones de ambiente; se activa solo si la calidad gráfica del usuario es baja).
- Estilo: fuentes gruesas (GothamBlack o FredokaOne), UIStroke, UIGradient y esquinas redondeadas; todo en Scale + UIAspectRatioConstraint; ScreenGuis con ResetOnSpawn = false.

# 8. PROGRESIÓN Y DATOS
- XP: baja 100, asistencia 50, captura de bandera 300, zona capturada 150, victoria 500, participación 150. Niveles con curva suave; cada 5 niveles se desbloquea una skin neón (colores, materiales, gradientes animados). Solo cosméticas: nada de pagar para ganar.
- DataStore robusto: UpdateAsync, reintentos con espera exponencial, autoguardado cada 2 min, guardado al salir y en game:BindToClose, bloqueo de sesión para no duplicar ni perder datos, esquema con versión y valores por defecto. (Si te digo que tengo ProfileStore, úsalo.)
- Se guarda: nivel, XP, bajas, muertes, victorias, loadout, skins desbloqueadas y equipadas, y ajustes.

# 9. OPTIMIZACIÓN (aplica a TODO el código)
Código:
- --!strict y tipos en todos los módulos. Sin variables globales. Un solo Script de servidor y un solo LocalScript de cliente que cargan módulos.
- Solo task.wait, task.spawn, task.defer y task.delay. Prohibido wait(), spawn(), delay() y bucles while true con wait para temporizadores: usa timestamps y eventos.
- Un único loop de render para cámara, armas y viewmodel. Nada de RenderStepped por arma ni por jugador.
- Limpieza de conexiones con Trove al morir, cambiar de arma, salir y terminar la ronda. Cero fugas de memoria.
- Pools de objetos para trazadoras, impactos, sonidos, partículas y filas del killfeed. Usa ParticleEmitter:Emit() en vez de crear emisores.
- RaycastParams y OverlapParams reutilizados; collision groups para que los raycasts ignoren viewmodels, efectos y paredes invisibles.
- CollectionService en vez de recorrer workspace:GetDescendants() una y otra vez.
- Zonas y banderas con chequeo de distancia o GetPartBoundsInBox a 10 Hz en el servidor, no con Touched.
- Sin crear tablas ni closures nuevas dentro de bucles por frame.
- Usa @native solo en funciones de cálculo intensivo (springs, validación de impactos) si mejora el rendimiento.
Red:
- Ningún remote por frame. Payloads compactos (números, Vector3, ids cortos). Efectos por UnreliableRemoteEvent, estado por Attributes, tiempos con GetServerTimeNow.
Mapa y render:
- Todo Anchored. Decoración con CanCollide, CanTouch y CanQuery en false. CastShadow en false en props pequeños y neón. MeshParts con CollisionFidelity Box o Hull. Reutiliza meshes y materiales. Pocas transparencias superpuestas. Luces con Shadows = false y en número limitado. Partículas con Rate bajo y escaladas según la calidad.
- StreamingEnabled activado con radio suficiente para cubrir el mapa, y ModelStreamingMode = Persistent en banderas, zonas y spawns.
Objetivo: 60 FPS en un móvil de gama media y red estable con 20 jugadores. En la última fase revisa todo el código contra esta lista y dime qué medir en el MicroProfiler (Ctrl+F6) y en la Developer Console (F9).

# 10. TOOLBOX Y SEGURIDAD
- Apóyate en la Toolbox (Creator Store) para props, cielo, modelos de armas, sonidos y música. Prefiere Roblox y creadores verificados. Antes de usar cualquier modelo, borra TODOS sus scripts y revisa que no traiga require() con IDs, getfenv, loadstring ni scripts escondidos.
- Dame un script de Command Bar "WeaponRigger" que prepare un modelo de arma de la Toolbox: borra sus scripts, suelda las partes a un Handle, pone Massless y CanCollide en false, crea los Attachments Grip, Muzzle y AimPoint (que luego yo coloco) y lo guarda en ReplicatedStorage/Assets/Weapons con el nombre del arma.
- Si falta el modelo de un arma, genérala por código con partes low-poly de estilo neón para que todo funcione siempre.
- Game Settings → Security: LoadStringEnabled desactivado y HTTP solo si hace falta.
- Nunca confíes en el cliente para daño, munición, puntos, XP ni compras.

# 11. FASES
Fase 1 — Base: árbol completo del Explorer, ServerMain y ClientMain, módulos de Config y Util, Remotes, PlayerService (equipos, spawns, hitboxes, protección de spawn) y DataService.
Fase 2 — Armas: WeaponService (validación), WeaponController, ViewmodelController (ADS, retroceso, balanceo), efectos con pools, cruz y hitmarkers, controles de PC, móvil y mando, WeaponRigger y armas de respaldo.
Fase 3 — Rondas y modos: RoundService, votación, ModeBase y los 6 modos, killfeed, rachas, cámara de muerte y fin de ronda con MVP.
Fase 4 — Mapa: script de blockout, script de Lighting, marcadores, efectos de ambiente del cliente y lista de búsquedas para la Toolbox.
Fase 5 — Interfaz: pantalla de carga, menú con cámara cinemática, HUD, marcador, ajustes, y arsenal con skins.
Fase 6 — Progresión y pulido: XP, niveles, skins, sonidos, anunciador, recompensa diaria y ajustes de balance.
Fase 7 — Optimización y QA: auditoría completa contra la sección 9, lista de pruebas con 20 jugadores y checklist de publicación (Max Players 20, dispositivos, avatar, seguridad y cuestionario de madurez).

Empieza ya con la Fase 1. Antes del código, resume en 15 líneas como máximo la arquitectura y el recorrido de red de un disparo, desde el clic hasta el daño.
```

---

## Miniatura e ícono de la tienda

Tamaños que pide Roblox: **miniaturas 1920 × 1080** (16:9, puedes subir varias) e **ícono 512 × 512**. Se suben en Studio desde **Game Settings → Basic Info** (Game Icon y Thumbnails) o desde el Creator Dashboard.

### Opción A (recomendada): captura real del juego

Roblox pide que la miniatura represente el juego real, y una captura real es lo que mejor funciona.

1. En Studio, coloca 2–4 avatares (Avatar → Rig Builder), uno de cada equipo, con armas neón en la mano. Pósalos en poses de acción con el Animation Editor.
2. Fondo: la plaza central del mapa con la torre y los neón encendidos. Oculta el HUD y pon la cámara con FieldOfView ~50 para que se vea más cinematográfico.
3. Haz la captura a 1920 × 1080 y termínala en Canva o Photopea: título grande con brillo, un poco más de saturación y contraste, y un viñeteado suave.

### Opción B: generarla con IA (Midjourney, DALL·E, etc.)

Prompt de miniatura (en inglés, porque estos generadores responden mejor así):

```text
Roblox game thumbnail, 16:9, 1920x1080, 3D cartoon render. A hypnotic neon synthwave arena floating in space at night: glowing cyan and magenta grid floor, swirling purple nebula sky with a spiral of light, holographic billboards, floating platforms. Foreground: two blocky Roblox-style avatars in dynamic action poses, one glowing cyan team, one glowing magenta team, aiming sleek neon pistols at each other, bright muzzle-flash light bursts, no blood. Middle: a glowing team flag on a tower. Top center: huge bold 3D title text "PRISMA STRIKE" with chrome bevel and cyan-to-pink-to-yellow neon gradient, thick dark outline, slight tilt. Ultra saturated colors, strong rim lighting, heavy bloom, shallow depth of field on the background, clean composition, readable at small size.
```

Prompt del ícono:

```text
Roblox game icon, square 512x512, 3D cartoon render. Close-up of a blocky Roblox avatar head wearing a glowing cyan visor, holding a sleek neon magenta pistol next to the face, swirling purple and pink neon spiral background, bold letters "PS" with neon gradient in a corner, thick outlines, ultra saturated, strong bloom, centered, readable at small size.
```

Reglas para que no te la rechacen: sin sangre, sin marcas o logos reales, sin texto engañoso (por ejemplo "GRATIS ROBUX") y el contenido debe parecerse al juego.

---

## Descripción para la página del juego

```text
⚡ PRISMA STRIKE ⚡
¡Entra a la arena neón más hipnotizante de Roblox!
🔫 Pistolas, rifles, escopetas y francotiradores con miras limpias y controles precisos
🏁 6 modos: Combate por Equipos, Captura la Bandera, Todos contra Todos, Dominación, Carrera de Armas y Duelo de Pistolas
🌌 Mapa synthwave flotante para 20 jugadores
⭐ Sube de nivel y desbloquea skins neón
📱 PC, móvil, tablet y consola
¡Dale a 👍 y a ⭐ Favoritos para recibir las actualizaciones!
```

---

## Checklist de publicación

- **File → Publish to Roblox**. En Game Settings → Places, **Max Players = 20**.
- **Devices**: Computer, Phone, Tablet y Console.
- **Avatar**: R15, con escalas fijas o hitboxes uniformes (lo que haya elegido la IA en la Fase 1).
- **Security**: activa "Enable Studio Access to API Services" para probar el DataStore en Studio; deja LoadStringEnabled desactivado.
- Responde el **cuestionario de madurez** (Maturity & Compliance) con sinceridad: es un shooter sin sangre.
- Sube la miniatura y el ícono. Género: Shooter.
- Antes de anunciarlo, prueba un servidor real con amigos (o Test → Clients and Servers con 8 clientes) y revisa F9 → Memory y Network.

---

## Prompts cortos para el Assistant de Roblox Studio

Para tareas puntuales dentro de Studio:

```text
Inserta desde la Toolbox un Sky de nebulosa morada estilo synthwave y configura Lighting de noche con Technology Future, Bloom y ColorCorrection con saturación 0.25.
```

```text
Busca en la Toolbox 10 props de ciudad neón (cajas, barreras, carteles holográficos, palmeras neón), insértalos en una carpeta workspace/Map/Props, borra cualquier script que traigan y deja todas las partes Anchored con CanCollide en false en las piezas decorativas.
```

```text
Selecciona todas las partes de workspace/Map que tengan material Neon y ponles CastShadow en false. Dime cuántas cambiaste.
```

```text
Revisa todo el juego y lista cualquier script que use require() con un número, getfenv o loadstring. No borres nada, solo dime dónde está.
```
