<?php

	$host = "mysql.hostinger.es";
	$usuario = "u568823178_us";
	$contrasena = "waspmote";
	$db = "u568823178_prueb";

	if (isset($_GET["nombre"]) && !empty($_GET["nombre"])) {
	
		$nombre = $_GET["nombre"];
		
		$conexion = mysqli_connect($host, $usuario, $contrasena)
		or die ("Problema con el servidor");
		
		mysqli_select_db($conexion, $db)
		or die ("Problema al seleccionar la BD");
		
		$consulta = $conexion->prepare("SELECT admin FROM config WHERE nombre=?");
		$consulta->bind_param('s', $nombre);
		$consulta->execute();
		$consulta->store_result();
		$consulta->bind_result($admin);
		$consulta->fetch();
		$consulta->close();
		
		if ($admin=="si") {
			$parametros = $conexion->query("SELECT nombre,minConex FROM config WHERE admin='no' ORDER BY minConex");
			while($fila = $parametros->fetch_array()) {
				echo "&nombre=" . $fila["nombre"] . "&minConex=" . $fila["minConex"];
			}
			echo "&";
			$parametros->close();
		} else {
			echo "&Informacion disponible solo para el nodo servidor";
		}
	
	} else {echo "&Configuracion incorrecta";}

?>