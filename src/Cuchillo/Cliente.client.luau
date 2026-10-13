-- Cliente: muestra la mano con el cuchillo en primera persona, la anima y
-- avisa al servidor cuando atacas. Va dentro de la herramienta (LocalScript).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local herramienta = script.Parent
local Config = require(herramienta:WaitForChild("Config"))
local Modelo = require(herramienta:WaitForChild("Modelo"))
local Animaciones = require(herramienta:WaitForChild("Animaciones"))
local eventoAtaque = herramienta:WaitForChild("Ataque") :: RemoteEvent

local jugador = Players.LocalPlayer
local NOMBRE_RENDER = "ViewmodelCuchillo"
local NOMBRE_ACCION = "InspeccionarCuchillo"
local POS_MANO = Config.POSE_REPOSO.Position

local viewmodel: Model? = nil
-- Piezas del viewmodel y su posicion respecto a la raiz (se arma en el origen).
-- Moverlas siempre desde estos desfases evita que se separen con el tiempo.
local partes: { BasePart } = {}
local desfases: { CFrame } = {}
local destinos: { CFrame } = {}
local equipado = false
local mostrandoViewmodel = false
local conexiones: { RBXScriptConnection } = {}
local modoCamaraAnterior: Enum.CameraMode? = nil

local clipActual: Animaciones.Clip? = nil
local tiempoClip = 0
local siguienteTajo = 1
local ultimoAtaque = -math.huge

local tiempo = 0
local caminar = 0
local inercia = Vector2.zero
local camaraAnterior: CFrame? = nil

-- Sonidos creados en el cliente: solo los escuchas tu.
local function crearSonido(id: string): Sound
	local sonido = Instance.new("Sound")
	sonido.SoundId = id
	sonido.Volume = Config.VOLUMEN
	sonido.Parent = script
	return sonido
end

local sonidoTajo = crearSonido(Config.SONIDO_TAJO)
local sonidoDesenfundar = crearSonido(Config.SONIDO_DESENFUNDAR)

local function sonar(sonido: Sound)
	sonido.TimePosition = 0
	sonido:Play()
end

local function reproducir(clip: Animaciones.Clip)
	clipActual = clip
	tiempoClip = 0
end

local function colorPiel(personaje: Model): Color3?
	if not Config.USAR_COLOR_DE_PIEL then
		return nil
	end
	local mano = personaje:FindFirstChild("RightHand") or personaje:FindFirstChild("Right Arm")
	if mano and mano:IsA("BasePart") then
		return mano.Color
	end
	return nil
end

-- En primera persona la camara esta pegada a la cabeza.
local function enPrimeraPersona(camara: Camera): boolean
	return (camara.Focus.Position - camara.CFrame.Position).Magnitude < 1
end

-- El cuchillo "de verdad" (el que ven los demas) se oculta solo para ti
-- cuando estas en primera persona, para que no tape la mano.
local function ocultarCuchilloMundo(ocultar: boolean)
	local handle = herramienta:FindFirstChild("Handle")
	if not handle then
		return
	end
	local valor = if ocultar then 1 else 0
	for _, parte in handle:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.LocalTransparencyModifier = valor
		end
	end
end

local function escalar(cf: CFrame, escala: number): CFrame
	return CFrame.new(cf.Position * escala) * cf.Rotation
end

