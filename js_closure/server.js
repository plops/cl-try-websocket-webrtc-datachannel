var player = document.getElementById("player"), log = document.getElementById("log");
function logger(c) {
}
function dbg(c, b) {
}
function wait(c) {
  return new Promise(function(b) {
    setTimeout(b, c);
  });
}
function create_websocket() {
  if (navigator.onLine) {
    logger("You are online!");
  } else {
    return logger("You are offline!"), !1;
  }
  if (window.WebSocket) {
    logger("WebSocket is supported");
  } else {
    return logger("Error: WebSocket is not supported"), !1;
  }
  var c = "wss://" + document.getElementById("wss-server-connection").innerText + "/", b = new WebSocket(c);
  b.onopen = function() {
    create_webrtc(b);
    b.send("{startup: '" + document.getElementById("ssl-client-connection").innerText + "'}");
    logger("websocket open");
  };
  b.onmessage = function(a) {
    dbg("websocket received message: e.data=", a.data);
  };
  b.onclose = function(a) {
    logger("websocket closed: " + a.data);
    1000 != a.code && (1006 == code && logger("websocket: probably authentication error, check your javascript console!"), logger("websocket connection was not closed normally! code=" + a.code + " reason=" + a.reason), navigator.onLine || logger("websocket: You are offline!"));
  };
  b.onerror = function(a) {
    logger("websocket error: " + a.data);
  };
  return b;
}
function create_webrtc(c) {
  logger("create_webrtc ..");
  var b = new RTCPeerConnection({iceServers:[]});
  b.onicecandidate = function(a) {
    a.candidate && (dbg("onicecandidate: event=", a), c.send(a.candidate));
  };
  b.createDataChannel("datachannel", {reliable:!1});
  b.createOffer().then(function(a) {
    dbg("createOffer: offer=", a);
    b.setLocalDescription(a);
    c.send(JSON.stringify({messageType:"offer", peerDescription:a}));
  });
}
function startup() {
  logger("startup ..");
  create_websocket();
}
window.addEventListener("load", startup, !1);


