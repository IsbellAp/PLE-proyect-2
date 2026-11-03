// Snippet 2 del enunciado (Proyecto 1): metodo talk de Cat.
// El snippet solo trae la definicion del metodo; se agregan los objetos
// y un main para que sea un programa completo.
// Salida esperada (con el interprete): Cats meows
object Animal
object Cat extends Animal

Cat.talk = method(): String {
  print("Cats meows")
}

method main {
  val gato = new Cat
  gato.talk()
}
