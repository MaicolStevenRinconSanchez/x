-- Animaciones: poses de la mano hechas con CFrames (no hacen falta AnimationIds).
--
-- Cada clip es una lista de claves en el tiempo. Una pose tiene:
--   pos  = desplazamiento en espacio de camara (unidades, X derecha, Y arriba, Z atras)
--   rot  = giro del brazo alrededor de la muneca, en grados y en ejes de la camara
--          (X apunta arriba/abajo, Y izquierda/derecha, Z gira en el plano de la pantalla)
--   giro = giro de la muneca alrededor del mango, en grados (Z rueda sobre la hoja)

local Animaciones = {}

export type Pose = { pos: Vector3, rot: Vector3, giro: Vector3 }
export type Clave = { t: number, pose: Pose, suavizado: string? }
export type Clip = { claves: { Clave } }

-- Punto de giro del brazo, relativo a la mano (un poco atras y a la derecha: la muneca).
local MUNECA = Vector3.new(0.25, -0.2, 0.35)

local function P(
	px: number,
	py: number,
	pz: number,
	rx: number?,
	ry: number?,
	rz: number?,
	gx: number?,
	gy: number?,
	gz: number?
): Pose
	return {
		pos = Vector3.new(px, py, pz),
		rot = Vector3.new(rx or 0, ry or 0, rz or 0),
		giro = Vector3.new(gx or 0, gy or 0, gz or 0),
	}
end

local REPOSO = P(0, 0, 0)
Animaciones.REPOSO = REPOSO

local SUAVIZADOS: { [string]: (number) -> number } = {
	lineal = function(a)
		return a
	end,
	-- rapido al inicio y frena al final
	salida = function(a)
		return 1 - (1 - a) ^ 3
	end,
	entrada = function(a)
		return a * a * a
	end,
	suave = function(a)
		return -(math.cos(math.pi * a) - 1) / 2
	end,
	-- se pasa un poco y vuelve
	rebote = function(a)
		local c1 = 1.70158
		return 1 + (c1 + 1) * (a - 1) ^ 3 + c1 * (a - 1) ^ 2
	end,
}

Animaciones.EQUIPAR = {
	claves = {
		{ t = 0, pose = P(0.3, -1.3, 0.3, -45, -10, 25) },
		{ t = 0.4, pose = REPOSO, suavizado = "rebote" },
	},
} :: Clip

-- Tajo de derecha a izquierda
Animaciones.TAJO_1 = {
	claves = {
		{ t = 0, pose = REPOSO },
		{ t = 0.07, pose = P(0.3, 0.25, 0.1, 5, -10, -25, 0, 0, -10), suavizado = "salida" },
		{ t = 0.17, pose = P(-0.45, 0.1, -0.05, 2, 10, 40, 0, 0, 20), suavizado = "salida" },
		{ t = 0.45, pose = REPOSO, suavizado = "suave" },
	},
} :: Clip

-- Reves de izquierda a derecha
Animaciones.TAJO_2 = {
	claves = {
		{ t = 0, pose = REPOSO },
		{ t = 0.07, pose = P(-0.5, 0.1, 0, 0, 10, 30, 0, 0, 20), suavizado = "salida" },
		{ t = 0.17, pose = P(0.3, -0.4, -0.1, -10, -15, -62, 0, 0, -25), suavizado = "salida" },
		{ t = 0.45, pose = REPOSO, suavizado = "suave" },
	},
} :: Clip

-- Acercar el cuchillo y girarlo para verlo por los dos lados
Animaciones.INSPECCIONAR = {
	claves = {
		{ t = 0, pose = REPOSO },
		{ t = 0.4, pose = P(-0.3, 0.15, 0.25, 0, 14, 10, 0, -20, 0), suavizado = "suave" },
		{ t = 1.0, pose = P(-0.3, 0.2, 0.25, 4, 14, 10, 0, -20, 0), suavizado = "suave" },
		{ t = 1.5, pose = P(-0.2, 0.1, 0.2, 0, 8, 6, 0, 10, 100), suavizado = "suave" },
		{ t = 2.1, pose = P(-0.2, 0.12, 0.2, 2, 8, 6, 0, 10, 100), suavizado = "suave" },
		{ t = 2.5, pose = REPOSO, suavizado = "suave" },
	},
} :: Clip

function Animaciones.duracion(clip: Clip): number
	return clip.claves[#clip.claves].t
end

local function mezclar(a: Pose, b: Pose, alfa: number): Pose
	return {
		pos = a.pos:Lerp(b.pos, alfa),
		rot = a.rot:Lerp(b.rot, alfa),
		giro = a.giro:Lerp(b.giro, alfa),
	}
end

-- Pose del clip en el segundo t.
function Animaciones.muestrear(clip: Clip, t: number): Pose
	local claves = clip.claves
	if t <= claves[1].t then
		return claves[1].pose
	end
	for i = 2, #claves do
		local b = claves[i]
		if t <= b.t then
			local a = claves[i - 1]
			local alfa = (t - a.t) / (b.t - a.t)
			local suavizar = SUAVIZADOS[b.suavizado or "lineal"] or SUAVIZADOS.lineal
			return mezclar(a.pose, b.pose, suavizar(alfa))
		end
	end
	return claves[#claves].pose
end

-- Una pose se aplica en dos partes: antes de la pose de reposo (brazo) y
-- despues (giro del mango), asi: antes * reposo * despues.
-- posMano es la posicion de la mano en reposo (POSE_REPOSO.Position).
function Animaciones.aCFrames(pose: Pose, posMano: Vector3): (CFrame, CFrame)
	local pivote = posMano + MUNECA
	local r = pose.rot
	local brazo = CFrame.new(pivote)
		* CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
		* CFrame.new(-pivote)
	local g = pose.giro
	return CFrame.new(pose.pos) * brazo, CFrame.Angles(math.rad(g.X), math.rad(g.Y), math.rad(g.Z))
end

-- Respiracion en reposo y vaiven al caminar (caminar va de 0 a 1).
function Animaciones.balanceo(tiempo: number, caminar: number): CFrame
	local respiracion = math.sin(tiempo * 1.8) * 0.02
	local fase = tiempo * 9
	local x = math.sin(fase) * 0.06 * caminar
	local y = -math.abs(math.cos(fase)) * 0.07 * caminar + respiracion
	local inclinacion = math.sin(fase) * math.rad(1.5) * caminar
	return CFrame.new(x, y, 0) * CFrame.Angles(0, 0, inclinacion)
end

return Animaciones
