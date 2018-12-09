var player = document.getElementById("player"), log = document.getElementById("log");
function logger(b) {
  log.innerHTML = "object" == typeof b ? log.innerHTML + ((JSON && JSON.stringify ? JSON.stringify(b) : b) + "<br />") : log.innerHTML + (b + "<br />");
}
function dbg(b, a) {
  logger(b + (JSON && JSON.stringify ? JSON.stringify(a) : a));
}
function wait(b) {
  return new Promise(function(a) {
    setTimeout(a, b);
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
  var b = "wss://" + document.getElementById("wss-server-connection").innerText + "/", a = new WebSocket(b);
  a.onopen = function() {
    create_webrtc(a);
    a.send("{startup: '" + document.getElementById("ssl-client-connection").innerText + "'}");
    logger("websocket open");
  };
  a.onmessage = function(a) {
    dbg("websocket received message: e.data=", a.data);
  };
  a.onclose = function(a) {
    logger("websocket closed: " + a.data);
    1000 != a.code && (1006 == code && logger("websocket: probably authentication error, check your javascript console!"), logger("websocket connection was not closed normally! code=" + a.code + " reason=" + a.reason), navigator.onLine || logger("websocket: You are offline!"));
  };
  a.onerror = function(a) {
    logger("websocket error: " + a.data);
  };
  return a;
}
function create_webrtc(b) {
  logger("create_webrtc ..");
  var a = new RTCPeerConnection({iceServers:[]});
  a.onicecandidate = function(a) {
    a.candidate && (dbg("onicecandidate: event=", a), b.send(a.candidate));
  };
  a.createDataChannel("datachannel", {reliable:!1});
  a.createOffer().then(function(c) {
    dbg("createOffer: offer=", c);
    a.setLocalDescription(c);
    b.send(JSON.stringify({messageType:"offer", peerDescription:c}));
  });
}
function startup() {
  logger("startup ..");
  create_websocket();
}
window.addEventListener("load", startup, !1);


