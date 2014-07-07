<?php


// Model
abstract class Model
{
	public function __construct()
	{
	}

  // Return if user is signedin or signedout
  public function state()
  {
    return isset($_SESSION['id']);
  }
}


// Index Model
class IndexModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}
}


// Home Model
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


// Signup Model
class SignupModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

	public function signup()
	{
    // Instantiate new User Active Record
    $user = new User();

    // If user can succesfully signup then signin
    if ($user->signup(Database::connection(), $_POST['username'], $_POST['password']))
    {
      $_SESSION['id'] = $user->id;
      return True;
    }

    return False;
  }
}


// Signin Model
class SigninModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

	public function signin()
	{
    // Instantiate new User Active Record
    $user = new User();

    // If user can succesfully signin then signin
    if ($user->signin(Database::connection(), $_POST['username'], $_POST['password']))
    {
      $_SESSION['id'] = $user->id;
      return True;
    }

    return False;
	}

	public function send()
	{
    // Instantiate new User Active Record
    $user = new User();

    // Send mail to user with password if username exists
    return $user->sendEmail(Database::connection(), $_POST['username']);
  }
}


// Settings Model
class SettingsModel extends Model
{
	public function __construct()
	{
		parent::__construct();
	}

  public function updateUsername()
  {
    // Instantiate new User Active Record from id
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Update Username
    return $user->updateUsername(Database::connection(), $_POST['username']);
  }

  public function updatePassword()
  {
    // Instantiate new User Active Record from id
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Update password
    return $user->updatePassword(Database::connection(), $_POST['password']);
  }
}


// Data Model
class DataModel extends Model
{
  public $data;

	public function __construct()
	{
		parent::__construct();
	}

  public function get()
  {
    // Instantiate new User Active Record from id
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Export widgets
    $this->data = $user->export(Database::connection());
  }

  public function set()
  {
    // Get payload
    $this->data = file_get_contents('php://input');

    // Instantiate new User Active Record from id
    $user = User::find(Database::connection(), $_SESSION['id']);

    // Import widgets
    $user->import(Database::connection(), $this->data);
  }
}


?>
