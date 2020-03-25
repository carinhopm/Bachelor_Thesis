<?php

	$host = "mysql.hostinger.es";
	$usuario = "u568823178_us";
	$contrasena = "waspmote";
	$db = "u568823178_prueb";
	
	$admin = "si";
	$nombre = "Carlos";
	$datos = "Esta funcionando...";
	$ip = "123.45.67.890";
	$puerto = "4400";
	
	$conexion = mysqli_connect($host, $usuario, $contrasena)
	or die ("Problema con el servidor");
	
	mysqli_select_db($conexion, $db)
	or die ("Problema al seleccionar la BD");
	
	// ('$admin','$nombre','$datos','$ip','$puerto',CURTIME(),CURDATE(),$conexion)
	mysqli_query($conexion, "INSERT INTO waspmotes (admin,nombre,datos,ip,puerto,hora,fecha) VALUES ('$admin','$nombre','$datos','$ip','$puerto',CURTIME(),CURDATE())")
	or die ("Problema al insertar datos en la BD");
	
	echo "Registro correcto";
		
?>