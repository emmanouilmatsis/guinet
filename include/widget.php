<?php


class Widget
{

  // DATABASE GATEWAY PROPERTIES

  // SQL table
  private $record = array(
    'id'=>null,
    'user_id'=>null,
    'type'=>null,
    'html'=>array()
  );

  public function __construct()
  {
  }

  // DATABASE GATEWAY METHODS

  // Insert new widget
  public function insert($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'INSERT INTO widget (user_id, type, html) ';
      $sql .= 'VALUES (:user_id, :type, :html)';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':user_id', $this->record['user_id'], PDO::PARAM_STR);
      $stmt->bindParam(':type', $this->record['type'], PDO::PARAM_STR);
      $stmt->bindParam(':html', $this->record['html'], PDO::PARAM_STR);
      $stmt->execute();

      $this->record['id'] = $connection->lastInsertId();

      $connection->commit();
    }
    catch (PDOException $e)
    {
      $connection->rollBack();
      throw $e;
    }
  }

  // Update existing widget
  public function update($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'UPDATE widget ';
      $sql .= 'SET user_id = :user_id, type = :type, html = :html ';
      $sql .= 'WHERE id=:id';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':id', $this->record['id'], PDO::PARAM_STR);
      $stmt->bindParam(':user_id', $this->record['user_id'], PDO::PARAM_STR);
      $stmt->bindParam(':type', $this->record['type'], PDO::PARAM_STR);
      $stmt->bindParam(':html', $this->record['html'], PDO::PARAM_STR);
      $stmt->execute();

      $connection->commit();
    }
    catch (PDOException $e)
    {
      $connection->rollBack();
      throw $e;
    }
  }

  // Delete existing widget
  public function delete($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'DELETE ';
      $sql .= 'FROM widget ';
      $sql .= 'WHERE id = :id';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':id', $this->record['id'], PDO::PARAM_STR);
      $stmt->execute();

      $connection->commit();
    }
    catch (PDOException $e)
    {
      $connection->rollBack();
      throw $e;
    }
  }

  // Find existing widget from id else return null
  public static function find($connection, $id)
  {
    try
    {
      $sql = 'SELECT * ';
      $sql .= 'FROM widget ';
      $sql .= 'WHERE id = :id ';
      $sql .= 'LIMIT 1';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':id', $id, PDO::PARAM_STR);
      $stmt->execute();

      $widget = null;

      // Populate record
      if ($record = $stmt->fetch(PDO::FETCH_ASSOC))
      {
        $widget = new User();
        $widget->id = $record['id'];
        $widget->user_id = $record['user_id'];
        $widget->type = $record['type'];
        $widget->html = $record['html'];
      }

      return $widget;
    }
    catch (PDOException $e)
    {
      throw $e;
    }
  }

  // Find all widgets else return empty array
  public static function findAll($connection)
  {
    try
    {
      $sql = 'SELECT * ';
      $sql .= 'FROM widget';

      $stmt = $connection->prepare($sql);
      $stmt->execute();

      $widgets = array();

      // Populate record
      while ($record = $stmt->fetch(PDO::FETCH_ASSOC))
      {
        $widget = new Widget();
        $widget->id = $record['id'];
        $widget->user_id = $record['user_id'];
        $widget->type = $record['type'];
        $widget->html = $record['html'];

        $widgets[] = $widget;
      }

      return $widgets;
    }
    catch (PDOException $e)
    {
      throw $e;
    }
  }

  // Find all widgets from user id else return emtpy array
  public static function findAllFromUser($connection, $user_id)
  {
    try
    {
      $sql = 'SELECT * ';
      $sql .= 'FROM widget ';
      $sql .= 'WHERE user_id = :user_id';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':user_id', $user_id, PDO::PARAM_STR);
      $stmt->execute();

      $widgets = array();

      while ($record = $stmt->fetch(PDO::FETCH_ASSOC))
      {
        $widget = new Widget();
        $widget->id = $record['id'];
        $widget->user_id = $record['user_id'];
        $widget->type = $record['type'];
        $widget->html = $record['html'];

        $widgets[] = $widget;
      }

      return $widgets;
    }
    catch (PDOException $e)
    {
      throw $e;
    }
  }

  // Set record at key
  public function __set($key, $value)
  {
    if (array_key_exists($key, $this->record))
      $this->record[$key] = $value;
  }

  // Get record at key
  public function __get($key)
  {
    if (array_key_exists($key, $this->record))
      return $this->record[$key];
  }
}


?>
