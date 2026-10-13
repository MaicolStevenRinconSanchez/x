-- Modelo: construye con Parts el cuchillo y el brazo en primera persona.
--
-- Todas las medidas estan en "unidades" y se multiplican por la escala que se
-- pase a cada funcion, asi el mismo diseno sirve para la mano en pantalla
-- (viewmodel) y para el cuchillo que ven los demas jugadores.
--
-- Ejes del cuchillo (el origen es el centro del mango, donde agarra la mano):
--   -Z = hacia la punta   +Y = lomo con dientes   -Y = filo   +X = dorso de la mano

local Modelo = {}

Modelo.COLORES = {
	hoja = Color3.fromRGB(220, 220, 246),
	filo = Color3.fromRGB(244, 244, 255),
	ranura = Color3.fromRGB(176, 176, 204),
	dientes = Color3.fromRGB(202, 202, 232),
	guarda = Color3.fromRGB(122, 122, 134),
	guardaOscura = Color3.fromRGB(94, 94, 106),
	mango = Color3.fromRGB(64, 64, 74),
	mangoAnillo = Color3.fromRGB(96, 96, 108),
	piel = Color3.fromRGB(242, 204, 186),
	guante = Color3.fromRGB(34, 36, 46),
	placa = Color3.fromRGB(48, 52, 66),
	costura = Color3.fromRGB(128, 134, 150),
}

local GIRO_CILINDRO = CFrame.Angles(0, math.pi / 2, 0) -- los cilindros de Roblox van en X; esto los pone en Z

local function crearParte(
	padre: Instance,
	nombre: string,
	clase: string,
	tamano: Vector3,
	cf: CFrame,
	color: Color3,
	escala: number
): BasePart
	local parte = Instance.new(clase) :: BasePart
	parte.Name = nombre
	parte.Size = tamano * escala
	parte.CFrame = CFrame.new(cf.Position * escala) * cf.Rotation
	parte.Color = color
	parte.Material = Enum.Material.SmoothPlastic
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.CastShadow = false
	parte.Massless = true
	parte.Parent = padre
	return parte
end

local function bloque(padre, nombre, tamano, cf, color, escala)
	return crearParte(padre, nombre, "Part", tamano, cf, color, escala)
end

local function cilindro(padre, nombre, largo: number, diametro: number, z: number, color, escala)
	local parte = crearParte(
		padre,
		nombre,
		"Part",
		Vector3.new(largo, diametro, diametro),
		CFrame.new(0, 0, z) * GIRO_CILINDRO,
		color,
		escala
	) :: Part
	parte.Shape = Enum.PartType.Cylinder
	return parte
end

-- Cuña: por defecto es alta en +Z y baja hasta la arista de abajo en -Z.
local function cuna(padre, nombre, tamano, cf, color, escala)
	return crearParte(padre, nombre, "WedgePart", tamano, cf, color, escala)
end

-- Pieza invisible en el origen; sirve de pivote del modelo (y de Handle en la herramienta).
local function crearRaiz(padre: Instance, escala: number): BasePart
	local raiz = bloque(padre, "Raiz", Vector3.new(0.3, 0.3, 1), CFrame.new(), Modelo.COLORES.mango, escala)
	raiz.Transparency = 1
	return raiz
end

