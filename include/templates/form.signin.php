<div class="form">

  <h1>Sign In</h1>

  <form method="post" action="<?php echo $signin; ?>">
    <input name="username" type="text" placeholder="Username"/>
    <input name="password" type="password" placeholder="Password"/>
    <button type="submit"/>Sign In</button>
  </form>

  <hr/>

  <h1>Send Password</h1>

  <form method="post" action="<?php echo $send; ?>">
    <input name="username" type="username" placeholder="Username"/>
    <button type="submit"/>Send</button>
  </form>

</div>
