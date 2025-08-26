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
<script>
  (function() {
    function save(key, value) {
      const body = new URLSearchParams();
      body.set('key', key);
      body.set('value', value);
      return fetch(OC.generateUrl('/apps/webhook_rabbitmq/settings/save'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'requesttoken': OC.requestToken
        },
        body: body.toString(),
        credentials: 'same-origin'
      }).then(r => r.json());
    }
    document.getElementById('wr-save').addEventListener('click', function() {
      const enabled = document.getElementById('wr-enabled').checked ? '1' : '0';
      const host = document.getElementById('wr-host').value;
      const port = document.getElementById('wr-port').value;
      const user = document.getElementById('wr-user').value;
      const pass = document.getElementById('wr-pass').value;
      const vhost = document.getElementById('wr-vhost').value;
      const exchange = document.getElementById('wr-exchange').value;
      const exchangeType = document.getElementById('wr-exchange-type').value;
      const routingPrefix = document.getElementById('wr-routing-prefix').value;
      const updates = [
        ['enabled', enabled],
        ['host', host],
        ['port', port],
        ['user', user],
        ['pass', pass],
        ['vhost', vhost],
        ['exchange', exchange],
        ['exchange_type', exchangeType],
        ['routing_prefix', routingPrefix],
      ];
      Promise.all(updates.map(([k,v]) => save(k,v)))
        .then(() => OC.Notification.show('Webhook RabbitMQ settings saved'))
        .catch(() => OC.Notification.show('Failed to save settings'));
    });
  })();
</script>

