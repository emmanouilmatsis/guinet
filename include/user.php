<?php


class User
{

  // DATABASE GATEWAY PROPERTIES

  private $record = array(
    'id'=>null,
    'username'=>null,
    'password'=>null,
    'widgets'=>array()
  );

  public function __construct()
  {
  }

  // DATABASE GATEWAY METHODS

  public function insert($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'INSERT INTO user (username, password) ';
      $sql .= 'VALUES (:username, :password)';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':username', $this->record['username'], PDO::PARAM_STR);
      $stmt->bindParam(':password', $this->record['password'], PDO::PARAM_STR);
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

  public function update($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'UPDATE user ';
      $sql .= 'SET username = :username, password = :password ';
      $sql .= 'WHERE id=:id';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':id', $this->record['id'], PDO::PARAM_STR);
      $stmt->bindParam(':username', $this->record['username'], PDO::PARAM_STR);
      $stmt->bindParam(':password', $this->record['password'], PDO::PARAM_STR);
      $stmt->execute();

      $connection->commit();
    }
    catch (PDOException $e)
    {
      $connection->rollBack();
      throw $e;
    }
  }

  public function delete($connection)
  {
    try
    {
      $connection->beginTransaction();

      // User table
      $sql = 'DELETE ';
      $sql .= 'FROM user ';
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

  public static function find($connection, $id)
  {
    try
    {
      $sql = 'SELECT * ';
      $sql .= 'FROM user ';
      $sql .= 'WHERE id = :id ';
      $sql .= 'LIMIT 1';

      $stmt = $connection->prepare($sql);
      $stmt->bindParam(':id', $id, PDO::PARAM_STR);
      $stmt->execute();

      $user = null;

      if ($record = $stmt->fetch(PDO::FETCH_ASSOC))
      {
        $user = new User();
        $user->id = $record['id'];
        $user->username = $record['username'];
        $user->password = $record['password'];
        $user->widgets = Widget::findAllFromUser(Database::connection(), $id);
      }

      return $user;
    }
    catch (PDOException $e)
    {
      throw $e;
    }
  }

  public static function findAll($connection)
  {
    try
    {
      $sql = 'SELECT * ';
      $sql .= 'FROM user';

      $stmt = $connection->prepare($sql);
      $stmt->execute();

      $users = array();

      while ($record = $stmt->fetch(PDO::FETCH_ASSOC))
      {
        $user = new User();
        $user->id = $record['id'];
        $user->username = $record['username'];
        $user->password = $record['password'];
        $user->widgets = Widget::findAllFromUser(Database::connection(), $record['id']);

        $users[] = $user;
      }

      return $users;
    }
    catch (PDOException $e)
    {
      throw $e;
    }
  }

  public function __set($key, $value)
  {
    if (array_key_exists($key, $this->record))
      $this->record[$key] = $value;
  }

  public function __get($key)
  {
    if (array_key_exists($key, $this->record))
      return $this->record[$key];
  }

  // DOMAIN LOGIC METHODS

  public function signup($connection, $username, $password)
  {
    // Test if username is empty string
    if (empty($username))
      return False;

    // Test if password is empty string
    if (empty($password))
      return False;

    // Test if username exist in the connection
    foreach (User::findAll($connection) as $user)
    {
      if ($user->username == $username)
        return False;
    }

    // Insert new record
    $this->record['username'] = $username;
    $this->record['password'] = $password;

    $this->insert($connection);

    return True;
  }

  public function signin($connection, $username, $password)
  {
    // Test if username and password exist in connection
    foreach (User::findAll($connection) as $user)
    {
      if ($user->username == $username && $user->password == $password)
      {
        // Load record from connection
        $this->record['id'] = $user->id;
        $this->record['username'] = $user->username;
        $this->record['password'] = $user->password;
        $this->record['widgets'] = Widget::findAllFromUser(Database::connection(), $user->id);

        return True;
      }
    }

    return False;
  }

  public function sendEmail($connection, $username)
  {
    // Test if username exist in the connection
    foreach (User::findAll($connection) as $user)
    {
      if ($user->username == $username)
      {
        // Send password reminder email to username
        $to = $user->username;

        $subject = file_get_contents(FP_ROOT . 'include/templates/email.subject.txt');

        $body = file_get_contents(FP_ROOT . 'include/templates/email.body.txt');
        $body = str_replace('{username}', $user->username, $body);
        $body = str_replace('{password}', $user->password, $body);

        $headers = file_get_contents(FP_ROOT . 'include/templates/email.headers.txt');

        return mail($to, $subject, $body, $headers);
      }
    }

    return False;
  }

  public function updateUsername($connection, $username)
  {
    // Test if username is empty string
    if (empty($username))
      return False;

    // Test if username already exist in connection
    foreach (User::findAll($connection) as $user)
    {
      if ($user->username == $username)
        return False;
    }

    // Update username
    $this->username = $username;
    $this->update($connection);

    return True;
  }

  public function updatePassword($connection, $password)
  {
    // Test if password is emtpy string
    if (empty($password))
      return False;

    // Update password
    $this->password = $password;
    $this->update($connection);

    return True;
  }

  public function import($connection, $data)
  {
    // Delete old widgets
    foreach ($this->record['widgets'] as $widget)
      $widget->delete($connection);

    // Insert new widgets
    $widgets = array();

    foreach (json_decode($data) as $key => $value)
    {
      $widget = new Widget();
      $widget->user_id = $this->record['id'];
      $widget->type = $value->type;
      $widget->html = $value->html;

      $widget->insert($connection);

      $widgets[] = $widget;
    }

    $this->record['widget'] = $widgets;
  }

  public function export($connection)
  {
    $data = array();

    foreach ($this->record['widgets'] as $key => $value)
      $data[] = array('type'=>$value->type, 'html'=>$value->html);

    return json_encode($data);
  }
}


?>
