-- Servidor: arma el cuchillo que ven los demas jugadores y aplica el dano.
-- Va dentro de la herramienta (Script con RunContext = Server).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local herramienta = script.Parent
local Config = require(herramienta:WaitForChild("Config"))
local Modelo = require(herramienta:WaitForChild("Modelo"))
local eventoAtaque = herramienta:WaitForChild("Ataque") :: RemoteEvent

-- Cuchillo visible para todos: sus piezas se sueldan a la pieza "Handle",
-- que es la que la mano del personaje agarra.
local function crearHandle()
	if herramienta:FindFirstChild("Handle") then
		return
	end
	local cuchillo = Modelo.crearCuchillo(Config.ESCALA_MUNDO)
	local handle = cuchillo.PrimaryPart :: BasePart
	handle.Name = "Handle"
	for _, parte in cuchillo:GetChildren() do
		if parte ~= handle and parte:IsA("BasePart") then
			local soldadura = Instance.new("WeldConstraint")
			soldadura.Part0 = handle
			soldadura.Part1 = parte
			soldadura.Parent = parte
			parte.Anchored = false
			parte.Parent = handle
		end
	end
	handle.Anchored = false
	handle.Parent = herramienta
	cuchillo:Destroy()
end

local function mismoEquipo(a: Player, b: Player?): boolean
	if not b or a.Neutral or b.Neutral then
		return false
	end
	local equipo: Team? = a.Team
	return equipo ~= nil and equipo == b.Team
end

local function hayParedEntre(desde: Vector3, hasta: Vector3, ignorar: { Instance }): boolean
	local parametros = RaycastParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	parametros.FilterDescendantsInstances = ignorar
	return workspace:Raycast(desde, hasta - desde, parametros) ~= nil
end

-- Busca el humanoide mas cercano y mas centrado delante de ti.
local function buscarObjetivo(personaje: Model, origen: Vector3, direccion: Vector3): Humanoid?
	local parametros = OverlapParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	parametros.FilterDescendantsInstances = { personaje }
	local partes = workspace:GetPartBoundsInRadius(
		origen + direccion * (Config.ALCANCE / 2),
		Config.ALCANCE / 2 + 1,
		parametros
	)

	local mejor: Humanoid? = nil
	local mejorPuntaje = -math.huge
	local revisados: { [Humanoid]: boolean } = {}
	for _, parte in partes do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local humanoide = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if modelo and humanoide and not revisados[humanoide] then
			revisados[humanoide] = true
			local raiz = modelo:FindFirstChild("HumanoidRootPart")
			local centro = if raiz and raiz:IsA("BasePart") then raiz.Position else parte.Position
			local hacia = centro - origen
			local distancia = hacia.Magnitude
			local alineacion = if distancia > 0.01 then hacia.Unit:Dot(direccion) else 1
			local delante = alineacion > 0.35 or distancia < 2.5
			if
				humanoide.Health > 0
				and distancia <= Config.ALCANCE
				and delante
				and not hayParedEntre(origen, centro, { personaje, modelo })
			then
				local puntaje = alineacion - distancia / Config.ALCANCE
				if puntaje > mejorPuntaje then
					mejor, mejorPuntaje = humanoide, puntaje
				end
			end
		end
	end
	return mejor
end

local ultimoGolpe = -math.huge

eventoAtaque.OnServerEvent:Connect(function(jugador: Player, direccion: any)
	-- Solo cuenta si quien ataca es el dueno y tiene el cuchillo en la mano
	local personaje = herramienta.Parent
	if not (personaje and personaje:IsA("Model")) or Players:GetPlayerFromCharacter(personaje) ~= jugador then
		return
	end
	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	local cabeza = personaje:FindFirstChild("Head")
	if not (humanoide and humanoide.Health > 0 and cabeza and cabeza:IsA("BasePart")) then
		return
	end

	-- El servidor tambien controla el tiempo entre tajos (no se puede saltar desde el cliente)
	local ahora = os.clock()
	if ahora - ultimoGolpe < Config.ENFRIAMIENTO * 0.8 then
		return
	end
	ultimoGolpe = ahora

	local mirada: Vector3 = cabeza.CFrame.LookVector
	if typeof(direccion) == "Vector3" and direccion.Magnitude > 0.5 and direccion.Magnitude < 1.5 then
		mirada = direccion.Unit
	end

	local objetivo = buscarObjetivo(personaje, cabeza.Position, mirada)
	if not objetivo then
		return
	end
	local otroJugador = Players:GetPlayerFromCharacter(objetivo.Parent)
	if not Config.DANO_A_COMPANEROS and mismoEquipo(jugador, otroJugador) then
		return
	end

	-- Etiqueta "creator": la usan muchos tableros de puntuacion para contar bajas
	local etiquetaVieja = objetivo:FindFirstChild("creator")
	if etiquetaVieja then
		etiquetaVieja:Destroy()
	end
	local etiqueta = Instance.new("ObjectValue")
	etiqueta.Name = "creator"
	etiqueta.Value = jugador
	etiqueta.Parent = objetivo
	Debris:AddItem(etiqueta, 2)

	objetivo:TakeDamage(Config.DANO)
end)

crearHandle()
