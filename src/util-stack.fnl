(local util-stack {})

;; FIXME needs to me moved to a more "common" location
;; (for use in other projects)

;; convert OpenComputers stack data to drop information that is unnessesary
(defn util-stack.from-table [the-table]
  (local tmp-table {})
  (tset tmp-table :colname the-table.name)
  (tset tmp-table :label the-table.label)
  (tset tmp-table :referid (.. the-table.name ":" the-table.label))
  (tset tmp-table :amount the-table.size)
  (tset tmp-table :max-amount the-table.maxSize)
  tmp-table)

;; gets the last segment of a string seperated by ";" (semicolons)
(defn util-stack.labelate [the-string]
  (local rv (string.reverse the-string))
  (local i (string.find rv ":"))
  (string.sub the-string (+ 1 (- i)) -1))

util-stack
