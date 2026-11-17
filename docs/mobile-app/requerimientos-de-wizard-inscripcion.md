## Requerimientos de Wizard de Inscripción

Versión 1.0.0

## Paso 1: Datos personales

Archivo: personal_data_form.dart

Input de Fotografía
	Requerida
	Máximo 5MB
	Formatos admitidos: PNG, JPG, JPEG, HEIF, HEIC

Input de Nombre(s)
	Requerida
	Máximo 64 caracteres

Input de Apellidos
	Requerida
	Máximo 64 caracteres

Input de Fecha de Nacimiento
	Requerida
	Valor máximo igual a 4 años anteriores a la fecha de hoy

Input de Correo electrónico
	Requerida
	Validar la siguiente expresión regular: /^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$/gm
	Máximo 96 caracteres

Input de Número de Teléfono
	Estará dividida en dos partes: un selector de lada y una input de número puro
		Selector de LADA
			Requerida
			Únicamente tres opciones: México, Estados Unidos y Canadá
			Valor por defecto: México
		Input de número puro
			Requerida
			Exactamente 10 caracteres
	Deberá retornar la concatenación del código asociado al selector de lada y el texto de la input de número puro

Input de Contraseña
	Requerida
	Mínimo 10 caracteres
	Máximo 16 caracteres
	Debe contener mayúsculas, minúsculas, números y caracteres especiales

Input de Confirmación de Contraseña
	Requerida
	Debe coincidir con el valor de la Input de Contraseña

## Paso 2: Documentos

Archivo: upload_adult_id_screen.dart

Input de Frente de INE
	Requerid
a
	Máximo 20 MB
	Formatos admitidos: PNG, JPG, JPEG, HEIF, HEIC
	Ofrecer dos giopciones: tomar foto o abrir galería (esto no aplica en las pruebas en web)

Input de Reverso de INE
	Requerida
	Máximo 20 MB
	Formatos admitidos: PNG, JPG, JPEG, HEIF, HEIC
	Ofrecer dos opciones: tomar foto o abrir galería (esto no aplica en las pruebas en web)

## Paso 3: Membresía

