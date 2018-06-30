(local MyClass {})
(set MyClass.__index MyClass)

(defn MyClass.new []
  (let [self (setmetatable {} MyClass)]
    self))

MyClass
