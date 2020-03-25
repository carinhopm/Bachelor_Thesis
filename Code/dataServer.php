<?php

	$host = "mysql.hostinger.es";
	$usuario = "u568823178_us";
	$contrasena = "waspmote";
	$db = "u568823178_prueb";
	
	if (isset($_GET["nombre"]) && !empty($_GET["nombre"])) {
	
		$nombre = $_GET["nombre"];
		$datos = $_GET["datos"];
		
		$repDatos = str_replace("_", " ", $datos);
		
		$conexion = mysqli_connect($host, $usuario, $contrasena)
		or die ("Problema con el servidor");
		
		mysqli_select_db($conexion, $db)
		or die ("Problema al seleccionar la BD");
		
		mysqli_query($conexion, "INSERT INTO data (nombre,datos,hora,fecha) VALUES ('$nombre','$repDatos',CURTIME(),CURDATE())")
		or die ("Problema al insertar datos en la BD");
		
		echo "&UPDATED - Datos actualizados";
	
	} else {echo "&ERROR - Datos incorrectos";}

?>