(local Cluster (require "cluster"))
(local term (require "term"))
(local util-stack (require "util-stack"))

;; standalone (normal) version of the storage system manager
;; not verry fancy but gets the job done

;; split string by separator
(defn split [the-string separator]
  (local t {})
  (local sep (or separator " "))
  (each [str (string.gmatch the-string (.. "([^" sep "]+)"))]
    (tset t (+ 1 (# t)) str))
  t)

(print "<-> Booting")

(local cluster (Cluster.new))

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

(initialize)


;; function to fetch and display list of stored items
(defn list-items []
  (each [k v (pairs (. cluster :referid-index))]
    ;;(print v k)
    (print v (util-stack.labelate k))))

;; function to prompt (user) for input
(defn prompt [message]
  (io.write message)
  (io.read))

;; funtion to (interactively) request an item
(defn request-item []
  (local item (prompt "choose item:"))
  (local item-amount (or (prompt "choose amount:") "1"))
  (: cluster :fetch-human item (tonumber item-amount)))

;; function to display "help" text
(defn help []
  (print "list of valid commands")
  (print)
  (print "help" "this list")
  (print "get" "request item from storage")
  (print "index" "manually re-index chests")
  (print "exit" "exit the program")
  (print)
  (prompt "(enter)"))

(while true
  (term.clear)
  (print "<-> ready")
  (list-items)
  (print)
  (local command (prompt ">"))
  (if (= command "index")
      (initialize)
      (= command "get")
      (request-item)
      (= command "list")
      (list-items)
      (or (= command "exit") (= command "give up"))
      (os.exit)
      (= command "help")
      (help)
      (help))
  (os.sleep))
