(function() {
    let player = document.getElementById("player");;
    let log = document.getElementById("log");;

    function logger(message) {
        if ((("object") == (typeof(message)))) {
            log.innerHTML += (((((JSON) && (JSON.stringify))) ? (JSON.stringify(message)) : (message)) + ("<br />"));
        } else {
            log.innerHTML += ((message) + ("<br />"));
        };
    };

    function dbg(title, obj) {
        logger(((title) + ((((JSON) && (JSON.stringify))) ? (JSON.stringify(obj)) : (obj))));
    };

    function wait(delay_ms) {
        return new Promise(function(x) {
            setTimeout(x, delay_ms);
        });
    };

    function create_websocket() {
        if (navigator.onLine) {
            logger("You are online!");;
        } else {
            logger("You are offline!");
            return false;;
        };
        if (window.WebSocket) {
            logger("WebSocket is supported");;
        } else {
            logger("Error: WebSocket is not supported");
            return false;;
        };
        (function() {
            let url = (("wss://") + (document.getElementById("wss-server-connection").innerText) + ("/"));;
            let w = new WebSocket(url);;
            w.onopen = function() {
                create_webrtc(w);
                w.send((("{startup: '") + (document.getElementById("ssl-client-connection").innerText) + ("'}")));
                logger("websocket open");
            };
            w.onmessage = function(e) {
                dbg("websocket received message: e.data=", e.data);
            };
            w.onclose = function(e) {
                logger((("websocket closed: ") + (e.data)));
                if (((1000) != (e.code))) {
                    if (((1006) == (code))) {
                        logger("websocket: probably authentication error, check your javascript console!");
                    };
                    logger((("websocket connection was not closed normally! code=") + (e.code) + (" reason=") + (e.reason)));
                    if ((!(navigator.onLine))) {
                        logger("websocket: You are offline!");
                    };;
                };
            };
            w.onerror = function(e) {
                logger((("websocket error: ") + (e.data)));
            };;
            return w;
        })();;
    };

    function create_webrtc(signaling) {
        logger("create_webrtc ..");
        (function() {
            let configuration = {
                iceServers: ([])
            };;
            let pc = new RTCPeerConnection(configuration);;
            pc.onicecandidate = function(event) {
                if (event.candidate) {
                    dbg("onicecandidate: event=", event);
                    signaling.send(event.candidate);;
                };
            };
            (function() {
                let chan_send = pc.createDataChannel("datachannel", {
                    reliable: (false)
                });;
                pc.createOffer().then(function(offer) {
                    dbg("createOffer: offer=", offer);
                    pc.setLocalDescription(offer);
                    signaling.send(JSON.stringify({
                        "messageType": ("offer"),
                        "peerDescription": (offer)
                    }));
                });
            })();;
        })();;
    };

    function startup() {
        logger("startup ..");
        (function() {
            let ws = create_websocket();;
        })();;
    };
    window.addEventListener("load", startup, false);
})();