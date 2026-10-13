-- Config: todo lo que se puede ajustar del cuchillo sin tocar el resto del codigo.

return {
	-- Mano en primera persona (viewmodel) ---------------------------------------
	-- Tamano de la mano y el cuchillo en pantalla. Mas pequeno = se mete menos en
	-- las paredes; se ve igual porque la posicion se escala con el.
	ESCALA_VIEWMODEL = 0.3,

	-- Donde queda la mano respecto a la camara (en unidades, antes de escalar):
	-- X = derecha, Y = arriba, -Z = adelante. Los angulos giran el cuchillo.
	POSE_REPOSO = CFrame.new(0.8, -0.8, -1.55)
		* CFrame.Angles(0, 0, math.rad(-18))
		* CFrame.Angles(math.rad(36), math.rad(58), math.rad(-8)),

	-- Pone la camara en primera persona mientras tienes el cuchillo en la mano.
	FORZAR_PRIMERA_PERSONA = true,

	-- Usa el color de piel del avatar para la mano (si es false usa el de Modelo).
	USAR_COLOR_DE_PIEL = true,

	-- Cuanto se mueve la mano al girar la camara y al caminar.
	INERCIA_CAMARA = 0.035,
	BALANCEO_CAMINAR = 1,

	-- Cuchillo que ven los demas jugadores ---------------------------------------
	ESCALA_MUNDO = 0.32,

	-- Combate --------------------------------------------------------------------
	DANO = 35,
	ALCANCE = 7, -- studs desde la cabeza
	ENFRIAMIENTO = 0.45, -- segundos entre tajos
	RETRASO_GOLPE = 0.08, -- el golpe se envia cuando la hoja pasa por el centro
	DANO_A_COMPANEROS = false, -- si hay equipos, no lastimar a los del mismo equipo

	-- Sonidos (puedes cambiarlos por rbxassetid://TU_ID) -------------------------
	SONIDO_TAJO = "rbxasset://sounds/swordslash.wav",
	SONIDO_DESENFUNDAR = "rbxasset://sounds/unsheath.wav",
	VOLUMEN = 0.5,

	-- Tecla para mirar el cuchillo.
	TECLA_INSPECCIONAR = Enum.KeyCode.F,
}