local function construirCuchillo(padre: Instance, escala: number)
	local c = Modelo.COLORES

	-- Mango, pomo y virola
	cilindro(padre, "Mango", 1.4, 0.3, -0.12, c.mango, escala)
	cilindro(padre, "AnilloMango2", 0.06, 0.34, -0.5, c.mangoAnillo, escala)
	cilindro(padre, "AnilloMango", 0.06, 0.34, 0.4, c.mangoAnillo, escala)
	cilindro(padre, "Pomo", 0.14, 0.38, 0.62, c.guarda, escala)
	cilindro(padre, "TapaPomo", 0.06, 0.26, 0.71, c.guardaOscura, escala)
	cilindro(padre, "Virola", 0.14, 0.36, -0.74, c.mangoAnillo, escala)

	-- Guarda: dos bloques cruzados para que se vea ochavada
	bloque(padre, "Guarda", Vector3.new(0.34, 0.76, 0.16), CFrame.new(0, -0.02, -0.89), c.guarda, escala)
	bloque(padre, "GuardaLado", Vector3.new(0.46, 0.54, 0.15), CFrame.new(0, -0.02, -0.89), c.guardaOscura, escala)

	-- Hoja
	local alto, grosor = 0.4, 0.07
	local inicio, largo = -0.97, 2.75
	local zCentro = inicio - largo / 2
	local zPunta = inicio - largo
	local largoPunta = 0.85
	bloque(padre, "Hoja", Vector3.new(grosor, alto, largo), CFrame.new(0, 0, zCentro), c.hoja, escala)
	bloque(padre, "Recazo", Vector3.new(0.09, alto, 0.16), CFrame.new(0, 0, inicio - 0.08), c.ranura, escala)

	-- Punta: cuña girada para que el lomo siga recto y el filo suba hasta la punta
	cuna(
		padre,
		"Punta",
		Vector3.new(grosor, alto, largoPunta),
		CFrame.new(0, 0, zPunta - largoPunta / 2) * CFrame.Angles(0, 0, math.pi),
		c.hoja,
		escala
	)

	-- Filo brillante a lo largo de la hoja y de la punta
	local altoFilo = 0.07
	bloque(
		padre,
		"Filo",
		Vector3.new(grosor + 0.008, altoFilo, largo),
		CFrame.new(0, -alto / 2 + altoFilo / 2, zCentro),
		c.filo,
		escala
	)
	local largoRampa = math.sqrt(alto * alto + largoPunta * largoPunta)
	local angulo = math.atan2(alto, largoPunta)
	local recorte = 0.12 -- evita que el filo sobresalga del lomo en la punta
	local dirRampa = Vector3.new(0, alto, -largoPunta) / largoRampa
	local normal = Vector3.new(0, largoPunta, alto) / largoRampa
	local centroRampa = Vector3.new(0, 0, zPunta - largoPunta / 2) - dirRampa * (recorte / 2) + normal * (altoFilo / 2)
	bloque(
		padre,
		"FiloPunta",
		Vector3.new(grosor + 0.008, altoFilo, largoRampa - recorte),
		CFrame.new(centroRampa) * CFrame.Angles(angulo, 0, 0),
		c.filo,
		escala
	)

	-- Ranura (canal) en el centro de la hoja
	bloque(padre, "Ranura", Vector3.new(grosor + 0.006, 0.05, 1.9), CFrame.new(0, 0.05, -2.15), c.ranura, escala)

	-- Dientes de sierra en el lomo
	local dientes, largoDiente, altoDiente = 10, 0.15, 0.09
	for i = 0, dientes - 1 do
		cuna(
			padre,
			"Diente" .. (i + 1),
			Vector3.new(grosor, altoDiente, largoDiente),
			CFrame.new(0, alto / 2 + altoDiente / 2, -1.16 - i * largoDiente),
			c.dientes,
			escala
		)
	end
end

