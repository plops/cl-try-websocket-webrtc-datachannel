(mapc #'ql:quickload '("cl-who" 
		       "clack" "websocket-driver"
		       "cl-js-generator" "event-emitter"
		       "local-time"
		       "alexandria"))
(in-package #:cl-js-generator)
;;https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Simple_RTCDataChannel_sample
;(setf *features* (union *features* '(:nolog)))
(setf *features* (set-difference *features* '(:nolog)))


(setq cl-who:*attribute-quote-char* #\")
(setf cl-who::*html-mode* :html5)

(defparameter *wss-port* 7778)
(defparameter *ssl-port* 7777)
(defparameter *server-ip* 
  (let ((ipstr (with-output-to-string (s)
		 (sb-ext:run-program "/usr/bin/hostname" '("-i") :output s)
		 )))
    (string-trim 
     '(#\Space #\Newline #\Backspace #\Tab 
       #\Linefeed #\Page #\Return #\Rubout)
     ipstr)
    ))


(defun handler (env)
  '(200 nil ("hello world")))

;; openssl req -new -x509 -nodes -out /tmp/server.crt -keyout /tmp/server.key



(unless (and (probe-file "/tmp/server.key")
	     (probe-file "/tmp/server.crt"))
  ;; generate keys if they don't exist
  (let* ((p (sb-ext:run-program "/usr/bin/openssl" '("req" "-new" "-x509"
						   "-nodes"  "-out"
						   "server.crt" "-keyout"
						   "server.key")
			      :directory "/tmp/" :output :stream :input :stream
			      :wait nil))
       (stream-in (sb-ext:process-input  p))
       (stream-out (sb-ext:process-output p)))
  (flet ((consume ()
	   (loop while (listen stream-out) do
		(format t "~a" (read-char stream-out))))
	 (consume-until-colon ()
	   (loop for char = (read-char stream-out nil 'foo)
	      until (or (eq char 'foo)
			(eq #\: char))
	      do (format t "~a" char)
		))
	 (consume-until-colon-nowait ()
	   (loop while (listen stream-out) do
		(let ((line (read-line stream-out nil 'foo)))
		  (print line)
		  ))))
    (loop for e in
	 '("NL"
	   "Noord-Brabant" "Veldhoven" "ck" "certifacte_unit"
	   "nn" "kielhorn.martin@gmail.com")
       do
	 (consume-until-colon)
	 (write-line (format nil "~a~%" e) stream-in)
	 (format t "~&> ~a~%" e)
	 (finish-output stream-in)))
  (close stream-in)
  (sb-ext:process-wait p)
  (sb-ext:process-close p)))


(progn
  (defvar *clack-server* nil) ;; initialize with nil
  (when *clack-server* ;; stop pre-existing server
    (clack.handler:stop *clack-server*)
    (setf *clack-server* nil))
  (setf *clack-server* ;; start new server
	(clack:clackup
	 (lambda (env)
	   (funcall 'handler env))
	 :port *ssl-port*
	 :ssl t :ssl-key-file  #P"/tmp/server.key" :ssl-cert-file #P"/tmp/server.crt"
	 :use-default-middlewares nil)))



;; :ssl-key-file #P"/etc/letsencrypt/live/cheapnest.org/privkey.pem"  :ssl-cert-file #P"/etc/letsencrypt/live/cheapnest.org/fullchain.pem"





(let ((ws-connections ()))
  (defun get-ws-connections ()
    ws-connections)
 (defun ws-handler (env)
   (handler-case 
       (destructuring-bind (&key request-uri remote-addr remote-port
				 content-type content-length headers &allow-other-keys)
	   env
	 (format t "ws-handler: ~a~%" env)
	 (let ((ws (websocket-driver:make-server env))
	       (now (local-time:now)))
	   
	   (push `(:remote-addr ,remote-addr
				:remote-port ,remote-port
				:socket ,ws
				:connection-setup-time ,now
				:user-agent ,(gethash "user-agent" headers)
				:last-seen ,now)
		 ws-connections)
	   (event-emitter:on :message ws
			     (lambda (message)
			       (format t "ws-handler received: ~a~%" message)
			       (mapcar #'(lambda (x) (websocket-driver:send (getf x :socket)
									    message))
				       ws-connections)))
	   (event-emitter:on :close ws
			     (lambda (&key code reason)
			       (format t "ws-handler socket closed: code=~a reason=~a~%" code reason)
			       (setf ws-connections
				     (remove-if #'(lambda (x)
						    (and (string= remote-addr
								  (getf x :remote-addr))
							 (eq remote-port (getf x :remote-port))
		     ))
	    ws-connections))
			       ))
	   
	   (event-emitter:on :error ws
			     (lambda (&rest rest)
			       (format t "ws-handler error: ~a~%" rest)
			       (setf ws-connections
				     (remove-if #'(lambda (x)
						    (and (string= remote-addr
								  (getf x :remote-addr))
							 (eq remote-port (getf x :remote-port))
		     ))
	    ws-connections))))
	   (lambda (responder)
	     (format t "ws-handler: start connection ~a~%" responder) 
	     (websocket-driver:start-connection ws))))
     (condition ()
       (format t "This connection wants websocket protocol!~%")
       `(404 nil ("This connection wants websocket protocol!"))))))

(progn
  (defvar *ws-server* nil) ;; initialize with nil
  (when *ws-server* ;; stop pre-existing server
    (clack.handler:stop *ws-server*)
    (setf *ws-server* nil))
  (setf *ws-server* ;; start new server
	(clack:clackup
	 (lambda (env)
	   (funcall 'ws-handler env))
	 :port *wss-port*
	 :ssl t :ssl-key-file  #P"/tmp/server.key" :ssl-cert-file #P"/tmp/server.crt"
	 :use-default-middlewares nil)))

(defun generate-js (env &key (server nil))
  (destructuring-bind (&key server-name remote-addr remote-port path-info &allow-other-keys) env
   (;;emit-js :clear-env t :code 
    cl-js-generator::beautify-source
    `(let ((player (document.getElementById (string "player")))
	   (log (document.getElementById (string "log"))))

       (def logger (message)
	 #-nolog
	 (if (== (string "object") (typeof message))
	     (incf log.innerHTML
		   (+ (? (and JSON
			      JSON.stringify)
			 (JSON.stringify message)
			 message)
		      (string "<br />")))
	     (incf log.innerHTML
		   (+ message
		      (string "<br />")))))
       (def dbg (title obj)
	 #-nolog
	 (logger (+ title
		    (? (and JSON
			    JSON.stringify)
		       (JSON.stringify obj)
		       obj))))
	   

       (def wait (delay_ms)
	 (return ("new Promise" (lambda (x)
				  (setTimeout x
					      delay_ms)))))

       (def create_websocket ()
	 (if navigator.onLine
	     (statement (logger (string "You are online!")))
	     (statement (logger (string "You are offline!"))
			(return false)))
	 (if window.WebSocket
	     (statement (logger (string "WebSocket is supported")))
	     (statement (logger (string "Error: WebSocket is not supported"))
			(return false)))
	 (let ((url (+ (string "wss://")
		       ;; alternative: window.location.host
		       (dot (document.getElementById (string "wss-server-connection"))
			    innerText)
		       (string "/")))
	       (w ("new WebSocket" url)))
	   (setf w.onopen
		 (lambda ()
		   (create_webrtc w)
		   (w.send (+ (string "{startup: '")
			      (dot (document.getElementById (string "ssl-client-connection"))
				   innerText)
			      (string "'}")))
		   (logger
		    (string "websocket open")))
		 w.onmessage
		 (lambda (e)
		   (dbg  (string "websocket received message: e.data=")
			 e.data))
		 w.onclose
		 (lambda (e)
		   (logger (+ (string "websocket closed: ")
			      e.data))
		   (if (!= 1000 e.code)
		       (statement
			;; in order to protect browser users this error message is vague according to the w3c websocket standard
			(if (== 1006 code)
			    (logger (string "websocket: probably authentication error, check your javascript console!")))
			(logger (+ (string "websocket connection was not closed normally! code=")
				   e.code
				   (string " reason=")
				   e.reason))
			(if (not navigator.onLine)
			    (logger (string "websocket: You are offline!"))))))
		 w.onerror ;; always followed by close
		 (lambda (e)
		   (logger (+ (string "websocket error: ")
			      e.data))))
	   (return w)))

       (def create_webrtc ( signaling )
	 (logger (string "create_webrtc .."))
	 (let ((configuration (dict (iceServers (list))))
	       (pc ("new RTCPeerConnection" configuration)))
	   (setf pc.onicecandidate (lambda (event)
				     (if event.candidate
					 (statement ;; send to peer

					      
					  (dbg (string "onicecandidate: event=")
					       event)
					  (signaling.send (JSON.stringify
							   (dict ((string "messageType")
								  (string "icecandidate"))
								 ((string "peerDescription")
								  event.candidate))))
					  )
					 ;; else all have been sent
					 )))
	   (let ((chan_send (pc.createDataChannel (string
						    "datachannel")
						   (dict (reliable
							  false)))))
	      #+nil (setf chan_send.onopen (lambda (s)))
	      (dot (pc.createOffer)
		   (then (lambda (offer)
			   (dbg (string "createOffer: offer=")
				offer)
			   (pc.setLocalDescription offer)
			   (signaling.send
			    (JSON.stringify
			     (dict ((string "messageType")
				    (string  "offer"))
				   ((string "peerDescription")
				    offer))))))))))
	   
       (def startup ()
	 (logger (string "startup .."))

	 ,@(loop for (e f) in '((button-connect connect_peers)
			    (button-disconnect disconnect_peers)
			    (button-send send_message))
		collect
		`(dot (document.getElementById (string ,e))
		      (addEventListener (string "click"
						)
					,f false)))
	     
	 (let ((ws (create_websocket)))))
       (window.addEventListener (string "load")
				startup false)))))

(defun generate-html (env &key (server nil))
  (destructuring-bind (&key server-name remote-addr remote-port path-info &allow-other-keys) env
   (cl-who:with-html-output-to-string (s)
     (cl-who:htm
      (:html
       (:head (:title (cl-who:str (if server "server" "client")))
	      ;(:script :src (if server "server.js" "client.js"))
	      )
       (:body
	(:div
	 (:table
	  (loop for row in (get-ws-connections) do
	       (cl-who:htm
		(:tr :cellpadding 4
		     (loop for x in '(:remote-addr :remote-port :last-seen :user-agent) do
			  (cl-who:htm
			   (:td (cl-who:fmt "~a" (getf row x)))))))))
	 )
	(:div :id "buttons"
	      (:button :id "button-connect" "connect")
	      (:button :id "button-disconnect" "disconnect"))
	(:div :class "messagebox"
	      (:label :for "message" "Enter a message:"
		      (:input :type "text"
			      :name "message"
			      :id "message"))
	      (:button :id "button-send" "send"))
	(:div :class "messagebox" :id "receivebox"
	      (:p "Messages received:"))
	(:p (princ (format nil "~a" env) s))
	(:div :id "wss-server-connection"
	      (princ (format nil "~a:~a"
			     *server-ip*
			     *wss-port*) s))
	(:div :id "ssl-client-connection"
	      (princ (format nil "~a:~a"
			     (or remote-addr "localhost")
			     remote-port) s))
		    
	(:a :href (format nil "https://~a:~a/"
			  (or server-name *server-ip*)
			  *wss-port*)
	    "accept secure websocket cert here")

		    
	(:pre :id "log")
		    
		    
		    (:script :src (if server "server.js" "client.js"))
	#+nil (:script :type "text/javascript"
		       (princ script-str s)
		       )))))))



(with-open-file (s "js/server.js"
		   :if-exists :supersede
		   :if-does-not-exist :create
		   :direction :output)
  (write-sequence 
   (generate-js nil :server t) s))

(defun handler (env)
  (destructuring-bind (&key server-name remote-addr remote-port path-info &allow-other-keys) env
    (alexandria:switch (path-info :test #'equal)
      ("/"
       `(200 (:content-type "text/html; charset=utf-8")
	     (,(generate-html env :server t))))
      ("/client"
       `(200 (:content-type "text/html; charset=utf-8")
	     (,(generate-html env :server nil))))
      ("/server.js"
       `(200 (:content-type "text/javascript; charset=utf-8")
	     (,(generate-js env :server t))))
      ("/client.js"
       `(200 (:content-type "text/javascript; charset=utf-8")
	     (,(generate-js env :server nil))))
      (t
       `(404 (:content-type "text/html; charset=utf-8")
	     (,(cl-who:with-html-output-to-string (s)
		 (cl-who:htm
		  (:html
		   (:head (:title "page missing"))
		   (:body))))))))))


