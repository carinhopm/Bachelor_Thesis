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
		
		$consulta = $conexion->prepare("SELECT admin,ip,minConex FROM config WHERE nombre=?");
		$consulta->bind_param('s', $nombre);
		$consulta->execute();
		$consulta->store_result();
		$consulta->bind_result($admin,$ip,$conexServ);
		$consulta->fetch();
		$consulta->close();
		
		if ($admin=="si") {
			echo "&admin=si&ip=" . $ip;
			$parametros = $conexion->query("SELECT minConex FROM config WHERE admin='no'");
			while($fila = $parametros->fetch_array()) {
				echo "&minConex=" . $fila["minConex"];
			}
			echo "&";
			$parametros->close();
		} else {
			echo "&admin=no&ip=" . $ip;
			$parametros = $conexion->query("SELECT ip FROM config WHERE admin='si'");
			while($fila = $parametros->fetch_array()) {
				echo "&ipServ=" . $fila["ip"] . "&conexServ=" . $conexServ;
			}
			echo "&";
			$parametros->close();
		}
	
	} else {echo "&Configuracion incorrecta";}

?>