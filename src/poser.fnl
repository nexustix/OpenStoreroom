(local util-stack (require "util-stack"))
(local sides (require "sides"))

(local Poser {})
(set Poser.__index Poser)

;; represends a Transposer that is tasked to oversee storage
(defn Poser.new [uuid]
  (let [self (setmetatable {} Poser)]
    (local c (require "component"))
    (set self.uuid uuid)
    (set self.proxy (c.proxy uuid))

    ;; {int side}[int slot] -> stack
    (set self.inventories []);; itable of htable of htable

    self))

;; refresh item data of inventories
(defn Poser.refresh-inventories [self]
  (set self.inventories [])
  (for [n 2 5] ;;all sides but bottom
    (let [(size-dst msg) (self.proxy.getInventorySize n)]
      (if size-dst
        (do
          (local tmp-inventory [])
          (for [slot-dst 1 size-dst]
            (let [tmp-stack (self.proxy.getStackInSlot n slot-dst)]
              (when tmp-stack
                (local nxstack (util-stack.from-table tmp-stack))
                (tset tmp-inventory slot-dst nxstack)))
            ;;(os.sleep)
            ;;(print "slot" slot-dst)
            (coroutine.yield))
          (tset self.inventories n tmp-inventory))))))

;; gets a list of all item types/kinds stored in managed inventories
(defn Poser.get-item-kinds [self]
  (local all-kinds {})
  (each [side inv (pairs self.inventories)]
    (each [slot stack (pairs inv)]
      (tset all-kinds stack.referid stack.referid)))
  all-kinds)

;; get total amount of items of a given type/kind (by referid)
(defn Poser.get-item-count [self referid]
  (var total 0)
  (each [side inv (pairs self.inventories)]
    (each [slot stack (pairs inv)]
      (when (= stack.referid referid)
        (set total (+ total stack.amount)))))
  total)

;; fetch (amount of) item by a given referid
(defn Poser.fetch-item [self referid fetch-amount]
  (var need-fetch fetch-amount)
  (when (> need-fetch 0)
    (each [side inv (pairs self.inventories)]
      (each [slot stack (pairs inv)]
        (when (and (= stack.referid referid) (> stack.amount 0))
          (if (>= need-fetch stack.amount)
              (do
                (self.proxy.transferItem side sides.down stack.amount slot 1)
                (set need-fetch (- need-fetch (math.max stack.amount 1)))
                (tset (. (. self.inventories side) slot) :amount 0))
              (do
                (self.proxy.transferItem side sides.down need-fetch slot 1)
                (tset (. (. self.inventories side) slot) :amount (- stack.amount need-fetch))
                (set need-fetch 0)))))))
  need-fetch)

Poser