local function actualizar(dt: number)
	local camara = workspace.CurrentCamera
	local personaje = jugador.Character
	if not (viewmodel and camara and personaje) then
		return
	end

	-- Mostrar la mano solo en primera persona
	local primera = enPrimeraPersona(camara)
	if primera ~= mostrandoViewmodel then
		mostrandoViewmodel = primera
		viewmodel.Parent = if primera then camara else nil
		ocultarCuchilloMundo(primera)
	end

	tiempo += dt

	-- Animacion activa (equipar, tajo, inspeccionar)
	local pose = Animaciones.REPOSO
	if clipActual then
		tiempoClip += dt
		pose = Animaciones.muestrear(clipActual, tiempoClip)
		if tiempoClip >= Animaciones.duracion(clipActual) then
			clipActual = nil
		end
	end
	local antes, despues = Animaciones.aCFrames(pose, POS_MANO)

	-- Vaiven al caminar
	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	local objetivoCaminar = 0
	if humanoide and humanoide.FloorMaterial ~= Enum.Material.Air then
		objetivoCaminar = math.clamp(humanoide.MoveDirection.Magnitude, 0, 1) * Config.BALANCEO_CAMINAR
	end
	caminar += (objetivoCaminar - caminar) * math.min(1, dt * 8)
	local balanceo = Animaciones.balanceo(tiempo, caminar)

	-- Inercia: la mano se queda un poco atras cuando giras la camara
	local cf = camara.CFrame
	local objetivoInercia = Vector2.zero
	if camaraAnterior and dt > 0 then
		local delta = camaraAnterior:ToObjectSpace(cf)
		local giroX, giroY = delta:ToEulerAnglesYXZ()
		local limite = math.rad(6)
		objetivoInercia = Vector2.new(
			math.clamp(-giroX / dt * Config.INERCIA_CAMARA, -limite, limite),
			math.clamp(-giroY / dt * Config.INERCIA_CAMARA, -limite, limite)
		)
	end
	camaraAnterior = cf
	inercia = inercia:Lerp(objetivoInercia, math.min(1, dt * 10))
	local balanceoCamara = CFrame.Angles(inercia.X, inercia.Y, inercia.Y * 0.5)

	local pose3D = balanceoCamara * balanceo * antes * Config.POSE_REPOSO * despues
	local raiz = cf * escalar(pose3D, Config.ESCALA_VIEWMODEL)
	for i, desfase in desfases do
		destinos[i] = raiz * desfase
	end
	workspace:BulkMoveTo(partes, destinos, Enum.BulkMoveMode.FireCFrameChanged)
end

local function atacar()
	if not equipado then
		return
	end
	local ahora = os.clock()
	if ahora - ultimoAtaque < Config.ENFRIAMIENTO then
		return
	end
	ultimoAtaque = ahora

	reproducir(if siguienteTajo == 1 then Animaciones.TAJO_1 else Animaciones.TAJO_2)
	siguienteTajo = 3 - siguienteTajo
	sonar(sonidoTajo)

	task.delay(Config.RETRASO_GOLPE, function()
		local camara = workspace.CurrentCamera
		if equipado and camara then
			eventoAtaque:FireServer(camara.CFrame.LookVector)
		end
	end)
end

local function inspeccionar(_nombre: string, estado: Enum.UserInputState): Enum.ContextActionResult
	if estado == Enum.UserInputState.Begin and equipado and clipActual == nil then
		reproducir(Animaciones.INSPECCIONAR)
	end
	return Enum.ContextActionResult.Pass
end

local function limpiar()
	if not equipado then
		return
	end
	equipado = false
	RunService:UnbindFromRenderStep(NOMBRE_RENDER)
	ContextActionService:UnbindAction(NOMBRE_ACCION)
	for _, conexion in conexiones do
		conexion:Disconnect()
	end
	table.clear(conexiones)
	if viewmodel then
		viewmodel:Destroy()
		viewmodel = nil
	end
	table.clear(partes)
	table.clear(desfases)
	table.clear(destinos)
	mostrandoViewmodel = false
	clipActual = nil
	camaraAnterior = nil
	ocultarCuchilloMundo(false)
	if modoCamaraAnterior then
		jugador.CameraMode = modoCamaraAnterior
		modoCamaraAnterior = nil
	end
end

local function alEquipar()
	local personaje = jugador.Character
	if equipado or not personaje then
		return
	end
	equipado = true

	if Config.FORZAR_PRIMERA_PERSONA then
		modoCamaraAnterior = jugador.CameraMode
		jugador.CameraMode = Enum.CameraMode.LockFirstPerson
	end

	local nuevo = Modelo.crearViewmodel(Config.ESCALA_VIEWMODEL, colorPiel(personaje))
	viewmodel = nuevo
	for _, parte in nuevo:GetDescendants() do
		if parte:IsA("BasePart") then
			table.insert(partes, parte)
			table.insert(desfases, parte.CFrame)
		end
	end
	-- El modelo se mete en la camara en el primer cuadro si estas en primera persona
	mostrandoViewmodel = false
	tiempo, caminar, inercia = 0, 0, Vector2.zero

	reproducir(Animaciones.EQUIPAR)
	sonar(sonidoDesenfundar)

	RunService:BindToRenderStep(NOMBRE_RENDER, Enum.RenderPriority.Camera.Value + 1, actualizar)
	ContextActionService:BindAction(NOMBRE_ACCION, inspeccionar, false, Config.TECLA_INSPECCIONAR)

	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	if humanoide then
		table.insert(conexiones, humanoide.Died:Connect(limpiar))
	end
end

herramienta.Equipped:Connect(alEquipar)
herramienta.Unequipped:Connect(limpiar)
herramienta.Activated:Connect(atacar)
script.Destroying:Connect(limpiar)
