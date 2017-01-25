//= require private_pub
var Channel = function() {}

$.extend(true, Channel, {

  init: function(server) {
    PrivatePub.fayeExtension = {};
    PrivatePub.subscriptions['server'] = server;
  },

  subscribe: function(channelNames) {
    var isSubscribed = true;
    var $container = $('#data-container');

    if(typeof PrivatePub !== "undefined") {
      if(typeof Faye !== "undefined") {
        PrivatePub.fayeClient = new Faye.Client(PrivatePub.subscriptions.server);
      }
      for (var i = 0; i < channelNames.length; i++) {
        PrivatePub.sign({ channel: channelNames[i] });
        PrivatePub.subscribe(channelNames[i], function(data, channel) {
          if(channel == '/general') {
            $container.append(data.message);
          } else if(isSubscribed) {
            $container.html(data.message).append('<br>');
            isSubscribed = false;
          }
        });
      }
    }
  }
})
