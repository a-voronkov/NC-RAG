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

  function onReady() {
    var btn = document.getElementById('wr-save');
    if (!btn) return;
    btn.addEventListener('click', function() {
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
      Promise.all(updates.map(function(kv){ return save(kv[0], kv[1]); }))
        .then(function(){ OC.Notification.show('Webhook RabbitMQ settings saved'); })
        .catch(function(){ OC.Notification.show('Failed to save settings'); });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', onReady);
  } else {
    onReady();
  }
})();

