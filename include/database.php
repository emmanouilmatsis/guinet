<?php


class Database
{
  public static function connection()
  {
		try
		{
			$dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME;
			$db = new PDO($dsn, DB_USER, DB_PASS);
			$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
      return $db;
		}
		catch (PDOException $e)
		{
			echo $e->getMessage();
			exit;
		}
  }

  public static function mysqli()
  {
    $db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    if ($db->connect_errno)
    {
      echo "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error;
      exit;
    }
    return $db;
  }
}


?>