local function construirMano(padre: Instance, escala: number, colorPiel: Color3)
	local c = Modelo.COLORES

	-- Palma y dedos cerrados alrededor del mango
	bloque(padre, "Palma", Vector3.new(0.36, 0.5, 0.6), CFrame.new(0.12, -0.03, -0.04), colorPiel, escala)
	local dedos = {
		{ z = -0.27, x = -0.115, alto = 0.48 },
		{ z = -0.125, x = -0.125, alto = 0.5 },
		{ z = 0.02, x = -0.115, alto = 0.46 },
		{ z = 0.16, x = -0.095, alto = 0.4 },
	}
	for i, d in dedos do
		bloque(
			padre,
			"Dedo" .. i,
			Vector3.new(0.2, d.alto, 0.135),
			CFrame.new(d.x, -0.04 - (0.5 - d.alto) / 2, d.z),
			colorPiel,
			escala
		)
	end
	bloque(
		padre,
		"Pulgar",
		Vector3.new(0.2, 0.14, 0.34),
		CFrame.new(-0.03, 0.22, -0.18) * CFrame.Angles(0, 0.25, 0),
		colorPiel,
		escala
	)

	-- Guante: dorso, nudillos y una costura clara
	bloque(padre, "GuanteDorso", Vector3.new(0.15, 0.6, 0.68), CFrame.new(0.33, -0.03, -0.03), c.guante, escala)
	bloque(padre, "GuanteNudillos", Vector3.new(0.3, 0.13, 0.64), CFrame.new(0.21, 0.24, -0.03), c.guante, escala)
	bloque(padre, "PlacaDorso", Vector3.new(0.04, 0.4, 0.46), CFrame.new(0.41, 0.0, -0.06), c.placa, escala)
	bloque(padre, "CosturaDorso", Vector3.new(0.045, 0.035, 0.46), CFrame.new(0.412, 0.12, -0.06), c.costura, escala)
end

local function construirAntebrazo(padre: Instance, escala: number)
	local c = Modelo.COLORES

	-- Marco del antebrazo: sale de la muñeca hacia atras, abajo y a la derecha
	local muneca = CFrame.new(0.12, -0.03, 0.27) * CFrame.Angles(math.rad(16), math.rad(14), 0)
	local function en(x, y, z)
		return muneca * CFrame.new(x, y, z)
	end

	bloque(padre, "Puno", Vector3.new(0.72, 0.72, 0.32), en(0, 0, 0.2), c.placa, escala)
	bloque(padre, "CosturaPuno", Vector3.new(0.73, 0.73, 0.04), en(0, 0, 0.37), c.costura, escala)
	bloque(padre, "Manga", Vector3.new(0.64, 0.64, 2.8), en(0, 0, 1.75), c.guante, escala)

	-- Placas de armadura arriba y afuera, con costuras claras
	bloque(padre, "PlacaArriba", Vector3.new(0.52, 0.05, 1.0), en(0, 0.34, 0.95), c.placa, escala)
	bloque(padre, "PlacaAfuera", Vector3.new(0.05, 0.5, 1.0), en(0.34, 0, 0.95), c.placa, escala)
	bloque(padre, "PlacaArriba2", Vector3.new(0.52, 0.05, 0.8), en(0, 0.34, 2.05), c.placa, escala)
	bloque(padre, "PlacaAfuera2", Vector3.new(0.05, 0.5, 0.8), en(0.34, 0, 2.05), c.placa, escala)
	bloque(padre, "CosturaArriba", Vector3.new(0.04, 0.055, 1.0), en(0.15, 0.342, 0.95), c.costura, escala)
	bloque(padre, "CosturaAfuera", Vector3.new(0.055, 0.04, 1.0), en(0.342, 0.12, 0.95), c.costura, escala)
	bloque(padre, "CosturaCruz", Vector3.new(0.53, 0.06, 0.04), en(0, 0.342, 1.5), c.costura, escala)
	bloque(padre, "CosturaCruzAfuera", Vector3.new(0.06, 0.51, 0.04), en(0.342, 0, 1.5), c.costura, escala)
end

-- Cuchillo solo (para la herramienta que ven los demas). La raiz esta en el mango.
function Modelo.crearCuchillo(escala: number): Model
	local modelo = Instance.new("Model")
	modelo.Name = "Cuchillo"
	modelo.PrimaryPart = crearRaiz(modelo, escala)
	construirCuchillo(modelo, escala)
	return modelo
end

-- Mano + antebrazo + cuchillo para la camara en primera persona.
function Modelo.crearViewmodel(escala: number, colorPiel: Color3?): Model
	local modelo = Instance.new("Model")
	modelo.Name = "ViewmodelCuchillo"
	modelo.PrimaryPart = crearRaiz(modelo, escala)
	construirCuchillo(modelo, escala)
	construirMano(modelo, escala, colorPiel or Modelo.COLORES.piel)
	construirAntebrazo(modelo, escala)
	return modelo
end

return Modelo
