// errores: 1 (un Cat no es un Dog)
object Animal
object Dog extends Animal
object Cat extends Animal

method main {
  val x: Dog = new Cat
  println(x)
}