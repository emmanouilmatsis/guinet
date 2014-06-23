<?php


abstract class Model
{
	public function __construct()
	{
	}

  public function state()
  {
    return isset($_SESSION['id']);
  }
}


class IndexModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}
}


class HomeModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

	public function signout()
	{
    unset($_SESSION['id']);
	}
}


class SignupModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

	public function signup()
	{
    $user = new User();

    if ($user->signup(Database::connection(), $_POST['username'], $_POST['password']))
    {
      $_SESSION['id'] = $user->id;
      return True;
    }

    return False;
  }
}


class SigninModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

	public function signin()
	{
    $user = new User();

    if ($user->signin(Database::connection(), $_POST['username'], $_POST['password']))
    {
      $_SESSION['id'] = $user->id;
      return True;
    }

    return False;
	}

	public function send()
	{
    $user = new User();

    return $user->sendEmail(Database::connection(), $_POST['username']);
  }
}


class SettingsModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

  public function updateUsername()
  {
    $user = User::find(Database::connection(), $_SESSION['id']);

    return $user->updateUsername(Database::connection(), $_POST['username']);
  }

  public function updatePassword()
  {
    $user = User::find(Database::connection(), $_SESSION['id']);

    return $user->updatePassword(Database::connection(), $_POST['password']);
  }
}


class DataModel extends Model
{
  public $data;

	public function __construct()
	{
		parent::__construct();
	}

  public function get()
  {
    // Find user
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Export trees
    $this->data = $user->export(Database::connection());
  }

  public function set()
  {
    // Get payload
    $this->data = file_get_contents('php://input');

    // Find user
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Import trees
    $user->import(Database::connection(), $this->data);
  }
}


?>
