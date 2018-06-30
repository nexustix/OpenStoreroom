(local Cluster (require "cluster"))
(local util-stack (require "util-stack"))
(local floodmesh (require "floodmesh"))

;; This code uses "floodmesh"
;; "floodmesh" is an old outdated networking library (written by me)
;; and was used as a poof of concept
;; this is not production level code

;; this code opens a "floodmesh" server
;; and provides storage informations to querying clients
;;

(local term (require "term"))
(local c (require "component"))
(local event (require "event"))
(local srs (require "serialization"))

(local cluster (Cluster.new))

;; split string by separator
(defn split [the-string separator]
  (local t {});;UTIL
  (local sep (or separator " "))
  (each [str (string.gmatch the-string (.. "([^" sep "]+)"))]
    (tset t (+ 1 (# t)) str))
  t)

;; index the storage system
(defn initialize []
  (local scanner (: cluster :make-scanner))
  (var running true)
  (while running
    (local x [(coroutine.resume scanner)])
    (local status (coroutine.status scanner))
    (if (= status :suspended)
        (each [i v (ipairs x)]
          (if (and (= i 1) (not v))
              (set running false)
              (= i 2)
              (do
                (term.clear)
                (print (.. "<-> indexing " v "%"))
                (os.sleep))))
        (set running false)))
  (: cluster :index))


;;NETWORKING

(local callsign "storemaster")
(local port 4242)

(local fm (floodmesh.new port))
(: fm :listen)

;;
(initialize)
(: fm :broadcast
  (srs.serialize
    [sender
     false
     "reset"]))
;;

;; gets desired segment from a numbered table (allows offset)
(defn msg-seg [segments index offset]
  (local offset (or offset 0))
  (. segments (+ index offset)))

;; uses "msg-seg" to check if a segment is equal to a desired value
(defn msg-seg-eq [value segments index offset]
  (local offset (or offset 0))
  (if (= (msg-seg segments index offset) value)
      true
      false))

;; handles a "message" and acts accordingly
(defn handle-message [sender segments]
  (io.write (.. "<" sender ">"))
  (each [k v (pairs segments)]
    (io.write "<" v ">"))
  (print)
  (when (msg-seg-eq callsign segments 1)
        (if (msg-seg-eq "fetch-human" segments 2)
            (do
              (: fm :broadcast
                (srs.serialize
                  [sender
                   (: cluster :fetch-human
                     (or (msg-seg segments 3) "")
                     (tonumber (or (msg-seg segments 4) 0)))
                   "fetch-human"])))

            (msg-seg-eq "fetch-computer" segments 2)
            (do
              (: fm :broadcast
                (srs.serialize
                  [sender
                   (: cluster :fetch-computer
                     (or (msg-seg segments 3) "")
                     (tonumber (or (msg-seg segments 4) 0)))
                   "fetch-computer"])))

            (msg-seg-eq "has-human" segments 2)
            (print "TODO stockcheck (human)")

            (msg-seg-eq "has-computer" segments 2)
            (print "TODO stockcheck (computer)")

            (msg-seg-eq "list" segments 2)
            (: fm :broadcast
              (srs.serialize
                [sender
                 true
                 "list"
                 (srs.serialize cluster.referid-index)]))

            (msg-seg-eq "index" segments 2)
            (do
              (initialize)
              (: fm :broadcast
                (srs.serialize
                  [sender
                   false
                   "reset"])))

            (print "<!> no idea what you want" sender))))
  ;;(print "<!> malformed message from" sender))


(var running true)
(while running
  (let [(sender message) (: fm :receive)]
    (local segments (srs.unserialize message))
    (when segments
      (handle-message sender segments))))

(os.exit)
