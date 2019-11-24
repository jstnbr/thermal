<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="x-ua-compatible" content="ie=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Thermal</title>
  </head>

  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    html {
      font-size: 16px;
    }

    body {
      padding: 0 2rem;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
      line-height: 1.5;
      color: #111;
      transition: all .25s ease-out;
    }

    a,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p,
    table,
    tr,
    .status,
    .status::before,
    .thermal-status {
      transition: all .25s ease-out;
    }

    a {
      color: #111;
      text-decoration: none;
    }

    .logo {
      margin: 4rem 0;
    }

    .logo h1 {
      font-size: 4rem;
    }

    .logo h2 {
      font-size: 1rem;
    }

    .heading {
      margin: 2rem 0 1rem;
    }

    .heading:first-child {
      margin-top: 0;
    }

    .table {
      width: 100%;
      border-collapse: collapse;
    }

    .table td {
      padding: .5rem;
      width: 50%;
    }

    .table tbody tr {
      border-top: 1px solid #e9e9e9;
    }

    .table tbody tr:nth-child(odd) {
      background: #f9f9f9;
    }

    .thermal-hud .switch {
      margin-bottom: 1rem;
      margin-bottom: .875rem;
      text-align: right;
    }

    .thermal-status {
      padding: 4rem 0 8rem;
    }

    .footer li {
      margin: .5rem 0;
    }

    .footer ul {
      padding: 4rem 0;
      list-style: none;
    }

    .splash__content {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .status {
      display: flex;
      align-items: center;
      font-size: .875rem;
    }

    .status::before {
      content: "";
      margin-right: 12px;
      top: 1px;
      width: 12px;
      height: 12px;
      background: #ff4136;
      border-radius: 50%;
      display: block;
      position: relative;
    }

    .status.status--online::before {
      background: #2ecc40;
      animation: pulse-online 6s ease infinite;
    }

    .theme-dark {
      background: #111;
    }

    .theme-dark a,
    .theme-dark h1,
    .theme-dark h2,
    .theme-dark h3,
    .theme-dark h4,
    .theme-dark h5,
    .theme-dark h6,
    .theme-dark p,
    .theme-dark .thermal-status {
      color: #fff;
    }

    .theme-dark .status {
      color: #fff;
    }

    .theme-dark .table tbody tr {
      border-top: 1px solid #777;
    }

    .theme-dark .table tbody tr:nth-child(odd) {
      background: #333;
    }

    /**
     * Toggle Switch
     * (https://wd.dizaina.net/en/experiments/ios7-style-switch)
     */
    .ios7-switch {
      font-size: 28px;
      display: inline-block;
      position: relative;
      cursor: pointer;
      -webkit-user-select: none;
      -moz-user-select: none;
      -ms-user-select: none;
      user-select: none;
      -webkit-tap-highlight-color: transparent;
      tap-highlight-color: transparent;
    }

    .ios7-switch input {
      opacity: 0;
      position: absolute;
    }

    .ios7-switch input + span {
      width: 1.65em;
      height: 1em;
      background: #fff;
      border-radius: .5em;
      box-shadow: inset 0 0 0 .0625em #e9e9e9;
      display: inline-block;
      position: relative;
      vertical-align: -.15em;
      transition: all .375s cubic-bezier(.17, .67, .43, .98);
    }

    .ios7-switch:active input + span,
    .ios7-switch input + span:active {
      box-shadow: inset 0 0 0 .73em #e9e9e9;
    }

    .ios7-switch input + span:after {
      content: '';
      top: .0625em;
      left: .0625em;
      width: .875em;
      height: .875em;
      background: #fff;
      border-radius: .4375em;
      background: white;
      box-shadow: inset 0 0 0 .03em rgba(0, 0, 0, .1), 0 0 .05em rgba(0, 0, 0, .05), 0 .1em .2em rgba(0, 0, 0, .2);
      display: block;
      position: absolute;
      transition: all .25s ease-out;
    }

    .ios7-switch:active input + span:after,
    .ios7-switch input + span:active:after {
      width: 1.15em;
    }

    .ios7-switch input:checked + span {
      box-shadow: inset 0 0 0 .73em #4cd964;
    }

    .ios7-switch input:checked + span:after {
      left: .7125em;
    }

    .ios7-switch:active input:checked + span:after,
    .ios7-switch input:checked + span:active:after {
      left: .4375em;
    }

    /* Accessibility styles */
    .ios7-switch input:focus + span:after {
      box-shadow: inset 0 0 0 .03em rgba(0, 0, 0, .15), 0 0 .05em rgba(0, 0, 0, .08), 0 .1em .2em rgba(0, 0, 0, .3);
      background: #fff;
    }

    .ios7-switch input:focus + span {
      box-shadow: inset 0 0 0 .0625em #dadada;
    }

    .ios7-switch input:focus:checked + span {
      box-shadow: inset 0 0 0 .73em #33be4b;
    }

    /* Reset accessibility style on hover */
    .ios7-switch:hover input:focus + span:after {
      box-shadow: inset 0 0 0 .03em rgba(0, 0, 0, .1), 0 0 .05em rgba(0, 0, 0, .05), 0 .1em .2em rgba(0, 0, 0, .2);
      background: #fff;
    }

    .ios7-switch:hover input:focus + span {
      box-shadow: inset 0 0 0 .0625em #e9e9e9;
    }

    .ios7-switch:hover input:focus:checked + span {
      box-shadow: inset 0 0 0 .73em #4cd964;
    }
    /* End Toggle Switch */

    @keyframes pulse-offline {
      80% {
        box-shadow: 0 0 0 #ff4136;
      }
      100% {
        box-shadow: 0 0 0 6px transparent;
      }
    }

    @keyframes pulse-online {
      80% {
        box-shadow: 0 0 0 #2ecc40;
      }
      100% {
        box-shadow: 0 0 0 9px transparent;
      }
    }

    @media screen and (max-width: 767px) {
      .logo h1 {
        font-size: 2rem;
      }
    }
  </style>

  <?php
    /**
     * WordPress version.
     */
    if ( file_exists( '../wp-includes/version.php' ) ) {
      require '../wp-includes/version.php';
    }

    /**
     * Thermal config.
     */
    $thermal_config_name = 'thermal.test';
    $thermal_config_site = 'site-url.com';

    /**
     * Thermal status.
     */
    function thermal_status_page() {
      exec( 'ping -c 1 192.168.55.10', $o, $status );

      if ( $status === 0 ) {
        return true;
      }

      return false;
    }

    /**
     * Thermal status class.
     */
    if ( thermal_status_page() ) {
      $status_class = 'status--online';
    } else {
      $status_class = 'status--offline';
    }

    /**
     * Thermal MySQL status.
     */
    $mysqli = @new mysqli( 'localhost', 'root', 'root', 'thermal' );

    if ( $mysqli ) {
      $mysql_version = $mysqli->server_info;
    }

    $mysqli->close();
  ?>

  <body>
    <div class="splash">
      <div class="splash__content">
        <div class="logo">
          <h1>
            <a href="//<?php echo $thermal_config_name; ?>" title="<?php echo $thermal_config_name; ?>">Thermal</a>
          </h1>

          <h2>Vagrant LAMP box for WordPress</h2>
        </div>

        <div class="thermal-hud">
          <div class="switch-group">
            <div class="switch">
              <label class="ios7-switch">
                <input id="theme-toggle" type="checkbox">
                <span></span>
              </label>
            </div>
          </div>

          <div class="status <?php echo $status_class ?>">

            <?php
              if ( thermal_status_page() ) {
                echo 'Online';
              } else {
                echo 'Offline';
              }
            ?>
          </div>
        </div>
      </div>
    </div>

    <div class="thermal-status">
      <div class="heading">
        <strong>System</strong>
      </div>

      <table class="table">
        <tr>
          <td>OS</td>
          <td>Debian 10.0</td>
        </tr>
        <tr>
          <td>Apache</td>
          <td><?php echo ( apache_get_version() ? '<span title="' . apache_get_version() . '">✅</span>' : '<span>❌</span>' ); ?></td>
        </tr>
        <tr>
          <td>MySQL</td>
          <td><?php echo ( $mysql_version ? '<span title="' . $mysql_version . '">✅</span>' : '<span title="' . $mysqli->connect_error . '">❌</span>' ); ?></td>
        </tr>
        <tr>
          <td>PHP</td>
          <td><?php echo '<span title="' . phpversion() . '">✅</span>'; ?></td>
        </tr>

        <tr>
          <td>WordPress</td>
          <td><?php echo ( $wp_version ? '<span title="' . $wp_version . '">✅</span>' : '<span title="No version.php found in ../wp-includes">❌</span>' ); ?></td>
        </tr>
      </table>

      <div class="heading">
        <strong>Database</strong>
      </div>

      <table class="table">
        <tr>
          <td>Host</td>
          <td>localhost</td>
        </tr>
        <tr>
          <td>User</td>
          <td>root</td>
        </tr>
        <tr>
          <td>Password</td>
          <td>root</td>
        </tr>
        <tr>
          <td>Name</td>
          <td>thermal</td>
        </tr>
      </table>

      <div class="heading">
        <strong>SSH</strong>
      </div>

      <table class="table">
        <tr>
          <td>Host</td>
          <td>localhost</td>
        </tr>
        <tr>
          <td>User</td>
          <td>vagrant</td>
        </tr>
        <tr>
          <td>Password</td>
          <td>vagrant</td>
        </tr>
      </table>

      <div class="heading">
        <strong>WordPress</strong>
      </div>

      <table class="table">
        <tr>
          <td>User</td>
          <td>thermal</td>
        </tr>
        <tr>
          <td>Password</td>
          <td>vagrant</td>
        </tr>
      </table>
    </div>
  </body>

  <script>
    var body = document.querySelector( 'body' );
    var theme_toggle = document.getElementById( 'theme-toggle' );

    var switch_theme = function() {
      if ( theme_toggle.checked ) {
        body.classList.add( 'theme-dark' );
      } else {
        body.classList.remove( 'theme-dark' );
      }
    }

    theme_toggle.addEventListener( 'click', function( e ) {
      switch_theme();
    }, false );

    document.addEventListener( 'DOMContentLoaded', function() {
      switch_theme();
    } );
  </script>
</html>