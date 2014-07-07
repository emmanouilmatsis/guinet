<?php


// Database
class Database
{
  // Create database connection
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
}


?>
