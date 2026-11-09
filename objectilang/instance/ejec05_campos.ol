// Campo del constructor leido desde afuera (k.item) y desde un metodo (item).
// Salida esperada:
//   Dog
//   Dog
object Animal
object Dog extends Animal
object Caja[+A](val item: A)
Caja.sacar = method(): A { item }

method main {
  val k: Caja[Dog] = new Caja(new Dog)
  println(k.item)
  println(k.sacar())
}
