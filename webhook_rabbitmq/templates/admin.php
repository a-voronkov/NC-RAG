<div class="section">
  <h2>Webhook RabbitMQ</h2>
  <form id="webhook-rabbitmq-settings">
    <p>
      <label for="wr-enabled">Enabled</label>
      <input type="checkbox" id="wr-enabled" <?= $enabled === '1' ? 'checked' : '' ?> />
    </p>
    <p>
      <label for="wr-host">Host</label>
      <input type="text" id="wr-host" value="<?= p($host) ?>" />
    </p>
    <p>
      <label for="wr-port">Port</label>
      <input type="number" id="wr-port" value="<?= p($port) ?>" />
    </p>
    <p>
      <label for="wr-user">User</label>
      <input type="text" id="wr-user" value="<?= p($user) ?>" />
    </p>
    <p>
      <label for="wr-pass">Password</label>
      <input type="password" id="wr-pass" value="<?= p($pass) ?>" />
    </p>
    <p>
      <label for="wr-vhost">VHost</label>
      <input type="text" id="wr-vhost" value="<?= p($vhost) ?>" />
    </p>
    <p>
      <label for="wr-exchange">Exchange</label>
      <input type="text" id="wr-exchange" value="<?= p($exchange) ?>" />
    </p>
    <p>
      <label for="wr-exchange-type">Exchange Type</label>
      <input type="text" id="wr-exchange-type" value="<?= p($exchange_type) ?>" />
    </p>
    <p>
      <label for="wr-routing-prefix">Routing Prefix</label>
      <input type="text" id="wr-routing-prefix" value="<?= p($routing_prefix) ?>" />
    </p>
    <button type="button" id="wr-save">Save</button>
  </form>
</div>
<!-- JS moved to js/admin.js to comply with CSP -->

