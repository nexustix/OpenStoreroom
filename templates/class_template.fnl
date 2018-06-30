(local MyClass {})
(set MyClass.__index MyClass)

(defn MyClass.new [init]
  (let [self (setmetatable {} MyClass)]
    (set self.value init)
    self))

(defn MyClass.set_value [self newval]
  (set self.value newval))

(defn MyClass.get_value [self]
  self.value)

(local o (MyClass.new 5))
(print (: o get_value))
(: o set_value 6)
(print (: o get_value))

MyClass
