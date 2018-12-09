function d() {
  if (navigator.onLine && window.WebSocket) {
    var a = new WebSocket("wss://" + document.getElementById("wss-server-connection").innerText + "/");
    a.onopen = function() {
      e(a);
      a.send("{startup: '" + document.getElementById("ssl-client-connection").innerText + "'}");
    };
    a.onmessage = function() {
    };
    a.onclose = function() {
    };
    a.onerror = function() {
    };
  }
}
function e(a) {
  var c = new RTCPeerConnection({iceServers:[]});
  c.onicecandidate = function(b) {
    b.candidate && a.send(b.candidate);
  };
  c.createDataChannel("datachannel", {reliable:!1});
  c.createOffer().then(function(b) {
    c.setLocalDescription(b);
    a.send(JSON.stringify({messageType:"offer", peerDescription:b}));
  });
}
window.addEventListener("load", function() {
  d();
}, !1);


