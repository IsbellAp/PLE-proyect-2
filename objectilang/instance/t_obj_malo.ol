object Animal
object Dog extends Animal
object Cat extends Animal

method main {
  val x: Dog = new Cat
  println(x)
}