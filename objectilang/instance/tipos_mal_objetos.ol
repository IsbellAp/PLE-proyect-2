// errores: 12
// Tipos de objetos que no corresponden: subtipos, varianza, argumentos y valores de retorno.
object Animal
object Dog extends Animal
object Cat extends Animal
object Caja[+A](val item: A)
object Celda[A](val item: A)
object Consumidor[-A]
Animal.comer = method(cantidad: Integer): String { "come $cantidad" }
Animal.edad = method(): Integer { "diez" }
Dog.comer = method(cantidad: Integer): Integer { cantidad }

method main {
  val x: Dog = new Cat
  val y: Dog = new Animal
  val cajaAnimal: Caja[Animal] = new Caja(new Cat)
  val cajaPerro: Caja[Dog] = cajaAnimal
  val celdaPerro: Celda[Dog] = new Celda(new Dog)
  val celda: Celda[Animal] = celdaPerro
  val consumidor: Consumidor[Dog] = new Consumidor[Animal]
  val alReves: Consumidor[Animal] = consumidor
  val c = new Caja(1, 2)
  val a = new Animal
  a.comer("mucho")
  a.comer(1, 2)
  val n: Integer = a.comer(1)
  val o = new Animal { override comer(n: Integer): Boolean = { true } }
  println(x, y, cajaPerro, celda, alReves, c, o, n)
}
