(local Poser (require "poser"))
(local math (require "math"))
(local util-stack (require "util-stack"))

(local Cluster {})
(set Cluster.__index Cluster)

(defn get-transposers []
  ((. (require "component") "list") "transposer"))

;; represent a cosntruct that handles all Posers
(defn Cluster.new []
  (let [self (setmetatable {} Cluster)]
    (set self.posers [])
    (each [uuid kind (pairs (get-transposers))]
      (tset self.posers (+ 1 (# self.posers)) (Poser.new uuid)))

    (set self.referid-index {})
    self))

;; collect index information of all managed posers
;; and calculate total sum in cluster
(defn Cluster.index [self]
  (set self.referid-index {})
  (each [i poser (ipairs self.posers)]
    (each [kind kind_ (pairs (: poser :get-item-kinds))]
      (tset self.referid-index kind 0)))

  (each [k v (pairs self.referid-index)]
    (tset self.referid-index k (: self :get-item-count k))))

;; create a "scanner" that scans one slot of each inventory every call
;; (for loading bars and unobst)
(defn Cluster.make-scanner [self]
  (var tasks [])

  (defn sweep [the-tasks]
    (var running false)
    (each [k v (pairs the-tasks)]
      (when (coroutine.resume v)
        (set running true)))
    running)

  (defn sweep-all [the-tasks]
    (var n 1)
    (var max 108)
    (while (sweep the-tasks)
      (local percent (math.floor (* (/ n max) 100)))
      ;;(print (.. percent "%"))
      (coroutine.yield percent)
      (set n (math.min (+ 1 n) max)))
    percent)

  (each [i poser (ipairs self.posers)]
    (local tmp-task
      (coroutine.create
        (lambda []
          (: poser :refresh-inventories))))
    (tset tasks (+ 1 (# tasks)) tmp-task))

  ;;(sweep-all tasks)

  (coroutine.create
    (lambda []
      (sweep-all tasks))))

;; get total number of item in cluster (by referid)
(defn Cluster.get-item-count [self referid]
  (var sum 0)
  (each [i poser (ipairs self.posers)]
    (set sum (+ sum (: poser :get-item-count referid))))
  (math.floor sum))

;; fetch item by referid
(defn Cluster.fetch-computer [self referid amount]
  (if (>= (: self :get-item-count referid) amount)
      (do
        (var need-fetch amount)
        (each [i poser (ipairs self.posers)]
          (set need-fetch (: poser :fetch-item referid need-fetch)))
        (: self :index)
        true)
      false))

;; fetch item by Human-readable name
;; (fetches LAST item found that matches)
(defn Cluster.fetch-human [self human amount]
  (var r human)
  (each [k v (pairs self.referid-index)]
    (when (= (util-stack.labelate k) human)
      (set r k)))
  (: self :fetch-computer r amount))

;; check if system has at least <amount> of fiven item (by referid)
(defn Cluster.in-stock [self referid amount]
  (: self :index)
  (if (>= (. self.referid-index referid) amount)
      true
      false))

Cluster
